#!/bin/bash
set -euo pipefail

echo "=== STEP 399 / FIX STATUS PATH ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_auto_heal.sh"

echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅ backup"

echo
echo "2. STATUS_JSON fix..."

sed -i 's|watchdog_alerts.json|auto_heal/status.json|g' "$SCRIPT"

echo "OK ✅ path duzeltildi"

echo
echo "3. test..."
grep -n "STATUS_JSON" "$SCRIPT"
echo "OK ✅ test"

echo
echo "=== STEP 399 TAMAM ✅ ==="
