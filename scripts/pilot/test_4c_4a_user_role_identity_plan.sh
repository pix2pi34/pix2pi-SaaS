#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="docs/pilot/faz4c/4c_4a_user_role_identity_plan.env"
DOC_FILE="docs/pilot/faz4c/4c_4_user_role_assignment.md"
PREV_REPORT="reports/pilot/faz4c/4c_3i_tenant_setup_final_closure_report.md"
PREV_DOC="docs/pilot/faz4c/4c_3_final_closure.md"
REPORT_FILE="reports/pilot/faz4c/4c_4a_user_role_identity_plan_report.md"

echo "===== 4C-4A USER ROLE IDENTITY PLAN TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-3I final closure report yok: $PREV_REPORT"
pass "4C-3I final closure report var"

grep -q "4C_3_FINAL_STATUS=PASS" "$PREV_REPORT" || fail "4C-3 final PASS degil"
pass "4C-3 final PASS"

grep -q "4C_4_READY=YES" "$PREV_REPORT" || fail "4C-4 ready YES degil"
pass "4C-4 ready YES"

[ -f "$PREV_DOC" ] || fail "4C-3 final closure doc yok: $PREV_DOC"
pass "4C-3 final closure doc var"

grep -q "4C_3_TENANT_BUSINESS_CODE=UZMANPARCACI" "$PREV_DOC" || fail "Tenant business code UZMANPARCACI yok"
pass "Tenant business code UZMANPARCACI var"

grep -q "4C_3_TENANT_SCHEMA=tenant_uzmanparcaci" "$PREV_DOC" || fail "Tenant schema tenant_uzmanparcaci yok"
pass "Tenant schema tenant_uzmanparcaci var"

[ -f "$ENV_FILE" ] || fail "User role env dosyasi yok: $ENV_FILE"
pass "User role env dosyasi var"

[ -f "$DOC_FILE" ] || fail "User role assignment dokumani yok: $DOC_FILE"
pass "User role assignment dokumani var"

grep -q '^TENANT_BUSINESS_CODE="UZMANPARCACI"' "$ENV_FILE" || fail "TENANT_BUSINESS_CODE UZMANPARCACI degil"
pass "TENANT_BUSINESS_CODE UZMANPARCACI"

grep -q '^TENANT_SCHEMA="tenant_uzmanparcaci"' "$ENV_FILE" || fail "TENANT_SCHEMA tenant_uzmanparcaci degil"
pass "TENANT_SCHEMA tenant_uzmanparcaci"

grep -q '^PILOT_USER_FULL_NAME="mert_omur"' "$ENV_FILE" || fail "PILOT_USER_FULL_NAME mert_omur degil"
pass "PILOT_USER_FULL_NAME mert_omur"

grep -q '^PILOT_USER_EMAIL="uzmanparcaci1@gmail.com"' "$ENV_FILE" || fail "PILOT_USER_EMAIL dogru degil"
pass "PILOT_USER_EMAIL dogru"

grep -q '^PILOT_USER_PHONE="5377457536"' "$ENV_FILE" || fail "PILOT_USER_PHONE dogru degil"
pass "PILOT_USER_PHONE dogru"

grep -q '^PILOT_ROLE_CODE="PILOT_ADMIN"' "$ENV_FILE" || fail "PILOT_ROLE_CODE PILOT_ADMIN degil"
pass "PILOT_ROLE_CODE PILOT_ADMIN"

grep -q '^PILOT_SUPER_ADMIN_PERMISSION="NO"' "$ENV_FILE" || fail "PILOT_SUPER_ADMIN_PERMISSION NO degil"
pass "PILOT_SUPER_ADMIN_PERMISSION NO"

grep -q '^USER_ROLE_SETUP_APPLY_STATUS="NOT_APPLIED"' "$ENV_FILE" || fail "USER_ROLE_SETUP_APPLY_STATUS NOT_APPLIED degil"
pass "USER_ROLE_SETUP_APPLY_STATUS NOT_APPLIED"

grep -q "4C_4A_USER_ROLE_IDENTITY_PLAN_STATUS=PASS" "$DOC_FILE" || fail "4C-4A status PASS yok"
pass "4C-4A status PASS var"

grep -q "4C_4B_READY=YES" "$DOC_FILE" || fail "4C-4B ready YES yok"
pass "4C-4B ready YES var"

PENDING_COUNT="$(grep -c 'PENDING' "$ENV_FILE" || true)"
if [ "$PENDING_COUNT" -ne 0 ]; then
  fail "User role env icinde PENDING kalmis: $PENDING_COUNT"
fi
pass "User role env icinde PENDING yok"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-4A User Role Identity Plan Report

Step: 4C-4A
Blok: User / Role Identity Plan Freeze
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_4A_USER_ROLE_IDENTITY_PLAN_STATUS=PASS
4C_4A_PREVIOUS_BLOCK_STATUS=PASS
4C_4A_TENANT_BUSINESS_CODE=UZMANPARCACI
4C_4A_TENANT_SCHEMA=tenant_uzmanparcaci
4C_4A_PILOT_USER_FULL_NAME=mert_omur
4C_4A_PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
4C_4A_PILOT_USER_PHONE=5377457536
4C_4A_PILOT_ROLE_CODE=PILOT_ADMIN
4C_4A_SUPER_ADMIN_PERMISSION=NO
4C_4A_USER_ROLE_SETUP_APPLY_STATUS=NOT_APPLIED
4C_4A_DB_WRITE_APPLIED=NO
4C_4B_READY=YES

## Sonuc

User/role identity plan donduruldu.
Bu adimda DB apply yapilmadi.
Sonraki adim: 4C-4B Identity User / Role DB Precheck.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-4A TEST SONUCU ====="
echo "4C_4A_USER_ROLE_IDENTITY_PLAN_STATUS=PASS ✅"
echo "4C_4A_TENANT_BUSINESS_CODE=UZMANPARCACI ✅"
echo "4C_4A_PILOT_USER_EMAIL=uzmanparcaci1@gmail.com ✅"
echo "4C_4A_PILOT_ROLE_CODE=PILOT_ADMIN ✅"
echo "4C_4A_DB_WRITE_APPLIED=NO ✅"
echo "4C_4B_READY=YES ✅"
