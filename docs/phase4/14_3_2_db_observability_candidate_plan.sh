#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 14.3.2 DB observability candidate plan."
echo "14.3.2 gate does not change PostgreSQL config."
echo "Actual config change must be done in a separate approved apply step."
exit 99

# FAZ 4 / 14.3.2 - DB Observability Candidate Plan
# Generated at: 2026-04-27 16:21:58 +0300
# This file is intentionally blocked by exit 99 above.

PRIMARY_CONTAINER="pix2pi_pg"
PRIMARY_IMAGE="postgres:16"
PRIMARY_DB="pix2pi"
PRIMARY_PORT="5433"

# Current observed values:
# shared_preload_libraries=
# pg_stat_statements_preload=NO
# pg_stat_statements_extension=f
# track_io_timing=off
# log_min_duration_statement=-1
# restart_required=YES

# Candidate high-level apply sequence:
# 1. Take fresh backup before config change.
# 2. Backup compose/config files.
# 3. Configure PostgreSQL:
#    shared_preload_libraries='pg_stat_statements'
#    track_io_timing=on
#    log_min_duration_statement=1000
# 4. Restart PostgreSQL container only in maintenance window if shared_preload_libraries changed.
# 5. Verify DB_CONNECTION_CHECK=PASS and DB_ROLE=PRIMARY_WRITE.
# 6. Create extension after restart if needed:
#    CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
# 7. Verify:
#    show shared_preload_libraries;
#    show track_io_timing;
#    select exists(select 1 from pg_extension where extname='pg_stat_statements');
# 8. Record evidence in next phase report.

# Rollback:
# 1. Restore previous compose/config backup.
# 2. Restart PostgreSQL container.
# 3. Verify DB_CONNECTION_CHECK=PASS and DB_ROLE=PRIMARY_WRITE.
