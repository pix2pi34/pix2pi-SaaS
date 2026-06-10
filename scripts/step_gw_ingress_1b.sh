#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/pix2pi/pix2pi-SaaS"
TS="$(date +%Y%m%d_%H%M%S)"

BACKUP_DIR="$ROOT/backups/nginx_gateway_ingress/$TS"
SITE_FILE="/etc/nginx/sites-enabled/pix2pi_ssl"
PUBLIC_SNIPPET="/etc/nginx/snippets/pix2pi_gateway_public.conf"
HEADER_SNIPPET="/etc/nginx/snippets/pix2pi_gateway_proxy_headers.conf"

mkdir -p "$BACKUP_DIR"

echo "===== STEP 1 - YEDEK ====="
cp -a /etc/nginx/nginx.conf "$BACKUP_DIR/nginx.conf.bak"
cp -a /etc/nginx/sites-enabled "$BACKUP_DIR/sites-enabled.bak"
cp -a /etc/nginx/sites-available "$BACKUP_DIR/sites-available.bak" 2>/dev/null || true
cp -a /etc/nginx/snippets "$BACKUP_DIR/snippets.bak" 2>/dev/null || true
echo "OK ✅ nginx yedekleri alindi: $BACKUP_DIR"

echo
echo "===== STEP 2 - CAKISMA KONTROL ====="
if grep -RnsE 'location[[:space:]]+(\^~[[:space:]]+)?/api/[[:space:]]*\{' /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/nginx/snippets 2>/dev/null | grep -v "pix2pi_gateway_public.conf" ; then
  echo "HATA ❌ mevcut /api/ location cakismasi bulundu"
  exit 1
fi

if grep -RnsE 'location[[:space:]]+(\^~[[:space:]]+)?/internal/[[:space:]]*\{' /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/nginx/snippets 2>/dev/null | grep -v "pix2pi_gateway_public.conf" ; then
  echo "HATA ❌ mevcut /internal/ location cakismasi bulundu"
  exit 1
fi

if grep -RnsE 'location[[:space:]]+(\^~[[:space:]]+)?/health/[[:space:]]*\{' /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/nginx/snippets 2>/dev/null | grep -v "pix2pi_gateway_public.conf" ; then
  echo "HATA ❌ mevcut /health/ location cakismasi bulundu"
  exit 1
fi

echo "OK ✅ location cakismasi yok"

echo
echo "===== STEP 3 - HEADER SNIPPET ====="
cat <<'SNIP' > "$HEADER_SNIPPET"
proxy_http_version 1.1;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Request-Id $request_id;
proxy_set_header X-Correlation-Id $request_id;
proxy_connect_timeout 5s;
proxy_send_timeout 30s;
proxy_read_timeout 30s;
SNIP
echo "OK ✅ header snippet yazildi"

echo
echo "===== STEP 4 - PUBLIC INGRESS SNIPPET ====="
cat <<'SNIP' > "$PUBLIC_SNIPPET"
# Pix2pi Gateway public ingress
location ^~ /internal/ {
    return 404;
}

location ^~ /health/ {
    proxy_pass http://127.0.0.1:9010;
    include /etc/nginx/snippets/pix2pi_gateway_proxy_headers.conf;
}

location ^~ /api/ {
    proxy_pass http://127.0.0.1:9010;
    include /etc/nginx/snippets/pix2pi_gateway_proxy_headers.conf;
}
SNIP
echo "OK ✅ public ingress snippet yazildi"

echo
echo "===== STEP 5 - SITE INCLUDE EKLE ====="
python3 - <<'PY'
from pathlib import Path

site = Path("/etc/nginx/sites-enabled/pix2pi_ssl")
include_line = "    include /etc/nginx/snippets/pix2pi_gateway_public.conf;\n"

if not site.exists():
    raise SystemExit("sites-enabled/pix2pi_ssl bulunamadi")

text = site.read_text()

if include_line in text:
    print("OK ✅ include zaten var")
    raise SystemExit(0)

marker = "server_name"
idx = text.find(marker)
if idx == -1:
    raise SystemExit("server_name satiri bulunamadi")

line_end = text.find("\n", idx)
if line_end == -1:
    raise SystemExit("server_name satiri sonu bulunamadi")

new_text = text[:line_end+1] + include_line + text[line_end+1:]
site.write_text(new_text)
print("OK ✅ include satiri eklendi")
PY

echo
echo "===== STEP 6 - NGINX TEST ====="
nginx -t
echo "OK ✅ nginx -t basarili"

echo
echo "===== STEP 7 - RELOAD ====="
systemctl reload nginx
echo "OK ✅ nginx reload tamam"

echo
echo "===== STEP 8 - CANLI HTTP KONTROL ====="
echo "--- /health/live ---"
curl -sk -i https://127.0.0.1/health/live -H 'Host: pix2pi.com.tr' | sed -n '1,20p'

echo
echo "--- /api/me ---"
curl -sk -i https://127.0.0.1/api/me -H 'Host: pix2pi.com.tr' | sed -n '1,20p'

echo
echo "--- /internal/routes ---"
curl -sk -i https://127.0.0.1/internal/routes -H 'Host: pix2pi.com.tr' | sed -n '1,20p'

echo
echo "===== STEP 9 - SON KONTROL ====="
grep -n "pix2pi_gateway_public.conf" "$SITE_FILE" || true
echo
echo "OK ✅ GW-INGRESS-1B bitti"
