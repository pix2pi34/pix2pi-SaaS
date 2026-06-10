#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FINAL_DOC="docs/pilot/faz4c/4c_8c_pilot_go_no_go_final_closure.md"
ALIAS_DOC="docs/pilot/faz4c/4c_8_final_closure.md"

A_REPORT="reports/pilot/faz4c/4c_8a_go_no_go_criteria_report.md"
B_REPORT="reports/pilot/faz4c/4c_8b_go_no_go_decision_apply_report.md"
B_TEST_REPORT="reports/pilot/faz4c/4c_8b_go_no_go_decision_apply_test_report.md"
B2_REPORT="reports/pilot/faz4c/4c_8b_2_go_no_go_decision_input_fill_report.md"
B2_TEST_REPORT="reports/pilot/faz4c/4c_8b_2_go_no_go_decision_input_fill_test_report.md"

INPUT_ENV="docs/pilot/faz4c/4c_8a_go_no_go_decision_input.env"
DECISION_FORM="uat/pilot/faz4c/uzmanparcaci/go_no_go_decision_form.md"

REPORT_FILE="reports/pilot/faz4c/4c_8c_pilot_go_no_go_final_closure_report.md"

echo "===== 4C-8C PILOT GO / NO-GO FINAL CLOSURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$FINAL_DOC" ] || fail "4C-8C final closure dokumani yok"
pass "4C-8C final closure dokumani var"

[ -f "$ALIAS_DOC" ] || fail "4C-8 final closure alias dokumani yok"
pass "4C-8 final closure alias dokumani var"

for report in "$A_REPORT" "$B_REPORT" "$B_TEST_REPORT" "$B2_REPORT" "$B2_TEST_REPORT"; do
  [ -f "$report" ] || fail "Eksik report: $report"
done
pass "Tum 4C-8 report dosyalari var"

[ -f "$INPUT_ENV" ] || fail "Decision input env yok"
pass "Decision input env var"

[ -f "$DECISION_FORM" ] || fail "Decision form yok"
pass "Decision form var"

grep -q "4C_8A_GO_NO_GO_CRITERIA_STATUS=PASS" "$A_REPORT" || fail "4C-8A PASS degil"
pass "4C-8A PASS"

grep -q "4C_8A_SYSTEM_RECOMMENDATION=GO" "$A_REPORT" || fail "4C-8A recommendation GO degil"
pass "4C-8A recommendation GO"

grep -q "4C_8A_CRITICAL_BLOCKER_COUNT=0" "$A_REPORT" || fail "4C-8A critical blocker 0 degil"
pass "4C-8A critical blocker 0"

grep -q "4C_8A_OPEN_WARNING_COUNT=0" "$A_REPORT" || fail "4C-8A open warning 0 degil"
pass "4C-8A open warning 0"

grep -q "4C_8A_OPEN_IMPROVEMENT_COUNT_FOR_4C=0" "$A_REPORT" || fail "4C-8A open improvement 0 degil"
pass "4C-8A open improvement 0"

grep -q "4C_8B_GO_NO_GO_DECISION_APPLY_STATUS=PASS" "$B_REPORT" || fail "4C-8B apply PASS degil"
pass "4C-8B apply PASS"

grep -q "4C_8B_DECISION_GATE_STATUS=GO" "$B_REPORT" || fail "4C-8B decision gate GO degil"
pass "4C-8B decision gate GO"

grep -q "4C_8B_FINAL_GO_NO_GO_DECISION=GO" "$B_REPORT" || fail "4C-8B final decision GO degil"
pass "4C-8B final decision GO"

grep -q "4C_8B_GO_NO_GO_FINALIZATION_READY=YES" "$B_REPORT" || fail "4C-8B finalization YES degil"
pass "4C-8B finalization YES"

grep -q "4C_8B_PENDING_FIELD_COUNT=0" "$B_REPORT" || fail "4C-8B pending field count 0 degil"
pass "4C-8B pending field count 0"

grep -q "4C_8B_BLOCKER_REASON=NONE" "$B_REPORT" || fail "4C-8B blocker reason NONE degil"
pass "4C-8B blocker reason NONE"

grep -q "4C_8B_DB_WRITE_APPLIED=NO" "$B_REPORT" || fail "4C-8B DB write NO degil"
pass "4C-8B DB write NO"

grep -q "4C_8C_READY=YES" "$B_REPORT" || fail "4C-8C ready YES yok"
pass "4C-8C ready YES"

grep -q "4C_8B_2_TEST_STATUS=PASS" "$B2_TEST_REPORT" || fail "4C-8B-2 test PASS degil"
pass "4C-8B-2 test PASS"

