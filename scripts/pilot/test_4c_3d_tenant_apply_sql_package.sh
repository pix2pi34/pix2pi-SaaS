#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_3d_tenant_apply_sql_package.sh"
PREV_REPORT="reports/pilot/faz4c/4c_3c_tenant_apply_strategy_decision_report.md"
DOC_FILE="docs/pilot/faz4c/4c_3d_tenant_apply_sql_package.md"
REPORT_FILE="reports/pilot/faz4c/4c_3d_tenant_apply_sql_package_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_3d_tenant_apply_sql_package_test_report.md"
SQL_FILE="sql/pilot/faz4c/4c_3d_preview_tenant_uzmanparcaci.sql"

echo "===== 4C-3D TENANT APPLY SQL PACKAGE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-3C report yok: $PREV_REPORT"
pass "4C-3C report var"

grep -q "4C_3C_TENANT_APPLY_STRATEGY_STATUS=PASS" "$PREV_REPORT" || fail "4C-3C PASS degil"
pass "4C-3C PASS"

grep -q "4C_3C_SELECTED_TENANT_TABLE=platform.tenants" "$PREV_REPORT" || fail "Selected tenant table platform.tenants degil"
pass "Selected tenant table platform.tenants"

grep -q "4C_3D_READY=YES" "$PREV_REPORT" || fail "4C-3D ready YES yok"
pass "4C-3D ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$DOC_FILE" ] || fail "SQL package dokumani yok: $DOC_FILE"
pass "SQL package dokumani var"

[ -f "$REPORT_FILE" ] || fail "SQL package report yok: $REPORT_FILE"
pass "SQL package report var"

[ -f "$SQL_FILE" ] || fail "SQL preview file yok: $SQL_FILE"
pass "SQL preview file var"

grep -q "4C_3D_SQL_PACKAGE_STATUS=PASS" "$REPORT_FILE" || fail "4C-3D SQL package PASS degil"
pass "4C-3D SQL package PASS"

grep -q "4C_3D_SELECTED_TENANT_TABLE=platform.tenants" "$REPORT_FILE" || fail "Report selected table platform.tenants degil"
pass "Report selected table platform.tenants"

grep -q "4C_3D_SQL_FILE_CREATED=YES" "$REPORT_FILE" || fail "SQL file created YES yok"
pass "SQL file created YES"

grep -q "4C_3D_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_3D_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_3E_READY=YES" "$REPORT_FILE" || fail "4C-3E ready YES yok"
pass "4C-3E ready YES"

grep -q "CREATE SCHEMA IF NOT EXISTS tenant_uzmanparcaci" "$SQL_FILE" || fail "SQL schema create yok"
pass "SQL schema create var"

grep -q "INSERT INTO platform.tenants" "$SQL_FILE" || fail "SQL insert platform.tenants yok"
pass "SQL insert platform.tenants var"

grep -q "ROLLBACK;" "$SQL_FILE" || fail "SQL preview ROLLBACK ile bitmiyor"
pass "SQL preview ROLLBACK var"

INSERT_COLUMN_COUNT="$(grep '^4C_3D_INSERT_COLUMN_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
EXISTING_COUNT="$(grep '^4C_3D_EXISTING_TENANT_COUNT_BY_CODE=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
SCHEMA_EXISTS="$(grep '^4C_3D_TENANT_SCHEMA_EXISTS_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-3D Tenant Apply SQL Package Test Report

Step: 4C-3D
Blok: Tenant Apply SQL Package / Dry Run Plan Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3D_TEST_STATUS=PASS
4C_3D_SQL_PACKAGE_STATUS=PASS
4C_3D_SELECTED_TENANT_TABLE=platform.tenants
4C_3D_INSERT_COLUMN_COUNT=$INSERT_COLUMN_COUNT
4C_3D_EXISTING_TENANT_COUNT_BY_CODE=$EXISTING_COUNT
4C_3D_TENANT_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS
4C_3D_SQL_FILE_CREATED=YES
4C_3D_DB_WRITE_APPLIED=NO
4C_3E_READY=YES

## Sonuc

Tenant SQL preview package test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-3E Tenant SQL Dry Run Execution / ROLLBACK Verification.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-3D TEST SONUCU ====="
echo "4C_3D_TEST_STATUS=PASS ✅"
echo "4C_3D_SELECTED_TENANT_TABLE=platform.tenants ✅"
echo "4C_3D_INSERT_COLUMN_COUNT=$INSERT_COLUMN_COUNT"
echo "4C_3D_EXISTING_TENANT_COUNT_BY_CODE=$EXISTING_COUNT"
echo "4C_3D_TENANT_SCHEMA_EXISTS_COUNT=$SCHEMA_EXISTS"
echo "4C_3D_DB_WRITE_APPLIED=NO ✅"
echo "4C_3E_READY=YES ✅"
