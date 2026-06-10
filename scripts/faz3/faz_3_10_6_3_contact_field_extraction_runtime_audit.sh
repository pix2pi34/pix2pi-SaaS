#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_FAILED / FAIL ❌"
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label file_missing=${file}"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern}"
  fi
}

echo "===== 148 — FAZ 3-10.6.3 CONTACT FIELD EXTRACTION RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/documentai/contactextraction/contact_field_extraction_runtime.go"
TEST_FILE="internal/erp/turkiye/documentai/contactextraction/contact_field_extraction_runtime_test.go"
CONFIG_FILE="configs/faz3/documentai/contact_field_extraction_runtime.v1.json"
DOC_FILE="docs/faz3/documentai/FAZ_3_10_6_3_CONTACT_FIELD_EXTRACTION_RUNTIME.md"

check_file "148 contact extraction runtime file" "$RUNTIME_FILE"
check_file "148 contact extraction test file" "$TEST_FILE"
check_file "148 contact extraction config file" "$CONFIG_FILE"
check_file "148 contact extraction documentation file" "$DOC_FILE"

check_grep "148 runtime constructor" "$RUNTIME_FILE" "NewContactFieldExtractionRuntime"
check_grep "148 extract runtime" "$RUNTIME_FILE" "Extract"
check_grep "148 request validation runtime" "$RUNTIME_FILE" "validateRequest"
check_grep "148 collect contact fields runtime" "$RUNTIME_FILE" "collectContactFields"
check_grep "148 missing required runtime" "$RUNTIME_FILE" "missingRequiredFields"
check_grep "148 confidence runtime" "$RUNTIME_FILE" "calculateConfidence"

check_grep "148 OCR processing import" "$RUNTIME_FILE" "documentai/ocrprocessing"
check_grep "148 extraction request model" "$RUNTIME_FILE" "type ContactFieldExtractionRequest"
check_grep "148 extracted contact field model" "$RUNTIME_FILE" "type ExtractedContactField"
check_grep "148 extraction result model" "$RUNTIME_FILE" "type ContactFieldExtractionResult"

check_grep "148 company name field key" "$RUNTIME_FILE" "ContactFieldCompanyName"
check_grep "148 phone field key" "$RUNTIME_FILE" "ContactFieldPhone"
check_grep "148 email field key" "$RUNTIME_FILE" "ContactFieldEmail"
check_grep "148 address field key" "$RUNTIME_FILE" "ContactFieldAddress"

check_grep "148 ready status" "$RUNTIME_FILE" "ContactExtractionStatusReady"
check_grep "148 review status" "$RUNTIME_FILE" "ContactExtractionStatusReviewNeeded"
check_grep "148 rejected status" "$RUNTIME_FILE" "ContactExtractionStatusRejected"
check_grep "148 extracted decision" "$RUNTIME_FILE" "ContactExtractionDecisionExtracted"
check_grep "148 review decision" "$RUNTIME_FILE" "ContactExtractionDecisionReview"
check_grep "148 rejected decision" "$RUNTIME_FILE" "ContactExtractionDecisionRejected"

check_grep "148 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "148 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "148 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "148 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "148 extraction id guard" "$RUNTIME_FILE" "extraction_id is required"
check_grep "148 OCR tenant mismatch guard" "$RUNTIME_FILE" "ocr_result tenant_id mismatch"
check_grep "148 OCR process id guard" "$RUNTIME_FILE" "ocr_result process_id is required"
check_grep "148 OCR document id guard" "$RUNTIME_FILE" "ocr_result document_id is required"
check_grep "148 OCR hash guard" "$RUNTIME_FILE" "ocr_result result_hash is required"
check_grep "148 OCR document type guard" "$RUNTIME_FILE" "ocr_result document_type is not supported"
check_grep "148 OCR status guard" "$RUNTIME_FILE" "ocr_result status must be READY or REVIEW_NEEDED"
check_grep "148 OCR normalized text guard" "$RUNTIME_FILE" "ocr_result normalized_text is required"
check_grep "148 OCR confidence guard" "$RUNTIME_FILE" "ocr_result confidence_bps is required"

