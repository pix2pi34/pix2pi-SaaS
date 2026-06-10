#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_4_PARASUT_OAUTH_FLOW_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_4_parasut_oauth_flow_audit.env"

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

echo "# FAZ 7-8P.4 Paraşüt OAuth Flow Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.4 PARASUT OAUTH FLOW REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_4_PARASUT_OAUTH_CALLBACK_READINESS.md" "7-8P.4.0.1 Documentation artifact"
check_file "configs/faz7/parasut_oauth_flow.v1.json" "7-8P.4.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_oauth_flow.go" "7-8P.4.0.3 OAuth flow code"
check_file "internal/platform/integrations/runtime/parasut_oauth_flow_test.go" "7-8P.4.0.4 OAuth flow test code"

check_grep "docs/faz7/FAZ_7_8P_4_PARASUT_OAUTH_CALLBACK_READINESS.md" "FAZ 7-8P.4 Paraşüt OAuth Callback / Authorization Flow Readiness" "7-8P.4.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_4_PARASUT_OAUTH_CALLBACK_READINESS.md" "7-8P.4.1 OAuth Connect Button / Surface Contract" "7-8P.4.1.0 Scope doc connect surface"
check_grep "docs/faz7/FAZ_7_8P_4_PARASUT_OAUTH_CALLBACK_READINESS.md" "7-8P.4.2 Authorization URL Contract" "7-8P.4.2.0 Scope doc authorization URL"
check_grep "docs/faz7/FAZ_7_8P_4_PARASUT_OAUTH_CALLBACK_READINESS.md" "7-8P.4.3 Callback Intake Contract" "7-8P.4.3.0 Scope doc callback intake"
check_grep "docs/faz7/FAZ_7_8P_4_PARASUT_OAUTH_CALLBACK_READINESS.md" "7-8P.4.4 Token Exchange Dry-Run Gate" "7-8P.4.4.0 Scope doc token exchange gate"
check_grep "docs/faz7/FAZ_7_8P_4_PARASUT_OAUTH_CALLBACK_READINESS.md" "7-8P.4.5 Token Ref Handoff Contract" "7-8P.4.5.0 Scope doc token ref handoff"
check_grep "docs/faz7/FAZ_7_8P_4_PARASUT_OAUTH_CALLBACK_READINESS.md" "7-8P.4.6 Final Closure" "7-8P.4.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"provider_key": "parasut"' "7-8P.4.0.6 Config provider key"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"real_provider_api_enabled": false' "7-8P.4.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"real_token_exchange_enabled": false' "7-8P.4.0.8 Config real token exchange disabled"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS"' "7-8P.4.0.9 Config dependency on credential UI"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"button_label": "Paraşüt’e Bağlan"' "7-8P.4.1.1 Config connect button label"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"callback_path": "/integrations/parasut/oauth/callback"' "7-8P.4.1.2 Config callback path"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"TENANT_ADMIN"' "7-8P.4.1.3 Config tenant admin role"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"INTEGRATION_ADMIN"' "7-8P.4.1.4 Config integration admin role"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"state_required": true' "7-8P.4.2.1 Config state required"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"nonce_required": true' "7-8P.4.2.2 Config nonce required"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"response_type": "code"' "7-8P.4.2.3 Config response type code"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"authorization_code_required": true' "7-8P.4.3.1 Config authorization code required"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"expected_state_required": true' "7-8P.4.3.2 Config expected state required"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"callback_error_supported": true' "7-8P.4.3.3 Config callback error supported"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"mode": "DRY_RUN_BLOCKED"' "7-8P.4.4.1 Config dry run token exchange mode"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"blocked_status": "TOKEN_EXCHANGE_DRY_RUN_BLOCKED"' "7-8P.4.4.2 Config token exchange blocked status"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"access_token_ref_required": true' "7-8P.4.5.1 Config access token ref required"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"refresh_token_ref_required": true' "7-8P.4.5.2 Config refresh token ref required"
check_grep "configs/faz7/parasut_oauth_flow.v1.json" '"tenant_safe_secret_ref_required": true' "7-8P.4.5.3 Config tenant-safe token refs"

