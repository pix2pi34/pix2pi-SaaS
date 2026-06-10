#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_4b_identity_user_role_db_precheck.sh"
PREV_REPORT="reports/pilot/faz4c/4c_4a_user_role_identity_plan_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_4b_identity_user_role_db_precheck_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_4b_identity_user_role_db_precheck_test_report.md"

echo "===== 4C-4B IDENTITY USER ROLE DB PRECHECK TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-4A report yok: $PREV_REPORT"
pass "4C-4A report var"

grep -q "4C_4A_USER_ROLE_IDENTITY_PLAN_STATUS=PASS" "$PREV_REPORT" || fail "4C-4A PASS degil"
pass "4C-4A PASS"

grep -q "4C_4B_READY=YES" "$PREV_REPORT" || fail "4C-4B ready YES yok"
pass "4C-4B ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-4B report yok: $REPORT_FILE"
pass "4C-4B report var"

grep -q "4C_4B_DB_PRECHECK_STATUS=PASS" "$REPORT_FILE" || fail "4C-4B precheck PASS degil"
pass "4C-4B precheck PASS"

grep -q "4C_4B_DB_CONNECT_STATUS=PASS" "$REPORT_FILE" || fail "DB connect PASS degil"
pass "DB connect PASS"

grep -q "4C_4B_TENANT_COUNT=1" "$REPORT_FILE" || fail "Tenant count 1 degil"
pass "Tenant count 1"

grep -q "4C_4B_TENANT_SCHEMA_COUNT=1" "$REPORT_FILE" || fail "Tenant schema count 1 degil"
pass "Tenant schema count 1"

grep -q "4C_4B_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_4C_READY=YES" "$REPORT_FILE" || fail "4C-4C ready YES yok"
pass "4C-4C ready YES"

USER_TABLE_COUNT="$(grep '^4C_4B_USER_TABLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
ROLE_TABLE_COUNT="$(grep '^4C_4B_ROLE_TABLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
MAPPING_TABLE_COUNT="$(grep '^4C_4B_MAPPING_TABLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
EXISTING_USER_COUNT="$(grep '^4C_4B_EXISTING_USER_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
EXISTING_ROLE_COUNT="$(grep '^4C_4B_EXISTING_ROLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_4B_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-4B Identity User Role DB Precheck Test Report

Step: 4C-4B
Blok: Identity User / Role DB Precheck Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_4B_TEST_STATUS=PASS
4C_4B_DB_PRECHECK_STATUS=PASS
4C_4B_DB_CONNECT_STATUS=PASS
4C_4B_TENANT_COUNT=1
4C_4B_TENANT_SCHEMA_COUNT=1
4C_4B_USER_TABLE_COUNT=$USER_TABLE_COUNT
4C_4B_ROLE_TABLE_COUNT=$ROLE_TABLE_COUNT
4C_4B_MAPPING_TABLE_COUNT=$MAPPING_TABLE_COUNT
4C_4B_EXISTING_USER_COUNT=$EXISTING_USER_COUNT
4C_4B_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT
4C_4B_WARNING_COUNT=$WARNING_COUNT
4C_4B_DB_WRITE_APPLIED=NO
4C_4C_READY=YES

## Sonuc

Identity user/role DB precheck test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-4C User / Role Apply Strategy Decision.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-4B TEST SONUCU ====="
echo "4C_4B_TEST_STATUS=PASS ✅"
echo "4C_4B_DB_CONNECT_STATUS=PASS ✅"
echo "4C_4B_TENANT_COUNT=1 ✅"
echo "4C_4B_TENANT_SCHEMA_COUNT=1 ✅"
echo "4C_4B_USER_TABLE_COUNT=$USER_TABLE_COUNT"
echo "4C_4B_ROLE_TABLE_COUNT=$ROLE_TABLE_COUNT"
echo "4C_4B_MAPPING_TABLE_COUNT=$MAPPING_TABLE_COUNT"
echo "4C_4B_EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
echo "4C_4B_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
echo "4C_4B_DB_WRITE_APPLIED=NO ✅"
echo "4C_4C_READY=YES ✅"
