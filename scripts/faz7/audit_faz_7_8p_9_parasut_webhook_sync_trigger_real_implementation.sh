#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_9_parasut_webhook_sync_trigger_audit.env"

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

echo "# FAZ 7-8P.9 Paraşüt Webhook Sync Trigger Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.9 PARASUT WEBHOOK SYNC TRIGGER REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_READINESS.md" "7-8P.9.0.1 Documentation artifact"
check_file "configs/faz7/parasut_webhook_sync_trigger.v1.json" "7-8P.9.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "7-8P.9.0.3 Webhook sync trigger code"
check_file "internal/platform/integrations/runtime/parasut_webhook_sync_trigger_test.go" "7-8P.9.0.4 Webhook sync trigger test code"

check_grep "docs/faz7/FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_READINESS.md" "FAZ 7-8P.9 Paraşüt Webhook Event → Sync Trigger Readiness" "7-8P.9.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_READINESS.md" "7-8P.9.1 Webhook Intake / Signature Contract" "7-8P.9.1.0 Scope doc webhook intake"
check_grep "docs/faz7/FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_READINESS.md" "7-8P.9.2 Event Type Mapping Contract" "7-8P.9.2.0 Scope doc event mapping"
check_grep "docs/faz7/FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_READINESS.md" "7-8P.9.3 Idempotency / Duplicate Guard" "7-8P.9.3.0 Scope doc idempotency"
check_grep "docs/faz7/FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_READINESS.md" "7-8P.9.4 Sync Worker Trigger Bridge" "7-8P.9.4.0 Scope doc sync worker trigger"
check_grep "docs/faz7/FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_READINESS.md" "7-8P.9.5 Retry / DLQ / Audit Orchestration" "7-8P.9.5.0 Scope doc retry DLQ audit"
check_grep "docs/faz7/FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_READINESS.md" "7-8P.9.6 Final Closure" "7-8P.9.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"provider_key": "parasut"' "7-8P.9.0.6 Config provider key"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"real_webhook_endpoint_enabled": false' "7-8P.9.0.7 Config real webhook endpoint disabled"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"real_provider_api_enabled": false' "7-8P.9.0.8 Config real provider API disabled"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"real_erp_write_enabled": false' "7-8P.9.0.9 Config real ERP write disabled"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"real_queue_trigger_enabled": false' "7-8P.9.0.10 Config real queue trigger disabled"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"FAZ_7_8P_8_PARASUT_SYNC_WORKER_DRY_RUN_READINESS"' "7-8P.9.0.11 Config dependency on sync worker"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"signature_required": true' "7-8P.9.1.1 Config signature required"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"timestamp_skew_guard_seconds": 300' "7-8P.9.1.2 Config timestamp skew guard"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"customer.updated": "SYNC_CUSTOMER"' "7-8P.9.2.1 Config customer event mapping"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"product.updated": "SYNC_PRODUCT"' "7-8P.9.2.2 Config product event mapping"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"sales_invoice.created": "PULL_INVOICE"' "7-8P.9.2.3 Config invoice event mapping"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"duplicate_event_ignored_safely": true' "7-8P.9.3.1 Config duplicate ignored"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"sync_worker_dry_run_bridge": true' "7-8P.9.4.1 Config sync worker bridge"
check_grep "configs/faz7/parasut_webhook_sync_trigger.v1.json" '"unknown_provider_error_dlq": true' "7-8P.9.5.1 Config unknown provider DLQ"

check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "type ParasutWebhookEnvelope struct" "7-8P.9.1.3 Code webhook envelope"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "BuildParasutWebhookDryRunSignature" "7-8P.9.1.4 Code dry-run signature builder"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "VerifyParasutWebhookEnvelope" "7-8P.9.1.5 Code webhook verifier"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "hmac.New" "7-8P.9.1.6 Code HMAC verification"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "webhook timestamp skew exceeded" "7-8P.9.1.7 Code timestamp skew guard"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "real webhook endpoint must remain disabled" "7-8P.9.1.8 Code real webhook endpoint blocker"

