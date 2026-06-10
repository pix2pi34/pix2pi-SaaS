#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FINAL_DOC="docs/pilot/faz4c/4c_5j_real_pilot_data_import_final_closure.md"
ALIAS_DOC="docs/pilot/faz4c/4c_5_final_closure.md"

A_REPORT="reports/pilot/faz4c/4c_5a_data_import_scope_freeze_report.md"
B_REPORT="reports/pilot/faz4c/4c_5b_import_template_structure_precheck_test_report.md"
C_REPORT="reports/pilot/faz4c/4c_5c_product_stock_table_discovery_test_report.md"
D_REPORT="reports/pilot/faz4c/4c_5d_import_mapping_strategy_test_report.md"
E_REPORT="reports/pilot/faz4c/4c_5e_sample_csv_generation_validation_test_report.md"
F_REPORT="reports/pilot/faz4c/4c_5f_import_sql_package_test_report.md"
G_REPORT="reports/pilot/faz4c/4c_5g_import_dry_run_rollback_test_report.md"
H_REPORT="reports/pilot/faz4c/4c_5h_controlled_sample_data_apply_test_report.md"
I_REPORT="reports/pilot/faz4c/4c_5i_sample_data_verification_test_report.md"
I_MAIN_REPORT="reports/pilot/faz4c/4c_5i_sample_data_verification_report.md"
SAMPLE_CSV="imports/pilot/faz4c/uzmanparcaci/product_import_sample.csv"

REPORT_FILE="reports/pilot/faz4c/4c_5j_real_pilot_data_import_final_closure_report.md"

echo "===== 4C-5J REAL PILOT DATA ENTRY / IMPORT FINAL CLOSURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$FINAL_DOC" ] || fail "4C-5J final closure dokumani yok"
pass "4C-5J final closure dokumani var"

[ -f "$ALIAS_DOC" ] || fail "4C-5 final closure alias dokumani yok"
pass "4C-5 final closure alias dokumani var"

for report in "$A_REPORT" "$B_REPORT" "$C_REPORT" "$D_REPORT" "$E_REPORT" "$F_REPORT" "$G_REPORT" "$H_REPORT" "$I_REPORT" "$I_MAIN_REPORT"; do
  [ -f "$report" ] || fail "Eksik report: $report"
done
pass "Tum onceki report dosyalari var"

[ -f "$SAMPLE_CSV" ] || fail "Sample CSV yok: $SAMPLE_CSV"
pass "Sample CSV var"

grep -q "4C_5A_DATA_IMPORT_SCOPE_STATUS=PASS" "$A_REPORT" || fail "4C-5A PASS degil"
pass "4C-5A PASS"

grep -q "4C_5B_TEST_STATUS=PASS" "$B_REPORT" || fail "4C-5B PASS degil"
pass "4C-5B PASS"

grep -q "4C_5C_TEST_STATUS=PASS" "$C_REPORT" || fail "4C-5C PASS degil"
pass "4C-5C PASS"

grep -q "4C_5D_TEST_STATUS=PASS" "$D_REPORT" || fail "4C-5D PASS degil"
pass "4C-5D PASS"

grep -q "4C_5D_SELECTED_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING" "$D_REPORT" || fail "4C-5D staging-first strategy yok"
pass "4C-5D staging-first strategy"

grep -q "4C_5D_CORE_DIRECT_APPLY_NOW=NO" "$D_REPORT" || fail "4C-5D core direct apply NO yok"
pass "4C-5D core direct apply NO"

grep -q "4C_5E_TEST_STATUS=PASS" "$E_REPORT" || fail "4C-5E PASS degil"
pass "4C-5E PASS"

grep -q "4C_5E_SAMPLE_ROW_COUNT=5" "$E_REPORT" || fail "4C-5E sample row count 5 degil"
pass "4C-5E sample row count 5"

grep -q "4C_5F_TEST_STATUS=PASS" "$F_REPORT" || fail "4C-5F PASS degil"
pass "4C-5F PASS"

grep -q "4C_5F_SQL_HAS_ROLLBACK=YES" "$F_REPORT" || fail "4C-5F rollback YES yok"
pass "4C-5F rollback YES"

