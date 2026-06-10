#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_4c_user_role_apply_strategy.sh"
PREV_REPORT="reports/pilot/faz4c/4c_4b_identity_user_role_db_precheck_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_4c_user_role_apply_strategy_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_4c_user_role_apply_strategy_test_report.md"

echo "===== 4C-4C USER ROLE APPLY STRATEGY TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-4B test report yok: $PREV_REPORT"
pass "4C-4B test report var"

grep -q "4C_4B_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-4B test PASS degil"
pass "4C-4B test PASS"

grep -q "4C_4C_READY=YES" "$PREV_REPORT" || fail "4C-4C ready YES yok"
pass "4C-4C ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-4C report yok: $REPORT_FILE"
pass "4C-4C report var"

grep -q "4C_4C_USER_ROLE_APPLY_STRATEGY_STATUS=PASS" "$REPORT_FILE" || fail "Strategy PASS degil"
pass "Strategy PASS"

grep -q "4C_4C_SELECTED_USER_TABLE=auth.users" "$REPORT_FILE" || fail "Selected user table auth.users degil"
pass "Selected user table auth.users"

grep -q "4C_4C_SELECTED_ROLE_TABLE=auth.roles" "$REPORT_FILE" || fail "Selected role table auth.roles degil"
pass "Selected role table auth.roles"

grep -q "4C_4C_SELECTED_MAPPING_TABLE=auth.user_role_assignments" "$REPORT_FILE" || fail "Selected mapping table auth.user_role_assignments degil"
pass "Selected mapping table auth.user_role_assignments"

grep -q "4C_4C_EXISTING_USER_COUNT=0" "$REPORT_FILE" || fail "Existing user count 0 degil"
pass "Existing user count 0"

grep -q "4C_4C_USER_CREATE_NEEDED=YES" "$REPORT_FILE" || fail "User create needed YES degil"
pass "User create needed YES"

grep -q "4C_4C_ROLE_CREATE_NEEDED=YES" "$REPORT_FILE" || fail "Role create needed YES degil"
pass "Role create needed YES"

grep -q "4C_4C_ASSIGNMENT_CREATE_NEEDED=YES" "$REPORT_FILE" || fail "Assignment create needed YES degil"
pass "Assignment create needed YES"

grep -q "4C_4C_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_4D_READY=YES" "$REPORT_FILE" || fail "4C-4D ready YES yok"
pass "4C-4D ready YES"

TENANT_ID="$(grep '^4C_4C_TENANT_ID=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2- | tr -d ' ')"
USER_REQUIRED_COUNT="$(grep '^4C_4C_USER_REQUIRED_COLUMN_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
ROLE_REQUIRED_COUNT="$(grep '^4C_4C_ROLE_REQUIRED_COLUMN_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
MAPPING_REQUIRED_COUNT="$(grep '^4C_4C_MAPPING_REQUIRED_COLUMN_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-4C User Role Apply Strategy Test Report

Step: 4C-4C
Blok: User / Role Apply Strategy Decision Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_4C_TEST_STATUS=PASS
4C_4C_USER_ROLE_APPLY_STRATEGY_STATUS=PASS
4C_4C_SELECTED_USER_TABLE=auth.users
4C_4C_SELECTED_ROLE_TABLE=auth.roles
4C_4C_SELECTED_MAPPING_TABLE=auth.user_role_assignments
4C_4C_TENANT_ID=$TENANT_ID
4C_4C_USER_CREATE_NEEDED=YES
4C_4C_ROLE_CREATE_NEEDED=YES
4C_4C_ASSIGNMENT_CREATE_NEEDED=YES
4C_4C_USER_REQUIRED_COLUMN_COUNT=$USER_REQUIRED_COUNT
4C_4C_ROLE_REQUIRED_COLUMN_COUNT=$ROLE_REQUIRED_COUNT
4C_4C_MAPPING_REQUIRED_COLUMN_COUNT=$MAPPING_REQUIRED_COUNT
4C_4C_DB_WRITE_APPLIED=NO
4C_4D_READY=YES

## Sonuc

User/role apply strategy test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-4D User / Role SQL Package / Dry Run Plan.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-4C TEST SONUCU ====="
echo "4C_4C_TEST_STATUS=PASS ✅"
echo "4C_4C_SELECTED_USER_TABLE=auth.users ✅"
echo "4C_4C_SELECTED_ROLE_TABLE=auth.roles ✅"
echo "4C_4C_SELECTED_MAPPING_TABLE=auth.user_role_assignments ✅"
echo "4C_4C_TENANT_ID=$TENANT_ID"
echo "4C_4C_USER_CREATE_NEEDED=YES ✅"
echo "4C_4C_ROLE_CREATE_NEEDED=YES ✅"
echo "4C_4C_ASSIGNMENT_CREATE_NEEDED=YES ✅"
echo "4C_4C_DB_WRITE_APPLIED=NO ✅"
echo "4C_4D_READY=YES ✅"
