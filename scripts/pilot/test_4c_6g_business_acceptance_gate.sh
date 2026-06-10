#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_6f_uat_bug_blocker_register_report.md"
PREV_REGISTER="uat/pilot/faz4c/uzmanparcaci/uat_bug_blocker_register.md"
EXECUTION_TEMPLATE="uat/pilot/faz4c/uzmanparcaci/uat_execution_template.md"

GATE_DOC="docs/pilot/faz4c/4c_6g_business_acceptance_gate.md"
INPUT_ENV="docs/pilot/faz4c/4c_6g_business_acceptance_input.env"
ACCEPTANCE_FORM="uat/pilot/faz4c/uzmanparcaci/business_acceptance_form.md"

REPORT_FILE="reports/pilot/faz4c/4c_6g_business_acceptance_gate_report.md"

echo "===== 4C-6G BUSINESS ACCEPTANCE GATE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-6F report yok: $PREV_REPORT"
pass "4C-6F report var"

[ -f "$PREV_REGISTER" ] || fail "UAT bug/blocker register yok: $PREV_REGISTER"
pass "UAT bug/blocker register var"

[ -f "$EXECUTION_TEMPLATE" ] || fail "UAT execution template yok: $EXECUTION_TEMPLATE"
pass "UAT execution template var"

grep -q "4C_6F_UAT_BUG_BLOCKER_REGISTER_STATUS=PASS" "$PREV_REPORT" || fail "4C-6F register PASS degil"
pass "4C-6F register PASS"

grep -q "4C_6F_CRITICAL_BLOCKER_COUNT=0" "$PREV_REPORT" || fail "4C-6F critical blocker 0 degil"
pass "4C-6F critical blocker 0"

grep -q "4C_6F_WARNING_COUNT=2" "$PREV_REPORT" || fail "4C-6F warning count 2 degil"
pass "4C-6F warning count 2"

grep -q "4C_6F_BUSINESS_ACCEPTANCE_PENDING=YES" "$PREV_REPORT" || fail "Business acceptance pending YES degil"
pass "Business acceptance pending YES"

grep -q "4C_6G_READY=YES" "$PREV_REPORT" || fail "4C-6G ready YES yok"
pass "4C-6G ready YES"

[ -f "$GATE_DOC" ] || fail "4C-6G gate doc yok"
pass "4C-6G gate doc var"

[ -f "$INPUT_ENV" ] || fail "Business acceptance input env yok"
pass "Business acceptance input env var"

[ -f "$ACCEPTANCE_FORM" ] || fail "Business acceptance form yok"
pass "Business acceptance form var"

grep -q '^BUSINESS_ACCEPTANCE_STATUS="PENDING"' "$INPUT_ENV" || fail "BUSINESS_ACCEPTANCE_STATUS PENDING degil"
pass "BUSINESS_ACCEPTANCE_STATUS PENDING"

grep -q '^BUSINESS_REPRESENTATIVE_NAME="PENDING"' "$INPUT_ENV" || fail "BUSINESS_REPRESENTATIVE_NAME PENDING degil"
pass "BUSINESS_REPRESENTATIVE_NAME PENDING"

grep -q '^FINAL_UAT_RESULT="PENDING_BUSINESS_ACCEPTANCE"' "$INPUT_ENV" || fail "FINAL_UAT_RESULT PENDING_BUSINESS_ACCEPTANCE degil"
pass "FINAL_UAT_RESULT PENDING_BUSINESS_ACCEPTANCE"

grep -q '^GO_NO_GO_READY="NO"' "$INPUT_ENV" || fail "GO_NO_GO_READY NO degil"
pass "GO_NO_GO_READY NO"

grep -q '^DB_WRITE_APPLIED="NO"' "$INPUT_ENV" || fail "DB_WRITE_APPLIED NO degil"
pass "DB_WRITE_APPLIED NO"

grep -q "4C_6G_GATE_DOC_STATUS=PASS" "$GATE_DOC" || fail "Gate doc status PASS yok"
pass "Gate doc status PASS"

