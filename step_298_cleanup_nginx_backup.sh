#!/bin/bash
set -e

mkdir -p /root/pix2pi/nginx_backups

mv /etc/nginx/sites-enabled/pix2pi_ssl.bak_fix_* /root/pix2pi/nginx_backups/ 2>/dev/null || true
mv /etc/nginx/sites-enabled/default.bak.* /root/pix2pi/nginx_backups/ 2>/dev/null || true

echo "OK ✅ sites-enabled icindeki backup dosyalari tasindi"

nginx -t
echo "OK ✅ nginx syntax temiz"
