#!/bin/bash
set -e

echo "=== STEP 369 / FIX PANEL DOM IDS ==="

PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"

echo
echo "1. backup..."
cp "$PANEL_HTML" "${PANEL_HTML}.bak_dom_fix_$(date +%s)"
echo "OK ✅ backup"

echo
echo "2. overallBanner kontrol..."

if ! grep -q 'id="overallBanner"' "$PANEL_HTML"; then
  echo "overallBanner eksik → ekleniyor..."

  sed -i 's/<h2>Genel Durum<\/h2>/<h2>Genel Durum<\/h2>\n<div id="overallBanner" class="status-banner status-planned">Yukleniyor...<\/div>/g' "$PANEL_HTML"

  echo "OK ✅ overallBanner eklendi"
else
  echo "OK ✅ overallBanner zaten var"
fi

echo
echo "3. errorBox kontrol..."

if ! grep -q 'id="errorBox"' "$PANEL_HTML"; then
  sed -i 's/<div id="overallBanner".*<\/div>/<div id="overallBanner" class="status-banner status-planned">Yukleniyor...<\/div>\n<div id="errorBox" style="display:none;color:#b91c1c;margin-top:8px"><\/div>/g' "$PANEL_HTML"

  echo "OK ✅ errorBox eklendi"
else
  echo "OK ✅ errorBox var"
fi

echo
echo "4. reload..."
nginx -t && systemctl reload nginx
echo "OK ✅ reload"

echo
echo "=== STEP 369 TAMAM ✅ ==="
