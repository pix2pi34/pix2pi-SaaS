#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_5_parasut_token_exchange_audit.env"

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

echo "# FAZ 7-8P.5 Paraşüt Token Exchange Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.5 PARASUT TOKEN EXCHANGE REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REFRESH_READINESS.md" "7-8P.5.0.1 Documentation artifact"
check_file "configs/faz7/parasut_token_exchange.v1.json" "7-8P.5.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_token_exchange.go" "7-8P.5.0.3 Token exchange code"
check_file "internal/platform/integrations/runtime/parasut_token_exchange_test.go" "7-8P.5.0.4 Token exchange test code"

check_grep "docs/faz7/FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REFRESH_READINESS.md" "FAZ 7-8P.5 Paraşüt Token Exchange / Refresh Runtime Dry-Run Readiness" "7-8P.5.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REFRESH_READINESS.md" "7-8P.5.1 Token Exchange Request Contract" "7-8P.5.1.0 Scope doc token exchange contract"
check_grep "docs/faz7/FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REFRESH_READINESS.md" "7-8P.5.2 Simulated Token Response / Secret Ref Storage" "7-8P.5.2.0 Scope doc simulated token response"
check_grep "docs/faz7/FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REFRESH_READINESS.md" "7-8P.5.3 Refresh Readiness / Lifecycle Guard" "7-8P.5.3.0 Scope doc refresh guard"
check_grep "docs/faz7/FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REFRESH_READINESS.md" "7-8P.5.4 Simulated Refresh Rotation" "7-8P.5.4.0 Scope doc simulated refresh"
check_grep "docs/faz7/FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REFRESH_READINESS.md" "7-8P.5.5 Token Endpoint Error Mapping" "7-8P.5.5.0 Scope doc token error mapping"
check_grep "docs/faz7/FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REFRESH_READINESS.md" "7-8P.5.6 Final Closure" "7-8P.5.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_token_exchange.v1.json" '"provider_key": "parasut"' "7-8P.5.0.6 Config provider key"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"real_provider_api_enabled": false' "7-8P.5.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"real_token_exchange_enabled": false' "7-8P.5.0.8 Config real token exchange disabled"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"real_token_refresh_enabled": false' "7-8P.5.0.9 Config real token refresh disabled"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"FAZ_7_8P_4_PARASUT_OAUTH_CALLBACK_READINESS"' "7-8P.5.0.10 Config dependency on OAuth flow"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"authorization_code_required": true' "7-8P.5.1.1 Config authorization code required"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"client_secret_ref_required": true' "7-8P.5.1.2 Config client secret ref required"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"real_token_exchange_must_remain_false": true' "7-8P.5.1.3 Config real token exchange closed"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"access_token_ref_created": true' "7-8P.5.2.1 Config access token ref created"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"refresh_token_ref_created": true' "7-8P.5.2.2 Config refresh token ref created"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"plaintext_token_db_storage_allowed": false' "7-8P.5.2.3 Config plaintext token DB storage denied"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"refresh_required_token_refresh_allowed": true' "7-8P.5.3.1 Config refresh required allowed"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"expired_access_token_refresh_allowed": true' "7-8P.5.3.2 Config expired access token refresh allowed"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"revoked_token_refresh_allowed": false' "7-8P.5.3.3 Config revoked token refresh blocked"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"rotate_access_token_ref": true' "7-8P.5.4.1 Config access token rotation"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"rotate_refresh_token_ref_optional": true' "7-8P.5.4.2 Config refresh token rotation optional"
check_grep "configs/faz7/parasut_token_exchange.v1.json" '"unknown": "UNKNOWN_PROVIDER_ERROR_DLQ"' "7-8P.5.5.1 Config unknown token error DLQ"

check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "type ParasutTokenExchangeContractRequest struct" "7-8P.5.1.4 Code token exchange request"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "PrepareParasutTokenExchangeContract" "7-8P.5.1.5 Code token exchange contract preparer"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "AuthorizationCode" "7-8P.5.1.6 Code authorization code field"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "ClientSecretRef" "7-8P.5.1.7 Code client secret ref field"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "real token exchange must remain disabled" "7-8P.5.1.8 Code real token exchange blocker"

