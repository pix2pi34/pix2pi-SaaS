#!/bin/bash
set -e

cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak.$(date +%F-%H%M%S)

cat <<'NGEOF' > /etc/nginx/snippets/pix2pi_watchdog.conf
location /internal/service-monitor {
    proxy_pass http://127.0.0.1:9016/status;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}

location /internal/service-watchdog-health {
    proxy_pass http://127.0.0.1:9016/health;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
NGEOF

python3 - <<'PYEOF'
from pathlib import Path

p = Path("/etc/nginx/sites-available/default")
text = p.read_text()

include_line = "include /etc/nginx/snippets/pix2pi_watchdog.conf;"

if include_line not in text:
    marker = "server_name _;"
    if marker in text:
        text = text.replace(marker, marker + "\n\n    " + include_line, 1)
    else:
        idx = text.find("server {")
        if idx == -1:
            raise SystemExit("server blogu bulunamadi")
        insert_at = text.find("\n", idx)
        text = text[:insert_at+1] + "    " + include_line + "\n" + text[insert_at+1:]

p.write_text(text)
print("OK ✅ nginx include eklendi")
PYEOF

nginx -t
systemctl reload nginx

echo "----- WATCHDOG HEALTH TEST -----"
curl -s http://127.0.0.1/internal/service-watchdog-health
echo
echo "----- WATCHDOG STATUS TEST -----"
curl -s http://127.0.0.1/internal/service-monitor
echo
echo "OK ✅ watchdog nginx proxy hazir"
