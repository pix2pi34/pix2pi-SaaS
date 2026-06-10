#!/usr/bin/env bash
set -Eeuo pipefail

RUNTIME_FILE="internal/platform/integrations/providers/zirve/zirve_final_closure.go"
TEST_FILE="internal/platform/integrations/providers/zirve/zirve_final_closure_test.go"
CONFIG_FILE="configs/faz7/integrations/zirve_final_closure.json"
DOC_FILE="docs/faz7/integrations/zirve/FAZ_7_8Z_7_ZIRVE_FINAL_CLOSURE.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8Z_7_ZIRVE_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

REQUIRED_FILES=(
  "internal/platform/integrations/providers/zirve/zirve_foundation.go"
  "internal/platform/integrations/providers/zirve/zirve_foundation_test.go"
  "configs/faz7/integrations/zirve_connector_foundation.json"
  "docs/faz7/evidence/FAZ_7_8Z_ZIRVE_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_AUDIT.md"

  "internal/platform/integrations/providers/zirve/zirve_file_generation.go"
  "internal/platform/integrations/providers/zirve/zirve_file_generation_test.go"
  "configs/faz7/integrations/zirve_file_generation_dry_run.json"
  "docs/faz7/evidence/FAZ_7_8Z_2_ZIRVE_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_AUDIT.md"

  "internal/platform/integrations/providers/zirve/zirve_import_delivery.go"
  "internal/platform/integrations/providers/zirve/zirve_import_delivery_test.go"
  "configs/faz7/integrations/zirve_import_delivery_contract.json"
  "docs/faz7/evidence/FAZ_7_8Z_3_ZIRVE_IMPORT_DELIVERY_CONTRACT_REAL_IMPLEMENTATION_AUDIT.md"

  "internal/platform/integrations/providers/zirve/zirve_validation_retry_dlq.go"
  "internal/platform/integrations/providers/zirve/zirve_validation_retry_dlq_test.go"
  "configs/faz7/integrations/zirve_validation_retry_dlq.json"
  "docs/faz7/evidence/FAZ_7_8Z_4_ZIRVE_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_AUDIT.md"

  "internal/platform/integrations/providers/zirve/zirve_admin_ops.go"
  "internal/platform/integrations/providers/zirve/zirve_admin_ops_test.go"
  "configs/faz7/integrations/zirve_admin_ops_manual_review.json"
  "docs/faz7/evidence/FAZ_7_8Z_5_ZIRVE_ADMIN_OPS_MANUAL_REVIEW_REAL_IMPLEMENTATION_AUDIT.md"

  "internal/platform/integrations/providers/zirve/zirve_e2e_dry_run.go"
  "internal/platform/integrations/providers/zirve/zirve_e2e_dry_run_test.go"
  "configs/faz7/integrations/zirve_e2e_dry_run_flow.json"
  "docs/faz7/evidence/FAZ_7_8Z_6_ZIRVE_E2E_DRY_RUN_FLOW_REAL_IMPLEMENTATION_AUDIT.md"
)

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
  echo "# FAZ 7-8Z.7 Zirve Final Closure Real Implementation Audit"
  echo
  echo "- Audit time UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Scope: final closure code/config/doc/test/script and all upstream dry-run module evidence"
  echo
} > "$EVIDENCE_FILE"

echo "===== 7-8Z.7 ZIRVE FINAL CLOSURE REAL IMPLEMENTATION AUDIT ====="

require_file "7-8Z.7.1.1" "$RUNTIME_FILE" "runtime file exists"
require_file "7-8Z.7.1.2" "$TEST_FILE" "test file exists"
require_file "7-8Z.7.1.3" "$CONFIG_FILE" "config file exists"
require_file "7-8Z.7.1.4" "$DOC_FILE" "documentation file exists"
require_file "7-8Z.7.1.5" "$EVIDENCE_FILE" "audit evidence file exists"

idx=1
for required_file in "${REQUIRED_FILES[@]}"; do
  require_file "7-8Z.7.2.${idx}" "$required_file" "upstream required file exists"
  idx=$((idx + 1))
done

require_contains "7-8Z.7.3.1" "$RUNTIME_FILE" "ZirveFinalClosureModuleCode = \"FAZ_7_8Z_7\"" "runtime declares FAZ 7-8Z.7 module code"
require_contains "7-8Z.7.3.2" "$RUNTIME_FILE" "CONNECTOR_FINAL_CLOSURE_DRY_RUN_MODULE_ONLY" "runtime declares final closure dry-run-only mode"
require_contains "7-8Z.7.3.3" "$RUNTIME_FILE" "ZirveConnectorModuleFinalSealStatus = \"SEALED\"" "runtime declares connector module sealed"
require_contains "7-8Z.7.3.4" "$RUNTIME_FILE" "ZirveDryRunModuleFinalStatus        = \"SEALED\"" "runtime declares dry-run module sealed"
require_contains "7-8Z.7.3.5" "$RUNTIME_FILE" "READY_FOR_PROVIDER_LIVE_MODULE" "runtime declares provider live handoff gate"
require_contains "7-8Z.7.3.6" "$RUNTIME_FILE" "NOT_STARTED" "runtime keeps provider live module not started"
require_contains "7-8Z.7.3.7" "$RUNTIME_FILE" "CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "runtime keeps real provider operations closed"
require_contains "7-8Z.7.3.8" "$RUNTIME_FILE" "DefaultZirveClosureModuleEvidence" "runtime declares upstream module evidence list"
require_contains "7-8Z.7.3.9" "$RUNTIME_FILE" "CanStartRealProviderLiveModule" "runtime exposes provider live handoff readiness"
require_contains "7-8Z.7.3.10" "$RUNTIME_FILE" "DecideFinalClosureOperation" "runtime exposes final closure operation decision"
require_contains "7-8Z.7.3.11" "$RUNTIME_FILE" "RealProviderAPIAllowed:            false" "runtime keeps real provider API closed"
require_contains "7-8Z.7.3.12" "$RUNTIME_FILE" "RealFileDeliveryAllowed:           false" "runtime keeps real file delivery closed"
require_contains "7-8Z.7.3.13" "$RUNTIME_FILE" "RealDeliveryChannelAllowed:        false" "runtime keeps real delivery channel closed"
require_contains "7-8Z.7.3.14" "$RUNTIME_FILE" "RealERPWriteAllowed:               false" "runtime keeps real ERP write closed"
require_contains "7-8Z.7.3.15" "$RUNTIME_FILE" "RealOperatorProviderActionAllowed: false" "runtime keeps real operator provider action closed"

