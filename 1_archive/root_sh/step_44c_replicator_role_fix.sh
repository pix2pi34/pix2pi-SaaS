#!/bin/bash
set -euo pipefail

PRIMARY_CONTAINER="pix2pi_pg"
APP_DB_USER="pix2pi"
APP_DB_NAME="pix2pi"
REPL_USER="replicator"
REPL_PASS="replica_pass"

echo "=== STEP 44C-3G / REPLICATOR ROLE FIX ==="

echo
echo "1. mevcut roller kontrol..."
docker exec "$PRIMARY_CONTAINER" psql -U "$APP_DB_USER" -d "$APP_DB_NAME" -c "\du"
echo "OK ✅ roller listelendi"

echo
echo "2. replicator var mi kontrol..."
docker exec "$PRIMARY_CONTAINER" psql -U "$APP_DB_USER" -d "$APP_DB_NAME" -Atqc \
"select rolname || '|' || rolreplication || '|' || rolcanlogin from pg_roles where rolname='${REPL_USER}';" \
|| true
echo "OK ✅ replicator sorgulandi"

echo
echo "3. replicator role create/alter..."
docker exec "$PRIMARY_CONTAINER" psql -v ON_ERROR_STOP=1 -U "$APP_DB_USER" -d "$APP_DB_NAME" <<EOFSQL
CREATE ROLE ${REPL_USER} WITH REPLICATION LOGIN PASSWORD '${REPL_PASS}';
ALTER ROLE ${REPL_USER} WITH REPLICATION LOGIN PASSWORD '${REPL_PASS}';
EOFSQL
echo "OK ✅ create/alter komutlari calisti"

echo
echo "4. create duplicate olursa fallback alter..."
set +e
docker exec "$PRIMARY_CONTAINER" psql -v ON_ERROR_STOP=1 -U "$APP_DB_USER" -d "$APP_DB_NAME" \
-c "ALTER ROLE ${REPL_USER} WITH REPLICATION LOGIN PASSWORD '${REPL_PASS}';" \
>/tmp/step_44c_rep_alter.out 2>/tmp/step_44c_rep_alter.err
RC=$?
set -e
cat /tmp/step_44c_rep_alter.out 2>/dev/null || true
cat /tmp/step_44c_rep_alter.err 2>/dev/null || true
echo "ALTER_RC=$RC"
echo "OK ✅ fallback alter denendi"

echo
echo "5. final role kontrol..."
docker exec "$PRIMARY_CONTAINER" psql -U "$APP_DB_USER" -d "$APP_DB_NAME" -c "\du ${REPL_USER}"
docker exec "$PRIMARY_CONTAINER" psql -U "$APP_DB_USER" -d "$APP_DB_NAME" -Atqc \
"select rolname || '|' || rolreplication || '|' || rolcanlogin from pg_roles where rolname='${REPL_USER}';"
echo "OK ✅ final role kontrol bitti"

echo
echo "6. tcp login testi..."
docker exec "$PRIMARY_CONTAINER" bash -lc \
"PGPASSWORD='${REPL_PASS}' psql -h 127.0.0.1 -U '${REPL_USER}' -d postgres -Atqc 'select current_user;'"
echo "OK ✅ replicator tcp login basarili"

echo
echo "OK ✅ STEP 44C-3G tamam"
