#!/bin/bash
set -e

pkill -f api_gateway_main || true
sleep 1

cd ~/pix2pi/pix2pi-SaaS
nohup go run cmd/api-gateway/api_gateway_main.go >/tmp/pix2pi_api_gateway.log 2>&1 &

sleep 3

cat /tmp/pix2pi_api_gateway.log || true

echo "OK ✅ combined gateway restart bitti"
