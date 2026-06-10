#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8L_1_LOGO_CONNECTOR_FOUNDATION.md"
CONFIG_FILE="configs/faz7/logo_connector_foundation.v1.json"
CODE_DIR="internal/platform/integrations/providers/logo"
CODE_FILE="internal/platform/integrations/providers/logo/logo_foundation.go"
TEST_FILE="internal/platform/integrations/providers/logo/logo_foundation_test.go"
OLD_CODE_FILE="internal/platform/integrations/logo/foundation.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8L_1_LOGO_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_AUDIT.md"
COUNT_FILE="/tmp/faz_7_8l_1_logo_connector_foundation_audit_counts.env"
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
    fail "$label" "old/incorrect file still exists: ${file}"
  fi
}

echo "===== 7-8L.1 LOGO CONNECTOR FOUNDATION REAL IMPLEMENTATION AUDIT ====="

check_file "7-8L.1.1 doc artifact" "$DOC_FILE"
check_file "7-8L.1.2 config artifact" "$CONFIG_FILE"
check_dir "7-8L.1.3 provider logo directory" "$CODE_DIR"
check_file "7-8L.1.4 Go runtime code artifact" "$CODE_FILE"
check_file "7-8L.1.5 Go test artifact" "$TEST_FILE"

check_json "7-8L.1.6 config json validity" "$CONFIG_FILE"

check_grep "7-8L.1.7 module marker in doc" "$DOC_FILE" "FAZ 7-8L.1"
check_grep "7-8L.1.8 provider directory in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/"
check_grep "7-8L.1.9 runtime filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_foundation.go"
check_grep "7-8L.1.10 test filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_foundation_test.go"
check_grep "7-8L.1.11 provider identity in doc" "$DOC_FILE" "Provider code: LOGO"
check_grep "7-8L.1.12 real provider API closed in doc" "$DOC_FILE" "LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.1.13 real file delivery closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
check_grep "7-8L.1.14 real ERP write closed in doc" "$DOC_FILE" "LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"

check_grep "7-8L.1.15 module marker in config" "$CONFIG_FILE" "\"module\": \"FAZ_7_8L\""
check_grep "7-8L.1.16 step marker in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.1\""
check_grep "7-8L.1.17 provider code in config" "$CONFIG_FILE" "\"provider_code\": \"LOGO\""
check_grep "7-8L.1.18 connector code in config" "$CONFIG_FILE" "\"connector_code\": \"logo_connector\""
check_grep "7-8L.1.19 provider directory in config" "$CONFIG_FILE" "\"provider_directory\": \"internal/platform/integrations/providers/logo\""
check_grep "7-8L.1.20 runtime file in config" "$CONFIG_FILE" "\"runtime_file\": \"internal/platform/integrations/providers/logo/logo_foundation.go\""
check_grep "7-8L.1.21 test file in config" "$CONFIG_FILE" "\"test_file\": \"internal/platform/integrations/providers/logo/logo_foundation_test.go\""
check_grep "7-8L.1.22 dry-run mode in config" "$CONFIG_FILE" "\"mode\": \"DRY_RUN\""
check_grep "7-8L.1.23 real provider API closed in config" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.1.24 real file delivery closed in config" "$CONFIG_FILE" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\""
check_grep "7-8L.1.25 real ERP write closed in config" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""

check_grep "7-8L.1.26 package logo" "$CODE_FILE" "package logo"
check_grep "7-8L.1.27 provider identity runtime struct" "$CODE_FILE" "type ProviderIdentity struct"
check_grep "7-8L.1.28 provider code const" "$CODE_FILE" "ProviderCode"
check_grep "7-8L.1.29 provider code value" "$CODE_FILE" "\"LOGO\""
check_grep "7-8L.1.30 connector code const" "$CODE_FILE" "ConnectorCode"
check_grep "7-8L.1.31 connector code value" "$CODE_FILE" "\"logo_connector\""
check_grep "7-8L.1.32 dry-run const" "$CODE_FILE" "RuntimeModeDryRun"
check_grep "7-8L.1.33 dry-run value" "$CODE_FILE" "\"DRY_RUN\""
check_grep "7-8L.1.34 real provider closed const" "$CODE_FILE" "RealProviderAPIClosedStatus"
check_grep "7-8L.1.35 real file delivery closed const" "$CODE_FILE" "RealFileDeliveryClosedStatus"
check_grep "7-8L.1.36 real ERP write closed const" "$CODE_FILE" "RealERPWriteClosedStatus"
check_grep "7-8L.1.37 real integrations closed guard" "$CODE_FILE" "func (p ProviderIdentity) RealIntegrationsClosed() bool"
check_grep "7-8L.1.38 validation guard" "$CODE_FILE" "func (p ProviderIdentity) Validate() error"
check_grep "7-8L.1.39 external call denied model" "$CODE_FILE" "ExternalCallAllowed bool"
check_grep "7-8L.1.40 ERP write denied model" "$CODE_FILE" "ERPWriteAllowed"

check_grep "7-8L.1.41 package logo test" "$TEST_FILE" "package logo"
check_grep "7-8L.1.42 provider identity test" "$TEST_FILE" "TestLogoProviderIdentityFoundation"
check_grep "7-8L.1.43 real integrations closed test" "$TEST_FILE" "TestLogoRealIntegrationsRemainClosed"
check_grep "7-8L.1.44 capability test" "$TEST_FILE" "TestLogoCapabilitiesAndOperations"
check_grep "7-8L.1.45 open API rejection test" "$TEST_FILE" "TestLogoProviderIdentityRejectsOpenRealProviderAPI"
check_grep "7-8L.1.46 external operation rejection test" "$TEST_FILE" "TestLogoProviderIdentityRejectsExternalOperation"

check_absent_file "7-8L.1.47 old flat logo foundation file absent" "$OLD_CODE_FILE"

{
  echo "# FAZ 7-8L.1 Logo Connector Foundation Real Implementation Audit"
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

echo "===== 7-8L.1 LOGO CONNECTOR FOUNDATION REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

rm -f "$TMP_BODY"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8L_1_LOGO_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8L_1_LOGO_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
