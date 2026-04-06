#!/bin/bash

echo "=== STEP 411 / FIX IMPORT PATH ==="

FILE=~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go

echo "1. backup..."
cp $FILE ${FILE}.bak_$(date +%s)
echo "OK ✅ backup"

echo "2. import fix..."

sed -i 's|pix2pi/internal/services/query_read_model|github.com/divrigili/pix2pi-SaaS/internal/services/query_read_model|g' $FILE

echo "OK ✅ import fixed"

echo "3. verify..."
grep query_read_model $FILE

echo "OK ✅ verify"

echo "=== STEP 411 TAMAM ==="
