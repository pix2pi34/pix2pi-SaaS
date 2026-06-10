#!/bin/bash
set -euo pipefail

echo "=== STEP 417D / BUILD RESTART TEST ==="

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
systemctl status pix2pi-api-gateway --no-pager | head -20
echo "OK ✅ status"

echo
echo "4. health test..."
curl -i --max-time 10 http://127.0.0.1:9010/health
echo
echo "OK ✅ health"

echo
echo "5. query test..."
curl -i --max-time 10 http://127.0.0.1:9010/api/query/users
echo
echo "OK ✅ query"

echo
echo "=== STEP 417D TAMAM ✅ ==="
