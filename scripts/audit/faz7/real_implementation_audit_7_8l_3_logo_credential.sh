#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8L_3_LOGO_CREDENTIAL_SECRET_REFERENCE_READINESS.md"
CONFIG_FILE="configs/faz7/logo_credential_secret_reference.v1.json"
CODE_DIR="internal/platform/integrations/providers/logo"
FOUNDATION_FILE="internal/platform/integrations/providers/logo/logo_foundation.go"
LIVE_CONTRACT_FILE="internal/platform/integrations/providers/logo/logo_live_contract.go"
CODE_FILE="internal/platform/integrations/providers/logo/logo_credential.go"
TEST_FILE="internal/platform/integrations/providers/logo/logo_credential_test.go"
FLAT_WRONG_FILE="internal/platform/integrations/runtime/logo_credential.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8L_3_LOGO_CREDENTIAL_REAL_IMPLEMENTATION_AUDIT.md"
COUNT_FILE="/tmp/faz_7_8l_3_logo_credential_audit_counts.env"
TMP_BODY="$(mktemp)"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

pass() {
  local label="$1"
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "${label} IMPLEMENTED_OR_PRESENT / OK ✅"
  echo "- ${label}: IMPLEMENTED_OR_PRESENT / OK" >> "$TMP_BODY"
}

fail() {
  local label="$1"
  local detail="$2"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "${label} REQUIRED_FAIL / ERROR ❌ :: ${detail}"
  echo "- ${label}: REQUIRED_FAIL :: ${detail}" >> "$TMP_BODY"
}

check_file() {
  local label="$1"
  local file="$2"
  if [ -s "$file" ]; then
    pass "$label"
  else
    fail "$label" "$file missing or empty"
  fi
}

check_dir() {
  local label="$1"
  local dir="$2"
  if [ -d "$dir" ]; then
    pass "$label"
  else
    fail "$label" "$dir missing"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -s "$file" ] && grep -Fq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label" "pattern not found: ${pattern}"
  fi
}

check_json() {
  local label="$1"
  local file="$2"
  if python3 -m json.tool "$file" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label" "invalid json: ${file}"
  fi
}

check_absent_file() {
  local label="$1"
  local file="$2"
  if [ ! -e "$file" ]; then
    pass "$label"
  else
    fail "$label" "wrong file exists: ${file}"
  fi
}

check_no_real_secret_assignment() {
  local label="$1"
  local file="$2"
  if [ ! -s "$file" ]; then
    fail "$label" "$file missing"
    return
  fi

  if grep -Eiq '(api[_-]?key|password|token|refresh[_-]?token|client[_-]?secret|private[_-]?key|certificate)[[:space:]]*[:=][[:space:]]*["'\''][^"'\'']{8,}["'\'']' "$file"; then
    fail "$label" "possible raw secret assignment detected in ${file}"
  else
    pass "$label"
  fi
}

echo "===== 7-8L.3 LOGO CREDENTIAL REAL IMPLEMENTATION AUDIT ====="

check_file "7-8L.3.1 doc artifact" "$DOC_FILE"
check_file "7-8L.3.2 config artifact" "$CONFIG_FILE"
check_dir "7-8L.3.3 provider logo directory" "$CODE_DIR"
check_file "7-8L.3.4 foundation runtime dependency" "$FOUNDATION_FILE"
check_file "7-8L.3.5 live contract runtime dependency" "$LIVE_CONTRACT_FILE"
check_file "7-8L.3.6 Go runtime code artifact" "$CODE_FILE"
check_file "7-8L.3.7 Go test artifact" "$TEST_FILE"
check_json "7-8L.3.8 config json validity" "$CONFIG_FILE"

