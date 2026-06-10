#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_5c_product_stock_table_discovery.sh"
PREV_REPORT="reports/pilot/faz4c/4c_5b_import_template_structure_precheck_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_5c_product_stock_table_discovery_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_5c_product_stock_table_discovery_test_report.md"

echo "===== 4C-5C PRODUCT / STOCK TABLE DISCOVERY TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-5B test report yok: $PREV_REPORT"
pass "4C-5B test report var"

grep -q "4C_5B_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-5B test PASS degil"
pass "4C-5B test PASS"

grep -q "4C_5C_READY=YES" "$PREV_REPORT" || fail "4C-5C ready YES yok"
pass "4C-5C ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-5C report yok: $REPORT_FILE"
pass "4C-5C report var"

grep -q "4C_5C_PRODUCT_STOCK_DISCOVERY_STATUS=PASS" "$REPORT_FILE" || fail "Discovery PASS degil"
pass "Discovery PASS"

grep -q "4C_5C_DB_CONNECT_STATUS=PASS" "$REPORT_FILE" || fail "DB connect PASS degil"
pass "DB connect PASS"

grep -q "4C_5C_TENANT_COUNT=1" "$REPORT_FILE" || fail "Tenant count 1 degil"
pass "Tenant count 1"

grep -q "4C_5C_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_5D_READY=YES" "$REPORT_FILE" || fail "4C-5D ready YES yok"
pass "4C-5D ready YES"

PRODUCT_TABLE_COUNT="$(grep '^4C_5C_PRODUCT_TABLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
STOCK_TABLE_COUNT="$(grep '^4C_5C_STOCK_TABLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
CATEGORY_TABLE_COUNT="$(grep '^4C_5C_CATEGORY_TABLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
UNIT_TABLE_COUNT="$(grep '^4C_5C_UNIT_TABLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
BEST_PRODUCT_TABLE="$(grep '^4C_5C_BEST_PRODUCT_TABLE=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2- | tr -d ' ')"
BEST_STOCK_TABLE="$(grep '^4C_5C_BEST_STOCK_TABLE=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2- | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_5C_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-5C Product Stock Table Discovery Test Report

Step: 4C-5C
Blok: Product / Stock Table Discovery Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5C_TEST_STATUS=PASS
4C_5C_PRODUCT_STOCK_DISCOVERY_STATUS=PASS
4C_5C_DB_CONNECT_STATUS=PASS
4C_5C_TENANT_COUNT=1
4C_5C_PRODUCT_TABLE_COUNT=$PRODUCT_TABLE_COUNT
4C_5C_STOCK_TABLE_COUNT=$STOCK_TABLE_COUNT
4C_5C_CATEGORY_TABLE_COUNT=$CATEGORY_TABLE_COUNT
4C_5C_UNIT_TABLE_COUNT=$UNIT_TABLE_COUNT
4C_5C_BEST_PRODUCT_TABLE=$BEST_PRODUCT_TABLE
4C_5C_BEST_STOCK_TABLE=$BEST_STOCK_TABLE
4C_5C_WARNING_COUNT=$WARNING_COUNT
4C_5C_DB_WRITE_APPLIED=NO
4C_5D_READY=YES

## Sonuc

Product / stock table discovery test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-5D Import Mapping Strategy Decision.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-5C TEST SONUCU ====="
echo "4C_5C_TEST_STATUS=PASS ✅"
echo "4C_5C_PRODUCT_STOCK_DISCOVERY_STATUS=PASS ✅"
echo "4C_5C_DB_CONNECT_STATUS=PASS ✅"
echo "4C_5C_TENANT_COUNT=1 ✅"
echo "4C_5C_PRODUCT_TABLE_COUNT=$PRODUCT_TABLE_COUNT"
echo "4C_5C_STOCK_TABLE_COUNT=$STOCK_TABLE_COUNT"
echo "4C_5C_CATEGORY_TABLE_COUNT=$CATEGORY_TABLE_COUNT"
echo "4C_5C_UNIT_TABLE_COUNT=$UNIT_TABLE_COUNT"
echo "4C_5C_BEST_PRODUCT_TABLE=$BEST_PRODUCT_TABLE"
echo "4C_5C_BEST_STOCK_TABLE=$BEST_STOCK_TABLE"
echo "4C_5C_DB_WRITE_APPLIED=NO ✅"
echo "4C_5D_READY=YES ✅"
