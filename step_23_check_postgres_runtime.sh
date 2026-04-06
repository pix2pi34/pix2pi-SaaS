#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== 1 ENV ==="
if [ -f .env ]; then
  echo "OK ✅ .env bulundu"
  grep -E '^(DB_NAME|DB_USER|DB_HOST|DB_PORT|POSTGRES_DB|POSTGRES_USER|POSTGRES_HOST|POSTGRES_PORT)=' .env || true
else
  echo "HATA ❌ .env bulunamadi"
fi

echo
echo "=== 2 PORT 5432 ==="
ss -ltnp | grep 5432 || true

echo
echo "=== 3 DOCKER PS ==="
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}' || true

echo
echo "=== 4 COMPOSE DOSYALARI ==="
find . -maxdepth 3 \( -name 'docker-compose.yml' -o -name 'compose.yml' -o -name 'docker-compose.yaml' \) | sort || true

echo
echo "=== 5 SYSTEMD POSTGRES ==="
systemctl status postgresql --no-pager || true

echo
echo "=== 6 PG_ISREADY ==="
if command -v pg_isready >/dev/null 2>&1; then
  DB_HOST_VAL="$(grep -E '^DB_HOST=' .env 2>/dev/null | tail -n1 | cut -d= -f2-)"
  DB_PORT_VAL="$(grep -E '^DB_PORT=' .env 2>/dev/null | tail -n1 | cut -d= -f2-)"
  DB_HOST_VAL="${DB_HOST_VAL:-localhost}"
  DB_PORT_VAL="${DB_PORT_VAL:-5432}"
  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
else
  echo "pg_isready yok"
fi

echo
echo "OK ✅ postgres runtime kontrolu bitti"
