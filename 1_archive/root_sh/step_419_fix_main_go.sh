#!/bin/bash
set -euo pipefail

echo "=== STEP 419 / FIX MAIN GO ==="

FILE="$HOME/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go"

cp "$FILE" "$FILE.bak_$(date +%s)"

# 1. yanlış import satırını sil
sed -i '/import query "pix2pi\/internal\/services\/query_read_model"/d' "$FILE"

# 2. doğru import bloğuna ekle
sed -i '/import (/a\ \ \ \ query "github.com/divrigili/pix2pi-SaaS/internal/services/query_read_model"' "$FILE"

gofmt -w "$FILE"

echo "OK ✅ import fix"
echo "=== STEP 419 TAMAM ✅ ==="
