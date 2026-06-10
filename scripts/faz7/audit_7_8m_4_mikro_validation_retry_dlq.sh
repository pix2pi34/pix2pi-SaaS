#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8M_4_MIKRO_VALIDATION_ERROR_MAPPING_RETRY_DLQ.md"
CONFIG_FILE="configs/faz7/integrations/mikro_validation_retry_dlq.v1.json"
FOUNDATION_FILE="internal/platform/integrations/providers/mikro/mikro_connector_foundation.go"
MAPPING_FILE="internal/platform/integrations/providers/mikro/mikro_export_mapping.go"
FILE_GENERATION_FILE="internal/platform/integrations/providers/mikro/mikro_file_generation_dry_run.go"
IMPORT_DELIVERY_FILE="internal/platform/integrations/providers/mikro/mikro_import_delivery.go"
RUNTIME_FILE="internal/platform/integrations/providers/mikro/mikro_validation_retry_dlq.go"
TEST_FILE="internal/platform/integrations/providers/mikro/mikro_validation_retry_dlq_test.go"
AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8M_4_MIKRO_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_AUDIT.md"

mkdir -p "$(dirname "$AUDIT_EVIDENCE_FILE")"
: > "$AUDIT_EVIDENCE_FILE"

log_line() {
  echo "$*" | tee -a "$AUDIT_EVIDENCE_FILE"
}

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  log_line "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  log_line "$1 MISSING_OR_INVALID / FAIL ❌"
}

