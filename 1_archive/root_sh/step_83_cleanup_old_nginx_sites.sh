#!/bin/bash
set -e

rm -f /etc/nginx/sites-enabled/pix2pi_test || true
rm -f /etc/nginx/sites-available/pix2pi_test || true
rm -f /etc/nginx/sites-enabled/default || true

nginx -t
systemctl reload nginx

echo "OK ✅ eski nginx test siteleri temizlendi"
