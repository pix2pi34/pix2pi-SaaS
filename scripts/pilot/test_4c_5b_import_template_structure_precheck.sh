#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_5b_import_template_structure_precheck.sh"
PREV_REPORT="reports/pilot/faz4c/4c_5a_data_import_scope_freeze_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_5b_import_template_structure_precheck_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_5b_import_template_structure_precheck_test_report.md"

echo "===== 4C-5B IMPORT TEMPLATE STRUCTURE PRECHECK TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-5A report yok: $PREV_REPORT"
pass "4C-5A report var"

grep -q "4C_5A_DATA_IMPORT_SCOPE_STATUS=PASS" "$PREV_REPORT" || fail "4C-5A PASS degil"
pass "4C-5A PASS"

grep -q "4C_5B_READY=YES" "$PREV_REPORT" || fail "4C-5B ready YES yok"
pass "4C-5B ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-5B report yok: $REPORT_FILE"
pass "4C-5B report var"

grep -q "4C_5B_IMPORT_TEMPLATE_STRUCTURE_STATUS=PASS" "$REPORT_FILE" || fail "Template structure PASS degil"
pass "Template structure PASS"

grep -q "4C_5B_CSV_FILE_FOUND=YES" "$REPORT_FILE" || fail "CSV file found YES degil"
pass "CSV file found YES"

grep -q "4C_5B_HEADER_COLUMN_COUNT=15" "$REPORT_FILE" || fail "Header column count 15 degil"
pass "Header column count 15"

grep -q "4C_5B_EXPECTED_COLUMN_COUNT=15" "$REPORT_FILE" || fail "Expected column count 15 degil"
pass "Expected column count 15"

grep -q "4C_5B_HEADER_ORDER_STATUS=PASS" "$REPORT_FILE" || fail "Header order PASS degil"
pass "Header order PASS"

grep -q "4C_5B_MISSING_COLUMN_COUNT=0" "$REPORT_FILE" || fail "Missing column count 0 degil"
pass "Missing column count 0"

grep -q "4C_5B_SAMPLE_ROW_COUNT=1" "$REPORT_FILE" || fail "Sample row count 1 degil"
pass "Sample row count 1"

grep -q "4C_5B_DUPLICATE_SKU_COUNT=0" "$REPORT_FILE" || fail "Duplicate SKU count 0 degil"
pass "Duplicate SKU count 0"

grep -q "4C_5B_ROW_ERROR_COUNT=0" "$REPORT_FILE" || fail "Row error count 0 degil"
pass "Row error count 0"

grep -q "4C_5B_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_5B_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_5C_READY=YES" "$REPORT_FILE" || fail "4C-5C ready YES yok"
pass "4C-5C ready YES"

WARNING_COUNT="$(grep '^4C_5B_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
ROW_WARNING_COUNT="$(grep '^4C_5B_ROW_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-5B Import Template Structure Precheck Test Report

Step: 4C-5B
Blok: Import Template Structure Precheck Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5B_TEST_STATUS=PASS
4C_5B_IMPORT_TEMPLATE_STRUCTURE_STATUS=PASS
4C_5B_CSV_FILE_FOUND=YES
4C_5B_HEADER_COLUMN_COUNT=15
4C_5B_EXPECTED_COLUMN_COUNT=15
4C_5B_HEADER_ORDER_STATUS=PASS
4C_5B_MISSING_COLUMN_COUNT=0
4C_5B_SAMPLE_ROW_COUNT=1
4C_5B_DUPLICATE_SKU_COUNT=0
4C_5B_ROW_ERROR_COUNT=0
4C_5B_ROW_WARNING_COUNT=$ROW_WARNING_COUNT
4C_5B_WARNING_COUNT=$WARNING_COUNT
4C_5B_DB_WRITE_APPLIED=NO
4C_5C_READY=YES

## Sonuc

Import template structure precheck test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-5C Product / Stock Table Discovery.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-5B TEST SONUCU ====="
echo "4C_5B_TEST_STATUS=PASS ✅"
echo "4C_5B_IMPORT_TEMPLATE_STRUCTURE_STATUS=PASS ✅"
echo "4C_5B_HEADER_COLUMN_COUNT=15 ✅"
echo "4C_5B_HEADER_ORDER_STATUS=PASS ✅"
echo "4C_5B_MISSING_COLUMN_COUNT=0 ✅"
echo "4C_5B_SAMPLE_ROW_COUNT=1 ✅"
echo "4C_5B_DUPLICATE_SKU_COUNT=0 ✅"
echo "4C_5B_ROW_ERROR_COUNT=0 ✅"
echo "4C_5B_DB_WRITE_APPLIED=NO ✅"
echo "4C_5C_READY=YES ✅"
