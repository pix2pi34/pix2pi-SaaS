#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 14.2.5 PITR enable candidate plan."
echo "14.2.5 does not change PostgreSQL config."
echo "Actual enable gate belongs to FAZ 4 / 14.2.6."
exit 99

# FAZ 4 / 14.2.5 - PITR Enable Candidate Plan
# Generated at: 2026-04-27 14:00:58 +0300
# This file is intentionally blocked by exit 99 above.

# Target primary container observed:
PRIMARY_CONTAINER="pix2pi_pg"
PRIMARY_IMAGE="postgres:16"
PRIMARY_DB="pix2pi"
PRIMARY_PORT="5433"

# Proposed WAL archive paths:
HOST_WAL_ARCHIVE_DIR="./backups/db/wal_archive"
CONTAINER_WAL_ARCHIVE_DIR="/var/lib/postgresql/wal_archive"

# Proposed archive command:
ARCHIVE_COMMAND_PLAN="test ! -f /var/lib/postgresql/wal_archive/%f && cp %p /var/lib/postgresql/wal_archive/%f"

# Required high-level actions for 14.2.6:
# 1. Create host WAL archive directory with safe permissions.
# 2. Mount host WAL archive directory into PostgreSQL container:
#    $HOST_WAL_ARCHIVE_DIR:$CONTAINER_WAL_ARCHIVE_DIR
# 3. Configure PostgreSQL:
#    wal_level=replica
#    archive_mode=on
#    archive_command='test ! -f /var/lib/postgresql/wal_archive/%f && cp %p /var/lib/postgresql/wal_archive/%f'
# 4. Restart PostgreSQL container in controlled maintenance window.
# 5. Verify:
#    show archive_mode;
#    show archive_command;
#    select pg_switch_wal();
#    check WAL file appears under $HOST_WAL_ARCHIVE_DIR
# 6. Run restic backup including WAL archive directory.
# 7. Record evidence in 14.2.6 report.

# Rollback plan:
# 1. Restore previous compose/config backup.
# 2. Set archive_mode=off or remove archive_command if startup fails.
# 3. Restart PostgreSQL container.
# 4. Verify DB_CONNECTION_CHECK=PASS and DB_ROLE=PRIMARY_WRITE.
