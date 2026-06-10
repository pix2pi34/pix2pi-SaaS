#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 14.3.3 DB observability config patch candidate."
echo "14.3.3 does not change PostgreSQL config."
echo "Actual controlled apply belongs to FAZ 4 / 14.3.4."
exit 99

# FAZ 4 / 14.3.3 - DB Observability Config Patch Candidate
# Generated at: 2026-04-27 16:28:34 +0300
# This file is intentionally blocked by exit 99 above.

export DB_DSN="${DB_DSN:?set DB_DSN before apply}"
PRIMARY_CONTAINER="pix2pi_pg"
PRIMARY_IMAGE="postgres:16"
PRIMARY_DB="pix2pi"
PRIMARY_PORT="5433"

# Fresh safety backup before apply:
# bash scripts/phase4_logical_backup_smoke.sh .
# restic backup command should be run according to current backup policy.

# Candidate config patch method:
# ALTER SYSTEM writes to postgresql.auto.conf under PGDATA.
# A restart is required for shared_preload_libraries.
psql "$DB_DSN" -v ON_ERROR_STOP=1 <<'SQL'
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET track_io_timing = 'on';
ALTER SYSTEM SET log_min_duration_statement = '1000';
SQL

# Controlled maintenance restart:
# docker restart "$PRIMARY_CONTAINER"

# After restart verification:
# psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show shared_preload_libraries;"
# psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show track_io_timing;"
# psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "show log_min_duration_statement;"

# Extension create after preload is active:
psql "$DB_DSN" -v ON_ERROR_STOP=1 <<'SQL'
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SQL

# Final verification:
# psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select exists(select 1 from pg_extension where extname='pg_stat_statements');"
