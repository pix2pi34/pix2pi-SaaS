#!/bin/bash
set -e

rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx

echo "OK ✅ default nginx site kapatildi"
