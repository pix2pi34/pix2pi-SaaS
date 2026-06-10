#!/usr/bin/env bash
set -Eeuo pipefail

RUNTIME_FILE="internal/platform/integrations/providers/zirve/zirve_validation_retry_dlq.go"
TEST_FILE="internal/platform/integrations/providers/zirve/zirve_validation_retry_dlq_test.go"
CONFIG_FILE="configs/faz7/integrations/zirve_validation_retry_dlq.json"
DOC_FILE="docs/faz7/integrations/zirve/FAZ_7_8Z_4_ZIRVE_VALIDATION_RETRY_DLQ.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8Z_4_ZIRVE_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

ok() {
  local code="$1"
  local message="$2"
  PASS_COUNT=$((PASS_COUNT + 1))
  printf '%s %s / OK ✅\n' "$code" "$message"
}

fail() {
  local code="$1"
  local message="$2"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  printf '%s %s / FAIL ❌\n' "$code" "$message"
}

require_file() {
  local code="$1"
  local file="$2"
  local message="$3"
  if [[ -f "$file" ]]; then
    ok "$code" "$message"
  else
    fail "$code" "$message missing: $file"
  fi
}

require_contains() {
  local code="$1"
  local file="$2"
  local needle="$3"
  local message="$4"
  if [[ -f "$file" ]] && grep -qF "$needle" "$file"; then
    ok "$code" "$message"
  else
    fail "$code" "$message missing needle: $needle"
  fi
}

mkdir -p "$(dirname "$EVIDENCE_FILE")"

{
  echo "# FAZ 7-8Z.4 Zirve Validation Retry-DLQ Real Implementation Audit"
  echo
  echo "- Audit time UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Scope: validation/error mapping/retry-dlq code/config/doc/test/script evidence"
  echo
} > "$EVIDENCE_FILE"

echo "===== 7-8Z.4 ZIRVE VALIDATION RETRY-DLQ REAL IMPLEMENTATION AUDIT ====="

require_file "7-8Z.4.1.1" "$RUNTIME_FILE" "runtime file exists"
require_file "7-8Z.4.1.2" "$TEST_FILE" "test file exists"
require_file "7-8Z.4.1.3" "$CONFIG_FILE" "config file exists"
require_file "7-8Z.4.1.4" "$DOC_FILE" "documentation file exists"
require_file "7-8Z.4.1.5" "$EVIDENCE_FILE" "audit evidence file exists"

require_contains "7-8Z.4.2.1" "$RUNTIME_FILE" "ZirveValidationRetryDLQModuleCode = \"FAZ_7_8Z_4\"" "runtime declares FAZ 7-8Z.4 module code"
require_contains "7-8Z.4.2.2" "$RUNTIME_FILE" "VALIDATION_RETRY_DLQ_DRY_RUN_ONLY" "runtime declares validation retry-dlq dry-run mode"
require_contains "7-8Z.4.2.3" "$RUNTIME_FILE" "VALIDATE_BEFORE_DELIVERY_AND_ROUTE_FAILURES" "runtime declares validation routing policy"
require_contains "7-8Z.4.2.4" "$RUNTIME_FILE" "MAX_ATTEMPT_THEN_DLQ" "runtime declares retry policy"
require_contains "7-8Z.4.2.5" "$RUNTIME_FILE" "DLQ_FOR_EXHAUSTED_RETRY_OR_BLOCKER" "runtime declares DLQ policy"
require_contains "7-8Z.4.2.6" "$RUNTIME_FILE" "MANUAL_REVIEW_FOR_BUSINESS_OR_SCHEMA_FAILURE" "runtime declares manual review policy"
require_contains "7-8Z.4.2.7" "$RUNTIME_FILE" "BuildDryRunValidationRetryDLQDecision" "runtime implements validation retry-dlq decision builder"
require_contains "7-8Z.4.2.8" "$RUNTIME_FILE" "validateZirveImportDeliveryContractForValidation" "runtime validates upstream 7-8Z.3 delivery contract"
require_contains "7-8Z.4.2.9" "$RUNTIME_FILE" "mapZirveValidationIssue" "runtime maps error codes to issues"
require_contains "7-8Z.4.2.10" "$RUNTIME_FILE" "decideZirveValidationOutcome" "runtime decides retry/dlq/manual-review outcome"
require_contains "7-8Z.4.2.11" "$RUNTIME_FILE" "ZirveErrProviderTemporary" "runtime has provider temporary error code"
require_contains "7-8Z.4.2.12" "$RUNTIME_FILE" "ZirveErrProviderRateLimit" "runtime has provider rate limit error code"
require_contains "7-8Z.4.2.13" "$RUNTIME_FILE" "ZirveErrSchemaMismatch" "runtime has schema mismatch error code"
require_contains "7-8Z.4.2.14" "$RUNTIME_FILE" "ZirveErrRealDeliveryAttempted" "runtime has real delivery attempt security error code"
require_contains "7-8Z.4.2.15" "$RUNTIME_FILE" "ZirveValidationOutcomeRetry" "runtime has retry outcome"
require_contains "7-8Z.4.2.16" "$RUNTIME_FILE" "ZirveValidationOutcomeDLQ" "runtime has DLQ outcome"
require_contains "7-8Z.4.2.17" "$RUNTIME_FILE" "ZirveValidationOutcomeManualReview" "runtime has manual review outcome"
require_contains "7-8Z.4.2.18" "$RUNTIME_FILE" "ZirveValidationOutcomeDeny" "runtime has deny outcome"
require_contains "7-8Z.4.2.19" "$RUNTIME_FILE" "RealProviderAPIAllowed:            false" "runtime keeps real provider API closed"
require_contains "7-8Z.4.2.20" "$RUNTIME_FILE" "RealFileDeliveryAllowed:           false" "runtime keeps real file delivery closed"
require_contains "7-8Z.4.2.21" "$RUNTIME_FILE" "RealDeliveryChannelAllowed:        false" "runtime keeps real delivery channel closed"
require_contains "7-8Z.4.2.22" "$RUNTIME_FILE" "RealERPWriteAllowed:               false" "runtime keeps real ERP write closed"
require_contains "7-8Z.4.2.23" "$RUNTIME_FILE" "RealOperatorProviderActionAllowed: false" "runtime keeps real operator provider action closed"

