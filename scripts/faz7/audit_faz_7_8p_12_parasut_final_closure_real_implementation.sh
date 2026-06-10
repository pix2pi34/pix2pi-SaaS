#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_12_PARASUT_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_12_parasut_final_closure_audit.env"

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

echo "# FAZ 7-8P.12 Paraşüt Final Closure Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.12 PARASUT FINAL CLOSURE REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_12_PARASUT_CONNECTOR_FINAL_CLOSURE_HANDOFF_GATE.md" "7-8P.12.0.1 Documentation artifact"
check_file "configs/faz7/parasut_connector_final_closure.v1.json" "7-8P.12.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "7-8P.12.0.3 Final closure code"
check_file "internal/platform/integrations/runtime/parasut_connector_final_closure_test.go" "7-8P.12.0.4 Final closure test code"

check_grep "docs/faz7/FAZ_7_8P_12_PARASUT_CONNECTOR_FINAL_CLOSURE_HANDOFF_GATE.md" "FAZ 7-8P.12 Paraşüt Connector Final Closure / Provider Live Module Handoff Gate" "7-8P.12.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_12_PARASUT_CONNECTOR_FINAL_CLOSURE_HANDOFF_GATE.md" "7-8P.12.1 Module Closure Evidence Intake" "7-8P.12.1.0 Scope doc evidence intake"
check_grep "docs/faz7/FAZ_7_8P_12_PARASUT_CONNECTOR_FINAL_CLOSURE_HANDOFF_GATE.md" "7-8P.12.2 Counter / Evidence Validation" "7-8P.12.2.0 Scope doc counter validation"
check_grep "docs/faz7/FAZ_7_8P_12_PARASUT_CONNECTOR_FINAL_CLOSURE_HANDOFF_GATE.md" "7-8P.12.3 Real Gate Safety Validation" "7-8P.12.3.0 Scope doc real gate safety"
check_grep "docs/faz7/FAZ_7_8P_12_PARASUT_CONNECTOR_FINAL_CLOSURE_HANDOFF_GATE.md" "7-8P.12.4 Provider Live Module Handoff Package" "7-8P.12.4.0 Scope doc handoff package"
check_grep "docs/faz7/FAZ_7_8P_12_PARASUT_CONNECTOR_FINAL_CLOSURE_HANDOFF_GATE.md" "7-8P.12.5 Final Connector Seal" "7-8P.12.5.0 Scope doc final seal"
check_grep "docs/faz7/FAZ_7_8P_12_PARASUT_CONNECTOR_FINAL_CLOSURE_HANDOFF_GATE.md" "7-8P.12.6 Final Closure" "7-8P.12.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"provider_key": "parasut"' "7-8P.12.0.6 Config provider key"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"real_provider_api_enabled": false' "7-8P.12.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"real_webhook_endpoint_enabled": false' "7-8P.12.0.8 Config real webhook endpoint disabled"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"real_erp_write_enabled": false' "7-8P.12.0.9 Config real ERP write disabled"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"real_queue_trigger_enabled": false' "7-8P.12.0.10 Config real queue trigger disabled"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"real_token_exchange_enabled": false' "7-8P.12.0.11 Config real token exchange disabled"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"real_token_refresh_enabled": false' "7-8P.12.0.12 Config real token refresh disabled"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"real_retry_job_enabled": false' "7-8P.12.0.13 Config real retry job disabled"

check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION"' "7-8P.12.1.1 Config requires 7-8I"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_PARASUT_CONNECTOR_FOUNDATION"' "7-8P.12.1.2 Config requires 7-8P foundation"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_1_PARASUT_LIVE_CONTRACT"' "7-8P.12.1.3 Config requires 7-8P.1"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_2_PARASUT_TOKEN_VAULT"' "7-8P.12.1.4 Config requires 7-8P.2"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_3_PARASUT_CREDENTIAL_UI"' "7-8P.12.1.5 Config requires 7-8P.3"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_4_PARASUT_OAUTH_FLOW"' "7-8P.12.1.6 Config requires 7-8P.4"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE"' "7-8P.12.1.7 Config requires 7-8P.5"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_6_PARASUT_API_CLIENT"' "7-8P.12.1.8 Config requires 7-8P.6"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_7_PARASUT_DATA_MAPPING"' "7-8P.12.1.9 Config requires 7-8P.7"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_8_PARASUT_SYNC_WORKER"' "7-8P.12.1.10 Config requires 7-8P.8"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER"' "7-8P.12.1.11 Config requires 7-8P.9"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_10_PARASUT_E2E_DRY_RUN"' "7-8P.12.1.12 Config requires 7-8P.10"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"FAZ_7_8P_11_PARASUT_ADMIN_OPS"' "7-8P.12.1.13 Config requires 7-8P.11"

