#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FINAL_DOC="docs/pilot/faz4c/4c_9d_pilot_next_action_final_closure.md"
ALIAS_DOC="docs/pilot/faz4c/4c_9_final_closure.md"

A_REPORT="reports/pilot/faz4c/4c_9a_controlled_followup_plan_report.md"
B_REPORT="reports/pilot/faz4c/4c_9b_followup_action_classification_report.md"
C_REPORT="reports/pilot/faz4c/4c_9c_followup_closure_gate_report.md"

REGISTER_FILE="uat/pilot/faz4c/uzmanparcaci/followup_action_register.md"
OWNER_FILE="uat/pilot/faz4c/uzmanparcaci/followup_owner_assignment.md"

REPORT_FILE="reports/pilot/faz4c/4c_9d_pilot_next_action_final_closure_report.md"

echo "===== 4C-9D PILOT NEXT ACTION FINAL CLOSURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$FINAL_DOC" ] || fail "4C-9D final closure dokumani yok"
pass "4C-9D final closure dokumani var"

[ -f "$ALIAS_DOC" ] || fail "4C-9 final closure alias dokumani yok"
pass "4C-9 final closure alias dokumani var"

for report in "$A_REPORT" "$B_REPORT" "$C_REPORT"; do
  [ -f "$report" ] || fail "Eksik report: $report"
done
pass "4C-9A/9B/9C report dosyalari var"

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

grep -q "4C_9C_FOLLOWUP_CLOSURE_GATE_STATUS=PASS" "$C_REPORT" || fail "4C-9C PASS degil"
pass "4C-9C PASS"

grep -q "4C_9C_ACTION_COUNT=7" "$C_REPORT" || fail "4C-9C action count 7 degil"
pass "4C-9C action count 7"

grep -q "4C_9C_CLASSIFIED_ACTION_COUNT=7" "$C_REPORT" || fail "4C-9C classified action count 7 degil"
pass "4C-9C classified action count 7"

grep -q "4C_9C_OWNER_ASSIGNED_COUNT=7" "$C_REPORT" || fail "4C-9C owner assigned count 7 degil"
pass "4C-9C owner assigned count 7"

grep -q "4C_9C_UNASSIGNED_ACTION_COUNT=0" "$C_REPORT" || fail "4C-9C unassigned action count 0 degil"
pass "4C-9C unassigned action count 0"

grep -q "4C_9C_BLOCKING_ACTION_COUNT=0" "$C_REPORT" || fail "4C-9C blocking action count 0 degil"
pass "4C-9C blocking action count 0"

grep -q "4C_9C_DB_WRITE_APPLIED=NO" "$C_REPORT" || fail "4C-9C DB write NO degil"
pass "4C-9C DB write NO"

grep -q "4C_9D_READY=YES" "$C_REPORT" || fail "4C-9D ready YES yok"
pass "4C-9D ready YES"

grep -q "FOLLOWUP_CLOSURE_GATE_STATUS=PASS" "$REGISTER_FILE" || fail "Register closure gate PASS yok"
pass "Register closure gate PASS"

grep -q "BLOCKING_ACTION_COUNT=0" "$REGISTER_FILE" || fail "Register blocking action count 0 yok"
pass "Register blocking action count 0"

grep -q "UNASSIGNED_ACTION_COUNT=0" "$REGISTER_FILE" || fail "Register unassigned action count 0 yok"
pass "Register unassigned action count 0"

grep -q "OWNER_ASSIGNED_COUNT=7" "$OWNER_FILE" || fail "Owner file owner assigned count 7 yok"
pass "Owner file owner assigned count 7"

grep -q "BLOCKING_ACTION_COUNT=0" "$OWNER_FILE" || fail "Owner file blocking action count 0 yok"
pass "Owner file blocking action count 0"

grep -q "4C_9_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-9 final status PASS yok"
pass "4C-9 final status PASS"

grep -q "4C_9_PILOT_NEXT_ACTION_STATUS=PASS" "$FINAL_DOC" || fail "4C-9 pilot next action status PASS yok"
pass "4C-9 pilot next action status PASS"

grep -q "4C_9_FINAL_GO_NO_GO_DECISION=GO" "$FINAL_DOC" || fail "4C-9 final GO yok"
pass "4C-9 final GO"

