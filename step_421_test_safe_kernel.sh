#!/bin/bash
set -euo pipefail

echo "=== STEP 421C / TEST SAFE KERNEL ==="

cd "$HOME/pix2pi/pix2pi-SaaS"

go build -o /opt/pix2pi/orchestrator/bin/pix2pi-api-gateway ./cmd/api-gateway
echo "OK ✅ build"

systemctl restart pix2pi-api-gateway
sleep 2
echo "OK ✅ restart"

echo
echo "1. query test..."
curl -i --max-time 10 http://127.0.0.1:9010/api/query/users || true
echo
echo "OK ✅ query test bitti"

echo
echo "2. log kontrol..."
journalctl -u pix2pi-api-gateway -n 30 --no-pager || true
echo "OK ✅ log kontrol bitti"

echo
echo "=== STEP 421C TAMAM ✅ ==="
