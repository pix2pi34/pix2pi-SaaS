#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

pkill -f auth_api_main || true

nohup go run cmd/auth-api/auth_api_main.go > /tmp/pix2pi_auth_api.log 2>&1 &

sleep 2

cat /tmp/pix2pi_auth_api.log || true

echo "OK ✅ auth api baslatildi"