check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "type ParasutOAuthConnectSurfaceContract struct" "7-8P.4.1.5 Code connect surface contract"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "DefaultParasutOAuthConnectSurfaceContract" "7-8P.4.1.6 Code default connect surface"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "CanRoleStartOAuth" "7-8P.4.1.7 Code role oauth guard"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "ValidateParasutOAuthConnectSurfaceContract" "7-8P.4.1.8 Code connect surface validator"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "RealTokenExchangeEnabled" "7-8P.4.1.9 Code real token exchange disabled field"

check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "BuildParasutOAuthState" "7-8P.4.2.4 Code state builder"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "sha256.Sum256" "7-8P.4.2.5 Code state hash guard"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "type ParasutAuthorizationURLRequest struct" "7-8P.4.2.6 Code authorization URL request"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "BuildParasutAuthorizationURL" "7-8P.4.2.7 Code authorization URL builder"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "response_type" "7-8P.4.2.8 Code response type query"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "redirect_uri" "7-8P.4.2.9 Code redirect URI query"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "scope" "7-8P.4.2.10 Code scope query"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "RealRedirectEnabled" "7-8P.4.2.11 Code real redirect disabled field"

check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "type ParasutOAuthCallbackRequest struct" "7-8P.4.3.4 Code callback request"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "HandleParasutOAuthCallback" "7-8P.4.3.5 Code callback handler"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "AuthorizationCode" "7-8P.4.3.6 Code authorization code field"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "CallbackError" "7-8P.4.3.7 Code callback error field"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "oauth state mismatch" "7-8P.4.3.8 Code state mismatch guard"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "ExpectedState" "7-8P.4.3.9 Code expected state field"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "ReceivedState" "7-8P.4.3.10 Code received state field"

check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "ParasutOAuthFlowStatusTokenExchangeDryRunBlocked" "7-8P.4.4.3 Code token exchange dry-run blocked status"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "ProviderLiveModuleOpened" "7-8P.4.4.4 Code provider live module guard"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "real token exchange cannot be enabled before provider live module" "7-8P.4.4.5 Code unsafe real token exchange blocker"

check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "type ParasutOAuthTokenRefHandoffRequest struct" "7-8P.4.5.4 Code token ref handoff request"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "BuildParasutOAuthTokenRefHandoff" "7-8P.4.5.5 Code token ref handoff builder"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "AccessTokenRef" "7-8P.4.5.6 Code access token ref field"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "RefreshTokenRef" "7-8P.4.5.7 Code refresh token ref field"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "isParasutSecretRefForTenant" "7-8P.4.5.8 Code tenant-safe ref validator"

check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "EvaluateParasutOAuthFlowReadinessGate" "7-8P.4.6.1 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "PARASUT_OAUTH_FLOW_READY_WITH_REAL_API_CLOSED" "7-8P.4.6.2 Code final readiness decision"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "real_api_enabled_must_remain_false_in_oauth_flow_phase" "7-8P.4.6.3 Code real API blocker"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow.go" "real_token_exchange_must_remain_false_in_oauth_flow_phase" "7-8P.4.6.4 Code real token exchange blocker"

check_grep "internal/platform/integrations/runtime/parasut_oauth_flow_test.go" "TestParasutOAuthConnectButtonSurfaceContract_7_8P_4_1" "7-8P.4.1.10 Test connect button surface"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow_test.go" "TestParasutAuthorizationURLContract_7_8P_4_2" "7-8P.4.2.12 Test authorization URL"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow_test.go" "TestParasutCallbackIntakeStateNonceGuard_7_8P_4_3" "7-8P.4.3.11 Test callback state nonce"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow_test.go" "TestParasutTokenExchangeDryRunGate_7_8P_4_4" "7-8P.4.4.6 Test token exchange dry run"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow_test.go" "TestParasutTokenRefHandoffContract_7_8P_4_5" "7-8P.4.5.9 Test token ref handoff"
check_grep "internal/platform/integrations/runtime/parasut_oauth_flow_test.go" "TestParasutOAuthFlowFinalClosure_7_8P_4_6" "7-8P.4.6.5 Test final closure"

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

echo "===== 7-8P.4 PARASUT OAUTH FLOW REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_4_PARASUT_OAUTH_FLOW_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
