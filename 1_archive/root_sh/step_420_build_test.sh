#!/bin/bash
set -euo pipefail

echo "=== STEP 420 BUILD ==="

cd "$HOME/pix2pi/pix2pi-SaaS"

go build -o /opt/pix2pi/orchestrator/bin/pix2pi-api-gateway ./cmd/api-gateway

echo "OK ✅ build"

systemctl restart pix2pi-api-gateway
sleep 2

echo
echo "=== TEST ==="
curl -i http://127.0.0.1:9010/api/query/users

echo
echo "=== LOG ==="
journalctl -u pix2pi-api-gateway -n 20 --no-pager

echo
echo "=== STEP 420 TAMAM ✅ ==="
