#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_6e_uat_result_classification_report.md"
PREV_DOC="docs/pilot/faz4c/4c_6e_uat_result_classification.md"
UAT_CLASS_FILE="uat/pilot/faz4c/uzmanparcaci/uat_result_classification.md"
EXECUTION_TEMPLATE="uat/pilot/faz4c/uzmanparcaci/uat_execution_template.md"

REGISTER_DOC="docs/pilot/faz4c/4c_6f_uat_bug_blocker_register.md"
REGISTER_FILE="uat/pilot/faz4c/uzmanparcaci/uat_bug_blocker_register.md"
REPORT_FILE="reports/pilot/faz4c/4c_6f_uat_bug_blocker_register_report.md"

echo "===== 4C-6F UAT BUG / BLOCKER REGISTER TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-6E report yok: $PREV_REPORT"
pass "4C-6E report var"

[ -f "$PREV_DOC" ] || fail "4C-6E doc yok: $PREV_DOC"
pass "4C-6E doc var"

[ -f "$UAT_CLASS_FILE" ] || fail "UAT classification file yok: $UAT_CLASS_FILE"
pass "UAT classification file var"

[ -f "$EXECUTION_TEMPLATE" ] || fail "UAT execution template yok: $EXECUTION_TEMPLATE"
pass "UAT execution template var"

grep -q "4C_6E_UAT_RESULT_CLASSIFICATION_STATUS=PASS" "$PREV_REPORT" || fail "4C-6E classification PASS degil"
pass "4C-6E classification PASS"

grep -q "4C_6E_TECHNICAL_UAT_CLASSIFICATION=PASS" "$PREV_REPORT" || fail "4C-6E technical classification PASS degil"
pass "4C-6E technical classification PASS"

grep -q "4C_6E_UAT_RESULT_CLASSIFICATION=TECHNICAL_PASS_BUSINESS_ACCEPTANCE_PENDING" "$PREV_REPORT" || fail "4C-6E result classification beklenen degil"
pass "4C-6E result classification beklenen"

grep -q "4C_6E_TECHNICAL_FAIL_COUNT=0" "$PREV_REPORT" || fail "4C-6E technical fail count 0 degil"
pass "4C-6E technical fail count 0"

grep -q "4C_6E_CRITICAL_BLOCKER_COUNT=0" "$PREV_REPORT" || fail "4C-6E critical blocker 0 degil"
pass "4C-6E critical blocker 0"

grep -q "4C_6E_WARNING_COUNT=2" "$PREV_REPORT" || fail "4C-6E warning count 2 degil"
pass "4C-6E warning count 2"

grep -q "4C_6E_BUSINESS_ACCEPTANCE_STATUS=PENDING" "$PREV_REPORT" || fail "4C-6E business acceptance PENDING degil"
pass "4C-6E business acceptance PENDING"

grep -q "4C_6F_READY=YES" "$PREV_REPORT" || fail "4C-6F ready YES yok"
pass "4C-6F ready YES"

[ -f "$REGISTER_DOC" ] || fail "4C-6F register doc yok"
pass "4C-6F register doc var"

[ -f "$REGISTER_FILE" ] || fail "UAT bug/blocker register file yok"
pass "UAT bug/blocker register file var"

grep -q "4C_6F_UAT_BUG_BLOCKER_REGISTER_STATUS=PASS" "$REGISTER_DOC" || fail "Register status PASS yok"
pass "Register status PASS var"

grep -q "4C_6F_CRITICAL_BLOCKER_COUNT=0" "$REGISTER_DOC" || fail "Critical blocker count 0 yok"
pass "Critical blocker count 0 var"

grep -q "4C_6F_WARNING_COUNT=2" "$REGISTER_DOC" || fail "Warning count 2 yok"
pass "Warning count 2 var"

grep -q "4C_6F_IMPROVEMENT_COUNT=3" "$REGISTER_DOC" || fail "Improvement count 3 yok"
pass "Improvement count 3 var"

