#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8L_7_LOGO_VALIDATION_ERROR_MAPPING_RETRY_DLQ.md"
CONFIG_FILE="configs/faz7/logo_validation_retry_dlq.v1.json"
CODE_DIR="internal/platform/integrations/providers/logo"
FOUNDATION_FILE="internal/platform/integrations/providers/logo/logo_foundation.go"
LIVE_CONTRACT_FILE="internal/platform/integrations/providers/logo/logo_live_contract.go"
CREDENTIAL_FILE="internal/platform/integrations/providers/logo/logo_credential.go"
EXPORT_MAPPING_FILE="internal/platform/integrations/providers/logo/logo_export_mapping.go"
FILE_GENERATION_FILE="internal/platform/integrations/providers/logo/logo_file_generation.go"
IMPORT_DELIVERY_FILE="internal/platform/integrations/providers/logo/logo_import_delivery.go"
CODE_FILE="internal/platform/integrations/providers/logo/logo_validation_retry_dlq.go"
TEST_FILE="internal/platform/integrations/providers/logo/logo_validation_retry_dlq_test.go"
FLAT_WRONG_FILE="internal/platform/integrations/runtime/logo_validation_retry_dlq.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8L_7_LOGO_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_AUDIT.md"
COUNT_FILE="/tmp/faz_7_8l_7_logo_validation_retry_dlq_audit_counts.env"
TMP_BODY="$(mktemp)"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

pass() {
  local label="$1"
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "${label} IMPLEMENTED_OR_PRESENT / OK ✅"
  echo "- ${label}: IMPLEMENTED_OR_PRESENT / OK" >> "$TMP_BODY"
}

fail() {
  local label="$1"
  local detail="$2"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "${label} REQUIRED_FAIL / ERROR ❌ :: ${detail}"
  echo "- ${label}: REQUIRED_FAIL :: ${detail}" >> "$TMP_BODY"
}

check_file() {
  local label="$1"
  local file="$2"
  if [ -s "$file" ]; then
    pass "$label"
  else
    fail "$label" "$file missing or empty"
  fi
}

check_dir() {
  local label="$1"
  local dir="$2"
  if [ -d "$dir" ]; then
    pass "$label"
  else
    fail "$label" "$dir missing"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -s "$file" ] && grep -Fq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label" "pattern not found: ${pattern}"
  fi
}

check_json() {
  local label="$1"
  local file="$2"
  if python3 -m json.tool "$file" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label" "invalid json: ${file}"
  fi
}

check_absent_file() {
  local label="$1"
  local file="$2"
  if [ ! -e "$file" ]; then
    pass "$label"
  else
    fail "$label" "wrong file exists: ${file}"
  fi
}

echo "===== 7-8L.7 LOGO VALIDATION RETRY-DLQ REAL IMPLEMENTATION AUDIT ====="

check_file "7-8L.7.1 doc artifact" "$DOC_FILE"
check_file "7-8L.7.2 config artifact" "$CONFIG_FILE"
check_dir "7-8L.7.3 provider logo directory" "$CODE_DIR"
check_file "7-8L.7.4 foundation runtime dependency" "$FOUNDATION_FILE"
check_file "7-8L.7.5 live contract runtime dependency" "$LIVE_CONTRACT_FILE"
check_file "7-8L.7.6 credential runtime dependency" "$CREDENTIAL_FILE"
check_file "7-8L.7.7 export mapping runtime dependency" "$EXPORT_MAPPING_FILE"
check_file "7-8L.7.8 file generation runtime dependency" "$FILE_GENERATION_FILE"
check_file "7-8L.7.9 import delivery runtime dependency" "$IMPORT_DELIVERY_FILE"
check_file "7-8L.7.10 Go runtime code artifact" "$CODE_FILE"
check_file "7-8L.7.11 Go test artifact" "$TEST_FILE"
check_json "7-8L.7.12 config json validity" "$CONFIG_FILE"

