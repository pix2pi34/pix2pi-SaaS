#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_3_parasut_credential_ui_audit.env"

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

echo "# FAZ 7-8P.3 Paraşüt Credential UI Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.3 PARASUT CREDENTIAL UI REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS.md" "7-8P.3.0.1 Documentation artifact"
check_file "configs/faz7/parasut_credential_ui.v1.json" "7-8P.3.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_credential_ui.go" "7-8P.3.0.3 Credential UI code"
check_file "internal/platform/integrations/runtime/parasut_credential_ui_test.go" "7-8P.3.0.4 Credential UI test code"

check_grep "docs/faz7/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS.md" "FAZ 7-8P.3 Paraşüt Credential UI / Admin Integration Surface Readiness" "7-8P.3.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS.md" "Panel → Ayarlar → Entegrasyonlar → Paraşüt → Bağlan / API Bilgileri" "7-8P.3.1.0 User API entry surface documented"
check_grep "docs/faz7/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS.md" "7-8P.3.1 Admin Integration Surface Contract" "7-8P.3.1.1 Scope doc admin surface"
check_grep "docs/faz7/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS.md" "7-8P.3.2 Credential Form Contract" "7-8P.3.2.0 Scope doc credential form"
check_grep "docs/faz7/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS.md" "7-8P.3.3 Save Credential Action" "7-8P.3.3.0 Scope doc save action"
check_grep "docs/faz7/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS.md" "7-8P.3.4 Test Connection Action" "7-8P.3.4.0 Scope doc test action"
check_grep "docs/faz7/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS.md" "7-8P.3.5 Disable / Rotate Action" "7-8P.3.5.0 Scope doc disable rotate"
check_grep "docs/faz7/FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_READINESS.md" "7-8P.3.6 Final Closure" "7-8P.3.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_credential_ui.v1.json" '"provider_key": "parasut"' "7-8P.3.0.6 Config provider key"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"real_provider_api_enabled": false' "7-8P.3.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"Panel > Ayarlar > Entegrasyonlar > Paraşüt > Bağlan / API Bilgileri"' "7-8P.3.1.2 Config panel path"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"TENANT_ADMIN"' "7-8P.3.1.3 Config tenant admin role"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"INTEGRATION_ADMIN"' "7-8P.3.1.4 Config integration admin role"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"client_id"' "7-8P.3.2.1 Config client id field"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"client_secret"' "7-8P.3.2.2 Config client secret field"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"webhook_secret"' "7-8P.3.2.3 Config webhook secret field"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"SAVE_CREDENTIALS"' "7-8P.3.3.1 Config save action"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"DRY_RUN_TEST_CONNECTION"' "7-8P.3.4.1 Config dry-run test action"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"DISABLE_INTEGRATION"' "7-8P.3.5.1 Config disable action"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"ROTATE_CLIENT_SECRET"' "7-8P.3.5.2 Config rotate client secret action"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"ROTATE_WEBHOOK_SECRET"' "7-8P.3.5.3 Config rotate webhook secret action"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"secret_fields_masked": true' "7-8P.3.2.4 Config secret fields masked"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"client_secret_plaintext_persisted": false' "7-8P.3.2.5 Config client secret plaintext forbidden"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"webhook_secret_plaintext_persisted": false' "7-8P.3.2.6 Config webhook secret plaintext forbidden"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"blocked_status": "BLOCKED_REAL_API_CLOSED"' "7-8P.3.4.2 Config real API closed status"
check_grep "configs/faz7/parasut_credential_ui.v1.json" '"vault_bridge_required": true' "7-8P.3.3.2 Config vault bridge required"

check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "type ParasutCredentialUIScreenContract struct" "7-8P.3.1.5 Code UI screen contract"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "DefaultParasutCredentialUIScreenContract" "7-8P.3.1.6 Code default UI contract"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "CanRoleAccess" "7-8P.3.1.7 Code role access guard"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "ValidateParasutCredentialUIScreenContract" "7-8P.3.1.8 Code screen contract validator"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "CredentialEntryRoleTenantAdmin" "7-8P.3.1.9 Code tenant admin role"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "CredentialEntryRoleIntegrationAdmin" "7-8P.3.1.10 Code integration admin role"

