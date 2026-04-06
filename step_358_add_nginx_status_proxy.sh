#!/bin/bash
set -e

echo "1. backup..."
cp /etc/nginx/sites-available/pix2pi /etc/nginx/sites-available/pix2pi.bak_$(date +%Y%m%d_%H%M%S)
echo "OK ✅ backup"

echo
echo "2. watchdog snippet yaziliyor..."
cat <<'SNIPPET' > /etc/nginx/snippets/pix2pi_watchdog.conf
location /status {
    proxy_pass http://127.0.0.1:8090/status;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_connect_timeout 2s;
    proxy_read_timeout 5s;
}
SNIPPET
echo "OK ✅ snippet yazildi"

echo
echo "3. include ekleniyor..."
if ! grep -q 'include /etc/nginx/snippets/pix2pi_watchdog.conf;' /etc/nginx/sites-available/pix2pi; then
python3 - <<'PY'
from pathlib import Path
p = Path('/etc/nginx/sites-available/pix2pi')
txt = p.read_text()
needle = 'server_name '
idx = txt.find(needle)
if idx == -1:
    raise SystemExit('HATA: server block icinde uygun yer bulunamadi')
line_end = txt.find('\n', idx)
insert = '\n    include /etc/nginx/snippets/pix2pi_watchdog.conf;'
txt = txt[:line_end+1] + insert + txt[line_end+1:]
p.write_text(txt)
PY
fi
echo "OK ✅ include eklendi"

echo
echo "4. nginx test..."
nginx -t
echo "OK ✅ nginx test"

echo
echo "5. reload..."
systemctl reload nginx
echo "OK ✅ nginx reload"

echo
echo "6. test..."
curl -k https://127.0.0.1/status | head -c 300
echo
echo "OK ✅ step 358 tamam"
