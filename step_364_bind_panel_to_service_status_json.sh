#!/bin/bash
set -e

echo "=== STEP 364 / PANEL BIND TO SERVICE-STATUS.JSON ==="

PANEL_HTML="/opt/pix2pi/nginx/panel_index.html"

echo
echo "1. backup aliniyor..."
cp "$PANEL_HTML" "${PANEL_HTML}.bak_$(date +%Y%m%d_%H%M%S)"
echo "OK ✅ backup"

echo
echo "2. fetch kaynagi duzeltiliyor..."
sed -i 's|fetch("/status")|fetch("/service-status.json")|g' "$PANEL_HTML"
sed -i "s|fetch('/status')|fetch('/service-status.json')|g" "$PANEL_HTML"
sed -i 's|fetch("http://127.0.0.1:8090/status")|fetch("/service-status.json")|g' "$PANEL_HTML"
sed -i "s|fetch('http://127.0.0.1:8090/status')|fetch('/service-status.json')|g" "$PANEL_HTML"
sed -i 's|https://panel.pix2pi.com.tr/status|/service-status.json|g' "$PANEL_HTML"
sed -i 's|https://pix2pi.com.tr/status|/service-status.json|g' "$PANEL_HTML"
echo "OK ✅ fetch kaynagi duzeltildi"

echo
echo "3. panel html kontrol..."
grep -n 'service-status.json\|liveServices\|runningCount\|stoppedCount\|degradedCount\|plannedCount' "$PANEL_HTML" || true
echo "OK ✅ html kontrol"

echo
echo "4. local panel header test..."
curl -I http://127.0.0.1:5858 | head
echo "OK ✅ local panel header"

echo
echo "5. local service json test..."
curl -s http://127.0.0.1/service-status.json | jq '.services | length'
echo "OK ✅ local json test"

echo
echo "6. public panel source test..."
curl -k -s https://panel.pix2pi.com.tr/service-status.json | jq '.services | length'
echo "OK ✅ public json test"

echo
echo "=== STEP 364 TAMAM ✅ ==="
