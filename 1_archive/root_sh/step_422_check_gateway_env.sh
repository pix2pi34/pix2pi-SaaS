#!/bin/bash
set -euo pipefail

echo "=== STEP 422C / CHECK GATEWAY ENV ==="

echo
echo "1. shell env kontrol..."
echo "DB_WRITE_DSN=${DB_WRITE_DSN:-<BOS>}"
echo "DB_READ_DSN=${DB_READ_DSN:-<BOS>}"
echo "OK ✅ shell env kontrol"

echo
echo "2. service dosyasi kontrol..."
systemctl cat pix2pi-api-gateway || true
echo "OK ✅ service dosyasi kontrol"

echo
echo "3. orchestrator run script kontrol..."
if [ -f /opt/pix2pi/orchestrator/bin/run_api_gateway.sh ]; then
  sed -n '1,220p' /opt/pix2pi/orchestrator/bin/run_api_gateway.sh
else
  echo "run_api_gateway.sh bulunamadi"
fi
echo "OK ✅ run script kontrol"

echo
echo "=== STEP 422C TAMAM ✅ ==="
