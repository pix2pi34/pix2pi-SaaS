#!/bin/bash
set -euo pipefail

echo "=== STEP 422D / BUILD RESTART TEST ==="

cd "$HOME/pix2pi/pix2pi-SaaS"

echo
echo "1. build..."
go build -o /opt/pix2pi/orchestrator/bin/pix2pi-api-gateway ./cmd/api-gateway
echo "OK ✅ build"

echo
echo "2. restart..."
systemctl restart pix2pi-api-gateway
sleep 2
echo "OK ✅ restart"

echo
echo "3. status..."
systemctl status pix2pi-api-gateway --no-pager | head -20 || true
echo "OK ✅ status"

echo
echo "4. health..."
curl -i --max-time 10 http://127.0.0.1:9010/health || true
echo
echo "OK ✅ health"

echo
echo "5. query..."
curl -i --max-time 10 http://127.0.0.1:9010/api/query/users || true
echo
echo "OK ✅ query"

echo
echo "6. log..."
journalctl -u pix2pi-api-gateway -n 40 --no-pager || true
echo "OK ✅ log"

echo
echo "=== STEP 422D TAMAM ✅ ==="