grep -q "4C_5F_SQL_HAS_COMMIT=NO" "$F_REPORT" || fail "4C-5F commit NO yok"
pass "4C-5F commit NO"

grep -q "4C_5G_TEST_STATUS=PASS" "$G_REPORT" || fail "4C-5G PASS degil"
pass "4C-5G PASS"

grep -q "4C_5G_ROLLBACK_VERIFIED=YES" "$G_REPORT" || fail "4C-5G rollback verified YES yok"
pass "4C-5G rollback verified YES"

grep -q "4C_5G_DB_WRITE_APPLIED=NO" "$G_REPORT" || fail "4C-5G DB write NO yok"
pass "4C-5G DB write NO"

grep -q "4C_5H_TEST_STATUS=PASS" "$H_REPORT" || fail "4C-5H PASS degil"
pass "4C-5H PASS"

grep -q "4C_5H_AFTER_TABLE_EXISTS=1" "$H_REPORT" || fail "4C-5H after table exists 1 degil"
pass "4C-5H after table exists 1"

grep -q "4C_5H_AFTER_ROW_COUNT=5" "$H_REPORT" || fail "4C-5H after row count 5 degil"
pass "4C-5H after row count 5"

grep -q "4C_5H_DB_WRITE_APPLIED=YES" "$H_REPORT" || fail "4C-5H DB write YES yok"
pass "4C-5H DB write YES"

grep -q "4C_5I_TEST_STATUS=PASS" "$I_REPORT" || fail "4C-5I PASS degil"
pass "4C-5I PASS"

grep -q "4C_5I_SAMPLE_DATA_VERIFICATION_STATUS=PASS" "$I_MAIN_REPORT" || fail "4C-5I verification PASS yok"
pass "4C-5I verification PASS"

grep -q "4C_5I_ROW_COUNT=5" "$I_MAIN_REPORT" || fail "4C-5I row count 5 degil"
pass "4C-5I row count 5"

grep -q "4C_5I_DUPLICATE_SKU_COUNT=0" "$I_MAIN_REPORT" || fail "4C-5I duplicate sku 0 degil"
pass "4C-5I duplicate sku 0"

grep -q "4C_5I_TENANT_MISMATCH_COUNT=0" "$I_MAIN_REPORT" || fail "4C-5I tenant mismatch 0 degil"
pass "4C-5I tenant mismatch 0"

grep -q "4C_5I_REQUIRED_TEXT_BLANK_COUNT=0" "$I_MAIN_REPORT" || fail "4C-5I required text blank 0 degil"
pass "4C-5I required text blank 0"

grep -q "4C_5I_NUMERIC_INVALID_COUNT=0" "$I_MAIN_REPORT" || fail "4C-5I numeric invalid 0 degil"
pass "4C-5I numeric invalid 0"

grep -q "4C_5I_INVALID_CURRENCY_COUNT=0" "$I_MAIN_REPORT" || fail "4C-5I invalid currency 0 degil"
pass "4C-5I invalid currency 0"

grep -q "4C_5I_CRITICAL_BLOCKER_COUNT=0" "$I_MAIN_REPORT" || fail "4C-5I critical blocker 0 degil"
pass "4C-5I critical blocker 0"

grep -q "4C_5I_BARCODE_BLANK_COUNT=5" "$I_MAIN_REPORT" || fail "4C-5I barcode blank count 5 yok"
pass "4C-5I barcode blank count 5"

grep -q "4C_5J_READY=YES" "$I_MAIN_REPORT" || fail "4C-5J ready YES yok"
pass "4C-5J ready YES"

grep -q "4C_5_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-5 final status PASS yok"
pass "4C-5 final status PASS"

grep -q "4C_5_REAL_PILOT_DATA_ENTRY_IMPORT_STATUS=PASS" "$FINAL_DOC" || fail "4C-5 import status PASS yok"
pass "4C-5 import status PASS"

grep -q "4C_5_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging" "$FINAL_DOC" || fail "4C-5 staging table yok"
pass "4C-5 staging table var"

grep -q "4C_5_SELECTED_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING" "$FINAL_DOC" || fail "4C-5 selected strategy yok"
pass "4C-5 selected strategy var"

