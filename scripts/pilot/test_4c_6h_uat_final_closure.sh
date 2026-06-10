#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FINAL_DOC="docs/pilot/faz4c/4c_6h_uat_final_closure.md"
ALIAS_DOC="docs/pilot/faz4c/4c_6_final_closure.md"

A_REPORT="reports/pilot/faz4c/4c_6a_uat_execution_plan_report.md"
B_REPORT="reports/pilot/faz4c/4c_6b_uat_runtime_precheck_test_report.md"
C_REPORT="reports/pilot/faz4c/4c_6c_uat_test_case_package_report.md"
D_REPORT="reports/pilot/faz4c/4c_6d_uat_execution_evidence_test_report.md"
D_MAIN_REPORT="reports/pilot/faz4c/4c_6d_uat_execution_evidence_report.md"
E_REPORT="reports/pilot/faz4c/4c_6e_uat_result_classification_report.md"
F_REPORT="reports/pilot/faz4c/4c_6f_uat_bug_blocker_register_report.md"
G_REPORT="reports/pilot/faz4c/4c_6g_business_acceptance_gate_report.md"
G2_REPORT="reports/pilot/faz4c/4c_6g_2_business_acceptance_apply_report.md"
G2_TEST_REPORT="reports/pilot/faz4c/4c_6g_2_business_acceptance_apply_test_report.md"
G3_REPORT="reports/pilot/faz4c/4c_6g_3_business_acceptance_input_fill_report.md"
G3_TEST_REPORT="reports/pilot/faz4c/4c_6g_3_business_acceptance_input_fill_test_report.md"

EXECUTION_TEMPLATE="uat/pilot/faz4c/uzmanparcaci/uat_execution_template.md"
REGISTER_FILE="uat/pilot/faz4c/uzmanparcaci/uat_bug_blocker_register.md"
ACCEPTANCE_FORM="uat/pilot/faz4c/uzmanparcaci/business_acceptance_form.md"

REPORT_FILE="reports/pilot/faz4c/4c_6h_uat_final_closure_report.md"

echo "===== 4C-6H UAT FINAL CLOSURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$FINAL_DOC" ] || fail "4C-6H final closure dokumani yok"
pass "4C-6H final closure dokumani var"

[ -f "$ALIAS_DOC" ] || fail "4C-6 final closure alias dokumani yok"
pass "4C-6 final closure alias dokumani var"

for report in \
  "$A_REPORT" \
  "$B_REPORT" \
  "$C_REPORT" \
  "$D_REPORT" \
  "$D_MAIN_REPORT" \
  "$E_REPORT" \
  "$F_REPORT" \
  "$G_REPORT" \
  "$G2_REPORT" \
  "$G2_TEST_REPORT" \
  "$G3_REPORT" \
  "$G3_TEST_REPORT"
do
  [ -f "$report" ] || fail "Eksik report: $report"
done
pass "Tum 4C-6 report dosyalari var"

for f in "$EXECUTION_TEMPLATE" "$REGISTER_FILE" "$ACCEPTANCE_FORM"; do
  [ -f "$f" ] || fail "Eksik UAT dosyasi: $f"
done
pass "UAT execution/register/acceptance dosyalari var"

grep -q "4C_6A_UAT_EXECUTION_PLAN_STATUS=PASS" "$A_REPORT" || fail "4C-6A PASS degil"
pass "4C-6A PASS"

grep -q "4C_6B_TEST_STATUS=PASS" "$B_REPORT" || fail "4C-6B PASS degil"
pass "4C-6B PASS"

grep -q "4C_6C_UAT_TEST_CASE_PACKAGE_STATUS=PASS" "$C_REPORT" || fail "4C-6C PASS degil"
pass "4C-6C PASS"

grep -q "4C_6D_TEST_STATUS=PASS" "$D_REPORT" || fail "4C-6D test PASS degil"
pass "4C-6D test PASS"

grep -q "4C_6D_TECHNICAL_UAT_STATUS=PASS" "$D_MAIN_REPORT" || fail "4C-6D technical UAT PASS degil"
pass "4C-6D technical UAT PASS"

grep -q "4C_6D_TECHNICAL_FAIL_COUNT=0" "$D_MAIN_REPORT" || fail "4C-6D technical fail count 0 degil"
pass "4C-6D technical fail count 0"

grep -q "4C_6E_UAT_RESULT_CLASSIFICATION_STATUS=PASS" "$E_REPORT" || fail "4C-6E PASS degil"
pass "4C-6E PASS"

grep -q "4C_6E_CRITICAL_BLOCKER_COUNT=0" "$E_REPORT" || fail "4C-6E critical blocker 0 degil"
pass "4C-6E critical blocker 0"

grep -q "4C_6F_UAT_BUG_BLOCKER_REGISTER_STATUS=PASS" "$F_REPORT" || fail "4C-6F PASS degil"
pass "4C-6F PASS"

grep -q "4C_6F_CRITICAL_BLOCKER_COUNT=0" "$F_REPORT" || fail "4C-6F critical blocker 0 degil"
pass "4C-6F critical blocker 0"

grep -q "4C_6G_GATE_DOC_STATUS=PASS" "$G_REPORT" || fail "4C-6G gate doc PASS degil"
pass "4C-6G gate doc PASS"

