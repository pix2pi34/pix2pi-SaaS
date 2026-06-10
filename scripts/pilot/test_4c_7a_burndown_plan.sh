#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_6h_uat_final_closure_report.md"
PREV_DOC="docs/pilot/faz4c/4c_6_final_closure.md"
UAT_REGISTER="uat/pilot/faz4c/uzmanparcaci/uat_bug_blocker_register.md"

MAIN_DOC="docs/pilot/faz4c/4c_7_bug_blocker_burndown.md"
PLAN_DOC="docs/pilot/faz4c/4c_7a_burndown_plan.md"
REGISTER_FILE="uat/pilot/faz4c/uzmanparcaci/burndown_register.md"

REPORT_FILE="reports/pilot/faz4c/4c_7a_burndown_plan_report.md"

echo "===== 4C-7A BURN-DOWN PLAN / REGISTER FREEZE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-6H final closure report yok: $PREV_REPORT"
pass "4C-6H final closure report var"

[ -f "$PREV_DOC" ] || fail "4C-6 final closure doc yok: $PREV_DOC"
pass "4C-6 final closure doc var"

[ -f "$UAT_REGISTER" ] || fail "UAT bug/blocker register yok: $UAT_REGISTER"
pass "UAT bug/blocker register var"

grep -q "4C_6_FINAL_STATUS=PASS" "$PREV_REPORT" || fail "4C-6 final PASS degil"
pass "4C-6 final PASS"

grep -q "4C_6_REAL_UAT_EXECUTION_STATUS=PASS" "$PREV_REPORT" || fail "4C-6 real UAT PASS degil"
pass "4C-6 real UAT PASS"

grep -q "4C_6_BUSINESS_ACCEPTANCE_STATUS=PASS" "$PREV_REPORT" || fail "4C-6 business acceptance PASS degil"
pass "4C-6 business acceptance PASS"

grep -q "4C_6_FINAL_UAT_RESULT=PASS" "$PREV_REPORT" || fail "4C-6 final UAT PASS degil"
pass "4C-6 final UAT PASS"

grep -q "4C_6_CRITICAL_BLOCKER_COUNT=0" "$PREV_REPORT" || fail "4C-6 critical blocker 0 degil"
pass "4C-6 critical blocker 0"

grep -q "4C_6_WARNING_COUNT=2" "$PREV_REPORT" || fail "4C-6 warning count 2 degil"
pass "4C-6 warning count 2"

grep -q "4C_6_IMPROVEMENT_COUNT=3" "$PREV_REPORT" || fail "4C-6 improvement count 3 degil"
pass "4C-6 improvement count 3"

grep -q "4C_7_READY=YES" "$PREV_REPORT" || fail "4C-7 ready YES yok"
pass "4C-7 ready YES"

[ -f "$MAIN_DOC" ] || fail "4C-7 ana dokuman yok"
pass "4C-7 ana dokuman var"

[ -f "$PLAN_DOC" ] || fail "4C-7A plan dokumani yok"
pass "4C-7A plan dokumani var"

[ -f "$REGISTER_FILE" ] || fail "Burn-down register yok"
pass "Burn-down register var"

grep -q "4C_7A_BURNDOWN_PLAN_STATUS=PASS" "$PLAN_DOC" || fail "4C-7A status PASS yok"
pass "4C-7A status PASS"

grep -q "4C_7A_CRITICAL_BLOCKER_COUNT=0" "$PLAN_DOC" || fail "4C-7A critical blocker 0 yok"
pass "4C-7A critical blocker 0"

grep -q "4C_7A_WARNING_COUNT=2" "$PLAN_DOC" || fail "4C-7A warning count 2 yok"
pass "4C-7A warning count 2"

grep -q "4C_7A_IMPROVEMENT_COUNT=3" "$PLAN_DOC" || fail "4C-7A improvement count 3 yok"
pass "4C-7A improvement count 3"

grep -q "4C_7A_BLOCKING_FIX_REQUIRED=NO" "$PLAN_DOC" || fail "4C-7A blocking fix NO yok"
pass "4C-7A blocking fix NO"

grep -q "4C_7A_DB_WRITE_APPLIED=NO" "$PLAN_DOC" || fail "4C-7A DB write NO yok"
pass "4C-7A DB write NO"

grep -q "4C_7B_READY=YES" "$PLAN_DOC" || fail "4C-7B ready YES yok"
pass "4C-7B ready YES"

grep -q "WARN-01" "$REGISTER_FILE" || fail "WARN-01 register yok"
pass "WARN-01 register var"

grep -q "WARN-02" "$REGISTER_FILE" || fail "WARN-02 register yok"
pass "WARN-02 register var"

grep -q "IMP-01" "$REGISTER_FILE" || fail "IMP-01 register yok"
pass "IMP-01 register var"

grep -q "IMP-02" "$REGISTER_FILE" || fail "IMP-02 register yok"
pass "IMP-02 register var"

grep -q "IMP-03" "$REGISTER_FILE" || fail "IMP-03 register yok"
pass "IMP-03 register var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-7A Burn-down Plan Report

Step: 4C-7A
Blok: Burn-down Plan / Register Freeze
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_7A_BURNDOWN_PLAN_STATUS=PASS
4C_7A_PREVIOUS_BLOCK_STATUS=PASS
4C_7A_REGISTER_CREATED=YES
4C_7A_CRITICAL_BLOCKER_COUNT=0
4C_7A_WARNING_COUNT=2
4C_7A_IMPROVEMENT_COUNT=3
4C_7A_BLOCKING_FIX_REQUIRED=NO
4C_7A_DB_WRITE_APPLIED=NO
4C_7B_READY=YES

## Register

BURN_DOWN_REGISTER=uat/pilot/faz4c/uzmanparcaci/burndown_register.md

## Sonuc

4C-7A burn-down plan ve register freeze tamamlandi.
Critical blocker yok.
Warning ve improvement kayitlari register'a alindi.
Bu adimda DB yazma islemi yapilmadi.
Sonraki adim: 4C-7B Warning Burn-down Classification.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-7A TEST SONUCU ====="
echo "4C_7A_BURNDOWN_PLAN_STATUS=PASS ✅"
echo "4C_7A_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_7A_WARNING_COUNT=2 ⚠️"
echo "4C_7A_IMPROVEMENT_COUNT=3 ✅"
echo "4C_7A_BLOCKING_FIX_REQUIRED=NO ✅"
echo "4C_7A_DB_WRITE_APPLIED=NO ✅"
echo "4C_7B_READY=YES ✅"
