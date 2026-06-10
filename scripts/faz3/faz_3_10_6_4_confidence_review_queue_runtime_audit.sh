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

echo "===== 149 — FAZ 3-10.6.4 CONFIDENCE REVIEW QUEUE RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/documentai/reviewqueue/confidence_review_queue_runtime.go"
TEST_FILE="internal/erp/turkiye/documentai/reviewqueue/confidence_review_queue_runtime_test.go"
CONFIG_FILE="configs/faz3/documentai/confidence_review_queue_runtime.v1.json"
DOC_FILE="docs/faz3/documentai/FAZ_3_10_6_4_CONFIDENCE_REVIEW_QUEUE_RUNTIME.md"

check_file "149 review queue runtime file" "$RUNTIME_FILE"
check_file "149 review queue test file" "$TEST_FILE"
check_file "149 review queue config file" "$CONFIG_FILE"
check_file "149 review queue documentation file" "$DOC_FILE"

check_grep "149 runtime constructor" "$RUNTIME_FILE" "NewConfidenceReviewQueueRuntime"
check_grep "149 register runtime" "$RUNTIME_FILE" "Register"
check_grep "149 OCR review bridge" "$RUNTIME_FILE" "RegisterOCRReview"
check_grep "149 tax review bridge" "$RUNTIME_FILE" "RegisterTaxReview"
check_grep "149 contact review bridge" "$RUNTIME_FILE" "RegisterContactReview"
check_grep "149 assign runtime" "$RUNTIME_FILE" "Assign"
check_grep "149 resolve approve runtime" "$RUNTIME_FILE" "ResolveApprove"
check_grep "149 resolve reject runtime" "$RUNTIME_FILE" "ResolveReject"
check_grep "149 dismiss runtime" "$RUNTIME_FILE" "Dismiss"
check_grep "149 list open runtime" "$RUNTIME_FILE" "ListOpen"
check_grep "149 priority runtime" "$RUNTIME_FILE" "priority"

check_grep "149 OCR processing import" "$RUNTIME_FILE" "documentai/ocrprocessing"
check_grep "149 tax extraction import" "$RUNTIME_FILE" "documentai/taxextraction"
check_grep "149 contact extraction import" "$RUNTIME_FILE" "documentai/contactextraction"

check_grep "149 source type model" "$RUNTIME_FILE" "type ReviewSourceType"
check_grep "149 review status model" "$RUNTIME_FILE" "type ReviewStatus"
check_grep "149 review priority model" "$RUNTIME_FILE" "type ReviewPriority"
check_grep "149 review action model" "$RUNTIME_FILE" "type ReviewAction"
check_grep "149 review item model" "$RUNTIME_FILE" "type ReviewItem"
check_grep "149 review decision model" "$RUNTIME_FILE" "type ReviewDecision"
check_grep "149 register request model" "$RUNTIME_FILE" "type ReviewRegisterRequest"
check_grep "149 action request model" "$RUNTIME_FILE" "type ReviewActionRequest"
check_grep "149 list request model" "$RUNTIME_FILE" "type ReviewListRequest"
check_grep "149 list result model" "$RUNTIME_FILE" "type ReviewListResult"

check_grep "149 OCR source type" "$RUNTIME_FILE" "ReviewSourceOCR"
check_grep "149 tax source type" "$RUNTIME_FILE" "ReviewSourceTax"
check_grep "149 contact source type" "$RUNTIME_FILE" "ReviewSourceContact"
check_grep "149 open status" "$RUNTIME_FILE" "ReviewStatusOpen"
check_grep "149 assigned status" "$RUNTIME_FILE" "ReviewStatusAssigned"
check_grep "149 approved status" "$RUNTIME_FILE" "ReviewStatusResolvedApproved"
check_grep "149 rejected status" "$RUNTIME_FILE" "ReviewStatusResolvedRejected"
check_grep "149 dismissed status" "$RUNTIME_FILE" "ReviewStatusDismissed"
check_grep "149 low priority" "$RUNTIME_FILE" "ReviewPriorityLow"
check_grep "149 medium priority" "$RUNTIME_FILE" "ReviewPriorityMedium"
check_grep "149 high priority" "$RUNTIME_FILE" "ReviewPriorityHigh"
check_grep "149 critical priority" "$RUNTIME_FILE" "ReviewPriorityCritical"

