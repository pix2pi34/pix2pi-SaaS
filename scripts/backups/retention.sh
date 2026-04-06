#!/bin/bash
set -e

echo "STEP6 retention start"

BACKUP_DIR=".backups"
KEEP_DAYS="${KEEP_DAYS:-7}"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "ERR: missing $BACKUP_DIR"
  exit 1
fi

echo "OK ✅ keeping last $KEEP_DAYS days in $BACKUP_DIR"

# Silinecekleri önce say
TO_DELETE_COUNT="$(find "$BACKUP_DIR" -type f -name "*.bak" -mtime +"$KEEP_DAYS" 2>/dev/null | wc -l || true)"
echo "OK ✅ candidates to delete: $TO_DELETE_COUNT"

# Sil
find "$BACKUP_DIR" -type f -name "*.bak" -mtime +"$KEEP_DAYS" -print -delete 2>/dev/null || true

# Boş klasörleri temizle
find "$BACKUP_DIR" -type d -empty -print -delete 2>/dev/null || true

echo "OK ✅ retention done"
