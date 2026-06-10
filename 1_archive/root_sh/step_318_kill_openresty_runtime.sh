#!/bin/bash
set -e

echo "=== OPENRESTY RUNTIME KILL ==="

echo "1. openresty nginx PID bulunuyor..."
PIDS=$(ps -ef | grep "/usr/local/openresty/nginx" | grep -v grep | awk '{print $2}')

if [ -z "$PIDS" ]; then
  echo "OK ✅ openresty zaten yok"
else
  echo "PIDLER: $PIDS"
  echo "$PIDS" | xargs kill -9
  echo "OK ✅ openresty kill edildi"
fi

echo
echo "2. kong prefix temizleniyor..."
rm -rf /usr/local/kong || true
echo "OK ✅ kong klasoru silindi"

echo
echo "3. openresty binary kontrol..."
rm -rf /usr/local/openresty || true
echo "OK ✅ openresty silindi"

echo
echo "4. port kontrol..."
ss -ltnp | grep -E '8001|8002|8007' || echo "OK ✅ bu portlar artik yok"

echo
echo "5. nginx restart (temiz state)..."
systemctl restart nginx

echo
echo "=== FINAL CHECK ==="
ps -ef | grep nginx | grep -v grep
echo
ss -ltnp | grep -E '8001|8002|8007' || echo "OK ✅ SISTEM TEMIZ"

echo
echo "OK 🚀 openresty tamamen temizlendi"
