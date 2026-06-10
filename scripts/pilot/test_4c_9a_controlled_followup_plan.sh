#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_8c_pilot_go_no_go_final_closure_report.md"
PREV_DOC="docs/pilot/faz4c/4c_8_final_closure.md"
FAZ4D_CARRY_FORWARD="docs/pilot/faz4d/4d_carry_forward_from_4c.md"

MAIN_DOC="docs/pilot/faz4c/4c_9_pilot_next_action_controlled_followup.md"
PLAN_DOC="docs/pilot/faz4c/4c_9a_controlled_followup_plan.md"
REGISTER_FILE="uat/pilot/faz4c/uzmanparcaci/followup_action_register.md"

REPORT_FILE="reports/pilot/faz4c/4c_9a_controlled_followup_plan_report.md"

echo "===== 4C-9A CONTROLLED FOLLOW-UP PLAN TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-8C report yok: $PREV_REPORT"
pass "4C-8C report var"

[ -f "$PREV_DOC" ] || fail "4C-8 final closure doc yok: $PREV_DOC"
pass "4C-8 final closure doc var"

[ -f "$FAZ4D_CARRY_FORWARD" ] || fail "FAZ 4D carry-forward doc yok: $FAZ4D_CARRY_FORWARD"
pass "FAZ 4D carry-forward doc var"

grep -q "4C_8_FINAL_STATUS=PASS" "$PREV_REPORT" || fail "4C-8 final PASS degil"
pass "4C-8 final PASS"

grep -q "4C_8_PILOT_GO_NO_GO_DECISION_STATUS=PASS" "$PREV_REPORT" || fail "4C-8 decision PASS degil"
pass "4C-8 decision PASS"

grep -q "4C_8_FINAL_GO_NO_GO_DECISION=GO" "$PREV_REPORT" || fail "4C-8 final decision GO degil"
pass "4C-8 final decision GO"

grep -q "4C_8_DECISION_GATE_STATUS=GO" "$PREV_REPORT" || fail "4C-8 decision gate GO degil"
pass "4C-8 decision gate GO"

grep -q "4C_8_CRITICAL_BLOCKER_COUNT=0" "$PREV_REPORT" || fail "4C-8 critical blocker 0 degil"
pass "4C-8 critical blocker 0"

grep -q "4C_8_OPEN_WARNING_COUNT=0" "$PREV_REPORT" || fail "4C-8 open warning 0 degil"
pass "4C-8 open warning 0"

grep -q "4C_8_OPEN_IMPROVEMENT_COUNT_FOR_4C=0" "$PREV_REPORT" || fail "4C-8 open improvement 0 degil"
pass "4C-8 open improvement 0"

grep -q "4C_8_DB_WRITE_APPLIED=NO" "$PREV_REPORT" || fail "4C-8 DB write NO degil"
pass "4C-8 DB write NO"

grep -q "4C_9_READY=YES" "$PREV_REPORT" || fail "4C-9 ready YES yok"
pass "4C-9 ready YES"

grep -q "4D_CARRY_FORWARD_FROM_4C_STATUS=PLANNED" "$FAZ4D_CARRY_FORWARD" || fail "FAZ 4D carry-forward planned yok"
pass "FAZ 4D carry-forward planned"

grep -q "4D_CARRY_FORWARD_ITEM_COUNT=3" "$FAZ4D_CARRY_FORWARD" || fail "FAZ 4D carry-forward item count 3 yok"
pass "FAZ 4D carry-forward item count 3"

[ -f "$MAIN_DOC" ] || fail "4C-9 main doc yok"
pass "4C-9 main doc var"

[ -f "$PLAN_DOC" ] || fail "4C-9A plan doc yok"
pass "4C-9A plan doc var"

[ -f "$REGISTER_FILE" ] || fail "Follow-up action register yok"
pass "Follow-up action register var"

grep -q "4C_9A_CONTROLLED_FOLLOWUP_PLAN_STATUS=PASS" "$PLAN_DOC" || fail "4C-9A status PASS yok"
pass "4C-9A status PASS"

grep -q "4C_9A_FINAL_GO_NO_GO_DECISION=GO" "$PLAN_DOC" || fail "4C-9A final GO yok"
pass "4C-9A final GO"

grep -q "4C_9A_ACTION_REGISTER_CREATED=YES" "$PLAN_DOC" || fail "Action register created YES yok"
pass "Action register created YES"

