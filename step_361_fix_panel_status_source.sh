#!/bin/bash
set -e

echo "=== STEP 361 / PANEL STATUS SOURCE FIX ==="

PANEL_NGINX="/etc/nginx/sites-available/pix2pi"
WATCHDOG_SNIPPET="/etc/nginx/snippets/pix2pi_watchdog.conf"
STATIC_DIR="/opt/pix2pi/nginx"

PANEL_HTML=""
if [ -f "$STATIC_DIR/panel.html" ]; then
  PANEL_HTML="$STATIC_DIR/panel.html"
elif [ -f "$STATIC_DIR/status.html" ]; then
  PANEL_HTML="$STATIC_DIR/status.html"
else
  PANEL_HTML="$(grep -Rsl 'Pix2pi Admin Panel' "$STATIC_DIR" 2>/dev/null | head -n 1 || true)"
fi

if [ -z "$PANEL_HTML" ]; then
  echo "HATA ❌ panel html bulunamadi"
  exit 1
fi

echo "1. backup aliniyor..."
cp "$PANEL_NGINX" "${PANEL_NGINX}.bak_$(date +%Y%m%d_%H%M%S)"
cp "$PANEL_HTML" "${PANEL_HTML}.bak_$(date +%Y%m%d_%H%M%S)"
echo "OK ✅ backup alindi"
echo "NGINX: $PANEL_NGINX"
echo "HTML : $PANEL_HTML"

echo
echo "2. panel icin exact json route ekleniyor..."
python3 - <<'PY'
from pathlib import Path

p = Path("/etc/nginx/sites-available/pix2pi")
text = p.read_text()

marker = "include /etc/nginx/snippets/pix2pi_watchdog.conf;"
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
    }
"""

if "location = /service-status.json" not in text:
    if marker in text:
        text = text.replace(marker, marker + "\n" + block, 1)
    else:
        raise SystemExit("NGINX_MARKER_BULUNAMADI")

p.write_text(text)
PY
echo "OK ✅ /service-status.json eklendi"

echo
echo "3. panel html fetch kaynagi duzeltiliyor..."
python3 - <<'PY'
from pathlib import Path
import re

html_path = Path("'"$PANEL_HTML"'")
text = html_path.read_text()

replacements = [
    (r'fetch\("http://127\.0\.0\.1:8090/status"\s*,', 'fetch("/service-status.json",'),
    (r"fetch\('http://127\.0\.0\.1:8090/status'\s*,", "fetch('/service-status.json',"),
    (r'fetch\("https://pix2pi\.com\.tr/status"\s*,', 'fetch("/service-status.json",'),
    (r"fetch\('https://pix2pi\.com\.tr/status'\s*,", "fetch('/service-status.json',"),
    (r'fetch\("/status"\s*,', 'fetch("/service-status.json",'),
    (r"fetch\('/status'\s*,", "fetch('/service-status.json',"),
    (r'fetch\("http://127\.0\.0\.1:8090/status"\)', 'fetch("/service-status.json")'),
    (r"fetch\('http://127\.0\.0\.1:8090/status'\)", "fetch('/service-status.json')"),
    (r'fetch\("https://pix2pi\.com\.tr/status"\)', 'fetch("/service-status.json")'),
    (r"fetch\('https://pix2pi\.com\.tr/status'\)", "fetch('/service-status.json')"),
    (r'fetch\("/status"\)', 'fetch("/service-status.json")'),
    (r"fetch\('/status'\)", "fetch('/service-status.json')"),
]

new_text = text
changed = False
for pattern, repl in replacements:
    newer = re.sub(pattern, repl, new_text)
    if newer != new_text:
        new_text = newer
        changed = True

if not changed:
    newer = re.sub(r'fetch\([^)]*status[^)]*\)', 'fetch("/service-status.json")', new_text, count=1)
    if newer != new_text:
        new_text = newer
        changed = True

if not changed:
    raise SystemExit("PANEL_FETCH_PATCH_BULUNAMADI")

html_path.write_text(new_text)
PY
echo "OK ✅ panel fetch duzeltildi"

echo
echo "4. nginx test..."
nginx -t
echo "OK ✅ nginx test"

echo
echo "5. nginx reload..."
systemctl reload nginx
echo "OK ✅ nginx reload"

echo
echo "6. local json test..."
curl -s http://127.0.0.1/service-status.json | jq '.services | length'
echo "OK ✅ local json test"

echo
echo "7. public json test..."
curl -k -s https://panel.pix2pi.com.tr/service-status.json | jq '.services | length'
echo "OK ✅ public json test"

echo
echo "8. html kontrol..."
grep -n "service-status.json" "$PANEL_HTML" || true
echo "OK ✅ html kontrol"

echo
echo "=== TAMAM ✅ STEP 361 ==="