check_grep "148 phone normalizer" "$RUNTIME_FILE" "normalizePhone"
check_grep "148 email validator" "$RUNTIME_FILE" "validEmail"
check_grep "148 phone validator" "$RUNTIME_FILE" "validPhone"
check_grep "148 email invalid candidate decision" "$RUNTIME_FILE" "CANDIDATE_REVIEW_INVALID_EMAIL"
check_grep "148 phone invalid candidate decision" "$RUNTIME_FILE" "CANDIDATE_REVIEW_INVALID_PHONE"
check_grep "148 missing fields review reason" "$RUNTIME_FILE" "CONTACT_FIELDS_REVIEW_REQUIRED"
check_grep "148 low confidence review reason" "$RUNTIME_FILE" "CONTACT_FIELDS_LOW_CONFIDENCE"
check_grep "148 result hash builder" "$RUNTIME_FILE" "buildResultHash"

check_grep "148 ready extraction test" "$TEST_FILE" "TestExtractContactFieldsReady"
check_grep "148 phone normalize test" "$TEST_FILE" "TestExtractPhoneNormalization"
check_grep "148 email normalize test" "$TEST_FILE" "TestExtractEmailNormalization"
check_grep "148 missing address review test" "$TEST_FILE" "TestExtractReviewWhenAddressMissing"
check_grep "148 low confidence review test" "$TEST_FILE" "TestExtractReviewWhenLowConfidence"
check_grep "148 invalid email test" "$TEST_FILE" "TestExtractReviewInvalidEmail"
check_grep "148 invalid phone test" "$TEST_FILE" "TestExtractReviewInvalidPhone"
check_grep "148 tenant mismatch test" "$TEST_FILE" "TestExtractRejectsTenantMismatch"
check_grep "148 missing OCR hash test" "$TEST_FILE" "TestExtractRejectsMissingOCRHash"
check_grep "148 unsupported document type test" "$TEST_FILE" "TestExtractRejectsUnsupportedDocumentType"
check_grep "148 bad OCR status test" "$TEST_FILE" "TestExtractRejectsBadOCRStatus"

check_grep "148 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "148 config tenant scope required" "$CONFIG_FILE" "\"require_tenant_scope\": true"
check_grep "148 config OCR hash required" "$CONFIG_FILE" "\"require_ocr_result_hash\": true"
check_grep "148 config OCR ready review required" "$CONFIG_FILE" "\"require_ocr_ready_or_review\": true"
check_grep "148 config phone required" "$CONFIG_FILE" "\"require_phone\": true"
check_grep "148 config email required" "$CONFIG_FILE" "\"require_email\": true"
check_grep "148 config address required" "$CONFIG_FILE" "\"require_address\": true"
check_grep "148 config company name required" "$CONFIG_FILE" "\"require_company_name_candidate\": true"
check_grep "148 config confidence required" "$CONFIG_FILE" "\"require_confidence\": true"
check_grep "148 config audit hash required" "$CONFIG_FILE" "\"require_audit_hash\": true"
check_grep "148 config phone field" "$CONFIG_FILE" "\"phone\""
check_grep "148 config email field" "$CONFIG_FILE" "\"email\""
check_grep "148 config address field" "$CONFIG_FILE" "\"address\""
check_grep "148 config previous gate" "$CONFIG_FILE" "FAZ_3_10_6_2_TAX_FIELD_EXTRACTION_RUNTIME"
check_grep "148 config next gate" "$CONFIG_FILE" "FAZ_3_10_6_4_CONFIDENCE_REVIEW_QUEUE_RUNTIME"

if go test ./internal/erp/turkiye/documentai/contactextraction; then
  pass "148 contact field extraction runtime Go test status"
else
  fail "148 contact field extraction runtime Go test status"
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
# 148 — FAZ 3-10.6.3 — Contact Field Extraction Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_6_3_CONTACT_FIELD_EXTRACTION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_6_3_CONTACT_FIELD_EXTRACTION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_6_4_READY=${NEXT_READY}

## Scope

- Contact field extraction request model
- Extracted contact field model
- Contact field extraction result model
- OCR result bridge
- Company name extraction
- Phone extraction
- Email extraction
- Address extraction
- Phone normalization
- Email normalization
- Missing required fields review signal
- Low confidence review signal
- Tenant scope guard
- OCR result hash guard
- OCR status guard
- Document type guard
- Result hash generation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 148 — FAZ 3-10.6.3 CONTACT FIELD EXTRACTION RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_6_3_CONTACT_FIELD_EXTRACTION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_6_3_CONTACT_FIELD_EXTRACTION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_6_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
