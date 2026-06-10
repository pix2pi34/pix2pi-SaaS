#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_db_backup_pitr_readiness.sh"
REPORT="docs/phase4/14_2_1_db_backup_pitr_readiness_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ db backup pitr readiness script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_2_1_readiness.log 2>&1 || {
  echo "TEST_FAIL ❌ readiness script hata verdi"
  cat /tmp/pix2pi_14_2_1_readiness.log || true
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_BACKUP_PITR_READINESS_ASSESSMENT=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ readiness assessment PASS degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_CONNECTION_CHECK=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ DB connection PASS yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ DB primary write degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "RESTORE_DRILL_READY=" "$REPORT" || {
  echo "TEST_FAIL ❌ restore drill readiness raporda yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "PITR_READY=" "$REPORT" || {
  echo "TEST_FAIL ❌ PITR readiness raporda yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_DB_BACKUP_PITR_READINESS_TEST=PASS ✅"
echo "PHASE4_DB_BACKUP_PITR_SECRET_TEST=PASS ✅"
