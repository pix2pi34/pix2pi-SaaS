#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_4h_user_role_verification.sh"
REPORT_FILE="reports/pilot/faz4c/4c_4h_user_role_verification_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_4h_user_role_verification_test_report.md"

echo "===== 4C-4H USER ROLE VERIFICATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$RUN_SCRIPT" ] || fail "Verification script yok: $RUN_SCRIPT"
pass "Verification script var"

[ -x "$RUN_SCRIPT" ] || fail "Verification script executable degil"
pass "Verification script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-4H report yok: $REPORT_FILE"
pass "4C-4H report var"

grep -q "4C_4H_USER_ROLE_VERIFICATION_STATUS=PASS" "$REPORT_FILE" || fail "User role verification PASS degil"
pass "User role verification PASS"

grep -q "4C_4H_TENANT_COUNT=1" "$REPORT_FILE" || fail "Tenant count 1 degil"
pass "Tenant count 1"

grep -q "4C_4H_USER_COUNT=1" "$REPORT_FILE" || fail "User count 1 degil"
pass "User count 1"

grep -q "4C_4H_USER_TENANT_MATCH_COUNT=1" "$REPORT_FILE" || fail "User tenant match 1 degil"
pass "User tenant match 1"

grep -q "4C_4H_ROLE_COUNT=1" "$REPORT_FILE" || fail "Role count 1 degil"
pass "Role count 1"

grep -q "4C_4H_ROLE_TENANT_MATCH_COUNT=1" "$REPORT_FILE" || fail "Role tenant match 1 degil"
pass "Role tenant match 1"

grep -q "4C_4H_ASSIGNMENT_COUNT=1" "$REPORT_FILE" || fail "Assignment count 1 degil"
pass "Assignment count 1"

grep -q "4C_4H_ASSIGNMENT_TENANT_MATCH_COUNT=1" "$REPORT_FILE" || fail "Assignment tenant match 1 degil"
pass "Assignment tenant match 1"

grep -q "4C_4H_SUPER_ADMIN_ASSIGNMENT_COUNT=0" "$REPORT_FILE" || fail "Super admin assignment 0 degil"
pass "Super admin assignment 0"

grep -q "4C_4H_CROSS_TENANT_ASSIGNMENT_COUNT=0" "$REPORT_FILE" || fail "Cross tenant assignment 0 degil"
pass "Cross tenant assignment 0"

grep -q "4C_4H_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED" "$REPORT_FILE" || fail "Password hash status beklenen degil"
pass "Password hash reset gate status"

grep -q "4C_4H_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_4H_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_4I_READY=YES" "$REPORT_FILE" || fail "4C-4I ready YES yok"
pass "4C-4I ready YES"

WARNING_COUNT="$(grep '^4C_4H_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-4H User Role Verification Test Report

Step: 4C-4H
Blok: User / Role Verification / Access Smoke Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_4H_TEST_STATUS=PASS
4C_4H_USER_ROLE_VERIFICATION_STATUS=PASS
4C_4H_TENANT_COUNT=1
4C_4H_USER_COUNT=1
4C_4H_USER_TENANT_MATCH_COUNT=1
4C_4H_ROLE_COUNT=1
4C_4H_ROLE_TENANT_MATCH_COUNT=1
4C_4H_ASSIGNMENT_COUNT=1
4C_4H_ASSIGNMENT_TENANT_MATCH_COUNT=1
4C_4H_SUPER_ADMIN_ASSIGNMENT_COUNT=0
4C_4H_CROSS_TENANT_ASSIGNMENT_COUNT=0
4C_4H_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED
4C_4H_DB_WRITE_APPLIED=NO
4C_4H_WARNING_COUNT=$WARNING_COUNT
4C_4I_READY=YES

## Sonuc

User/role verification smoke test tamamlandi.
Kalici DB yazma yapilmadi.
Sonraki adim: 4C-4I User / Role Assignment Final Closure.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-4H TEST SONUCU ====="
echo "4C_4H_TEST_STATUS=PASS ✅"
echo "4C_4H_USER_ROLE_VERIFICATION_STATUS=PASS ✅"
echo "4C_4H_TENANT_COUNT=1 ✅"
echo "4C_4H_USER_COUNT=1 ✅"
echo "4C_4H_USER_TENANT_MATCH_COUNT=1 ✅"
echo "4C_4H_ROLE_COUNT=1 ✅"
echo "4C_4H_ROLE_TENANT_MATCH_COUNT=1 ✅"
echo "4C_4H_ASSIGNMENT_COUNT=1 ✅"
echo "4C_4H_ASSIGNMENT_TENANT_MATCH_COUNT=1 ✅"
echo "4C_4H_SUPER_ADMIN_ASSIGNMENT_COUNT=0 ✅"
echo "4C_4H_CROSS_TENANT_ASSIGNMENT_COUNT=0 ✅"
echo "4C_4H_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED ⚠️"
echo "4C_4H_DB_WRITE_APPLIED=NO ✅"
echo "4C_4I_READY=YES ✅"
