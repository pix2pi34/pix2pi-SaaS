#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "API Gateway baslatiliyor..."

go run cmd/api-gateway/api_gateway_main.go &
sleep 2

echo "=== GATEWAY HEALTH 9010 ==="
curl -s http://127.0.0.1:9010/health

echo
echo "OK ✅ api gateway calisiyor"
