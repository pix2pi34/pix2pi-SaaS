#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-/var/log/pix2pi/ops_retention_cleanup.log}"
CLEANUP_SCRIPT="${CLEANUP_SCRIPT:-/root/pix2pi/pix2pi-SaaS/scripts/ops_retention_cleanup.sh}"
ARCHIVE_RETENTION_DAYS="${ARCHIVE_RETENTION_DAYS:-14}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
APPLY="${APPLY:-1}"

mkdir -p "$(dirname "$LOG_FILE")"

START_TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "===== pix2pi ops retention start ${START_TS} =====" >> "$LOG_FILE"

set +e
ARCHIVE_RETENTION_DAYS="$ARCHIVE_RETENTION_DAYS" \
BACKUP_RETENTION_DAYS="$BACKUP_RETENTION_DAYS" \
APPLY="$APPLY" \
"$CLEANUP_SCRIPT" >> "$LOG_FILE" 2>&1
RC=$?
set -e

END_TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "===== pix2pi ops retention end ${END_TS} rc=${RC} =====" >> "$LOG_FILE"
echo >> "$LOG_FILE"

exit "$RC"
