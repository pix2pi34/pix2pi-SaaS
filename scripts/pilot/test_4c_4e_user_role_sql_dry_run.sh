#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_4e_user_role_sql_dry_run.sh"
PREV_REPORT="reports/pilot/faz4c/4c_4d_user_role_sql_package_test_report.md"
FIX3_REPORT="reports/pilot/faz4c/4c_4d_fix3_assignment_cte_columns_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_4e_user_role_sql_dry_run_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_4e_user_role_sql_dry_run_test_report.md"

echo "===== 4C-4E USER ROLE SQL DRY RUN TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-4D test report yok: $PREV_REPORT"
pass "4C-4D test report var"

[ -f "$FIX3_REPORT" ] || fail "4C-4D-FIX3 report yok: $FIX3_REPORT"
pass "4C-4D-FIX3 report var"

grep -q "4C_4D_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-4D test PASS degil"
pass "4C-4D test PASS"

grep -q "4C_4E_READY=YES" "$PREV_REPORT" || fail "4C-4E ready YES yok"
pass "4C-4E ready YES"

grep -q "4C_4D_FIX3_STATUS=PASS" "$FIX3_REPORT" || fail "4C-4D-FIX3 PASS degil"
pass "4C-4D-FIX3 PASS"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-4E report yok: $REPORT_FILE"
pass "4C-4E report var"

grep -q "4C_4E_DRY_RUN_STATUS=PASS" "$REPORT_FILE" || fail "4C-4E dry run PASS degil"
pass "4C-4E dry run PASS"

grep -q "4C_4E_SQL_EXECUTION_STATUS=PASS" "$REPORT_FILE" || fail "SQL execution PASS degil"
pass "SQL execution PASS"

grep -q "4C_4E_ROLLBACK_VERIFIED=YES" "$REPORT_FILE" || fail "Rollback verified YES degil"
pass "Rollback verified YES"

grep -q "4C_4E_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_4E_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_4F_READY=YES" "$REPORT_FILE" || fail "4C-4F ready YES yok"
pass "4C-4F ready YES"

BEFORE_USER="$(grep '^4C_4E_BEFORE_USER_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_USER="$(grep '^4C_4E_AFTER_USER_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
BEFORE_ROLE="$(grep '^4C_4E_BEFORE_ROLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_ROLE="$(grep '^4C_4E_AFTER_ROLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
BEFORE_ASSIGNMENT="$(grep '^4C_4E_BEFORE_ASSIGNMENT_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
AFTER_ASSIGNMENT="$(grep '^4C_4E_AFTER_ASSIGNMENT_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

[ "$BEFORE_USER" = "$AFTER_USER" ] || fail "User count rollback sonrasi degisti"
pass "User count degismedi"

[ "$BEFORE_ROLE" = "$AFTER_ROLE" ] || fail "Role count rollback sonrasi degisti"
pass "Role count degismedi"

[ "$BEFORE_ASSIGNMENT" = "$AFTER_ASSIGNMENT" ] || fail "Assignment count rollback sonrasi degisti"
pass "Assignment count degismedi"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-4E User Role SQL Dry Run Test Report

Step: 4C-4E
Blok: User / Role SQL Dry Run / ROLLBACK Verification Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_4E_TEST_STATUS=PASS
4C_4E_DRY_RUN_STATUS=PASS
4C_4E_SQL_EXECUTION_STATUS=PASS
4C_4E_ROLLBACK_VERIFIED=YES
4C_4E_BEFORE_USER_COUNT=$BEFORE_USER
4C_4E_AFTER_USER_COUNT=$AFTER_USER
4C_4E_BEFORE_ROLE_COUNT=$BEFORE_ROLE
4C_4E_AFTER_ROLE_COUNT=$AFTER_ROLE
4C_4E_BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT
4C_4E_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT
4C_4E_DB_WRITE_APPLIED=NO
4C_4F_READY=YES

## Sonuc

User/role SQL dry-run test tamamlandi.
ROLLBACK dogrulandi.
Kalici DB yazma yapilmadi.
Sonraki adim: 4C-4F User / Role Commit SQL Package / Apply Guard.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-4E TEST SONUCU ====="
echo "4C_4E_TEST_STATUS=PASS ✅"
echo "4C_4E_SQL_EXECUTION_STATUS=PASS ✅"
echo "4C_4E_ROLLBACK_VERIFIED=YES ✅"
echo "4C_4E_BEFORE_USER_COUNT=$BEFORE_USER"
echo "4C_4E_AFTER_USER_COUNT=$AFTER_USER"
echo "4C_4E_BEFORE_ROLE_COUNT=$BEFORE_ROLE"
echo "4C_4E_AFTER_ROLE_COUNT=$AFTER_ROLE"
echo "4C_4E_BEFORE_ASSIGNMENT_COUNT=$BEFORE_ASSIGNMENT"
echo "4C_4E_AFTER_ASSIGNMENT_COUNT=$AFTER_ASSIGNMENT"
echo "4C_4E_DB_WRITE_APPLIED=NO ✅"
echo "4C_4F_READY=YES ✅"