grep -q "4C_6G_2_BUSINESS_ACCEPTANCE_APPLY_STATUS=PASS" "$G2_REPORT" || fail "4C-6G-2 apply PASS degil"
pass "4C-6G-2 apply PASS"

grep -q "4C_6G_2_BUSINESS_ACCEPTANCE_STATUS=PASS" "$G2_REPORT" || fail "4C-6G-2 business acceptance PASS degil"
pass "4C-6G-2 business acceptance PASS"

grep -q "4C_6G_2_FINAL_UAT_RESULT=PASS" "$G2_REPORT" || fail "4C-6G-2 final UAT PASS degil"
pass "4C-6G-2 final UAT PASS"

grep -q "4C_6G_2_GO_NO_GO_READY=YES" "$G2_REPORT" || fail "4C-6G-2 go/no-go YES degil"
pass "4C-6G-2 go/no-go YES"

grep -q "4C_6G_2_PENDING_FIELD_COUNT=0" "$G2_REPORT" || fail "4C-6G-2 pending count 0 degil"
pass "4C-6G-2 pending count 0"

grep -q "4C_6G_3_TEST_STATUS=PASS" "$G3_TEST_REPORT" || fail "4C-6G-3 test PASS degil"
pass "4C-6G-3 test PASS"

grep -q "4C_6G_3_BUSINESS_ACCEPTANCE_STATUS=PASS" "$G3_TEST_REPORT" || fail "4C-6G-3 business acceptance PASS degil"
pass "4C-6G-3 business acceptance PASS"

grep -q "4C_6H_READY=YES" "$G3_TEST_REPORT" || fail "4C-6H ready YES degil"
pass "4C-6H ready YES"

grep -q "4C_6_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-6 final status PASS yok"
pass "4C-6 final status PASS"

grep -q "4C_6_REAL_UAT_EXECUTION_STATUS=PASS" "$FINAL_DOC" || fail "4C-6 real UAT status PASS yok"
pass "4C-6 real UAT status PASS"

grep -q "4C_6_BUSINESS_ACCEPTANCE_STATUS=PASS" "$FINAL_DOC" || fail "4C-6 business acceptance PASS yok"
pass "4C-6 business acceptance PASS"

grep -q "4C_6_FINAL_UAT_RESULT=PASS" "$FINAL_DOC" || fail "4C-6 final UAT result PASS yok"
pass "4C-6 final UAT result PASS"

grep -q "4C_6_GO_NO_GO_READY=YES" "$FINAL_DOC" || fail "4C-6 go/no-go ready YES yok"
pass "4C-6 go/no-go ready YES"

grep -q "4C_6_CRITICAL_BLOCKER_COUNT=0" "$FINAL_DOC" || fail "4C-6 critical blocker 0 yok"
pass "4C-6 critical blocker 0"

grep -q "4C_6_DB_WRITE_APPLIED=NO" "$FINAL_DOC" || fail "4C-6 DB write NO yok"
pass "4C-6 DB write NO"

grep -q "4C_7_READY=YES" "$FINAL_DOC" || fail "4C-7 ready YES yok"
pass "4C-7 ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-6H UAT Final Closure Report

Step: 4C-6H
Blok: UAT Final Closure
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6H_FINAL_DOC_STATUS=PASS
4C_6H_ALIAS_DOC_STATUS=PASS
4C_6A_STATUS=PASS
4C_6B_STATUS=PASS
4C_6C_STATUS=PASS
4C_6D_STATUS=PASS
4C_6E_STATUS=PASS
4C_6F_STATUS=PASS
4C_6G_STATUS=PASS
4C_6G_2_STATUS=PASS
4C_6G_3_STATUS=PASS
4C_6_FINAL_STATUS=PASS
4C_6_REAL_UAT_EXECUTION_STATUS=PASS
4C_6_TECHNICAL_UAT_STATUS=PASS
4C_6_BUSINESS_ACCEPTANCE_STATUS=PASS
4C_6_FINAL_UAT_RESULT=PASS
4C_6_GO_NO_GO_READY=YES
4C_6_CRITICAL_BLOCKER_COUNT=0
4C_6_WARNING_COUNT=2
4C_6_IMPROVEMENT_COUNT=3
4C_6_DB_WRITE_APPLIED=NO
4C_7_READY=YES

## Karar

4C-6 Real UAT Execution ana blogu kapandi.
Teknik UAT PASS.
Business acceptance PASS.
Critical blocker yok.
Sonraki ana blok: 4C-7 Bug / Blocker Burn-down.

## Sonuc

UAT final closure tamamlandi.
Bu adimda DB yazma islemi yapilmadi.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-6H TEST SONUCU ====="
echo "4C_6_FINAL_STATUS=PASS ✅"
echo "4C_6_REAL_UAT_EXECUTION_STATUS=PASS ✅"
echo "4C_6_TECHNICAL_UAT_STATUS=PASS ✅"
echo "4C_6_BUSINESS_ACCEPTANCE_STATUS=PASS ✅"
echo "4C_6_FINAL_UAT_RESULT=PASS ✅"
echo "4C_6_GO_NO_GO_READY=YES ✅"
echo "4C_6_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_6_DB_WRITE_APPLIED=NO ✅"
echo "4C_7_READY=YES ✅"
