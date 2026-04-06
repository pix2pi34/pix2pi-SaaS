#!/bin/bash
set -euo pipefail

echo "=== STEP 408 TEST / API GATEWAY NETHTTP ==="

echo
echo "1. service restart..."
systemctl restart pix2pi-api-gateway
echo "OK ✅ restart"

echo
echo "2. local health..."
curl -s http://127.0.0.1:9010/health
echo

echo
echo "3. local query..."
curl -s http://127.0.0.1:9010/api/query/users
echo

echo
echo "=== STEP 408 TEST TAMAM ✅ ==="
