#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_migration_reconciliation_final.sh"
REPORT="docs/phase4/14_1_8_migration_reconciliation_final_report.md"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ final reconciliation script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_1_8_final.log 2>&1 || {
  echo "TEST_FAIL ❌ final reconciliation script hata verdi"
  cat /tmp/pix2pi_14_1_8_final.log || true
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "MIGRATION_RECONCILIATION_FINAL=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ final reconciliation PASS degil"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "FINAL_DECISION=NO_OP_APPLY_NOT_REQUIRED" "$REPORT" || {
  echo "TEST_FAIL ❌ final decision no-op degil"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "APPLY_ACTION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ apply action NO degil"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "INDEX_APPLY_ACTION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ index apply action NO degil"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ db mutation NO kaniti yok"
  sed -n '1,240p' "$REPORT" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_MIGRATION_RECONCILIATION_FINAL_TEST=PASS ✅"
echo "PHASE4_MIGRATION_RECONCILIATION_NOOP_TEST=PASS ✅"
echo "PHASE4_MIGRATION_RECONCILIATION_SECRET_TEST=PASS ✅"