check_grep "7-8L.7.13 module marker in doc" "$DOC_FILE" "FAZ 7-8L.7"
check_grep "7-8L.7.14 provider directory in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/"
check_grep "7-8L.7.15 runtime filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_validation_retry_dlq.go"
check_grep "7-8L.7.16 test filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_validation_retry_dlq_test.go"
check_grep "7-8L.7.17 provider identity in doc" "$DOC_FILE" "Provider code: LOGO"
check_grep "7-8L.7.18 validation mode in doc" "$DOC_FILE" "Validation mode: VALIDATION_RETRY_DLQ_DRY_RUN_ONLY"
check_grep "7-8L.7.19 error class set in doc" "$DOC_FILE" "TRANSIENT_PROVIDER_ERROR"
check_grep "7-8L.7.20 checksum error in doc" "$DOC_FILE" "CHECKSUM_ERROR"
check_grep "7-8L.7.21 tenant boundary in doc" "$DOC_FILE" "TENANT_BOUNDARY_ERROR"
check_grep "7-8L.7.22 provider timeout in doc" "$DOC_FILE" "PROVIDER_TIMEOUT"
check_grep "7-8L.7.23 provider rate limit in doc" "$DOC_FILE" "PROVIDER_RATE_LIMIT"
check_grep "7-8L.7.24 retry max in doc" "$DOC_FILE" "Max retry attempts: 3"
check_grep "7-8L.7.25 pass action in doc" "$DOC_FILE" "PASS"
check_grep "7-8L.7.26 retry action in doc" "$DOC_FILE" "RETRY"
check_grep "7-8L.7.27 DLQ action in doc" "$DOC_FILE" "DLQ"
check_grep "7-8L.7.28 manual review action in doc" "$DOC_FILE" "MANUAL_REVIEW"
check_grep "7-8L.7.29 real provider API closed in doc" "$DOC_FILE" "LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.7.30 real file delivery closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
check_grep "7-8L.7.31 real ERP write closed in doc" "$DOC_FILE" "LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
check_grep "7-8L.7.32 retry DLQ ready in doc" "$DOC_FILE" "LOGO_VALIDATION_RETRY_DLQ_STATUS=READY"
check_grep "7-8L.7.33 next step marker in doc" "$DOC_FILE" "FAZ 7-8L.8"

check_grep "7-8L.7.34 module marker in config" "$CONFIG_FILE" "\"module\": \"FAZ_7_8L\""
check_grep "7-8L.7.35 step marker in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.7\""
check_grep "7-8L.7.36 provider code in config" "$CONFIG_FILE" "\"provider_code\": \"LOGO\""
check_grep "7-8L.7.37 provider directory in config" "$CONFIG_FILE" "\"provider_directory\": \"internal/platform/integrations/providers/logo\""
check_grep "7-8L.7.38 runtime file in config" "$CONFIG_FILE" "\"runtime_file\": \"internal/platform/integrations/providers/logo/logo_validation_retry_dlq.go\""
check_grep "7-8L.7.39 test file in config" "$CONFIG_FILE" "\"test_file\": \"internal/platform/integrations/providers/logo/logo_validation_retry_dlq_test.go\""
check_grep "7-8L.7.40 validation mode in config" "$CONFIG_FILE" "\"validation_mode\": \"VALIDATION_RETRY_DLQ_DRY_RUN_ONLY\""
check_grep "7-8L.7.41 validation status in config" "$CONFIG_FILE" "\"validation_retry_dlq_status\": \"READY\""
check_grep "7-8L.7.42 validation contract in config" "$CONFIG_FILE" "\"validation_contract\""
check_grep "7-8L.7.43 error classes in config" "$CONFIG_FILE" "\"error_classes\""
check_grep "7-8L.7.44 error codes in config" "$CONFIG_FILE" "\"error_codes\""
check_grep "7-8L.7.45 retry policy in config" "$CONFIG_FILE" "\"retry_policy\""
check_grep "7-8L.7.46 max attempts in config" "$CONFIG_FILE" "\"max_attempts\": 3"
check_grep "7-8L.7.47 retry limit DLQ in config" "$CONFIG_FILE" "\"retry_limit_exceeded_action\": \"DLQ\""
check_grep "7-8L.7.48 provider timeout in config" "$CONFIG_FILE" "\"code\": \"PROVIDER_TIMEOUT\""
check_grep "7-8L.7.49 provider rate limit in config" "$CONFIG_FILE" "\"code\": \"PROVIDER_RATE_LIMIT\""
check_grep "7-8L.7.50 checksum mismatch in config" "$CONFIG_FILE" "\"code\": \"CHECKSUM_MISMATCH\""
check_grep "7-8L.7.51 tenant boundary in config" "$CONFIG_FILE" "\"code\": \"TENANT_BOUNDARY_VIOLATION\""
check_grep "7-8L.7.52 manual review true in config" "$CONFIG_FILE" "\"manual_review\": true"
check_grep "7-8L.7.53 retryable true in config" "$CONFIG_FILE" "\"retryable\": true"
check_grep "7-8L.7.54 DLQ true in config" "$CONFIG_FILE" "\"dlq\": true"
check_grep "7-8L.7.55 external call disabled in config" "$CONFIG_FILE" "\"external_call_allowed\": false"
check_grep "7-8L.7.56 real file delivery disabled in config" "$CONFIG_FILE" "\"real_file_delivery_allowed\": false"
check_grep "7-8L.7.57 ERP write disabled in config" "$CONFIG_FILE" "\"erp_write_allowed\": false"
check_grep "7-8L.7.58 real provider API closed in config" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.7.59 real file delivery closed in config" "$CONFIG_FILE" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\""
check_grep "7-8L.7.60 real ERP write closed in config" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""

