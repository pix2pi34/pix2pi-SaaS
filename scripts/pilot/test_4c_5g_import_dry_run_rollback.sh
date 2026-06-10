#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_5g_import_dry_run_rollback.sh"
PREV_REPORT="reports/pilot/faz4c/4c_5f_import_sql_package_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_5g_import_dry_run_rollback_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_5g_import_dry_run_rollback_test_report.md"

echo "===== 4C-5G IMPORT DRY RUN / ROLLBACK TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-5F test report yok: $PREV_REPORT"
pass "4C-5F test report var"

grep -q "4C_5F_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-5F test PASS degil"
pass "4C-5F test PASS"

grep -q "4C_5G_READY=YES" "$PREV_REPORT" || fail "4C-5G ready YES yok"
pass "4C-5G ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-5G report yok: $REPORT_FILE"
pass "4C-5G report var"

grep -q "4C_5G_IMPORT_DRY_RUN_STATUS=PASS" "$REPORT_FILE" || fail "Import dry-run PASS degil"
pass "Import dry-run PASS"

grep -q "4C_5G_SQL_EXECUTION_STATUS=PASS" "$REPORT_FILE" || fail "SQL execution PASS degil"
pass "SQL execution PASS"

grep -q "4C_5G_SQL_OUTPUT_STAGING_ROW_COUNT=5" "$REPORT_FILE" || fail "SQL output staging row count 5 degil"
pass "SQL output staging row count 5"

grep -q "4C_5G_SQL_OUTPUT_DUPLICATE_SKU_COUNT=0" "$REPORT_FILE" || fail "SQL output duplicate sku count 0 degil"
pass "SQL output duplicate SKU count 0"

grep -q "4C_5G_ROLLBACK_VERIFIED=YES" "$REPORT_FILE" || fail "Rollback verified YES degil"
pass "Rollback verified YES"

grep -q "4C_5G_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_5G_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_5H_READY=YES" "$REPORT_FILE" || fail "4C-5H ready YES yok"
pass "4C-5H ready YES"

BEFORE_TABLE_EXISTS="$(grep '^4C_5G_BEFORE_TABLE_EXISTS=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_TABLE_EXISTS="$(grep '^4C_5G_AFTER_TABLE_EXISTS=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
BEFORE_ROW_COUNT="$(grep '^4C_5G_BEFORE_ROW_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_ROW_COUNT="$(grep '^4C_5G_AFTER_ROW_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

[ "$BEFORE_TABLE_EXISTS" = "$AFTER_TABLE_EXISTS" ] || fail "Table exists rollback sonrasi degisti"
pass "Table exists rollback sonrasi degismedi"

[ "$BEFORE_ROW_COUNT" = "$AFTER_ROW_COUNT" ] || fail "Row count rollback sonrasi degisti"
pass "Row count rollback sonrasi degismedi"

cat > "$TEST_REPORT" <<REPORT_EOF
# FAZ 4C — 4C-5G Import Dry Run Rollback Test Report

Step: 4C-5G
Blok: Import Dry Run / ROLLBACK Verification Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5G_TEST_STATUS=PASS
4C_5G_IMPORT_DRY_RUN_STATUS=PASS
4C_5G_SQL_EXECUTION_STATUS=PASS
4C_5G_SQL_OUTPUT_STAGING_ROW_COUNT=5
4C_5G_SQL_OUTPUT_DUPLICATE_SKU_COUNT=0
4C_5G_BEFORE_TABLE_EXISTS=$BEFORE_TABLE_EXISTS
4C_5G_AFTER_TABLE_EXISTS=$AFTER_TABLE_EXISTS
4C_5G_BEFORE_ROW_COUNT=$BEFORE_ROW_COUNT
4C_5G_AFTER_ROW_COUNT=$AFTER_ROW_COUNT
4C_5G_ROLLBACK_VERIFIED=YES
4C_5G_DB_WRITE_APPLIED=NO
4C_5H_READY=YES

## Sonuc

Import dry-run / rollback verification test tamamlandi.
Kalici DB yazma yapilmadi.
Sonraki adim: 4C-5H Controlled Sample Data Apply.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-5G TEST SONUCU ====="
echo "4C_5G_TEST_STATUS=PASS ✅"
echo "4C_5G_IMPORT_DRY_RUN_STATUS=PASS ✅"
echo "4C_5G_SQL_EXECUTION_STATUS=PASS ✅"
echo "4C_5G_SQL_OUTPUT_STAGING_ROW_COUNT=5 ✅"
echo "4C_5G_SQL_OUTPUT_DUPLICATE_SKU_COUNT=0 ✅"
echo "4C_5G_ROLLBACK_VERIFIED=YES ✅"
echo "4C_5G_DB_WRITE_APPLIED=NO ✅"
echo "4C_5H_READY=YES ✅"