grep -q "4C_8B_2_FINAL_GO_NO_GO_DECISION=GO" "$B2_TEST_REPORT" || fail "4C-8B-2 final decision GO degil"
pass "4C-8B-2 final decision GO"

grep -q '^FINAL_GO_NO_GO_DECISION="GO"' "$INPUT_ENV" || fail "Input env final GO degil"
pass "Input env final GO"

grep -q '^DECISION_OWNER="mert_omur"' "$INPUT_ENV" || fail "Decision owner dogru degil"
pass "Decision owner dogru"

grep -q "FINAL_GO_NO_GO_DECISION=GO" "$DECISION_FORM" || fail "Decision form GO degil"
pass "Decision form GO"

grep -q "4C_8_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-8 final status PASS yok"
pass "4C-8 final status PASS"

grep -q "4C_8_PILOT_GO_NO_GO_DECISION_STATUS=PASS" "$FINAL_DOC" || fail "4C-8 decision status PASS yok"
pass "4C-8 decision status PASS"

grep -q "4C_8_FINAL_GO_NO_GO_DECISION=GO" "$FINAL_DOC" || fail "4C-8 final decision GO yok"
pass "4C-8 final decision GO"

grep -q "4C_8_DECISION_GATE_STATUS=GO" "$FINAL_DOC" || fail "4C-8 decision gate GO yok"
pass "4C-8 decision gate GO"

grep -q "4C_8_GO_NO_GO_FINALIZATION_READY=YES" "$FINAL_DOC" || fail "4C-8 finalization ready YES yok"
pass "4C-8 finalization ready YES"

grep -q "4C_8_CRITICAL_BLOCKER_COUNT=0" "$FINAL_DOC" || fail "4C-8 critical blocker 0 yok"
pass "4C-8 critical blocker 0"

grep -q "4C_8_OPEN_WARNING_COUNT=0" "$FINAL_DOC" || fail "4C-8 open warning 0 yok"
pass "4C-8 open warning 0"

grep -q "4C_8_OPEN_IMPROVEMENT_COUNT_FOR_4C=0" "$FINAL_DOC" || fail "4C-8 open improvement 0 yok"
pass "4C-8 open improvement 0"

grep -q "4C_8_BLOCKING_FIX_REQUIRED=NO" "$FINAL_DOC" || fail "4C-8 blocking fix NO yok"
pass "4C-8 blocking fix NO"

grep -q "4C_8_DB_WRITE_APPLIED=NO" "$FINAL_DOC" || fail "4C-8 DB write NO yok"
pass "4C-8 DB write NO"

grep -q "4C_9_READY=YES" "$FINAL_DOC" || fail "4C-9 ready YES yok"
pass "4C-9 ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-8C Pilot Go / No-Go Final Closure Report

Step: 4C-8C
Blok: Pilot Go / No-Go Final Closure
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_8C_FINAL_DOC_STATUS=PASS
4C_8C_ALIAS_DOC_STATUS=PASS
4C_8A_STATUS=PASS
4C_8B_STATUS=PASS
4C_8B_2_STATUS=PASS
4C_8_FINAL_STATUS=PASS
4C_8_PILOT_GO_NO_GO_DECISION_STATUS=PASS
4C_8_SYSTEM_RECOMMENDATION=GO
4C_8_FINAL_GO_NO_GO_DECISION=GO
4C_8_DECISION_GATE_STATUS=GO
4C_8_GO_NO_GO_FINALIZATION_READY=YES
4C_8_CRITICAL_BLOCKER_COUNT=0
4C_8_OPEN_WARNING_COUNT=0
4C_8_OPEN_IMPROVEMENT_COUNT_FOR_4C=0
4C_8_BLOCKING_FIX_REQUIRED=NO
4C_8_DB_WRITE_APPLIED=NO
4C_9_READY=YES

## Karar

4C-8 Pilot Go / No-Go Decision ana blogu kapandi.
Final karar: GO.
Bu adimda DB yazma islemi yapilmadi.
Sonraki ana blok: 4C-9 Pilot Next Action / Controlled Follow-up Plan.

## Sonuc

4C-8C final closure tamamlandi.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-8C TEST SONUCU ====="
echo "4C_8_FINAL_STATUS=PASS ✅"
echo "4C_8_PILOT_GO_NO_GO_DECISION_STATUS=PASS ✅"
echo "4C_8_FINAL_GO_NO_GO_DECISION=GO ✅"
echo "4C_8_DECISION_GATE_STATUS=GO ✅"
echo "4C_8_GO_NO_GO_FINALIZATION_READY=YES ✅"
echo "4C_8_DB_WRITE_APPLIED=NO ✅"
echo "4C_9_READY=YES ✅"