require_contains "7-8Z.7.4.1" "$TEST_FILE" "TestZirveFinalClosureReportValidates" "test validates final closure report"
require_contains "7-8Z.7.4.2" "$TEST_FILE" "TestZirveFinalClosureRequiresAllModules" "test validates all required modules"
require_contains "7-8Z.7.4.3" "$TEST_FILE" "TestZirveFinalClosureKeepsRealBoundariesClosed" "test validates real boundaries closed"
require_contains "7-8Z.7.4.4" "$TEST_FILE" "TestZirveFinalClosureProviderLiveHandoffReadyButLiveNotStarted" "test validates handoff ready but live not started"
require_contains "7-8Z.7.4.5" "$TEST_FILE" "TestZirveFinalClosureRejectsMissingEvidence" "test rejects missing evidence"
require_contains "7-8Z.7.4.6" "$TEST_FILE" "TestZirveFinalClosureRejectsMissingModule" "test rejects missing module"
require_contains "7-8Z.7.4.7" "$TEST_FILE" "TestZirveFinalClosureDecisionModel" "test validates decision model"

require_contains "7-8Z.7.5.1" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_8Z_7\"" "config declares module code"
require_contains "7-8Z.7.5.2" "$CONFIG_FILE" "\"provider_id\": \"zirve\"" "config declares Zirve provider"
require_contains "7-8Z.7.5.3" "$CONFIG_FILE" "\"zirve_connector_module_final_seal_status\": \"SEALED\"" "config declares connector sealed"
require_contains "7-8Z.7.5.4" "$CONFIG_FILE" "\"zirve_dry_run_module_status\": \"SEALED\"" "config declares dry-run module sealed"
require_contains "7-8Z.7.5.5" "$CONFIG_FILE" "\"zirve_provider_live_handoff_gate\": \"READY_FOR_PROVIDER_LIVE_MODULE\"" "config declares provider live handoff gate"
require_contains "7-8Z.7.5.6" "$CONFIG_FILE" "\"zirve_provider_live_module_status\": \"NOT_STARTED\"" "config keeps provider live module not started"
require_contains "7-8Z.7.5.7" "$CONFIG_FILE" "\"real_zirve_api\": false" "config keeps real Zirve API closed"
require_contains "7-8Z.7.5.8" "$CONFIG_FILE" "\"real_file_delivery\": false" "config keeps real file delivery closed"
require_contains "7-8Z.7.5.9" "$CONFIG_FILE" "\"real_delivery_channel\": false" "config keeps real delivery channel closed"
require_contains "7-8Z.7.5.10" "$CONFIG_FILE" "\"real_erp_write\": false" "config keeps real ERP write closed"
require_contains "7-8Z.7.5.11" "$CONFIG_FILE" "\"real_operator_provider_action\": false" "config keeps real operator provider action closed"

require_contains "7-8Z.7.6.1" "$DOC_FILE" "ZIRVE_CONNECTOR_MODULE_FINAL_SEAL_STATUS=SEALED" "doc declares connector final seal"
require_contains "7-8Z.7.6.2" "$DOC_FILE" "ZIRVE_DRY_RUN_MODULE_STATUS=SEALED" "doc declares dry-run module sealed"
require_contains "7-8Z.7.6.3" "$DOC_FILE" "ZIRVE_PROVIDER_LIVE_HANDOFF_GATE=READY_FOR_PROVIDER_LIVE_MODULE" "doc declares provider live handoff gate"
require_contains "7-8Z.7.6.4" "$DOC_FILE" "ZIRVE_PROVIDER_LIVE_MODULE_STATUS=NOT_STARTED" "doc keeps provider live module not started"
require_contains "7-8Z.7.6.5" "$DOC_FILE" "Gerçek Zirve API çağrısı" "doc states real Zirve API remains closed"
require_contains "7-8Z.7.6.6" "$DOC_FILE" "Gerçek operator provider action" "doc states real operator provider action remains closed"
require_contains "7-8Z.7.6.7" "$DOC_FILE" "FAZ 7-8 entegrasyon ailesi master review" "doc declares next integration family review step"

{
  echo
  echo "## Audit Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
    echo "- FAZ_7_8Z_7_ZIRVE_FINAL_CLOSURE_REAL_IMPLEMENTATION_STATUS=PASS"
  else
    echo "- FAZ_7_8Z_7_ZIRVE_FINAL_CLOSURE_REAL_IMPLEMENTATION_STATUS=FAIL"
  fi
} >> "$EVIDENCE_FILE"

echo "===== 7-8Z.7 ZIRVE FINAL CLOSURE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [[ "$FAIL_COUNT" -eq 0 && "$REQUIRED_FAIL" -eq 0 ]]; then
  echo "FAZ_7_8Z_7_ZIRVE_FINAL_CLOSURE_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8Z_7_ZIRVE_FINAL_CLOSURE_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
