#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_PARASUT_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_parasut_audit.env"

mkdir -p "$(dirname "$AUDIT_EVIDENCE_FILE")"

: > "$AUDIT_EVIDENCE_FILE"

record_pass() {
  local label="$1"
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$label IMPLEMENTED_OR_PRESENT / OK ✅"
  echo "- $label IMPLEMENTED_OR_PRESENT / OK" >> "$AUDIT_EVIDENCE_FILE"
}

record_fail() {
  local label="$1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$label REQUIRED_FAIL / MISSING ❌"
  echo "- $label REQUIRED_FAIL / MISSING" >> "$AUDIT_EVIDENCE_FILE"
}

check_file() {
  local path="$1"
  local label="$2"
  if [ -f "$path" ]; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

check_grep() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if [ -f "$path" ] && grep -Fq "$pattern" "$path"; then
    record_pass "$label"
  else
    record_fail "$label"
  fi
}

echo "# FAZ 7-8P Paraşüt Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P PARASUT REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_PARASUT_CONNECTOR_MODULE.md" "7-8P.0.1 Documentation artifact"
check_file "configs/faz7/parasut_connector.v1.json" "7-8P.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_connector.go" "7-8P.0.3 Paraşüt connector code"
check_file "internal/platform/integrations/runtime/parasut_connector_test.go" "7-8P.0.4 Paraşüt connector test code"

check_grep "docs/faz7/FAZ_7_8P_PARASUT_CONNECTOR_MODULE.md" "FAZ 7-8P Paraşüt Connector Module Foundation" "7-8P.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_PARASUT_CONNECTOR_MODULE.md" "7-8P.1 Paraşüt Connector Config / Provider Identity" "7-8P.1.0 Scope doc config identity"
check_grep "docs/faz7/FAZ_7_8P_PARASUT_CONNECTOR_MODULE.md" "7-8P.2 Paraşüt Adapter SDK Bridge" "7-8P.2.0 Scope doc adapter bridge"
check_grep "docs/faz7/FAZ_7_8P_PARASUT_CONNECTOR_MODULE.md" "7-8P.3 Paraşüt Data Mapping Foundation" "7-8P.3.0 Scope doc data mapping"
check_grep "docs/faz7/FAZ_7_8P_PARASUT_CONNECTOR_MODULE.md" "7-8P.4 Paraşüt Webhook Bridge" "7-8P.4.0 Scope doc webhook bridge"
check_grep "docs/faz7/FAZ_7_8P_PARASUT_CONNECTOR_MODULE.md" "7-8P.5 Paraşüt Failure / Retry / DLQ Bridge" "7-8P.5.0 Scope doc retry DLQ"
check_grep "docs/faz7/FAZ_7_8P_PARASUT_CONNECTOR_MODULE.md" "7-8P.6 Paraşüt Connector Final Closure / Provider Handoff Gate" "7-8P.6.0 Scope doc final gate"

check_grep "configs/faz7/parasut_connector.v1.json" '"provider_key": "parasut"' "7-8P.1.1 Config provider key"
check_grep "configs/faz7/parasut_connector.v1.json" '"production_real_provider_enabled": false' "7-8P.1.2 Config production gate closed"
check_grep "configs/faz7/parasut_connector.v1.json" '"enabled_environment": "SIMULATION"' "7-8P.1.3 Config simulation mode"
check_grep "configs/faz7/parasut_connector.v1.json" '"invoice.pull"' "7-8P.1.4 Config invoice pull capability"
check_grep "configs/faz7/parasut_connector.v1.json" '"invoice.push"' "7-8P.1.5 Config invoice push capability"
check_grep "configs/faz7/parasut_connector.v1.json" '"customer.sync"' "7-8P.1.6 Config customer sync capability"
check_grep "configs/faz7/parasut_connector.v1.json" '"product.sync"' "7-8P.1.7 Config product sync capability"
check_grep "configs/faz7/parasut_connector.v1.json" '"webhook.verify"' "7-8P.1.8 Config webhook verify capability"
check_grep "configs/faz7/parasut_connector.v1.json" '"FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION"' "7-8P.1.9 Config dependency on 7-8I"

check_grep "internal/platform/integrations/runtime/parasut_connector.go" "const ParasutProviderKey = \"parasut\"" "7-8P.1.10 Code provider key constant"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "type ParasutConnectorConfig struct" "7-8P.1.11 Code connector config model"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "ParasutEnvironmentSimulation" "7-8P.1.12 Code simulation environment"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "ParasutEnvironmentSandbox" "7-8P.1.13 Code sandbox environment"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "ParasutEnvironmentProduction" "7-8P.1.14 Code production environment"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "ValidateParasutConnectorConfig" "7-8P.1.15 Code config validator"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "parasut production provider gate is closed" "7-8P.1.16 Code production gate closed"

