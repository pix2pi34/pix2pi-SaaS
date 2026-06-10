#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/pix2pi/pix2pi-SaaS"
TS="$(date +%Y%m%d_%H%M%S)"

ACTIVE_SITE="/etc/nginx/sites-enabled/pix2pi_ssl"
HEADER_SNIPPET="/etc/nginx/snippets/pix2pi_gateway_proxy_headers.conf"
PUBLIC_SNIPPET="/etc/nginx/snippets/pix2pi_gateway_public.conf"
BACKUP_DIR="$ROOT/backups/nginx_gateway_ingress_active/$TS"

mkdir -p "$BACKUP_DIR"

echo "===== STEP 1 - AKTIF DOSYA KONTROL ====="
test -f "$ACTIVE_SITE"
echo "OK ✅ aktif site bulundu: $ACTIVE_SITE"

echo
echo "===== STEP 2 - YEDEK ====="
cp -a /etc/nginx/nginx.conf "$BACKUP_DIR/nginx.conf.bak"
cp -a "$ACTIVE_SITE" "$BACKUP_DIR/pix2pi_ssl.bak"
test -f "$HEADER_SNIPPET" && cp -a "$HEADER_SNIPPET" "$BACKUP_DIR/" || true
test -f "$PUBLIC_SNIPPET" && cp -a "$PUBLIC_SNIPPET" "$BACKUP_DIR/" || true
echo "OK ✅ aktif nginx yedegi alindi: $BACKUP_DIR"

echo
echo "===== STEP 3 - AKTIF CAKISMA KONTROL ====="
if grep -nE 'location[[:space:]]+(\^~[[:space:]]+)?/api/[[:space:]]*\{' "$ACTIVE_SITE" >/dev/null; then
  echo "HATA ❌ aktif site icinde /api/ prefix location zaten var"
  exit 1
fi

if grep -nE 'location[[:space:]]+(\^~[[:space:]]+)?/health/[[:space:]]*\{' "$ACTIVE_SITE" >/dev/null; then
  echo "HATA ❌ aktif site icinde /health/ prefix location zaten var"
  exit 1
fi

if grep -nE 'location[[:space:]]+(\^~[[:space:]]+)?/internal/[[:space:]]*\{' "$ACTIVE_SITE" >/dev/null; then
  echo "HATA ❌ aktif site icinde /internal/ prefix location zaten var"
  exit 1
fi

echo "OK ✅ aktif site icinde prefix cakisma yok"

echo
echo "===== STEP 4 - HEADER SNIPPET ====="
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
echo "===== STEP 5 - PUBLIC INGRESS SNIPPET ====="
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
echo "===== STEP 6 - INCLUDE EKLE ====="
python3 - <<'PY'
from pathlib import Path

site = Path("/etc/nginx/sites-enabled/pix2pi_ssl")
include_line = "    include /etc/nginx/snippets/pix2pi_gateway_public.conf;\n"
text = site.read_text()

if include_line in text:
    print("OK ✅ include zaten var")
    raise SystemExit(0)

lines = text.splitlines(keepends=True)
inserted = False
new_lines = []

for line in lines:
    new_lines.append(line)
    if (not inserted) and ("server_name" in line) and ("pix2pi.com.tr" in line):
        new_lines.append(include_line)
        inserted = True

if not inserted:
    raise SystemExit("server_name pix2pi.com.tr satiri bulunamadi")

site.write_text("".join(new_lines))
print("OK ✅ include satiri eklendi")
PY

echo
echo "===== STEP 7 - NGINX TEST ====="
nginx -t
echo "OK ✅ nginx -t basarili"

echo
echo "===== STEP 8 - RELOAD ====="
systemctl reload nginx
echo "OK ✅ nginx reload tamam"

echo
echo "===== STEP 9 - CANLI TEST ====="
echo "--- /health/live ---"
curl -sk -i https://127.0.0.1/health/live -H 'Host: pix2pi.com.tr' | sed -n '1,20p'

echo
echo "--- /api/me ---"
curl -sk -i https://127.0.0.1/api/me -H 'Host: pix2pi.com.tr' | sed -n '1,20p'

echo
echo "--- /internal/routes ---"
curl -sk -i https://127.0.0.1/internal/routes -H 'Host: pix2pi.com.tr' | sed -n '1,20p'

echo
echo "===== STEP 10 - SON KONTROL ====="
grep -n "pix2pi_gateway_public.conf" "$ACTIVE_SITE" || true
echo
echo "OK ✅ GW-INGRESS-2 bitti"
