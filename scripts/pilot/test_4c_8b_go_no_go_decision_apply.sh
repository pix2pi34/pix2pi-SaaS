#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/apply_4c_8b_go_no_go_decision.sh"
PREV_REPORT="reports/pilot/faz4c/4c_8a_go_no_go_criteria_report.md"
INPUT_ENV="docs/pilot/faz4c/4c_8a_go_no_go_decision_input.env"
REPORT_FILE="reports/pilot/faz4c/4c_8b_go_no_go_decision_apply_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_8b_go_no_go_decision_apply_test_report.md"

echo "===== 4C-8B GO / NO-GO DECISION APPLY TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-8A report yok: $PREV_REPORT"
pass "4C-8A report var"

[ -f "$INPUT_ENV" ] || fail "Decision input env yok: $INPUT_ENV"
pass "Decision input env var"

grep -q "4C_8A_GO_NO_GO_CRITERIA_STATUS=PASS" "$PREV_REPORT" || fail "4C-8A PASS degil"
pass "4C-8A PASS"

grep -q "4C_8A_SYSTEM_RECOMMENDATION=GO" "$PREV_REPORT" || fail "4C-8A recommendation GO degil"
pass "4C-8A recommendation GO"

grep -q "4C_8B_READY=YES" "$PREV_REPORT" || fail "4C-8B ready YES yok"
pass "4C-8B ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Apply script yok"
pass "Apply script var"

[ -x "$RUN_SCRIPT" ] || fail "Apply script executable degil"
pass "Apply script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-8B report yok"
pass "4C-8B report var"

APPLY_STATUS="$(grep '^4C_8B_GO_NO_GO_DECISION_APPLY_STATUS=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
DECISION_STATUS="$(grep '^4C_8B_FINAL_GO_NO_GO_DECISION=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
FINALIZATION_READY="$(grep '^4C_8B_GO_NO_GO_FINALIZATION_READY=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
PENDING_FIELD_COUNT="$(grep '^4C_8B_PENDING_FIELD_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
BLOCKER_REASON="$(grep '^4C_8B_BLOCKER_REASON=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
C_READY="$(grep '^4C_8C_READY=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

grep -q "4C_8B_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

if [ "$DECISION_STATUS" = "PENDING" ]; then
  [ "$APPLY_STATUS" = "BLOCKED" ] || fail "PENDING iken apply BLOCKED olmali"
  pass "PENDING iken apply BLOCKED"

  [ "$FINALIZATION_READY" = "NO" ] || fail "PENDING iken finalization NO olmali"
  pass "PENDING iken finalization NO"

  [ "$C_READY" = "NO" ] || fail "PENDING iken 4C-8C ready NO olmali"
  pass "PENDING iken 4C-8C ready NO"
else
  case "$DECISION_STATUS" in
    GO|CONDITIONAL_GO|NO_GO)
      [ "$APPLY_STATUS" = "PASS" ] || fail "Final karar varken apply PASS olmali"
      [ "$FINALIZATION_READY" = "YES" ] || fail "Final karar varken finalization YES olmali"
      [ "$C_READY" = "YES" ] || fail "Final karar varken 4C-8C ready YES olmali"
      pass "Final karar var, gate uygun"
      ;;
    *)
      fail "Bilinmeyen final karar: $DECISION_STATUS"
      ;;
  esac
fi

cat > "$TEST_REPORT" <<REPORT_EOF
# FAZ 4C — 4C-8B Go / No-Go Decision Apply Test Report

Step: 4C-8B
Blok: Go / No-Go Decision Apply Guard Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_8B_TEST_STATUS=PASS
4C_8B_GO_NO_GO_DECISION_APPLY_STATUS=$APPLY_STATUS
4C_8B_FINAL_GO_NO_GO_DECISION=$DECISION_STATUS
4C_8B_GO_NO_GO_FINALIZATION_READY=$FINALIZATION_READY
4C_8B_PENDING_FIELD_COUNT=$PENDING_FIELD_COUNT
4C_8B_BLOCKER_REASON=$BLOCKER_REASON
4C_8B_DB_WRITE_APPLIED=NO
4C_8C_READY=$C_READY

## Sonuc

Go / No-Go decision apply guard test tamamlandı.
DB yazma işlemi yapılmadı.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-8B TEST SONUCU ====="
echo "4C_8B_TEST_STATUS=PASS ✅"
echo "4C_8B_GO_NO_GO_DECISION_APPLY_STATUS=$APPLY_STATUS"
echo "4C_8B_FINAL_GO_NO_GO_DECISION=$DECISION_STATUS"
echo "4C_8B_GO_NO_GO_FINALIZATION_READY=$FINALIZATION_READY"
echo "4C_8B_PENDING_FIELD_COUNT=$PENDING_FIELD_COUNT"
echo "4C_8B_BLOCKER_REASON=$BLOCKER_REASON"
echo "4C_8B_DB_WRITE_APPLIED=NO ✅"
echo "4C_8C_READY=$C_READY"
