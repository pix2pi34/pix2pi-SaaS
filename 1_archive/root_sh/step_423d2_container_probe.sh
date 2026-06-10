#!/bin/bash
set -euo pipefail

echo "=== STEP 423D-5 / CONTAINER POSTGRES PROBE ==="

ROOT="$HOME/pix2pi/pix2pi-SaaS"
BACKUP_DIR="$ROOT/_backup/step_423d2"
mkdir -p "$BACKUP_DIR"

echo
echo "1. docker container tespiti..."
DB_CONTAINER="$(docker ps --format '{{.Names}} {{.Ports}}' | awk '/5433->5432/ {print $1; exit}')"
if [ -z "$DB_CONTAINER" ]; then
  echo "HATA ❌ 5433->5432 map edilen container bulunamadi"
  docker ps
  exit 1
fi
echo "DB_CONTAINER=$DB_CONTAINER"
echo "OK ✅ container bulundu"

echo
echo "2. container temel bilgi..."
docker ps --filter "name=$DB_CONTAINER"
echo "--- inspect image ---"
docker inspect "$DB_CONTAINER" --format 'Image={{.Config.Image}}'
echo "--- inspect user ---"
docker inspect "$DB_CONTAINER" --format 'User={{.Config.User}}'
echo "OK ✅ temel bilgi alindi"

echo
echo "3. container icinde user kontrol..."
echo "--- whoami as default user ---"
docker exec "$DB_CONTAINER" sh -lc 'whoami || id || true'
echo "--- id postgres ---"
docker exec "$DB_CONTAINER" sh -lc 'id postgres || true'
echo "--- getent passwd postgres ---"
docker exec "$DB_CONTAINER" sh -lc 'getent passwd postgres || cat /etc/passwd | grep postgres || true'
echo "OK ✅ user kontrol bitti"

echo
echo "4. psql binary kontrol..."
docker exec "$DB_CONTAINER" sh -lc 'command -v psql || find / -name psql 2>/dev/null | head'
echo "OK ✅ psql binary kontrol bitti"

echo
echo "5. postgres user ile psql denemesi..."
set +e
docker exec -u postgres "$DB_CONTAINER" psql -d postgres -Atqc "select current_user;" >/tmp/step_423d2_psql.out 2>/tmp/step_423d2_psql.err
RC1=$?
set -e
echo "RC1=$RC1"
echo "--- stdout ---"
cat /tmp/step_423d2_psql.out 2>/dev/null || true
echo
echo "--- stderr ---"
cat /tmp/step_423d2_psql.err 2>/dev/null || true

echo
echo "6. default user ile psql denemesi..."
set +e
docker exec "$DB_CONTAINER" sh -lc 'psql -U postgres -d postgres -Atqc "select current_user;"' >/tmp/step_423d2_default_psql.out 2>/tmp/step_423d2_default_psql.err
RC2=$?
set -e
echo "RC2=$RC2"
echo "--- stdout ---"
cat /tmp/step_423d2_default_psql.out 2>/dev/null || true
echo
echo "--- stderr ---"
cat /tmp/step_423d2_default_psql.err 2>/dev/null || true

echo
echo "7. env kontrol..."
docker inspect "$DB_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -E 'POSTGRES_|PGDATA|POSTGRES_DB' || true
echo "OK ✅ env kontrol bitti"

echo
echo "8. sonuc..."
if [ "${RC1:-1}" -eq 0 ] || [ "${RC2:-1}" -eq 0 ]; then
  echo "OK ✅ container icinden psql erisimi var"
else
  echo "HATA ❌ container icinden psql erisimi basarisiz"
fi
