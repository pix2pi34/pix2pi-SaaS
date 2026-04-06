#!/bin/bash
set -e

echo "=== STEP 366 / REMOVE OLD STATUS CALLS ==="

PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"

echo
echo "1. backup..."
cp "$PANEL_HTML" "${PANEL_HTML}.bak_clean_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. eski status fetch temizleniyor..."

# /status kullanan her şeyi öldür
sed -i '/fetch(.*status/d' "$PANEL_HTML"
sed -i '/Service monitor/d' "$PANEL_HTML"
sed -i '/monitor fetch/d' "$PANEL_HTML"

echo "OK ✅ eski fetch temizlendi"

echo
echo "3. kontrol..."
grep -n "status" "$PANEL_HTML" || echo "OK temiz"
echo "OK ✅ kontrol"

echo
echo "4. nginx reload..."
nginx -t && systemctl reload nginx
echo "OK ✅ reload"

echo
echo "=== STEP 366 TAMAM ✅ ==="
