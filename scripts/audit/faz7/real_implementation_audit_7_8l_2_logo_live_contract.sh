#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8L_2_LOGO_LIVE_CONTRACT_API_FILE_CONTRACT_READINESS.md"
CONFIG_FILE="configs/faz7/logo_live_contract.v1.json"
CODE_DIR="internal/platform/integrations/providers/logo"
FOUNDATION_FILE="internal/platform/integrations/providers/logo/logo_foundation.go"
CODE_FILE="internal/platform/integrations/providers/logo/logo_live_contract.go"
TEST_FILE="internal/platform/integrations/providers/logo/logo_live_contract_test.go"
FLAT_WRONG_FILE="internal/platform/integrations/runtime/logo_live_contract.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8L_2_LOGO_LIVE_CONTRACT_REAL_IMPLEMENTATION_AUDIT.md"
COUNT_FILE="/tmp/faz_7_8l_2_logo_live_contract_audit_counts.env"
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

echo "===== 7-8L.2 LOGO LIVE CONTRACT REAL IMPLEMENTATION AUDIT ====="

check_file "7-8L.2.1 doc artifact" "$DOC_FILE"
check_file "7-8L.2.2 config artifact" "$CONFIG_FILE"
check_dir "7-8L.2.3 provider logo directory" "$CODE_DIR"
check_file "7-8L.2.4 foundation runtime dependency" "$FOUNDATION_FILE"
check_file "7-8L.2.5 Go runtime code artifact" "$CODE_FILE"
check_file "7-8L.2.6 Go test artifact" "$TEST_FILE"
check_json "7-8L.2.7 config json validity" "$CONFIG_FILE"

check_grep "7-8L.2.8 module marker in doc" "$DOC_FILE" "FAZ 7-8L.2"
check_grep "7-8L.2.9 provider directory in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/"
check_grep "7-8L.2.10 runtime filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_live_contract.go"
check_grep "7-8L.2.11 test filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_live_contract_test.go"
check_grep "7-8L.2.12 provider identity in doc" "$DOC_FILE" "Provider code: LOGO"
check_grep "7-8L.2.13 API contract in doc" "$DOC_FILE" "API contract declared: true"
check_grep "7-8L.2.14 file contract in doc" "$DOC_FILE" "File contract declared: true"
check_grep "7-8L.2.15 real provider API closed in doc" "$DOC_FILE" "LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.2.16 real file delivery closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
check_grep "7-8L.2.17 real ERP write closed in doc" "$DOC_FILE" "LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
check_grep "7-8L.2.18 next step marker in doc" "$DOC_FILE" "FAZ 7-8L.3"

check_grep "7-8L.2.19 module marker in config" "$CONFIG_FILE" "\"module\": \"FAZ_7_8L\""
check_grep "7-8L.2.20 step marker in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.2\""
check_grep "7-8L.2.21 provider code in config" "$CONFIG_FILE" "\"provider_code\": \"LOGO\""
check_grep "7-8L.2.22 provider directory in config" "$CONFIG_FILE" "\"provider_directory\": \"internal/platform/integrations/providers/logo\""
check_grep "7-8L.2.23 runtime file in config" "$CONFIG_FILE" "\"runtime_file\": \"internal/platform/integrations/providers/logo/logo_live_contract.go\""
check_grep "7-8L.2.24 test file in config" "$CONFIG_FILE" "\"test_file\": \"internal/platform/integrations/providers/logo/logo_live_contract_test.go\""
check_grep "7-8L.2.25 dry-run mode in config" "$CONFIG_FILE" "\"mode\": \"DRY_RUN\""
check_grep "7-8L.2.26 contract mode in config" "$CONFIG_FILE" "\"contract_mode\": \"DRY_RUN_CONTRACT_ONLY\""
check_grep "7-8L.2.27 api declared in config" "$CONFIG_FILE" "\"api_contract\""
check_grep "7-8L.2.28 api real call disabled in config" "$CONFIG_FILE" "\"real_call_allowed\": false"
check_grep "7-8L.2.29 file contract declared in config" "$CONFIG_FILE" "\"file_contract\""
check_grep "7-8L.2.30 file delivery disabled in config" "$CONFIG_FILE" "\"real_file_delivery_allowed\": false"
check_grep "7-8L.2.31 real provider API closed in config" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.2.32 real file delivery closed in config" "$CONFIG_FILE" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\""
check_grep "7-8L.2.33 real ERP write closed in config" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""

