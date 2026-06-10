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

echo "===== 146 — FAZ 3-10.6.1 OCR LENS PROCESSING RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/documentai/ocrprocessing/ocr_lens_processing_runtime.go"
TEST_FILE="internal/erp/turkiye/documentai/ocrprocessing/ocr_lens_processing_runtime_test.go"
CONFIG_FILE="configs/faz3/documentai/ocr_lens_processing_runtime.v1.json"
DOC_FILE="docs/faz3/documentai/FAZ_3_10_6_1_OCR_LENS_PROCESSING_RUNTIME.md"

check_file "146 OCR lens runtime file" "$RUNTIME_FILE"
check_file "146 OCR lens test file" "$TEST_FILE"
check_file "146 OCR lens config file" "$CONFIG_FILE"
check_file "146 OCR lens documentation file" "$DOC_FILE"

check_grep "146 runtime constructor" "$RUNTIME_FILE" "NewOCRLensProcessingRuntime"
check_grep "146 process runtime" "$RUNTIME_FILE" "Process"
check_grep "146 source validation runtime" "$RUNTIME_FILE" "validateSource"
check_grep "146 document type detection runtime" "$RUNTIME_FILE" "detectDocumentType"
check_grep "146 block builder runtime" "$RUNTIME_FILE" "buildBlocks"
check_grep "146 candidate extraction runtime" "$RUNTIME_FILE" "extractCandidates"
check_grep "146 confidence calculation runtime" "$RUNTIME_FILE" "calculateConfidence"

check_grep "146 source model" "$RUNTIME_FILE" "type OCRSource"
check_grep "146 block model" "$RUNTIME_FILE" "type OCRBlock"
check_grep "146 field candidate model" "$RUNTIME_FILE" "type OCRFieldCandidate"
check_grep "146 process request model" "$RUNTIME_FILE" "type ProcessRequest"
check_grep "146 process result model" "$RUNTIME_FILE" "type ProcessResult"

check_grep "146 image source type" "$RUNTIME_FILE" "SourceTypeImage"
check_grep "146 PDF source type" "$RUNTIME_FILE" "SourceTypePDF"
check_grep "146 scan source type" "$RUNTIME_FILE" "SourceTypeScan"
check_grep "146 tax certificate document type" "$RUNTIME_FILE" "DocumentTypeTaxCertificate"
check_grep "146 business card document type" "$RUNTIME_FILE" "DocumentTypeBusinessCard"
check_grep "146 invoice document type" "$RUNTIME_FILE" "DocumentTypeInvoice"
check_grep "146 receipt document type" "$RUNTIME_FILE" "DocumentTypeReceipt"

check_grep "146 ready status" "$RUNTIME_FILE" "OCRStatusReady"
check_grep "146 review needed status" "$RUNTIME_FILE" "OCRStatusReviewNeeded"
check_grep "146 rejected status" "$RUNTIME_FILE" "OCRStatusRejected"
check_grep "146 processed decision" "$RUNTIME_FILE" "OCRDecisionProcessed"
check_grep "146 review decision" "$RUNTIME_FILE" "OCRDecisionReview"
check_grep "146 rejected decision" "$RUNTIME_FILE" "OCRDecisionRejected"

check_grep "146 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "146 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "146 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "146 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "146 process id guard" "$RUNTIME_FILE" "process_id is required"
check_grep "146 source tenant mismatch guard" "$RUNTIME_FILE" "source tenant_id mismatch"
check_grep "146 document id guard" "$RUNTIME_FILE" "source document_id is required"
check_grep "146 source type guard" "$RUNTIME_FILE" "source_type is not allowed"
check_grep "146 mime type guard" "$RUNTIME_FILE" "mime_type is not allowed"
check_grep "146 file name guard" "$RUNTIME_FILE" "file_name is required"
check_grep "146 file hash guard" "$RUNTIME_FILE" "file_hash is required"
check_grep "146 source text guard" "$RUNTIME_FILE" "source_text is required"
check_grep "146 max text guard" "$RUNTIME_FILE" "source_text exceeds max_text_length"
check_grep "146 language guard" "$RUNTIME_FILE" "language is required"
check_grep "146 page count guard" "$RUNTIME_FILE" "page_count must be positive"
check_grep "146 image count guard" "$RUNTIME_FILE" "image_count must be positive"
check_grep "146 uploaded by guard" "$RUNTIME_FILE" "uploaded_by is required"
check_grep "146 uploaded at guard" "$RUNTIME_FILE" "uploaded_at is required"

