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

echo "===== 150 — FAZ 3-10.6.5 DOCUMENT AI RUNTIME TESTS REAL IMPLEMENTATION AUDIT START ====="

SUITE_FILE="internal/erp/turkiye/documentai/runtimetests/document_ai_runtime_test_suite.go"
TEST_FILE="internal/erp/turkiye/documentai/runtimetests/document_ai_runtime_test_suite_test.go"
CONFIG_FILE="configs/faz3/documentai/document_ai_runtime_tests.v1.json"
DOC_FILE="docs/faz3/documentai/FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS.md"

check_file "150 document AI runtime suite file" "$SUITE_FILE"
check_file "150 document AI runtime test file" "$TEST_FILE"
check_file "150 document AI runtime config file" "$CONFIG_FILE"
check_file "150 document AI runtime documentation file" "$DOC_FILE"

check_grep "150 suite constructor" "$SUITE_FILE" "NewDocumentAIRuntimeTestSuite"
check_grep "150 happy path runtime" "$SUITE_FILE" "RunHappyPath"
check_grep "150 review required path runtime" "$SUITE_FILE" "RunReviewRequiredPath"
check_grep "150 OCR runner" "$SUITE_FILE" "runOCR"
check_grep "150 tax extraction runner" "$SUITE_FILE" "runTaxExtraction"
check_grep "150 contact extraction runner" "$SUITE_FILE" "runContactExtraction"
check_grep "150 request validation runtime" "$SUITE_FILE" "validateRequest"

check_grep "150 OCR processing import" "$SUITE_FILE" "documentai/ocrprocessing"
check_grep "150 tax extraction import" "$SUITE_FILE" "documentai/taxextraction"
check_grep "150 contact extraction import" "$SUITE_FILE" "documentai/contactextraction"
check_grep "150 review queue import" "$SUITE_FILE" "documentai/reviewqueue"

check_grep "150 test request model" "$SUITE_FILE" "type DocumentAIRuntimeTestRequest"
check_grep "150 test result model" "$SUITE_FILE" "type DocumentAIRuntimeTestResult"
check_grep "150 suite status pass" "$SUITE_FILE" "SuiteStatusPass"
check_grep "150 suite status fail" "$SUITE_FILE" "SuiteStatusFail"

check_grep "150 OCR process operation" "$SUITE_FILE" "ocrRuntime.Process"
check_grep "150 tax extract operation" "$SUITE_FILE" "taxRuntime.Extract"
check_grep "150 contact extract operation" "$SUITE_FILE" "contactRuntime.Extract"
check_grep "150 OCR review register operation" "$SUITE_FILE" "RegisterOCRReview"
check_grep "150 tax review register operation" "$SUITE_FILE" "RegisterTaxReview"
check_grep "150 contact review register operation" "$SUITE_FILE" "RegisterContactReview"
check_grep "150 review list operation" "$SUITE_FILE" "ListOpen"

check_grep "150 tenant guard" "$SUITE_FILE" "tenant_id is required"
check_grep "150 correlation guard" "$SUITE_FILE" "correlation_id is required"
check_grep "150 request guard" "$SUITE_FILE" "request_id is required"
check_grep "150 idempotency guard" "$SUITE_FILE" "idempotency_key is required"
check_grep "150 suite id guard" "$SUITE_FILE" "suite_id is required"
check_grep "150 OCR process id guard" "$SUITE_FILE" "ocr_process_id is required"
check_grep "150 document id guard" "$SUITE_FILE" "document_id is required"
check_grep "150 source file hash guard" "$SUITE_FILE" "source file_hash is required"
check_grep "150 source text guard" "$SUITE_FILE" "source_text is required"
check_grep "150 suite hash builder" "$SUITE_FILE" "buildSuiteHash"

