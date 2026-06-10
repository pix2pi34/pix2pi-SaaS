#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/build_4c_4f_user_role_commit_sql_package.sh"
REPORT_FILE="reports/pilot/faz4c/4c_4f_user_role_commit_sql_package_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_4f_user_role_commit_sql_package_test_report.md"
COMMIT_SQL="sql/pilot/faz4c/4c_4f_commit_user_role_uzmanparcaci.sql"

echo "===== 4C-4F USER ROLE COMMIT SQL PACKAGE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-4F report yok: $REPORT_FILE"
pass "4C-4F report var"

[ -f "$COMMIT_SQL" ] || fail "Commit SQL dosyasi yok: $COMMIT_SQL"
pass "Commit SQL dosyasi var"

grep -q "4C_4F_COMMIT_SQL_PACKAGE_STATUS=PASS" "$REPORT_FILE" || fail "Commit SQL package PASS degil"
pass "Commit SQL package PASS"

grep -q "4C_4F_COMMIT_SQL_FILE_CREATED=YES" "$REPORT_FILE" || fail "Commit SQL file created YES degil"
pass "Commit SQL file created YES"

grep -q "4C_4F_COMMIT_SQL_HAS_COMMIT=YES" "$REPORT_FILE" || fail "Commit SQL has COMMIT YES degil"
pass "Commit SQL has COMMIT"

grep -q "4C_4F_COMMIT_SQL_HAS_ROLLBACK=NO" "$REPORT_FILE" || fail "Commit SQL has ROLLBACK NO degil"
pass "Commit SQL has no ROLLBACK"

grep -q "4C_4F_PASSWORD_HASH_MAPPING=YES" "$REPORT_FILE" || fail "password_hash mapping YES degil"
pass "password_hash mapping YES"

grep -q "4C_4F_ROLE_NAME_MAPPING=YES" "$REPORT_FILE" || fail "role_name mapping YES degil"
pass "role_name mapping YES"

grep -q "4C_4F_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_4G_READY=YES" "$REPORT_FILE" || fail "4C-4G ready YES yok"
pass "4C-4G ready YES"

grep -q "COMMIT;" "$COMMIT_SQL" || fail "Commit SQL icinde COMMIT yok"
pass "Commit SQL icinde COMMIT var"

if grep -q "ROLLBACK;" "$COMMIT_SQL"; then
  fail "Commit SQL icinde ROLLBACK var"
fi
pass "Commit SQL icinde ROLLBACK yok"

grep -q "INSERT INTO auth.users" "$COMMIT_SQL" || fail "Commit SQL auth.users insert yok"
pass "Commit SQL auth.users insert var"

grep -q "INSERT INTO auth.roles" "$COMMIT_SQL" || fail "Commit SQL auth.roles insert yok"
pass "Commit SQL auth.roles insert var"

grep -q "INSERT INTO auth.user_role_assignments" "$COMMIT_SQL" || fail "Commit SQL auth.user_role_assignments insert yok"
pass "Commit SQL auth.user_role_assignments insert var"

grep -q "PILOT_TEMP_PASSWORD_HASH_RESET_REQUIRED" "$COMMIT_SQL" || fail "Commit SQL temp password hash yok"
pass "Commit SQL temp password hash var"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-4F User Role Commit SQL Package Test Report

Step: 4C-4F
Blok: User / Role Commit SQL Package / Apply Guard Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_4F_TEST_STATUS=PASS
4C_4F_COMMIT_SQL_PACKAGE_STATUS=PASS
4C_4F_COMMIT_SQL_FILE_CREATED=YES
4C_4F_COMMIT_SQL_HAS_COMMIT=YES
4C_4F_COMMIT_SQL_HAS_ROLLBACK=NO
4C_4F_PASSWORD_HASH_MAPPING=YES
4C_4F_ROLE_NAME_MAPPING=YES
4C_4F_DB_WRITE_APPLIED=NO
4C_4G_READY=YES

## Sonuc

User/role COMMIT SQL paketi test edildi.
Bu adimda DB yazma yapilmadi.
Sonraki adim: 4C-4G User / Role Apply Execution.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-4F TEST SONUCU ====="
echo "4C_4F_TEST_STATUS=PASS ✅"
echo "4C_4F_COMMIT_SQL_PACKAGE_STATUS=PASS ✅"
echo "4C_4F_COMMIT_SQL_FILE_CREATED=YES ✅"
echo "4C_4F_COMMIT_SQL_HAS_COMMIT=YES ✅"
echo "4C_4F_COMMIT_SQL_HAS_ROLLBACK=NO ✅"
echo "4C_4F_PASSWORD_HASH_MAPPING=YES ✅"
echo "4C_4F_ROLE_NAME_MAPPING=YES ✅"
echo "4C_4F_DB_WRITE_APPLIED=NO ✅"
echo "4C_4G_READY=YES ✅"
