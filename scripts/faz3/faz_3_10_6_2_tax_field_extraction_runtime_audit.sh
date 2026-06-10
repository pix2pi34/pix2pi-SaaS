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

echo "===== 147 — FAZ 3-10.6.2 TAX FIELD EXTRACTION RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/documentai/taxextraction/tax_field_extraction_runtime.go"
TEST_FILE="internal/erp/turkiye/documentai/taxextraction/tax_field_extraction_runtime_test.go"
CONFIG_FILE="configs/faz3/documentai/tax_field_extraction_runtime.v1.json"
DOC_FILE="docs/faz3/documentai/FAZ_3_10_6_2_TAX_FIELD_EXTRACTION_RUNTIME.md"

check_file "147 tax extraction runtime file" "$RUNTIME_FILE"
check_file "147 tax extraction test file" "$TEST_FILE"
check_file "147 tax extraction config file" "$CONFIG_FILE"
check_file "147 tax extraction documentation file" "$DOC_FILE"

check_grep "147 runtime constructor" "$RUNTIME_FILE" "NewTaxFieldExtractionRuntime"
check_grep "147 extract runtime" "$RUNTIME_FILE" "Extract"
check_grep "147 request validation runtime" "$RUNTIME_FILE" "validateRequest"
check_grep "147 collect tax fields runtime" "$RUNTIME_FILE" "collectTaxFields"
check_grep "147 missing required runtime" "$RUNTIME_FILE" "missingRequiredFields"
check_grep "147 confidence runtime" "$RUNTIME_FILE" "calculateConfidence"

check_grep "147 OCR processing import" "$RUNTIME_FILE" "documentai/ocrprocessing"
check_grep "147 extraction request model" "$RUNTIME_FILE" "type TaxFieldExtractionRequest"
check_grep "147 extracted tax field model" "$RUNTIME_FILE" "type ExtractedTaxField"
check_grep "147 extraction result model" "$RUNTIME_FILE" "type TaxFieldExtractionResult"

check_grep "147 company name field key" "$RUNTIME_FILE" "TaxFieldCompanyName"
check_grep "147 tax no field key" "$RUNTIME_FILE" "TaxFieldTaxNo"
check_grep "147 tax office field key" "$RUNTIME_FILE" "TaxFieldTaxOffice"
check_grep "147 mersis field key" "$RUNTIME_FILE" "TaxFieldMersisNo"

check_grep "147 ready status" "$RUNTIME_FILE" "TaxExtractionStatusReady"
check_grep "147 review status" "$RUNTIME_FILE" "TaxExtractionStatusReviewNeeded"
check_grep "147 rejected status" "$RUNTIME_FILE" "TaxExtractionStatusRejected"
check_grep "147 extracted decision" "$RUNTIME_FILE" "TaxExtractionDecisionExtracted"
check_grep "147 review decision" "$RUNTIME_FILE" "TaxExtractionDecisionReview"
check_grep "147 rejected decision" "$RUNTIME_FILE" "TaxExtractionDecisionRejected"

check_grep "147 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "147 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "147 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "147 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "147 extraction id guard" "$RUNTIME_FILE" "extraction_id is required"
check_grep "147 OCR tenant mismatch guard" "$RUNTIME_FILE" "ocr_result tenant_id mismatch"
check_grep "147 OCR process id guard" "$RUNTIME_FILE" "ocr_result process_id is required"
check_grep "147 OCR document id guard" "$RUNTIME_FILE" "ocr_result document_id is required"
check_grep "147 OCR hash guard" "$RUNTIME_FILE" "ocr_result result_hash is required"
check_grep "147 OCR document type guard" "$RUNTIME_FILE" "ocr_result document_type is not supported"
check_grep "147 OCR status guard" "$RUNTIME_FILE" "ocr_result status must be READY or REVIEW_NEEDED"
check_grep "147 OCR normalized text guard" "$RUNTIME_FILE" "ocr_result normalized_text is required"
check_grep "147 OCR confidence guard" "$RUNTIME_FILE" "ocr_result confidence_bps is required"

