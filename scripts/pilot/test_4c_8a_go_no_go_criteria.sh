#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_7e_bug_blocker_burndown_final_closure_report.md"
PREV_DOC="docs/pilot/faz4c/4c_7_final_closure.md"

MAIN_DOC="docs/pilot/faz4c/4c_8_pilot_go_no_go_decision.md"
CRITERIA_DOC="docs/pilot/faz4c/4c_8a_go_no_go_criteria.md"
INPUT_ENV="docs/pilot/faz4c/4c_8a_go_no_go_decision_input.env"
DECISION_FORM="uat/pilot/faz4c/uzmanparcaci/go_no_go_decision_form.md"

REPORT_FILE="reports/pilot/faz4c/4c_8a_go_no_go_criteria_report.md"

echo "===== 4C-8A GO / NO-GO CRITERIA TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-7E report yok: $PREV_REPORT"
pass "4C-7E report var"

[ -f "$PREV_DOC" ] || fail "4C-7 final closure doc yok: $PREV_DOC"
pass "4C-7 final closure doc var"

grep -q "4C_7_FINAL_STATUS=PASS" "$PREV_REPORT" || fail "4C-7 final PASS degil"
pass "4C-7 final PASS"

grep -q "4C_7_BUG_BLOCKER_BURNDOWN_STATUS=PASS" "$PREV_REPORT" || fail "4C-7 burn-down PASS degil"
pass "4C-7 burn-down PASS"

grep -q "4C_7_CRITICAL_BLOCKER_COUNT=0" "$PREV_REPORT" || fail "4C-7 critical blocker 0 degil"
pass "4C-7 critical blocker 0"

grep -q "4C_7_OPEN_WARNING_COUNT=0" "$PREV_REPORT" || fail "4C-7 open warning 0 degil"
pass "4C-7 open warning 0"

grep -q "4C_7_OPEN_IMPROVEMENT_COUNT_FOR_4C=0" "$PREV_REPORT" || fail "4C-7 open improvement for 4C 0 degil"
pass "4C-7 open improvement for 4C 0"

grep -q "4C_7_BLOCKING_FIX_REQUIRED=NO" "$PREV_REPORT" || fail "4C-7 blocking fix NO degil"
pass "4C-7 blocking fix NO"

grep -q "4C_8_READY=YES" "$PREV_REPORT" || fail "4C-8 ready YES yok"
pass "4C-8 ready YES"

[ -f "$MAIN_DOC" ] || fail "4C-8 main doc yok"
pass "4C-8 main doc var"

[ -f "$CRITERIA_DOC" ] || fail "4C-8A criteria doc yok"
pass "4C-8A criteria doc var"

[ -f "$INPUT_ENV" ] || fail "4C-8A decision input env yok"
pass "4C-8A decision input env var"

[ -f "$DECISION_FORM" ] || fail "Go/no-go decision form yok"
pass "Go/no-go decision form var"

grep -q "4C_8A_GO_NO_GO_CRITERIA_STATUS=PASS" "$CRITERIA_DOC" || fail "4C-8A status PASS yok"
pass "4C-8A status PASS"

grep -q "4C_8A_SYSTEM_RECOMMENDATION=GO" "$CRITERIA_DOC" || fail "System recommendation GO yok"
pass "System recommendation GO"

grep -q "4C_8A_FINAL_DECISION_STATUS=PENDING" "$CRITERIA_DOC" || fail "Final decision PENDING yok"
pass "Final decision PENDING"

grep -q "4C_8A_CRITICAL_BLOCKER_COUNT=0" "$CRITERIA_DOC" || fail "4C-8A critical blocker 0 yok"
pass "4C-8A critical blocker 0"

grep -q "4C_8A_OPEN_WARNING_COUNT=0" "$CRITERIA_DOC" || fail "4C-8A open warning 0 yok"
pass "4C-8A open warning 0"

grep -q "4C_8A_OPEN_IMPROVEMENT_COUNT_FOR_4C=0" "$CRITERIA_DOC" || fail "4C-8A open improvement 0 yok"
pass "4C-8A open improvement 0"

grep -q "4C_8A_BLOCKING_FIX_REQUIRED=NO" "$CRITERIA_DOC" || fail "4C-8A blocking fix NO yok"
pass "4C-8A blocking fix NO"

grep -q "4C_8A_DB_WRITE_APPLIED=NO" "$CRITERIA_DOC" || fail "4C-8A DB write NO yok"
pass "4C-8A DB write NO"

grep -q "4C_8B_READY=YES" "$CRITERIA_DOC" || fail "4C-8B ready YES yok"
pass "4C-8B ready YES"

grep -q '^SYSTEM_RECOMMENDATION="GO"' "$INPUT_ENV" || fail "Input env system recommendation GO degil"
pass "Input env system recommendation GO"

grep -q '^FINAL_GO_NO_GO_DECISION="PENDING"' "$INPUT_ENV" || fail "Input env final decision PENDING degil"
pass "Input env final decision PENDING"

grep -q '^GO_NO_GO_FINALIZATION_READY="NO"' "$INPUT_ENV" || fail "Input env finalization ready NO degil"
pass "Input env finalization ready NO"

grep -q '^DB_WRITE_APPLIED="NO"' "$INPUT_ENV" || fail "Input env DB write NO degil"
pass "Input env DB write NO"

grep -q "FINAL_GO_NO_GO_DECISION=PENDING" "$DECISION_FORM" || fail "Decision form final decision PENDING yok"
pass "Decision form final decision PENDING"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-8A Go / No-Go Criteria Report

Step: 4C-8A
Blok: Go / No-Go Criteria & Decision Input Freeze
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_8A_GO_NO_GO_CRITERIA_STATUS=PASS
4C_8A_PREVIOUS_BLOCK_STATUS=PASS
4C_8A_SYSTEM_RECOMMENDATION=GO
4C_8A_FINAL_DECISION_STATUS=PENDING
4C_8A_CRITICAL_BLOCKER_COUNT=0
4C_8A_OPEN_WARNING_COUNT=0
4C_8A_OPEN_IMPROVEMENT_COUNT_FOR_4C=0
4C_8A_BLOCKING_FIX_REQUIRED=NO
4C_8A_DECISION_INPUT_CREATED=YES
4C_8A_DECISION_FORM_CREATED=YES
4C_8A_DB_WRITE_APPLIED=NO
4C_8B_READY=YES

## Karar

Sistem önerisi GO.
Final karar henüz PENDING.
4C-8B adımında decision input okunacak ve guard çalışacaktır.

## Sonuc

4C-8A Go / No-Go criteria ve decision input freeze tamamlandı.
Bu adımda DB yazma işlemi yapılmadı.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-8A TEST SONUCU ====="
echo "4C_8A_GO_NO_GO_CRITERIA_STATUS=PASS ✅"
echo "4C_8A_SYSTEM_RECOMMENDATION=GO ✅"
echo "4C_8A_FINAL_DECISION_STATUS=PENDING ⚠️"
echo "4C_8A_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_8A_OPEN_WARNING_COUNT=0 ✅"
echo "4C_8A_OPEN_IMPROVEMENT_COUNT_FOR_4C=0 ✅"
echo "4C_8A_DB_WRITE_APPLIED=NO ✅"
echo "4C_8B_READY=YES ✅"
