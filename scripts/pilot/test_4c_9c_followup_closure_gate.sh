#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

A_REPORT="reports/pilot/faz4c/4c_9a_controlled_followup_plan_report.md"
B_REPORT="reports/pilot/faz4c/4c_9b_followup_action_classification_report.md"

GATE_DOC="docs/pilot/faz4c/4c_9c_followup_closure_gate.md"
REGISTER_FILE="uat/pilot/faz4c/uzmanparcaci/followup_action_register.md"
OWNER_FILE="uat/pilot/faz4c/uzmanparcaci/followup_owner_assignment.md"

REPORT_FILE="reports/pilot/faz4c/4c_9c_followup_closure_gate_report.md"

echo "===== 4C-9C FOLLOW-UP CLOSURE GATE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

for report in "$A_REPORT" "$B_REPORT"; do
  [ -f "$report" ] || fail "Eksik report: $report"
done
pass "4C-9A/9B report dosyalari var"

[ -f "$GATE_DOC" ] || fail "4C-9C gate doc yok"
pass "4C-9C gate doc var"

[ -f "$REGISTER_FILE" ] || fail "Follow-up register yok"
pass "Follow-up register var"

[ -f "$OWNER_FILE" ] || fail "Owner assignment file yok"
pass "Owner assignment file var"

grep -q "4C_9A_CONTROLLED_FOLLOWUP_PLAN_STATUS=PASS" "$A_REPORT" || fail "4C-9A PASS degil"
pass "4C-9A PASS"

grep -q "4C_9A_FINAL_GO_NO_GO_DECISION=GO" "$A_REPORT" || fail "4C-9A final GO degil"
pass "4C-9A final GO"

grep -q "4C_9A_ACTION_COUNT=7" "$A_REPORT" || fail "4C-9A action count 7 degil"
pass "4C-9A action count 7"

grep -q "4C_9B_FOLLOWUP_ACTION_CLASSIFICATION_STATUS=PASS" "$B_REPORT" || fail "4C-9B PASS degil"
pass "4C-9B PASS"

grep -q "4C_9B_ACTION_COUNT=7" "$B_REPORT" || fail "4C-9B action count 7 degil"
pass "4C-9B action count 7"

grep -q "4C_9B_CLASSIFIED_ACTION_COUNT=7" "$B_REPORT" || fail "4C-9B classified action count 7 degil"
pass "4C-9B classified action count 7"

grep -q "4C_9B_OWNER_ASSIGNED_COUNT=7" "$B_REPORT" || fail "4C-9B owner assigned count 7 degil"
pass "4C-9B owner assigned count 7"

grep -q "4C_9B_UNASSIGNED_ACTION_COUNT=0" "$B_REPORT" || fail "4C-9B unassigned action count 0 degil"
pass "4C-9B unassigned action count 0"

grep -q "4C_9B_BLOCKING_ACTION_COUNT=0" "$B_REPORT" || fail "4C-9B blocking action count 0 degil"
pass "4C-9B blocking action count 0"

grep -q "4C_9B_CRITICAL_BLOCKER_COUNT=0" "$B_REPORT" || fail "4C-9B critical blocker count 0 degil"
pass "4C-9B critical blocker count 0"

grep -q "4C_9C_READY=YES" "$B_REPORT" || fail "4C-9C ready YES yok"
pass "4C-9C ready YES"

grep -q "4C_9C_FOLLOWUP_CLOSURE_GATE_STATUS=PASS" "$GATE_DOC" || fail "4C-9C gate status PASS yok"
pass "4C-9C gate status PASS"

grep -q "4C_9C_ACTION_COUNT=7" "$GATE_DOC" || fail "4C-9C action count 7 yok"
pass "4C-9C action count 7"

grep -q "4C_9C_CLASSIFIED_ACTION_COUNT=7" "$GATE_DOC" || fail "4C-9C classified count 7 yok"
pass "4C-9C classified count 7"

grep -q "4C_9C_OWNER_ASSIGNED_COUNT=7" "$GATE_DOC" || fail "4C-9C owner assigned count 7 yok"
pass "4C-9C owner assigned count 7"

grep -q "4C_9C_UNASSIGNED_ACTION_COUNT=0" "$GATE_DOC" || fail "4C-9C unassigned count 0 yok"
pass "4C-9C unassigned count 0"

