#!/bin/bash
set -euo pipefail

echo "=== STEP 391 / REAL SYSTEMD TEST ==="

echo
echo "1. auth durduruluyor..."
systemctl stop pix2pi-auth || true
echo "OK ✅ stop"

echo
echo "2. early warning calistiriliyor..."
/opt/pix2pi/bin/pix2pi_early_warning.sh
echo "OK ✅ early warning"

echo
echo "3. json kontrol..."
cat /opt/pix2pi/runtime/early_warning.json | jq .
echo "OK ✅ json"

echo
echo "4. service status..."
systemctl status pix2pi-auth --no-pager || true

echo
echo "5. log son 20 satir..."
tail -n 20 /opt/pix2pi/runtime/auto_heal/logs/early_warning.log || true

echo
echo "=== STEP 391 TAMAM ✅ ==="
