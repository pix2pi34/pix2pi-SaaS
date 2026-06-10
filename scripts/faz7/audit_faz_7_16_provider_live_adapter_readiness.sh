#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/commercial/liveready/provider_live_adapter_readiness.go"
TEST_FILE="internal/platform/commercial/liveready/provider_live_adapter_readiness_test.go"
CONFIG_FILE="configs/faz7/provider_live_adapter_readiness.json"
DOC_FILE="docs/faz7/commercial/FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-16 PROVIDER LIVE ADAPTER READINESS REAL IMPLEMENTATION AUDIT START ====="

require_file "7-16.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-16.6.2 test file exists" "$TEST_FILE"
require_file "7-16.6.3 config file exists" "$CONFIG_FILE"
require_file "7-16.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-16.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS"
require_grep "7-16.6.6 provider live-ready mode implemented" "$RUNTIME_FILE" "PROVIDER_LIVE_ADAPTER_READY_WITH_REAL_PROVIDER_API_DISABLED"
require_grep "7-16.6.7 provider gate implemented" "$RUNTIME_FILE" "type ProviderLiveAdapterReadinessGate struct"
require_grep "7-16.6.8 provider input implemented" "$RUNTIME_FILE" "type ProviderLiveAdapterReadinessInput struct"
require_grep "7-16.6.9 provider requirement model implemented" "$RUNTIME_FILE" "type ProviderLiveAdapterRequirement struct"
require_grep "7-16.6.10 secret contract implemented" "$RUNTIME_FILE" "type ProviderSecretContract struct"
require_grep "7-16.6.11 endpoint contract implemented" "$RUNTIME_FILE" "type ProviderEndpointContract struct"
require_grep "7-16.6.12 operation plan request implemented" "$RUNTIME_FILE" "type ProviderOperationPlanRequest struct"
require_grep "7-16.6.13 operation plan implemented" "$RUNTIME_FILE" "type ProviderOperationPlan struct"
require_grep "7-16.6.14 provider report implemented" "$RUNTIME_FILE" "type ProviderLiveAdapterReadinessReport struct"
require_grep "7-16.6.15 runtime implemented" "$RUNTIME_FILE" "type ProviderLiveAdapterReadinessRuntime struct"
require_grep "7-16.6.16 build provider report implemented" "$RUNTIME_FILE" "BuildProviderLiveAdapterReadinessReport"
require_grep "7-16.6.17 build operation plan implemented" "$RUNTIME_FILE" "BuildProviderOperationPlan"
require_grep "7-16.6.18 missing provider requirements implemented" "$RUNTIME_FILE" "MissingProviderLiveAdapterRequirements"
require_grep "7-16.6.19 audit event implemented" "$RUNTIME_FILE" "ProviderLiveAdapterAuditEvent"

require_grep "7-16.6.20 production provider lock implemented" "$RUNTIME_FILE" "PRODUCTION_PROVIDER_API_LOCKED_IN_FAZ_7_16"
require_grep "7-16.6.21 no real provider API policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_16"
require_grep "7-16.6.22 no real secret use policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_SECRET_USE_IN_FAZ_7_16"
require_grep "7-16.6.23 no real webhook policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_WEBHOOK_INGESTION_IN_FAZ_7_16"
require_grep "7-16.6.24 no real file delivery policy implemented" "$RUNTIME_FILE" "NO_REAL_FILE_DELIVERY_IN_FAZ_7_16"
require_grep "7-16.6.25 no real ERP write policy implemented" "$RUNTIME_FILE" "NO_REAL_ERP_WRITE_IN_FAZ_7_16"
require_grep "7-16.6.26 no real customer data policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_16"
require_grep "7-16.6.27 no real operator action policy implemented" "$RUNTIME_FILE" "NO_REAL_OPERATOR_PROVIDER_ACTION_IN_FAZ_7_16"