grep -q "4C_5_SAMPLE_ROW_COUNT=5" "$FINAL_DOC" || fail "4C-5 sample row count 5 yok"
pass "4C-5 sample row count 5"

grep -q "4C_5_DUPLICATE_SKU_COUNT=0" "$FINAL_DOC" || fail "4C-5 duplicate sku 0 yok"
pass "4C-5 duplicate sku 0"

grep -q "4C_5_TENANT_MISMATCH_COUNT=0" "$FINAL_DOC" || fail "4C-5 tenant mismatch 0 yok"
pass "4C-5 tenant mismatch 0"

grep -q "4C_5_STAGING_DB_WRITE_APPLIED=YES" "$FINAL_DOC" || fail "4C-5 staging DB write YES yok"
pass "4C-5 staging DB write YES"

grep -q "4C_5_CORE_DB_WRITE_APPLIED=NO" "$FINAL_DOC" || fail "4C-5 core DB write NO yok"
pass "4C-5 core DB write NO"

grep -q "4C_5_CRITICAL_BLOCKER_COUNT=0" "$FINAL_DOC" || fail "4C-5 critical blocker 0 yok"
pass "4C-5 critical blocker 0"

grep -q "4C_6_READY=YES" "$FINAL_DOC" || fail "4C-6 ready YES yok"
pass "4C-6 ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-5J Real Pilot Data Entry / Import Final Closure Report

Step: 4C-5J
Blok: Real Pilot Data Entry / Import Final Closure
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5J_FINAL_DOC_STATUS=PASS
4C_5J_ALIAS_DOC_STATUS=PASS
4C_5A_STATUS=PASS
4C_5B_STATUS=PASS
4C_5C_STATUS=PASS
4C_5D_STATUS=PASS
4C_5E_STATUS=PASS
4C_5F_STATUS=PASS
4C_5G_STATUS=PASS
4C_5H_STATUS=PASS
4C_5I_STATUS=PASS
4C_5_FINAL_STATUS=PASS
4C_5_REAL_PILOT_DATA_ENTRY_IMPORT_STATUS=PASS
4C_5_TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439
4C_5_TENANT_BUSINESS_CODE=UZMANPARCACI
4C_5_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
4C_5_SELECTED_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING
4C_5_CORE_DIRECT_APPLY_NOW=NO
4C_5_SAMPLE_ROW_COUNT=5
4C_5_DUPLICATE_SKU_COUNT=0
4C_5_TENANT_MISMATCH_COUNT=0
4C_5_DATA_VALIDATION_STATUS=PASS
4C_5_STAGING_DB_WRITE_APPLIED=YES
4C_5_CORE_DB_WRITE_APPLIED=NO
4C_5_BARCODE_BLANK_COUNT=5
4C_5_BARCODE_BLANK_IS_BLOCKER=NO
4C_5_CRITICAL_BLOCKER_COUNT=0
4C_5_WARNING_COUNT=1
4C_6_READY=YES

## Sonuc

4C-5 Real Pilot Data Entry / Import ana blogu kapandi.
uzmanparcaci sample ürün verileri staging-first yaklaşımıyla başarıyla import edildi.
Sonraki ana blok: 4C-6 Real UAT Execution.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-5J TEST SONUCU ====="
echo "4C_5_FINAL_STATUS=PASS ✅"
echo "4C_5_REAL_PILOT_DATA_ENTRY_IMPORT_STATUS=PASS ✅"
echo "4C_5_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging ✅"
echo "4C_5_SELECTED_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING ✅"
echo "4C_5_SAMPLE_ROW_COUNT=5 ✅"
echo "4C_5_DUPLICATE_SKU_COUNT=0 ✅"
echo "4C_5_TENANT_MISMATCH_COUNT=0 ✅"
echo "4C_5_DATA_VALIDATION_STATUS=PASS ✅"
echo "4C_5_STAGING_DB_WRITE_APPLIED=YES ✅"
echo "4C_5_CORE_DB_WRITE_APPLIED=NO ✅"
echo "4C_5_BARCODE_BLANK_IS_BLOCKER=NO ⚠️"
echo "4C_5_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_6_READY=YES ✅"
