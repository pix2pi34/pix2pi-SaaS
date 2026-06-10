#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/root/pix2pi/pix2pi-SaaS"
ACTIVE_LINK="/etc/nginx/sites-enabled/pix2pi_ssl"
PUBLIC_SNIPPET="/etc/nginx/snippets/pix2pi_gateway_public.conf"
INTERNAL_SNIPPET="/etc/nginx/snippets/pix2pi_gateway_internal_block.conf"

echo "===== STEP 1 - AKTIF SITE BUL ====="
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
BACKUP_DIR="$ROOT_DIR/backups/nginx_gateway_internal_fix/$TS"
mkdir -p "$BACKUP_DIR"

cp "$SITE_REAL" "$BACKUP_DIR/$(basename "$SITE_REAL").bak"
if [ -f "$PUBLIC_SNIPPET" ]; then
  cp "$PUBLIC_SNIPPET" "$BACKUP_DIR/$(basename "$PUBLIC_SNIPPET").bak"
fi
if [ -f "$INTERNAL_SNIPPET" ]; then
  cp "$INTERNAL_SNIPPET" "$BACKUP_DIR/$(basename "$INTERNAL_SNIPPET").bak"
fi

echo "OK ✅ yedek alindi: $BACKUP_DIR"

echo
echo "===== STEP 3 - ESKI INTERNAL LOCATION TEMIZLE ====="
SITE_REAL_ENV="$SITE_REAL" PUBLIC_SNIPPET_ENV="$PUBLIC_SNIPPET" python3 <<'PY'
import os
import re
from pathlib import Path

targets = [
    Path(os.environ["SITE_REAL_ENV"]),
    Path(os.environ["PUBLIC_SNIPPET_ENV"]),
]

pattern = re.compile(r'^\s*location\s+(?:\^~\s+)?/internal/\s*\{')

def remove_internal_locations(text: str):
    lines = text.splitlines(True)
    out = []
    removed = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        if pattern.match(line):
            removed += 1
            balance = line.count("{") - line.count("}")
            i += 1
            while i < len(lines) and balance > 0:
                balance += lines[i].count("{") - lines[i].count("}")
                i += 1
            while i < len(lines) and lines[i].strip() == "":
                i += 1
            continue
        out.append(line)
        i += 1
    return "".join(out), removed

for path in targets:
    if not path.exists():
        continue
    text = path.read_text()
    cleaned, removed = remove_internal_locations(text)
    if path.name == "pix2pi_ssl":
        cleaned = cleaned.replace(
            "include /etc/nginx/snippets/pix2pi_gateway_internal_block.conf;\n",
            ""
        )
    path.write_text(cleaned)
    print(f"OK ✅ {path} icinden temizlenen internal location sayisi: {removed}")
PY

echo
echo "===== STEP 4 - CANONICAL INTERNAL BLOCK YAZ ====="
cat <<'SNIPPET' > "$INTERNAL_SNIPPET"
location ^~ /internal/ {
    default_type application/json;
    add_header Cache-Control "no-store" always;
    add_header X-Ingress-Policy "public-internal-deny" always;
    return 404 '{"status":"error","source":"nginx","code":"public_internal_route_blocked","message":"public domain uzerinden internal route kapali"}';
}
SNIPPET

echo "OK ✅ canonical internal block snippet yazildi"

echo
echo "===== STEP 5 - INCLUDE SATIRINI TEKIL EKLE ====="
SITE_REAL_ENV="$SITE_REAL" python3 <<'PY'
import os
from pathlib import Path

site = Path(os.environ["SITE_REAL_ENV"])
text = site.read_text()

internal_include = "include /etc/nginx/snippets/pix2pi_gateway_internal_block.conf;"
public_include = "include /etc/nginx/snippets/pix2pi_gateway_public.conf;"

text = text.replace(internal_include + "\n", "")
text = text.replace(internal_include, "")

