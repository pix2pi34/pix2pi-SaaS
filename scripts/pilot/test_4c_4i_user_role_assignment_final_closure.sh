#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FINAL_DOC="docs/pilot/faz4c/4c_4i_user_role_assignment_final_closure.md"
ALIAS_DOC="docs/pilot/faz4c/4c_4_final_closure.md"

A_REPORT="reports/pilot/faz4c/4c_4a_user_role_identity_plan_report.md"
B_REPORT="reports/pilot/faz4c/4c_4b_identity_user_role_db_precheck_test_report.md"
C_REPORT="reports/pilot/faz4c/4c_4c_user_role_apply_strategy_test_report.md"
D_REPORT="reports/pilot/faz4c/4c_4d_user_role_sql_package_test_report.md"
D_FIX4_REPORT="reports/pilot/faz4c/4c_4d_fix4_password_hash_role_name_report.md"
E_REPORT="reports/pilot/faz4c/4c_4e_user_role_sql_dry_run_test_report.md"
F_REPORT="reports/pilot/faz4c/4c_4f_user_role_commit_sql_package_test_report.md"
G_REPORT="reports/pilot/faz4c/4c_4g_user_role_apply_execution_test_report.md"
H_REPORT="reports/pilot/faz4c/4c_4h_user_role_verification_test_report.md"
H_MAIN_REPORT="reports/pilot/faz4c/4c_4h_user_role_verification_report.md"

REPORT_FILE="reports/pilot/faz4c/4c_4i_user_role_assignment_final_closure_report.md"

echo "===== 4C-4I USER ROLE ASSIGNMENT FINAL CLOSURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$FINAL_DOC" ] || fail "4C-4I final closure dokumani yok"
pass "4C-4I final closure dokumani var"

[ -f "$ALIAS_DOC" ] || fail "4C-4 final closure alias dokumani yok"
pass "4C-4 final closure alias dokumani var"

for report in "$A_REPORT" "$B_REPORT" "$C_REPORT" "$D_REPORT" "$D_FIX4_REPORT" "$E_REPORT" "$F_REPORT" "$G_REPORT" "$H_REPORT" "$H_MAIN_REPORT"; do
  [ -f "$report" ] || fail "Eksik report: $report"
done
pass "Tum onceki report dosyalari var"

grep -q "4C_4A_USER_ROLE_IDENTITY_PLAN_STATUS=PASS" "$A_REPORT" || fail "4C-4A PASS degil"
pass "4C-4A PASS"

grep -q "4C_4B_TEST_STATUS=PASS" "$B_REPORT" || fail "4C-4B PASS degil"
pass "4C-4B PASS"

grep -q "4C_4C_TEST_STATUS=PASS" "$C_REPORT" || fail "4C-4C PASS degil"
pass "4C-4C PASS"

grep -q "4C_4D_TEST_STATUS=PASS" "$D_REPORT" || fail "4C-4D PASS degil"
pass "4C-4D PASS"

grep -q "4C_4D_FIX4_STATUS=PASS" "$D_FIX4_REPORT" || fail "4C-4D-FIX4 PASS degil"
pass "4C-4D-FIX4 PASS"

grep -q "4C_4E_TEST_STATUS=PASS" "$E_REPORT" || fail "4C-4E PASS degil"
pass "4C-4E PASS"

grep -q "4C_4E_ROLLBACK_VERIFIED=YES" "$E_REPORT" || fail "4C-4E rollback verified YES degil"
pass "4C-4E rollback verified YES"

grep -q "4C_4F_TEST_STATUS=PASS" "$F_REPORT" || fail "4C-4F PASS degil"
pass "4C-4F PASS"

grep -q "4C_4G_TEST_STATUS=PASS" "$G_REPORT" || fail "4C-4G PASS degil"
pass "4C-4G PASS"

grep -q "4C_4G_DB_WRITE_APPLIED=YES" "$G_REPORT" || fail "4C-4G DB write YES degil"
pass "4C-4G DB write YES"

grep -q "4C_4H_TEST_STATUS=PASS" "$H_REPORT" || fail "4C-4H PASS degil"
pass "4C-4H PASS"

grep -q "4C_4H_USER_ROLE_VERIFICATION_STATUS=PASS" "$H_MAIN_REPORT" || fail "4C-4H verification PASS degil"
pass "4C-4H verification PASS"

grep -q "4C_4H_USER_COUNT=1" "$H_MAIN_REPORT" || fail "4C-4H user count 1 degil"
pass "4C-4H user count 1"

grep -q "4C_4H_ROLE_COUNT=1" "$H_MAIN_REPORT" || fail "4C-4H role count 1 degil"
pass "4C-4H role count 1"

grep -q "4C_4H_ASSIGNMENT_COUNT=1" "$H_MAIN_REPORT" || fail "4C-4H assignment count 1 degil"
pass "4C-4H assignment count 1"

grep -q "4C_4H_SUPER_ADMIN_ASSIGNMENT_COUNT=0" "$H_MAIN_REPORT" || fail "Super admin assignment 0 degil"
pass "Super admin assignment 0"

