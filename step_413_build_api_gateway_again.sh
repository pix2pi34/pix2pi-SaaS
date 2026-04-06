#!/bin/bash
set -euo pipefail

echo "=== STEP 413 / BUILD API GATEWAY AGAIN ==="

cd "$HOME/pix2pi/pix2pi-SaaS"

echo
echo "1. build..."
go build -o pix2pi-api-gateway cmd/api-gateway/api_gateway_main.go
echo "OK ✅ build"

echo
echo "2. binary kopya..."
cp pix2pi-api-gateway /opt/pix2pi/orchestrator/bin/pix2pi-api-gateway
chmod +x /opt/pix2pi/orchestrator/bin/pix2pi-api-gateway
echo "OK ✅ binary kopyalandi"

echo
echo "3. restart..."
systemctl restart pix2pi-api-gateway
echo "OK ✅ restart"

echo
echo "4. status..."
systemctl status pix2pi-api-gateway --no-pager | head -20
echo "OK ✅ status kontrol"

echo
echo "5. port..."
ss -tulnp | grep 9010 || true
echo "OK ✅ port kontrol"

echo
echo "=== STEP 413 TAMAM ✅ ==="
