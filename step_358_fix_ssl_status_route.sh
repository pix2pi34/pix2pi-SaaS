#!/bin/bash
set -e

CONF="/etc/nginx/sites-available/pix2pi_ssl"
BACKUP="/etc/nginx/sites-available/pix2pi_ssl.bak_$(date +%Y%m%d_%H%M%S)"

echo "1. backup aliniyor..."
cp "$CONF" "$BACKUP"
echo "OK ✅ backup: $BACKUP"

echo
echo "2. exact /status ve /watchdog-health inject ediliyor..."

python3 <<'PY'
from pathlib import Path
import re

conf = Path("/etc/nginx/sites-available/pix2pi_ssl")
text = conf.read_text()

# varsa eski exact bloklari temizle
text = re.sub(
    r'\n\s*location\s*=\s*/status\s*\{.*?\n\s*\}\n',
    '\n',
    text,
    flags=re.S
)

text = re.sub(
    r'\n\s*location\s*=\s*/watchdog-health\s*\{.*?\n\s*\}\n',
    '\n',
    text,
    flags=re.S
)

block = '''
    location = /status {
        proxy_pass http://127.0.0.1:8090/status;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location = /watchdog-health {
        proxy_pass http://127.0.0.1:8090/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
'''

m = re.search(r'(server_name\s+[^;]+;\n)', text)
if not m:
    raise SystemExit("HATA: server_name satiri bulunamadi")

idx = m.end()
text = text[:idx] + block + text[idx:]

conf.write_text(text)
PY

echo "OK ✅ ssl status route eklendi"

echo
echo "3. nginx test..."
nginx -t
echo "OK ✅ nginx test"

echo
echo "4. nginx reload..."
systemctl reload nginx
echo "OK ✅ nginx reload"

echo
echo "5. local ssl status test..."
curl -k -I https://127.0.0.1/status -H 'Host: pix2pi.com.tr'
echo
curl -k -s https://127.0.0.1/status -H 'Host: pix2pi.com.tr' | head -c 300
echo
echo "OK ✅ local ssl /status test bitti"

echo
echo "6. public status test..."
curl -I https://pix2pi.com.tr/status
echo "OK ✅ public /status test bitti"