check_grep "7-8L.3.9 module marker in doc" "$DOC_FILE" "FAZ 7-8L.3"
check_grep "7-8L.3.10 provider directory in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/"
check_grep "7-8L.3.11 runtime filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_credential.go"
check_grep "7-8L.3.12 test filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_credential_test.go"
check_grep "7-8L.3.13 provider identity in doc" "$DOC_FILE" "Provider code: LOGO"
check_grep "7-8L.3.14 credential mode in doc" "$DOC_FILE" "Credential mode: SECRET_REFERENCE_ONLY"
check_grep "7-8L.3.15 forbidden raw secret in doc" "$DOC_FILE" "raw_api_key"
check_grep "7-8L.3.16 real provider API closed in doc" "$DOC_FILE" "LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.3.17 real file delivery closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
check_grep "7-8L.3.18 real ERP write closed in doc" "$DOC_FILE" "LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
check_grep "7-8L.3.19 real secret value forbidden in doc" "$DOC_FILE" "LOGO_REAL_SECRET_VALUE_STATUS=FORBIDDEN_IN_CODE_CONFIG_DOCS"
check_grep "7-8L.3.20 next step marker in doc" "$DOC_FILE" "FAZ 7-8L.4"

check_grep "7-8L.3.21 module marker in config" "$CONFIG_FILE" "\"module\": \"FAZ_7_8L\""
check_grep "7-8L.3.22 step marker in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.3\""
check_grep "7-8L.3.23 provider code in config" "$CONFIG_FILE" "\"provider_code\": \"LOGO\""
check_grep "7-8L.3.24 provider directory in config" "$CONFIG_FILE" "\"provider_directory\": \"internal/platform/integrations/providers/logo\""
check_grep "7-8L.3.25 runtime file in config" "$CONFIG_FILE" "\"runtime_file\": \"internal/platform/integrations/providers/logo/logo_credential.go\""
check_grep "7-8L.3.26 test file in config" "$CONFIG_FILE" "\"test_file\": \"internal/platform/integrations/providers/logo/logo_credential_test.go\""
check_grep "7-8L.3.27 credential mode in config" "$CONFIG_FILE" "\"credential_mode\": \"SECRET_REFERENCE_ONLY\""
check_grep "7-8L.3.28 credential profile in config" "$CONFIG_FILE" "\"credential_profile\""
check_grep "7-8L.3.29 secret reference contract in config" "$CONFIG_FILE" "\"secret_reference_contract\""
check_grep "7-8L.3.30 raw secret disabled in config" "$CONFIG_FILE" "\"raw_secret_allowed\": false"
check_grep "7-8L.3.31 secret values config disabled" "$CONFIG_FILE" "\"secret_values_in_config_allowed\": false"
check_grep "7-8L.3.32 secret values code disabled" "$CONFIG_FILE" "\"secret_values_in_code_allowed\": false"
check_grep "7-8L.3.33 secret values docs disabled" "$CONFIG_FILE" "\"secret_values_in_docs_allowed\": false"
check_grep "7-8L.3.34 real provider API closed in config" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.3.35 real file delivery closed in config" "$CONFIG_FILE" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\""
check_grep "7-8L.3.36 real ERP write closed in config" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""
check_grep "7-8L.3.37 real secret value forbidden in config" "$CONFIG_FILE" "\"real_secret_value_status\": \"FORBIDDEN_IN_CODE_CONFIG_DOCS\""

