#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); REQUIRED_FAIL=$((REQUIRED_FAIL + 1)); echo "$1 MISSING_OR_FAILED / FAIL ❌"; }

check_file() {
  local label="$1"; local file="$2"
  if [ -f "$file" ]; then pass "$label"; else fail "$label file_missing=${file}"; fi
}

check_grep() {
  local label="$1"; local file="$2"; local pattern="$3"
  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then pass "$label"; else fail "$label pattern_missing=${pattern}"; fi
}

echo "===== 176 — FAZ 3-13.6 DOCUMENT INTEGRATION UI TESTS REAL IMPLEMENTATION AUDIT START ====="

REPORT_FILE="web/faz3/document-integration/ui-tests/index.html"
CONFIG_FILE="configs/faz3/document-integration/document_integration_ui_tests.v1.json"
DOC_FILE="docs/faz3/document-integration/FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS.md"
TEST_SCRIPT="scripts/faz3/faz_3_13_6_document_integration_ui_tests_suite.sh"

check_file "176 document integration UI tests report HTML file" "$REPORT_FILE"
check_file "176 document integration UI tests config file" "$CONFIG_FILE"
check_file "176 document integration UI tests documentation file" "$DOC_FILE"
check_file "176 document integration UI tests suite script file" "$TEST_SCRIPT"

check_grep "176 report phase marker" "$REPORT_FILE" "FAZ_3_13_6"
check_grep "176 report screen marker" "$REPORT_FILE" "DOCUMENT_INTEGRATION_UI_TESTS_REPORT"
check_grep "176 report title surface" "$REPORT_FILE" "Belge / Entegrasyon UI Testleri"
check_grep "176 report 174 coverage" "$REPORT_FILE" "174|e-Belge Durum Merkezi|/faz3/document-integration/ebelge-status-center/"
check_grep "176 report 175 coverage" "$REPORT_FILE" "175|OCR / Belge Okuma Review|/faz3/document-integration/ocr-review/"
check_grep "176 report 177 next coverage" "$REPORT_FILE" "177.*Retry / Cancel / Resend"
check_grep "176 report 178 planned coverage" "$REPORT_FILE" "178|Provider Hata|FAZ_3_13_3_PROVIDER_ERROR_VIEW"
check_grep "176 report 179 planned coverage" "$REPORT_FILE" "179|Manuel Düzeltme|FAZ_3_13_5_MANUAL_CORRECTION_QUEUE"
check_grep "176 report tenant guard" "$REPORT_FILE" "Tenant Guard"
check_grep "176 report firm guard" "$REPORT_FILE" "Firm Guard"
check_grep "176 report production false" "$REPORT_FILE" "Production: FALSE"
check_grep "176 report readonly policy" "$REPORT_FILE" "READ-ONLY|Canlı aksiyon yok"
check_grep "176 report live closed policy" "$REPORT_FILE" "Real GİB: CLOSED|Real provider: CLOSED|Auto commit: CLOSED|Audit delete/mutation: CLOSED"

check_grep "176 config suite enabled" "$CONFIG_FILE" "\"suite_enabled\": true"
check_grep "176 config route" "$CONFIG_FILE" "\"route\": \"/faz3/document-integration/ui-tests/\""
check_grep "176 config report file" "$CONFIG_FILE" "\"report_file\": \"web/faz3/document-integration/ui-tests/index.html\""
check_grep "176 config test script" "$CONFIG_FILE" "faz_3_13_6_document_integration_ui_tests_suite.sh"
check_grep "176 config audit script" "$CONFIG_FILE" "faz_3_13_6_document_integration_ui_tests_audit.sh"
check_grep "176 config 174 coverage" "$CONFIG_FILE" "\"screen_174_ebelge_status_center\""
check_grep "176 config 175 coverage" "$CONFIG_FILE" "\"screen_175_ocr_document_review\""
check_grep "176 config 177 next planned" "$CONFIG_FILE" "FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE"
check_grep "176 config 178 planned" "$CONFIG_FILE" "FAZ_3_13_3_PROVIDER_ERROR_VIEW"
check_grep "176 config 179 planned" "$CONFIG_FILE" "FAZ_3_13_5_MANUAL_CORRECTION_QUEUE"
check_grep "176 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "176 config readonly tests true" "$CONFIG_FILE" "\"document_integration_ui_tests_are_static_and_readonly\": true"
check_grep "176 config real GIB false" "$CONFIG_FILE" "\"real_gib_call_allowed\": false"
check_grep "176 config real provider false" "$CONFIG_FILE" "\"real_provider_call_allowed\": false"
check_grep "176 config external delivery false" "$CONFIG_FILE" "\"real_external_delivery_allowed\": false"
check_grep "176 config auto commit false" "$CONFIG_FILE" "\"auto_commit_allowed\": false"
check_grep "176 config customer card write false" "$CONFIG_FILE" "\"customer_card_write_allowed\": false"
check_grep "176 config raw image storage false" "$CONFIG_FILE" "\"raw_image_storage_allowed\": false"
check_grep "176 config audit delete false" "$CONFIG_FILE" "\"audit_delete_allowed\": false"
check_grep "176 config audit mutation false" "$CONFIG_FILE" "\"audit_mutation_allowed\": false"
check_grep "176 config previous gate" "$CONFIG_FILE" "FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN"
check_grep "176 config next gate" "$CONFIG_FILE" "FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE"

echo "===== 176 — RUN DOCUMENT INTEGRATION UI TEST SUITE FROM AUDIT ====="
if "$TEST_SCRIPT"; then
  pass "176 document integration UI test suite execution"
else
  fail "176 document integration UI test suite execution"
fi

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_gib_call_allowed\"[[:space:]]*:[[:space:]]*true|\"real_provider_call_allowed\"[[:space:]]*:[[:space:]]*true|\"real_external_delivery_allowed\"[[:space:]]*:[[:space:]]*true|\"auto_commit_allowed\"[[:space:]]*:[[:space:]]*true|\"customer_card_write_allowed\"[[:space:]]*:[[:space:]]*true|\"raw_image_storage_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_delete_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_mutation_allowed\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "176 live policy document integration UI tests guard"
else
  pass "176 live policy document integration UI tests guard"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 176 — FAZ 3-13.6 — Document Integration UI Tests Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_13_2_READY=${NEXT_READY}

## Scope

- 174 e-Belge status center
- 175 OCR document review screen
- Route/config/evidence coverage
- Tenant/firm/correlation/review guard coverage
- Audit hash / evidence trace coverage
- Real GİB/provider/external delivery closed policy
- Auto commit/customer card write/raw image storage closed policy
- Planned next screens: 177, 178, 179

## Live Policy

- Production approved: FALSE
- Real GİB call: CLOSED
- Real provider call: CLOSED
- Real external delivery: CLOSED
- Auto commit: CLOSED
- Customer card write: CLOSED
- Raw image storage: CLOSED
- Audit delete: CLOSED
- Audit mutation: CLOSED
- UI actions are navigation/evidence only.

## Audit Notes

Final status is derived from real screen/config/doc files, real suite execution, and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 176 — FAZ 3-13.6 DOCUMENT INTEGRATION UI TESTS COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_13_2_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
