#!/bin/bash

echo "=== NGINX MONITOR FIX ==="

CONF="/etc/nginx/sites-available/pix2pi_ssl"

echo "1. backup..."
cp $CONF ${CONF}.bak_$(date +%s)

echo "OK ✅ backup alindi"

echo "2. duplicate temizleniyor..."

rm -f /etc/nginx/sites-enabled/default

echo "OK ✅ default kaldırıldı"

echo "3. monitor route inject..."

# önce varsa sil
sed -i '/location = \/monitor/,/}/d' $CONF

# server block içine ekle
sed -i '/server_name/a \
\
    location = /monitor {\
        root /root/pix2pi/pix2pi-SaaS/web;\
        index monitor.html;\
    }\
' $CONF

echo "OK ✅ monitor route eklendi"

echo "4. nginx test..."

nginx -t

if [ $? -ne 0 ]; then
  echo "HATA ❌ nginx config bozuk"
  exit 1
fi

echo "5. reload..."

systemctl reload nginx

echo "OK ✅ nginx reload"

echo "6. test..."

curl -I https://pix2pi.com.tr/monitor

echo ""
echo "=== TAMAM ✅ ==="
