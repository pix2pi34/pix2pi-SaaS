#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/apply_4c_3g_tenant_commit.sh"
REPORT_FILE="reports/pilot/faz4c/4c_3g_tenant_apply_execution_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_3g_tenant_apply_execution_test_report.md"

echo "===== 4C-3G TENANT APPLY EXECUTION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$RUN_SCRIPT" ] || fail "Apply script yok: $RUN_SCRIPT"
pass "Apply script var"

[ -x "$RUN_SCRIPT" ] || fail "Apply script executable degil"
pass "Apply script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-3G report yok: $REPORT_FILE"
pass "4C-3G report var"

grep -q "4C_3G_TENANT_APPLY_STATUS=PASS" "$REPORT_FILE" || fail "Tenant apply PASS degil"
pass "Tenant apply PASS"

grep -q "4C_3G_SQL_EXECUTION_STATUS=PASS" "$REPORT_FILE" || fail "SQL execution PASS degil"
pass "SQL execution PASS"

grep -q "4C_3G_AFTER_SCHEMA_COUNT=1" "$REPORT_FILE" || fail "Schema count 1 degil"
pass "Schema count 1"

grep -q "4C_3G_AFTER_TENANT_COUNT=1" "$REPORT_FILE" || fail "Tenant count 1 degil"
pass "Tenant count 1"

grep -q "4C_3G_DB_WRITE_APPLIED=YES" "$REPORT_FILE" || fail "DB write applied YES degil"
pass "DB write applied YES"

grep -q "4C_3H_READY=YES" "$REPORT_FILE" || fail "4C-3H ready YES yok"
pass "4C-3H ready YES"

AFTER_SCHEMA="$(grep '^4C_3G_AFTER_SCHEMA_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_TENANT="$(grep '^4C_3G_AFTER_TENANT_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-3G Tenant Apply Execution Test Report

Step: 4C-3G
Blok: Tenant Apply Execution / Real DB Write Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3G_TEST_STATUS=PASS
4C_3G_TENANT_APPLY_STATUS=PASS
4C_3G_SQL_EXECUTION_STATUS=PASS
4C_3G_AFTER_SCHEMA_COUNT=$AFTER_SCHEMA
4C_3G_AFTER_TENANT_COUNT=$AFTER_TENANT
4C_3G_DB_WRITE_APPLIED=YES
4C_3H_READY=YES

## Sonuç

Tenant apply execution test tamamlandı.
uzmanparcaci gerçek pilot tenant kaydı DB'ye işlendi.
Sonraki adım: 4C-3H Tenant Apply Verification / Isolation Smoke.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-3G TEST SONUCU ====="
echo "4C_3G_TEST_STATUS=PASS ✅"
echo "4C_3G_TENANT_APPLY_STATUS=PASS ✅"
echo "4C_3G_SQL_EXECUTION_STATUS=PASS ✅"
echo "4C_3G_AFTER_SCHEMA_COUNT=$AFTER_SCHEMA ✅"
echo "4C_3G_AFTER_TENANT_COUNT=$AFTER_TENANT ✅"
echo "4C_3G_DB_WRITE_APPLIED=YES ✅"
echo "4C_3H_READY=YES ✅"
