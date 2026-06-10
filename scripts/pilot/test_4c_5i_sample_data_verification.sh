#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_5i_sample_data_verification.sh"
PREV_REPORT="reports/pilot/faz4c/4c_5h_controlled_sample_data_apply_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_5i_sample_data_verification_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_5i_sample_data_verification_test_report.md"

echo "===== 4C-5I SAMPLE DATA VERIFICATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-5H test report yok: $PREV_REPORT"
pass "4C-5H test report var"

grep -q "4C_5H_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-5H test PASS degil"
pass "4C-5H test PASS"

grep -q "4C_5I_READY=YES" "$PREV_REPORT" || fail "4C-5I ready YES yok"
pass "4C-5I ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-5I report yok: $REPORT_FILE"
pass "4C-5I report var"

grep -q "4C_5I_SAMPLE_DATA_VERIFICATION_STATUS=PASS" "$REPORT_FILE" || fail "Sample data verification PASS degil"
pass "Sample data verification PASS"

grep -q "4C_5I_STAGING_TABLE_EXISTS=1" "$REPORT_FILE" || fail "Staging table exists 1 degil"
pass "Staging table exists 1"

grep -q "4C_5I_ROW_COUNT=5" "$REPORT_FILE" || fail "Row count 5 degil"
pass "Row count 5"

grep -q "4C_5I_DUPLICATE_SKU_COUNT=0" "$REPORT_FILE" || fail "Duplicate SKU count 0 degil"
pass "Duplicate SKU count 0"

grep -q "4C_5I_TENANT_MISMATCH_COUNT=0" "$REPORT_FILE" || fail "Tenant mismatch count 0 degil"
pass "Tenant mismatch count 0"

grep -q "4C_5I_REQUIRED_TEXT_BLANK_COUNT=0" "$REPORT_FILE" || fail "Required text blank count 0 degil"
pass "Required text blank count 0"

grep -q "4C_5I_NUMERIC_INVALID_COUNT=0" "$REPORT_FILE" || fail "Numeric invalid count 0 degil"
pass "Numeric invalid count 0"

grep -q "4C_5I_SALE_LT_PURCHASE_COUNT=0" "$REPORT_FILE" || fail "Sale < purchase count 0 degil"
pass "Sale < purchase count 0"

grep -q "4C_5I_INVALID_CURRENCY_COUNT=0" "$REPORT_FILE" || fail "Invalid currency count 0 degil"
pass "Invalid currency count 0"

grep -q "4C_5I_VALIDATION_STATUS_COUNT=5" "$REPORT_FILE" || fail "Validation status count 5 degil"
pass "Validation status count 5"

grep -q "4C_5I_EXPECTED_SKU_MATCH_COUNT=5" "$REPORT_FILE" || fail "Expected SKU match count 5 degil"
pass "Expected SKU match count 5"

grep -q "4C_5I_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_5I_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_5J_READY=YES" "$REPORT_FILE" || fail "4C-5J ready YES yok"
pass "4C-5J ready YES"

BARCODE_BLANK_COUNT="$(grep '^4C_5I_BARCODE_BLANK_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_5I_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
DISTINCT_CATEGORY_COUNT="$(grep '^4C_5I_DISTINCT_CATEGORY_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
DISTINCT_PART_GROUP_COUNT="$(grep '^4C_5I_DISTINCT_PART_GROUP_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat > "$TEST_REPORT" <<REPORT_EOF
# FAZ 4C — 4C-5I Sample Data Verification Test Report

Step: 4C-5I
Blok: Sample Data Verification Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5I_TEST_STATUS=PASS
4C_5I_SAMPLE_DATA_VERIFICATION_STATUS=PASS
4C_5I_STAGING_TABLE_EXISTS=1
4C_5I_ROW_COUNT=5
4C_5I_DUPLICATE_SKU_COUNT=0
4C_5I_TENANT_MISMATCH_COUNT=0
4C_5I_REQUIRED_TEXT_BLANK_COUNT=0
4C_5I_NUMERIC_INVALID_COUNT=0
4C_5I_SALE_LT_PURCHASE_COUNT=0
4C_5I_INVALID_CURRENCY_COUNT=0
4C_5I_VALIDATION_STATUS_COUNT=5
4C_5I_EXPECTED_SKU_MATCH_COUNT=5
4C_5I_DISTINCT_CATEGORY_COUNT=$DISTINCT_CATEGORY_COUNT
4C_5I_DISTINCT_PART_GROUP_COUNT=$DISTINCT_PART_GROUP_COUNT
4C_5I_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT
4C_5I_WARNING_COUNT=$WARNING_COUNT
4C_5I_DB_WRITE_APPLIED=NO
4C_5J_READY=YES

## Sonuc

Sample data verification test tamamlandi.
Kalici DB yazma yapilmadi.
Sonraki adim: 4C-5J Real Pilot Data Entry / Import Final Closure.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-5I TEST SONUCU ====="
echo "4C_5I_TEST_STATUS=PASS ✅"
echo "4C_5I_SAMPLE_DATA_VERIFICATION_STATUS=PASS ✅"
echo "4C_5I_STAGING_TABLE_EXISTS=1 ✅"
echo "4C_5I_ROW_COUNT=5 ✅"
echo "4C_5I_DUPLICATE_SKU_COUNT=0 ✅"
echo "4C_5I_TENANT_MISMATCH_COUNT=0 ✅"
echo "4C_5I_REQUIRED_TEXT_BLANK_COUNT=0 ✅"
echo "4C_5I_NUMERIC_INVALID_COUNT=0 ✅"
echo "4C_5I_SALE_LT_PURCHASE_COUNT=0 ✅"
echo "4C_5I_INVALID_CURRENCY_COUNT=0 ✅"
echo "4C_5I_VALIDATION_STATUS_COUNT=5 ✅"
echo "4C_5I_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT ⚠️"
echo "4C_5I_DB_WRITE_APPLIED=NO ✅"
echo "4C_5J_READY=YES ✅"
