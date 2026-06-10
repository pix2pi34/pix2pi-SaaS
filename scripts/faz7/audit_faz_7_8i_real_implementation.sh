#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8I_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8i_audit.env"

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

echo "# FAZ 7-8I Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8I REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION.md" "7-8I.0.1 Documentation artifact"
check_file "configs/faz7/integration_runtime_foundation.v1.json" "7-8I.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/types.go" "7-8I.0.3 Runtime types code"
check_file "internal/platform/integrations/runtime/adapter_sdk.go" "7-8I.0.4 Adapter SDK code"
check_file "internal/platform/integrations/runtime/webhook_intake.go" "7-8I.0.5 Webhook intake code"
check_file "internal/platform/integrations/runtime/observability.go" "7-8I.0.6 Observability code"
check_file "internal/platform/integrations/runtime/retry_dlq.go" "7-8I.0.7 Retry DLQ code"
check_file "internal/platform/integrations/runtime/handoff.go" "7-8I.0.8 Handoff gate code"
check_file "internal/platform/integrations/runtime/runtime_test.go" "7-8I.0.9 Runtime test code"

check_grep "docs/faz7/FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION.md" "FAZ 7-8I Integration Runtime Foundation" "7-8I.0.10 Scope document title"
check_grep "docs/faz7/FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION.md" "7-8I.1 Tenant Integration Install / Enablement Runtime" "7-8I.1.0 Scope doc tenant install"
check_grep "docs/faz7/FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION.md" "7-8I.2 Connector Runtime Foundation / Adapter SDK" "7-8I.2.0 Scope doc adapter SDK"
check_grep "docs/faz7/FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION.md" "7-8I.3 Webhook / External Event Intake Foundation" "7-8I.3.0 Scope doc webhook"
check_grep "docs/faz7/FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION.md" "7-8I.4 Connector Operation Audit / Observability" "7-8I.4.0 Scope doc observability"
check_grep "docs/faz7/FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION.md" "7-8I.5 Connector Failure / Retry / DLQ Readiness" "7-8I.5.0 Scope doc retry DLQ"
check_grep "docs/faz7/FAZ_7_8I_INTEGRATION_RUNTIME_FOUNDATION.md" "7-8I.6 Connector Final Closure / Provider Module Handoff Gate" "7-8I.6.0 Scope doc handoff"

check_grep "configs/faz7/integration_runtime_foundation.v1.json" "tenant_install_enablement" "7-8I.1.1 Config tenant install flag"
check_grep "configs/faz7/integration_runtime_foundation.v1.json" "connector_adapter_sdk" "7-8I.2.1 Config adapter SDK flag"
check_grep "configs/faz7/integration_runtime_foundation.v1.json" "webhook_external_event_intake" "7-8I.3.1 Config webhook intake flag"
check_grep "configs/faz7/integration_runtime_foundation.v1.json" "connector_operation_audit_observability" "7-8I.4.1 Config observability flag"
check_grep "configs/faz7/integration_runtime_foundation.v1.json" "failure_retry_dlq" "7-8I.5.1 Config retry DLQ flag"
check_grep "configs/faz7/integration_runtime_foundation.v1.json" "provider_specific_modules_required" "7-8I.6.1 Config provider module handoff flag"
check_grep "configs/faz7/integration_runtime_foundation.v1.json" "production_real_provider_enabled" "7-8I.6.2 Config real provider production gate"

check_grep "internal/platform/integrations/runtime/types.go" "EnableTenantIntegration" "7-8I.1.2 Tenant enablement runtime function"
check_grep "internal/platform/integrations/runtime/types.go" "TenantIntegrationInstallation" "7-8I.1.3 Tenant installation model"
check_grep "internal/platform/integrations/runtime/types.go" "ProductionEnabled" "7-8I.1.4 Production gate field"
check_grep "internal/platform/integrations/runtime/types.go" "AuditDecision" "7-8I.1.5 Audit decision model"

check_grep "internal/platform/integrations/runtime/adapter_sdk.go" "ConnectorAdapter interface" "7-8I.2.2 ConnectorAdapter interface"
check_grep "internal/platform/integrations/runtime/adapter_sdk.go" "RegisterAdapter" "7-8I.2.3 Adapter registry"
check_grep "internal/platform/integrations/runtime/adapter_sdk.go" "ValidateOperationRequest" "7-8I.2.4 Operation request guard"
check_grep "internal/platform/integrations/runtime/adapter_sdk.go" "IdempotencyKey" "7-8I.2.5 Idempotency field"
check_grep "internal/platform/integrations/runtime/adapter_sdk.go" "CorrelationID" "7-8I.2.6 Correlation field"