require_grep "7-16.6.28 payment capture requirement implemented" "$RUNTIME_FILE" "payment_capture_live_ready"
require_grep "7-16.6.29 adapter interface requirement implemented" "$RUNTIME_FILE" "provider_adapter_interface_ready"
require_grep "7-16.6.30 secret contract requirement implemented" "$RUNTIME_FILE" "provider_secret_contract_ready"
require_grep "7-16.6.31 endpoint contract requirement implemented" "$RUNTIME_FILE" "provider_endpoint_contract_ready"
require_grep "7-16.6.32 operation contract requirement implemented" "$RUNTIME_FILE" "provider_operation_contract_ready"
require_grep "7-16.6.33 webhook contract requirement implemented" "$RUNTIME_FILE" "provider_webhook_contract_ready"
require_grep "7-16.6.34 retry DLQ requirement implemented" "$RUNTIME_FILE" "provider_retry_dlq_ready"
require_grep "7-16.6.35 idempotency requirement implemented" "$RUNTIME_FILE" "provider_idempotency_ready"
require_grep "7-16.6.36 audit requirement implemented" "$RUNTIME_FILE" "provider_audit_ready"
require_grep "7-16.6.37 rollback requirement implemented" "$RUNTIME_FILE" "provider_rollback_ready"
require_grep "7-16.6.38 legal approval requirement implemented" "$RUNTIME_FILE" "legal_approval_gate_ready"
require_grep "7-16.6.39 finance approval requirement implemented" "$RUNTIME_FILE" "finance_approval_gate_ready"
require_grep "7-16.6.40 security gate requirement implemented" "$RUNTIME_FILE" "security_gate_ready"
require_grep "7-16.6.41 observability requirement implemented" "$RUNTIME_FILE" "provider_observability_ready"

require_grep "7-16.6.42 Paraşüt provider implemented" "$RUNTIME_FILE" "PARASUT"
require_grep "7-16.6.43 Logo provider implemented" "$RUNTIME_FILE" "LOGO"
require_grep "7-16.6.44 Mikro provider implemented" "$RUNTIME_FILE" "MIKRO"
require_grep "7-16.6.45 Zirve provider implemented" "$RUNTIME_FILE" "ZIRVE"

require_grep "7-16.6.46 real provider API blocker implemented" "$RUNTIME_FILE" "RequestRealProviderAPI"
require_grep "7-16.6.47 real secret use blocker implemented" "$RUNTIME_FILE" "RequestRealProviderSecretUse"
require_grep "7-16.6.48 real webhook blocker implemented" "$RUNTIME_FILE" "RequestRealWebhookIngestion"
require_grep "7-16.6.49 real file delivery blocker implemented" "$RUNTIME_FILE" "RequestRealFileDelivery"
require_grep "7-16.6.50 real ERP write blocker implemented" "$RUNTIME_FILE" "RequestRealERPWrite"
require_grep "7-16.6.51 real operator provider action blocker implemented" "$RUNTIME_FILE" "RequestRealOperatorProviderAction"

require_grep "7-16.6.52 idempotency key implemented" "$RUNTIME_FILE" "IdempotencyKey"
require_grep "7-16.6.53 secret contract status implemented" "$RUNTIME_FILE" "SecretContractStatus"
require_grep "7-16.6.54 endpoint contract status implemented" "$RUNTIME_FILE" "EndpointContractStatus"
require_grep "7-16.6.55 operation contract status implemented" "$RUNTIME_FILE" "OperationContractStatus"
require_grep "7-16.6.56 webhook contract status implemented" "$RUNTIME_FILE" "WebhookContractStatus"
require_grep "7-16.6.57 next module 7-17 implemented" "$RUNTIME_FILE" "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE"

