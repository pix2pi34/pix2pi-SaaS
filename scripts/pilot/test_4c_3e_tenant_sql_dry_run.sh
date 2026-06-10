#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_3e_tenant_sql_dry_run.sh"
PREV_REPORT="reports/pilot/faz4c/4c_3d_tenant_apply_sql_package_test_report.md"
DOC_FILE="docs/pilot/faz4c/4c_3e_tenant_sql_dry_run.md"
REPORT_FILE="reports/pilot/faz4c/4c_3e_tenant_sql_dry_run_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_3e_tenant_sql_dry_run_test_report.md"

echo "===== 4C-3E TENANT SQL DRY RUN TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-3D test report yok: $PREV_REPORT"
pass "4C-3D test report var"

grep -q "4C_3D_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-3D PASS degil"
pass "4C-3D PASS"

grep -q "4C_3E_READY=YES" "$PREV_REPORT" || fail "4C-3E ready YES yok"
pass "4C-3E ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$DOC_FILE" ] || fail "Dry run dokumani yok: $DOC_FILE"
pass "Dry run dokumani var"

[ -f "$REPORT_FILE" ] || fail "Dry run report yok: $REPORT_FILE"
pass "Dry run report var"

grep -q "4C_3E_DRY_RUN_STATUS=PASS" "$REPORT_FILE" || fail "4C-3E dry run PASS degil"
pass "4C-3E dry run PASS"

grep -q "4C_3E_SQL_EXECUTION_STATUS=PASS" "$REPORT_FILE" || fail "SQL execution PASS degil"
pass "SQL execution PASS"

grep -q "4C_3E_ROLLBACK_VERIFIED=YES" "$REPORT_FILE" || fail "Rollback verified YES degil"
pass "Rollback verified YES"

grep -q "4C_3E_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_3E_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_3F_READY=YES" "$REPORT_FILE" || fail "4C-3F ready YES yok"
pass "4C-3F ready YES"

BEFORE_SCHEMA="$(grep '^4C_3E_BEFORE_SCHEMA_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_SCHEMA="$(grep '^4C_3E_AFTER_SCHEMA_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
BEFORE_TENANT="$(grep '^4C_3E_BEFORE_TENANT_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_TENANT="$(grep '^4C_3E_AFTER_TENANT_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

if [ "$BEFORE_SCHEMA" != "$AFTER_SCHEMA" ]; then
  fail "Schema count rollback sonrasi degismis"
fi
pass "Schema count degismedi"

if [ "$BEFORE_TENANT" != "$AFTER_TENANT" ]; then
  fail "Tenant count rollback sonrasi degismis"
fi
pass "Tenant count degismedi"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-3E Tenant SQL Dry Run Test Report

Step: 4C-3E
Blok: Tenant SQL Dry Run Execution / ROLLBACK Verification Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3E_TEST_STATUS=PASS
4C_3E_DRY_RUN_STATUS=PASS
4C_3E_SQL_EXECUTION_STATUS=PASS
4C_3E_ROLLBACK_VERIFIED=YES
4C_3E_BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA
4C_3E_AFTER_SCHEMA_COUNT=$AFTER_SCHEMA
4C_3E_BEFORE_TENANT_COUNT=$BEFORE_TENANT
4C_3E_AFTER_TENANT_COUNT=$AFTER_TENANT
4C_3E_DB_WRITE_APPLIED=NO
4C_3F_READY=YES

## Sonuc

Tenant SQL dry-run test tamamlandi.
ROLLBACK dogrulandi.
Kalici DB yazma yapilmadi.
Sonraki adim: 4C-3F Tenant Apply Guard / Commit SQL Package.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-3E TEST SONUCU ====="
echo "4C_3E_TEST_STATUS=PASS ✅"
echo "4C_3E_SQL_EXECUTION_STATUS=PASS ✅"
echo "4C_3E_ROLLBACK_VERIFIED=YES ✅"
echo "4C_3E_BEFORE_SCHEMA_COUNT=$BEFORE_SCHEMA"
echo "4C_3E_AFTER_SCHEMA_COUNT=$AFTER_SCHEMA"
echo "4C_3E_BEFORE_TENANT_COUNT=$BEFORE_TENANT"
echo "4C_3E_AFTER_TENANT_COUNT=$AFTER_TENANT"
echo "4C_3E_DB_WRITE_APPLIED=NO ✅"
echo "4C_3F_READY=YES ✅"