check_grep "147 tax no normalizer" "$RUNTIME_FILE" "onlyDigits"
check_grep "147 tax no validator" "$RUNTIME_FILE" "validTaxNo"
check_grep "147 10 or 11 digit policy" "$RUNTIME_FILE" "len(digits) == 10 || len(digits) == 11"
check_grep "147 missing fields review reason" "$RUNTIME_FILE" "TAX_FIELDS_REVIEW_REQUIRED"
check_grep "147 low confidence review reason" "$RUNTIME_FILE" "TAX_FIELDS_LOW_CONFIDENCE"
check_grep "147 invalid tax no candidate decision" "$RUNTIME_FILE" "CANDIDATE_REVIEW_INVALID_TAX_NO"
check_grep "147 result hash builder" "$RUNTIME_FILE" "buildResultHash"

check_grep "147 ready extraction test" "$TEST_FILE" "TestExtractTaxFieldsReady"
check_grep "147 tax no normalize test" "$TEST_FILE" "TestExtractNormalizesTaxNo"
check_grep "147 mersis test" "$TEST_FILE" "TestExtractMersisNo"
check_grep "147 missing tax office review test" "$TEST_FILE" "TestExtractReviewWhenTaxOfficeMissing"
check_grep "147 low confidence review test" "$TEST_FILE" "TestExtractReviewWhenLowConfidence"
check_grep "147 invalid tax no test" "$TEST_FILE" "TestExtractReviewInvalidTaxNo"
check_grep "147 tenant mismatch test" "$TEST_FILE" "TestExtractRejectsTenantMismatch"
check_grep "147 missing OCR hash test" "$TEST_FILE" "TestExtractRejectsMissingOCRHash"
check_grep "147 unsupported document type test" "$TEST_FILE" "TestExtractRejectsUnsupportedDocumentType"
check_grep "147 bad OCR status test" "$TEST_FILE" "TestExtractRejectsBadOCRStatus"

check_grep "147 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "147 config tenant scope required" "$CONFIG_FILE" "\"require_tenant_scope\": true"
check_grep "147 config OCR hash required" "$CONFIG_FILE" "\"require_ocr_result_hash\": true"
check_grep "147 config OCR ready review required" "$CONFIG_FILE" "\"require_ocr_ready_or_review\": true"
check_grep "147 config tax no required" "$CONFIG_FILE" "\"require_tax_no\": true"
check_grep "147 config tax office required" "$CONFIG_FILE" "\"require_tax_office\": true"
check_grep "147 config company name required" "$CONFIG_FILE" "\"require_company_name_candidate\": true"
check_grep "147 config confidence required" "$CONFIG_FILE" "\"require_confidence\": true"
check_grep "147 config audit hash required" "$CONFIG_FILE" "\"require_audit_hash\": true"
check_grep "147 config tax no field" "$CONFIG_FILE" "\"tax_no\""
check_grep "147 config tax office field" "$CONFIG_FILE" "\"tax_office\""
check_grep "147 config mersis field" "$CONFIG_FILE" "\"mersis_no\""
check_grep "147 config previous gate" "$CONFIG_FILE" "FAZ_3_10_6_1_OCR_LENS_PROCESSING_RUNTIME"
check_grep "147 config next gate" "$CONFIG_FILE" "FAZ_3_10_6_3_CONTACT_FIELD_EXTRACTION_RUNTIME"

if go test ./internal/erp/turkiye/documentai/taxextraction; then
  pass "147 tax field extraction runtime Go test status"
else
  fail "147 tax field extraction runtime Go test status"
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
# 147 — FAZ 3-10.6.2 — Tax Field Extraction Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_6_2_TAX_FIELD_EXTRACTION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_6_2_TAX_FIELD_EXTRACTION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_6_3_READY=${NEXT_READY}

## Scope

- Tax field extraction request model
- Extracted tax field model
- Tax field extraction result model
- OCR result bridge
- Company name extraction
- VKN/TCKN extraction
- Tax office extraction
- MERSIS extraction
- VKN/TCKN digit normalization
- 10/11 digit tax number validation
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

echo "===== 147 — FAZ 3-10.6.2 TAX FIELD EXTRACTION RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_6_2_TAX_FIELD_EXTRACTION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_6_2_TAX_FIELD_EXTRACTION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_6_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
