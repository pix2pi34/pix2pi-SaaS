#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8L_9_LOGO_E2E_DRY_RUN_FLOW.md"
CONFIG_FILE="configs/faz7/logo_e2e_dry_run_flow.v1.json"
CODE_DIR="internal/platform/integrations/providers/logo"
FOUNDATION_FILE="internal/platform/integrations/providers/logo/logo_foundation.go"
LIVE_CONTRACT_FILE="internal/platform/integrations/providers/logo/logo_live_contract.go"
CREDENTIAL_FILE="internal/platform/integrations/providers/logo/logo_credential.go"
EXPORT_MAPPING_FILE="internal/platform/integrations/providers/logo/logo_export_mapping.go"
FILE_GENERATION_FILE="internal/platform/integrations/providers/logo/logo_file_generation.go"
IMPORT_DELIVERY_FILE="internal/platform/integrations/providers/logo/logo_import_delivery.go"
VALIDATION_FILE="internal/platform/integrations/providers/logo/logo_validation_retry_dlq.go"
ADMIN_OPS_FILE="internal/platform/integrations/providers/logo/logo_admin_ops.go"
CODE_FILE="internal/platform/integrations/providers/logo/logo_e2e_dry_run.go"
TEST_FILE="internal/platform/integrations/providers/logo/logo_e2e_dry_run_test.go"
FLAT_WRONG_FILE="internal/platform/integrations/runtime/logo_e2e_dry_run.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8L_9_LOGO_E2E_DRY_RUN_REAL_IMPLEMENTATION_AUDIT.md"
COUNT_FILE="/tmp/faz_7_8l_9_logo_e2e_dry_run_audit_counts.env"
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

echo "===== 7-8L.9 LOGO E2E DRY-RUN REAL IMPLEMENTATION AUDIT ====="

check_file "7-8L.9.1 doc artifact" "$DOC_FILE"
check_file "7-8L.9.2 config artifact" "$CONFIG_FILE"
check_dir "7-8L.9.3 provider logo directory" "$CODE_DIR"
check_file "7-8L.9.4 foundation runtime dependency" "$FOUNDATION_FILE"
check_file "7-8L.9.5 live contract runtime dependency" "$LIVE_CONTRACT_FILE"
check_file "7-8L.9.6 credential runtime dependency" "$CREDENTIAL_FILE"
check_file "7-8L.9.7 export mapping runtime dependency" "$EXPORT_MAPPING_FILE"
check_file "7-8L.9.8 file generation runtime dependency" "$FILE_GENERATION_FILE"
check_file "7-8L.9.9 import delivery runtime dependency" "$IMPORT_DELIVERY_FILE"
check_file "7-8L.9.10 validation retry-DLQ runtime dependency" "$VALIDATION_FILE"
check_file "7-8L.9.11 admin ops runtime dependency" "$ADMIN_OPS_FILE"
check_file "7-8L.9.12 Go runtime code artifact" "$CODE_FILE"
check_file "7-8L.9.13 Go test artifact" "$TEST_FILE"
check_json "7-8L.9.14 config json validity" "$CONFIG_FILE"

check_grep "7-8L.9.15 module marker in doc" "$DOC_FILE" "FAZ 7-8L.9"
check_grep "7-8L.9.16 provider directory in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/"
check_grep "7-8L.9.17 runtime filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_e2e_dry_run.go"
check_grep "7-8L.9.18 test filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_e2e_dry_run_test.go"
check_grep "7-8L.9.19 provider identity in doc" "$DOC_FILE" "Provider code: LOGO"
check_grep "7-8L.9.20 E2E mode in doc" "$DOC_FILE" "E2E mode: E2E_DRY_RUN_ONLY"
check_grep "7-8L.9.21 successful flow in doc" "$DOC_FILE" "SUCCESSFUL_DRY_RUN_FLOW"
check_grep "7-8L.9.22 validation flow in doc" "$DOC_FILE" "VALIDATION_FAILURE_TO_DLQ_FLOW"
check_grep "7-8L.9.23 retry flow in doc" "$DOC_FILE" "TRANSIENT_PROVIDER_RETRY_FLOW"
check_grep "7-8L.9.24 manual review flow in doc" "$DOC_FILE" "UNKNOWN_PROVIDER_MANUAL_REVIEW_FLOW"
check_grep "7-8L.9.25 no real provider API step in doc" "$DOC_FILE" "NO_REAL_PROVIDER_API_CALLED"
check_grep "7-8L.9.26 no real file delivery step in doc" "$DOC_FILE" "NO_REAL_FILE_DELIVERY_ATTEMPTED"
check_grep "7-8L.9.27 no ERP write step in doc" "$DOC_FILE" "NO_ERP_WRITE_ATTEMPTED"
check_grep "7-8L.9.28 real provider API closed in doc" "$DOC_FILE" "LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.9.29 real file delivery closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
check_grep "7-8L.9.30 real ERP write closed in doc" "$DOC_FILE" "LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
check_grep "7-8L.9.31 next step marker in doc" "$DOC_FILE" "FAZ 7-8L.10"

