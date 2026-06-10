#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/build_4c_5f_import_sql_package.sh"
PREV_REPORT="reports/pilot/faz4c/4c_5e_sample_csv_generation_validation_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_5f_import_sql_package_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_5f_import_sql_package_test_report.md"
SQL_FILE="sql/pilot/faz4c/4c_5f_preview_product_import_staging_uzmanparcaci.sql"

echo "===== 4C-5F IMPORT SQL PACKAGE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-5E test report yok: $PREV_REPORT"
pass "4C-5E test report var"

grep -q "4C_5E_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-5E test PASS degil"
pass "4C-5E test PASS"

grep -q "4C_5F_READY=YES" "$PREV_REPORT" || fail "4C-5F ready YES yok"
pass "4C-5F ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-5F report yok: $REPORT_FILE"
pass "4C-5F report var"

[ -f "$SQL_FILE" ] || fail "4C-5F SQL file yok: $SQL_FILE"
pass "4C-5F SQL file var"

grep -q "4C_5F_IMPORT_SQL_PACKAGE_STATUS=PASS" "$REPORT_FILE" || fail "SQL package PASS degil"
pass "SQL package PASS"

grep -q "4C_5F_SQL_FILE_CREATED=YES" "$REPORT_FILE" || fail "SQL file created YES degil"
pass "SQL file created YES"

grep -q "4C_5F_SQL_HAS_BEGIN=YES" "$REPORT_FILE" || fail "SQL has BEGIN YES degil"
pass "SQL has BEGIN YES"

grep -q "4C_5F_SQL_HAS_ROLLBACK=YES" "$REPORT_FILE" || fail "SQL has ROLLBACK YES degil"
pass "SQL has ROLLBACK YES"

grep -q "4C_5F_SQL_HAS_COMMIT=NO" "$REPORT_FILE" || fail "SQL has COMMIT NO degil"
pass "SQL has COMMIT NO"

grep -q "4C_5F_STAGING_TABLE_CREATE_INCLUDED=YES" "$REPORT_FILE" || fail "Staging table create included YES degil"
pass "Staging table create included YES"

grep -q "4C_5F_SAMPLE_INSERT_COUNT=5" "$REPORT_FILE" || fail "Sample insert count 5 degil"
pass "Sample insert count 5"

grep -q "4C_5F_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_5F_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_5G_READY=YES" "$REPORT_FILE" || fail "4C-5G ready YES yok"
pass "4C-5G ready YES"

grep -q "BEGIN;" "$SQL_FILE" || fail "SQL BEGIN yok"
pass "SQL BEGIN var"

grep -q "ROLLBACK;" "$SQL_FILE" || fail "SQL ROLLBACK yok"
pass "SQL ROLLBACK var"

if grep -q "COMMIT;" "$SQL_FILE"; then
  fail "SQL preview COMMIT icermemeli"
fi
pass "SQL COMMIT icermiyor"

grep -q "CREATE TABLE IF NOT EXISTS tenant_uzmanparcaci.pilot_product_import_staging" "$SQL_FILE" || fail "SQL staging create yok"
pass "SQL staging create var"

grep -q "INSERT INTO tenant_uzmanparcaci.pilot_product_import_staging" "$SQL_FILE" || fail "SQL staging insert yok"
pass "SQL staging insert var"

INSERT_COUNT="$(grep -c "INSERT INTO tenant_uzmanparcaci.pilot_product_import_staging" "$SQL_FILE" | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-5F Import SQL Package Test Report

Step: 4C-5F
Blok: Import SQL Package / Dry Run Plan Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_5F_TEST_STATUS=PASS
4C_5F_IMPORT_SQL_PACKAGE_STATUS=PASS
4C_5F_SQL_FILE_CREATED=YES
4C_5F_SQL_HAS_BEGIN=YES
4C_5F_SQL_HAS_ROLLBACK=YES
4C_5F_SQL_HAS_COMMIT=NO
4C_5F_STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
4C_5F_STAGING_TABLE_CREATE_INCLUDED=YES
4C_5F_SAMPLE_INSERT_COUNT=$INSERT_COUNT
4C_5F_EXPECTED_INSERT_COUNT=5
4C_5F_DB_WRITE_APPLIED=NO
4C_5G_READY=YES

## Sonuc

Import SQL package test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-5G Import Dry Run / ROLLBACK Verification.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-5F TEST SONUCU ====="
echo "4C_5F_TEST_STATUS=PASS ✅"
echo "4C_5F_IMPORT_SQL_PACKAGE_STATUS=PASS ✅"
echo "4C_5F_SQL_FILE_CREATED=YES ✅"
echo "4C_5F_SQL_HAS_BEGIN=YES ✅"
echo "4C_5F_SQL_HAS_ROLLBACK=YES ✅"
echo "4C_5F_SQL_HAS_COMMIT=NO ✅"
echo "4C_5F_STAGING_TABLE_CREATE_INCLUDED=YES ✅"
echo "4C_5F_SAMPLE_INSERT_COUNT=$INSERT_COUNT ✅"
echo "4C_5F_DB_WRITE_APPLIED=NO ✅"
echo "4C_5G_READY=YES ✅"
