#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/apply_4c_4g_user_role_commit.sh"
REPORT_FILE="reports/pilot/faz4c/4c_4g_user_role_apply_execution_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_4g_user_role_apply_execution_test_report.md"

echo "===== 4C-4G USER ROLE APPLY EXECUTION TEST ====="

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

[ -f "$REPORT_FILE" ] || fail "4C-4G report yok: $REPORT_FILE"
pass "4C-4G report var"

grep -q "4C_4G_USER_ROLE_APPLY_STATUS=PASS" "$REPORT_FILE" || fail "User role apply PASS degil"
pass "User role apply PASS"

grep -q "4C_4G_SQL_EXECUTION_STATUS=PASS" "$REPORT_FILE" || fail "SQL execution PASS degil"
pass "SQL execution PASS"

grep -q "4C_4G_TENANT_COUNT=1" "$REPORT_FILE" || fail "Tenant count 1 degil"
pass "Tenant count 1"

grep -q "4C_4G_AFTER_USER_COUNT=1" "$REPORT_FILE" || fail "After user count 1 degil"
pass "After user count 1"

grep -q "4C_4G_AFTER_ROLE_COUNT=1" "$REPORT_FILE" || fail "After role count 1 degil"
pass "After role count 1"

grep -q "4C_4G_AFTER_ASSIGNMENT_COUNT=1" "$REPORT_FILE" || fail "After assignment count 1 degil"
pass "After assignment count 1"

grep -q "4C_4G_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED" "$REPORT_FILE" || fail "Password hash status beklenen degil"
pass "Password hash temp/reset gate status"

grep -q "4C_4G_DB_WRITE_APPLIED=YES" "$REPORT_FILE" || fail "DB write applied YES degil"
pass "DB write applied YES"

grep -q "4C_4G_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_4H_READY=YES" "$REPORT_FILE" || fail "4C-4H ready YES yok"
pass "4C-4H ready YES"

AFTER_USER="$(grep '^4C_4G_AFTER_USER_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_ROLE="$(grep '^4C_4G_AFTER_ROLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_ASSIGNMENT="$(grep '^4C_4G_AFTER_ASSIGNMENT_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_4G_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-4G User Role Apply Execution Test Report

Step: 4C-4G
Blok: User / Role Apply Execution Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_4G_TEST_STATUS=PASS
4C_4G_USER_ROLE_APPLY_STATUS=PASS
4C_4G_SQL_EXECUTION_STATUS=PASS
4C_4G_AFTER_USER_COUNT=$AFTER_USER
4C_4G_AFTER_ROLE_COUNT=$AFTER_ROLE
4C_4G_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT
4C_4G_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED
4C_4G_DB_WRITE_APPLIED=YES
4C_4G_WARNING_COUNT=$WARNING_COUNT
4C_4H_READY=YES

## Sonuc

User/role apply execution test tamamlandi.
uzmanparcaci pilot kullanicisi, PILOT_ADMIN rolu ve user-role assignment DB'ye islendi.
Sonraki adim: 4C-4H User / Role Verification / Access Smoke.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-4G TEST SONUCU ====="
echo "4C_4G_TEST_STATUS=PASS ✅"
echo "4C_4G_USER_ROLE_APPLY_STATUS=PASS ✅"
echo "4C_4G_SQL_EXECUTION_STATUS=PASS ✅"
echo "4C_4G_AFTER_USER_COUNT=$AFTER_USER ✅"
echo "4C_4G_AFTER_ROLE_COUNT=$AFTER_ROLE ✅"
echo "4C_4G_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT ✅"
echo "4C_4G_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED ⚠️"
echo "4C_4G_DB_WRITE_APPLIED=YES ✅"
echo "4C_4H_READY=YES ✅"