check_grep "7-8L.9.32 module marker in config" "$CONFIG_FILE" "\"module\": \"FAZ_7_8L\""
check_grep "7-8L.9.33 step marker in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.9\""
check_grep "7-8L.9.34 provider code in config" "$CONFIG_FILE" "\"provider_code\": \"LOGO\""
check_grep "7-8L.9.35 provider directory in config" "$CONFIG_FILE" "\"provider_directory\": \"internal/platform/integrations/providers/logo\""
check_grep "7-8L.9.36 runtime file in config" "$CONFIG_FILE" "\"runtime_file\": \"internal/platform/integrations/providers/logo/logo_e2e_dry_run.go\""
check_grep "7-8L.9.37 test file in config" "$CONFIG_FILE" "\"test_file\": \"internal/platform/integrations/providers/logo/logo_e2e_dry_run_test.go\""
check_grep "7-8L.9.38 e2e mode in config" "$CONFIG_FILE" "\"e2e_mode\": \"E2E_DRY_RUN_ONLY\""
check_grep "7-8L.9.39 e2e status in config" "$CONFIG_FILE" "\"e2e_dry_run_status\": \"READY\""
check_grep "7-8L.9.40 chain steps in config" "$CONFIG_FILE" "\"chain_steps\""
check_grep "7-8L.9.41 flow types in config" "$CONFIG_FILE" "\"flow_types\""
check_grep "7-8L.9.42 successful flow in config" "$CONFIG_FILE" "\"SUCCESSFUL_DRY_RUN_FLOW\""
check_grep "7-8L.9.43 validation flow in config" "$CONFIG_FILE" "\"VALIDATION_FAILURE_TO_DLQ_FLOW\""
check_grep "7-8L.9.44 retry flow in config" "$CONFIG_FILE" "\"TRANSIENT_PROVIDER_RETRY_FLOW\""
check_grep "7-8L.9.45 manual review flow in config" "$CONFIG_FILE" "\"UNKNOWN_PROVIDER_MANUAL_REVIEW_FLOW\""
check_grep "7-8L.9.46 e2e contract in config" "$CONFIG_FILE" "\"e2e_contract\""
check_grep "7-8L.9.47 dry run only in config" "$CONFIG_FILE" "\"dry_run_only\": true"
check_grep "7-8L.9.48 successful flow required in config" "$CONFIG_FILE" "\"successful_flow_required\": true"
check_grep "7-8L.9.49 validation failure required in config" "$CONFIG_FILE" "\"validation_failure_flow_required\": true"
check_grep "7-8L.9.50 retry decision required in config" "$CONFIG_FILE" "\"retry_decision_flow_required\": true"
check_grep "7-8L.9.51 manual review required in config" "$CONFIG_FILE" "\"manual_review_flow_required\": true"
check_grep "7-8L.9.52 external call disabled in config" "$CONFIG_FILE" "\"external_call_allowed\": false"
check_grep "7-8L.9.53 real file delivery disabled in config" "$CONFIG_FILE" "\"real_file_delivery_allowed\": false"
check_grep "7-8L.9.54 ERP write disabled in config" "$CONFIG_FILE" "\"erp_write_allowed\": false"
check_grep "7-8L.9.55 real provider API closed in config" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""

