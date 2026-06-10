#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FILL_SCRIPT="scripts/pilot/fill_4c_6g_3_business_acceptance_input.sh"
APPLY_TEST_SCRIPT="scripts/pilot/test_4c_6g_2_business_acceptance_apply.sh"

FILL_REPORT="reports/pilot/faz4c/4c_6g_3_business_acceptance_input_fill_report.md"
APPLY_REPORT="reports/pilot/faz4c/4c_6g_2_business_acceptance_apply_report.md"
APPLY_TEST_REPORT="reports/pilot/faz4c/4c_6g_2_business_acceptance_apply_test_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_6g_3_business_acceptance_input_fill_test_report.md"

INPUT_ENV="docs/pilot/faz4c/4c_6g_business_acceptance_input.env"

echo "===== 4C-6G-3-FIX1 BUSINESS ACCEPTANCE INPUT FILL TEST ====="

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

[ -f "$APPLY_TEST_SCRIPT" ] || fail "4C-6G-2 apply test script yok"
pass "4C-6G-2 apply test script var"

[ -x "$APPLY_TEST_SCRIPT" ] || fail "4C-6G-2 apply test script executable degil"
pass "4C-6G-2 apply test script executable"

bash "$FILL_SCRIPT"

[ -f "$FILL_REPORT" ] || fail "Fill report yok"
pass "Fill report var"

grep -q "4C_6G_3_BUSINESS_ACCEPTANCE_INPUT_FILL_STATUS=PASS" "$FILL_REPORT" || fail "Fill status PASS degil"
pass "Fill status PASS"

grep -q "4C_6G_3_BUSINESS_ACCEPTANCE_STATUS=PASS" "$FILL_REPORT" || fail "Business acceptance PASS degil"
pass "Business acceptance PASS"

grep -q "4C_6G_3_PENDING_FIELD_COUNT=0" "$FILL_REPORT" || fail "Pending field count 0 degil"
pass "Pending field count 0"

grep -q '^BUSINESS_ACCEPTANCE_STATUS="PASS"' "$INPUT_ENV" || fail "Input env PASS degil"
pass "Input env PASS"

grep -q '^BUSINESS_ACCEPTS_TENANT_ACCESS="YES"' "$INPUT_ENV" || fail "Tenant access YES degil"
pass "Tenant access YES"

grep -q '^BUSINESS_ACCEPTS_MARKETPLACE_PHASE_4D="YES"' "$INPUT_ENV" || fail "Marketplace phase 4D YES degil"
pass "Marketplace phase 4D YES"

echo
echo "===== 4C-6G-2 TEKRAR CALISTIRILIYOR ====="
bash "$APPLY_TEST_SCRIPT"

[ -f "$APPLY_REPORT" ] || fail "4C-6G-2 apply report yok"
pass "4C-6G-2 apply report var"

[ -f "$APPLY_TEST_REPORT" ] || fail "4C-6G-2 apply test report yok"
pass "4C-6G-2 apply test report var"

grep -q "4C_6G_2_BUSINESS_ACCEPTANCE_APPLY_STATUS=PASS" "$APPLY_REPORT" || fail "4C-6G-2 apply PASS degil"
pass "4C-6G-2 apply PASS"

grep -q "4C_6G_2_BUSINESS_ACCEPTANCE_STATUS=PASS" "$APPLY_REPORT" || fail "4C-6G-2 acceptance PASS degil"
pass "4C-6G-2 acceptance PASS"

grep -q "4C_6G_2_FINAL_UAT_RESULT=PASS" "$APPLY_REPORT" || fail "4C-6G-2 final UAT PASS degil"
pass "4C-6G-2 final UAT PASS"

grep -q "4C_6G_2_GO_NO_GO_READY=YES" "$APPLY_REPORT" || fail "4C-6G-2 go/no-go YES degil"
pass "4C-6G-2 go/no-go YES"

grep -q "4C_6G_2_PENDING_FIELD_COUNT=0" "$APPLY_REPORT" || fail "4C-6G-2 pending count 0 degil"
pass "4C-6G-2 pending count 0"

grep -q "4C_6G_2_DB_WRITE_APPLIED=NO" "$APPLY_REPORT" || fail "4C-6G-2 DB write NO degil"
pass "4C-6G-2 DB write NO"

grep -q "4C_6H_READY=YES" "$APPLY_REPORT" || fail "4C-6H ready YES degil"
pass "4C-6H ready YES"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-6G-3 Business Acceptance Input Fill Test Report

Step: 4C-6G-3-FIX1
Blok: Business Acceptance Input Fill Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6G_3_TEST_STATUS=PASS
4C_6G_3_FIX_STATUS=PASS
4C_6G_3_BUSINESS_ACCEPTANCE_INPUT_FILL_STATUS=PASS
4C_6G_3_BUSINESS_ACCEPTANCE_STATUS=PASS
4C_6G_3_PENDING_FIELD_COUNT=0
4C_6G_2_RETRY_STATUS=PASS
4C_6G_2_BUSINESS_ACCEPTANCE_APPLY_STATUS=PASS
4C_6G_2_FINAL_UAT_RESULT=PASS
4C_6G_2_GO_NO_GO_READY=YES
4C_6G_2_PENDING_FIELD_COUNT=0
4C_6G_3_DB_WRITE_APPLIED=NO
4C_6H_READY=YES

## Sonuc

Business acceptance PASS olarak islendi.
4C-6G-2 tekrar calistirildi ve PASS oldu.
DB yazma islemi yapilmadi.
4C-6H final closure adimina gecilebilir.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-6G-3-FIX1 TEST SONUCU ====="
echo "4C_6G_3_TEST_STATUS=PASS ✅"
echo "4C_6G_3_BUSINESS_ACCEPTANCE_STATUS=PASS ✅"
echo "4C_6G_2_BUSINESS_ACCEPTANCE_APPLY_STATUS=PASS ✅"
echo "4C_6G_2_FINAL_UAT_RESULT=PASS ✅"
echo "4C_6G_2_GO_NO_GO_READY=YES ✅"
echo "4C_6G_2_PENDING_FIELD_COUNT=0 ✅"
echo "4C_6G_3_DB_WRITE_APPLIED=NO ✅"
echo "4C_6H_READY=YES ✅"
