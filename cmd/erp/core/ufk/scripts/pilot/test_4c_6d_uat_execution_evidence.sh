#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_SCRIPT="scripts/pilot/run_4c_6d_uat_execution_evidence.sh"
PREV_REPORT="reports/pilot/faz4c/4c_6c_uat_test_case_package_report.md"

REPORT_FILE="reports/pilot/faz4c/4c_6d_uat_execution_evidence_report.md"
TEST_REPORT="reports/pilot/faz4c/4c_6d_uat_execution_evidence_test_report.md"
EVIDENCE_FILE="uat/pilot/faz4c/uzmanparcaci/evidence/uat_technical_evidence.md"
EXECUTION_TEMPLATE="uat/pilot/faz4c/uzmanparcaci/uat_execution_template.md"

echo "===== 4C-6D UAT EXECUTION / EVIDENCE CAPTURE TEST ====="

fail() {
  echo "HATA ❌ $1"
  exit 1
}

pass() {
  echo "OK ✅ $1"
}

[ -f "$PREV_REPORT" ] || fail "4C-6C report yok: $PREV_REPORT"
pass "4C-6C report var"

grep -q "4C_6C_UAT_TEST_CASE_PACKAGE_STATUS=PASS" "$PREV_REPORT" || fail "4C-6C PASS degil"
pass "4C-6C PASS"

grep -q "4C_6D_READY=YES" "$PREV_REPORT" || fail "4C-6D ready YES yok"
pass "4C-6D ready YES"

[ -f "$RUN_SCRIPT" ] || fail "Run script yok: $RUN_SCRIPT"
pass "Run script var"

[ -x "$RUN_SCRIPT" ] || fail "Run script executable degil"
pass "Run script executable"

bash "$RUN_SCRIPT"

[ -f "$REPORT_FILE" ] || fail "4C-6D report yok"
pass "4C-6D report var"

[ -f "$EVIDENCE_FILE" ] || fail "Evidence file yok"
pass "Evidence file var"

[ -f "$EXECUTION_TEMPLATE" ] || fail "Execution template yok"
pass "Execution template var"

grep -q "4C_6D_UAT_EVIDENCE_CAPTURE_STATUS=PASS" "$REPORT_FILE" || fail "Evidence capture PASS degil"
pass "Evidence capture PASS"

grep -q "4C_6D_TECHNICAL_UAT_STATUS=PASS" "$REPORT_FILE" || fail "Technical UAT PASS degil"
pass "Technical UAT PASS"

grep -q "4C_6D_TECHNICAL_FAIL_COUNT=0" "$REPORT_FILE" || fail "Technical fail count 0 degil"
pass "Technical fail count 0"

grep -q "4C_6D_API_GATEWAY_HEALTH_HTTP=200" "$REPORT_FILE" || fail "Gateway health 200 degil"
pass "Gateway health 200"

grep -q "4C_6D_IDENTITY_HEALTH_HTTP=200" "$REPORT_FILE" || fail "Identity health 200 degil"
pass "Identity health 200"

grep -q "4C_6D_DB_CONNECT_STATUS=PASS" "$REPORT_FILE" || fail "DB connect PASS degil"
pass "DB connect PASS"

grep -q "4C_6D_STAGING_ROW_COUNT=5" "$REPORT_FILE" || fail "Staging row count 5 degil"
pass "Staging row count 5"

grep -q "4C_6D_DUPLICATE_SKU_COUNT=0" "$REPORT_FILE" || fail "Duplicate SKU count 0 degil"
pass "Duplicate SKU count 0"

grep -q "4C_6D_TENANT_MISMATCH_COUNT=0" "$REPORT_FILE" || fail "Tenant mismatch count 0 degil"
pass "Tenant mismatch count 0"

grep -q "4C_6D_OEM_FIELD_COUNT=5" "$REPORT_FILE" || fail "OEM field count 5 degil"
pass "OEM field count 5"

grep -q "4C_6D_EQUIVALENT_FIELD_COUNT=5" "$REPORT_FILE" || fail "Equivalent field count 5 degil"
pass "Equivalent field count 5"

grep -q "4C_6D_FITMENT_FIELD_COUNT=5" "$REPORT_FILE" || fail "Fitment field count 5 degil"
pass "Fitment field count 5"

for n in $(seq -w 1 11); do
  grep -q "UAT_${n}_STATUS=PASS" "$REPORT_FILE" || fail "UAT_${n}_STATUS PASS degil"
done
pass "UAT-01..UAT-11 PASS"

grep -q "UAT_12_STATUS=PENDING_BUSINESS_ACCEPTANCE" "$REPORT_FILE" || fail "UAT-12 business acceptance pending yok"
pass "UAT-12 business acceptance pending"

grep -q "4C_6D_DB_WRITE_APPLIED=NO" "$REPORT_FILE" || fail "DB write applied NO degil"
pass "DB write applied NO"

grep -q "4C_6D_CRITICAL_BLOCKER_COUNT=0" "$REPORT_FILE" || fail "Critical blocker 0 degil"
pass "Critical blocker 0"

grep -q "4C_6E_READY=YES" "$REPORT_FILE" || fail "4C-6E ready YES yok"
pass "4C-6E ready YES"

WARNING_COUNT="$(grep '^4C_6D_WARNING_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"
BARCODE_BLANK_COUNT="$(grep '^4C_6D_BARCODE_BLANK_COUNT=' "$REPORT_FILE" | tail -n 1 | cut -d'=' -f2 | tr -d ' ')"

cat > "$TEST_REPORT" <<REPORT_EOF
# FAZ 4C — 4C-6D UAT Execution Evidence Test Report

Step: 4C-6D
Blok: UAT Execution / Evidence Capture Test
Test tarihi: $(date '+%Y-%m-%d %H:%M:%S')

## Test sonucu

4C_6D_TEST_STATUS=PASS
4C_6D_UAT_EVIDENCE_CAPTURE_STATUS=PASS
4C_6D_TECHNICAL_UAT_STATUS=PASS
4C_6D_TECHNICAL_FAIL_COUNT=0
4C_6D_UAT_01_TO_11_STATUS=PASS
4C_6D_UAT_12_STATUS=PENDING_BUSINESS_ACCEPTANCE
4C_6D_BARCODE_BLANK_COUNT=$BARCODE_BLANK_COUNT
4C_6D_WARNING_COUNT=$WARNING_COUNT
4C_6D_DB_WRITE_APPLIED=NO
4C_6E_READY=YES

## Sonuc

UAT technical evidence capture test tamamlandı.
DB yazma işlemi yapılmadı.
Sonraki adım: 4C-6E UAT Result Classification.
REPORT_EOF

pass "Test report uretildi: $TEST_REPORT"

echo
echo "===== 4C-6D TEST SONUCU ====="
echo "4C_6D_TEST_STATUS=PASS ✅"
echo "4C_6D_UAT_EVIDENCE_CAPTURE_STATUS=PASS ✅"
echo "4C_6D_TECHNICAL_UAT_STATUS=PASS ✅"
echo "4C_6D_TECHNICAL_FAIL_COUNT=0 ✅"
echo "4C_6D_UAT_01_TO_11_STATUS=PASS ✅"
echo "4C_6D_UAT_12_STATUS=PENDING_BUSINESS_ACCEPTANCE ⚠️"
echo "4C_6D_DB_WRITE_APPLIED=NO ✅"
echo "4C_6E_READY=YES ✅"
