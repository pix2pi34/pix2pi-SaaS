#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_1_parasut_live_contract_audit.env"

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

echo "# FAZ 7-8P.1 Paraşüt Live Contract Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.1 PARASUT LIVE CONTRACT REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_READINESS.md" "7-8P.1.0.1 Documentation artifact"
check_file "configs/faz7/parasut_live_contract.v1.json" "7-8P.1.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_live_contract.go" "7-8P.1.0.3 Live contract code"
check_file "internal/platform/integrations/runtime/parasut_live_contract_test.go" "7-8P.1.0.4 Live contract test code"

check_grep "docs/faz7/FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_READINESS.md" "FAZ 7-8P.1 Paraşüt Live Contract / OAuth + API Contract Readiness" "7-8P.1.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_READINESS.md" "7-8P.1.1 OAuth Credential Contract" "7-8P.1.1.0 Scope doc OAuth contract"
check_grep "docs/faz7/FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_READINESS.md" "7-8P.1.2 Token Lifecycle Contract" "7-8P.1.2.0 Scope doc token lifecycle"
check_grep "docs/faz7/FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_READINESS.md" "7-8P.1.3 Paraşüt API Endpoint Contract" "7-8P.1.3.0 Scope doc API endpoint"
check_grep "docs/faz7/FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_READINESS.md" "7-8P.1.4 Provider Response / Error Mapping" "7-8P.1.4.0 Scope doc error mapping"
check_grep "docs/faz7/FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_READINESS.md" "7-8P.1.5 Live Integration Safety Gate" "7-8P.1.5.0 Scope doc live safety gate"
check_grep "docs/faz7/FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_READINESS.md" "7-8P.1.6 Final Closure" "7-8P.1.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_live_contract.v1.json" '"provider_key": "parasut"' "7-8P.1.0.6 Config provider key"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"real_provider_api_enabled": false' "7-8P.1.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"FAZ_7_8P_PARASUT_CONNECTOR_MODULE"' "7-8P.1.0.8 Config dependency on Paraşüt foundation"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"client_secret_reference_required": true' "7-8P.1.1.1 Config secret reference required"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"webhook_secret_reference_required": true' "7-8P.1.1.2 Config webhook secret reference required"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"access_token_reference_only": true' "7-8P.1.2.1 Config access token reference only"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"refresh_token_reference_only": true' "7-8P.1.2.2 Config refresh token reference only"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"refresh_window_seconds": 600' "7-8P.1.2.3 Config refresh window"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"PULL_INVOICE"' "7-8P.1.3.1 Config pull invoice endpoint"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"PUSH_INVOICE"' "7-8P.1.3.2 Config push invoice endpoint"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"SYNC_CUSTOMER"' "7-8P.1.3.3 Config sync customer endpoint"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"SYNC_PRODUCT"' "7-8P.1.3.4 Config sync product endpoint"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"VERIFY_WEBHOOK"' "7-8P.1.3.5 Config verify webhook endpoint"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"401": "UNAUTHORIZED_NON_RETRYABLE"' "7-8P.1.4.1 Config unauthorized mapping"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"429": "RATE_LIMIT_RETRYABLE"' "7-8P.1.4.2 Config rate limit mapping"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"500": "SERVER_ERROR_RETRYABLE"' "7-8P.1.4.3 Config server error mapping"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"legal_approval_required": true' "7-8P.1.5.1 Config legal approval gate"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"finance_approval_required": true' "7-8P.1.5.2 Config finance approval gate"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"kvkk_approval_required": true' "7-8P.1.5.3 Config KVKK approval gate"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"secret_management_required": true' "7-8P.1.5.4 Config secret management gate"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"rollback_plan_required": true' "7-8P.1.5.5 Config rollback plan gate"
check_grep "configs/faz7/parasut_live_contract.v1.json" '"provider_contract_required": true' "7-8P.1.5.6 Config provider contract gate"

check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "type ParasutOAuthCredentialContract struct" "7-8P.1.1.3 Code OAuth contract model"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "BuildParasutOAuthCredentialContract" "7-8P.1.1.4 Code OAuth contract builder"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ValidateParasutOAuthCredentialContract" "7-8P.1.1.5 Code OAuth contract validator"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ClientSecretRef" "7-8P.1.1.6 Code client secret reference"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "WebhookSecretRef" "7-8P.1.1.7 Code webhook secret reference"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "real api enabled is closed" "7-8P.1.1.8 Code real API disabled guard"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "production approval required" "7-8P.1.1.9 Code production approval guard"