require_grep "7-16.6.58 provider report test exists" "$TEST_FILE" "TestSevenSixteenBuildProviderLiveAdapterReadinessReport"
require_grep "7-16.6.59 missing requirements test exists" "$TEST_FILE" "TestSevenSixteenMissingProviderRequirements"
require_grep "7-16.6.60 provider operation plan test exists" "$TEST_FILE" "TestSevenSixteenBuildProviderOperationPlanNoRealAPI"
require_grep "7-16.6.61 idempotency test exists" "$TEST_FILE" "TestSevenSixteenProviderOperationPlanIdempotency"
require_grep "7-16.6.62 invalid provider test exists" "$TEST_FILE" "TestSevenSixteenRejectInvalidProviderPlan"
require_grep "7-16.6.63 real blocker test exists" "$TEST_FILE" "TestSevenSixteenRealProviderOperationBlockers"
require_grep "7-16.6.64 opened gate reject test exists" "$TEST_FILE" "TestSevenSixteenGateRejectsOpenedRealProviderAPI"
require_grep "7-16.6.65 audit trail test exists" "$TEST_FILE" "TestSevenSixteenAuditTrail"

require_grep "7-16.6.66 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS\""
require_grep "7-16.6.67 config mode exists" "$CONFIG_FILE" "\"mode\": \"PROVIDER_LIVE_ADAPTER_READY_WITH_REAL_PROVIDER_API_DISABLED\""
require_grep "7-16.6.68 config depends on 7-15 PASS" "$CONFIG_FILE" "\"faz_7_15_payment_capture_live_ready_runtime_final_status\": \"PASS\""
require_grep "7-16.6.69 config production provider false" "$CONFIG_FILE" "\"production_provider_api_allowed\": false"
require_grep "7-16.6.70 config real provider API false" "$CONFIG_FILE" "\"real_provider_api_call_allowed\": false"
require_grep "7-16.6.71 config real secret use false" "$CONFIG_FILE" "\"real_provider_secret_use_allowed\": false"
require_grep "7-16.6.72 config real webhook false" "$CONFIG_FILE" "\"real_webhook_ingestion_allowed\": false"
require_grep "7-16.6.73 config real file delivery false" "$CONFIG_FILE" "\"real_file_delivery_allowed\": false"
require_grep "7-16.6.74 config real ERP write false" "$CONFIG_FILE" "\"real_erp_write_allowed\": false"
require_grep "7-16.6.75 config next module 7-17 exists" "$CONFIG_FILE" "\"next_module\": \"FAZ_7_17_EXPORT_LIVE_READY_PIPELINE\""

require_grep "7-16.6.76 documentation says live provider is not this phase" "$DOC_FILE" "Bu faz live provider değildir"
require_grep "7-16.6.77 documentation live-ready requirements exist" "$DOC_FILE" "Live-ready requirements"
require_grep "7-16.6.78 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-16.6.79 runtime does not default production provider API true" "$RUNTIME_FILE" "ProductionProviderAPIAllowed: true"
require_not_grep "7-16.6.80 runtime does not default real provider API true" "$RUNTIME_FILE" "RealProviderAPICallAllowed:   true"
require_not_grep "7-16.6.81 runtime does not default real secret use true" "$RUNTIME_FILE" "RealProviderSecretUseAllowed: true"
require_not_grep "7-16.6.82 runtime does not default real webhook true" "$RUNTIME_FILE" "RealWebhookIngestionAllowed:  true"
require_not_grep "7-16.6.83 runtime does not default real file delivery true" "$RUNTIME_FILE" "RealFileDeliveryAllowed:      true"
require_not_grep "7-16.6.84 operation plan does not request real provider API" "$RUNTIME_FILE" "RealProviderAPICallRequested:    true"
require_not_grep "7-16.6.85 operation plan does not request real secret use" "$RUNTIME_FILE" "RealProviderSecretUseRequested:  true"
require_not_grep "7-16.6.86 operation plan does not request real ERP write" "$RUNTIME_FILE" "RealERPWriteRequested:           true"

if go test ./internal/platform/commercial/liveready; then
  ok "7-16.6.87 go test verification PASS"
else
  fail "7-16.6.87 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-16 PROVIDER LIVE ADAPTER READINESS REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
