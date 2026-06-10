#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_10_parasut_e2e_dry_run_audit.env"

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

echo "# FAZ 7-8P.10 Paraşüt E2E Dry-Run Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.10 PARASUT E2E DRY-RUN REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_CONNECTOR_FLOW_READINESS.md" "7-8P.10.0.1 Documentation artifact"
check_file "configs/faz7/parasut_e2e_dry_run.v1.json" "7-8P.10.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "7-8P.10.0.3 E2E dry-run code"
check_file "internal/platform/integrations/runtime/parasut_e2e_dry_run_test.go" "7-8P.10.0.4 E2E dry-run test code"

check_grep "docs/faz7/FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_CONNECTOR_FLOW_READINESS.md" "FAZ 7-8P.10 Paraşüt End-to-End Dry-Run Scenario / Full Connector Flow Readiness" "7-8P.10.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_CONNECTOR_FLOW_READINESS.md" "7-8P.10.1 Credential + OAuth E2E Bridge" "7-8P.10.1.0 Scope doc credential oauth"
check_grep "docs/faz7/FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_CONNECTOR_FLOW_READINESS.md" "7-8P.10.2 Token Exchange + Token Lifecycle E2E Bridge" "7-8P.10.2.0 Scope doc token lifecycle"
check_grep "docs/faz7/FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_CONNECTOR_FLOW_READINESS.md" "7-8P.10.3 API Client + Data Mapping + ERP Write E2E Bridge" "7-8P.10.3.0 Scope doc API mapping ERP"
check_grep "docs/faz7/FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_CONNECTOR_FLOW_READINESS.md" "7-8P.10.4 Sync Worker + Webhook Trigger E2E Bridge" "7-8P.10.4.0 Scope doc sync webhook"
check_grep "docs/faz7/FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_CONNECTOR_FLOW_READINESS.md" "7-8P.10.5 Audit / Retry / DLQ E2E Bridge" "7-8P.10.5.0 Scope doc audit retry DLQ"
check_grep "docs/faz7/FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_CONNECTOR_FLOW_READINESS.md" "7-8P.10.6 Final Closure" "7-8P.10.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"provider_key": "parasut"' "7-8P.10.0.6 Config provider key"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"real_provider_api_enabled": false' "7-8P.10.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"real_webhook_endpoint_enabled": false' "7-8P.10.0.8 Config real webhook endpoint disabled"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"real_erp_write_enabled": false' "7-8P.10.0.9 Config real ERP write disabled"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"real_queue_trigger_enabled": false' "7-8P.10.0.10 Config real queue trigger disabled"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_READINESS"' "7-8P.10.0.11 Config dependency on webhook trigger"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"credential_oauth_bridge": true' "7-8P.10.1.1 Config credential oauth bridge"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"token_exchange_lifecycle_bridge": true' "7-8P.10.2.1 Config token lifecycle bridge"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"api_client_data_mapping_erp_write_bridge": true' "7-8P.10.3.1 Config API mapping ERP bridge"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"sync_worker_webhook_trigger_bridge": true' "7-8P.10.4.1 Config sync worker webhook bridge"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"audit_retry_dlq_bridge": true' "7-8P.10.5.1 Config audit retry DLQ bridge"
check_grep "configs/faz7/parasut_e2e_dry_run.v1.json" '"idempotency_duplicate_guard": true' "7-8P.10.4.2 Config idempotency duplicate guard"

check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "type ParasutConnectorE2EDryRunInput struct" "7-8P.10.0.12 Code E2E input model"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "type ParasutConnectorE2EDryRunResult struct" "7-8P.10.0.13 Code E2E result model"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "ExecuteParasutConnectorE2EDryRun" "7-8P.10.0.14 Code E2E executor"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "ExecuteParasutConnectorE2EDryRunWithRuntime" "7-8P.10.0.15 Code E2E runtime executor"

check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "ParasutSecretKindClientSecret" "7-8P.10.1.2 Code client secret ref bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "BuildParasutOAuthState" "7-8P.10.1.3 Code OAuth state bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "BuildParasutAuthorizationURL" "7-8P.10.1.4 Code authorization URL bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "HandleParasutOAuthCallback" "7-8P.10.1.5 Code OAuth callback bridge"

check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "PrepareParasutTokenExchangeContract" "7-8P.10.2.2 Code token exchange bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "StoreParasutSimulatedTokenResponse" "7-8P.10.2.3 Code simulated token response bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "TokenStorage" "7-8P.10.2.4 Code token storage result"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "tokenStorage.Lifecycle" "7-8P.10.2.5 Code token lifecycle handoff"

check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "BuildParasutAPIClientContract" "7-8P.10.3.2 Code API client bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "BuildParasutAPIOperationRequest" "7-8P.10.3.3 Code API operation bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "ExecuteParasutAPIDryRun" "7-8P.10.3.4 Code API dry-run bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "BuildParasutSyncWorkerMapping" "7-8P.10.3.5 Code data mapping bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "BuildParasutERPWriteDryRunContract" "7-8P.10.3.6 Code ERP write dry-run bridge"

check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "ExecuteParasutSyncWorkerDryRun" "7-8P.10.4.3 Code sync worker bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "BuildParasutWebhookDryRunSignature" "7-8P.10.4.4 Code webhook signature bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "VerifyParasutWebhookEnvelope" "7-8P.10.4.5 Code webhook verification bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "TriggerParasutSyncWorkerFromWebhook" "7-8P.10.4.6 Code webhook trigger bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "NewInMemoryParasutWebhookIdempotencyStore" "7-8P.10.4.7 Code idempotency store bridge"

check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "RecordParasutAPIOperationAudit" "7-8P.10.5.2 Code API audit bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "RecordParasutMappingAudit" "7-8P.10.5.3 Code mapping audit bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "EvaluateParasutWebhookFailure" "7-8P.10.5.4 Code webhook failure bridge"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "FailureDecision" "7-8P.10.5.5 Code retry DLQ result"

check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "real provider API must remain disabled in e2e dry-run phase" "7-8P.10.6.1 Code real provider API blocker"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "real webhook endpoint must remain disabled in e2e dry-run phase" "7-8P.10.6.2 Code real webhook endpoint blocker"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "real ERP write must remain disabled in e2e dry-run phase" "7-8P.10.6.3 Code real ERP write blocker"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "EvaluateParasutConnectorE2EReadinessGate" "7-8P.10.6.4 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run.go" "PARASUT_FULL_CONNECTOR_E2E_DRY_RUN_READY_WITH_REAL_API_WEBHOOK_ERP_CLOSED" "7-8P.10.6.5 Code final readiness decision"

check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run_test.go" "TestParasutConnectorE2EDryRunFullFlow_7_8P_10_1_To_10_5" "7-8P.10.1-5 Test full E2E flow"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run_test.go" "TestParasutConnectorE2EDuplicateWebhookGuard_7_8P_10_4_X" "7-8P.10.4 Test duplicate webhook guard"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run_test.go" "TestParasutConnectorE2ERealGateBlockers_7_8P_10_6" "7-8P.10.6 Test real gate blockers"
check_grep "internal/platform/integrations/runtime/parasut_e2e_dry_run_test.go" "TestParasutConnectorE2EFinalClosure_7_8P_10_6" "7-8P.10.6 Test final closure"

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

echo "===== 7-8P.10 PARASUT E2E DRY-RUN REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_10_PARASUT_E2E_DRY_RUN_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
