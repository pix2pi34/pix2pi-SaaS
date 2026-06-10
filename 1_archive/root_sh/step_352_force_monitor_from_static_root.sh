#!/bin/bash
set -e

echo "=== STEP 352 / FORCE MONITOR FROM STATIC ROOT ==="

NGINX_FILE="/etc/nginx/sites-available/pix2pi_ssl"
STATIC_DIR="/opt/pix2pi/nginx"
STATIC_FILE="${STATIC_DIR}/monitor.html"

echo
echo "1. backup aliniyor..."
cp "$NGINX_FILE" "${NGINX_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
echo "OK ✅ backup alindi"

echo
echo "2. static monitor dosyasi yaziliyor..."
mkdir -p "$STATIC_DIR"
cat <<'HTML' > "$STATIC_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <title>Pix2pi Monitor</title>
</head>
<body>
  <h1>Pix2pi Monitor</h1>
  <p>monitor ok</p>
</body>
</html>
HTML
chmod 644 "$STATIC_FILE"
echo "OK ✅ monitor.html yazildi: $STATIC_FILE"

echo
echo "3. nginx route zorla duzeltiliyor..."
python3 <<'PY'
from pathlib import Path
import re

p = Path("/etc/nginx/sites-available/pix2pi_ssl")
text = p.read_text()

server_marker = """server {
    listen 443 ssl;
    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;"""

if server_marker not in text:
    raise SystemExit("HATA: ana ssl server block bulunamadi")

start = text.index(server_marker)
end = text.find("\nserver {", start + 1)
if end == -1:
    end = len(text)

block = text[start:end]

block = re.sub(r'\n\s*location\s*=\s*/monitor\s*\{.*?\n\s*\}\n', '\n', block, flags=re.S)

monitor_block = """
    location = /monitor {
        root /opt/pix2pi/nginx;
        try_files /monitor.html =404;
    }

"""

insert_after = """    ssl_protocols TLSv1.2 TLSv1.3;
"""
if insert_after not in block:
    raise SystemExit("HATA: ssl_protocols satiri bulunamadi")

block = block.replace(insert_after, insert_after + monitor_block, 1)

new_text = text[:start] + block + text[end:]
p.write_text(new_text)
PY
echo "OK ✅ /monitor route sabitlendi"

echo
echo "4. nginx test..."
nginx -t
echo "OK ✅ nginx test gecti"

echo
echo "5. nginx reload..."
systemctl reload nginx
echo "OK ✅ nginx reload"

echo
echo "6. local test..."
curl -k -I https://127.0.0.1/monitor || true

echo
echo "7. file test..."
ls -l "$STATIC_FILE"

echo
echo "OK ✅ step 352 tamam"