check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"module_final_status_pass_required": true' "7-8P.12.2.1 Config final status pass required"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"module_final_seal_status_sealed_required": true' "7-8P.12.2.2 Config seal status required"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"fail_count_zero_required": true' "7-8P.12.2.3 Config fail count zero"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"required_fail_zero_required": true' "7-8P.12.2.4 Config required fail zero"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"audit_evidence_file_required": true' "7-8P.12.2.5 Config evidence required"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"counter_aggregation_required": true' "7-8P.12.2.6 Config counter aggregation"

check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"provider_live_module_handoff_gate": "READY"' "7-8P.12.4.1 Config provider live handoff gate"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"approval_required": true' "7-8P.12.4.2 Config approval required"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"real_credential_secret_required": true' "7-8P.12.4.3 Config real credential required"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"rollback_safe_disable_required": true' "7-8P.12.4.4 Config rollback safe disable"
check_grep "configs/faz7/parasut_connector_final_closure.v1.json" '"faz_7_9_hold_until_integration_family_done": true' "7-8P.12.5.1 Config FAZ 7-9 hold"

check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "type ParasutConnectorModuleClosureEvidence struct" "7-8P.12.1.14 Code module evidence model"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "RequiredParasutConnectorClosureModules" "7-8P.12.1.15 Code required modules function"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "ParasutRequiredModuleIntegrationRuntime" "7-8P.12.1.16 Code required 7-8I"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "ParasutRequiredModuleAdminOps" "7-8P.12.1.17 Code required admin ops"

check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "EvaluateParasutConnectorFinalClosure" "7-8P.12.2.7 Code final closure evaluator"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "validateParasutModuleClosureEvidence" "7-8P.12.2.8 Code module evidence validator"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "module_final_status_not_pass" "7-8P.12.2.9 Code final status guard"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "module_seal_status_not_sealed" "7-8P.12.2.10 Code seal status guard"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "module_fail_count_not_zero" "7-8P.12.2.11 Code fail count guard"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "module_required_fail_not_zero" "7-8P.12.2.12 Code required fail guard"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "TotalPassCount" "7-8P.12.2.13 Code pass count aggregation"

check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "real_provider_api_must_remain_false_in_final_closure" "7-8P.12.3.9 Code real provider API guard"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "real_webhook_endpoint_must_remain_false_in_final_closure" "7-8P.12.3.10 Code real webhook guard"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "real_erp_write_must_remain_false_in_final_closure" "7-8P.12.3.11 Code real ERP write guard"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "real_queue_trigger_must_remain_false_in_final_closure" "7-8P.12.3.12 Code real queue guard"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "real_token_exchange_must_remain_false_in_final_closure" "7-8P.12.3.13 Code real token exchange guard"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "real_token_refresh_must_remain_false_in_final_closure" "7-8P.12.3.14 Code real token refresh guard"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "real_retry_job_must_remain_false_in_final_closure" "7-8P.12.3.15 Code real retry job guard"

check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "type ParasutProviderLiveHandoffPackage struct" "7-8P.12.4.5 Code handoff package model"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "BuildParasutProviderLiveHandoffPackage" "7-8P.12.4.6 Code handoff package builder"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "READY_FOR_PROVIDER_LIVE_MODULE" "7-8P.12.4.7 Code provider live module gate"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "ApprovalRequired" "7-8P.12.4.8 Code approval marker"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "RollbackSafeDisableRequired" "7-8P.12.4.9 Code rollback marker"

check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "RecordParasutConnectorFinalClosureAudit" "7-8P.12.5.6 Code final closure audit"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "PARASUT_CONNECTOR_FINAL_CLOSURE" "7-8P.12.5.7 Code audit operation"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "EvaluateParasutConnectorFinalClosureReadinessGate" "7-8P.12.6.10 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure.go" "PARASUT_CONNECTOR_FINAL_CLOSURE_READY_FOR_PROVIDER_LIVE_MODULE_HANDOFF" "7-8P.12.6.11 Code final readiness decision"

check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure_test.go" "TestParasutConnectorFinalClosureEvidenceIntake_7_8P_12_1" "7-8P.12.1.18 Test evidence intake"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure_test.go" "TestParasutConnectorCounterEvidenceValidation_7_8P_12_2" "7-8P.12.2.14 Test counter validation"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure_test.go" "TestParasutConnectorRealGateSafetyValidation_7_8P_12_3" "7-8P.12.3.16 Test real gate safety"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure_test.go" "TestParasutProviderLiveModuleHandoffPackage_7_8P_12_4" "7-8P.12.4.10 Test handoff package"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure_test.go" "TestParasutFinalConnectorSealAndAudit_7_8P_12_5" "7-8P.12.5.8 Test final seal audit"
check_grep "internal/platform/integrations/runtime/parasut_connector_final_closure_test.go" "TestParasutConnectorFinalClosureReadinessGate_7_8P_12_6" "7-8P.12.6.12 Test final closure gate"

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

echo "===== 7-8P.12 PARASUT FINAL CLOSURE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_12_PARASUT_FINAL_CLOSURE_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
