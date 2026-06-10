#!/bin/bash
set -e

echo "=== STEP 362 / PANEL SSL SERVICE STATUS FIX ==="

SSL_FILE="/etc/nginx/sites-available/pix2pi_ssl"

echo
echo "1. backup..."
cp "$SSL_FILE" "${SSL_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
echo "OK ✅ backup"

echo
echo "2. mevcut service-status bloklari temizleniyor..."
python3 - <<'PY'
from pathlib import Path
import re

p = Path("/etc/nginx/sites-available/pix2pi_ssl")
text = p.read_text()

text = re.sub(
    r'\n\s*# SERVICE STATUS \(panel safe endpoint\)\n\s*location = /service-status\.json \{.*?\n\s*\}\n',
    '\n',
    text,
    flags=re.S
)

p.write_text(text)
PY
echo "OK ✅ eski blok temizlendi"

echo
echo "3. panel ssl server icine exact route inject ediliyor..."
python3 - <<'PY'
from pathlib import Path

p = Path("/etc/nginx/sites-available/pix2pi_ssl")
text = p.read_text()

block = """
    location = /service-status.json {
        proxy_pass http://127.0.0.1:8090/status;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 5s;
        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
        default_type application/json;
    }

    location = /watchdog-health {
        proxy_pass http://127.0.0.1:8090/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
"""

marker = "listen 443 ssl;"
idx = text.find(marker)
if idx == -1:
    raise SystemExit("LISTEN_443_MARKER_BULUNAMADI")

insert_pos = text.find("\n", idx)
if insert_pos == -1:
    raise SystemExit("INSERT_POS_BULUNAMADI")

text = text[:insert_pos+1] + block + text[insert_pos+1:]
p.write_text(text)
PY
echo "OK ✅ ssl route eklendi"

echo
echo "4. nginx test..."
nginx -t
echo "OK ✅ nginx test"

echo
echo "5. reload..."
systemctl reload nginx
echo "OK ✅ reload"

echo
echo "6. public header test..."
curl -k -I https://panel.pix2pi.com.tr/service-status.json
echo "OK ✅ header test"

echo
echo "7. public body test..."
curl -k -s https://panel.pix2pi.com.tr/service-status.json | head -c 200
echo
echo "OK ✅ body test"

echo
echo "8. jq test..."
curl -k -s https://panel.pix2pi.com.tr/service-status.json | jq '.services | length'
echo "OK ✅ jq test"

echo
echo "=== TAMAM ✅ STEP 362 ==="
