#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/build_4c_4d_user_role_sql_package.sh"
PREV_REPORT="reports/pilot/faz4c/4c_4c_user_role_apply_strategy_test_report.md"
REPORT_FILE="reports/pilot/faz4c/4c_4d_user_role_sql_package_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_4d_user_role_sql_package_test_report.md"
SQL_FILE="sql/pilot/faz4c/4c_4d_preview_user_role_uzmanparcaci.sql"

echo "===== 4C-4D USER ROLE SQL PACKAGE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-4C test report yok: $PREV_REPORT"
pass "4C-4C test report var"

grep -q "4C_4C_TEST_STATUS=PASS" "$PREV_REPORT" || fail "4C-4C test PASS degil"
pass "4C-4C test PASS"

grep -q "4C_4D_READY=YES" "$PREV_REPORT" || fail "4C-4D ready YES yok"
pass "4C-4D ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-4D report yok: $REPORT_FILE"
pass "4C-4D report var"

[ -f "$SQL_FILE" ] || fail "SQL preview dosyasi yok: $SQL_FILE"
pass "SQL preview dosyasi var"

grep -q "4C_4D_SQL_PACKAGE_STATUS=PASS" "$REPORT_FILE" || fail "SQL package PASS degil"
pass "SQL package PASS"

grep -q "4C_4D_SELECTED_USER_TABLE=auth.users" "$REPORT_FILE" || fail "Selected user table auth.users degil"
pass "Selected user table auth.users"

grep -q "4C_4D_SELECTED_ROLE_TABLE=auth.roles" "$REPORT_FILE" || fail "Selected role table auth.roles degil"
pass "Selected role table auth.roles"

grep -q "4C_4D_SELECTED_MAPPING_TABLE=auth.user_role_assignments" "$REPORT_FILE" || fail "Selected mapping table auth.user_role_assignments degil"
pass "Selected mapping table auth.user_role_assignments"

grep -q "4C_4D_SQL_FILE_CREATED=YES" "$REPORT_FILE" || fail "SQL file created YES yok"
pass "SQL file created YES"

grep -q "4C_4D_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_4E_READY=YES" "$REPORT_FILE" || fail "4C-4E ready YES yok"
pass "4C-4E ready YES"

grep -q "INSERT INTO auth.users" "$SQL_FILE" || fail "SQL icinde auth.users insert yok"
pass "SQL auth.users insert var"

grep -q "INSERT INTO auth.roles" "$SQL_FILE" || fail "SQL icinde auth.roles insert yok"
pass "SQL auth.roles insert var"

grep -q "INSERT INTO auth.user_role_assignments" "$SQL_FILE" || fail "SQL icinde auth.user_role_assignments insert yok"
pass "SQL auth.user_role_assignments insert var"

grep -q "ROLLBACK;" "$SQL_FILE" || fail "SQL preview ROLLBACK icermiyor"
pass "SQL preview ROLLBACK var"

if grep -q "COMMIT;" "$SQL_FILE"; then
  fail "SQL preview COMMIT icermemeli"
fi
pass "SQL preview COMMIT icermiyor"

USER_COLUMN_COUNT="$(grep '^4C_4D_USER_COLUMN_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
ROLE_COLUMN_COUNT="$(grep '^4C_4D_ROLE_COLUMN_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
ASSIGN_COLUMN_COUNT="$(grep '^4C_4D_ASSIGN_COLUMN_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
EXISTING_USER_COUNT="$(grep '^4C_4D_EXISTING_USER_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
EXISTING_ROLE_COUNT="$(grep '^4C_4D_EXISTING_ROLE_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
ROLE_CODE_COL="$(grep '^4C_4D_ROLE_CODE_COL=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$TEST_REPORT"
# FAZ 4C — 4C-4D User Role SQL Package Test Report

Step: 4C-4D-FIX2
Blok: User / Role SQL Package / Dry Run Plan Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_4D_TEST_STATUS=PASS
4C_4D_SQL_PACKAGE_STATUS=PASS
4C_4D_SELECTED_USER_TABLE=auth.users
4C_4D_SELECTED_ROLE_TABLE=auth.roles
4C_4D_SELECTED_MAPPING_TABLE=auth.user_role_assignments
4C_4D_ROLE_CODE_COL=$ROLE_CODE_COL
4C_4D_USER_COLUMN_COUNT=$USER_COLUMN_COUNT
4C_4D_ROLE_COLUMN_COUNT=$ROLE_COLUMN_COUNT
4C_4D_ASSIGN_COLUMN_COUNT=$ASSIGN_COLUMN_COUNT
4C_4D_EXISTING_USER_COUNT=$EXISTING_USER_COUNT
4C_4D_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT
4C_4D_SQL_FILE_CREATED=YES
4C_4D_DB_WRITE_APPLIED=NO
4C_4E_READY=YES

## Sonuc

User/role SQL package test tamamlandi.
DB yazma islemi yapilmadi.
Sonraki adim: 4C-4E User / Role SQL Dry Run / ROLLBACK Verification.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-4D TEST SONUCU ====="
echo "4C_4D_TEST_STATUS=PASS ✅"
echo "4C_4D_SELECTED_USER_TABLE=auth.users ✅"
echo "4C_4D_SELECTED_ROLE_TABLE=auth.roles ✅"
echo "4C_4D_SELECTED_MAPPING_TABLE=auth.user_role_assignments ✅"
echo "4C_4D_ROLE_CODE_COL=$ROLE_CODE_COL"
echo "4C_4D_USER_COLUMN_COUNT=$USER_COLUMN_COUNT"
echo "4C_4D_ROLE_COLUMN_COUNT=$ROLE_COLUMN_COUNT"
echo "4C_4D_ASSIGN_COLUMN_COUNT=$ASSIGN_COLUMN_COUNT"
echo "4C_4D_EXISTING_USER_COUNT=$EXISTING_USER_COUNT"
echo "4C_4D_EXISTING_ROLE_COUNT=$EXISTING_ROLE_COUNT"
echo "4C_4D_DB_WRITE_APPLIED=NO ✅"
echo "4C_4E_READY=YES ✅"
