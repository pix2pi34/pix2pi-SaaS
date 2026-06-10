#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_5e_sample_csv_generation_validation.sh"
PREV_REPORT="reports/pilot/faz4c/4c_5d_import_mapping_strategy_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_5e_sample_csv_generation_validation_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_5e_sample_csv_generation_validation_test_report.md"
SAMPLE_CSV="imports/pilot/faz4c/uzmanparcaci/product_import_sample.csv"

echo "===== 4C-5E SAMPLE CSV GENERATION / VALIDATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-5D test report yok: $PREV_REPORT"
pass "4C-5D test report var"

grep -q "4C_5D_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-5D test PASS degil"
pass "4C-5D test PASS"

grep -q "4C_5E_READY=YES" "$PREV_REPORT" || fail "4C-5E ready YES yok"
pass "4C-5E ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-5E report yok: $REPORT_FILE"
pass "4C-5E report var"

[ -f "$SAMPLE_CSV" ] || fail "Sample CSV yok: $SAMPLE_CSV"
pass "Sample CSV var"

grep -q "4C_5E_SAMPLE_CSV_VALIDATION_STATUS=PASS" "$REPORT_FILE" || fail "Sample validation PASS degil"
pass "Sample validation PASS"

grep -q "4C_5E_SAMPLE_CSV_CREATED=YES" "$REPORT_FILE" || fail "Sample CSV created YES degil"
pass "Sample CSV created YES"

grep -q "4C_5E_HEADER_COLUMN_COUNT=15" "$REPORT_FILE" || fail "Header column count 15 degil"
pass "Header column count 15"

grep -q "4C_5E_EXPECTED_COLUMN_COUNT=15" "$REPORT_FILE" || fail "Expected column count 15 degil"
pass "Expected column count 15"

grep -q "4C_5E_HEADER_ORDER_STATUS=PASS" "$REPORT_FILE" || fail "Header order PASS degil"
pass "Header order PASS"

grep -q "4C_5E_MISSING_COLUMN_COUNT=0" "$REPORT_FILE" || fail "Missing column count 0 degil"
pass "Missing column count 0"

grep -q "4C_5E_SAMPLE_ROW_COUNT=5" "$REPORT_FILE" || fail "Sample row count 5 degil"
pass "Sample row count 5"

grep -q "4C_5E_DUPLICATE_SKU_COUNT=0" "$REPORT_FILE" || fail "Duplicate SKU count 0 degil"
pass "Duplicate SKU count 0"

grep -q "4C_5E_ROW_ERROR_COUNT=0" "$REPORT_FILE" || fail "Row error count 0 degil"
pass "Row error count 0"

grep -q "4C_5E_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_5E_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_5F_READY=YES" "$REPORT_FILE" || fail "4C-5F ready YES yok"
pass "4C-5F ready YES"

BARCODE_BLANK_COUNT="$(grep '^4C_5E_BARCODE_BLANK_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_5E_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-5E Sample CSV Generation Validation Test Report

Step: 4C-5E
Blok: Sample CSV Generation / Validation Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5E_TEST_STATUS=PASS
4C_5E_SAMPLE_CSV_VALIDATION_STATUS=PASS
4C_5E_SAMPLE_CSV_CREATED=YES
4C_5E_HEADER_COLUMN_COUNT=15
4C_5E_EXPECTED_COLUMN_COUNT=15
4C_5E_HEADER_ORDER_STATUS=PASS
4C_5E_MISSING_COLUMN_COUNT=0
4C_5E_SAMPLE_ROW_COUNT=5
4C_5E_DUPLICATE_SKU_COUNT=0
4C_5E_ROW_ERROR_COUNT=0
4C_5E_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT
4C_5E_WARNING_COUNT=$WARNING_COUNT
4C_5E_DB_WRITE_APPLIED=NO
4C_5F_READY=YES

## Sonuc

Sample CSV generation / validation test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-5F Import SQL Package / Dry Run Plan.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-5E TEST SONUCU ====="
echo "4C_5E_TEST_STATUS=PASS ✅"
echo "4C_5E_SAMPLE_CSV_VALIDATION_STATUS=PASS ✅"
echo "4C_5E_SAMPLE_CSV_CREATED=YES ✅"
echo "4C_5E_HEADER_COLUMN_COUNT=15 ✅"
echo "4C_5E_SAMPLE_ROW_COUNT=5 ✅"
echo "4C_5E_DUPLICATE_SKU_COUNT=0 ✅"
echo "4C_5E_ROW_ERROR_COUNT=0 ✅"
echo "4C_5E_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT ⚠️"
echo "4C_5E_DB_WRITE_APPLIED=NO ✅"
echo "4C_5F_READY=YES ✅"