check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "ParasutCredentialUIActionSaveCredentials" "7-8P.3.3.3 Code save action constant"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "ParasutCredentialUIActionDryRunTestConnection" "7-8P.3.4.3 Code dry-run test action constant"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "ParasutCredentialUIActionDisableIntegration" "7-8P.3.5.4 Code disable action constant"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "ParasutCredentialUIActionRotateClientSecret" "7-8P.3.5.5 Code rotate client action constant"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "ParasutCredentialUIActionRotateWebhookSecret" "7-8P.3.5.6 Code rotate webhook action constant"

check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "HandleParasutCredentialUIAction" "7-8P.3.0.8 Code UI action handler"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "saveParasutCredentials" "7-8P.3.3.4 Code save credentials handler"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "StoreSecret" "7-8P.3.3.5 Code vault store bridge"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "BuildParasutCredentialSet" "7-8P.3.3.6 Code credential set bridge"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "PlaintextPersisted" "7-8P.3.2.7 Code plaintext persisted flag"

check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "dryRunParasutConnectionTest" "7-8P.3.4.4 Code dry-run test handler"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "ParasutCredentialUIStatusBlockedRealAPIClosed" "7-8P.3.4.5 Code blocked real API status"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "ProviderLiveModuleOpened" "7-8P.3.4.6 Code provider live module guard"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "RealAPIEnabled" "7-8P.3.4.7 Code real API enabled guard"

check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "disableParasutIntegration" "7-8P.3.5.7 Code disable handler"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "rotateParasutSecret" "7-8P.3.5.8 Code rotate handler"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "RotateSecret" "7-8P.3.5.9 Code token vault rotate bridge"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "ParasutCredentialUIStatusDisabled" "7-8P.3.5.10 Code disabled status"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "ParasutCredentialUIStatusRotated" "7-8P.3.5.11 Code rotated status"

check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "buildParasutCredentialUIDisplayFields" "7-8P.3.2.8 Code display field builder"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "maskParasutSecretRef" "7-8P.3.2.9 Code secret masking"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "SECRET_REF_ONLY" "7-8P.3.2.10 Code secret ref only display"

check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "EvaluateParasutCredentialUIReadinessGate" "7-8P.3.6.1 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "PARASUT_CREDENTIAL_UI_READY_WITH_REAL_API_CLOSED" "7-8P.3.6.2 Code readiness decision"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui.go" "real_api_enabled_must_remain_false_in_credential_ui_phase" "7-8P.3.6.3 Code real API blocker"

check_grep "internal/platform/integrations/runtime/parasut_credential_ui_test.go" "TestParasutAdminIntegrationSurfaceContract_7_8P_3_1" "7-8P.3.1.11 Test admin surface"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui_test.go" "TestParasutCredentialFormContract_7_8P_3_2" "7-8P.3.2.11 Test credential form"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui_test.go" "TestParasutSaveCredentialAction_7_8P_3_3" "7-8P.3.3.7 Test save action"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui_test.go" "TestParasutDryRunTestConnectionAction_7_8P_3_4" "7-8P.3.4.8 Test dry-run connection"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui_test.go" "TestParasutDisableAndRotateActions_7_8P_3_5" "7-8P.3.5.12 Test disable rotate"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui_test.go" "TestParasutCredentialUIRoleAndTenantGuards_7_8P_3_5_X" "7-8P.3.5.13 Test role tenant guards"
check_grep "internal/platform/integrations/runtime/parasut_credential_ui_test.go" "TestParasutCredentialUIFinalClosure_7_8P_3_6" "7-8P.3.6.4 Test final closure"

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

echo "===== 7-8P.3 PARASUT CREDENTIAL UI REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_3_PARASUT_CREDENTIAL_UI_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