check_grep "7-8L.7.61 package logo" "$CODE_FILE" "package logo"
check_grep "7-8L.7.62 validation retry DLQ contract struct" "$CODE_FILE" "type LogoValidationRetryDLQContract struct"
check_grep "7-8L.7.63 validation contract type" "$CODE_FILE" "type LogoValidationContract struct"
check_grep "7-8L.7.64 error mapping type" "$CODE_FILE" "type LogoErrorMapping struct"
check_grep "7-8L.7.65 retry policy type" "$CODE_FILE" "type LogoRetryPolicy struct"
check_grep "7-8L.7.66 validation result type" "$CODE_FILE" "type LogoValidationResult struct"
check_grep "7-8L.7.67 validation error type" "$CODE_FILE" "type LogoValidationError struct"
check_grep "7-8L.7.68 retry decision type" "$CODE_FILE" "type LogoRetryDecision struct"
check_grep "7-8L.7.69 constructor" "$CODE_FILE" "func NewLogoValidationRetryDLQContract() LogoValidationRetryDLQContract"
check_grep "7-8L.7.70 validator" "$CODE_FILE" "func (c LogoValidationRetryDLQContract) Validate() error"
check_grep "7-8L.7.71 real integrations closed guard" "$CODE_FILE" "func (c LogoValidationRetryDLQContract) RealIntegrationsClosed() bool"
check_grep "7-8L.7.72 error mappings validator" "$CODE_FILE" "func (c LogoValidationRetryDLQContract) ValidateErrorMappings() error"
check_grep "7-8L.7.73 operations validator" "$CODE_FILE" "func (c LogoValidationRetryDLQContract) ValidateOperations() error"
check_grep "7-8L.7.74 envelope validator" "$CODE_FILE" "func (c LogoValidationRetryDLQContract) ValidateEnvelope"
check_grep "7-8L.7.75 decide method" "$CODE_FILE" "func (c LogoValidationRetryDLQContract) Decide"
check_grep "7-8L.7.76 backoff method" "$CODE_FILE" "func (p LogoRetryPolicy) BackoffForAttempt"
check_grep "7-8L.7.77 checksum mismatch code" "$CODE_FILE" "CHECKSUM_MISMATCH"
check_grep "7-8L.7.78 invalid manifest code" "$CODE_FILE" "INVALID_MANIFEST"
check_grep "7-8L.7.79 tenant boundary code" "$CODE_FILE" "TENANT_BOUNDARY_VIOLATION"
check_grep "7-8L.7.80 provider timeout code" "$CODE_FILE" "PROVIDER_TIMEOUT"
check_grep "7-8L.7.81 provider rate limit code" "$CODE_FILE" "PROVIDER_RATE_LIMIT"
check_grep "7-8L.7.82 provider rejected code" "$CODE_FILE" "PROVIDER_REJECTED_PACKAGE"
check_grep "7-8L.7.83 unknown provider code" "$CODE_FILE" "UNKNOWN_PROVIDER_ERROR"
check_grep "7-8L.7.84 retry decision const" "$CODE_FILE" "LogoDecisionRetry"
check_grep "7-8L.7.85 DLQ decision const" "$CODE_FILE" "LogoDecisionDLQ"
check_grep "7-8L.7.86 manual review decision const" "$CODE_FILE" "LogoDecisionManualReview"
check_grep "7-8L.7.87 real file delivery denied model" "$CODE_FILE" "RealFileDeliveryAllowed"
check_grep "7-8L.7.88 ERP write denied model" "$CODE_FILE" "ERPWriteAllowed"