if public_include in text:
    text = text.replace(
        public_include,
        internal_include + "\n    " + public_include,
        1,
    )
    site.write_text(text)
    print("OK ✅ internal include public include onune tekil eklendi")
else:
    fallback = "location / {"
    if fallback in text:
        text = text.replace(
            fallback,
            internal_include + "\n\n    " + fallback,
            1,
        )
        site.write_text(text)
        print("OK ✅ internal include fallback onune tekil eklendi")
    else:
        raise SystemExit("HATA ❌ include eklenecek uygun nokta bulunamadi")
PY

echo
echo "===== STEP 6 - HIZLI KONTROL ====="
grep -nE 'location\s+(\^~\s+)?/internal/' "$SITE_REAL" "$PUBLIC_SNIPPET" "$INTERNAL_SNIPPET" || true
echo "OK ✅ hizli kontrol tamam"

echo
echo "===== STEP 7 - NGINX TEST ====="
nginx -t
echo "OK ✅ nginx test tamam"

echo
echo "===== STEP 8 - NGINX RELOAD ====="
systemctl reload nginx
echo "OK ✅ nginx reload tamam"

echo
echo "===== STEP 9 - CANLI TEST ====="
REPORT_DIR="$ROOT_DIR/reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/gw_ingress_4_fix_${TS}.txt"
LATEST_FILE="$REPORT_DIR/gw_ingress_4_fix_latest.txt"

{
  echo "GW INGRESS 4 FIX REPORT"
  echo "Tarih: $(date '+%F %T %z')"
  echo "Aktif site: $SITE_REAL"
  echo

  echo "--- /health/live ---"
  curl -ksS -D /tmp/gw4fix_health_headers.txt https://pix2pi.com.tr/health/live -o /tmp/gw4fix_health_body.txt || true
  sed -n '1,20p' /tmp/gw4fix_health_headers.txt || true
  echo
  cat /tmp/gw4fix_health_body.txt || true
  echo
  echo

  echo "--- /api/me ---"
  curl -ksS -D /tmp/gw4fix_api_headers.txt https://pix2pi.com.tr/api/me -o /tmp/gw4fix_api_body.txt || true
  sed -n '1,20p' /tmp/gw4fix_api_headers.txt || true
  echo
  cat /tmp/gw4fix_api_body.txt || true
  echo
  echo

  echo "--- /internal/routes ---"
  curl -ksS -D /tmp/gw4fix_internal_headers.txt https://pix2pi.com.tr/internal/routes -o /tmp/gw4fix_internal_body.txt || true
  sed -n '1,20p' /tmp/gw4fix_internal_headers.txt || true
  echo
  cat /tmp/gw4fix_internal_body.txt || true
  echo
} | tee "$REPORT_FILE"

cp "$REPORT_FILE" "$LATEST_FILE"

echo
echo "===== STEP 10 - BEKLENEN OZET ====="
if grep -q "HTTP/1.1 200" /tmp/gw4fix_health_headers.txt; then
  echo "OK ✅ health_live = 200"
else
  echo "HATA ❌ health_live 200 degil"
fi

if grep -q "HTTP/1.1 401" /tmp/gw4fix_api_headers.txt; then
  echo "OK ✅ api_me = 401"
else
  echo "HATA ❌ api_me 401 degil"
fi

if grep -q "HTTP/1.1 404" /tmp/gw4fix_internal_headers.txt; then
  echo "OK ✅ internal_routes = 404"
else
  echo "HATA ❌ internal_routes 404 degil"
fi

if grep -qi "X-Ingress-Policy: public-internal-deny" /tmp/gw4fix_internal_headers.txt; then
  echo "OK ✅ ingress policy header geldi"
else
  echo "HATA ❌ ingress policy header gelmedi"
fi

if grep -qi 'public_internal_route_blocked' /tmp/gw4fix_internal_body.txt; then
  echo "OK ✅ internal JSON body dogru"
else
  echo "HATA ❌ internal JSON body dogru degil"
fi

echo
echo "OK ✅ GW-INGRESS-4-FIX bitti"
