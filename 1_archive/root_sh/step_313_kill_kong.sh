#!/bin/bash
set -e

echo "=== KONG KAPATILIYOR ==="

systemctl stop kong || true
systemctl disable kong || true

echo "OK ✅ kong service durduruldu"

echo "=== tum openresty/nginx olduruluyor ==="
pkill -f openresty || true
pkill -9 nginx || true

sleep 1

echo "=== system nginx baslatiliyor ==="
systemctl start nginx

sleep 1

echo "=== PORT DURUM ==="
ss -tulnp | grep -E "8001|8002|8007|8099" || true

echo
echo "OK 🚀 kong tamamen devre disi"
