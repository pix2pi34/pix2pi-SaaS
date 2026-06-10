#!/usr/bin/env bash
set -Eeuo pipefail

RUNTIME_FILE="internal/platform/integrations/providers/zirve/zirve_e2e_dry_run.go"
TEST_FILE="internal/platform/integrations/providers/zirve/zirve_e2e_dry_run_test.go"
CONFIG_FILE="configs/faz7/integrations/zirve_e2e_dry_run_flow.json"
DOC_FILE="docs/faz7/integrations/zirve/FAZ_7_8Z_6_ZIRVE_E2E_DRY_RUN_FLOW.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8Z_6_ZIRVE_E2E_DRY_RUN_FLOW_REAL_IMPLEMENTATION_AUDIT.md"

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
  echo "# FAZ 7-8Z.6 Zirve E2E Dry-Run Flow Real Implementation Audit"
  echo
  echo "- Audit time UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Scope: E2E dry-run chain code/config/doc/test/script evidence"
  echo
} > "$EVIDENCE_FILE"

echo "===== 7-8Z.6 ZIRVE E2E DRY-RUN FLOW REAL IMPLEMENTATION AUDIT ====="

require_file "7-8Z.6.1.1" "$RUNTIME_FILE" "runtime file exists"
require_file "7-8Z.6.1.2" "$TEST_FILE" "test file exists"
require_file "7-8Z.6.1.3" "$CONFIG_FILE" "config file exists"
require_file "7-8Z.6.1.4" "$DOC_FILE" "documentation file exists"
require_file "7-8Z.6.1.5" "$EVIDENCE_FILE" "audit evidence file exists"

require_contains "7-8Z.6.2.1" "$RUNTIME_FILE" "ZirveE2EDryRunModuleCode = \"FAZ_7_8Z_6\"" "runtime declares FAZ 7-8Z.6 module code"
require_contains "7-8Z.6.2.2" "$RUNTIME_FILE" "E2E_DRY_RUN_FLOW_ONLY" "runtime declares E2E dry-run mode"
require_contains "7-8Z.6.2.3" "$RUNTIME_FILE" "FOUNDATION_TO_ADMIN_OPS_DRY_RUN_CHAIN" "runtime declares E2E chain policy"
require_contains "7-8Z.6.2.4" "$RUNTIME_FILE" "CHAIN_EVIDENCE_REQUIRED_FOR_EVERY_STEP" "runtime declares evidence policy"
require_contains "7-8Z.6.2.5" "$RUNTIME_FILE" "RunDryRunFlow" "runtime implements E2E dry-run flow"
require_contains "7-8Z.6.2.6" "$RUNTIME_FILE" "NewZirveExportPackageBuilder" "runtime uses file generation builder"
require_contains "7-8Z.6.2.7" "$RUNTIME_FILE" "BuildDryRunExportPackage" "runtime builds dry-run export package"
require_contains "7-8Z.6.2.8" "$RUNTIME_FILE" "NewZirveImportDeliveryContractBuilder" "runtime uses import delivery builder"
require_contains "7-8Z.6.2.9" "$RUNTIME_FILE" "BuildDryRunImportDeliveryContract" "runtime builds import delivery contract"
require_contains "7-8Z.6.2.10" "$RUNTIME_FILE" "NewZirveValidationRetryDLQRuntime" "runtime uses validation retry-DLQ runtime"
require_contains "7-8Z.6.2.11" "$RUNTIME_FILE" "BuildDryRunValidationRetryDLQDecision" "runtime builds validation retry-DLQ decision"
require_contains "7-8Z.6.2.12" "$RUNTIME_FILE" "NewZirveAdminOpsRuntime" "runtime uses admin ops runtime"
require_contains "7-8Z.6.2.13" "$RUNTIME_FILE" "OpenManualReview" "runtime opens manual review when eligible"
require_contains "7-8Z.6.2.14" "$RUNTIME_FILE" "isZirveE2EManualReviewEligible" "runtime has manual review eligibility logic"
require_contains "7-8Z.6.2.15" "$RUNTIME_FILE" "RealProviderAPIAllowed:            false" "runtime keeps real provider API closed"
require_contains "7-8Z.6.2.16" "$RUNTIME_FILE" "RealFileDeliveryAllowed:           false" "runtime keeps real file delivery closed"
require_contains "7-8Z.6.2.17" "$RUNTIME_FILE" "RealDeliveryChannelAllowed:        false" "runtime keeps real delivery channel closed"
require_contains "7-8Z.6.2.18" "$RUNTIME_FILE" "RealERPWriteAllowed:               false" "runtime keeps real ERP write closed"
require_contains "7-8Z.6.2.19" "$RUNTIME_FILE" "RealOperatorProviderActionAllowed: false" "runtime keeps real operator provider action closed"

