#!/bin/bash
set -euo pipefail

echo "=== STEP 397 / AUTO HEAL SOURCE FIX ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_auto_heal.sh"

echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅ backup"

echo
echo "2. eski ALERT_JSON kaldırılıyor..."
sed -i 's|ALERT_JSON=.*|STATUS_JSON="/opt/pix2pi/runtime/auto_heal/status.json"|' "$SCRIPT"
echo "OK ✅ path degisti"

echo
echo "3. jq okuma duzeltiliyor..."
sed -i 's|jq -r \.severity .*ALERT_JSON.*|jq -r ".severity // \"unknown\"" "$STATUS_JSON"|' "$SCRIPT"
sed -i 's|jq -r \.stopped_names .*ALERT_JSON.*|jq -r ".stopped_names // \"\"" "$STATUS_JSON"|' "$SCRIPT"

# fallback: eger satirlar farkliysa direkt replace
sed -i 's|"$ALERT_JSON"|"${STATUS_JSON}"|g' "$SCRIPT"

echo "OK ✅ jq duzeltildi"

echo
echo "4. test..."
grep -n "STATUS_JSON" "$SCRIPT"
echo "OK ✅ test"

echo
echo "=== STEP 397 TAMAM ✅ ==="
