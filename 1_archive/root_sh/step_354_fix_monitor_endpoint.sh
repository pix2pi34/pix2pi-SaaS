#!/bin/bash
set -e

FILE="/opt/pix2pi/nginx/monitor.html"

echo "=== STEP 354 / FIX ENDPOINT ==="

echo
echo "1. backup aliniyor..."
cp "$FILE" "$FILE.bak_$(date +%s)"
echo "OK ✅ backup alindi"

echo
echo "2. endpoint degistiriliyor..."

sed -i 's|/internal/service-monitor|/status|g' "$FILE"

echo "OK ✅ endpoint /status yapildi"

echo
echo "3. test..."

grep "/status" "$FILE" >/dev/null && echo "OK ✅ patch basarili"

echo
echo "4. curl test..."

curl -s http://127.0.0.1:8090/status | head -c 200

echo
echo "OK ✅ step 354 tamam"
