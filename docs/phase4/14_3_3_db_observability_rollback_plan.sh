#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 14.3.3 DB observability rollback plan."
echo "14.3.3 does not execute rollback."
echo "Rollback execution belongs to a separate approved step if needed."
exit 99

# FAZ 4 / 14.3.3 - DB Observability Rollback Plan
# Generated at: 2026-04-27 16:28:34 +0300
# This file is intentionally blocked by exit 99 above.

export DB_DSN="${DB_DSN:?set DB_DSN before rollback}"
PRIMARY_CONTAINER="pix2pi_pg"

# Rollback config values written by ALTER SYSTEM:
psql "$DB_DSN" -v ON_ERROR_STOP=1 <<'SQL'
ALTER SYSTEM RESET shared_preload_libraries;
ALTER SYSTEM RESET track_io_timing;
ALTER SYSTEM RESET log_min_duration_statement;
SQL

# Controlled restart:
# docker restart "$PRIMARY_CONTAINER"

# Optional extension rollback is NOT recommended by default because it can drop statistics object references.
# If absolutely needed and approved:
# DROP EXTENSION IF EXISTS pg_stat_statements;

# Verify DB health:
# psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select 1;"
# psql "$DB_DSN" -v ON_ERROR_STOP=1 -Atqc "select pg_is_in_recovery();"
