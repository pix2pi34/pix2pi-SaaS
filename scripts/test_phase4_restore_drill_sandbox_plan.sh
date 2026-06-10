#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_restore_drill_sandbox_plan.sh"
REPORT="docs/phase4/14_2_3_restore_drill_sandbox_plan_report.md"
PLAN="docs/phase4/14_2_3_restore_drill_execution_plan.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ restore drill sandbox plan script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_2_3_restore_plan.log 2>&1 || {
  echo "TEST_FAIL ❌ restore drill plan script hata verdi"
  cat /tmp/pix2pi_14_2_3_restore_plan.log || true
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "RESTORE_DRILL_SANDBOX_PLAN=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ restore drill sandbox plan PASS degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "DUMP_CHECKSUM_VERIFY=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ checksum verify PASS degil"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "RESTORE_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ restore executed NO yok"
  sed -n '1,200p' "$REPORT" || true
  exit 1
}

grep -q "SANDBOX_CONTAINER_CREATE_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ sandbox create NO yok"
  sed -n '1,200p' "$REPORT" || true
  exit 1
}

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ db mutation NO yok"
  sed -n '1,200p' "$REPORT" || true
  exit 1
}

if [ ! -f "$PLAN" ]; then
  echo "TEST_FAIL ❌ execution plan dosyasi yok"
  exit 1
fi

grep -q "DO_NOT_RUN_AUTOMATICALLY=YES" "$PLAN" || {
  echo "TEST_FAIL ❌ execution plan default blocked degil"
  sed -n '1,80p' "$PLAN" || true
  exit 1
}

grep -q "exit 99" "$PLAN" || {
  echo "TEST_FAIL ❌ execution plan safety exit yok"
  sed -n '1,80p' "$PLAN" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_RESTORE_DRILL_SANDBOX_PLAN_TEST=PASS ✅"
echo "PHASE4_RESTORE_DRILL_CHECKSUM_TEST=PASS ✅"
echo "PHASE4_RESTORE_DRILL_NO_EXECUTION_TEST=PASS ✅"
echo "PHASE4_RESTORE_DRILL_SECRET_TEST=PASS ✅"