require_contains "7-8Z.6.3.1" "$TEST_FILE" "TestZirveE2EDryRunManualReviewFlow" "test validates manual review E2E flow"
require_contains "7-8Z.6.3.2" "$TEST_FILE" "TestZirveE2EDryRunPassFlowSkipsManualReview" "test validates PASS flow skips manual review"
require_contains "7-8Z.6.3.3" "$TEST_FILE" "TestZirveE2EDryRunDLQFlowOpensManualReview" "test validates DLQ flow opens manual review"
require_contains "7-8Z.6.3.4" "$TEST_FILE" "TestZirveE2EDryRunDenyFlowOpensCriticalManualReview" "test validates DENY flow opens critical manual review"
require_contains "7-8Z.6.3.5" "$TEST_FILE" "TestZirveE2EDryRunKeepsRealBoundariesClosed" "test validates real boundaries closed"
require_contains "7-8Z.6.3.6" "$TEST_FILE" "TestZirveE2EDryRunRejectsNonDryRun" "test rejects non-dry-run E2E request"
require_contains "7-8Z.6.3.7" "$TEST_FILE" "TestZirveE2EDryRunRequiresObjects" "test requires export objects"
require_contains "7-8Z.6.3.8" "$TEST_FILE" "TestZirveE2EDryRunRejectsAttemptGreaterThanMax" "test rejects invalid attempt count"

require_contains "7-8Z.6.4.1" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_8Z_6\"" "config declares module code"
require_contains "7-8Z.6.4.2" "$CONFIG_FILE" "\"provider_id\": \"zirve\"" "config declares Zirve provider"
require_contains "7-8Z.6.4.3" "$CONFIG_FILE" "\"mode\": \"E2E_DRY_RUN_FLOW_ONLY\"" "config declares E2E dry-run mode"
require_contains "7-8Z.6.4.4" "$CONFIG_FILE" "\"chain_policy\": \"FOUNDATION_TO_ADMIN_OPS_DRY_RUN_CHAIN\"" "config declares chain policy"
require_contains "7-8Z.6.4.5" "$CONFIG_FILE" "\"evidence_policy\": \"CHAIN_EVIDENCE_REQUIRED_FOR_EVERY_STEP\"" "config declares evidence policy"
require_contains "7-8Z.6.4.6" "$CONFIG_FILE" "\"real_zirve_api\": false" "config keeps real Zirve API closed"
require_contains "7-8Z.6.4.7" "$CONFIG_FILE" "\"real_file_delivery\": false" "config keeps real file delivery closed"
require_contains "7-8Z.6.4.8" "$CONFIG_FILE" "\"real_delivery_channel\": false" "config keeps real delivery channel closed"
require_contains "7-8Z.6.4.9" "$CONFIG_FILE" "\"real_erp_write\": false" "config keeps real ERP write closed"
require_contains "7-8Z.6.4.10" "$CONFIG_FILE" "\"real_operator_provider_action\": false" "config keeps real operator provider action closed"

require_contains "7-8Z.6.5.1" "$DOC_FILE" "Foundation identity validation" "doc includes foundation step"
require_contains "7-8Z.6.5.2" "$DOC_FILE" "File generation dry-run package" "doc includes file generation step"
require_contains "7-8Z.6.5.3" "$DOC_FILE" "Import delivery contract" "doc includes import delivery step"
require_contains "7-8Z.6.5.4" "$DOC_FILE" "Validation / Retry-DLQ decision" "doc includes validation step"
require_contains "7-8Z.6.5.5" "$DOC_FILE" "Admin / Ops manual review" "doc includes admin ops step"
require_contains "7-8Z.6.5.6" "$DOC_FILE" "Gerçek operator provider action" "doc states real operator provider action remains closed"
require_contains "7-8Z.6.5.7" "$DOC_FILE" "FAZ 7-8Z.7" "doc declares next step"

{
  echo
  echo "## Audit Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
    echo "- FAZ_7_8Z_6_ZIRVE_E2E_DRY_RUN_FLOW_REAL_IMPLEMENTATION_STATUS=PASS"
  else
    echo "- FAZ_7_8Z_6_ZIRVE_E2E_DRY_RUN_FLOW_REAL_IMPLEMENTATION_STATUS=FAIL"
  fi
} >> "$EVIDENCE_FILE"

echo "===== 7-8Z.6 ZIRVE E2E DRY-RUN FLOW REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
  echo "FAZ_7_8Z_6_ZIRVE_E2E_DRY_RUN_FLOW_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8Z_6_ZIRVE_E2E_DRY_RUN_FLOW_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
