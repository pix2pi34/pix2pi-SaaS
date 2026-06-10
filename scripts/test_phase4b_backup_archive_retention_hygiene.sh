#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4b_backup_archive_retention_hygiene.sh"
PY_SCRIPT="scripts/phase4b_backup_archive_retention_hygiene.py"
REPORT="docs/phase4/20_6_backup_archive_retention_report.md"
MATRIX="docs/phase4/20_6_backup_archive_retention_matrix.tsv"
INVENTORY="docs/phase4/20_6_backup_archive_inventory.tsv"
VOLUMES="docs/phase4/20_6_backup_archive_volume_retention.tsv"
POLICY="docs/phase4/20_6_backup_archive_retention_policy.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ backup/archive retention wrapper executable degil"
  exit 1
fi

if [ ! -x "$PY_SCRIPT" ]; then
  echo "TEST_FAIL ❌ backup/archive retention python executable degil"
  exit 1
fi

bash -n "$SCRIPT" || {
  echo "TEST_FAIL ❌ wrapper bash syntax hatali"
  exit 1
}

python3 -m py_compile "$PY_SCRIPT" || {
  echo "TEST_FAIL ❌ python validator syntax hatali"
  exit 1
}

bash "$SCRIPT" . >/tmp/pix2pi_20_6_backup_archive_retention.log 2>&1 || {
  echo "TEST_FAIL ❌ backup/archive retention script hata verdi"
  cat /tmp/pix2pi_20_6_backup_archive_retention.log || true
  sed -n '1,2600p' "$REPORT" || true
  exit 1
}

for required in \
  "BACKUP_ARCHIVE_RETENTION_HYGIENE=PASS" \
  "FAZ4B_20_6_FINAL_STATUS=PASS" \
  "BACKUP_ARCHIVE_PREVIOUS_20_5=PASS" \
  "BACKUP_ARCHIVE_INVENTORY=PASS" \
  "BACKUP_ARCHIVE_VOLUME_RETENTION=PASS" \
  "BACKUP_ARCHIVE_POLICY=PASS" \
  "BACKUP_ARCHIVE_NO_DELETE=PASS" \
  "BACKUP_ARCHIVE_NO_PRUNE=PASS" \
  "BACKUP_ARCHIVE_NO_RESTORE=PASS" \
  "BACKUP_ARCHIVE_SECRET_SAFE=PASS" \
  "BACKUP_DELETE_EXECUTED=NO" \
  "ARCHIVE_DELETE_EXECUTED=NO" \
  "FILE_DELETE_EXECUTED=NO" \
  "FILE_MOVE_EXECUTED=NO" \
  "DOCKER_VOLUME_REMOVED=NO" \
  "DOCKER_VOLUME_PRUNE_EXECUTED=NO" \
  "RESTIC_FORGET_EXECUTED=NO" \
  "RESTIC_PRUNE_EXECUTED=NO" \
  "RESTIC_REPAIR_EXECUTED=NO" \
  "RESTORE_EXECUTED=NO" \
  "PG_DUMP_EXECUTED=NO" \
  "PG_RESTORE_EXECUTED=NO" \
  "DB_MUTATION=NO" \
  "DB_APPLY_EXECUTED=NO" \
  "MIGRATION_CREATED=NO" \
  "MIGRATION_APPLY_EXECUTED=NO" \
  "CONFIG_CHANGED=NO" \
  "ENV_CHANGED=NO" \
  "SERVICE_RESTARTED=NO" \
  "CONTAINER_RESTARTED=NO" \
  "DEPLOY_EXECUTED=NO" \
  "QUERY_TEXT_PRINTED=NO" \
  "RAW_DSN_PRINTED=NO" \
  "SECRET_VALUE_PRINTED=NO"
do
  grep -q "$required" "$REPORT" || {
    echo "TEST_FAIL ❌ required missing: $required"
    sed -n '1,2600p' "$REPORT" || true
    exit 1
  }
done

for f in "$MATRIX" "$INVENTORY" "$VOLUMES" "$POLICY"; do
  if [ ! -f "$f" ]; then
    echo "TEST_FAIL ❌ file yok: $f"
    exit 1
  fi
done

for gate in \
  previous_20_5 \
  backup_archive_inventory \
  volume_retention \
  backup_candidates \
  db_backup_candidates \
  secret_backup_paths \
  no_delete \
  no_prune \
  no_restore \
  secret_safe
do
  grep -q "$gate" "$MATRIX" || {
    echo "TEST_FAIL ❌ matrix gate eksik: $gate"
    cat "$MATRIX" || true
    exit 1
  }
done

for header in \
  "path" \
  "category" \
  "risk" \
  "retention_policy" \
  "age_days"
do
  grep -q "$header" "$INVENTORY" || {
    echo "TEST_FAIL ❌ inventory header eksik: $header"
    cat "$INVENTORY" || true
    exit 1
  }
done

for header in \
  "volume_name" \
  "retention_class" \
  "backup_required" \
  "restore_drill_required" \
  "risk"
do
  grep -q "$header" "$VOLUMES" || {
    echo "TEST_FAIL ❌ volume retention header eksik: $header"
    cat "$VOLUMES" || true
    exit 1
  }
done

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT" "$MATRIX" "$INVENTORY" "$VOLUMES" "$POLICY"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

if grep -R "password=[^* ]" "$REPORT" "$MATRIX" "$INVENTORY" "$VOLUMES" "$POLICY"; then
  echo "TEST_FAIL ❌ password maskelenmeden rapora sizdi"
  exit 1
fi

if grep -R "Bearer " "$REPORT" "$MATRIX" "$INVENTORY" "$VOLUMES" "$POLICY"; then
  echo "TEST_FAIL ❌ auth token rapora basildi"
  exit 1
fi

echo "PHASE4B_BACKUP_ARCHIVE_RETENTION_TEST=PASS ✅"
echo "PHASE4B_BACKUP_ARCHIVE_INVENTORY_TEST=PASS ✅"
echo "PHASE4B_BACKUP_ARCHIVE_VOLUME_RETENTION_TEST=PASS ✅"
echo "PHASE4B_BACKUP_ARCHIVE_NO_DELETE_TEST=PASS ✅"
echo "PHASE4B_BACKUP_ARCHIVE_NO_PRUNE_TEST=PASS ✅"
echo "PHASE4B_BACKUP_ARCHIVE_SECRET_TEST=PASS ✅"