check_grep "7-8L.3.38 package logo" "$CODE_FILE" "package logo"
check_grep "7-8L.3.39 credential contract struct" "$CODE_FILE" "type LogoCredentialContract struct"
check_grep "7-8L.3.40 credential constructor" "$CODE_FILE" "func NewLogoCredentialContract() LogoCredentialContract"
check_grep "7-8L.3.41 credential validator" "$CODE_FILE" "func (c LogoCredentialContract) Validate() error"
check_grep "7-8L.3.42 credential profile type" "$CODE_FILE" "type LogoCredentialProfile struct"
check_grep "7-8L.3.43 secret reference type" "$CODE_FILE" "type LogoSecretReferenceContract struct"
check_grep "7-8L.3.44 rotation policy type" "$CODE_FILE" "type LogoCredentialRotationPolicy struct"
check_grep "7-8L.3.45 audit policy type" "$CODE_FILE" "type LogoCredentialAuditPolicy struct"
check_grep "7-8L.3.46 credential reference type" "$CODE_FILE" "type LogoCredentialReference struct"
check_grep "7-8L.3.47 reference constructor" "$CODE_FILE" "func NewLogoDryRunCredentialReference"
check_grep "7-8L.3.48 reference only validator" "$CODE_FILE" "func (r LogoCredentialReference) ValidateReferenceOnly() error"
check_grep "7-8L.3.49 raw secret detector" "$CODE_FILE" "func (r LogoCredentialReference) ContainsRawSecret() bool"
check_grep "7-8L.3.50 credential mode const" "$CODE_FILE" "LogoCredentialMode"
check_grep "7-8L.3.51 real secret forbidden const" "$CODE_FILE" "LogoRealSecretValueStatus"
check_grep "7-8L.3.52 external call denied model" "$CODE_FILE" "ExternalCallAllowed"
check_grep "7-8L.3.53 file delivery denied model" "$CODE_FILE" "FileDeliveryAllowed"
check_grep "7-8L.3.54 ERP write denied model" "$CODE_FILE" "ERPWriteAllowed"
check_grep "7-8L.3.55 raw secret denied model" "$CODE_FILE" "RawSecretAllowed"

check_grep "7-8L.3.56 package logo test" "$TEST_FILE" "package logo"
check_grep "7-8L.3.57 credential readiness test" "$TEST_FILE" "TestLogoCredentialContractReadiness"
check_grep "7-8L.3.58 integrations closed test" "$TEST_FILE" "TestLogoCredentialKeepsRealIntegrationsAndSecretsClosed"
check_grep "7-8L.3.59 secret reference only test" "$TEST_FILE" "TestLogoSecretReferenceOnlyContract"
check_grep "7-8L.3.60 credential reference validation test" "$TEST_FILE" "TestLogoCredentialReferenceValidation"
check_grep "7-8L.3.61 raw secret rejection test" "$TEST_FILE" "TestLogoCredentialReferenceRejectsRawSecret"
check_grep "7-8L.3.62 raw secret allowed rejection test" "$TEST_FILE" "TestLogoCredentialContractRejectsRawSecretAllowed"
check_grep "7-8L.3.63 secret logging rejection test" "$TEST_FILE" "TestLogoCredentialContractRejectsSecretLogging"
check_grep "7-8L.3.64 external operation rejection test" "$TEST_FILE" "TestLogoCredentialContractRejectsExternalOperation"

check_no_real_secret_assignment "7-8L.3.65 no raw secret assignment in config" "$CONFIG_FILE"
check_no_real_secret_assignment "7-8L.3.66 no raw secret assignment in code" "$CODE_FILE"
check_no_real_secret_assignment "7-8L.3.67 no raw secret assignment in doc" "$DOC_FILE"

check_absent_file "7-8L.3.68 runtime flat Logo credential file absent" "$FLAT_WRONG_FILE"

{
  echo "# FAZ 7-8L.3 Logo Credential Real Implementation Audit"
  echo
  echo "## Result"
  echo
  echo "- PASS_COUNT=${PASS_COUNT}"
  echo "- FAIL_COUNT=${FAIL_COUNT}"
  echo "- REQUIRED_FAIL=${REQUIRED_FAIL}"
  echo "- OPTIONAL_WARN=${OPTIONAL_WARN}"
  echo
  echo "## Evidence"
  echo
  cat "$TMP_BODY"
} > "$EVIDENCE_FILE"

cat <<COUNT_EOF > "$COUNT_FILE"
PASS_COUNT=${PASS_COUNT}
FAIL_COUNT=${FAIL_COUNT}
REQUIRED_FAIL=${REQUIRED_FAIL}
OPTIONAL_WARN=${OPTIONAL_WARN}
AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}
COUNT_EOF

echo "===== 7-8L.3 LOGO CREDENTIAL REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

rm -f "$TMP_BODY"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8L_3_LOGO_CREDENTIAL_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8L_3_LOGO_CREDENTIAL_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
