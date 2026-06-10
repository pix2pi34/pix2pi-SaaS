#!/bin/bash
set -euo pipefail

echo "=== STEP 379 / SCALE HOOK ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_scale_hook.sh"

echo
echo "1. script yaziliyor..."

cat <<'EOS' > "$SCRIPT"
#!/bin/bash
set -euo pipefail

TRIGGER_DIR="/opt/pix2pi/runtime/auto_heal/scale"
LOG_FILE="/opt/pix2pi/runtime/auto_heal/logs/scale_hook.log"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(timestamp)] $1" >> "$LOG_FILE"
}

shopt -s nullglob
FILES=("$TRIGGER_DIR"/*.json)

if [ ${#FILES[@]} -eq 0 ]; then
  log "no_scale_trigger"
  exit 0
fi

for f in "${FILES[@]}"; do
  svc="$(jq -r '.service // "unknown"' "$f" 2>/dev/null || echo unknown)"
  reason="$(jq -r '.reason // "unknown"' "$f" 2>/dev/null || echo unknown)"
  log "scale_trigger_detected service=$svc reason=$reason file=$f"

  # Gelecekte:
  # docker compose up --scale ...
  # kubectl scale deployment ...
  # systemd template instance baslat ...
  # simdilik sadece loglayip trigger dosyasini arsivliyoruz.

  mv "$f" "${f}.processed_$(date +%Y%m%d_%H%M%S)"
done
EOS

chmod 700 "$SCRIPT"
echo "OK ✅ script yazildi"

echo
echo "2. test trigger uretiliyor..."
mkdir -p /opt/pix2pi/runtime/auto_heal/scale
cat <<'JSON' > /opt/pix2pi/runtime/auto_heal/scale/test_auth.json
{
  "service": "auth",
  "reason": "manual_test",
  "created_at": "test"
}
JSON

"$SCRIPT"
echo "OK ✅ test tamam"

echo
echo "3. log kontrol..."
tail -n 20 /opt/pix2pi/runtime/auto_heal/logs/scale_hook.log || true

echo
echo "=== STEP 379 TAMAM ✅ ==="