check_grep "internal/platform/integrations/runtime/webhook_intake.go" "ExternalEventIntakeRequest" "7-8I.3.2 External event intake request"
check_grep "internal/platform/integrations/runtime/webhook_intake.go" "BuildWebhookSignature" "7-8I.3.3 Webhook signature builder"
check_grep "internal/platform/integrations/runtime/webhook_intake.go" "VerifyAndBuildEvent" "7-8I.3.4 Webhook verify and build"
check_grep "internal/platform/integrations/runtime/webhook_intake.go" "hmac.New" "7-8I.3.5 HMAC SHA256 implementation"
check_grep "internal/platform/integrations/runtime/webhook_intake.go" "MaxTimestampSkew" "7-8I.3.6 Timestamp skew guard"
check_grep "internal/platform/integrations/runtime/webhook_intake.go" "RawPayload" "7-8I.3.7 Raw payload guard"

check_grep "internal/platform/integrations/runtime/observability.go" "ConnectorObservabilityRuntime" "7-8I.4.2 Observability runtime"
check_grep "internal/platform/integrations/runtime/observability.go" "ConnectorAuditEvent" "7-8I.4.3 Connector audit event"
check_grep "internal/platform/integrations/runtime/observability.go" "RecordOperation" "7-8I.4.4 Operation audit recorder"
check_grep "internal/platform/integrations/runtime/observability.go" "RecordWebhookEvent" "7-8I.4.5 Webhook metric recorder"
check_grep "internal/platform/integrations/runtime/observability.go" "AuditTrailByTenant" "7-8I.4.6 Tenant audit trail reader"
check_grep "internal/platform/integrations/runtime/observability.go" "DuplicateEvents" "7-8I.4.7 Duplicate event metric"

check_grep "internal/platform/integrations/runtime/retry_dlq.go" "RetryPolicy" "7-8I.5.2 Retry policy model"
check_grep "internal/platform/integrations/runtime/retry_dlq.go" "EvaluateRetry" "7-8I.5.3 Retry decision runtime"
check_grep "internal/platform/integrations/runtime/retry_dlq.go" "FailureKindPoison" "7-8I.5.4 Poison message model"
check_grep "internal/platform/integrations/runtime/retry_dlq.go" "CreateDLQMessage" "7-8I.5.5 DLQ message builder"
check_grep "internal/platform/integrations/runtime/retry_dlq.go" "MaxAttempts" "7-8I.5.6 Max attempt guard"

check_grep "internal/platform/integrations/runtime/handoff.go" "EvaluateProviderModuleHandoffGate" "7-8I.6.3 Provider module handoff gate"
check_grep "internal/platform/integrations/runtime/handoff.go" "RealPaymentLiveEnabled" "7-8I.6.4 Real payment live blocker"
check_grep "internal/platform/integrations/runtime/handoff.go" "ProviderSpecificModuleRequired" "7-8I.6.5 Provider specific module required guard"
check_grep "internal/platform/integrations/runtime/handoff.go" "READY_FOR_PROVIDER_MODULE" "7-8I.6.6 Ready for provider module decision"

check_grep "internal/platform/integrations/runtime/runtime_test.go" "TestTenantIntegrationEnablement_7_8I_1" "7-8I.1.6 Tenant install test"
check_grep "internal/platform/integrations/runtime/runtime_test.go" "TestConnectorRuntimeAdapterSDK_7_8I_2" "7-8I.2.7 Adapter SDK test"
check_grep "internal/platform/integrations/runtime/runtime_test.go" "TestWebhookExternalEventIntakeFoundation_7_8I_3" "7-8I.3.8 Webhook intake test"
check_grep "internal/platform/integrations/runtime/runtime_test.go" "TestConnectorOperationAuditObservability_7_8I_4" "7-8I.4.8 Observability test"
check_grep "internal/platform/integrations/runtime/runtime_test.go" "TestConnectorFailureRetryDLQReadiness_7_8I_5" "7-8I.5.7 Retry DLQ test"
check_grep "internal/platform/integrations/runtime/runtime_test.go" "TestConnectorFinalClosureProviderHandoffGate_7_8I_6" "7-8I.6.7 Handoff gate test"

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

echo "===== 7-8I REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8I_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
