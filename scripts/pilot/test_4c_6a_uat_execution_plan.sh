#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_5j_real_pilot_data_import_final_closure_report.md"
PREV_DOC="docs/pilot/faz4c/4c_5_final_closure.md"

MAIN_DOC="docs/pilot/faz4c/4c_6_real_uat_execution.md"
PLAN_DOC="docs/pilot/faz4c/4c_6a_uat_execution_plan.md"
ENV_FILE="docs/pilot/faz4c/4c_6a_uat_execution_scope.env"
CHECKLIST="uat/pilot/faz4c/uzmanparcaci/uat_checklist.md"

REPORT_FILE="reports/pilot/faz4c/4c_6a_uat_execution_plan_report.md"

echo "===== 4C-6A UAT EXECUTION PLAN / CHECKLIST FREEZE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-5J final closure report yok: $PREV_REPORT"
pass "4C-5J final closure report var"

[ -f "$PREV_DOC" ] || fail "4C-5 final closure doc yok: $PREV_DOC"
pass "4C-5 final closure doc var"

grep -q "4C_5_FINAL_STATUS=PASS" "$PREV_REPORT" || fail "4C-5 final PASS degil"
pass "4C-5 final PASS"

grep -q "4C_5_REAL_PILOT_DATA_ENTRY_IMPORT_STATUS=PASS" "$PREV_REPORT" || fail "4C-5 import PASS degil"
pass "4C-5 import PASS"

grep -q "4C_5_STAGING_DB_WRITE_APPLIED=YES" "$PREV_REPORT" || fail "4C-5 staging DB write YES degil"
pass "4C-5 staging DB write YES"

grep -q "4C_5_CORE_DB_WRITE_APPLIED=NO" "$PREV_REPORT" || fail "4C-5 core DB write NO degil"
pass "4C-5 core DB write NO"

grep -q "4C_6_READY=YES" "$PREV_REPORT" || fail "4C-6 ready YES yok"
pass "4C-6 ready YES"

[ -f "$MAIN_DOC" ] || fail "4C-6 ana dokuman yok"
pass "4C-6 ana dokuman var"

[ -f "$PLAN_DOC" ] || fail "4C-6A plan dokumani yok"
pass "4C-6A plan dokumani var"

[ -f "$ENV_FILE" ] || fail "4C-6A env dosyasi yok"
pass "4C-6A env dosyasi var"

[ -f "$CHECKLIST" ] || fail "UAT checklist yok"
pass "UAT checklist var"

grep -q '^TENANT_BUSINESS_CODE="UZMANPARCACI"' "$ENV_FILE" || fail "TENANT_BUSINESS_CODE UZMANPARCACI degil"
pass "TENANT_BUSINESS_CODE UZMANPARCACI"

grep -q '^PILOT_BUSINESS_NAME="uzmanparcaci"' "$ENV_FILE" || fail "Pilot business uzmanparcaci degil"
pass "Pilot business uzmanparcaci"

grep -q '^PILOT_SECTOR="OTO_YEDEK_PARCA"' "$ENV_FILE" || fail "Pilot sector OTO_YEDEK_PARCA degil"
pass "Pilot sector OTO_YEDEK_PARCA"

grep -q '^UAT_MODE="REAL_PILOT_UAT"' "$ENV_FILE" || fail "UAT mode REAL_PILOT_UAT degil"
pass "UAT mode REAL_PILOT_UAT"

grep -q '^UAT_SCOPE_STATUS="FROZEN"' "$ENV_FILE" || fail "UAT scope FROZEN degil"
pass "UAT scope FROZEN"

grep -q '^UAT_DB_WRITE_APPLIED="NO"' "$ENV_FILE" || fail "UAT DB write NO degil"
pass "UAT DB write NO"

grep -q '^UAT_SAMPLE_ROW_COUNT_EXPECTED="5"' "$ENV_FILE" || fail "UAT sample row expected 5 degil"
pass "UAT sample row expected 5"

grep -q '^UAT_CORE_PRODUCT_APPLY_EXPECTED="NO"' "$ENV_FILE" || fail "UAT core product apply expected NO degil"
pass "UAT core product apply expected NO"

grep -q '^UAT_MARKETPLACE_LIVE_INTEGRATION_EXPECTED="NO"' "$ENV_FILE" || fail "UAT marketplace live expected NO degil"
pass "UAT marketplace live expected NO"

grep -q "4C_6A_UAT_EXECUTION_PLAN_STATUS=PASS" "$PLAN_DOC" || fail "4C-6A status PASS yok"
pass "4C-6A status PASS var"

grep -q "4C_6B_READY=YES" "$PLAN_DOC" || fail "4C-6B ready YES yok"
pass "4C-6B ready YES var"

grep -q "UAT-01" "$CHECKLIST" || fail "Checklist UAT-01 yok"
pass "Checklist UAT-01 var"

grep -q "UAT-14" "$CHECKLIST" || fail "Checklist UAT-14 yok"
pass "Checklist UAT-14 var"

grep -q "UAT_RESULT=PENDING" "$CHECKLIST" || fail "Checklist UAT_RESULT PENDING yok"
pass "Checklist UAT_RESULT PENDING var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-6A UAT Execution Plan Report

Step: 4C-6A
Blok: UAT Execution Plan / Checklist Freeze
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6A_UAT_EXECUTION_PLAN_STATUS=PASS
4C_6A_PREVIOUS_BLOCK_STATUS=PASS
4C_6A_UAT_SCOPE_STATUS=FROZEN
4C_6A_SELECTED_BUSINESS=uzmanparcaci
4C_6A_SELECTED_SECTOR=OTO_YEDEK_PARCA
4C_6A_TENANT_BUSINESS_CODE=UZMANPARCACI
4C_6A_UAT_MODE=REAL_PILOT_UAT
4C_6A_UAT_EXECUTION_TYPE=CHECKLIST_BASED
4C_6A_UAT_CHECKLIST_CREATED=YES
4C_6A_UAT_CHECKLIST_PATH=uat/pilot/faz4c/uzmanparcaci/uat_checklist.md
4C_6A_EXPECTED_SAMPLE_ROW_COUNT=5
4C_6A_CORE_PRODUCT_APPLY_EXPECTED=NO
4C_6A_MARKETPLACE_LIVE_INTEGRATION_EXPECTED=NO
4C_6A_DB_WRITE_APPLIED=NO
4C_6A_CRITICAL_BLOCKER_COUNT=0
4C_6B_READY=YES

## Sonuc

uzmanparcaci gerçek UAT kapsamı donduruldu.
UAT checklist oluşturuldu.
Bu adımda DB yazma işlemi yapılmadı.
Sonraki adım: 4C-6B UAT Runtime Precheck.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-6A TEST SONUCU ====="
echo "4C_6A_UAT_EXECUTION_PLAN_STATUS=PASS ✅"
echo "4C_6A_UAT_SCOPE_STATUS=FROZEN ✅"
echo "4C_6A_SELECTED_BUSINESS=uzmanparcaci ✅"
echo "4C_6A_SELECTED_SECTOR=OTO_YEDEK_PARCA ✅"
echo "4C_6A_UAT_CHECKLIST_CREATED=YES ✅"
echo "4C_6A_EXPECTED_SAMPLE_ROW_COUNT=5 ✅"
echo "4C_6A_CORE_PRODUCT_APPLY_EXPECTED=NO ✅"
echo "4C_6A_MARKETPLACE_LIVE_INTEGRATION_EXPECTED=NO ✅"
echo "4C_6A_DB_WRITE_APPLIED=NO ✅"
echo "4C_6B_READY=YES ✅"
