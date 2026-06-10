#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_9a_controlled_followup_plan_report.md"

CLASS_DOC="docs/pilot/faz4c/4c_9b_followup_action_classification.md"
REGISTER_FILE="uat/pilot/faz4c/uzmanparcaci/followup_action_register.md"
OWNER_FILE="uat/pilot/faz4c/uzmanparcaci/followup_owner_assignment.md"

REPORT_FILE="reports/pilot/faz4c/4c_9b_followup_action_classification_report.md"

echo "===== 4C-9B FOLLOW-UP ACTION CLASSIFICATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-9A report yok: $PREV_REPORT"
pass "4C-9A report var"

grep -q "4C_9A_CONTROLLED_FOLLOWUP_PLAN_STATUS=PASS" "$PREV_REPORT" || fail "4C-9A PASS degil"
pass "4C-9A PASS"

grep -q "4C_9A_FINAL_GO_NO_GO_DECISION=GO" "$PREV_REPORT" || fail "4C-9A final GO degil"
pass "4C-9A final GO"

grep -q "4C_9A_ACTION_COUNT=7" "$PREV_REPORT" || fail "4C-9A action count 7 degil"
pass "4C-9A action count 7"

grep -q "4C_9A_CRITICAL_BLOCKER_COUNT=0" "$PREV_REPORT" || fail "4C-9A critical blocker 0 degil"
pass "4C-9A critical blocker 0"

grep -q "4C_9B_READY=YES" "$PREV_REPORT" || fail "4C-9B ready YES yok"
pass "4C-9B ready YES"

[ -f "$CLASS_DOC" ] || fail "4C-9B classification doc yok"
pass "4C-9B classification doc var"

[ -f "$REGISTER_FILE" ] || fail "Follow-up register yok"
pass "Follow-up register var"

[ -f "$OWNER_FILE" ] || fail "Owner assignment file yok"
pass "Owner assignment file var"

grep -q "4C_9B_FOLLOWUP_ACTION_CLASSIFICATION_STATUS=PASS" "$CLASS_DOC" || fail "4C-9B status PASS yok"
pass "4C-9B status PASS"

grep -q "4C_9B_ACTION_COUNT=7" "$CLASS_DOC" || fail "Action count 7 yok"
pass "Action count 7"

grep -q "4C_9B_CLASSIFIED_ACTION_COUNT=7" "$CLASS_DOC" || fail "Classified action count 7 yok"
pass "Classified action count 7"

grep -q "4C_9B_OWNER_ASSIGNED_COUNT=7" "$CLASS_DOC" || fail "Owner assigned count 7 yok"
pass "Owner assigned count 7"

grep -q "4C_9B_UNASSIGNED_ACTION_COUNT=0" "$CLASS_DOC" || fail "Unassigned action count 0 yok"
pass "Unassigned action count 0"

grep -q "4C_9B_CONTROLLED_FOLLOWUP_COUNT=2" "$CLASS_DOC" || fail "Controlled follow-up count 2 yok"
pass "Controlled follow-up count 2"

grep -q "4C_9B_CARRIED_FORWARD_COUNT=4" "$CLASS_DOC" || fail "Carried forward count 4 yok"
pass "Carried forward count 4"

grep -q "4C_9B_SCOPE_GUARD_CLOSED_COUNT=1" "$CLASS_DOC" || fail "Scope guard closed count 1 yok"
pass "Scope guard closed count 1"

grep -q "4C_9B_BLOCKING_ACTION_COUNT=0" "$CLASS_DOC" || fail "Blocking action count 0 yok"
pass "Blocking action count 0"

grep -q "4C_9B_CRITICAL_BLOCKER_COUNT=0" "$CLASS_DOC" || fail "Critical blocker count 0 yok"
pass "Critical blocker count 0"

grep -q "4C_9B_DB_WRITE_APPLIED=NO" "$CLASS_DOC" || fail "DB write NO yok"
pass "DB write NO"

grep -q "4C_9C_READY=YES" "$CLASS_DOC" || fail "4C-9C ready YES yok"
pass "4C-9C ready YES"

grep -q "OWNER_ASSIGNED_COUNT=7" "$OWNER_FILE" || fail "Owner file owner assigned count 7 yok"
pass "Owner file owner assigned count 7"

