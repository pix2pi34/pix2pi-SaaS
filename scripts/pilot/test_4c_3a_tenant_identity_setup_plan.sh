#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="docs/pilot/faz4c/4c_3a_tenant_identity_setup_plan.env"
DOC_FILE="docs/pilot/faz4c/4c_3_tenant_setup.md"
PREV_REPORT="reports/pilot/faz4c/4c_2f_runtime_gap_final_closure_report.md"
PROFILE_DOC="docs/pilot/faz4c/4c_1_1h_real_business_profile_applied.md"
REPORT_FILE="reports/pilot/faz4c/4c_3a_tenant_identity_setup_plan_report.md"

echo "===== 4C-3A TENANT IDENTITY SETUP PLAN TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-2 final closure report yok: $PREV_REPORT"
pass "4C-2 final closure report var"

grep -q "4C_2_FINAL_STATUS=PASS" "$PREV_REPORT" || fail "4C-2 final PASS degil"
pass "4C-2 final PASS"

grep -q "4C_3_READY=YES" "$PREV_REPORT" || fail "4C-3 ready YES degil"
pass "4C-3 ready YES"

[ -f "$PROFILE_DOC" ] || fail "Pilot business profile yok: $PROFILE_DOC"
pass "Pilot business profile var"

grep -q "uzmanparcaci" "$PROFILE_DOC" || fail "Pilot profile icinde uzmanparcaci yok"
pass "Pilot profile icinde uzmanparcaci var"

[ -f "$ENV_FILE" ] || fail "Tenant env dosyasi yok: $ENV_FILE"
pass "Tenant env dosyasi var"

[ -f "$DOC_FILE" ] || fail "Tenant setup dokumani yok: $DOC_FILE"
pass "Tenant setup dokumani var"

grep -q '^TENANT_CODE="uzmanparcaci"' "$ENV_FILE" || fail "TENANT_CODE uzmanparcaci degil"
pass "TENANT_CODE uzmanparcaci"

grep -q '^TENANT_SCHEMA="tenant_uzmanparcaci"' "$ENV_FILE" || fail "TENANT_SCHEMA tenant_uzmanparcaci degil"
pass "TENANT_SCHEMA tenant_uzmanparcaci"

grep -q '^TENANT_IS_REAL_PILOT="YES"' "$ENV_FILE" || fail "TENANT_IS_REAL_PILOT YES degil"
pass "TENANT_IS_REAL_PILOT YES"

grep -q '^TENANT_IS_TEST_TENANT="NO"' "$ENV_FILE" || fail "TENANT_IS_TEST_TENANT NO degil"
pass "TENANT_IS_TEST_TENANT NO"

grep -q '^TENANT_MARKETPLACE_LIVE_INTEGRATION="NO"' "$ENV_FILE" || fail "Marketplace live integration NO degil"
pass "Marketplace live integration NO"

grep -q '^TENANT_MARKETPLACE_PHASE="FAZ_4D"' "$ENV_FILE" || fail "Marketplace phase FAZ_4D degil"
pass "Marketplace phase FAZ_4D"

grep -q "4C_3A_TENANT_IDENTITY_PLAN_STATUS=PASS" "$DOC_FILE" || fail "4C-3A status PASS yok"
pass "4C-3A status PASS var"

grep -q "4C_3B_READY=YES" "$DOC_FILE" || fail "4C-3B ready YES yok"
pass "4C-3B ready YES var"

PENDING_COUNT="$(grep -c 'PENDING' "$ENV_FILE" || true)"

if [ "$PENDING_COUNT" -ne 0 ]; then
  fail "Tenant env icinde PENDING kalmis: $PENDING_COUNT"
fi

pass "Tenant env icinde PENDING yok"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-3A Tenant Identity Setup Plan Report

Step: 4C-3A
Blok: Tenant Identity / Setup Plan Freeze
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_3A_TENANT_IDENTITY_PLAN_STATUS=PASS
4C_3A_PREVIOUS_BLOCK_STATUS=PASS
4C_3A_SELECTED_BUSINESS=uzmanparcaci
4C_3A_TENANT_CODE=uzmanparcaci
4C_3A_TENANT_SCHEMA=tenant_uzmanparcaci
4C_3A_TENANT_IS_REAL_PILOT=YES
4C_3A_TENANT_IS_TEST_TENANT=NO
4C_3A_MARKETPLACE_LIVE_INTEGRATION=NO
4C_3A_MARKETPLACE_PHASE=FAZ_4D
4C_3A_TENANT_SETUP_APPLY_STATUS=NOT_APPLIED
4C_3B_READY=YES

## Sonuc

Tenant identity ve setup plan donduruldu.
Bu adimda DB apply yapilmadi.
Sonraki adim: 4C-3B DB Tenant Precheck / Existing Tenant Discovery.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-3A TEST SONUCU ====="
echo "4C_3A_TENANT_IDENTITY_PLAN_STATUS=PASS ✅"
echo "4C_3A_SELECTED_BUSINESS=uzmanparcaci ✅"
echo "4C_3A_TENANT_CODE=uzmanparcaci ✅"
echo "4C_3A_TENANT_SCHEMA=tenant_uzmanparcaci ✅"
echo "4C_3A_TENANT_SETUP_APPLY_STATUS=NOT_APPLIED ✅"
echo "4C_3B_READY=YES ✅"