grep -q "4C_6F_BARKOD_WARNING_IS_BLOCKER=NO" "$REGISTER_DOC" || fail "Barkod warning blocker NO yok"
pass "Barkod warning blocker NO var"

grep -q "4C_6F_BUSINESS_ACCEPTANCE_PENDING=YES" "$REGISTER_DOC" || fail "Business acceptance pending YES yok"
pass "Business acceptance pending YES var"

grep -q "4C_6F_UAT_13_STATUS=PASS" "$REGISTER_DOC" || fail "UAT-13 status PASS yok"
pass "UAT-13 status PASS var"

grep -q "4C_6F_DB_WRITE_APPLIED=NO" "$REGISTER_DOC" || fail "DB write applied NO yok"
pass "DB write applied NO var"

grep -q "4C_6G_READY=YES" "$REGISTER_DOC" || fail "4C-6G ready YES yok"
pass "4C-6G ready YES var"

grep -q "WARN-01" "$REGISTER_FILE" || fail "WARN-01 yok"
pass "WARN-01 var"

grep -q "WARN-02" "$REGISTER_FILE" || fail "WARN-02 yok"
pass "WARN-02 var"

grep -q "IMP-01" "$REGISTER_FILE" || fail "IMP-01 yok"
pass "IMP-01 var"

grep -q "IMP-02" "$REGISTER_FILE" || fail "IMP-02 yok"
pass "IMP-02 var"

grep -q "IMP-03" "$REGISTER_FILE" || fail "IMP-03 yok"
pass "IMP-03 var"

grep -q "NEXT_STEP=4C_6G_BUSINESS_ACCEPTANCE_GATE" "$REGISTER_FILE" || fail "Next step 4C-6G yok"
pass "Next step 4C-6G var"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-6F UAT Bug / Blocker Register Report

Step: 4C-6F
Blok: UAT Bug / Blocker Register
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6F_UAT_BUG_BLOCKER_REGISTER_STATUS=PASS
4C_6F_PREVIOUS_BLOCK_STATUS=PASS
4C_6F_UAT_RESULT_CLASSIFICATION=TECHNICAL_PASS_BUSINESS_ACCEPTANCE_PENDING
4C_6F_TECHNICAL_UAT_CLASSIFICATION=PASS
4C_6F_TECHNICAL_FAIL_COUNT=0
4C_6F_CRITICAL_BLOCKER_COUNT=0
4C_6F_WARNING_COUNT=2
4C_6F_IMPROVEMENT_COUNT=3
4C_6F_WARN_01=BARKOD_BLANK_NON_BLOCKING
4C_6F_WARN_02=BUSINESS_ACCEPTANCE_PENDING
4C_6F_BARKOD_WARNING_IS_BLOCKER=NO
4C_6F_BUSINESS_ACCEPTANCE_PENDING=YES
4C_6F_UAT_13_STATUS=PASS
4C_6F_DB_WRITE_APPLIED=NO
4C_6G_READY=YES

## Register files

REGISTER_DOC=docs/pilot/faz4c/4c_6f_uat_bug_blocker_register.md
REGISTER_FILE=uat/pilot/faz4c/uzmanparcaci/uat_bug_blocker_register.md

## Sonuc

UAT bug / blocker register tamamlandı.
Critical blocker yok.
İşletme kabulü 4C-6G Business Acceptance Gate adımına taşındı.
Bu adımda DB yazma işlemi yapılmadı.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-6F TEST SONUCU ====="
echo "4C_6F_UAT_BUG_BLOCKER_REGISTER_STATUS=PASS ✅"
echo "4C_6F_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_6F_WARNING_COUNT=2 ⚠️"
echo "4C_6F_IMPROVEMENT_COUNT=3 ✅"
echo "4C_6F_BARKOD_WARNING_IS_BLOCKER=NO ✅"
echo "4C_6F_BUSINESS_ACCEPTANCE_PENDING=YES ⚠️"
echo "4C_6F_UAT_13_STATUS=PASS ✅"
echo "4C_6F_DB_WRITE_APPLIED=NO ✅"
echo "4C_6G_READY=YES ✅"
