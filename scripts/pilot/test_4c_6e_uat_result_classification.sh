#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PREV_REPORT="reports/pilot/faz4c/4c_6d_uat_execution_evidence_report.md"
PREV_TEST_REPORT="reports/pilot/faz4c/4c_6d_uat_execution_evidence_test_report.md"
EVIDENCE_FILE="uat/pilot/faz4c/uzmanparcaci/evidence/uat_technical_evidence.md"
EXECUTION_TEMPLATE="uat/pilot/faz4c/uzmanparcaci/uat_execution_template.md"

CLASS_DOC="docs/pilot/faz4c/4c_6e_uat_result_classification.md"
UAT_CLASS_FILE="uat/pilot/faz4c/uzmanparcaci/uat_result_classification.md"
REPORT_FILE="reports/pilot/faz4c/4c_6e_uat_result_classification_report.md"

echo "===== 4C-6E UAT RESULT CLASSIFICATION TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-6D report yok: $PREV_REPORT"
pass "4C-6D report var"

[ -f "$PREV_TEST_REPORT" ] || fail "4C-6D test report yok: $PREV_TEST_REPORT"
pass "4C-6D test report var"

[ -f "$EVIDENCE_FILE" ] || fail "UAT technical evidence yok: $EVIDENCE_FILE"
pass "UAT technical evidence var"

[ -f "$EXECUTION_TEMPLATE" ] || fail "UAT execution template yok: $EXECUTION_TEMPLATE"
pass "UAT execution template var"

grep -q "4C_6D_TEST_STATUS=PASS" "$PREV_TEST_REPORT" || fail "4C-6D test PASS degil"
pass "4C-6D test PASS"

grep -q "4C_6D_UAT_EVIDENCE_CAPTURE_STATUS=PASS" "$PREV_REPORT" || fail "4C-6D evidence PASS degil"
pass "4C-6D evidence PASS"

grep -q "4C_6D_TECHNICAL_UAT_STATUS=PASS" "$PREV_REPORT" || fail "Technical UAT PASS degil"
pass "Technical UAT PASS"

grep -q "4C_6D_TECHNICAL_FAIL_COUNT=0" "$PREV_REPORT" || fail "Technical fail count 0 degil"
pass "Technical fail count 0"

grep -q "4C_6D_CRITICAL_BLOCKER_COUNT=0" "$PREV_REPORT" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_6D_DB_WRITE_APPLIED=NO" "$PREV_REPORT" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_6E_READY=YES" "$PREV_REPORT" || fail "4C-6E ready YES yok"
pass "4C-6E ready YES"

for n in $(seq -w 1 11); do
  grep -q "UAT_${n}_STATUS=PASS" "$PREV_REPORT" || fail "UAT_${n}_STATUS PASS degil"
done
pass "UAT-01..UAT-11 PASS"

grep -q "UAT_12_STATUS=PENDING_BUSINESS_ACCEPTANCE" "$PREV_REPORT" || fail "UAT-12 business acceptance pending yok"
pass "UAT-12 business acceptance pending"

grep -q "UAT_13_STATUS=PENDING_CLASSIFICATION" "$PREV_REPORT" || fail "UAT-13 classification pending yok"
pass "UAT-13 classification pending"

grep -q "UAT_14_STATUS=PENDING_GO_NO_GO" "$PREV_REPORT" || fail "UAT-14 go/no-go pending yok"
pass "UAT-14 go/no-go pending"

[ -f "$CLASS_DOC" ] || fail "Classification doc yok"
pass "Classification doc var"

[ -f "$UAT_CLASS_FILE" ] || fail "UAT classification file yok"
pass "UAT classification file var"

grep -q "4C_6E_UAT_RESULT_CLASSIFICATION_STATUS=PASS" "$CLASS_DOC" || fail "Classification status PASS yok"
pass "Classification status PASS var"

