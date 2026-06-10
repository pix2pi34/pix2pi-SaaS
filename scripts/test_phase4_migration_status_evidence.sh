#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_migration_status_evidence.sh"
REPORT="docs/phase4/14_1_5_migration_status_evidence_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ migration status evidence script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_1_5_status.log 2>&1 || {
  echo "TEST_FAIL ❌ migration status evidence script hata verdi"
  cat /tmp/pix2pi_14_1_5_status.log || true
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "MIGRATION_STATUS_EVIDENCE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ status evidence PASS degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ DB primary write degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "SCHEMA_MIGRATIONS_DIRTY_STATE=f" "$REPORT" || {
  echo "TEST_FAIL ❌ dirty state temiz degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_MIGRATION_STATUS_EVIDENCE_TEST=PASS ✅"
