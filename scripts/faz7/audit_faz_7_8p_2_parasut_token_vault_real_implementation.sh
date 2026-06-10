#!/usr/bin/env bash
set -u

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_REAL_IMPLEMENTATION_AUDIT.md"
AUDIT_ENV_FILE="/tmp/faz_7_8p_2_parasut_token_vault_audit.env"

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

echo "# FAZ 7-8P.2 Paraşüt Token Vault Real Implementation Audit" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$AUDIT_EVIDENCE_FILE"
echo "" >> "$AUDIT_EVIDENCE_FILE"

echo "===== 7-8P.2 PARASUT TOKEN VAULT REAL IMPLEMENTATION AUDIT CHECKS ====="

check_file "docs/faz7/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_READINESS.md" "7-8P.2.0.1 Documentation artifact"
check_file "configs/faz7/parasut_token_vault.v1.json" "7-8P.2.0.2 Config artifact"
check_file "internal/platform/integrations/runtime/parasut_token_vault.go" "7-8P.2.0.3 Token vault code"
check_file "internal/platform/integrations/runtime/parasut_token_vault_test.go" "7-8P.2.0.4 Token vault test code"

check_grep "docs/faz7/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_READINESS.md" "FAZ 7-8P.2 Paraşüt Token Vault / Secret Reference / Credential Storage Readiness" "7-8P.2.0.5 Scope document title"
check_grep "docs/faz7/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_READINESS.md" "Panel → Ayarlar → Entegrasyonlar → Paraşüt → Bağlan / API Bilgileri" "7-8P.2.1.0 User API entry surface documented"
check_grep "docs/faz7/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_READINESS.md" "7-8P.2.1 Credential Entry Surface Contract" "7-8P.2.1.1 Scope doc credential entry"
check_grep "docs/faz7/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_READINESS.md" "7-8P.2.2 Secret Reference Model" "7-8P.2.2.0 Scope doc secret reference"
check_grep "docs/faz7/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_READINESS.md" "7-8P.2.3 In-Memory Vault Contract Foundation" "7-8P.2.3.0 Scope doc vault"
check_grep "docs/faz7/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_READINESS.md" "7-8P.2.4 Credential Storage Contract" "7-8P.2.4.0 Scope doc credential storage"
check_grep "docs/faz7/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_READINESS.md" "7-8P.2.5 Rotation / Revocation / Expiry Readiness" "7-8P.2.5.0 Scope doc rotation revocation"
check_grep "docs/faz7/FAZ_7_8P_2_PARASUT_TOKEN_VAULT_READINESS.md" "7-8P.2.6 Final Closure" "7-8P.2.6.0 Scope doc final closure"

check_grep "configs/faz7/parasut_token_vault.v1.json" '"provider_key": "parasut"' "7-8P.2.0.6 Config provider key"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"real_provider_api_enabled": false' "7-8P.2.0.7 Config real provider API disabled"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"Panel > Ayarlar > Entegrasyonlar > Paraşüt > Bağlan / API Bilgileri"' "7-8P.2.1.2 Config UI entry path"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"TENANT_ADMIN"' "7-8P.2.1.3 Config tenant admin role"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"INTEGRATION_ADMIN"' "7-8P.2.1.4 Config integration admin role"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"secret_plaintext_never_persisted": true' "7-8P.2.1.5 Config plaintext never persisted"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"format": "secret://pix2pi/{tenant_id}/parasut/{secret_kind}/v{version}"' "7-8P.2.2.1 Config secret ref format"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"CLIENT_SECRET"' "7-8P.2.2.2 Config client secret kind"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"WEBHOOK_SECRET"' "7-8P.2.2.3 Config webhook secret kind"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"ACCESS_TOKEN"' "7-8P.2.2.4 Config access token kind"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"REFRESH_TOKEN"' "7-8P.2.2.5 Config refresh token kind"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"store_secret": true' "7-8P.2.3.1 Config store secret"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"rotate_secret": true' "7-8P.2.5.1 Config rotate secret"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"revoke_secret": true' "7-8P.2.5.2 Config revoke secret"
check_grep "configs/faz7/parasut_token_vault.v1.json" '"plaintext_db_storage_allowed": false' "7-8P.2.4.1 Config plaintext DB storage denied"

