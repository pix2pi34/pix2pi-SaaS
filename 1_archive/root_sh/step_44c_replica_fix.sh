#!/bin/bash
set -euo pipefail

PRIMARY_CONTAINER="pix2pi_pg"
REPLICA_CONTAINER="pix2pi_pg_replica"
REPLICA_VOLUME="root_pix2pi_pg_replica_data"
REPL_USER="replicator"
REPL_PASS="replica_pass"
PRIMARY_HOST="pix2pi_pg"
PRIMARY_DB_USER="pix2pi"
PRIMARY_DB_NAME="pix2pi"
NETWORK_NAME="dev_default"

echo "=== STEP 44C-3 FIX / REPLICATOR RESET + BASEBACKUP ==="

echo
echo "1. primary tarafinda replicator reset..."
docker exec "$PRIMARY_CONTAINER" psql -U "$PRIMARY_DB_USER" -d "$PRIMARY_DB_NAME" <<EOFSQL
DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_roles WHERE rolname = '$REPL_USER'
   ) THEN
      CREATE ROLE $REPL_USER WITH REPLICATION LOGIN PASSWORD '$REPL_PASS';
   ELSE
      ALTER ROLE $REPL_USER WITH REPLICATION LOGIN PASSWORD '$REPL_PASS';
   END IF;
END
\$\$;
EOFSQL
echo "OK ✅ replicator role resetlendi"

echo
echo "2. pg_hba replication satiri kontrol..."
docker exec "$PRIMARY_CONTAINER" bash -lc "grep -n 'host replication $REPL_USER' /var/lib/postgresql/data/pg_hba.conf || true"
echo "OK ✅ pg_hba kontrol bitti"

echo
echo "3. postgres config reload..."
docker exec "$PRIMARY_CONTAINER" psql -U "$PRIMARY_DB_USER" -d "$PRIMARY_DB_NAME" -c "SELECT pg_reload_conf();"
echo "OK ✅ config reload tamam"

echo
echo "4. replicator login testi (primary ustunden TCP)..."
docker exec "$PRIMARY_CONTAINER" bash -lc "PGPASSWORD='$REPL_PASS' psql -h 127.0.0.1 -U '$REPL_USER' -d postgres -Atqc 'select current_user;'"
echo "OK ✅ replicator login testi basarili"

echo
echo "5. replica container stop..."
docker stop "$REPLICA_CONTAINER"
echo "OK ✅ replica container durdu"

echo
echo "6. replica volume temizleniyor..."
docker run --rm \
  -v "$REPLICA_VOLUME":/var/lib/postgresql/data \
  postgres:16 \
  bash -lc 'rm -rf /var/lib/postgresql/data/* /var/lib/postgresql/data/.[!.]* /var/lib/postgresql/data/..?* 2>/dev/null || true'
echo "OK ✅ replica volume temizlendi"

echo
echo "7. pg_basebackup one-shot container ile aliniyor..."
docker run --rm \
  --network "$NETWORK_NAME" \
  -e PGPASSWORD="$REPL_PASS" \
  -v "$REPLICA_VOLUME":/var/lib/postgresql/data \
  postgres:16 \
  bash -lc "pg_basebackup -h $PRIMARY_HOST -U $REPL_USER -D /var/lib/postgresql/data -P -R"
echo "OK ✅ pg_basebackup tamam"

echo
echo "8. standby sinyasi ve primary_conninfo kontrol..."
docker run --rm \
  -v "$REPLICA_VOLUME":/var/lib/postgresql/data \
  postgres:16 \
  bash -lc "ls -lah /var/lib/postgresql/data/standby.signal /var/lib/postgresql/data/postgresql.auto.conf && echo '--- postgresql.auto.conf ---' && cat /var/lib/postgresql/data/postgresql.auto.conf"
echo "OK ✅ standby dosyalari kontrol edildi"

echo
echo "9. replica container baslatiliyor..."
docker start "$REPLICA_CONTAINER"
sleep 5
echo "OK ✅ replica container basladi"

echo
echo "10. replica recovery durumu..."
docker exec "$REPLICA_CONTAINER" psql -U "$PRIMARY_DB_USER" -d "$PRIMARY_DB_NAME" -Atqc "select pg_is_in_recovery();"
echo "OK ✅ recovery kontrol bitti"

echo
echo "11. primary tarafinda replication durumu..."
docker exec "$PRIMARY_CONTAINER" psql -U "$PRIMARY_DB_USER" -d "$PRIMARY_DB_NAME" -c "SELECT application_name, client_addr, state, sync_state FROM pg_stat_replication;"
echo "OK ✅ pg_stat_replication kontrol bitti"

echo
echo "12. replica health test..."
docker exec "$REPLICA_CONTAINER" psql -U "$PRIMARY_DB_USER" -d "$PRIMARY_DB_NAME" -Atqc "select now();"
echo "OK ✅ replica query testi bitti"

echo
echo "OK ✅ STEP 44C-3 FIX tamam"