check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "type ParasutSimulatedTokenResponse struct" "7-8P.5.2.4 Code simulated token response"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "StoreParasutSimulatedTokenResponse" "7-8P.5.2.5 Code simulated token storage"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "ParasutSecretKindAccessToken" "7-8P.5.2.6 Code access token secret kind"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "ParasutSecretKindRefreshToken" "7-8P.5.2.7 Code refresh token secret kind"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "BuildParasutOAuthTokenRefHandoff" "7-8P.5.2.8 Code token ref handoff bridge"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "BuildParasutTokenLifecycle" "7-8P.5.2.9 Code token lifecycle bridge"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "PlaintextPersisted" "7-8P.5.2.10 Code plaintext persisted flag"

check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "EvaluateParasutAccessTokenRefreshNeed" "7-8P.5.3.4 Code refresh need evaluator"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "active_token_refresh_not_required" "7-8P.5.3.5 Code active no refresh reason"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "refresh_required" "7-8P.5.3.6 Code refresh required reason"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "access_token_expired_refresh_allowed" "7-8P.5.3.7 Code expired refresh allowed"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "revoked_token_refresh_blocked" "7-8P.5.3.8 Code revoked refresh blocked"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "PrepareParasutTokenRefreshContract" "7-8P.5.3.9 Code refresh contract preparer"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "real token refresh must remain disabled" "7-8P.5.3.10 Code real refresh blocker"

check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "type ParasutSimulatedRefreshResponse struct" "7-8P.5.4.3 Code simulated refresh response"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "StoreParasutSimulatedRefreshResponse" "7-8P.5.4.4 Code simulated refresh storage"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "RotateRefreshToken" "7-8P.5.4.5 Code optional refresh token rotation"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "RotateSecret" "7-8P.5.4.6 Code vault rotate bridge"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "ParasutTokenExchangeStatusRefreshRefsRotated" "7-8P.5.4.7 Code refresh rotated status"

check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "MapParasutTokenEndpointError" "7-8P.5.5.2 Code token endpoint error mapper"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "MapParasutProviderError" "7-8P.5.5.3 Code provider error mapping bridge"

check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "EvaluateParasutTokenExchangeReadinessGate" "7-8P.5.6.1 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "PARASUT_TOKEN_EXCHANGE_REFRESH_DRY_RUN_READY_WITH_REAL_API_CLOSED" "7-8P.5.6.2 Code final readiness decision"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "real_api_enabled_must_remain_false_in_token_exchange_phase" "7-8P.5.6.3 Code real API blocker"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "real_token_exchange_must_remain_false_in_token_exchange_phase" "7-8P.5.6.4 Code real token exchange blocker"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange.go" "real_token_refresh_must_remain_false_in_token_exchange_phase" "7-8P.5.6.5 Code real token refresh blocker"

check_grep "internal/platform/integrations/runtime/parasut_token_exchange_test.go" "TestParasutTokenExchangeRequestContract_7_8P_5_1" "7-8P.5.1.9 Test token exchange request"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange_test.go" "TestParasutSimulatedTokenResponseSecretRefStorage_7_8P_5_2" "7-8P.5.2.11 Test simulated token storage"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange_test.go" "TestParasutRefreshReadinessLifecycleGuard_7_8P_5_3" "7-8P.5.3.11 Test refresh lifecycle guard"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange_test.go" "TestParasutSimulatedRefreshRotation_7_8P_5_4" "7-8P.5.4.8 Test simulated refresh rotation"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange_test.go" "TestParasutTokenEndpointErrorMapping_7_8P_5_5" "7-8P.5.5.4 Test token endpoint error mapping"
check_grep "internal/platform/integrations/runtime/parasut_token_exchange_test.go" "TestParasutTokenExchangeRefreshFinalClosure_7_8P_5_6" "7-8P.5.6.6 Test final closure"

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

echo "===== 7-8P.5 PARASUT TOKEN EXCHANGE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_5_PARASUT_TOKEN_EXCHANGE_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