grep -q "4C_9_ACTION_COUNT=7" "$FINAL_DOC" || fail "4C-9 action count 7 yok"
pass "4C-9 action count 7"

grep -q "4C_9_CLASSIFIED_ACTION_COUNT=7" "$FINAL_DOC" || fail "4C-9 classified action count 7 yok"
pass "4C-9 classified action count 7"

grep -q "4C_9_OWNER_ASSIGNED_COUNT=7" "$FINAL_DOC" || fail "4C-9 owner assigned count 7 yok"
pass "4C-9 owner assigned count 7"

grep -q "4C_9_UNASSIGNED_ACTION_COUNT=0" "$FINAL_DOC" || fail "4C-9 unassigned action count 0 yok"
pass "4C-9 unassigned action count 0"

grep -q "4C_9_BLOCKING_ACTION_COUNT=0" "$FINAL_DOC" || fail "4C-9 blocking action count 0 yok"
pass "4C-9 blocking action count 0"

grep -q "4C_9_CONTROLLED_FOLLOWUP_COUNT=2" "$FINAL_DOC" || fail "4C-9 controlled follow-up count 2 yok"
pass "4C-9 controlled follow-up count 2"

grep -q "4C_9_CARRIED_FORWARD_COUNT=4" "$FINAL_DOC" || fail "4C-9 carried forward count 4 yok"
pass "4C-9 carried forward count 4"

grep -q "4C_9_SCOPE_GUARD_CLOSED_COUNT=1" "$FINAL_DOC" || fail "4C-9 scope guard closed count 1 yok"
pass "4C-9 scope guard closed count 1"

grep -q "4C_9_CRITICAL_BLOCKER_COUNT=0" "$FINAL_DOC" || fail "4C-9 critical blocker count 0 yok"
pass "4C-9 critical blocker count 0"

grep -q "4C_9_DB_WRITE_APPLIED=NO" "$FINAL_DOC" || fail "4C-9 DB write NO yok"
pass "4C-9 DB write NO"

grep -q "4C_10_READY=YES" "$FINAL_DOC" || fail "4C-10 ready YES yok"
pass "4C-10 ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-9D Pilot Next Action Final Closure Report

Step: 4C-9D
Blok: Pilot Next Action Final Closure
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_9D_FINAL_DOC_STATUS=PASS
4C_9D_ALIAS_DOC_STATUS=PASS
4C_9A_STATUS=PASS
4C_9B_STATUS=PASS
4C_9C_STATUS=PASS
4C_9_FINAL_STATUS=PASS
4C_9_PILOT_NEXT_ACTION_STATUS=PASS
4C_9_FINAL_GO_NO_GO_DECISION=GO
4C_9_ACTION_COUNT=7
4C_9_CLASSIFIED_ACTION_COUNT=7
4C_9_OWNER_ASSIGNED_COUNT=7
4C_9_UNASSIGNED_ACTION_COUNT=0
4C_9_BLOCKING_ACTION_COUNT=0
4C_9_CONTROLLED_FOLLOWUP_COUNT=2
4C_9_CARRIED_FORWARD_COUNT=4
4C_9_SCOPE_GUARD_CLOSED_COUNT=1
4C_9_CRITICAL_BLOCKER_COUNT=0
4C_9_DB_WRITE_APPLIED=NO
4C_10_READY=YES

## Karar

4C-9 Pilot Next Action / Controlled Follow-up Plan ana blogu kapandi.
GO sonrasi takip aksiyonlari siniflandirildi.
Owner assignment tamamlandi.
Blocking action yok.
Sonraki ana blok: 4C-10 Pilot Handoff / Evidence Package.

## Sonuc

4C-9D final closure tamamlandi.
Bu adimda DB yazma islemi yapilmadi.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-9D TEST SONUCU ====="
echo "4C_9_FINAL_STATUS=PASS ✅"
echo "4C_9_PILOT_NEXT_ACTION_STATUS=PASS ✅"
echo "4C_9_FINAL_GO_NO_GO_DECISION=GO ✅"
echo "4C_9_ACTION_COUNT=7 ✅"
echo "4C_9_OWNER_ASSIGNED_COUNT=7 ✅"
echo "4C_9_BLOCKING_ACTION_COUNT=0 ✅"
echo "4C_9_DB_WRITE_APPLIED=NO ✅"
echo "4C_10_READY=YES ✅"
