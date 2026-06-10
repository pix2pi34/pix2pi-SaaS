#!/bin/bash
set -e

rm -f /etc/nginx/sites-enabled/pix2pi

echo "=== ENABLED SITES ==="
ls -l /etc/nginx/sites-enabled

nginx -t
systemctl reload nginx

echo "OK ✅ eski pix2pi nginx sitesi kapatildi"
