#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

FINAL_DOC="docs/pilot/faz4c/4c_3i_tenant_setup_final_closure.md"
ALIAS_DOC="docs/pilot/faz4c/4c_3_final_closure.md"

A_REPORT="reports/pilot/faz4c/4c_3a_tenant_identity_setup_plan_report.md"
B_REPORT="reports/pilot/faz4c/4c_3b_db_tenant_precheck_report.md"
C_REPORT="reports/pilot/faz4c/4c_3c_tenant_apply_strategy_decision_report.md"
D_FIX3_REPORT="reports/pilot/faz4c/4c_3d_fix3_business_code_uppercase_report.md"
E_REPORT="reports/pilot/faz4c/4c_3e_tenant_sql_dry_run_test_report.md"
F_REPORT="reports/pilot/faz4c/4c_3f_tenant_commit_sql_package_test_report.md"
G_REPORT="reports/pilot/faz4c/4c_3g_tenant_apply_execution_test_report.md"
H_REPORT="reports/pilot/faz4c/4c_3h_tenant_apply_verification_test_report.md"

REPORT_FILE="reports/pilot/faz4c/4c_3i_tenant_setup_final_closure_report.md"

echo "===== 4C-3I TENANT SETUP FINAL CLOSURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$FINAL_DOC" ] || fail "4C-3I final closure dokumani yok"
pass "4C-3I final closure dokumani var"

[ -f "$ALIAS_DOC" ] || fail "4C-3 final closure alias dokumani yok"
pass "4C-3 final closure alias dokumani var"

for report in "$A_REPORT" "$B_REPORT" "$C_REPORT" "$D_FIX3_REPORT" "$E_REPORT" "$F_REPORT" "$G_REPORT" "$H_REPORT"; do
  [ -f "$report" ] || fail "Eksik report: $report"
done
pass "Tum onceki report dosyalari var"

grep -q "4C_3A_TENANT_IDENTITY_PLAN_STATUS=PASS" "$A_REPORT" || fail "4C-3A PASS degil"
pass "4C-3A PASS"

grep -q "4C_3B_DB_TENANT_PRECHECK_STATUS=PASS" "$B_REPORT" || fail "4C-3B PASS degil"
pass "4C-3B PASS"

grep -q "4C_3C_TENANT_APPLY_STRATEGY_STATUS=PASS" "$C_REPORT" || fail "4C-3C PASS degil"
pass "4C-3C PASS"

grep -q "4C_3D_FIX3_BUSINESS_CODE_UPPERCASE_STATUS=PASS" "$D_FIX3_REPORT" || fail "4C-3D-FIX3 PASS degil"
pass "4C-3D-FIX3 PASS"

grep -q "4C_3D_FIX3_BUSINESS_CODE=UZMANPARCACI" "$D_FIX3_REPORT" || fail "Business code UZMANPARCACI degil"
pass "Business code UZMANPARCACI"

grep -q "4C_3E_TEST_STATUS=PASS" "$E_REPORT" || fail "4C-3E PASS degil"
pass "4C-3E PASS"

grep -q "4C_3E_ROLLBACK_VERIFIED=YES" "$E_REPORT" || fail "4C-3E rollback verified YES degil"
pass "4C-3E rollback verified YES"

grep -q "4C_3F_TEST_STATUS=PASS" "$F_REPORT" || fail "4C-3F PASS degil"
pass "4C-3F PASS"

grep -q "4C_3G_TEST_STATUS=PASS" "$G_REPORT" || fail "4C-3G PASS degil"
pass "4C-3G PASS"

grep -q "4C_3G_DB_WRITE_APPLIED=YES" "$G_REPORT" || fail "4C-3G DB write YES degil"
pass "4C-3G DB write YES"

grep -q "4C_3H_TEST_STATUS=PASS" "$H_REPORT" || fail "4C-3H PASS degil"
pass "4C-3H PASS"

grep -q "4C_3H_TENANT_VERIFICATION_STATUS=PASS" "$H_REPORT" || fail "4C-3H verification PASS degil"
pass "4C-3H verification PASS"

grep -q "4C_3H_SCHEMA_COUNT=1" "$H_REPORT" || fail "4C-3H schema count 1 degil"
pass "4C-3H schema count 1"

grep -q "4C_3H_TENANT_COUNT_BY_SLUG=1" "$H_REPORT" || fail "4C-3H tenant count 1 degil"
pass "4C-3H tenant count 1"

grep -q "4C_3_FINAL_STATUS=PASS" "$FINAL_DOC" || fail "4C-3 final status PASS yok"
pass "4C-3 final status PASS"

grep -q "4C_3_REAL_PILOT_TENANT_SETUP_STATUS=PASS" "$FINAL_DOC" || fail "4C-3 tenant setup PASS yok"
pass "4C-3 tenant setup PASS"

grep -q "4C_3_TENANT_BUSINESS_CODE=UZMANPARCACI" "$FINAL_DOC" || fail "4C-3 business code yok"
pass "4C-3 business code var"

grep -q "4C_3_TENANT_SCHEMA=tenant_uzmanparcaci" "$FINAL_DOC" || fail "4C-3 tenant schema yok"
pass "4C-3 tenant schema var"

grep -q "4C_4_READY=YES" "$FINAL_DOC" || fail "4C-4 ready YES yok"
pass "4C-4 ready YES"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-3I Tenant Setup Final Closure Report

Step: 4C-3I
Blok: Tenant Setup Final Closure
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3I_FINAL_DOC_STATUS=PASS
4C_3I_ALIAS_DOC_STATUS=PASS
4C_3A_STATUS=PASS
4C_3B_STATUS=PASS
4C_3C_STATUS=PASS
4C_3D_FIX3_STATUS=PASS
4C_3E_STATUS=PASS
4C_3F_STATUS=PASS
4C_3G_STATUS=PASS
4C_3H_STATUS=PASS
4C_3_FINAL_STATUS=PASS
4C_3_REAL_PILOT_TENANT_SETUP_STATUS=PASS
4C_3_TENANT_BUSINESS_CODE=UZMANPARCACI
4C_3_TENANT_SLUG=uzmanparcaci
4C_3_TENANT_SCHEMA=tenant_uzmanparcaci
4C_3_DB_WRITE_APPLIED=YES
4C_3_CRITICAL_BLOCKER_COUNT=0
4C_4_READY=YES

## Sonuc

4C-3 Real Pilot Tenant Setup ana blogu kapandi.
uzmanparcaci gercek pilot tenant olarak kuruldu.
Sonraki ana blok: 4C-4 Real User / Role Assignment.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-3I TEST SONUCU ====="
echo "4C_3_FINAL_STATUS=PASS ✅"
echo "4C_3_REAL_PILOT_TENANT_SETUP_STATUS=PASS ✅"
echo "4C_3_TENANT_BUSINESS_CODE=UZMANPARCACI ✅"
echo "4C_3_TENANT_SLUG=uzmanparcaci ✅"
echo "4C_3_TENANT_SCHEMA=tenant_uzmanparcaci ✅"
echo "4C_3_DB_WRITE_APPLIED=YES ✅"
echo "4C_4_READY=YES ✅"