check_grep "internal/platform/integrations/runtime/parasut_connector.go" "type ParasutConnectorAdapter struct" "7-8P.2.1 Code adapter model"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "NewParasutConnectorAdapter" "7-8P.2.2 Code adapter constructor"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "func (adapter *ParasutConnectorAdapter) ProviderKey()" "7-8P.2.3 Code ProviderKey interface method"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "func (adapter *ParasutConnectorAdapter) Capabilities()" "7-8P.2.4 Code Capabilities interface method"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "func (adapter *ParasutConnectorAdapter) Execute" "7-8P.2.5 Code Execute interface method"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "ConnectorOperationPullInvoice" "7-8P.2.6 Code pull invoice operation"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "ConnectorOperationPushInvoice" "7-8P.2.7 Code push invoice operation"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "ConnectorOperationSyncCustomer" "7-8P.2.8 Code sync customer operation"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "ConnectorOperationSyncProduct" "7-8P.2.9 Code sync product operation"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "ConnectorOperationVerifyWebhook" "7-8P.2.10 Code verify webhook operation"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "simulatedProviderTransactionID" "7-8P.2.11 Code simulated provider transaction trace"

check_grep "internal/platform/integrations/runtime/parasut_connector.go" "type ParasutInvoiceDraftRequest struct" "7-8P.3.1 Code invoice draft request"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "type ParasutInvoiceDraft struct" "7-8P.3.2 Code invoice draft model"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "BuildParasutInvoiceDraft" "7-8P.3.3 Code invoice draft mapper"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "AmountMinor" "7-8P.3.4 Code amount minor unit guard"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "CustomerTaxNo" "7-8P.3.5 Code customer tax no field"

check_grep "internal/platform/integrations/runtime/parasut_connector.go" "type ParasutWebhookBridge struct" "7-8P.4.1 Code webhook bridge"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "NewParasutWebhookBridge" "7-8P.4.2 Code webhook bridge constructor"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "BuildParasutWebhookSignature" "7-8P.4.3 Code webhook signature bridge"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "Verify(req ExternalEventIntakeRequest)" "7-8P.4.4 Code webhook verify bridge"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "DefaultWebhookIntakeRuntime" "7-8P.4.5 Code 7-8I webhook intake runtime bridge"

check_grep "internal/platform/integrations/runtime/parasut_connector_test.go" "TestParasutFailureRetryDLQBridge_7_8P_5" "7-8P.5.1 Test retry DLQ bridge"
check_grep "internal/platform/integrations/runtime/parasut_connector_test.go" "PARASUT_PROVIDER_TIMEOUT" "7-8P.5.2 Test provider timeout failure code"
check_grep "internal/platform/integrations/runtime/parasut_connector_test.go" "CreateDLQMessage" "7-8P.5.3 Test DLQ message creation"
check_grep "internal/platform/integrations/runtime/parasut_connector_test.go" "FailureKindPoison" "7-8P.5.4 Test poison message bridge"

check_grep "internal/platform/integrations/runtime/parasut_connector.go" "type ParasutConnectorModuleGateInput struct" "7-8P.6.1 Code final gate input"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "EvaluateParasutConnectorModuleGate" "7-8P.6.2 Code final gate evaluator"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "PARASUT_CONNECTOR_FOUNDATION_READY" "7-8P.6.3 Code ready decision"
check_grep "internal/platform/integrations/runtime/parasut_connector.go" "parasut_production_gate_must_remain_closed" "7-8P.6.4 Code production blocker"

check_grep "internal/platform/integrations/runtime/parasut_connector_test.go" "TestParasutConnectorConfigProviderIdentity_7_8P_1" "7-8P.1.17 Test config provider identity"
check_grep "internal/platform/integrations/runtime/parasut_connector_test.go" "TestParasutAdapterSDKBridge_7_8P_2" "7-8P.2.12 Test adapter SDK bridge"
check_grep "internal/platform/integrations/runtime/parasut_connector_test.go" "TestParasutDataMappingFoundation_7_8P_3" "7-8P.3.6 Test data mapping"
check_grep "internal/platform/integrations/runtime/parasut_connector_test.go" "TestParasutWebhookBridge_7_8P_4" "7-8P.4.6 Test webhook bridge"
check_grep "internal/platform/integrations/runtime/parasut_connector_test.go" "TestParasutConnectorFinalClosureGate_7_8P_6" "7-8P.6.5 Test final closure gate"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_STATUS="PASS"
else
  REAL_STATUS="FAIL"
fi

{
  echo "AUDIT_PASS_COUNT=$PASS_COUNT"
  echo "AUDIT_FAIL_COUNT=$FAIL_COUNT"
  echo "AUDIT_REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "AUDIT_OPTIONAL_WARN=$OPTIONAL_WARN"
  echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
  echo "AUDIT_REAL_STATUS=$REAL_STATUS"
} > "$AUDIT_ENV_FILE"

echo "===== 7-8P PARASUT REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_PARASUT_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
