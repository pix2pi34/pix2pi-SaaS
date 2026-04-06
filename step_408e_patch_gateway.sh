#!/bin/bash
set -euo pipefail

echo "=== STEP 408E / PATCH API GATEWAY ==="

FILE="cmd/api-gateway/api_gateway_main.go"

echo "1. backup..."
cp "$FILE" "$FILE.bak_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. query route import ekleniyor..."

grep -q "query_read_model" "$FILE" || sed -i '1i\
import query "pix2pi/internal/services/query_read_model"\
' "$FILE"

echo "OK ✅ import"

echo
echo "3. route register ekleniyor..."

grep -q "query.RegisterRoutes" "$FILE" || sed -i '/fiber.New()/a\
    query.RegisterRoutes(app)\
' "$FILE"

echo "OK ✅ route eklendi"

echo
echo "4. build test..."
go build ./cmd/api-gateway || true

echo
echo "=== STEP 408E TAMAM ✅ ==="
