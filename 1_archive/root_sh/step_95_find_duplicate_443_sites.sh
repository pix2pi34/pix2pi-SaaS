#!/bin/bash
set -e

echo "=== 1 ENABLED SITES ==="
ls -l /etc/nginx/sites-enabled

echo
echo "=== 2 443 DINLEYEN DOSYALAR ==="
grep -RIn "listen 443" /etc/nginx/sites-available /etc/nginx/sites-enabled || true

echo
echo "=== 3 SERVER_NAME GECEN DOSYALAR ==="
grep -RIn "server_name .*pix2pi.com.tr" /etc/nginx/sites-available /etc/nginx/sites-enabled || true

echo
echo "OK ✅ duplicate 443 site kontrolu bitti"
