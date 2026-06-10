#!/usr/bin/env bash
set -euo pipefail

echo "DO_NOT_RUN_AUTOMATICALLY=YES"
echo "This is only the 14.2.6 PITR enable candidate execution file."
echo "14.2.6 gate does not execute PITR enable."
echo "Actual config change must be done in a separate approved apply step."
exit 99

# FAZ 4 / 14.2.6 - PITR Enable Candidate Execution
# Generated at: 2026-04-27 14:03:31 +0300
# This file is intentionally blocked by exit 99 above.

PRIMARY_CONTAINER="pix2pi_pg"
PRIMARY_IMAGE="postgres:16"
PRIMARY_DB="pix2pi"
PRIMARY_PORT="5433"

HOST_WAL_ARCHIVE_DIR="./backups/db/wal_archive"
CONTAINER_WAL_ARCHIVE_DIR="/var/lib/postgresql/wal_archive"
ARCHIVE_COMMAND_PLAN="test ! -f /var/lib/postgresql/wal_archive/%f && cp %p /var/lib/postgresql/wal_archive/%f"

# Candidate high-level apply sequence:
# 1. Take fresh logical backup and restic backup.
# 2. Backup Docker compose/config files.
# 3. mkdir -p "$HOST_WAL_ARCHIVE_DIR"
# 4. Add mount:
#    $HOST_WAL_ARCHIVE_DIR:$CONTAINER_WAL_ARCHIVE_DIR
# 5. Configure PostgreSQL:
#    wal_level=replica
#    archive_mode=on
#    archive_command='test ! -f /var/lib/postgresql/wal_archive/%f && cp %p /var/lib/postgresql/wal_archive/%f'
# 6. Restart primary PostgreSQL container in maintenance window.
# 7. Verify:
#    show archive_mode;
#    show archive_command;
#    select pg_switch_wal();
#    check WAL file appears in $HOST_WAL_ARCHIVE_DIR
# 8. Run backup job including WAL archive directory.
# 9. Record evidence.
#
# Rollback:
# 1. Restore previous compose/config.
# 2. Restart PostgreSQL.
# 3. Verify DB_CONNECTION_CHECK=PASS and DB_ROLE=PRIMARY_WRITE.
