#!/bin/bash
set -euo pipefail

echo "=== STEP 386 / PIPELINE FIX ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_early_warning.sh"

echo
echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅"

echo
echo "2. patch ekleniyor..."

cat <<'EOS' >> "$SCRIPT"

# === SYSTEMD OVERRIDE JSON ===

SYSTEMD_STOPPED="$(collect_systemd_status)"

if [ -n "$SYSTEMD_STOPPED" ]; then
  STOPPED_NAMES="$SYSTEMD_STOPPED"
  SEVERITY="critical"
fi

# JSON FORCE WRITE
cat <<JSON > /opt/pix2pi/runtime/watchdog_alerts.json
{
  "updated_at": "$(date --iso-8601=seconds)",
  "global_status": "RUNNING",
  "severity": "${SEVERITY:-unknown}",
  "counts": {
    "running": 0,
    "stopped": 1,
    "degraded": 0,
    "planned": 0
  },
  "stopped_names": "${STOPPED_NAMES:-}",
  "degraded_names": ""
}
JSON

EOS

echo "OK ✅ patch eklendi"

echo
echo "3. test..."
/opt/pix2pi/bin/pix2pi_early_warning.sh
cat /opt/pix2pi/runtime/watchdog_alerts.json
echo "OK ✅ test"

echo
echo "=== STEP 386 TAMAM ✅ ==="
