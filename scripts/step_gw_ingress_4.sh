#!/usr/bin/env bash
set -euo pipefail

echo "===== STEP 1 - AKTIF SITE BUL ====="
ACTIVE_LINK="/etc/nginx/sites-enabled/pix2pi_ssl"

if [ ! -L "$ACTIVE_LINK" ] && [ ! -f "$ACTIVE_LINK" ]; then
  echo "HATA ❌ aktif site bulunamadi: $ACTIVE_LINK"
  exit 1
fi

SITE_REAL="$(readlink -f "$ACTIVE_LINK")"
if [ -z "${SITE_REAL:-}" ] || [ ! -f "$SITE_REAL" ]; then
  echo "HATA ❌ aktif site real path bulunamadi"
  exit 1
fi

echo "OK ✅ aktif site: $SITE_REAL"

echo
echo "===== STEP 2 - YEDEK ====="
TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="/root/pix2pi/pix2pi-SaaS/backups/nginx_gateway_internal_block/$TS"
mkdir -p "$BACKUP_DIR"

cp "$SITE_REAL" "$BACKUP_DIR/$(basename "$SITE_REAL").bak"
cp -a /etc/nginx/snippets "$BACKUP_DIR/snippets_bak"

echo "OK ✅ yedek alindi: $BACKUP_DIR"

echo
echo "===== STEP 3 - INTERNAL BLOCK SNIPPET YAZ ====="
cat <<'SNIPPET' > /etc/nginx/snippets/pix2pi_gateway_internal_block.conf
location ^~ /internal/ {
    default_type application/json;
    add_header Cache-Control "no-store" always;
    add_header X-Ingress-Policy "public-internal-deny" always;
    return 404 '{"status":"error","source":"nginx","code":"public_internal_route_blocked","message":"public domain uzerinden internal route kapali"}';
}
SNIPPET

echo "OK ✅ internal block snippet yazildi"

echo
echo "===== STEP 4 - SITE ICINE INCLUDE EKLE ====="
if grep -qF "include /etc/nginx/snippets/pix2pi_gateway_internal_block.conf;" "$SITE_REAL"; then
  echo "OK ✅ include zaten var"
else
  SITE_REAL_ENV="$SITE_REAL" python3 <<'PY'
import os
from pathlib import Path

site = Path(os.environ["SITE_REAL_ENV"])
text = site.read_text()

public_include = "include /etc/nginx/snippets/pix2pi_gateway_public.conf;"
internal_include = "include /etc/nginx/snippets/pix2pi_gateway_internal_block.conf;"

if internal_include in text:
    print("OK ✅ include zaten mevcut")
    raise SystemExit(0)

if public_include in text:
    text = text.replace(
        public_include,
        internal_include + "\n    " + public_include,
        1,
    )
    site.write_text(text)
    print("OK ✅ internal include public include onune eklendi")
    raise SystemExit(0)

fallback = "location / {"
if fallback in text:
    text = text.replace(
        fallback,
        internal_include + "\n\n    " + fallback,
        1,
    )
    site.write_text(text)
    print("OK ✅ internal include fallback location onune eklendi")
    raise SystemExit(0)

raise SystemExit("HATA ❌ include eklenecek uygun nokta bulunamadi")
PY
fi

echo
echo "===== STEP 5 - NGINX TEST ====="
nginx -t
echo "OK ✅ nginx test tamam"

echo
echo "===== STEP 6 - NGINX RELOAD ====="
systemctl reload nginx
echo "OK ✅ nginx reload tamam"

echo
echo "===== STEP 7 - CANLI TEST ====="
REPORT_DIR="/root/pix2pi/pix2pi-SaaS/reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/gw_ingress_4_${TS}.txt"
LATEST_FILE="$REPORT_DIR/gw_ingress_4_latest.txt"

{
  echo "GW INGRESS 4 REPORT"
  echo "Tarih: $(date '+%F %T %z')"
  echo "Aktif site: $SITE_REAL"
  echo

  echo "--- /health/live ---"
  curl -ksS -D /tmp/gw4_health_headers.txt https://pix2pi.com.tr/health/live -o /tmp/gw4_health_body.txt || true
  sed -n '1,20p' /tmp/gw4_health_headers.txt || true
  echo
  cat /tmp/gw4_health_body.txt || true
  echo
  echo

  echo "--- /api/me ---"
  curl -ksS -D /tmp/gw4_api_headers.txt https://pix2pi.com.tr/api/me -o /tmp/gw4_api_body.txt || true
  sed -n '1,20p' /tmp/gw4_api_headers.txt || true
  echo
  cat /tmp/gw4_api_body.txt || true
  echo
  echo

  echo "--- /internal/routes ---"
  curl -ksS -D /tmp/gw4_internal_headers.txt https://pix2pi.com.tr/internal/routes -o /tmp/gw4_internal_body.txt || true
  sed -n '1,20p' /tmp/gw4_internal_headers.txt || true
  echo
  cat /tmp/gw4_internal_body.txt || true
  echo
  echo "--- SON KONTROL ---"
  grep -n "pix2pi_gateway_internal_block.conf" "$SITE_REAL" || true
} | tee "$REPORT_FILE"

cp "$REPORT_FILE" "$LATEST_FILE"

echo
echo "===== STEP 8 - BEKLENEN OZET ====="
if grep -q "HTTP/1.1 200" /tmp/gw4_health_headers.txt; then
  echo "OK ✅ health_live = 200"
else
  echo "HATA ❌ health_live 200 degil"
fi

if grep -q "HTTP/1.1 401" /tmp/gw4_api_headers.txt; then
  echo "OK ✅ api_me = 401"
else
  echo "HATA ❌ api_me 401 degil"
fi

if grep -q "HTTP/1.1 404" /tmp/gw4_internal_headers.txt; then
  echo "OK ✅ internal_routes = 404"
else
  echo "HATA ❌ internal_routes 404 degil"
fi

if grep -qi "X-Ingress-Policy: public-internal-deny" /tmp/gw4_internal_headers.txt; then
  echo "OK ✅ internal ingress policy header geldi"
else
  echo "HATA ❌ internal ingress policy header gelmedi"
fi

echo
echo "OK ✅ GW-INGRESS-4 bitti"
