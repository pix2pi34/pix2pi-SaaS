#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_8_PARASUT_SYNC_WORKER_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_8_parasut_sync_worker_audit.env"

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

echo "# FAZ 7-8P.8 Paraşüt Sync Worker Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.8 PARASUT SYNC WORKER REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_8_PARASUT_SYNC_WORKER_DRY_RUN_READINESS.md" "7-8P.8.0.1 Documentation artifact"
check_file "configs/faz7/parasut_sync_worker.v1.json" "7-8P.8.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_sync_worker.go" "7-8P.8.0.3 Sync worker code"
check_file "internal/platform/integrations/runtime/parasut_sync_worker_test.go" "7-8P.8.0.4 Sync worker test code"

check_grep "docs/faz7/FAZ_7_8P_8_PARASUT_SYNC_WORKER_DRY_RUN_READINESS.md" "FAZ 7-8P.8 Paraşüt Sync Worker / Job Orchestration Dry-Run Readiness" "7-8P.8.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_8_PARASUT_SYNC_WORKER_DRY_RUN_READINESS.md" "7-8P.8.1 Sync Job Schedule / Worker Context" "7-8P.8.1.0 Scope doc schedule"
check_grep "docs/faz7/FAZ_7_8P_8_PARASUT_SYNC_WORKER_DRY_RUN_READINESS.md" "7-8P.8.2 Tenant Integration Enabled / Token Lifecycle Gate" "7-8P.8.2.0 Scope doc enabled token gate"
check_grep "docs/faz7/FAZ_7_8P_8_PARASUT_SYNC_WORKER_DRY_RUN_READINESS.md" "7-8P.8.3 API Operation + Mapping Orchestration" "7-8P.8.3.0 Scope doc API mapping orchestration"
check_grep "docs/faz7/FAZ_7_8P_8_PARASUT_SYNC_WORKER_DRY_RUN_READINESS.md" "7-8P.8.4 ERP Write Dry-Run Orchestration" "7-8P.8.4.0 Scope doc ERP write"
check_grep "docs/faz7/FAZ_7_8P_8_PARASUT_SYNC_WORKER_DRY_RUN_READINESS.md" "7-8P.8.5 Retry / DLQ / Failure Orchestration" "7-8P.8.5.0 Scope doc retry DLQ"
check_grep "docs/faz7/FAZ_7_8P_8_PARASUT_SYNC_WORKER_DRY_RUN_READINESS.md" "7-8P.8.6 Final Closure" "7-8P.8.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_sync_worker.v1.json" '"provider_key": "parasut"' "7-8P.8.0.6 Config provider key"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"real_provider_api_enabled": false' "7-8P.8.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"real_erp_write_enabled": false' "7-8P.8.0.8 Config real ERP write disabled"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"real_scheduler_enabled": false' "7-8P.8.0.9 Config real scheduler disabled"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"real_queue_consumer_enabled": false' "7-8P.8.0.10 Config real queue consumer disabled"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"FAZ_7_8P_7_PARASUT_DATA_MAPPING_ERP_SYNC_READINESS"' "7-8P.8.0.11 Config dependency on data mapping"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"schedule_interval_seconds_default": 900' "7-8P.8.1.1 Config schedule interval"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"tenant_integration_enabled_required": true' "7-8P.8.2.1 Config tenant integration enabled"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"refresh_required_token_blocks_api_operation": true' "7-8P.8.2.2 Config refresh required blocks API"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"api_client_contract_bridge": true' "7-8P.8.3.1 Config API client bridge"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"customer_mapping_bridge": true' "7-8P.8.3.2 Config customer mapping bridge"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"erp_write_dry_run_bridge": true' "7-8P.8.4.1 Config ERP write dry-run bridge"
check_grep "configs/faz7/parasut_sync_worker.v1.json" '"unknown_provider_error_dlq": true' "7-8P.8.5.1 Config unknown provider DLQ"

check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "type ParasutSyncJobSchedule struct" "7-8P.8.1.2 Code sync job schedule model"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "BuildParasutSyncJobSchedule" "7-8P.8.1.3 Code sync job schedule builder"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "real scheduler must remain disabled" "7-8P.8.1.4 Code scheduler blocker"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "real queue consumer must remain disabled" "7-8P.8.1.5 Code queue consumer blocker"

