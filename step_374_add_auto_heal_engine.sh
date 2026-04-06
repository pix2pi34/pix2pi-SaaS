#!/bin/bash
set -e

echo "=== STEP 374 / AUTO HEAL ENGINE ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_auto_heal.sh"

echo
echo "1. script yaziliyor..."

cat <<'EOS' > "$SCRIPT"
#!/bin/bash
set -euo pipefail

ALERT_JSON="/opt/pix2pi/runtime/watchdog_alerts.json"
LOG="/opt/pix2pi/runtime/auto_heal.log"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(timestamp)] $1" >> "$LOG"
}

if [ ! -f "$ALERT_JSON" ]; then
  log "alert json yok"
  exit 0
fi

SEVERITY="$(jq -r '.severity' "$ALERT_JSON")"
STOPPED="$(jq -r '.stopped_names' "$ALERT_JSON")"

if [ "$SEVERITY" != "critical" ]; then
  log "sistem kritik degil"
  exit 0
fi

IFS=',' read -ra SERVICES <<< "$STOPPED"

for s in "${SERVICES[@]}"; do
  svc="$(echo "$s" | xargs)"

  case "$svc" in
    auth)
      log "auth restart denemesi"
      systemctl restart pix2pi-auth || log "auth restart fail"
      ;;
    *)
      log "skip $svc (policy disi)"
      ;;
  esac
done

log "auto-heal tamam"
EOS

chmod +x "$SCRIPT"

echo "OK ✅ script yazildi"

echo
echo "2. test calistiriliyor..."
"$SCRIPT"

echo "OK ✅ test calisti"

echo
echo "3. log kontrol..."
tail -n 5 /opt/pix2pi/runtime/auto_heal.log || true

echo
echo "=== STEP 374 TAMAM ✅ ==="
