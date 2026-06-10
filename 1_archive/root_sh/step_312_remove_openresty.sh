#!/bin/bash
set -e

echo "=== OPENRESTY TEMIZLIK ==="

echo "1. openresty nginx durduruluyor"
pkill -f openresty || true

sleep 1

echo "2. tum nginx processleri temizleniyor"
pkill -9 nginx || true

sleep 1

echo "3. openresty klasoru backup aliniyor"
if [ -d /usr/local/openresty ]; then
  mv /usr/local/openresty /usr/local/openresty_BACKUP_$(date +%s)
  echo "OK ✅ openresty tasindi"
else
  echo "OK ✅ openresty zaten yok"
fi

echo "4. nginx temiz baslatiliyor"
systemctl start nginx

sleep 1

echo "5. aktif port kontrol"
ss -tulnp | grep -E "8001|8002|8007|8099" || true

echo
echo "OK 🚀 openresty temizlendi"