check_grep "150 OCR config bridge" "$SUITE_FILE" "defaultOCRConfig"
check_grep "150 tax config bridge" "$SUITE_FILE" "defaultTaxConfig"
check_grep "150 contact config bridge" "$SUITE_FILE" "defaultContactConfig"
check_grep "150 review queue config bridge" "$SUITE_FILE" "defaultReviewQueueConfig"

check_grep "150 happy path test" "$TEST_FILE" "TestDocumentAIHappyPathPasses"
check_grep "150 OCR result test" "$TEST_FILE" "TestDocumentAIHappyPathBuildsOCRResult"
check_grep "150 tax fields test" "$TEST_FILE" "TestDocumentAIHappyPathExtractsTaxFields"
check_grep "150 contact fields test" "$TEST_FILE" "TestDocumentAIHappyPathExtractsContactFields"
check_grep "150 review required path test" "$TEST_FILE" "TestDocumentAIReviewRequiredPathPasses"
check_grep "150 OCR review test" "$TEST_FILE" "TestDocumentAIReviewPathRegistersOCRReview"
check_grep "150 tax review test" "$TEST_FILE" "TestDocumentAIReviewPathRegistersTaxReview"
check_grep "150 contact review test" "$TEST_FILE" "TestDocumentAIReviewPathRegistersContactReview"
check_grep "150 missing tenant test" "$TEST_FILE" "TestDocumentAIRejectsMissingTenant"
check_grep "150 missing source text test" "$TEST_FILE" "TestDocumentAIRejectsMissingSourceText"
check_grep "150 missing file hash test" "$TEST_FILE" "TestDocumentAIRejectsMissingFileHash"

check_grep "150 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "150 config OCR flow required" "$CONFIG_FILE" "\"require_ocr_flow\": true"
check_grep "150 config tax flow required" "$CONFIG_FILE" "\"require_tax_flow\": true"
check_grep "150 config contact flow required" "$CONFIG_FILE" "\"require_contact_flow\": true"
check_grep "150 config review queue flow required" "$CONFIG_FILE" "\"require_review_queue_flow\": true"
check_grep "150 config all hashes required" "$CONFIG_FILE" "\"require_all_hashes\": true"
check_grep "150 config review scenario required" "$CONFIG_FILE" "\"require_review_scenario\": true"
check_grep "150 config OCR module coverage" "$CONFIG_FILE" "FAZ_3_10_6_1_OCR_LENS_PROCESSING_RUNTIME"
check_grep "150 config tax module coverage" "$CONFIG_FILE" "FAZ_3_10_6_2_TAX_FIELD_EXTRACTION_RUNTIME"
check_grep "150 config contact module coverage" "$CONFIG_FILE" "FAZ_3_10_6_3_CONTACT_FIELD_EXTRACTION_RUNTIME"
check_grep "150 config review queue module coverage" "$CONFIG_FILE" "FAZ_3_10_6_4_CONFIDENCE_REVIEW_QUEUE_RUNTIME"
check_grep "150 config previous gate" "$CONFIG_FILE" "FAZ_3_10_6_4_CONFIDENCE_REVIEW_QUEUE_RUNTIME"
check_grep "150 config next gate" "$CONFIG_FILE" "FAZ_3_10_8_3_EBELGE_SMOKE"

if go test ./internal/erp/turkiye/documentai/runtimetests; then
  pass "150 document AI runtime tests Go test status"
else
  fail "150 document AI runtime tests Go test status"
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
# 150 — FAZ 3-10.6.5 — Document AI Runtime Tests Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_8_3_READY=${NEXT_READY}

## Scope

- OCR / Lens processing runtime bridge
- Tax field extraction runtime bridge
- Contact field extraction runtime bridge
- Confidence + review queue runtime bridge
- Happy path: OCR → tax extraction → contact extraction
- Review path: OCR review → tax review → contact review → review queue
- Runtime hash verification
- Tenant validation
- Source file hash validation
- Source text validation
- Suite hash generation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 150 — FAZ 3-10.6.5 DOCUMENT AI RUNTIME TESTS COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_8_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