check_grep "7-8L.9.56 package logo" "$CODE_FILE" "package logo"
check_grep "7-8L.9.57 E2E contract struct" "$CODE_FILE" "type LogoE2EDryRunContract struct"
check_grep "7-8L.9.58 E2E result type" "$CODE_FILE" "type LogoE2EDryRunResult struct"
check_grep "7-8L.9.59 E2E rules type" "$CODE_FILE" "type LogoE2EDryRunContractRules struct"
check_grep "7-8L.9.60 E2E operation contract type" "$CODE_FILE" "type LogoE2EDryRunOperationContract struct"
check_grep "7-8L.9.61 constructor" "$CODE_FILE" "func NewLogoE2EDryRunContract() LogoE2EDryRunContract"
check_grep "7-8L.9.62 validator" "$CODE_FILE" "func (c LogoE2EDryRunContract) Validate() error"
check_grep "7-8L.9.63 real integrations closed guard" "$CODE_FILE" "func (c LogoE2EDryRunContract) RealIntegrationsClosed() bool"
check_grep "7-8L.9.64 operations validator" "$CODE_FILE" "func (c LogoE2EDryRunContract) ValidateOperations() error"
check_grep "7-8L.9.65 successful flow method" "$CODE_FILE" "func (c LogoE2EDryRunContract) RunSuccessfulDryRunFlow"
check_grep "7-8L.9.66 manual review flow method" "$CODE_FILE" "func (c LogoE2EDryRunContract) RunManualReviewDryRunFlow"
check_grep "7-8L.9.67 retry decision flow method" "$CODE_FILE" "func (c LogoE2EDryRunContract) RunRetryDecisionDryRunFlow"
check_grep "7-8L.9.68 default steps method" "$CODE_FILE" "func (c LogoE2EDryRunContract) defaultSteps() []string"
check_grep "7-8L.9.69 no real side effects validator" "$CODE_FILE" "func (r LogoE2EDryRunResult) ValidateNoRealSideEffects() error"
check_grep "7-8L.9.70 required steps validator" "$CODE_FILE" "func (r LogoE2EDryRunResult) ValidateRequiredSteps() error"
check_grep "7-8L.9.71 successful flow const" "$CODE_FILE" "SUCCESSFUL_DRY_RUN_FLOW"
check_grep "7-8L.9.72 validation DLQ flow const" "$CODE_FILE" "VALIDATION_FAILURE_TO_DLQ_FLOW"
check_grep "7-8L.9.73 retry flow const" "$CODE_FILE" "TRANSIENT_PROVIDER_RETRY_FLOW"
check_grep "7-8L.9.74 manual review flow const" "$CODE_FILE" "UNKNOWN_PROVIDER_MANUAL_REVIEW_FLOW"
check_grep "7-8L.9.75 no real provider API field" "$CODE_FILE" "RealProviderAPICalled"
check_grep "7-8L.9.76 no real file delivery field" "$CODE_FILE" "RealFileDeliveryAttempted"
check_grep "7-8L.9.77 no ERP write field" "$CODE_FILE" "ERPWriteAttempted"
check_grep "7-8L.9.78 E2E final closure operation" "$CODE_FILE" "PREPARE_LOGO_FINAL_CLOSURE_HANDOFF"
check_grep "7-8L.9.79 E2E mode const" "$CODE_FILE" "LogoE2EDryRunMode"
check_grep "7-8L.9.80 E2E status const" "$CODE_FILE" "LogoE2EDryRunStatus"
check_grep "7-8L.9.81 admin ops dependency" "$CODE_FILE" "NewLogoAdminOpsContract"
check_grep "7-8L.9.82 file generation dependency" "$CODE_FILE" "NewLogoFileGenerationContract"
check_grep "7-8L.9.83 import delivery dependency" "$CODE_FILE" "NewLogoImportDeliveryContract"

check_grep "7-8L.9.84 package logo test" "$TEST_FILE" "package logo"
check_grep "7-8L.9.85 readiness test" "$TEST_FILE" "TestLogoE2EDryRunContractReadiness"
check_grep "7-8L.9.86 integrations closed test" "$TEST_FILE" "TestLogoE2EDryRunKeepsRealIntegrationsClosed"
check_grep "7-8L.9.87 successful flow test" "$TEST_FILE" "TestLogoE2ESuccessfulDryRunFlow"
check_grep "7-8L.9.88 validation failure DLQ test" "$TEST_FILE" "TestLogoE2EValidationFailureToDLQFlow"
check_grep "7-8L.9.89 retry flow test" "$TEST_FILE" "TestLogoE2ERetryDecisionFlow"
check_grep "7-8L.9.90 retry limit DLQ test" "$TEST_FILE" "TestLogoE2ERetryLimitToDLQFlow"
check_grep "7-8L.9.91 manual review flow test" "$TEST_FILE" "TestLogoE2EManualReviewDryRunFlow"
check_grep "7-8L.9.92 external op rejection test" "$TEST_FILE" "TestLogoE2ERejectsExternalOperation"
check_grep "7-8L.9.93 real file delivery rejection test" "$TEST_FILE" "TestLogoE2ERejectsRealFileDeliveryOperation"
check_grep "7-8L.9.94 ERP write rejection test" "$TEST_FILE" "TestLogoE2ERejectsERPWriteOperation"
check_grep "7-8L.9.95 real side effect rejection test" "$TEST_FILE" "TestLogoE2ERejectsRealSideEffectResult"

check_absent_file "7-8L.9.96 runtime flat Logo E2E dry-run file absent" "$FLAT_WRONG_FILE"

{
  echo "# FAZ 7-8L.9 Logo E2E Dry-Run Real Implementation Audit"
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

echo "===== 7-8L.9 LOGO E2E DRY-RUN REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

rm -f "$TMP_BODY"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8L_9_LOGO_E2E_DRY_RUN_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8L_9_LOGO_E2E_DRY_RUN_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