check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "type ParasutCredentialEntrySurface struct" "7-8P.2.1.6 Code credential entry surface"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "DefaultParasutCredentialEntrySurface" "7-8P.2.1.7 Code default credential entry surface"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "CanRoleManage" "7-8P.2.1.8 Code role guard"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "CredentialEntryRoleTenantAdmin" "7-8P.2.1.9 Code tenant admin role"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "CredentialEntryRoleIntegrationAdmin" "7-8P.2.1.10 Code integration admin role"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "SecretPlaintextNeverPersisted" "7-8P.2.1.11 Code plaintext never persisted field"

check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "type ParasutSecretKind string" "7-8P.2.2.6 Code secret kind model"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "ParasutSecretKindClientSecret" "7-8P.2.2.7 Code client secret kind"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "ParasutSecretKindWebhookSecret" "7-8P.2.2.8 Code webhook secret kind"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "ParasutSecretKindAccessToken" "7-8P.2.2.9 Code access token kind"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "ParasutSecretKindRefreshToken" "7-8P.2.2.10 Code refresh token kind"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "type ParasutSecretReference struct" "7-8P.2.2.11 Code secret reference model"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "buildParasutSecretRef" "7-8P.2.2.12 Code secret ref builder"

check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "type InMemoryParasutCredentialVault struct" "7-8P.2.3.2 Code in-memory vault contract"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "StoreSecret" "7-8P.2.3.3 Code store secret"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "FindSecretReference" "7-8P.2.3.4 Code find secret reference"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "ResolveRawSecret" "7-8P.2.3.5 Code raw secret resolver"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "raw secret resolve blocked until provider live module" "7-8P.2.3.6 Code raw resolve blocked while live closed"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "tenant mismatch for secret lookup" "7-8P.2.3.7 Code tenant-safe lookup"

check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "type ParasutCredentialSet struct" "7-8P.2.4.2 Code credential set model"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "BuildParasutCredentialSet" "7-8P.2.4.3 Code credential set builder"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "ClientSecretRef" "7-8P.2.4.4 Code client secret ref field"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "WebhookSecretRef" "7-8P.2.4.5 Code webhook secret ref field"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "AccessTokenRef" "7-8P.2.4.6 Code access token ref field"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "RefreshTokenRef" "7-8P.2.4.7 Code refresh token ref field"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "isParasutSecretRefForTenant" "7-8P.2.4.8 Code tenant-safe secret ref validator"

check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "RotateSecret" "7-8P.2.5.3 Code rotate secret"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "RevokeSecret" "7-8P.2.5.4 Code revoke secret"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "ParasutCredentialStatusRotated" "7-8P.2.5.5 Code rotated status"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "ParasutCredentialStatusRevoked" "7-8P.2.5.6 Code revoked status"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "ParasutCredentialStatusExpired" "7-8P.2.5.7 Code expired status"

check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "EvaluateParasutTokenVaultReadinessGate" "7-8P.2.6.1 Code final readiness gate"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "PARASUT_TOKEN_VAULT_READY_WITH_REAL_API_CLOSED" "7-8P.2.6.2 Code readiness decision"
check_grep "internal/platform/integrations/runtime/parasut_token_vault.go" "real_api_enabled_must_remain_false_in_token_vault_phase" "7-8P.2.6.3 Code real API blocker"

check_grep "internal/platform/integrations/runtime/parasut_token_vault_test.go" "TestParasutCredentialEntrySurface_7_8P_2_1" "7-8P.2.1.12 Test credential entry surface"
check_grep "internal/platform/integrations/runtime/parasut_token_vault_test.go" "TestParasutSecretReferenceModel_7_8P_2_2" "7-8P.2.2.13 Test secret reference model"
check_grep "internal/platform/integrations/runtime/parasut_token_vault_test.go" "TestParasutVaultContractFoundation_7_8P_2_3" "7-8P.2.3.8 Test vault contract"
check_grep "internal/platform/integrations/runtime/parasut_token_vault_test.go" "TestParasutCredentialStorageContract_7_8P_2_4" "7-8P.2.4.9 Test credential storage"
check_grep "internal/platform/integrations/runtime/parasut_token_vault_test.go" "TestParasutRotationRevocationExpiryReadiness_7_8P_2_5" "7-8P.2.5.8 Test rotation revocation"
check_grep "internal/platform/integrations/runtime/parasut_token_vault_test.go" "TestParasutTokenVaultFinalClosure_7_8P_2_6" "7-8P.2.6.4 Test final closure"

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

echo "===== 7-8P.2 PARASUT TOKEN VAULT REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"
echo "FAZ_7_8P_2_PARASUT_TOKEN_VAULT_REAL_IMPLEMENTATION_STATUS=$REAL_STATUS"

if [ "$REAL_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
