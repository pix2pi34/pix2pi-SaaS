#!/bin/bash
set -euo pipefail

echo "=== STEP 401 / ENABLE ALL SERVICES ==="

SCRIPT="/opt/pix2pi/bin/pix2pi_auto_heal.sh"

echo "1. backup..."
cp "$SCRIPT" "${SCRIPT}.bak_$(date +%s)" || true
echo "OK ✅ backup"

echo
echo "2. policy kaldiriliyor..."

sed -i 's/log "svc=\$svc action=skip reason=policy"/restart_service_dynamic "$svc"/g' "$SCRIPT"

echo "OK ✅ tum servisler aktif"

echo
echo "3. test..."
grep -n "restart_service_dynamic" "$SCRIPT"
echo "OK ✅ test"

echo
echo "=== STEP 401 TAMAM ✅ ==="
