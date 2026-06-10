#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_migration_drift_evidence.sh"
REPORT="docs/phase4/14_1_6_migration_drift_evidence_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ drift evidence script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_1_6_real.log 2>&1 || {
  echo "TEST_FAIL ❌ drift evidence script hata verdi"
  cat /tmp/pix2pi_14_1_6_real.log || true
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "MIGRATION_DRIFT_EVIDENCE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ drift evidence PASS degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "DB_ROLE=PRIMARY_WRITE" "$REPORT" || {
  echo "TEST_FAIL ❌ primary write kaniti yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "EXPECTED_OBJECT_COUNT=" "$REPORT" || {
  echo "TEST_FAIL ❌ expected object count yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if grep '^MISSING|INDEX|' "$REPORT" | grep -q ' ON '; then
  echo "TEST_FAIL ❌ index parser ON ifadesini index adina katiyor"
  grep '^MISSING|INDEX|' "$REPORT" | grep ' ON ' | head -n 20 || true
  exit 1
fi

if grep -R "POSTGRES_PASSWORD" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_MIGRATION_DRIFT_EVIDENCE_REAL_TEST=PASS ✅"
echo "PHASE4_MIGRATION_DRIFT_EVIDENCE_SECRET_TEST=PASS ✅"
