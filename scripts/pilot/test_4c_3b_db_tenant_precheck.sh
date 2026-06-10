#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_3b_db_tenant_precheck.sh"
PREV_REPORT="reports/pilot/faz4c/4c_3a_tenant_identity_setup_plan_report.md"
DOC_FILE="docs/pilot/faz4c/4c_3b_db_tenant_precheck.md"
REPORT_FILE="reports/pilot/faz4c/4c_3b_db_tenant_precheck_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_3b_db_tenant_precheck_test_report.md"

echo "===== 4C-3B DB TENANT PRECHECK TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-3A report yok: $PREV_REPORT"
pass "4C-3A report var"

grep -q "4C_3A_TENANT_IDENTITY_PLAN_STATUS=PASS" "$PREV_REPORT" || fail "4C-3A PASS degil"
pass "4C-3A PASS"

grep -q "4C_3B_READY=YES" "$PREV_REPORT" || fail "4C-3B ready YES degil"
pass "4C-3B ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$DOC_FILE" ] || fail "DB tenant precheck dokumani yok: $DOC_FILE"
pass "DB tenant precheck dokumani var"

[ -f "$REPORT_FILE" ] || fail "DB tenant precheck report yok: $REPORT_FILE"
pass "DB tenant precheck report var"

grep -q "4C_3B_DB_TENANT_PRECHECK_STATUS=PASS" "$REPORT_FILE" || fail "4C-3B precheck PASS degil"
pass "4C-3B precheck PASS"

grep -q "4C_3B_DB_CONNECT_STATUS=PASS" "$REPORT_FILE" || fail "DB connect PASS degil"
pass "DB connect PASS"

grep -q "4C_3B_TENANT_CODE=uzmanparcaci" "$REPORT_FILE" || fail "Tenant code uzmanparcaci degil"
pass "Tenant code uzmanparcaci"

grep -q "4C_3B_TENANT_SCHEMA=tenant_uzmanparcaci" "$REPORT_FILE" || fail "Tenant schema tenant_uzmanparcaci degil"
pass "Tenant schema tenant_uzmanparcaci"

grep -q "4C_3B_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_3C_READY=YES" "$REPORT_FILE" || fail "4C-3C ready YES yok"
pass "4C-3C ready YES"

SCHEMA_STATUS="$(grep '^4C_3B_TENANT_SCHEMA_STATUS=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
TENANT_TABLE_COUNT="$(grep '^4C_3B_TENANT_TABLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_3B_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-3B DB Tenant Precheck Test Report

Step: 4C-3B
Blok: DB Tenant Precheck / Existing Tenant Discovery Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3B_TEST_STATUS=PASS
4C_3B_DB_TENANT_PRECHECK_STATUS=PASS
4C_3B_DB_CONNECT_STATUS=PASS
4C_3B_TENANT_SCHEMA_STATUS=$SCHEMA_STATUS
4C_3B_TENANT_TABLE_COUNT=$TENANT_TABLE_COUNT
4C_3B_WARNING_COUNT=$WARNING_COUNT
4C_3B_DB_WRITE_APPLIED=NO
4C_3C_READY=YES

## Sonuc

DB tenant precheck test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-3C Tenant Apply Strategy Decision.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-3B TEST SONUCU ====="
echo "4C_3B_TEST_STATUS=PASS ✅"
echo "4C_3B_DB_CONNECT_STATUS=PASS ✅"
echo "4C_3B_TENANT_SCHEMA_STATUS=$SCHEMA_STATUS"
echo "4C_3B_TENANT_TABLE_COUNT=$TENANT_TABLE_COUNT"
echo "4C_3B_DB_WRITE_APPLIED=NO ✅"
echo "4C_3C_READY=YES ✅"
