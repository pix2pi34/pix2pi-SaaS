#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 14.2.3 restore drill execution plan."
echo "14.2.3 does not execute restore."
exit 99

# FAZ 4 / 14.2.3 - Restore Drill Execution Plan
# Generated at: 2026-04-27 13:55:25 +0300
# This file is intentionally blocked by exit 99 above.
# Actual execution belongs to FAZ 4 / 14.2.4.

export RESTORE_DRILL_PASSWORD="${RESTORE_DRILL_PASSWORD:?set RESTORE_DRILL_PASSWORD before restore drill}"

SANDBOX_CONTAINER="pix2pi_pg_restore_drill_14_2_4"
SANDBOX_VOLUME="pix2pi_pg_restore_drill_14_2_4_data"
SANDBOX_IMAGE="postgres:16"
SANDBOX_DB="pix2pi_restore_drill"
SANDBOX_USER="pix2pi_restore"
SANDBOX_PORT="55433"
SOURCE_DUMP_FILE="./backups/db/logical/phase4_14_2_2_20260427_135150/pix2pi_schema_only.dump"
SANDBOX_DUMP_PATH="/tmp/pix2pi_schema_only.dump"

docker rm -f "$SANDBOX_CONTAINER" 2>/dev/null || true
docker volume rm "$SANDBOX_VOLUME" 2>/dev/null || true
docker volume create "$SANDBOX_VOLUME"

docker run -d \
  --name "$SANDBOX_CONTAINER" \
  -e POSTGRES_USER="$SANDBOX_USER" \
  -e POSTGRES_PASSWORD="$RESTORE_DRILL_PASSWORD" \
  -e POSTGRES_DB="$SANDBOX_DB" \
  -p "127.0.0.1:$SANDBOX_PORT:5432" \
  -v "$SANDBOX_VOLUME:/var/lib/postgresql/data" \
  "$SANDBOX_IMAGE"

for i in $(seq 1 30); do
  if docker exec -e PGPASSWORD="$RESTORE_DRILL_PASSWORD" "$SANDBOX_CONTAINER" \
    psql -U "$SANDBOX_USER" -d "$SANDBOX_DB" -Atqc "select 1;" >/dev/null 2>&1; then
    echo "SANDBOX_DB_READY=YES"
    break
  fi
  sleep 1
done

docker cp "$SOURCE_DUMP_FILE" "$SANDBOX_CONTAINER:$SANDBOX_DUMP_PATH"

docker exec -e PGPASSWORD="$RESTORE_DRILL_PASSWORD" "$SANDBOX_CONTAINER" \
  pg_restore \
    -U "$SANDBOX_USER" \
    -d "$SANDBOX_DB" \
    --no-owner \
    --no-privileges \
    "$SANDBOX_DUMP_PATH"

docker exec -e PGPASSWORD="$RESTORE_DRILL_PASSWORD" "$SANDBOX_CONTAINER" \
  psql -U "$SANDBOX_USER" -d "$SANDBOX_DB" -Atqc \
  "select count(*) from information_schema.tables where table_schema not in ('pg_catalog','information_schema');"

# Cleanup command after evidence:
# docker rm -f "$SANDBOX_CONTAINER"
# docker volume rm "$SANDBOX_VOLUME"