check_grep "7-8L.2.34 package logo" "$CODE_FILE" "package logo"
check_grep "7-8L.2.35 live contract struct" "$CODE_FILE" "type LogoLiveContract struct"
check_grep "7-8L.2.36 live contract constructor" "$CODE_FILE" "func NewLogoLiveContract() LogoLiveContract"
check_grep "7-8L.2.37 live contract validator" "$CODE_FILE" "func (c LogoLiveContract) Validate() error"
check_grep "7-8L.2.38 API contract type" "$CODE_FILE" "type LogoAPIContract struct"
check_grep "7-8L.2.39 file contract type" "$CODE_FILE" "type LogoFileContract struct"
check_grep "7-8L.2.40 operation contract type" "$CODE_FILE" "type LogoLiveOperationContract struct"
check_grep "7-8L.2.41 contract mode const" "$CODE_FILE" "LogoLiveContractMode"
check_grep "7-8L.2.42 API contract status" "$CODE_FILE" "LogoAPIContractStatus"
check_grep "7-8L.2.43 file contract status" "$CODE_FILE" "LogoFileContractStatus"
check_grep "7-8L.2.44 external call denied model" "$CODE_FILE" "ExternalCallAllowed"
check_grep "7-8L.2.45 file delivery denied model" "$CODE_FILE" "FileDeliveryAllowed"
check_grep "7-8L.2.46 ERP write denied model" "$CODE_FILE" "ERPWriteAllowed"
check_grep "7-8L.2.47 API declared field" "$CODE_FILE" "Declared"
check_grep "7-8L.2.48 real call allowed field" "$CODE_FILE" "RealCallAllowed"
check_grep "7-8L.2.49 real file delivery allowed field" "$CODE_FILE" "RealFileDeliveryAllowed"
check_grep "7-8L.2.50 real integrations closed guard" "$CODE_FILE" "func (c LogoLiveContract) RealIntegrationsClosed() bool"

check_grep "7-8L.2.51 package logo test" "$TEST_FILE" "package logo"
check_grep "7-8L.2.52 live contract readiness test" "$TEST_FILE" "TestLogoLiveContractReadiness"
check_grep "7-8L.2.53 real integrations closed test" "$TEST_FILE" "TestLogoLiveContractKeepsRealIntegrationsClosed"
check_grep "7-8L.2.54 API contract disabled test" "$TEST_FILE" "TestLogoAPIContractDeclaredButRealCallsDisabled"
check_grep "7-8L.2.55 file contract disabled test" "$TEST_FILE" "TestLogoFileContractDeclaredButRealDeliveryDisabled"
check_grep "7-8L.2.56 open provider API rejection test" "$TEST_FILE" "TestLogoLiveContractRejectsOpenProviderAPI"
check_grep "7-8L.2.57 real file delivery rejection test" "$TEST_FILE" "TestLogoLiveContractRejectsRealFileDelivery"
check_grep "7-8L.2.58 external operation rejection test" "$TEST_FILE" "TestLogoLiveContractRejectsExternalOperation"

check_absent_file "7-8L.2.59 runtime flat Logo live contract file absent" "$FLAT_WRONG_FILE"

{
  echo "# FAZ 7-8L.2 Logo Live Contract Real Implementation Audit"
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

echo "===== 7-8L.2 LOGO LIVE CONTRACT REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

rm -f "$TMP_BODY"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8L_2_LOGO_LIVE_CONTRACT_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8L_2_LOGO_LIVE_CONTRACT_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
