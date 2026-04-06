#!/bin/bash
set -e

echo "=== NGINX TEST ==="
nginx -t

echo
echo "=== NGINX STOP ==="
systemctl stop nginx || true
pkill -9 nginx || true
sleep 2

echo
echo "=== PORT KONTROL (STOP SONRASI) ==="
ss -ltnp | grep -E '8002|8007|8080|443|80' || true

echo
echo "=== NGINX START ==="
systemctl start nginx
sleep 2

echo
echo "=== NGINX STATUS ==="
systemctl status nginx --no-pager -n 20 || true

echo
echo "=== PORT KONTROL (START SONRASI) ==="
ss -ltnp | grep -E '8002|8007|8080|443|80' || true

echo
echo "OK ✅ nginx hard restart bitti"