check_grep "146 tax no candidate" "$RUNTIME_FILE" "tax_no"
check_grep "146 tax office candidate" "$RUNTIME_FILE" "tax_office"
check_grep "146 mersis candidate" "$RUNTIME_FILE" "mersis_no"
check_grep "146 phone candidate" "$RUNTIME_FILE" "phone"
check_grep "146 email candidate" "$RUNTIME_FILE" "email"
check_grep "146 address candidate" "$RUNTIME_FILE" "address"
check_grep "146 company name candidate" "$RUNTIME_FILE" "company_name"
check_grep "146 result hash builder" "$RUNTIME_FILE" "buildResultHash"

check_grep "146 ready test" "$TEST_FILE" "TestProcessTaxCertificateReady"
check_grep "146 blocks test" "$TEST_FILE" "TestProcessBuildsBlocks"
check_grep "146 candidates test" "$TEST_FILE" "TestProcessExtractsFieldCandidates"
check_grep "146 detect unknown test" "$TEST_FILE" "TestProcessDetectsUnknownDocumentType"
check_grep "146 review needed test" "$TEST_FILE" "TestProcessReviewNeededForLowText"
check_grep "146 tenant mismatch test" "$TEST_FILE" "TestProcessRejectsTenantMismatch"
check_grep "146 file hash test" "$TEST_FILE" "TestProcessRejectsMissingFileHash"
check_grep "146 mime type test" "$TEST_FILE" "TestProcessRejectsUnsupportedMimeType"
check_grep "146 source text test" "$TEST_FILE" "TestProcessRejectsEmptySourceText"
check_grep "146 max text test" "$TEST_FILE" "TestProcessRejectsTooLongSourceText"

check_grep "146 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "146 config default language" "$CONFIG_FILE" "\"default_language\": \"tr\""
check_grep "146 config tenant scope required" "$CONFIG_FILE" "\"require_tenant_scope\": true"
check_grep "146 config file hash required" "$CONFIG_FILE" "\"require_file_hash\": true"
check_grep "146 config source text required" "$CONFIG_FILE" "\"require_source_text\": true"
check_grep "146 config confidence required" "$CONFIG_FILE" "\"require_confidence\": true"
check_grep "146 config audit hash required" "$CONFIG_FILE" "\"require_audit_hash\": true"
check_grep "146 config image source" "$CONFIG_FILE" "\"IMAGE\""
check_grep "146 config PDF source" "$CONFIG_FILE" "\"PDF\""
check_grep "146 config scan source" "$CONFIG_FILE" "\"SCAN\""
check_grep "146 config tax field next gate" "$CONFIG_FILE" "FAZ_3_10_6_2_TAX_FIELD_EXTRACTION_RUNTIME"

if go test ./internal/erp/turkiye/documentai/ocrprocessing; then
  pass "146 OCR lens processing runtime Go test status"
else
  fail "146 OCR lens processing runtime Go test status"
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
# 146 — FAZ 3-10.6.1 — OCR Lens Processing Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_6_1_OCR_LENS_PROCESSING_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_6_1_OCR_LENS_PROCESSING_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_6_2_READY=${NEXT_READY}

## Scope

- OCR source model
- OCR block model
- OCR field candidate model
- Process request/result model
- Source type validation
- MIME type validation
- Tenant scope guard
- File hash guard
- Source text guard
- OCR text normalization
- Document type detection
- Field candidate extraction
- Confidence calculation
- Review required decision
- Result hash generation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 146 — FAZ 3-10.6.1 OCR LENS PROCESSING RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_6_1_OCR_LENS_PROCESSING_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_6_1_OCR_LENS_PROCESSING_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_6_2_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