grep -q "4C_4H_CROSS_TENANT_ASSIGNMENT_COUNT=0" "$H_MAIN_REPORT" || fail "Cross tenant assignment 0 degil"
pass "Cross tenant assignment 0"

grep -q "4C_4H_PASSWORD_HASH_STATUS=TEMP_PASSWORD_HASH_RESET_REQUIRED" "$H_MAIN_REPORT" || fail "Password reset gate status yok"
pass "Password reset gate status var"

grep -q "4C_4_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-4 final status PASS yok"
pass "4C-4 final status PASS"

grep -q "4C_4_REAL_USER_ROLE_ASSIGNMENT_STATUS=PASS" "$FINAL_DOC" || fail "4C-4 user role assignment PASS yok"
pass "4C-4 user role assignment PASS"

grep -q "4C_4_USER_CREATED=YES" "$FINAL_DOC" || fail "4C-4 user created YES yok"
pass "4C-4 user created YES"

grep -q "4C_4_ROLE_CREATED=YES" "$FINAL_DOC" || fail "4C-4 role created YES yok"
pass "4C-4 role created YES"

grep -q "4C_4_ASSIGNMENT_CREATED=YES" "$FINAL_DOC" || fail "4C-4 assignment created YES yok"
pass "4C-4 assignment created YES"

grep -q "4C_4_SUPER_ADMIN_ASSIGNMENT_COUNT=0" "$FINAL_DOC" || fail "4C-4 super admin count 0 yok"
pass "4C-4 super admin count 0"

grep -q "4C_4_CROSS_TENANT_ASSIGNMENT_COUNT=0" "$FINAL_DOC" || fail "4C-4 cross tenant count 0 yok"
pass "4C-4 cross tenant count 0"

grep -q "4C_4_PASSWORD_RESET_OR_INVITE_REQUIRED=YES" "$FINAL_DOC" || fail "Password reset/invite required YES yok"
pass "Password reset/invite required YES"

grep -q "4C_5_READY=YES" "$FINAL_DOC" || fail "4C-5 ready YES yok"
pass "4C-5 ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-4I User Role Assignment Final Closure Report

Step: 4C-4I
Blok: User / Role Assignment Final Closure
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_4I_FINAL_DOC_STATUS=PASS
4C_4I_ALIAS_DOC_STATUS=PASS
4C_4A_STATUS=PASS
4C_4B_STATUS=PASS
4C_4C_STATUS=PASS
4C_4D_STATUS=PASS
4C_4D_FIX4_STATUS=PASS
4C_4E_STATUS=PASS
4C_4F_STATUS=PASS
4C_4G_STATUS=PASS
4C_4H_STATUS=PASS
4C_4_FINAL_STATUS=PASS
4C_4_REAL_USER_ROLE_ASSIGNMENT_STATUS=PASS
4C_4_TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439
4C_4_TENANT_BUSINESS_CODE=UZMANPARCACI
4C_4_PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
4C_4_PILOT_ROLE_CODE=PILOT_ADMIN
4C_4_USER_CREATED=YES
4C_4_ROLE_CREATED=YES
4C_4_ASSIGNMENT_CREATED=YES
4C_4_SUPER_ADMIN_ASSIGNMENT_COUNT=0
4C_4_CROSS_TENANT_ASSIGNMENT_COUNT=0
4C_4_PASSWORD_RESET_OR_INVITE_REQUIRED=YES
4C_4_DB_WRITE_APPLIED=YES
4C_4_CRITICAL_BLOCKER_COUNT=0
4C_4_WARNING_COUNT=1
4C_5_READY=YES

## Sonuc

4C-4 Real User / Role Assignment ana blogu kapandi.
uzmanparcaci pilot kullanicisi, PILOT_ADMIN rolu ve tenant assignment tamamlandi.
Sonraki ana blok: 4C-5 Real Pilot Data Entry / Import.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-4I TEST SONUCU ====="
echo "4C_4_FINAL_STATUS=PASS ✅"
echo "4C_4_REAL_USER_ROLE_ASSIGNMENT_STATUS=PASS ✅"
echo "4C_4_PILOT_USER_EMAIL=uzmanparcaci1@gmail.com ✅"
echo "4C_4_PILOT_ROLE_CODE=PILOT_ADMIN ✅"
echo "4C_4_USER_CREATED=YES ✅"
echo "4C_4_ROLE_CREATED=YES ✅"
echo "4C_4_ASSIGNMENT_CREATED=YES ✅"
echo "4C_4_SUPER_ADMIN_ASSIGNMENT_COUNT=0 ✅"
echo "4C_4_CROSS_TENANT_ASSIGNMENT_COUNT=0 ✅"
echo "4C_4_PASSWORD_RESET_OR_INVITE_REQUIRED=YES ⚠️"
echo "4C_4_DB_WRITE_APPLIED=YES ✅"
echo "4C_5_READY=YES ✅"
