#!/bin/bash
set -e

echo "=== STEP 351 / NGINX DUPLICATE CLEAN + MONITOR FIX ==="

NGINX_SSL="/etc/nginx/sites-available/pix2pi_ssl"

echo
echo "1. backup aliniyor..."
cp "$NGINX_SSL" "${NGINX_SSL}.bak_$(date +%Y%m%d_%H%M%S)"
echo "OK ✅ backup alindi"

echo
echo "2. sites-enabled icindeki hatali backup/link dosyalari temizleniyor..."
find /etc/nginx/sites-enabled -maxdepth 1 \( -name "*.bak" -o -name "*.bak_*" \) -print -delete || true
echo "OK ✅ bak dosyalari temizlendi"

echo
echo "3. aktif symlink duzeltiliyor..."
rm -f /etc/nginx/sites-enabled/pix2pi_ssl
ln -sf /etc/nginx/sites-available/pix2pi_ssl /etc/nginx/sites-enabled/pix2pi_ssl
echo "OK ✅ symlink duzeltildi"

echo
echo "4. /monitor location yeniden yaziliyor..."
python3 <<'PY'
from pathlib import Path
p = Path("/etc/nginx/sites-available/pix2pi_ssl")
text = p.read_text()

start_marker = "server {\n    listen 443 ssl;\n    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;"
if start_marker not in text:
    raise SystemExit("HATA: ana ssl server block bulunamadi")

block_start = text.index(start_marker)
next_server = text.find("\nserver {", block_start + 1)
if next_server == -1:
    next_server = len(text)

block = text[block_start:next_server]

import re
block = re.sub(r'\n\s*location = /monitor \{.*?\n\s*\}\n', '\n', block, flags=re.S)

monitor_block = '''
    location = /monitor {
        root /root/pix2pi/pix2pi-SaaS/web;
        try_files /monitor.html =404;
    }

'''

insert_after = '    ssl_protocols TLSv1.2 TLSv1.3;\n'
if insert_after not in block:
    raise SystemExit("HATA: ssl_protocols satiri bulunamadi")

block = block.replace(insert_after, insert_after + monitor_block, 1)

new_text = text[:block_start] + block + text[next_server:]
p.write_text(new_text)
PY
echo "OK ✅ /monitor route yazildi"

echo
echo "5. monitor dosya kontrolu..."
mkdir -p /root/pix2pi/pix2pi-SaaS/web
if [ ! -f /root/pix2pi/pix2pi-SaaS/web/monitor.html ]; then
  cat <<'HTML' > /root/pix2pi/pix2pi-SaaS/web/monitor.html
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
fi
echo "OK ✅ monitor.html hazir"

echo
echo "6. nginx test..."
nginx -t
echo "OK ✅ nginx test gecti"

echo
echo "7. nginx reload..."
systemctl reload nginx
echo "OK ✅ nginx reload"

echo
echo "8. aktif cakisma kontrolu..."
grep -R "server_name pix2pi.com.tr" -n /etc/nginx/sites-enabled || true

echo
echo "9. local test..."
curl -k -I https://127.0.0.1/monitor || true

echo
echo "OK ✅ step 351 tamam"
