#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/apply_4c_6g_2_business_acceptance.sh"
PREV_REPORT="reports/pilot/faz4c/4c_6g_business_acceptance_gate_report.md"
INPUT_ENV="docs/pilot/faz4c/4c_6g_business_acceptance_input.env"
REPORT_FILE="reports/pilot/faz4c/4c_6g_2_business_acceptance_apply_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_6g_2_business_acceptance_apply_test_report.md"

echo "===== 4C-6G-2 BUSINESS ACCEPTANCE APPLY TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-6G report yok: $PREV_REPORT"
pass "4C-6G report var"

[ -f "$INPUT_ENV" ] || fail "Business acceptance input env yok: $INPUT_ENV"
pass "Business acceptance input env var"

grep -q "4C_6G_GATE_DOC_STATUS=PASS" "$PREV_REPORT" || fail "4C-6G gate doc PASS degil"
pass "4C-6G gate doc PASS"

grep -q "4C_6G_TECHNICAL_UAT_STATUS=PASS" "$PREV_REPORT" || fail "4C-6G technical UAT PASS degil"
pass "4C-6G technical UAT PASS"

grep -q "4C_6G_2_READY=YES" "$PREV_REPORT" || fail "4C-6G-2 ready YES yok"
pass "4C-6G-2 ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Apply script yok: $RUN_SCRIPT"
pass "Apply script var"

[ -x "$RUN_SCRIPT" ] || fail "Apply script executable degil"
pass "Apply script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-6G-2 report yok"
pass "4C-6G-2 report var"

APPLY_STATUS="$(grep '^4C_6G_2_BUSINESS_ACCEPTANCE_APPLY_STATUS=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
ACCEPTANCE_STATUS="$(grep '^4C_6G_2_BUSINESS_ACCEPTANCE_STATUS=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
FINAL_UAT_RESULT="$(grep '^4C_6G_2_FINAL_UAT_RESULT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
GO_NO_GO_READY="$(grep '^4C_6G_2_GO_NO_GO_READY=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
PENDING_FIELD_COUNT="$(grep '^4C_6G_2_PENDING_FIELD_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
BLOCKER_REASON="$(grep '^4C_6G_2_BLOCKER_REASON=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
H_READY="$(grep '^4C_6H_READY=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

grep -q "4C_6G_2_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

if [ "$ACCEPTANCE_STATUS" = "PENDING" ]; then
  [ "$APPLY_STATUS" = "BLOCKED" ] || fail "PENDING iken apply BLOCKED olmali"
  pass "PENDING iken apply BLOCKED"

  [ "$FINAL_UAT_RESULT" = "PENDING_BUSINESS_ACCEPTANCE" ] || fail "PENDING iken final UAT pending olmali"
  pass "PENDING iken final UAT pending"

  [ "$GO_NO_GO_READY" = "NO" ] || fail "PENDING iken go/no-go NO olmali"
  pass "PENDING iken go/no-go NO"

  [ "$H_READY" = "NO" ] || fail "PENDING iken 4C-6H ready NO olmali"
  pass "PENDING iken 4C-6H ready NO"
else
  case "$ACCEPTANCE_STATUS" in
    PASS|CONDITIONAL_PASS)
      [ "$APPLY_STATUS" = "PASS" ] || fail "Acceptance var iken apply PASS olmali"
      [ "$GO_NO_GO_READY" = "YES" ] || fail "Acceptance var iken go/no-go YES olmali"
      [ "$H_READY" = "YES" ] || fail "Acceptance var iken 4C-6H ready YES olmali"
      pass "Acceptance var, gate PASS"
      ;;
    FAIL)
      [ "$APPLY_STATUS" = "FAIL" ] || fail "FAIL kabulde apply FAIL olmali"
      [ "$H_READY" = "NO" ] || fail "FAIL kabulde 4C-6H ready NO olmali"
      pass "Acceptance FAIL, gate FAIL"
      ;;
    *)
      fail "Bilinmeyen acceptance status: $ACCEPTANCE_STATUS"
      ;;
  esac
fi

cat > "$TEST_REPORT" <<REPORT_EOF
# FAZ 4C — 4C-6G-2 Business Acceptance Apply Test Report

Step: 4C-6G-2
Blok: Business Acceptance Apply / Gate Finalization Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6G_2_TEST_STATUS=PASS
4C_6G_2_BUSINESS_ACCEPTANCE_APPLY_STATUS=$APPLY_STATUS
4C_6G_2_BUSINESS_ACCEPTANCE_STATUS=$ACCEPTANCE_STATUS
4C_6G_2_FINAL_UAT_RESULT=$FINAL_UAT_RESULT
4C_6G_2_GO_NO_GO_READY=$GO_NO_GO_READY
4C_6G_2_PENDING_FIELD_COUNT=$PENDING_FIELD_COUNT
4C_6G_2_BLOCKER_REASON=$BLOCKER_REASON
4C_6G_2_DB_WRITE_APPLIED=NO
4C_6H_READY=$H_READY

## Sonuc

Business acceptance apply guard test tamamlandı.
DB yazma işlemi yapılmadı.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-6G-2 TEST SONUCU ====="
echo "4C_6G_2_TEST_STATUS=PASS ✅"
echo "4C_6G_2_BUSINESS_ACCEPTANCE_APPLY_STATUS=$APPLY_STATUS"
echo "4C_6G_2_BUSINESS_ACCEPTANCE_STATUS=$ACCEPTANCE_STATUS"
echo "4C_6G_2_FINAL_UAT_RESULT=$FINAL_UAT_RESULT"
echo "4C_6G_2_GO_NO_GO_READY=$GO_NO_GO_READY"
echo "4C_6G_2_PENDING_FIELD_COUNT=$PENDING_FIELD_COUNT"
echo "4C_6G_2_BLOCKER_REASON=$BLOCKER_REASON"
echo "4C_6G_2_DB_WRITE_APPLIED=NO ✅"
echo "4C_6H_READY=$H_READY"
