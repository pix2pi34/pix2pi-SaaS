#!/bin/bash
set -e

echo "=== OPENRESTY HARD BLOCK ==="

pkill -f openresty || true
pkill -9 nginx || true

sleep 1

if [ -f /usr/local/openresty/nginx/sbin/nginx ]; then
  chmod -x /usr/local/openresty/nginx/sbin/nginx
  echo "OK ✅ openresty binary disable edildi"
fi

echo "system nginx baslatiliyor"
systemctl start nginx

sleep 1

echo "PORT DURUM"
ss -tulnp | grep -E "8001|8002|8007|8099" || true

echo "OK 🚀 openresty artik calisamaz"