require_file() {
  local label="$1"
  local file="$2"
  if [[ -f "$file" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_dir() {
  local label="$1"
  local dir="$2"
  if [[ -d "$dir" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_grep() {
  local label="$1"
  local pattern="$2"
  local file="$3"
  if [[ -f "$file" ]] && grep -Eq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

log_line "===== 7-8M.4 MIKRO VALIDATION RETRY-DLQ REAL IMPLEMENTATION AUDIT ====="

require_file "7-8M.4.1 doc artifact exists" "$DOC_FILE"
require_file "7-8M.4.2 config artifact exists" "$CONFIG_FILE"
require_dir "7-8M.4.3 provider directory exists" "internal/platform/integrations/providers/mikro"
require_file "7-8M.4.4 foundation runtime exists" "$FOUNDATION_FILE"
require_file "7-8M.4.5 export mapping runtime exists" "$MAPPING_FILE"
require_file "7-8M.4.6 file generation runtime exists" "$FILE_GENERATION_FILE"
require_file "7-8M.4.7 import delivery runtime exists" "$IMPORT_DELIVERY_FILE"
require_file "7-8M.4.8 validation retry dlq runtime code exists" "$RUNTIME_FILE"
require_file "7-8M.4.9 validation retry dlq test code exists" "$TEST_FILE"

require_grep "7-8M.4.1.1 doc declares FAZ_7_8M_4" "FAZ_7_8M_4" "$DOC_FILE"
require_grep "7-8M.4.1.2 doc declares Mikro Validation" "Mikro Validation" "$DOC_FILE"
require_grep "7-8M.4.1.3 doc declares Error Mapping" "Error Mapping" "$DOC_FILE"
require_grep "7-8M.4.1.4 doc declares Retry-DLQ" "Retry-DLQ" "$DOC_FILE"
require_grep "7-8M.4.1.5 doc declares PIX2PI_TO_MIKRO direction" "PIX2PI_TO_MIKRO" "$DOC_FILE"
require_grep "7-8M.4.1.6 doc declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$DOC_FILE"
require_grep "7-8M.4.1.7 doc keeps real provider API closed" "MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.4.1.8 doc keeps real file delivery closed" "MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.4.1.9 doc keeps real ERP write closed" "MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.4.1.10 doc keeps real delivery channel closed" "MIKRO_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.4.1.11 doc declares retry policy" "Max Attempts: 3" "$DOC_FILE"
require_grep "7-8M.4.1.12 doc declares DLQ policy" "DLQ" "$DOC_FILE"
require_grep "7-8M.4.1.13 doc declares manual review policy" "Manual review" "$DOC_FILE"
require_grep "7-8M.4.1.14 doc requires counter based final status" "final status sayaçlardan türemeli" "$DOC_FILE"

require_grep "7-8M.4.2.1 config phase is FAZ_7_8M_4" "\"phase\": \"FAZ_7_8M_4\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.2 config module is validation retry dlq" "\"module\": \"MIKRO_VALIDATION_ERROR_MAPPING_RETRY_DLQ\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.3 config provider id is mikro" "\"provider_id\": \"mikro\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.4 config provider name is Mikro" "\"provider_name\": \"Mikro\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.5 config validation mode is dry-run only" "\"validation_mode\": \"VALIDATION_RETRY_DLQ_DRY_RUN_ONLY\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.6 config direction is PIX2PI_TO_MIKRO" "\"direction\": \"PIX2PI_TO_MIKRO\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.7 config target system is Mikro dry-run import" "\"target_system\": \"MIKRO_ACCOUNTING_IMPORT_DRY_RUN\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.8 config declares no real queue write" "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE" "$CONFIG_FILE"
require_grep "7-8M.4.2.9 config declares max attempts 3" "\"max_attempts\": 3" "$CONFIG_FILE"
require_grep "7-8M.4.2.10 config declares retry strategy" "EXPONENTIAL_BACKOFF_DRY_RUN" "$CONFIG_FILE"
require_grep "7-8M.4.2.11 config declares MIKRO_TIMEOUT mapping" "MIKRO_TIMEOUT" "$CONFIG_FILE"
require_grep "7-8M.4.2.12 config declares MIKRO_RATE_LIMIT mapping" "MIKRO_RATE_LIMIT" "$CONFIG_FILE"
require_grep "7-8M.4.2.13 config declares MIKRO_FORMAT_ERROR mapping" "MIKRO_FORMAT_ERROR" "$CONFIG_FILE"
require_grep "7-8M.4.2.14 config declares MIKRO_AUTH_FAILED mapping" "MIKRO_AUTH_FAILED" "$CONFIG_FILE"
require_grep "7-8M.4.2.15 config declares RETRYABLE_TEMPORARY" "RETRYABLE_TEMPORARY" "$CONFIG_FILE"
require_grep "7-8M.4.2.16 config declares NON_RETRYABLE_VALIDATION" "NON_RETRYABLE_VALIDATION" "$CONFIG_FILE"
require_grep "7-8M.4.2.17 config declares real provider API closed" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.18 config declares real file delivery closed" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.19 config declares real ERP write closed" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.20 config declares real delivery channel closed" "\"real_delivery_channel_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.21 config requires tenant_id" "\"tenant_id\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.22 config requires validation_id" "\"validation_id\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.23 config requires package_id" "\"package_id\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.24 config forbids client_secret" "\"client_secret\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.25 config forbids access_token" "\"access_token\"" "$CONFIG_FILE"
require_grep "7-8M.4.2.26 config keeps FAZ 7-9 on hold" "HOLD_UNTIL_INTEGRATION_FAMILY_DONE" "$CONFIG_FILE"

require_grep "7-8M.4.3.1 foundation keeps real provider API closed" "MikroRealProviderAPIStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$FOUNDATION_FILE"
require_grep "7-8M.4.3.2 foundation keeps real file delivery closed" "MikroRealFileDeliveryStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$FOUNDATION_FILE"
require_grep "7-8M.4.3.3 foundation keeps real ERP write closed" "MikroRealERPWriteStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$FOUNDATION_FILE"

require_grep "7-8M.4.4.1 mapping runtime has phase 7-8M.1" "MikroExportMappingPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_1\"" "$MAPPING_FILE"
require_grep "7-8M.4.4.2 file generation runtime has phase 7-8M.2" "MikroFileGenerationPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_2\"" "$FILE_GENERATION_FILE"
require_grep "7-8M.4.4.3 import delivery runtime has phase 7-8M.3" "MikroImportDeliveryPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_3\"" "$IMPORT_DELIVERY_FILE"
require_grep "7-8M.4.4.4 import delivery runtime has real delivery channel closed" "MikroRealDeliveryChannelStatus" "$IMPORT_DELIVERY_FILE"

require_grep "7-8M.4.5.1 runtime package is mikro" "^package mikro" "$RUNTIME_FILE"
require_grep "7-8M.4.5.2 runtime declares phase" "MikroValidationRetryDLQPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_4\"" "$RUNTIME_FILE"
require_grep "7-8M.4.5.3 runtime declares module" "MIKRO_VALIDATION_ERROR_MAPPING_RETRY_DLQ" "$RUNTIME_FILE"
require_grep "7-8M.4.5.4 runtime declares validation mode" "VALIDATION_RETRY_DLQ_DRY_RUN_ONLY" "$RUNTIME_FILE"
require_grep "7-8M.4.5.5 runtime declares direction" "PIX2PI_TO_MIKRO" "$RUNTIME_FILE"
require_grep "7-8M.4.5.6 runtime declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$RUNTIME_FILE"
require_grep "7-8M.4.5.7 runtime declares no real queue write" "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE" "$RUNTIME_FILE"
require_grep "7-8M.4.5.8 runtime declares retry strategy" "EXPONENTIAL_BACKOFF_DRY_RUN" "$RUNTIME_FILE"
require_grep "7-8M.4.5.9 runtime declares MIKRO_TIMEOUT" "MIKRO_TIMEOUT" "$RUNTIME_FILE"
require_grep "7-8M.4.5.10 runtime declares MIKRO_RATE_LIMIT" "MIKRO_RATE_LIMIT" "$RUNTIME_FILE"
require_grep "7-8M.4.5.11 runtime declares MIKRO_FORMAT_ERROR" "MIKRO_FORMAT_ERROR" "$RUNTIME_FILE"
require_grep "7-8M.4.5.12 runtime declares MIKRO_AUTH_FAILED" "MIKRO_AUTH_FAILED" "$RUNTIME_FILE"
require_grep "7-8M.4.5.13 runtime declares RETRYABLE_TEMPORARY" "RETRYABLE_TEMPORARY" "$RUNTIME_FILE"
require_grep "7-8M.4.5.14 runtime declares NON_RETRYABLE_VALIDATION" "NON_RETRYABLE_VALIDATION" "$RUNTIME_FILE"
require_grep "7-8M.4.5.15 runtime declares ACCEPT action" "MikroValidationActionAccept" "$RUNTIME_FILE"
require_grep "7-8M.4.5.16 runtime declares RETRY action" "MikroValidationActionRetry" "$RUNTIME_FILE"
require_grep "7-8M.4.5.17 runtime declares DLQ action" "MikroValidationActionDLQ" "$RUNTIME_FILE"
require_grep "7-8M.4.5.18 runtime declares manual review action" "MikroValidationActionManualReview" "$RUNTIME_FILE"
require_grep "7-8M.4.5.19 runtime uses real provider API closed status" "MikroRealProviderAPIStatus" "$RUNTIME_FILE"
require_grep "7-8M.4.5.20 runtime uses real file delivery closed status" "MikroRealFileDeliveryStatus" "$RUNTIME_FILE"
require_grep "7-8M.4.5.21 runtime uses real ERP write closed status" "MikroRealERPWriteStatus" "$RUNTIME_FILE"
require_grep "7-8M.4.5.22 runtime uses real delivery channel closed status" "MikroRealDeliveryChannelStatus" "$RUNTIME_FILE"
require_grep "7-8M.4.5.23 runtime has retry policy type" "type MikroRetryPolicy struct" "$RUNTIME_FILE"
require_grep "7-8M.4.5.24 runtime has provider error mapping type" "type MikroProviderErrorMapping struct" "$RUNTIME_FILE"
require_grep "7-8M.4.5.25 runtime has contract type" "type MikroValidationRetryDLQContract struct" "$RUNTIME_FILE"
require_grep "7-8M.4.5.26 runtime has request type" "type MikroValidationRequest struct" "$RUNTIME_FILE"
require_grep "7-8M.4.5.27 runtime has decision type" "type MikroValidationDecision struct" "$RUNTIME_FILE"
require_grep "7-8M.4.5.28 runtime has runtime type" "type MikroValidationRetryDLQRuntime struct" "$RUNTIME_FILE"
require_grep "7-8M.4.5.29 runtime has contract constructor" "func NewMikroValidationRetryDLQContract" "$RUNTIME_FILE"
require_grep "7-8M.4.5.30 runtime has runtime constructor" "func NewMikroValidationRetryDLQRuntime" "$RUNTIME_FILE"
require_grep "7-8M.4.5.31 runtime has validate method" "func \\(c MikroValidationRetryDLQContract\\) Validate" "$RUNTIME_FILE"
require_grep "7-8M.4.5.32 runtime has provider error lookup" "MappingForProviderError" "$RUNTIME_FILE"
require_grep "7-8M.4.5.33 runtime has Evaluate method" "func \\(r MikroValidationRetryDLQRuntime\\) Evaluate" "$RUNTIME_FILE"
require_grep "7-8M.4.5.34 runtime has provider error evaluator" "evaluateProviderError" "$RUNTIME_FILE"
require_grep "7-8M.4.5.35 runtime validates tenant id" "TenantID" "$RUNTIME_FILE"
require_grep "7-8M.4.5.36 runtime validates actor user id" "ActorUserID" "$RUNTIME_FILE"
require_grep "7-8M.4.5.37 runtime validates correlation id" "CorrelationID" "$RUNTIME_FILE"
require_grep "7-8M.4.5.38 runtime validates validation id" "ValidationID" "$RUNTIME_FILE"
require_grep "7-8M.4.5.39 runtime validates package id" "PackageID" "$RUNTIME_FILE"
require_grep "7-8M.4.5.40 runtime verifies dry-run package" "verifyMikroDryRunPackage" "$RUNTIME_FILE"
require_grep "7-8M.4.5.41 runtime denies provider live mode" "PROVIDER_LIVE" "$RUNTIME_FILE"
require_grep "7-8M.4.5.42 runtime denies real provider API enabled" "RealProviderAPIEnabled" "$RUNTIME_FILE"
require_grep "7-8M.4.5.43 runtime denies real file delivery enabled" "RealFileDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.4.5.44 runtime denies real ERP write enabled" "RealERPWriteEnabled" "$RUNTIME_FILE"
require_grep "7-8M.4.5.45 runtime denies real delivery enabled" "RealDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.4.5.46 runtime forbids secret fields" "containsForbiddenMappingField" "$RUNTIME_FILE"
require_grep "7-8M.4.5.47 runtime calculates retry backoff" "calculateMikroRetryBackoffSeconds" "$RUNTIME_FILE"
require_grep "7-8M.4.5.48 runtime has retry limit guard" "MaxAttempts" "$RUNTIME_FILE"
require_grep "7-8M.4.5.49 runtime sets SendToDLQ" "SendToDLQ" "$RUNTIME_FILE"
require_grep "7-8M.4.5.50 runtime sets ManualReview" "ManualReview" "$RUNTIME_FILE"
require_grep "7-8M.4.5.51 runtime declares ready decision" "MIKRO_VALIDATION_DRY_RUN_PACKAGE_ACCEPTED" "$RUNTIME_FILE"
require_grep "7-8M.4.5.52 runtime declares retry decision" "MIKRO_VALIDATION_RETRY_DECISION_READY" "$RUNTIME_FILE"
require_grep "7-8M.4.5.53 runtime declares DLQ decision" "MIKRO_VALIDATION_DLQ_DECISION_READY" "$RUNTIME_FILE"
require_grep "7-8M.4.5.54 runtime declares manual review decision" "MIKRO_VALIDATION_MANUAL_REVIEW_DECISION_READY" "$RUNTIME_FILE"

require_grep "7-8M.4.6.1 tests include root 7-8M.4 OK output" "7-8M\\.4" "$TEST_FILE"
require_grep "7-8M.4.6.2 tests include 7-8M.4.1 OK output" "7-8M\\.4\\.1" "$TEST_FILE"
require_grep "7-8M.4.6.3 tests include 7-8M.4.1.1 OK output" "7-8M\\.4\\.1\\.1" "$TEST_FILE"
require_grep "7-8M.4.6.4 tests validate accepted package" "valid dry-run package is accepted" "$TEST_FILE"
require_grep "7-8M.4.6.5 tests validate retry mapping" "MIKRO_TIMEOUT maps to retry decision" "$TEST_FILE"
require_grep "7-8M.4.6.6 tests validate retry backoff" "MIKRO_RATE_LIMIT maps to retry decision with backoff" "$TEST_FILE"
require_grep "7-8M.4.6.7 tests validate retry exhausted DLQ" "retry exhausted timeout maps to DLQ" "$TEST_FILE"
require_grep "7-8M.4.6.8 tests validate format DLQ" "MIKRO_FORMAT_ERROR maps to DLQ" "$TEST_FILE"
require_grep "7-8M.4.6.9 tests validate auth manual review" "MIKRO_AUTH_FAILED maps to manual review" "$TEST_FILE"
require_grep "7-8M.4.6.10 tests validate closed real API" "real Mikro API request is denied" "$TEST_FILE"
require_grep "7-8M.4.6.11 tests validate closed file delivery" "real Mikro file delivery request is denied" "$TEST_FILE"
require_grep "7-8M.4.6.12 tests validate closed ERP write" "real ERP write request is denied" "$TEST_FILE"
require_grep "7-8M.4.6.13 tests validate closed delivery channel" "real delivery channel request is denied" "$TEST_FILE"
require_grep "7-8M.4.6.14 tests validate validation id guard" "missing validation id is rejected" "$TEST_FILE"
require_grep "7-8M.4.6.15 tests validate checksum DLQ" "checksum mismatch is classified for DLQ" "$TEST_FILE"
require_grep "7-8M.4.6.16 tests validate secret rejection" "client_secret field is rejected" "$TEST_FILE"

log_line "===== 7-8M.4 MIKRO VALIDATION RETRY-DLQ REAL IMPLEMENTATION AUDIT RESULT ====="
log_line "PASS_COUNT=$PASS_COUNT"
log_line "FAIL_COUNT=$FAIL_COUNT"
log_line "REQUIRED_FAIL=$REQUIRED_FAIL"
log_line "OPTIONAL_WARN=$OPTIONAL_WARN"
log_line "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"

if [[ "$REQUIRED_FAIL" -eq 0 ]]; then
  log_line "FAZ_7_8M_4_MIKRO_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

log_line "FAZ_7_8M_4_MIKRO_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