check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "type ParasutTokenStatus string" "7-8P.1.2.4 Code token status model"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ParasutTokenStatusActive" "7-8P.1.2.5 Code active token status"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ParasutTokenStatusRefreshRequired" "7-8P.1.2.6 Code refresh required token status"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ParasutTokenStatusExpired" "7-8P.1.2.7 Code expired token status"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ParasutTokenStatusRevoked" "7-8P.1.2.8 Code revoked token status"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "BuildParasutTokenLifecycle" "7-8P.1.2.9 Code token lifecycle builder"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "AccessTokenRef" "7-8P.1.2.10 Code access token reference"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "RefreshTokenRef" "7-8P.1.2.11 Code refresh token reference"

check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "type ParasutAPIEndpointContract struct" "7-8P.1.3.6 Code endpoint contract model"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "DefaultParasutAPIEndpointContracts" "7-8P.1.3.7 Code default endpoint contracts"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ValidateParasutAPIEndpointContract" "7-8P.1.3.8 Code endpoint contract validator"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ValidateParasutAPIEndpointContracts" "7-8P.1.3.9 Code endpoint contract set validator"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "RateLimitPerMinute" "7-8P.1.3.10 Code rate limit policy"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "RealCallEnabled" "7-8P.1.3.11 Code real call disabled field"

check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "type ParasutProviderErrorMapping struct" "7-8P.1.4.4 Code provider error mapping model"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "MapParasutProviderError" "7-8P.1.4.5 Code provider error mapper"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ParasutMappedErrorUnauthorized" "7-8P.1.4.6 Code unauthorized mapping"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ParasutMappedErrorRateLimited" "7-8P.1.4.7 Code rate limit mapping"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ParasutMappedErrorServer" "7-8P.1.4.8 Code server error mapping"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "MoveToDLQ" "7-8P.1.4.9 Code DLQ mapping field"

check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "type ParasutLiveSafetyGateInput struct" "7-8P.1.5.7 Code live safety gate input"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "EvaluateParasutLiveSafetyGate" "7-8P.1.5.8 Code live safety gate evaluator"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "LegalApprovalReady" "7-8P.1.5.9 Code legal approval guard"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "FinanceApprovalReady" "7-8P.1.5.10 Code finance approval guard"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "KVKKApprovalReady" "7-8P.1.5.11 Code KVKK approval guard"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "SecretManagementReady" "7-8P.1.5.12 Code secret management guard"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "RollbackPlanReady" "7-8P.1.5.13 Code rollback plan guard"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "ProviderContractReady" "7-8P.1.5.14 Code provider contract guard"
check_grep "internal/platform/integrations/runtime/parasut_live_contract.go" "PARASUT_LIVE_CONTRACT_READY_BUT_REAL_API_CLOSED" "7-8P.1.5.15 Code readiness decision"

check_grep "internal/platform/integrations/runtime/parasut_live_contract_test.go" "TestParasutOAuthCredentialContract_7_8P_1_1" "7-8P.1.1.10 Test OAuth contract"
check_grep "internal/platform/integrations/runtime/parasut_live_contract_test.go" "TestParasutTokenLifecycleContract_7_8P_1_2" "7-8P.1.2.12 Test token lifecycle"
check_grep "internal/platform/integrations/runtime/parasut_live_contract_test.go" "TestParasutAPIEndpointContract_7_8P_1_3" "7-8P.1.3.12 Test endpoint contract"
check_grep "internal/platform/integrations/runtime/parasut_live_contract_test.go" "TestParasutProviderResponseErrorMapping_7_8P_1_4" "7-8P.1.4.10 Test error mapping"
check_grep "internal/platform/integrations/runtime/parasut_live_contract_test.go" "TestParasutLiveIntegrationSafetyGate_7_8P_1_5" "7-8P.1.5.16 Test live safety gate"
check_grep "internal/platform/integrations/runtime/parasut_live_contract_test.go" "TestParasutLiveContractFinalClosure_7_8P_1_6" "7-8P.1.6.1 Test final closure"

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

echo "===== 7-8P.1 PARASUT LIVE CONTRACT REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_1_PARASUT_LIVE_CONTRACT_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
