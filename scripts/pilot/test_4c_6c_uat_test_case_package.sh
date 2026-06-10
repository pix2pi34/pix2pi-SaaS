#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_6b_uat_runtime_precheck_test_report.md"
PREV_MAIN_REPORT="reports/pilot/faz4c/4c_6b_uat_runtime_precheck_report.md"

PACKAGE_DOC="docs/pilot/faz4c/4c_6c_uat_test_case_package.md"
ACCEPTANCE_DOC="docs/pilot/faz4c/4c_6c_uat_acceptance_criteria.md"
TEST_CASES="uat/pilot/faz4c/uzmanparcaci/uat_test_cases.md"
EXECUTION_TEMPLATE="uat/pilot/faz4c/uzmanparcaci/uat_execution_template.md"

REPORT_FILE="reports/pilot/faz4c/4c_6c_uat_test_case_package_report.md"

echo "===== 4C-6C UAT TEST CASE PACKAGE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-6B test report yok: $PREV_REPORT"
pass "4C-6B test report var"

[ -f "$PREV_MAIN_REPORT" ] || fail "4C-6B main report yok: $PREV_MAIN_REPORT"
pass "4C-6B main report var"

grep -q "4C_6B_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-6B test PASS degil"
pass "4C-6B test PASS"

grep -q "4C_6B_UAT_RUNTIME_PRECHECK_STATUS=PASS" "$PREV_REPORT" || fail "4C-6B runtime precheck PASS degil"
pass "4C-6B runtime precheck PASS"

grep -q "4C_6B_CRITICAL_BLOCKER_COUNT=0" "$PREV_MAIN_REPORT" || fail "4C-6B critical blocker 0 degil"
pass "4C-6B critical blocker 0"

grep -q "4C_6C_READY=YES" "$PREV_REPORT" || fail "4C-6C ready YES yok"
pass "4C-6C ready YES"

[ -f "$PACKAGE_DOC" ] || fail "4C-6C package doc yok"
pass "4C-6C package doc var"

[ -f "$ACCEPTANCE_DOC" ] || fail "Acceptance criteria doc yok"
pass "Acceptance criteria doc var"

[ -f "$TEST_CASES" ] || fail "UAT test cases yok"
pass "UAT test cases var"

[ -f "$EXECUTION_TEMPLATE" ] || fail "UAT execution template yok"
pass "UAT execution template var"

for n in $(seq -w 1 14); do
  grep -q "UAT-$n" "$TEST_CASES" || fail "Test cases icinde UAT-$n yok"
done
pass "UAT-01..UAT-14 test case var"

for n in $(seq -w 1 14); do
  grep -q "UAT-$n" "$EXECUTION_TEMPLATE" || fail "Execution template icinde UAT-$n yok"
done
pass "Execution template UAT-01..UAT-14 var"

grep -q "4C_6C_UAT_TEST_CASE_PACKAGE_STATUS=PASS" "$PACKAGE_DOC" || fail "Package status PASS yok"
pass "Package status PASS var"

grep -q "4C_6C_TEST_CASE_COUNT=14" "$PACKAGE_DOC" || fail "Test case count 14 yok"
pass "Test case count 14 var"

grep -q "4C_6C_ACCEPTANCE_CRITERIA_STATUS=PASS" "$ACCEPTANCE_DOC" || fail "Acceptance criteria PASS yok"
pass "Acceptance criteria PASS var"

grep -q "Critical blocker" "$ACCEPTANCE_DOC" || fail "Critical blocker kriterleri yok"
pass "Critical blocker kriterleri var"

grep -q "Blocker olmayan" "$ACCEPTANCE_DOC" || fail "Non-blocking warnings yok"
pass "Non-blocking warnings var"

grep -q "Barkod" "$ACCEPTANCE_DOC" || fail "Barkod karari yok"
pass "Barkod karari var"

grep -q "Pazaryeri" "$ACCEPTANCE_DOC" || fail "Pazaryeri scope guard yok"
pass "Pazaryeri scope guard var"

grep -q "UAT_EXECUTION_STATUS=PENDING" "$EXECUTION_TEMPLATE" || fail "Execution status PENDING yok"
pass "Execution status PENDING var"

grep -q "BUSINESS_ACCEPTANCE_STATUS=PENDING" "$EXECUTION_TEMPLATE" || fail "Business acceptance PENDING yok"
pass "Business acceptance PENDING var"

grep -q "4C_6D_READY=YES" "$PACKAGE_DOC" || fail "4C-6D ready YES yok"
pass "4C-6D ready YES var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-6C UAT Test Case Package Report

Step: 4C-6C
Blok: UAT Test Case Package
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6C_UAT_TEST_CASE_PACKAGE_STATUS=PASS
4C_6C_PREVIOUS_BLOCK_STATUS=PASS
4C_6C_ACCEPTANCE_CRITERIA_STATUS=PASS
4C_6C_TEST_CASE_COUNT=14
4C_6C_TEST_CASES_CREATED=YES
4C_6C_EXECUTION_TEMPLATE_CREATED=YES
4C_6C_CRITICAL_BLOCKER_RULES_DEFINED=YES
4C_6C_NON_BLOCKING_WARNINGS_DEFINED=YES
4C_6C_BARKOD_WARNING_IS_BLOCKER=NO
4C_6C_MARKETPLACE_SCOPE_GUARD=FAZ_4D
4C_6C_DB_WRITE_APPLIED=NO
4C_6C_CRITICAL_BLOCKER_COUNT=0
4C_6D_READY=YES

## Dosyalar

UAT_TEST_CASES=uat/pilot/faz4c/uzmanparcaci/uat_test_cases.md
UAT_EXECUTION_TEMPLATE=uat/pilot/faz4c/uzmanparcaci/uat_execution_template.md
ACCEPTANCE_CRITERIA=docs/pilot/faz4c/4c_6c_uat_acceptance_criteria.md

## Sonuc

UAT test case paketi oluşturuldu.
Bu adımda DB yazma işlemi yapılmadı.
Sonraki adım: 4C-6D UAT Execution / Evidence Capture.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-6C TEST SONUCU ====="
echo "4C_6C_UAT_TEST_CASE_PACKAGE_STATUS=PASS ✅"
echo "4C_6C_ACCEPTANCE_CRITERIA_STATUS=PASS ✅"
echo "4C_6C_TEST_CASE_COUNT=14 ✅"
echo "4C_6C_TEST_CASES_CREATED=YES ✅"
echo "4C_6C_EXECUTION_TEMPLATE_CREATED=YES ✅"
echo "4C_6C_BARKOD_WARNING_IS_BLOCKER=NO ✅"
echo "4C_6C_MARKETPLACE_SCOPE_GUARD=FAZ_4D ✅"
echo "4C_6C_DB_WRITE_APPLIED=NO ✅"
echo "4C_6D_READY=YES ✅"