check_grep "149 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "149 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "149 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "149 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "149 review id guard" "$RUNTIME_FILE" "review_id is required"
check_grep "149 source type guard" "$RUNTIME_FILE" "source_type is not allowed"
check_grep "149 source id guard" "$RUNTIME_FILE" "source_id is required"
check_grep "149 document id guard" "$RUNTIME_FILE" "document_id is required"
check_grep "149 source hash guard" "$RUNTIME_FILE" "source_hash is required"
check_grep "149 confidence guard" "$RUNTIME_FILE" "confidence_bps is below minimum"
check_grep "149 reason code guard" "$RUNTIME_FILE" "reason_code is required"
check_grep "149 reason guard" "$RUNTIME_FILE" "reason is required"
check_grep "149 actor guard" "$RUNTIME_FILE" "actor_id is required"
check_grep "149 assignee guard" "$RUNTIME_FILE" "assignee_id is required"
check_grep "149 resolution note guard" "$RUNTIME_FILE" "resolution_note is required"
check_grep "149 duplicate guard" "$RUNTIME_FILE" "review item already exists"
check_grep "149 max open guard" "$RUNTIME_FILE" "max open items per tenant exceeded"
check_grep "149 decision hash builder" "$RUNTIME_FILE" "buildDecisionHash"
check_grep "149 list hash builder" "$RUNTIME_FILE" "buildListHash"

check_grep "149 register test" "$TEST_FILE" "TestRegisterReviewItem"
check_grep "149 OCR register test" "$TEST_FILE" "TestRegisterOCRReview"
check_grep "149 tax register test" "$TEST_FILE" "TestRegisterTaxReviewCriticalPriority"
check_grep "149 contact register test" "$TEST_FILE" "TestRegisterContactReview"
check_grep "149 assign test" "$TEST_FILE" "TestAssignReviewItem"
check_grep "149 approve test" "$TEST_FILE" "TestResolveApproveReviewItem"
check_grep "149 reject test" "$TEST_FILE" "TestResolveRejectReviewItem"
check_grep "149 dismiss test" "$TEST_FILE" "TestDismissReviewItem"
check_grep "149 list tenant scope test" "$TEST_FILE" "TestListOpenTenantScoped"
check_grep "149 duplicate test" "$TEST_FILE" "TestRejectsDuplicateReview"
check_grep "149 source hash test" "$TEST_FILE" "TestRejectsMissingSourceHash"
check_grep "149 assignee test" "$TEST_FILE" "TestRejectsMissingAssignee"
check_grep "149 resolution note test" "$TEST_FILE" "TestRejectsMissingResolutionNote"

check_grep "149 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "149 config tenant scope required" "$CONFIG_FILE" "\"require_tenant_scope\": true"
check_grep "149 config source hash required" "$CONFIG_FILE" "\"require_source_hash\": true"
check_grep "149 config review reason required" "$CONFIG_FILE" "\"require_review_reason\": true"
check_grep "149 config actor required" "$CONFIG_FILE" "\"require_actor_for_action\": true"
check_grep "149 config assignee required" "$CONFIG_FILE" "\"require_assignee_for_assign\": true"
check_grep "149 config resolution note required" "$CONFIG_FILE" "\"require_resolution_note\": true"
check_grep "149 config decision hash required" "$CONFIG_FILE" "\"require_decision_hash\": true"
check_grep "149 config OCR source" "$CONFIG_FILE" "\"OCR\""
check_grep "149 config tax source" "$CONFIG_FILE" "\"TAX_EXTRACTION\""
check_grep "149 config contact source" "$CONFIG_FILE" "\"CONTACT_EXTRACTION\""
check_grep "149 config previous gate" "$CONFIG_FILE" "FAZ_3_10_6_3_CONTACT_FIELD_EXTRACTION_RUNTIME"
check_grep "149 config next gate" "$CONFIG_FILE" "FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS"

if go test ./internal/erp/turkiye/documentai/reviewqueue; then
  pass "149 confidence review queue runtime Go test status"
else
  fail "149 confidence review queue runtime Go test status"
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
# 149 — FAZ 3-10.6.4 — Confidence Review Queue Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_6_4_CONFIDENCE_REVIEW_QUEUE_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_6_4_CONFIDENCE_REVIEW_QUEUE_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_6_5_READY=${NEXT_READY}

## Scope

- Review source type model
- Review status model
- Review priority model
- Review action model
- Review item model
- Review decision model
- Register review runtime
- OCR review bridge
- Tax extraction review bridge
- Contact extraction review bridge
- Assign runtime
- Resolve approve runtime
- Resolve reject runtime
- Dismiss runtime
- List open runtime
- Priority calculation
- Tenant-safe in-memory queue
- Decision hash generation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 149 — FAZ 3-10.6.4 CONFIDENCE REVIEW QUEUE RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_6_4_CONFIDENCE_REVIEW_QUEUE_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_6_4_CONFIDENCE_REVIEW_QUEUE_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_6_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