check_grep "7-8L.7.89 package logo test" "$TEST_FILE" "package logo"
check_grep "7-8L.7.90 readiness test" "$TEST_FILE" "TestLogoValidationRetryDLQContractReadiness"
check_grep "7-8L.7.91 integrations closed test" "$TEST_FILE" "TestLogoValidationRetryDLQKeepsRealIntegrationsClosed"
check_grep "7-8L.7.92 envelope pass test" "$TEST_FILE" "TestLogoValidationEnvelopePasses"
check_grep "7-8L.7.93 missing tenant DLQ test" "$TEST_FILE" "TestLogoValidationRejectsMissingTenantAsDLQ"
check_grep "7-8L.7.94 tenant boundary review test" "$TEST_FILE" "TestLogoValidationTenantBoundaryManualReview"
check_grep "7-8L.7.95 checksum review test" "$TEST_FILE" "TestLogoValidationChecksumManualReview"
check_grep "7-8L.7.96 manifest DLQ test" "$TEST_FILE" "TestLogoValidationInvalidManifestDLQ"
check_grep "7-8L.7.97 retry transient test" "$TEST_FILE" "TestLogoRetryDecisionForTransientProviderError"
check_grep "7-8L.7.98 retry limit DLQ test" "$TEST_FILE" "TestLogoRetryLimitExceededGoesToDLQ"
check_grep "7-8L.7.99 permanent provider DLQ test" "$TEST_FILE" "TestLogoPermanentProviderRejectedPackageGoesToDLQ"
check_grep "7-8L.7.100 unknown provider manual review test" "$TEST_FILE" "TestLogoUnknownProviderErrorManualReview"
check_grep "7-8L.7.101 external operation rejection test" "$TEST_FILE" "TestLogoValidationRejectsExternalOperation"
check_grep "7-8L.7.102 real file delivery rejection test" "$TEST_FILE" "TestLogoValidationRejectsRealFileDeliveryOperation"
check_grep "7-8L.7.103 ERP write rejection test" "$TEST_FILE" "TestLogoValidationRejectsERPWriteOperation"

check_absent_file "7-8L.7.104 runtime flat Logo validation retry-DLQ file absent" "$FLAT_WRONG_FILE"

{
  echo "# FAZ 7-8L.7 Logo Validation Retry-DLQ Real Implementation Audit"
  echo
  echo "## Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  echo
  echo "## Evidence"
  echo
  cat "$TMP_BODY"
} > "$EVIDENCE_FILE"

cat <<COUNT_EOF > "$COUNT_FILE"
PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}
AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}
COUNT_EOF

echo "===== 7-8L.7 LOGO VALIDATION RETRY-DLQ REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

rm -f "$TMP_BODY"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8L_7_LOGO_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8L_7_LOGO_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
