#!/bin/bash
set -e

echo "===== SITES-ENABLED ====="
ls -l /etc/nginx/sites-enabled

echo
echo "===== TEMIZLENIYOR ====="

# sadece pix2pi_ssl kalsın
find /etc/nginx/sites-enabled -type l ! -name "pix2pi_ssl" -exec rm -f {} \;

echo "OK ✅ sadece pix2pi_ssl birakildi"

echo
echo "===== KONTROL ====="
ls -l /etc/nginx/sites-enabled

nginx -t
systemctl reload nginx

echo
echo "===== TEST ====="
curl -s http://127.0.0.1/internal/service-monitor
echo
echo
echo "OK ✅ duplicate nginx config temizlendi"