grep -q "4C_9C_BLOCKING_ACTION_COUNT=0" "$GATE_DOC" || fail "4C-9C blocking action count 0 yok"
pass "4C-9C blocking action count 0"

grep -q "4C_9C_CONTROLLED_FOLLOWUP_COUNT=2" "$GATE_DOC" || fail "4C-9C controlled follow-up count 2 yok"
pass "4C-9C controlled follow-up count 2"

grep -q "4C_9C_CARRIED_FORWARD_COUNT=4" "$GATE_DOC" || fail "4C-9C carried forward count 4 yok"
pass "4C-9C carried forward count 4"

grep -q "4C_9C_SCOPE_GUARD_CLOSED_COUNT=1" "$GATE_DOC" || fail "4C-9C scope guard closed count 1 yok"
pass "4C-9C scope guard closed count 1"

grep -q "4C_9C_CRITICAL_BLOCKER_COUNT=0" "$GATE_DOC" || fail "4C-9C critical blocker 0 yok"
pass "4C-9C critical blocker 0"

grep -q "4C_9C_DB_WRITE_APPLIED=NO" "$GATE_DOC" || fail "4C-9C DB write NO yok"
pass "4C-9C DB write NO"

grep -q "4C_9D_READY=YES" "$GATE_DOC" || fail "4C-9D ready YES yok"
pass "4C-9D ready YES"

grep -q "FOLLOWUP_CLOSURE_GATE_STATUS=PASS" "$REGISTER_FILE" || fail "Register closure gate PASS yok"
pass "Register closure gate PASS"

grep -q "BLOCKING_ACTION_COUNT=0" "$REGISTER_FILE" || fail "Register blocking action count 0 yok"
pass "Register blocking action count 0"

grep -q "UNASSIGNED_ACTION_COUNT=0" "$REGISTER_FILE" || fail "Register unassigned action count 0 yok"
pass "Register unassigned action count 0"

grep -q "4C_9D_READY=YES" "$REGISTER_FILE" || fail "Register 4C-9D ready YES yok"
pass "Register 4C-9D ready YES"

grep -q "OWNER_ASSIGNED_COUNT=7" "$OWNER_FILE" || fail "Owner file owner assigned count 7 yok"
pass "Owner file owner assigned count 7"

grep -q "BLOCKING_ACTION_COUNT=0" "$OWNER_FILE" || fail "Owner file blocking action count 0 yok"
pass "Owner file blocking action count 0"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-9C Follow-up Closure Gate Report

Step: 4C-9C
Blok: Follow-up Closure Gate
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_9C_FOLLOWUP_CLOSURE_GATE_STATUS=PASS
4C_9C_PREVIOUS_BLOCK_STATUS=PASS
4C_9C_9A_STATUS=PASS
4C_9C_9B_STATUS=PASS
4C_9C_ACTION_COUNT=7
4C_9C_CLASSIFIED_ACTION_COUNT=7
4C_9C_OWNER_ASSIGNED_COUNT=7
4C_9C_UNASSIGNED_ACTION_COUNT=0
4C_9C_BLOCKING_ACTION_COUNT=0
4C_9C_CONTROLLED_FOLLOWUP_COUNT=2
4C_9C_CARRIED_FORWARD_COUNT=4
4C_9C_SCOPE_GUARD_CLOSED_COUNT=1
4C_9C_CRITICAL_BLOCKER_COUNT=0
4C_9C_DB_WRITE_APPLIED=NO
4C_9D_READY=YES

## Karar

4C-9 final closure öncesi kapı PASS.
Blocking action yok.
Unassigned action yok.
Critical blocker yok.
DB write yok.
Sonraki adım: 4C-9D Pilot Next Action Final Closure.

## Sonuc

4C-9C follow-up closure gate tamamlandı.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-9C TEST SONUCU ====="
echo "4C_9C_FOLLOWUP_CLOSURE_GATE_STATUS=PASS ✅"
echo "4C_9C_ACTION_COUNT=7 ✅"
echo "4C_9C_CLASSIFIED_ACTION_COUNT=7 ✅"
echo "4C_9C_OWNER_ASSIGNED_COUNT=7 ✅"
echo "4C_9C_UNASSIGNED_ACTION_COUNT=0 ✅"
echo "4C_9C_BLOCKING_ACTION_COUNT=0 ✅"
echo "4C_9C_DB_WRITE_APPLIED=NO ✅"
echo "4C_9D_READY=YES ✅"
