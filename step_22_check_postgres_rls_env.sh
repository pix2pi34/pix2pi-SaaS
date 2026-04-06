#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== 1 DOSYA KONTROL ==="
ls -lah deploy/sql/rls_tenant_policy.sql
echo
sed -n '1,220p' deploy/sql/rls_tenant_policy.sql

echo
echo "=== 2 ENV KONTROL ==="
if [ -f .env ]; then
  echo "OK ✅ .env bulundu"
  grep -E '^(DB_NAME|DB_USER|DB_HOST|DB_PORT|POSTGRES_DB|POSTGRES_USER|POSTGRES_HOST|POSTGRES_PORT)=' .env || true
else
  echo "HATA ❌ .env bulunamadi"
fi

echo
echo "=== 3 POSTGRES PROCESS / CONTAINER KONTROL ==="
ps aux | grep postgres | grep -v grep || true
echo
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}' || true

echo
echo "=== 4 PORT 5432 KONTROL ==="
ss -ltnp | grep 5432 || true

echo
echo "=== 5 PG ISREADY KONTROL ==="
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
echo "OK ✅ postgres rls ortam kontrolu bitti"
