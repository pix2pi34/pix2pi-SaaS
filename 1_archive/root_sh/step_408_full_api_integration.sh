#!/bin/bash
set -euo pipefail

echo "=== STEP 408 / API INTEGRATION ==="

FILE="$HOME/pix2pi/pix2pi-SaaS/internal/api-gateway/transport/http/routes.go"

echo "1. backup..."
cp "$FILE" "${FILE}.bak_$(date +%s)"
echo "OK ✅ backup"

echo "2. import ekleniyor..."

# import ekle (zaten varsa tekrar eklemez)
grep -q "query_read_model" "$FILE" || sed -i '/import (/a \	qrm "pix2pi/internal/services/query_read_model"' "$FILE"

echo "OK ✅ import"

echo "3. register ekleniyor..."

# app tanımından sonra ekle
grep -q "qrm.Register" "$FILE" || sed -i '/fiber.New()/a \ \n\tqrmService := qrm.New()\n\tqrm.Register(app, qrmService)\n' "$FILE"

echo "OK ✅ register"

echo "4. build test..."

cd ~/pix2pi/pix2pi-SaaS

if go build ./... >/dev/null 2>&1; then
    echo "OK ✅ build başarılı"
else
    echo "HATA ❌ build fail"
fi

echo
echo "=== STEP 408 TAMAM ==="
