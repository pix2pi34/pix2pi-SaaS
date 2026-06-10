#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_index_reconciliation_plan.sh"
REPORT="docs/phase4/14_1_7_index_reconciliation_report.md"
PLAN="docs/phase4/14_1_7_index_reconciliation_plan.sql"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ index reconciliation script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_1_7_index_plan.log 2>&1 || {
  echo "TEST_FAIL ❌ index reconciliation script hata verdi"
  cat /tmp/pix2pi_14_1_7_index_plan.log || true
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "INDEX_RECONCILIATION_PLAN=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ index reconciliation PASS degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "INDEX_PLAN_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ mutation no kaniti yok"
  sed -n '1,120p' "$REPORT" || true
  exit 1
}

grep -q "SAFE_INDEX_CANDIDATE_COUNT=" "$REPORT" || {
  echo "TEST_FAIL ❌ safe candidate count yok"
  sed -n '1,120p' "$REPORT" || true
  exit 1
}

grep -q "SKIPPED_TABLE_MISSING_COUNT=" "$REPORT" || {
  echo "TEST_FAIL ❌ skipped table missing count yok"
  sed -n '1,120p' "$REPORT" || true
  exit 1
}

if [ ! -f "$PLAN" ]; then
  echo "TEST_FAIL ❌ plan sql olusmadi"
  exit 1
fi

grep -q "INDEX_PLAN_MUTATION=NO" "$PLAN" || {
  echo "TEST_FAIL ❌ plan dosyasinda mutation no yok"
  sed -n '1,80p' "$PLAN" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD" "$REPORT" "$PLAN"; then
  echo "TEST_FAIL ❌ secret rapora/plana sizdi"
  exit 1
fi

echo "PHASE4_INDEX_RECONCILIATION_PLAN_TEST=PASS ✅"
echo "PHASE4_INDEX_RECONCILIATION_SECRET_TEST=PASS ✅"
