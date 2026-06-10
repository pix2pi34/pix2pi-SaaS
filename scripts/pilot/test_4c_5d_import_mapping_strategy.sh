#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_5d_import_mapping_strategy.sh"
PREV_REPORT="reports/pilot/faz4c/4c_5c_product_stock_table_discovery_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_5d_import_mapping_strategy_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_5d_import_mapping_strategy_test_report.md"
ENV_FILE="docs/pilot/faz4c/4c_5d_import_mapping_strategy.env"

echo "===== 4C-5D IMPORT MAPPING STRATEGY TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-5C test report yok: $PREV_REPORT"
pass "4C-5C test report var"

grep -q "4C_5C_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-5C test PASS degil"
pass "4C-5C test PASS"

grep -q "4C_5D_READY=YES" "$PREV_REPORT" || fail "4C-5D ready YES yok"
pass "4C-5D ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-5D report yok: $REPORT_FILE"
pass "4C-5D report var"

[ -f "$ENV_FILE" ] || fail "4C-5D env yok: $ENV_FILE"
pass "4C-5D env var"

grep -q "4C_5D_IMPORT_MAPPING_STRATEGY_STATUS=PASS" "$REPORT_FILE" || fail "Strategy PASS degil"
pass "Strategy PASS"

grep -q "4C_5D_SELECTED_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING" "$REPORT_FILE" || fail "Selected strategy staging-first degil"
pass "Selected strategy staging-first"

grep -q "4C_5D_CORE_DIRECT_APPLY_NOW=NO" "$REPORT_FILE" || fail "Core direct apply NO degil"
pass "Core direct apply NO"

grep -q "4C_5D_STAGING_TABLE_CREATE_NEEDED=YES" "$REPORT_FILE" || fail "Staging table create needed YES degil"
pass "Staging table create needed YES"

grep -q "4C_5D_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging" "$REPORT_FILE" || fail "Staging table beklenen degil"
pass "Staging table beklenen"

grep -q "4C_5D_PRODUCT_TABLE=public.erp_items" "$REPORT_FILE" || fail "Product table public.erp_items degil"
pass "Product table public.erp_items"

grep -q "4C_5D_STOCK_TABLE=public.erp_stock_movements" "$REPORT_FILE" || fail "Stock table public.erp_stock_movements degil"
pass "Stock table public.erp_stock_movements"

grep -q "4C_5D_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_5D_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_5E_READY=YES" "$REPORT_FILE" || fail "4C-5E ready YES yok"
pass "4C-5E ready YES"

CORE_DIRECT_REQUIRED_OK="$(grep '^4C_5D_CORE_DIRECT_REQUIRED_OK=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2- | tr -d ' ')"
AUTO_PART_SPECIAL_DIRECT_OK="$(grep '^4C_5D_AUTO_PART_SPECIAL_DIRECT_OK=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2- | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_5D_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-5D Import Mapping Strategy Test Report

Step: 4C-5D
Blok: Import Mapping Strategy Decision Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5D_TEST_STATUS=PASS
4C_5D_IMPORT_MAPPING_STRATEGY_STATUS=PASS
4C_5D_SELECTED_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING
4C_5D_CORE_DIRECT_APPLY_NOW=NO
4C_5D_STAGING_TABLE_CREATE_NEEDED=YES
4C_5D_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
4C_5D_PRODUCT_TABLE=public.erp_items
4C_5D_STOCK_TABLE=public.erp_stock_movements
4C_5D_CORE_DIRECT_REQUIRED_OK=$CORE_DIRECT_REQUIRED_OK
4C_5D_AUTO_PART_SPECIAL_DIRECT_OK=$AUTO_PART_SPECIAL_DIRECT_OK
4C_5D_WARNING_COUNT=$WARNING_COUNT
4C_5D_DB_WRITE_APPLIED=NO
4C_5E_READY=YES

## Sonuc

Import mapping strategy decision test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-5E Sample CSV Generation / Validation.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-5D TEST SONUCU ====="
echo "4C_5D_TEST_STATUS=PASS ✅"
echo "4C_5D_IMPORT_MAPPING_STRATEGY_STATUS=PASS ✅"
echo "4C_5D_SELECTED_STRATEGY=STAGING_FIRST_THEN_CORE_MAPPING ✅"
echo "4C_5D_CORE_DIRECT_APPLY_NOW=NO ✅"
echo "4C_5D_STAGING_TABLE_CREATE_NEEDED=YES ✅"
echo "4C_5D_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging ✅"
echo "4C_5D_PRODUCT_TABLE=public.erp_items ✅"
echo "4C_5D_STOCK_TABLE=public.erp_stock_movements ✅"
echo "4C_5D_DB_WRITE_APPLIED=NO ✅"
echo "4C_5E_READY=YES ✅"
