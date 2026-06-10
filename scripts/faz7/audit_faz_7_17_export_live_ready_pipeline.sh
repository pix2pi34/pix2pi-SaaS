#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/commercial/liveready/export_live_ready_pipeline.go"
TEST_FILE="internal/platform/commercial/liveready/export_live_ready_pipeline_test.go"
CONFIG_FILE="configs/faz7/export_live_ready_pipeline.json"
DOC_FILE="docs/faz7/commercial/FAZ_7_17_EXPORT_LIVE_READY_PIPELINE.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_17_EXPORT_LIVE_READY_PIPELINE_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

mkdir -p "$(dirname "$EVIDENCE_FILE")"
exec > >(tee "$EVIDENCE_FILE") 2>&1

ok() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 / FAIL ❌"
}

require_file() {
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

require_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

require_not_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && ! grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 7-17 EXPORT LIVE-READY PIPELINE REAL IMPLEMENTATION AUDIT START ====="

require_file "7-17.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-17.6.2 test file exists" "$TEST_FILE"
require_file "7-17.6.3 config file exists" "$CONFIG_FILE"
require_file "7-17.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-17.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE"
require_grep "7-17.6.6 export live-ready mode implemented" "$RUNTIME_FILE" "EXPORT_LIVE_READY_PIPELINE_WITH_REAL_EXPORT_DISABLED"
require_grep "7-17.6.7 export gate implemented" "$RUNTIME_FILE" "type ExportLiveReadyGate struct"
require_grep "7-17.6.8 export input implemented" "$RUNTIME_FILE" "type ExportLiveReadyInput struct"
require_grep "7-17.6.9 export requirement model implemented" "$RUNTIME_FILE" "type ExportLiveReadyRequirement struct"
require_grep "7-17.6.10 export package request implemented" "$RUNTIME_FILE" "type ExportPackagePlanRequest struct"
require_grep "7-17.6.11 export manifest item implemented" "$RUNTIME_FILE" "type ExportManifestItem struct"
require_grep "7-17.6.12 export delivery plan implemented" "$RUNTIME_FILE" "type ExportDeliveryPlan struct"
require_grep "7-17.6.13 export package plan implemented" "$RUNTIME_FILE" "type ExportPackagePlan struct"
require_grep "7-17.6.14 export report implemented" "$RUNTIME_FILE" "type ExportLiveReadyReport struct"
require_grep "7-17.6.15 runtime implemented" "$RUNTIME_FILE" "type ExportLiveReadyRuntime struct"
require_grep "7-17.6.16 build export report implemented" "$RUNTIME_FILE" "BuildExportLiveReadyReport"
require_grep "7-17.6.17 build export package plan implemented" "$RUNTIME_FILE" "BuildExportPackagePlan"
require_grep "7-17.6.18 missing export requirements implemented" "$RUNTIME_FILE" "MissingExportLiveReadyRequirements"
require_grep "7-17.6.19 audit event implemented" "$RUNTIME_FILE" "ExportLiveReadyAuditEvent"

require_grep "7-17.6.20 production export lock implemented" "$RUNTIME_FILE" "PRODUCTION_EXPORT_LOCKED_IN_FAZ_7_17"
require_grep "7-17.6.21 no real export policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_17"
require_grep "7-17.6.22 no real file delivery policy implemented" "$RUNTIME_FILE" "NO_REAL_FILE_DELIVERY_IN_FAZ_7_17"
require_grep "7-17.6.23 no real provider API policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_17"
require_grep "7-17.6.24 no real ERP write policy implemented" "$RUNTIME_FILE" "NO_REAL_ERP_WRITE_IN_FAZ_7_17"
require_grep "7-17.6.25 no real customer data payload policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_PAYLOAD_IN_FAZ_7_17"
require_grep "7-17.6.26 no real operator action policy implemented" "$RUNTIME_FILE" "NO_REAL_OPERATOR_EXPORT_ACTION_IN_FAZ_7_17"

require_grep "7-17.6.27 provider live adapter requirement implemented" "$RUNTIME_FILE" "provider_live_adapter_ready"
require_grep "7-17.6.28 export schema requirement implemented" "$RUNTIME_FILE" "export_schema_ready"
require_grep "7-17.6.29 manifest requirement implemented" "$RUNTIME_FILE" "export_manifest_ready"
require_grep "7-17.6.30 package builder requirement implemented" "$RUNTIME_FILE" "export_package_builder_ready"
require_grep "7-17.6.31 checksum requirement implemented" "$RUNTIME_FILE" "export_checksum_ready"
require_grep "7-17.6.32 delivery plan requirement implemented" "$RUNTIME_FILE" "export_delivery_plan_ready"
require_grep "7-17.6.33 customer consent gate requirement implemented" "$RUNTIME_FILE" "customer_data_consent_gate_ready"
require_grep "7-17.6.34 idempotency requirement implemented" "$RUNTIME_FILE" "export_idempotency_ready"
require_grep "7-17.6.35 retry DLQ requirement implemented" "$RUNTIME_FILE" "export_retry_dlq_ready"
require_grep "7-17.6.36 audit requirement implemented" "$RUNTIME_FILE" "export_audit_ready"
require_grep "7-17.6.37 rollback requirement implemented" "$RUNTIME_FILE" "export_rollback_ready"
require_grep "7-17.6.38 legal approval requirement implemented" "$RUNTIME_FILE" "legal_approval_gate_ready"
require_grep "7-17.6.39 finance approval requirement implemented" "$RUNTIME_FILE" "finance_approval_gate_ready"
require_grep "7-17.6.40 security gate requirement implemented" "$RUNTIME_FILE" "security_gate_ready"
require_grep "7-17.6.41 observability requirement implemented" "$RUNTIME_FILE" "export_observability_ready"

require_grep "7-17.6.42 Paraşüt provider implemented" "$RUNTIME_FILE" "PARASUT"
require_grep "7-17.6.43 Logo provider implemented" "$RUNTIME_FILE" "LOGO"
require_grep "7-17.6.44 Mikro provider implemented" "$RUNTIME_FILE" "MIKRO"
require_grep "7-17.6.45 Zirve provider implemented" "$RUNTIME_FILE" "ZIRVE"

require_grep "7-17.6.46 real customer data export blocker implemented" "$RUNTIME_FILE" "RequestRealCustomerDataExport"
require_grep "7-17.6.47 real file delivery blocker implemented" "$RUNTIME_FILE" "RequestRealFileDelivery"
require_grep "7-17.6.48 real provider API blocker implemented" "$RUNTIME_FILE" "RequestRealProviderAPI"
require_grep "7-17.6.49 real ERP write blocker implemented" "$RUNTIME_FILE" "RequestRealERPWrite"
require_grep "7-17.6.50 real operator export action blocker implemented" "$RUNTIME_FILE" "RequestRealOperatorExportAction"

require_grep "7-17.6.51 idempotency key implemented" "$RUNTIME_FILE" "IdempotencyKey"
require_grep "7-17.6.52 package checksum implemented" "$RUNTIME_FILE" "PackageChecksum"
require_grep "7-17.6.53 checksum function implemented" "$RUNTIME_FILE" "exportChecksum"
require_grep "7-17.6.54 synthetic manifest builder implemented" "$RUNTIME_FILE" "buildSyntheticExportManifest"
require_grep "7-17.6.55 delivery plan builder implemented" "$RUNTIME_FILE" "buildExportDeliveryPlan"
require_grep "7-17.6.56 next module 7-18 implemented" "$RUNTIME_FILE" "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME"

require_grep "7-17.6.57 export report test exists" "$TEST_FILE" "TestSevenSeventeenBuildExportLiveReadyReport"
require_grep "7-17.6.58 missing requirements test exists" "$TEST_FILE" "TestSevenSeventeenMissingExportRequirements"
require_grep "7-17.6.59 export package plan test exists" "$TEST_FILE" "TestSevenSeventeenBuildExportPackagePlanNoRealExport"
require_grep "7-17.6.60 idempotency test exists" "$TEST_FILE" "TestSevenSeventeenExportPackagePlanIdempotency"
require_grep "7-17.6.61 invalid plan test exists" "$TEST_FILE" "TestSevenSeventeenRejectInvalidExportPackagePlan"
require_grep "7-17.6.62 real blocker test exists" "$TEST_FILE" "TestSevenSeventeenRealExportOperationBlockers"
require_grep "7-17.6.63 opened gate reject test exists" "$TEST_FILE" "TestSevenSeventeenGateRejectsOpenedRealExport"
require_grep "7-17.6.64 audit trail test exists" "$TEST_FILE" "TestSevenSeventeenAuditTrail"

require_grep "7-17.6.65 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_17_EXPORT_LIVE_READY_PIPELINE\""
require_grep "7-17.6.66 config mode exists" "$CONFIG_FILE" "\"mode\": \"EXPORT_LIVE_READY_PIPELINE_WITH_REAL_EXPORT_DISABLED\""
require_grep "7-17.6.67 config depends on 7-16 PASS" "$CONFIG_FILE" "\"faz_7_16_provider_live_adapter_readiness_final_status\": \"PASS\""
require_grep "7-17.6.68 config production export false" "$CONFIG_FILE" "\"production_export_allowed\": false"
require_grep "7-17.6.69 config real customer data export false" "$CONFIG_FILE" "\"real_customer_data_export_allowed\": false"
require_grep "7-17.6.70 config real file delivery false" "$CONFIG_FILE" "\"real_file_delivery_allowed\": false"
require_grep "7-17.6.71 config real provider API false" "$CONFIG_FILE" "\"real_provider_api_call_allowed\": false"
require_grep "7-17.6.72 config real ERP write false" "$CONFIG_FILE" "\"real_erp_write_allowed\": false"
require_grep "7-17.6.73 config next module 7-18 exists" "$CONFIG_FILE" "\"next_module\": \"FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME\""

require_grep "7-17.6.74 documentation says live export is not this phase" "$DOC_FILE" "Bu faz live export değildir"
require_grep "7-17.6.75 documentation live-ready requirements exist" "$DOC_FILE" "Live-ready requirements"
require_grep "7-17.6.76 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-17.6.77 runtime does not default production export true" "$RUNTIME_FILE" "ProductionExportAllowed:       true"
require_not_grep "7-17.6.78 runtime does not default real customer export true" "$RUNTIME_FILE" "RealCustomerDataExportAllowed: true"
require_not_grep "7-17.6.79 runtime does not default real file delivery true" "$RUNTIME_FILE" "RealFileDeliveryAllowed:       true"
require_not_grep "7-17.6.80 runtime does not default real provider API true" "$RUNTIME_FILE" "RealProviderAPICallAllowed:    true"
require_not_grep "7-17.6.81 runtime does not default real ERP write true" "$RUNTIME_FILE" "RealERPWriteAllowed:           true"
require_not_grep "7-17.6.82 export plan does not request customer export" "$RUNTIME_FILE" "RealCustomerDataExportRequested: true"
require_not_grep "7-17.6.83 export plan does not include real payload" "$RUNTIME_FILE" "RealCustomerPayloadIncluded:     true"
require_not_grep "7-17.6.84 export plan does not request file delivery" "$RUNTIME_FILE" "RealFileDeliveryRequested:       true"
require_not_grep "7-17.6.85 export plan does not request provider API" "$RUNTIME_FILE" "RealProviderAPICallRequested:    true"
require_not_grep "7-17.6.86 export plan does not request ERP write" "$RUNTIME_FILE" "RealERPWriteRequested:           true"

if go test ./internal/platform/commercial/liveready; then
  ok "7-17.6.87 go test verification PASS"
else
  fail "7-17.6.87 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-17 EXPORT LIVE-READY PIPELINE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