grep -q "4C_6G_BUSINESS_ACCEPTANCE_STATUS=PENDING" "$GATE_DOC" || fail "Gate business acceptance PENDING yok"
pass "Gate business acceptance PENDING"

grep -q "4C_6G_FINAL_UAT_RESULT=PENDING_BUSINESS_ACCEPTANCE" "$GATE_DOC" || fail "Gate final UAT result pending yok"
pass "Gate final UAT result pending"

grep -q "4C_6G_GO_NO_GO_READY=NO" "$GATE_DOC" || fail "Gate go/no-go NO yok"
pass "Gate go/no-go NO"

grep -q "4C_6H_READY=NO" "$GATE_DOC" || fail "4C-6H ready NO yok"
pass "4C-6H ready NO"

grep -q "BUSINESS_ACCEPTS_TENANT_ACCESS=PENDING" "$ACCEPTANCE_FORM" || fail "Acceptance form tenant access pending yok"
pass "Acceptance form tenant access pending"

grep -q "BUSINESS_ACCEPTS_MARKETPLACE_PHASE_4D=PENDING" "$ACCEPTANCE_FORM" || fail "Acceptance form marketplace phase pending yok"
pass "Acceptance form marketplace phase pending"

PENDING_COUNT="$(grep -R "PENDING" "$INPUT_ENV" "$ACCEPTANCE_FORM" | wc -l | tr -d ' ')"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-6G Business Acceptance Gate Report

Step: 4C-6G
Blok: Business Acceptance Gate
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6G_BUSINESS_ACCEPTANCE_GATE_STATUS=PENDING
4C_6G_GATE_DOC_STATUS=PASS
4C_6G_PREVIOUS_BLOCK_STATUS=PASS
4C_6G_TECHNICAL_UAT_STATUS=PASS
4C_6G_TECHNICAL_FAIL_COUNT=0
4C_6G_CRITICAL_BLOCKER_COUNT=0
4C_6G_WARNING_COUNT=2
4C_6G_BUSINESS_ACCEPTANCE_STATUS=PENDING
4C_6G_PENDING_FIELD_COUNT=$PENDING_COUNT
4C_6G_FINAL_UAT_RESULT=PENDING_BUSINESS_ACCEPTANCE
4C_6G_GO_NO_GO_READY=NO
4C_6G_DB_WRITE_APPLIED=NO
4C_6G_ACCEPTANCE_INPUT_CREATED=YES
4C_6G_ACCEPTANCE_FORM_CREATED=YES
4C_6G_FINALIZATION_READY=NO
4C_6G_2_READY=YES
4C_6H_READY=NO

## Dosyalar

ACCEPTANCE_INPUT=docs/pilot/faz4c/4c_6g_business_acceptance_input.env
ACCEPTANCE_FORM=uat/pilot/faz4c/uzmanparcaci/business_acceptance_form.md
GATE_DOC=docs/pilot/faz4c/4c_6g_business_acceptance_gate.md

## Karar

Teknik UAT PASS.
Critical blocker yok.
İşletme kabulü bekliyor.
Bu sebeple 4C-6H final closure henüz açılmadı.

## Sonuc

Business acceptance gate hazırlandı.
Bu adımda DB yazma işlemi yapılmadı.
Gerçek işletme kabul bilgileri girilince 4C-6G-2 çalıştırılacak.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-6G TEST SONUCU ====="
echo "4C_6G_BUSINESS_ACCEPTANCE_GATE_STATUS=PENDING ⚠️"
echo "4C_6G_GATE_DOC_STATUS=PASS ✅"
echo "4C_6G_TECHNICAL_UAT_STATUS=PASS ✅"
echo "4C_6G_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_6G_BUSINESS_ACCEPTANCE_STATUS=PENDING ⚠️"
echo "4C_6G_FINAL_UAT_RESULT=PENDING_BUSINESS_ACCEPTANCE ⚠️"
echo "4C_6G_GO_NO_GO_READY=NO ⚠️"
echo "4C_6G_DB_WRITE_APPLIED=NO ✅"
echo "4C_6G_2_READY=YES ✅"
echo "4C_6H_READY=NO ⚠️"
