#!/bin/bash
set -e

echo "=== STEP 361 FIX / MANUAL INSERT ==="

NGINX_FILE="/etc/nginx/sites-available/pix2pi"

echo
echo "1. backup..."
cp "$NGINX_FILE" "${NGINX_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
echo "OK ✅ backup"

echo
echo "2. service-status route ekleniyor..."

if grep -q "service-status.json" "$NGINX_FILE"; then
  echo "OK ✅ zaten var"
else
  cat <<'BLOCK' >> "$NGINX_FILE"

    # SERVICE STATUS (panel safe endpoint)
    location = /service-status.json {
        proxy_pass http://127.0.0.1:8090/status;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 5s;
        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
    }

BLOCK
  echo "OK ✅ route eklendi"
fi

echo
echo "3. panel fetch fix..."

PANEL_FILE="/opt/pix2pi/nginx/panel_index.html"

cp "$PANEL_FILE" "${PANEL_FILE}.bak_$(date +%Y%m%d_%H%M%S)"

sed -i 's|fetch("/status")|fetch("/service-status.json")|g' "$PANEL_FILE"
sed -i "s|fetch('/status')|fetch('/service-status.json')|g" "$PANEL_FILE"
sed -i 's|127.0.0.1:8090/status|service-status.json|g' "$PANEL_FILE"

echo "OK ✅ fetch fix"

echo
echo "4. nginx test..."
nginx -t
echo "OK ✅ nginx test"

echo
echo "5. reload..."
systemctl reload nginx
echo "OK ✅ reload"

echo
echo "6. test..."
curl -s http://127.0.0.1/service-status.json | jq '.services | length'
echo "OK ✅ local test"

echo
echo "7. public test..."
curl -k -s https://panel.pix2pi.com.tr/service-status.json | jq '.services | length'
echo "OK ✅ public test"

echo
echo "=== TAMAM ✅ ==="
