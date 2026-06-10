#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_6_PARASUT_API_CLIENT_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_6_parasut_api_client_audit.env"

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

echo "# FAZ 7-8P.6 Paraşüt API Client Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.6 PARASUT API CLIENT REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_6_PARASUT_API_CLIENT_OPERATION_RUNTIME_READINESS.md" "7-8P.6.0.1 Documentation artifact"
check_file "configs/faz7/parasut_api_client.v1.json" "7-8P.6.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_api_client.go" "7-8P.6.0.3 API client code"
check_file "internal/platform/integrations/runtime/parasut_api_client_test.go" "7-8P.6.0.4 API client test code"

check_grep "docs/faz7/FAZ_7_8P_6_PARASUT_API_CLIENT_OPERATION_RUNTIME_READINESS.md" "FAZ 7-8P.6 Paraşüt API Client / Operation Runtime Dry-Run Readiness" "7-8P.6.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_6_PARASUT_API_CLIENT_OPERATION_RUNTIME_READINESS.md" "7-8P.6.1 API Client Contract" "7-8P.6.1.0 Scope doc API client contract"
check_grep "docs/faz7/FAZ_7_8P_6_PARASUT_API_CLIENT_OPERATION_RUNTIME_READINESS.md" "7-8P.6.2 Operation Request Builder" "7-8P.6.2.0 Scope doc operation builder"
check_grep "docs/faz7/FAZ_7_8P_6_PARASUT_API_CLIENT_OPERATION_RUNTIME_READINESS.md" "7-8P.6.3 Dry-Run Provider Response" "7-8P.6.3.0 Scope doc dry-run response"
check_grep "docs/faz7/FAZ_7_8P_6_PARASUT_API_CLIENT_OPERATION_RUNTIME_READINESS.md" "7-8P.6.4 Rate Limit / Timeout / Retry Bridge" "7-8P.6.4.0 Scope doc policy bridge"
check_grep "docs/faz7/FAZ_7_8P_6_PARASUT_API_CLIENT_OPERATION_RUNTIME_READINESS.md" "7-8P.6.5 Operation Audit / Observability Bridge" "7-8P.6.5.0 Scope doc observability bridge"
check_grep "docs/faz7/FAZ_7_8P_6_PARASUT_API_CLIENT_OPERATION_RUNTIME_READINESS.md" "7-8P.6.6 Final Closure" "7-8P.6.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_api_client.v1.json" '"provider_key": "parasut"' "7-8P.6.0.6 Config provider key"
check_grep "configs/faz7/parasut_api_client.v1.json" '"real_provider_api_enabled": false' "7-8P.6.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_api_client.v1.json" '"real_http_client_enabled": false' "7-8P.6.0.8 Config real HTTP client disabled"
check_grep "configs/faz7/parasut_api_client.v1.json" '"access_token_plaintext_resolve_enabled": false' "7-8P.6.0.9 Config plaintext token resolve disabled"
check_grep "configs/faz7/parasut_api_client.v1.json" '"FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REFRESH_READINESS"' "7-8P.6.0.10 Config dependency on token exchange"
check_grep "configs/faz7/parasut_api_client.v1.json" '"access_token_ref_required": true' "7-8P.6.1.1 Config access token ref required"
check_grep "configs/faz7/parasut_api_client.v1.json" '"tenant_safe_access_token_ref_required": true' "7-8P.6.1.2 Config tenant-safe access token ref"
check_grep "configs/faz7/parasut_api_client.v1.json" '"real_api_enabled_must_remain_false": true' "7-8P.6.1.3 Config real API closed"
check_grep "configs/faz7/parasut_api_client.v1.json" '"PULL_INVOICE"' "7-8P.6.2.1 Config pull invoice operation"
check_grep "configs/faz7/parasut_api_client.v1.json" '"PUSH_INVOICE"' "7-8P.6.2.2 Config push invoice operation"
check_grep "configs/faz7/parasut_api_client.v1.json" '"SYNC_CUSTOMER"' "7-8P.6.2.3 Config sync customer operation"
check_grep "configs/faz7/parasut_api_client.v1.json" '"SYNC_PRODUCT"' "7-8P.6.2.4 Config sync product operation"
check_grep "configs/faz7/parasut_api_client.v1.json" '"VERIFY_WEBHOOK"' "7-8P.6.2.5 Config verify webhook operation"
check_grep "configs/faz7/parasut_api_client.v1.json" '"real_http_call": false' "7-8P.6.3.1 Config real HTTP call false"
check_grep "configs/faz7/parasut_api_client.v1.json" '"simulated_http_status": 200' "7-8P.6.3.2 Config simulated HTTP status"
check_grep "configs/faz7/parasut_api_client.v1.json" '"plaintext_token_usage_allowed": false' "7-8P.6.3.3 Config plaintext token usage denied"
check_grep "configs/faz7/parasut_api_client.v1.json" '"timeout_policy_required": true' "7-8P.6.4.1 Config timeout policy"
check_grep "configs/faz7/parasut_api_client.v1.json" '"rate_limit_policy_required": true' "7-8P.6.4.2 Config rate limit policy"
check_grep "configs/faz7/parasut_api_client.v1.json" '"retry_policy_required": true' "7-8P.6.4.3 Config retry policy"
check_grep "configs/faz7/parasut_api_client.v1.json" '"unknown_error_dlq": true' "7-8P.6.4.4 Config unknown error DLQ"
check_grep "configs/faz7/parasut_api_client.v1.json" '"connector_audit_event_required": true' "7-8P.6.5.1 Config audit event required"
check_grep "configs/faz7/parasut_api_client.v1.json" '"operation_metrics_required": true' "7-8P.6.5.2 Config operation metrics required"
check_grep "configs/faz7/parasut_api_client.v1.json" '"provider_transaction_trace_required": true' "7-8P.6.5.3 Config provider transaction trace"