check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "type ParasutTenantIntegrationState struct" "7-8P.8.2.3 Code tenant integration state"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "ValidateParasutTenantIntegrationEnabled" "7-8P.8.2.4 Code integration enabled validator"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "EvaluateParasutAccessTokenRefreshNeed" "7-8P.8.2.5 Code token lifecycle gate"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "ParasutSyncWorkerStatusTokenRefreshRequired" "7-8P.8.2.6 Code token refresh required status"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "ParasutSyncWorkerStatusTokenRevoked" "7-8P.8.2.7 Code token revoked status"

check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "ExecuteParasutSyncWorkerDryRun" "7-8P.8.3.3 Code sync worker dry-run executor"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "BuildParasutAPIClientContract" "7-8P.8.3.4 Code API client bridge"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "BuildParasutAPIOperationRequest" "7-8P.8.3.5 Code API operation bridge"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "ExecuteParasutAPIDryRun" "7-8P.8.3.6 Code API dry-run bridge"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "BuildParasutSyncWorkerMapping" "7-8P.8.3.7 Code mapping bridge"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "BuildParasutCustomerERPSync" "7-8P.8.3.8 Code customer mapping call"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "BuildParasutProductERPSync" "7-8P.8.3.9 Code product mapping call"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "BuildParasutInvoiceERPSync" "7-8P.8.3.10 Code invoice mapping call"

check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "BuildParasutERPWriteDryRunContract" "7-8P.8.4.2 Code ERP write dry-run bridge"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "RecordParasutMappingAudit" "7-8P.8.4.3 Code mapping audit bridge"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "RecordParasutAPIOperationAudit" "7-8P.8.4.4 Code API audit bridge"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "real ERP write must remain disabled" "7-8P.8.4.5 Code real ERP write blocker"

check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "EvaluateParasutSyncWorkerFailure" "7-8P.8.5.2 Code failure evaluator"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "EvaluateParasutAPIOperationFailure" "7-8P.8.5.3 Code API failure bridge"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "DLQReady" "7-8P.8.5.4 Code DLQ readiness marker"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "RetryDecision" "7-8P.8.5.5 Code retry decision bridge"

check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "EvaluateParasutSyncWorkerReadinessGate" "7-8P.8.6.1 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "PARASUT_SYNC_WORKER_DRY_RUN_READY_WITH_REAL_API_AND_ERP_WRITE_CLOSED" "7-8P.8.6.2 Code final readiness decision"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "real_provider_api_must_remain_false_in_sync_worker_phase" "7-8P.8.6.3 Code real provider API blocker"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "real_erp_write_must_remain_false_in_sync_worker_phase" "7-8P.8.6.4 Code real ERP write blocker"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "real_scheduler_must_remain_false_in_sync_worker_phase" "7-8P.8.6.5 Code real scheduler blocker"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker.go" "real_queue_consumer_must_remain_false_in_sync_worker_phase" "7-8P.8.6.6 Code real queue blocker"

check_grep "internal/platform/integrations/runtime/parasut_sync_worker_test.go" "TestParasutSyncJobScheduleWorkerContext_7_8P_8_1" "7-8P.8.1.11 Test sync job schedule"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker_test.go" "TestParasutTenantIntegrationEnabledTokenLifecycleGate_7_8P_8_2" "7-8P.8.2.8 Test enabled token gate"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker_test.go" "TestParasutAPIOperationMappingOrchestration_7_8P_8_3" "7-8P.8.3.11 Test API mapping orchestration"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker_test.go" "TestParasutERPWriteDryRunOrchestration_7_8P_8_4" "7-8P.8.4.6 Test ERP write orchestration"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker_test.go" "TestParasutRetryDLQFailureOrchestration_7_8P_8_5" "7-8P.8.5.6 Test retry DLQ orchestration"
check_grep "internal/platform/integrations/runtime/parasut_sync_worker_test.go" "TestParasutSyncWorkerFinalClosure_7_8P_8_6" "7-8P.8.6.7 Test final closure"

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

echo "===== 7-8P.8 PARASUT SYNC WORKER REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_8_PARASUT_SYNC_WORKER_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
