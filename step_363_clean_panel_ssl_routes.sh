#!/bin/bash
set -e

echo "=== STEP 363 / CLEAN PANEL SSL ROUTES ==="

SSL_FILE="/etc/nginx/sites-available/pix2pi_ssl"

echo
echo "1. backup aliniyor..."
cp "$SSL_FILE" "${SSL_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
echo "OK ✅ backup"

echo
echo "2. duplicate route bloklari temizleniyor..."
python3 - <<'PY'
from pathlib import Path
import re

p = Path("/etc/nginx/sites-available/pix2pi_ssl")
text = p.read_text()

patterns = [
    r'\n\s*location\s*=\s*/watchdog-health\s*\{.*?\n\s*\}\n',
    r'\n\s*location\s*=\s*/service-status\.json\s*\{.*?\n\s*\}\n',
]

for pat in patterns:
    text = re.sub(pat, '\n', text, flags=re.S)

p.write_text(text)
PY
echo "OK ✅ eski bloklar temizlendi"

echo
echo "3. sadece service-status.json exact route ekleniyor..."
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

"""

marker = "listen 443 ssl;"
idx = text.find(marker)
if idx == -1:
    raise SystemExit("LISTEN_443_SSL_BULUNAMADI")

insert_pos = text.find("\n", idx)
if insert_pos == -1:
    raise SystemExit("INSERT_POS_BULUNAMADI")

text = text[:insert_pos+1] + block + text[insert_pos+1:]
p.write_text(text)
PY
echo "OK ✅ service-status exact route eklendi"

echo
echo "4. nginx test..."
nginx -t
echo "OK ✅ nginx test"

echo
echo "5. nginx reload..."
systemctl reload nginx
echo "OK ✅ nginx reload"

echo
echo "6. local ssl test..."
curl -k -I https://127.0.0.1/service-status.json
echo "OK ✅ local ssl header"

echo
echo "7. public ssl header test..."
curl -k -I https://panel.pix2pi.com.tr/service-status.json
echo "OK ✅ public ssl header"

echo
echo "8. public body preview..."
curl -k -s https://panel.pix2pi.com.tr/service-status.json | head -c 220
echo
echo "OK ✅ public body"

echo
echo "9. jq test..."
curl -k -s https://panel.pix2pi.com.tr/service-status.json | jq '.services | length'
echo "OK ✅ jq test"

echo
echo "=== STEP 363 TAMAM ✅ ==="