check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "type ParasutAPIClientContractRequest struct" "7-8P.6.1.4 Code API client contract request"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "BuildParasutAPIClientContract" "7-8P.6.1.5 Code API client contract builder"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "AccessTokenRef" "7-8P.6.1.6 Code access token ref field"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "real parasut api must remain disabled" "7-8P.6.1.7 Code real API blocker"

check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "type ParasutAPIOperationRequest struct" "7-8P.6.2.6 Code operation request model"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "BuildParasutAPIOperationRequest" "7-8P.6.2.7 Code operation request builder"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "DefaultParasutAPIEndpointContracts" "7-8P.6.2.8 Code endpoint contract bridge"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "IdempotencyKey" "7-8P.6.2.9 Code idempotency key field"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "operation payload required" "7-8P.6.2.10 Code payload guard"

check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "type ParasutAPIDryRunProviderResponse struct" "7-8P.6.3.4 Code dry-run provider response"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "ExecuteParasutAPIDryRun" "7-8P.6.3.5 Code dry-run executor"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "RealHTTPCall" "7-8P.6.3.6 Code real HTTP call flag"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "PlaintextTokenUsed" "7-8P.6.3.7 Code plaintext token used flag"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "ProviderTransactionID" "7-8P.6.3.8 Code provider transaction trace"

check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "type ParasutAPIOperationPolicyBridge struct" "7-8P.6.4.5 Code policy bridge model"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "BuildParasutAPIOperationPolicyBridge" "7-8P.6.4.6 Code policy bridge builder"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "RateLimitPerMinute" "7-8P.6.4.7 Code rate limit field"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "RetryPolicy" "7-8P.6.4.8 Code retry policy bridge"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "EvaluateParasutAPIOperationFailure" "7-8P.6.4.9 Code operation failure evaluator"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "MapParasutProviderError" "7-8P.6.4.10 Code provider error mapping bridge"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "EvaluateRetry" "7-8P.6.4.11 Code retry decision bridge"

check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "RecordParasutAPIOperationAudit" "7-8P.6.5.4 Code operation audit recorder"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "ConnectorAuditEvent" "7-8P.6.5.5 Code connector audit event bridge"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "RecordOperation" "7-8P.6.5.6 Code observability record operation"

check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "EvaluateParasutAPIClientReadinessGate" "7-8P.6.6.1 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "PARASUT_API_CLIENT_OPERATION_DRY_RUN_READY_WITH_REAL_API_CLOSED" "7-8P.6.6.2 Code final readiness decision"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "real_api_enabled_must_remain_false_in_api_client_phase" "7-8P.6.6.3 Code real API blocker"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "real_http_client_must_remain_false_in_api_client_phase" "7-8P.6.6.4 Code real HTTP blocker"
check_grep "internal/platform/integrations/runtime/parasut_api_client.go" "plaintext_token_resolve_must_remain_false_in_api_client_phase" "7-8P.6.6.5 Code plaintext token blocker"

check_grep "internal/platform/integrations/runtime/parasut_api_client_test.go" "TestParasutAPIClientContract_7_8P_6_1" "7-8P.6.1.9 Test API client contract"
check_grep "internal/platform/integrations/runtime/parasut_api_client_test.go" "TestParasutOperationRequestBuilder_7_8P_6_2" "7-8P.6.2.11 Test operation request builder"
check_grep "internal/platform/integrations/runtime/parasut_api_client_test.go" "TestParasutDryRunProviderResponse_7_8P_6_3" "7-8P.6.3.9 Test dry-run provider response"
check_grep "internal/platform/integrations/runtime/parasut_api_client_test.go" "TestParasutRateLimitTimeoutRetryBridge_7_8P_6_4" "7-8P.6.4.12 Test policy bridge"
check_grep "internal/platform/integrations/runtime/parasut_api_client_test.go" "TestParasutOperationAuditObservabilityBridge_7_8P_6_5" "7-8P.6.5.7 Test observability bridge"
check_grep "internal/platform/integrations/runtime/parasut_api_client_test.go" "TestParasutAPIClientFinalClosure_7_8P_6_6" "7-8P.6.6.6 Test final closure"

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

echo "===== 7-8P.6 PARASUT API CLIENT REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_6_PARASUT_API_CLIENT_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
