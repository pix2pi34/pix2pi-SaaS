#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="scripts/phase4_pitr_enable_gate.sh"
REPORT="docs/phase4/14_2_6_pitr_enable_gate_report.md"
PLAN="docs/phase4/14_2_6_pitr_enable_candidate_execution.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "TEST_FAIL ❌ PITR enable gate script executable degil"
  exit 1
fi

bash "$SCRIPT" . >/tmp/pix2pi_14_2_6_pitr_enable_gate.log 2>&1 || {
  echo "TEST_FAIL ❌ PITR enable gate script hata verdi"
  cat /tmp/pix2pi_14_2_6_pitr_enable_gate.log || true
  sed -n '1,280p' "$REPORT" || true
  exit 1
}

grep -q "PITR_ENABLE_GATE=PASS" "$REPORT" || {
  echo "TEST_FAIL ❌ PITR enable gate PASS degil"
  sed -n '1,280p' "$REPORT" || true
  exit 1
}

grep -q "APPLY_PITR=0" "$REPORT" || {
  echo "TEST_FAIL ❌ APPLY_PITR=0 kaniti yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "PITR_ENABLE_EXECUTED=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ PITR enable executed NO yok"
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

grep -q "DB_MUTATION=NO" "$REPORT" || {
  echo "TEST_FAIL ❌ DB mutation NO yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "PITR_ENABLE_DECISION=" "$REPORT" || {
  echo "TEST_FAIL ❌ PITR enable decision yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

grep -q "ARCHIVE_COMMAND_PLAN=" "$REPORT" || {
  echo "TEST_FAIL ❌ archive command plan yok"
  sed -n '1,220p' "$REPORT" || true
  exit 1
}

if [ ! -f "$PLAN" ]; then
  echo "TEST_FAIL ❌ candidate execution plan yok"
  exit 1
fi

grep -q "DO_NOT_RUN_AUTOMATICALLY=YES" "$PLAN" || {
  echo "TEST_FAIL ❌ candidate execution plan default blocked degil"
  sed -n '1,100p' "$PLAN" || true
  exit 1
}

grep -q "exit 99" "$PLAN" || {
  echo "TEST_FAIL ❌ candidate execution plan safety exit yok"
  sed -n '1,100p' "$PLAN" || true
  exit 1
}

if grep -R "POSTGRES_PASSWORD=.*[A-Za-z0-9]" "$REPORT"; then
  echo "TEST_FAIL ❌ secret rapora sizdi"
  exit 1
fi

echo "PHASE4_PITR_ENABLE_GATE_TEST=PASS ✅"
echo "PHASE4_PITR_ENABLE_GATE_NO_EXECUTION_TEST=PASS ✅"
echo "PHASE4_PITR_ENABLE_GATE_SECRET_TEST=PASS ✅"
