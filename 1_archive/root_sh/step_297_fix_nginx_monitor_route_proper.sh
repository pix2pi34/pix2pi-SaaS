#!/bin/bash
set -e

TARGET="/etc/nginx/sites-enabled/pix2pi_ssl"
BACKUP="/etc/nginx/sites-enabled/pix2pi_ssl.bak_fix_$(date +%Y%m%d_%H%M%S)"

cp "$TARGET" "$BACKUP"
echo "OK ✅ yedek alindi -> $BACKUP"

python3 <<'PYEOF'
from pathlib import Path

p = Path("/etc/nginx/sites-enabled/pix2pi_ssl")
text = p.read_text()

bad_block = r'''
    location /internal/service-monitor {
        proxy_pass http://127.0.0.1:9016/status;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
'''

# onceki hatali eklemeyi temizle
text = text.replace(bad_block, "\n")

insert_block = '''
    location /internal/service-monitor {
        proxy_pass http://127.0.0.1:9016/status;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /internal/service-watchdog-health {
        proxy_pass http://127.0.0.1:9016/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

'''

marker = '''    location / {
        root /opt/pix2pi/nginx;
        index panel_index.html;
        try_files $uri $uri/ /panel_index.html;
    }'''

if insert_block not in text:
    if marker in text:
        text = text.replace(marker, insert_block + marker, 1)
    else:
        raise SystemExit("HATA: panel server blogundaki location / marker bulunamadi")

p.write_text(text)
print("OK ✅ route dogru server bloguna eklendi")
PYEOF

nginx -t
systemctl reload nginx

echo
echo "=== WATCHDOG HEALTH TEST ==="
curl -s http://127.0.0.1/internal/service-watchdog-health
echo
echo
echo "=== WATCHDOG STATUS TEST ==="
curl -s http://127.0.0.1/internal/service-monitor
echo
echo
echo "OK ✅ nginx monitor route duzeltildi"