grep -q "4C_6E_TECHNICAL_UAT_CLASSIFICATION=PASS" "$CLASS_DOC" || fail "Technical classification PASS yok"
pass "Technical classification PASS var"

grep -q "4C_6E_UAT_RESULT_CLASSIFICATION=TECHNICAL_PASS_BUSINESS_ACCEPTANCE_PENDING" "$CLASS_DOC" || fail "UAT result classification beklenen degil"
pass "UAT result classification beklenen"

grep -q "4C_6E_BUSINESS_ACCEPTANCE_STATUS=PENDING" "$CLASS_DOC" || fail "Business acceptance PENDING yok"
pass "Business acceptance PENDING var"

grep -q "4C_6E_DB_WRITE_APPLIED=NO" "$CLASS_DOC" || fail "DB write applied NO yok"
pass "DB write applied NO var"

grep -q "4C_6F_READY=YES" "$CLASS_DOC" || fail "4C-6F ready YES yok"
pass "4C-6F ready YES var"

BARCODE_BLANK_COUNT="$(grep '^4C_6D_BARCODE_BLANK_COUNT=' "$PREV_REPORT" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
WARNING_COUNT="$(grep '^4C_6D_WARNING_COUNT=' "$PREV_REPORT" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat <<REPORT_EOF > "$REPORT_FILE"
# FAZ 4C — 4C-6E UAT Result Classification Report

Step: 4C-6E
Blok: UAT Result Classification
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6E_UAT_RESULT_CLASSIFICATION_STATUS=PASS
4C_6E_PREVIOUS_BLOCK_STATUS=PASS
4C_6E_TECHNICAL_UAT_CLASSIFICATION=PASS
4C_6E_UAT_RESULT_CLASSIFICATION=TECHNICAL_PASS_BUSINESS_ACCEPTANCE_PENDING
4C_6E_TECHNICAL_FAIL_COUNT=0
4C_6E_UAT_01_TO_11_STATUS=PASS
4C_6E_UAT_12_STATUS=PENDING_BUSINESS_ACCEPTANCE
4C_6E_UAT_13_STATUS=PENDING_CLASSIFICATION
4C_6E_UAT_14_STATUS=PENDING_GO_NO_GO
4C_6E_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT
4C_6E_BUSINESS_ACCEPTANCE_STATUS=PENDING
4C_6E_CRITICAL_BLOCKER_COUNT=0
4C_6E_WARNING_COUNT=$WARNING_COUNT
4C_6E_DB_WRITE_APPLIED=NO
4C_6F_READY=YES

## Karar

Teknik UAT PASS.
İşletme kabulü bekliyor.
Final UAT PASS, 4C-6G Business Acceptance Gate sonrasında verilecek.

## Sonuc

UAT result classification tamamlandı.
Bu adımda DB yazma işlemi yapılmadı.
Sonraki adım: 4C-6F UAT Bug / Blocker Register.
REPORT_EOF

pass "Final report uretildi: $REPORT_FILE"

echo
echo "===== 4C-6E TEST SONUCU ====="
echo "4C_6E_UAT_RESULT_CLASSIFICATION_STATUS=PASS ✅"
echo "4C_6E_TECHNICAL_UAT_CLASSIFICATION=PASS ✅"
echo "4C_6E_UAT_RESULT_CLASSIFICATION=TECHNICAL_PASS_BUSINESS_ACCEPTANCE_PENDING ✅"
echo "4C_6E_TECHNICAL_FAIL_COUNT=0 ✅"
echo "4C_6E_UAT_01_TO_11_STATUS=PASS ✅"
echo "4C_6E_UAT_12_STATUS=PENDING_BUSINESS_ACCEPTANCE ⚠️"
echo "4C_6E_BUSINESS_ACCEPTANCE_STATUS=PENDING ⚠️"
echo "4C_6E_CRITICAL_BLOCKER_COUNT=0 ✅"
echo "4C_6E_DB_WRITE_APPLIED=NO ✅"
echo "4C_6F_READY=YES ✅"
