#!/bin/bash
set -euo pipefail

echo "=== STEP 414 / TEST API GATEWAY LOCAL ==="

echo
echo "1. health..."
curl -s http://127.0.0.1:9010/health
echo
echo "OK ✅ health"

echo
echo "2. query users..."
curl -s http://127.0.0.1:9010/api/query/users
echo
echo "OK ✅ query"

echo
echo "=== STEP 414 TAMAM ✅ ==="
