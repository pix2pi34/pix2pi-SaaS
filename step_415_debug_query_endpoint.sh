#!/bin/bash
set -euo pipefail

echo "=== STEP 415 / DEBUG QUERY ENDPOINT ==="

echo
echo "1. local query header test..."
curl -i --max-time 10 http://127.0.0.1:9010/api/query/users || true
echo
echo "OK ✅ local query header test bitti"

echo
echo "2. local query verbose test..."
curl -v --max-time 10 http://127.0.0.1:9010/api/query/users || true
echo
echo "OK ✅ local query verbose test bitti"

echo
echo "3. gateway log son 50 satir..."
journalctl -u pix2pi-api-gateway -n 50 --no-pager || true
echo "OK ✅ gateway log kontrol bitti"

echo
echo "4. process kontrol..."
systemctl status pix2pi-api-gateway --no-pager | head -30 || true
echo "OK ✅ process kontrol bitti"

echo
echo "=== STEP 415 TAMAM ✅ ==="