check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "type ParasutWebhookEventMapping struct" "7-8P.9.2.4 Code event mapping model"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "MapParasutWebhookEventToSync" "7-8P.9.2.5 Code event mapping function"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "ConnectorOperationSyncCustomer" "7-8P.9.2.6 Code customer sync operation"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "ConnectorOperationSyncProduct" "7-8P.9.2.7 Code product sync operation"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "ConnectorOperationPullInvoice" "7-8P.9.2.8 Code invoice pull operation"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "unsupported parasut webhook event type" "7-8P.9.2.9 Code unsupported event rejection"

check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "type InMemoryParasutWebhookIdempotencyStore struct" "7-8P.9.3.2 Code idempotency store"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "BuildParasutWebhookIdempotencyKey" "7-8P.9.3.3 Code idempotency key builder"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "RecordFirstSeen" "7-8P.9.3.4 Code first seen duplicate guard"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "ParasutWebhookStatusDuplicateIgnored" "7-8P.9.3.5 Code duplicate ignored status"

check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "type ParasutWebhookSyncTriggerRequest struct" "7-8P.9.4.2 Code trigger request"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "TriggerParasutSyncWorkerFromWebhook" "7-8P.9.4.3 Code sync worker trigger"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "BuildParasutSyncJobSchedule" "7-8P.9.4.4 Code sync schedule bridge"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "ExecuteParasutSyncWorkerDryRun" "7-8P.9.4.5 Code worker dry-run bridge"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "webhook source object type mismatch" "7-8P.9.4.6 Code source object mismatch guard"

check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "RecordParasutWebhookTriggerAudit" "7-8P.9.5.2 Code webhook trigger audit"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "EvaluateParasutWebhookFailure" "7-8P.9.5.3 Code webhook failure evaluator"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "MapParasutProviderError" "7-8P.9.5.4 Code provider error mapping bridge"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "EvaluateRetry" "7-8P.9.5.5 Code retry decision bridge"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "DLQReady" "7-8P.9.5.6 Code DLQ readiness marker"

check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "EvaluateParasutWebhookSyncTriggerReadinessGate" "7-8P.9.6.1 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "PARASUT_WEBHOOK_SYNC_TRIGGER_DRY_RUN_READY_WITH_REAL_API_AND_ERP_WRITE_CLOSED" "7-8P.9.6.2 Code final readiness decision"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "real_webhook_endpoint_must_remain_false_in_webhook_trigger_phase" "7-8P.9.6.3 Code real webhook blocker"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "real_provider_api_must_remain_false_in_webhook_trigger_phase" "7-8P.9.6.4 Code real provider API blocker"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "real_erp_write_must_remain_false_in_webhook_trigger_phase" "7-8P.9.6.5 Code real ERP write blocker"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger.go" "real_queue_trigger_must_remain_false_in_webhook_trigger_phase" "7-8P.9.6.6 Code real queue trigger blocker"

check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger_test.go" "TestParasutWebhookIntakeSignatureContract_7_8P_9_1" "7-8P.9.1.13 Test webhook intake signature"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger_test.go" "TestParasutWebhookEventTypeMappingContract_7_8P_9_2" "7-8P.9.2.10 Test event type mapping"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger_test.go" "TestParasutWebhookIdempotencyDuplicateGuard_7_8P_9_3" "7-8P.9.3.6 Test idempotency duplicate"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger_test.go" "TestParasutWebhookSyncWorkerTriggerBridge_7_8P_9_4" "7-8P.9.4.7 Test sync worker trigger"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger_test.go" "TestParasutWebhookDuplicateDoesNotTriggerWorker_7_8P_9_4_X" "7-8P.9.4.8 Test duplicate does not trigger worker"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger_test.go" "TestParasutWebhookRetryDLQAuditOrchestration_7_8P_9_5" "7-8P.9.5.7 Test retry DLQ audit"
check_grep "internal/platform/integrations/runtime/parasut_webhook_sync_trigger_test.go" "TestParasutWebhookSyncTriggerFinalClosure_7_8P_9_6" "7-8P.9.6.7 Test final closure"

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

echo "===== 7-8P.9 PARASUT WEBHOOK SYNC TRIGGER REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_9_PARASUT_WEBHOOK_SYNC_TRIGGER_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