grep -q "UNASSIGNED_ACTION_COUNT=0" "$OWNER_FILE" || fail "Owner file unassigned count 0 yok"
pass "Owner file unassigned count 0"

grep -q "ACT_01_OWNER=PIX2PI_OPS" "$OWNER_FILE" || fail "ACT-01 owner yok"
pass "ACT-01 owner var"

grep -q "ACT_02_OWNER=PIX2PI_PRODUCT" "$OWNER_FILE" || fail "ACT-02 owner yok"
pass "ACT-02 owner var"

grep -q "ACT_05_OWNER=PIX2PI_INTEGRATION" "$OWNER_FILE" || fail "ACT-05 owner yok"
pass "ACT-05 owner var"

grep -q "ACT_07_OWNER=PIX2PI_ARCHITECTURE" "$OWNER_FILE" || fail "ACT-07 owner yok"
pass "ACT-07 owner var"

grep -q "ACT_01_STATUS=CONTROLLED_FOLLOWUP" "$REGISTER_FILE" || fail "Register ACT-01 controlled follow-up yok"
pass "Register ACT-01 controlled follow-up"

grep -q "ACT_02_STATUS=CONTROLLED_FOLLOWUP" "$REGISTER_FILE" || fail "Register ACT-02 controlled follow-up yok"
pass "Register ACT-02 controlled follow-up"

grep -q "ACT_03_STATUS=CARRIED_FORWARD" "$REGISTER_FILE" || fail "Register ACT-03 carried forward yok"
pass "Register ACT-03 carried forward"

grep -q "ACT_07_STATUS=CLOSED_AS_SCOPE_GUARD" "$REGISTER_FILE" || fail "Register ACT-07 closed as scope guard yok"
pass "Register ACT-07 closed as scope guard"

grep -q "BLOCKING_ACTION_COUNT=0" "$REGISTER_FILE" || fail "Register blocking action count 0 yok"
pass "Register blocking action count 0"

grep -q "4C_9C_READY=YES" "$REGISTER_FILE" || fail "Register 4C-9C ready YES yok"
pass "Register 4C-9C ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-9B Follow-up Action Classification Report

Step: 4C-9B
Blok: Follow-up Action Classification / Owner Assignment
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_9B_FOLLOWUP_ACTION_CLASSIFICATION_STATUS=PASS
4C_9B_PREVIOUS_BLOCK_STATUS=PASS
4C_9B_ACTION_COUNT=7
4C_9B_CLASSIFIED_ACTION_COUNT=7
4C_9B_OWNER_ASSIGNED_COUNT=7
4C_9B_UNASSIGNED_ACTION_COUNT=0
4C_9B_CONTROLLED_FOLLOWUP_COUNT=2
4C_9B_CARRIED_FORWARD_COUNT=4
4C_9B_SCOPE_GUARD_CLOSED_COUNT=1
4C_9B_BLOCKING_ACTION_COUNT=0
4C_9B_CRITICAL_BLOCKER_COUNT=0
4C_9B_DB_WRITE_APPLIED=NO
4C_9C_READY=YES

## Dosyalar

FOLLOWUP_REGISTER=uat/pilot/faz4c/uzmanparcaci/followup_action_register.md
OWNER_ASSIGNMENT=uat/pilot/faz4c/uzmanparcaci/followup_owner_assignment.md

## Karar

7 aksiyonun tamamı sınıflandırıldı.
7 aksiyonun tamamına owner atandı.
Blocking action yok.
DB yazma işlemi yapılmadı.
Sonraki adım: 4C-9C Follow-up Closure Gate.

## Sonuc

4C-9B follow-up action classification tamamlandı.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-9B TEST SONUCU ====="
echo "4C_9B_FOLLOWUP_ACTION_CLASSIFICATION_STATUS=PASS ✅"
echo "4C_9B_ACTION_COUNT=7 ✅"
echo "4C_9B_CLASSIFIED_ACTION_COUNT=7 ✅"
echo "4C_9B_OWNER_ASSIGNED_COUNT=7 ✅"
echo "4C_9B_UNASSIGNED_ACTION_COUNT=0 ✅"
echo "4C_9B_BLOCKING_ACTION_COUNT=0 ✅"
echo "4C_9B_DB_WRITE_APPLIED=NO ✅"
echo "4C_9C_READY=YES ✅"
