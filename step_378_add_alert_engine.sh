#!/bin/bash
set -euo pipefail

echo "=== STEP 378 / ALERT ENGINE ==="

ENV_FILE="/opt/pix2pi/runtime/auto_heal/alert.env"
SCRIPT="/opt/pix2pi/bin/pix2pi_alert_dispatch.sh"

echo
echo "1. env dosyasi yaziliyor..."

if [ ! -f "$ENV_FILE" ]; then
cat <<'EOS' > "$ENV_FILE"
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
ALERT_WEBHOOK_URL=""
EOS
chmod 600 "$ENV_FILE"
fi

echo "OK ✅ env hazir"

echo
echo "2. dispatch script yaziliyor..."

cat <<'EOS' > "$SCRIPT"
#!/bin/bash
set -euo pipefail

ENV_FILE="/opt/pix2pi/runtime/auto_heal/alert.env"
LOG_FILE="/opt/pix2pi/runtime/auto_heal/logs/alert_engine.log"

[ -f "$ENV_FILE" ] && source "$ENV_FILE"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(timestamp)] $1" >> "$LOG_FILE"
}

MSG="${1:-Pix2pi alert}"

send_telegram() {
  if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
    log "telegram_skip reason=missing_config"
    return 0
  fi

  curl -fsS -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${MSG}" >/dev/null

  log "telegram_sent"
}

send_webhook() {
  if [ -z "${ALERT_WEBHOOK_URL:-}" ]; then
    log "webhook_skip reason=missing_config"
    return 0
  fi

  curl -fsS -X POST "$ALERT_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"message\":\"${MSG//\"/\\\"}\",\"sent_at\":\"$(date --iso-8601=seconds)\"}" >/dev/null

  log "webhook_sent"
}

send_telegram || log "telegram_error"
send_webhook || log "webhook_error"
EOS

chmod 700 "$SCRIPT"
echo "OK ✅ script hazir"

echo
echo "3. test..."
"$SCRIPT" "Pix2pi test alert engine aktif"
echo "OK ✅ test tamam"

echo
echo "4. log kontrol..."
tail -n 20 /opt/pix2pi/runtime/auto_heal/logs/alert_engine.log || true

echo
echo "=== STEP 378 TAMAM ✅ ==="