grep -q "4C_9A_ACTION_COUNT=7" "$PLAN_DOC" || fail "Action count 7 yok"
pass "Action count 7"

grep -q "4C_9A_FOLLOWUP_ACTION_COUNT=2" "$PLAN_DOC" || fail "Follow-up action count 2 yok"
pass "Follow-up action count 2"

grep -q "4C_9A_CARRY_FORWARD_ACTION_COUNT=3" "$PLAN_DOC" || fail "Carry-forward action count 3 yok"
pass "Carry-forward action count 3"

grep -q "4C_9A_SCOPE_GUARD_ACTION_COUNT=1" "$PLAN_DOC" || fail "Scope guard action count 1 yok"
pass "Scope guard action count 1"

grep -q "4C_9A_CARRY_FORWARD_NOTE_COUNT=1" "$PLAN_DOC" || fail "Carry-forward note count 1 yok"
pass "Carry-forward note count 1"

grep -q "4C_9A_CRITICAL_BLOCKER_COUNT=0" "$PLAN_DOC" || fail "Critical blocker count 0 yok"
pass "Critical blocker count 0"

grep -q "4C_9A_DB_WRITE_APPLIED=NO" "$PLAN_DOC" || fail "DB write NO yok"
pass "DB write NO"

grep -q "4C_9B_READY=YES" "$PLAN_DOC" || fail "4C-9B ready YES yok"
pass "4C-9B ready YES"

grep -q "ACT_01_STATUS=OPEN" "$REGISTER_FILE" || fail "ACT-01 OPEN yok"
pass "ACT-01 OPEN"

grep -q "ACT_02_STATUS=OPEN" "$REGISTER_FILE" || fail "ACT-02 OPEN yok"
pass "ACT-02 OPEN"

grep -q "ACT_04_STATUS=PLANNED" "$REGISTER_FILE" || fail "ACT-04 PLANNED yok"
pass "ACT-04 PLANNED"

grep -q "ACT_05_STATUS=PLANNED" "$REGISTER_FILE" || fail "ACT-05 PLANNED yok"
pass "ACT-05 PLANNED"

grep -q "ACT_06_STATUS=PLANNED" "$REGISTER_FILE" || fail "ACT-06 PLANNED yok"
pass "ACT-06 PLANNED"

grep -q "4C_9B_READY=YES" "$REGISTER_FILE" || fail "Register 4C-9B ready YES yok"
pass "Register 4C-9B ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-9A Controlled Follow-up Plan Report

Step: 4C-9A
Blok: Controlled Follow-up Plan / Action Register Freeze
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_9A_CONTROLLED_FOLLOWUP_PLAN_STATUS=PASS
4C_9A_PREVIOUS_BLOCK_STATUS=PASS
4C_9A_FINAL_GO_NO_GO_DECISION=GO
4C_9A_ACTION_REGISTER_CREATED=YES
4C_9A_ACTION_COUNT=7
4C_9A_FOLLOWUP_ACTION_COUNT=2
4C_9A_CARRY_FORWARD_ACTION_COUNT=3
4C_9A_SCOPE_GUARD_ACTION_COUNT=1
4C_9A_CARRY_FORWARD_NOTE_COUNT=1
4C_9A_CRITICAL_BLOCKER_COUNT=0
4C_9A_DB_WRITE_APPLIED=NO
4C_9B_READY=YES

## Register

FOLLOWUP_ACTION_REGISTER=uat/pilot/faz4c/uzmanparcaci/followup_action_register.md

## Karar

GO karari sonrasi kontrollu follow-up register olusturuldu.
Canli entegrasyon veya DB write yapilmadi.
Sonraki adim: 4C-9B Follow-up Action Classification / Owner Assignment.

## Sonuc

4C-9A Controlled Follow-up Plan tamamlandi.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-9A TEST SONUCU ====="
echo "4C_9A_CONTROLLED_FOLLOWUP_PLAN_STATUS=PASS ✅"
echo "4C_9A_FINAL_GO_NO_GO_DECISION=GO ✅"
echo "4C_9A_ACTION_REGISTER_CREATED=YES ✅"
echo "4C_9A_ACTION_COUNT=7 ✅"
echo "4C_9A_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_9A_DB_WRITE_APPLIED=NO ✅"
echo "4C_9B_READY=YES ✅"
