#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FILL_SCRIPT="scripts/pilot/fill_4c_8b_2_go_no_go_decision_input.sh"
APPLY_TEST_SCRIPT="scripts/pilot/test_4c_8b_go_no_go_decision_apply.sh"

FILL_REPORT="reports/pilot/faz4c/4c_8b_2_go_no_go_decision_input_fill_report.md"
APPLY_REPORT="reports/pilot/faz4c/4c_8b_go_no_go_decision_apply_report.md"
APPLY_TEST_REPORT="reports/pilot/faz4c/4c_8b_go_no_go_decision_apply_test_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_8b_2_go_no_go_decision_input_fill_test_report.md"

INPUT_ENV="docs/pilot/faz4c/4c_8a_go_no_go_decision_input.env"

echo "===== 4C-8B-2 GO / NO-GO DECISION INPUT FILL TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$FILL_SCRIPT" ] || fail "Fill script yok"
pass "Fill script var"

[ -x "$FILL_SCRIPT" ] || fail "Fill script executable degil"
pass "Fill script executable"

[ -f "$APPLY_TEST_SCRIPT" ] || fail "4C-8B apply test script yok"
pass "4C-8B apply test script var"

[ -x "$APPLY_TEST_SCRIPT" ] || fail "4C-8B apply test script executable degil"
pass "4C-8B apply test script executable"

bash "$FILL_SCRIPT"

[ -f "$FILL_REPORT" ] || fail "Fill report yok"
pass "Fill report var"

grep -q "4C_8B_2_GO_NO_GO_DECISION_INPUT_FILL_STATUS=PASS" "$FILL_REPORT" || fail "Fill status PASS degil"
pass "Fill status PASS"

grep -q "4C_8B_2_FINAL_GO_NO_GO_DECISION=GO" "$FILL_REPORT" || fail "Final decision GO degil"
pass "Final decision GO"

grep -q "4C_8B_2_PENDING_FIELD_COUNT=0" "$FILL_REPORT" || fail "Pending field count 0 degil"
pass "Pending field count 0"

grep -q '^FINAL_GO_NO_GO_DECISION="GO"' "$INPUT_ENV" || fail "Input env final decision GO degil"
pass "Input env final decision GO"

grep -q '^DECISION_OWNER="mert_omur"' "$INPUT_ENV" || fail "Decision owner dogru degil"
pass "Decision owner dogru"

grep -q '^ACCEPTS_PHASE_4D_CARRY_FORWARD="YES"' "$INPUT_ENV" || fail "Phase 4D carry-forward YES degil"
pass "Phase 4D carry-forward YES"

grep -q '^ACCEPTS_MARKETPLACE_PHASE_4D="YES"' "$INPUT_ENV" || fail "Marketplace phase 4D YES degil"
pass "Marketplace phase 4D YES"

grep -q '^ACCEPTS_NO_CORE_PRODUCT_APPLY_IN_4C="YES"' "$INPUT_ENV" || fail "No core product apply YES degil"
pass "No core product apply YES"

grep -q '^ACCEPTS_NO_LIVE_MARKETPLACE_IN_4C="YES"' "$INPUT_ENV" || fail "No live marketplace YES degil"
pass "No live marketplace YES"

echo
echo "===== 4C-8B TEKRAR CALISTIRILIYOR ====="
bash "$APPLY_TEST_SCRIPT"

[ -f "$APPLY_REPORT" ] || fail "4C-8B apply report yok"
pass "4C-8B apply report var"

[ -f "$APPLY_TEST_REPORT" ] || fail "4C-8B apply test report yok"
pass "4C-8B apply test report var"

grep -q "4C_8B_GO_NO_GO_DECISION_APPLY_STATUS=PASS" "$APPLY_REPORT" || fail "4C-8B apply PASS degil"
pass "4C-8B apply PASS"

grep -q "4C_8B_DECISION_GATE_STATUS=GO" "$APPLY_REPORT" || fail "4C-8B decision gate GO degil"
pass "4C-8B decision gate GO"

grep -q "4C_8B_FINAL_GO_NO_GO_DECISION=GO" "$APPLY_REPORT" || fail "4C-8B final decision GO degil"
pass "4C-8B final decision GO"

grep -q "4C_8B_GO_NO_GO_FINALIZATION_READY=YES" "$APPLY_REPORT" || fail "4C-8B finalization YES degil"
pass "4C-8B finalization YES"

grep -q "4C_8B_PENDING_FIELD_COUNT=0" "$APPLY_REPORT" || fail "4C-8B pending count 0 degil"
pass "4C-8B pending count 0"

grep -q "4C_8B_DB_WRITE_APPLIED=NO" "$APPLY_REPORT" || fail "4C-8B DB write NO degil"
pass "4C-8B DB write NO"

grep -q "4C_8C_READY=YES" "$APPLY_REPORT" || fail "4C-8C ready YES degil"
pass "4C-8C ready YES"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-8B-2 Go / No-Go Decision Input Fill Test Report

Step: 4C-8B-2
Blok: Go / No-Go Decision Input Fill Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_8B_2_TEST_STATUS=PASS
4C_8B_2_GO_NO_GO_DECISION_INPUT_FILL_STATUS=PASS
4C_8B_2_FINAL_GO_NO_GO_DECISION=GO
4C_8B_2_PENDING_FIELD_COUNT=0
4C_8B_RETRY_STATUS=PASS
4C_8B_GO_NO_GO_DECISION_APPLY_STATUS=PASS
4C_8B_DECISION_GATE_STATUS=GO
4C_8B_GO_NO_GO_FINALIZATION_READY=YES
4C_8B_DB_WRITE_APPLIED=NO
4C_8C_READY=YES

## Sonuc

Go / No-Go final karar GO olarak islendi.
4C-8B tekrar calistirildi ve PASS oldu.
DB yazma islemi yapilmadi.
4C-8C final closure adimina gecilebilir.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-8B-2 TEST SONUCU ====="
echo "4C_8B_2_TEST_STATUS=PASS ✅"
echo "4C_8B_2_FINAL_GO_NO_GO_DECISION=GO ✅"
echo "4C_8B_GO_NO_GO_DECISION_APPLY_STATUS=PASS ✅"
echo "4C_8B_DECISION_GATE_STATUS=GO ✅"
echo "4C_8B_GO_NO_GO_FINALIZATION_READY=YES ✅"
echo "4C_8B_DB_WRITE_APPLIED=NO ✅"
echo "4C_8C_READY=YES ✅"