require_contains "7-8Z.4.3.1" "$TEST_FILE" "TestZirveValidationRetryDLQPassDecision" "test validates PASS decision"
require_contains "7-8Z.4.3.2" "$TEST_FILE" "TestZirveValidationRetryDLQRetryableTemporaryFailure" "test validates retryable temporary failure"
require_contains "7-8Z.4.3.3" "$TEST_FILE" "TestZirveValidationRetryDLQMaxAttemptGoesToDLQ" "test validates max attempt DLQ"
require_contains "7-8Z.4.3.4" "$TEST_FILE" "TestZirveValidationRetryDLQManualReviewForSchemaMismatch" "test validates manual review for schema mismatch"
require_contains "7-8Z.4.3.5" "$TEST_FILE" "TestZirveValidationRetryDLQDenyRealDeliveryAttempt" "test validates deny for real delivery attempt"
require_contains "7-8Z.4.3.6" "$TEST_FILE" "TestZirveValidationRetryDLQKeepsRealBoundariesClosed" "test validates real boundaries closed"
require_contains "7-8Z.4.3.7" "$TEST_FILE" "TestZirveValidationRetryDLQRejectsNonDryRun" "test rejects non-dry-run request"
require_contains "7-8Z.4.3.8" "$TEST_FILE" "TestZirveValidationRetryDLQRejectsInvalidContract" "test rejects invalid upstream contract"
require_contains "7-8Z.4.3.9" "$TEST_FILE" "TestZirveValidationRetryDLQRejectsAttemptGreaterThanMax" "test rejects attempt greater than max"

require_contains "7-8Z.4.4.1" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_8Z_4\"" "config declares module code"
require_contains "7-8Z.4.4.2" "$CONFIG_FILE" "\"provider_id\": \"zirve\"" "config declares Zirve provider"
require_contains "7-8Z.4.4.3" "$CONFIG_FILE" "\"mode\": \"VALIDATION_RETRY_DLQ_DRY_RUN_ONLY\"" "config declares dry-run mode"
require_contains "7-8Z.4.4.4" "$CONFIG_FILE" "\"retry_policy\": \"MAX_ATTEMPT_THEN_DLQ\"" "config declares retry policy"
require_contains "7-8Z.4.4.5" "$CONFIG_FILE" "\"dlq_policy\": \"DLQ_FOR_EXHAUSTED_RETRY_OR_BLOCKER\"" "config declares DLQ policy"
require_contains "7-8Z.4.4.6" "$CONFIG_FILE" "\"manual_review_policy\": \"MANUAL_REVIEW_FOR_BUSINESS_OR_SCHEMA_FAILURE\"" "config declares manual review policy"
require_contains "7-8Z.4.4.7" "$CONFIG_FILE" "\"real_file_delivery\": false" "config keeps real file delivery closed"
require_contains "7-8Z.4.4.8" "$CONFIG_FILE" "\"real_delivery_channel\": false" "config keeps real delivery channel closed"
require_contains "7-8Z.4.4.9" "$CONFIG_FILE" "\"real_erp_write\": false" "config keeps real ERP write closed"
require_contains "7-8Z.4.4.10" "$CONFIG_FILE" "\"external_delivery_attempted\": false" "config states external delivery not attempted"

require_contains "7-8Z.4.5.1" "$DOC_FILE" "Error Mapping" "doc includes error mapping"
require_contains "7-8Z.4.5.2" "$DOC_FILE" "Retryable / non-retryable" "doc states retry classification scope"
require_contains "7-8Z.4.5.3" "$DOC_FILE" "Gerçek Zirve dosya gönderimi" "doc states real Zirve file delivery remains closed"
require_contains "7-8Z.4.5.4" "$DOC_FILE" "Gerçek delivery channel" "doc states real delivery channel remains closed"
require_contains "7-8Z.4.5.5" "$DOC_FILE" "Gerçek ERP write" "doc states real ERP write remains closed"
require_contains "7-8Z.4.5.6" "$DOC_FILE" "FAZ 7-8Z.5" "doc declares next step"

{
  echo
  echo "## Audit Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
    echo "- FAZ_7_8Z_4_ZIRVE_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_STATUS=PASS"
  else
    echo "- FAZ_7_8Z_4_ZIRVE_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_STATUS=FAIL"
  fi
} >> "$EVIDENCE_FILE"

echo "===== 7-8Z.4 ZIRVE VALIDATION RETRY-DLQ REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
  echo "FAZ_7_8Z_4_ZIRVE_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8Z_4_ZIRVE_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
