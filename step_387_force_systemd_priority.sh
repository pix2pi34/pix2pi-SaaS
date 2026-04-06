#!/bin/bash
set -euo pipefail

echo "=== STEP 387 / FORCE SYSTEMD PRIORITY ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_early_warning.sh"

echo
echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅"

echo
echo "2. eski STOPPED_NAMES temizleniyor..."

sed -i '/STOPPED_NAMES=/d' "$SCRIPT"
echo "OK ✅ eski temizlendi"

echo
echo "3. final logic ekleniyor..."

cat <<'EOS' >> "$SCRIPT"

# === FINAL SYSTEMD AUTHORITY ===

FINAL_STOPPED="$(collect_systemd_status)"

if [ -n "$FINAL_STOPPED" ]; then
  STOPPED_NAMES="$FINAL_STOPPED"
  SEVERITY="critical"
else
  STOPPED_NAMES=""
fi

EOS

echo "OK ✅ final logic eklendi"

echo
echo "4. test..."
/opt/pix2pi/bin/pix2pi_early_warning.sh
cat /opt/pix2pi/runtime/watchdog_alerts.json
echo "OK ✅ test"

echo
echo "=== STEP 387 TAMAM ✅ ==="
