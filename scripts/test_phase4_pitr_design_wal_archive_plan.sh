#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_pitr_design_wal_archive_plan.sh"
REPORT="docs/phase4/14_2_5_pitr_design_wal_archive_report.md"
PLAN="docs/phase4/14_2_5_pitr_enable_candidate_plan.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ PITR design script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_2_5_pitr_design.log 2>&1 || {
  echo "TEST_FAIL ❌ PITR design script hata verdi"
  cat /tmp/pix2pi_14_2_5_pitr_design.log || true
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PITR_DESIGN_WAL_ARCHIVE_PLAN=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ PITR design PASS degil"
  sed -n '1,260p' "$REPORT" || true
  exit 1
}

grep -q "PITR_ENABLE_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ PITR enable NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "POSTGRES_CONFIG_CHANGED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ postgres config changed NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "CONTAINER_RESTARTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ container restarted NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "ARCHIVE_COMMAND_PLAN=" "$REPORT" || {
  echo "TEST_FAIL ❌ archive command plan yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "HOST_WAL_ARCHIVE_DIR=" "$REPORT" || {
  echo "TEST_FAIL ❌ host WAL archive dir yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "RESTORE_DRILL_TEST=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ restore drill PASS kaniti yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if [ ! -f "$PLAN" ]; then
  echo "TEST_FAIL ❌ enable candidate plan dosyasi yok"
  exit 1
fi

grep -q "DO_NOT_RUN_AUTOMATICALLY=YES" "$PLAN" || {
  echo "TEST_FAIL ❌ enable candidate plan default blocked degil"
  sed -n '1,80p' "$PLAN" || true
  exit 1
}

grep -q "exit 99" "$PLAN" || {
  echo "TEST_FAIL ❌ enable candidate plan safety exit yok"
  sed -n '1,80p' "$PLAN" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_PITR_DESIGN_WAL_ARCHIVE_PLAN_TEST=PASS ✅"
echo "PHASE4_PITR_DESIGN_NO_EXECUTION_TEST=PASS ✅"
echo "PHASE4_PITR_DESIGN_SECRET_TEST=PASS ✅"
