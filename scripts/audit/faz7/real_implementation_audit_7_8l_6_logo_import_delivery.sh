#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8L_6_LOGO_IMPORT_PACKAGE_DELIVERY_CONTRACT.md"
CONFIG_FILE="configs/faz7/logo_import_delivery_contract.v1.json"
CODE_DIR="internal/platform/integrations/providers/logo"
FOUNDATION_FILE="internal/platform/integrations/providers/logo/logo_foundation.go"
LIVE_CONTRACT_FILE="internal/platform/integrations/providers/logo/logo_live_contract.go"
CREDENTIAL_FILE="internal/platform/integrations/providers/logo/logo_credential.go"
EXPORT_MAPPING_FILE="internal/platform/integrations/providers/logo/logo_export_mapping.go"
FILE_GENERATION_FILE="internal/platform/integrations/providers/logo/logo_file_generation.go"
CODE_FILE="internal/platform/integrations/providers/logo/logo_import_delivery.go"
TEST_FILE="internal/platform/integrations/providers/logo/logo_import_delivery_test.go"
FLAT_WRONG_FILE="internal/platform/integrations/runtime/logo_import_delivery.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8L_6_LOGO_IMPORT_DELIVERY_REAL_IMPLEMENTATION_AUDIT.md"
COUNT_FILE="/tmp/faz_7_8l_6_logo_import_delivery_audit_counts.env"
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

echo "===== 7-8L.6 LOGO IMPORT DELIVERY REAL IMPLEMENTATION AUDIT ====="

check_file "7-8L.6.1 doc artifact" "$DOC_FILE"
check_file "7-8L.6.2 config artifact" "$CONFIG_FILE"
check_dir "7-8L.6.3 provider logo directory" "$CODE_DIR"
check_file "7-8L.6.4 foundation runtime dependency" "$FOUNDATION_FILE"
check_file "7-8L.6.5 live contract runtime dependency" "$LIVE_CONTRACT_FILE"
check_file "7-8L.6.6 credential runtime dependency" "$CREDENTIAL_FILE"
check_file "7-8L.6.7 export mapping runtime dependency" "$EXPORT_MAPPING_FILE"
check_file "7-8L.6.8 file generation runtime dependency" "$FILE_GENERATION_FILE"
check_file "7-8L.6.9 Go runtime code artifact" "$CODE_FILE"
check_file "7-8L.6.10 Go test artifact" "$TEST_FILE"
check_json "7-8L.6.11 config json validity" "$CONFIG_FILE"

check_grep "7-8L.6.12 module marker in doc" "$DOC_FILE" "FAZ 7-8L.6"
check_grep "7-8L.6.13 provider directory in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/"
check_grep "7-8L.6.14 runtime filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_import_delivery.go"
check_grep "7-8L.6.15 test filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_import_delivery_test.go"
check_grep "7-8L.6.16 provider identity in doc" "$DOC_FILE" "Provider code: LOGO"
check_grep "7-8L.6.17 delivery mode in doc" "$DOC_FILE" "Delivery mode: IMPORT_PACKAGE_DELIVERY_CONTRACT_ONLY"
check_grep "7-8L.6.18 target system in doc" "$DOC_FILE" "Target system: LOGO_ACCOUNTING_IMPORT_DRY_RUN"
check_grep "7-8L.6.19 manual upload placeholder in doc" "$DOC_FILE" "MANUAL_UPLOAD_PLACEHOLDER"
check_grep "7-8L.6.20 SFTP placeholder in doc" "$DOC_FILE" "SFTP_PLACEHOLDER"
check_grep "7-8L.6.21 provider API placeholder in doc" "$DOC_FILE" "PROVIDER_API_PLACEHOLDER"
check_grep "7-8L.6.22 delivery envelope in doc" "$DOC_FILE" "delivery_id"
check_grep "7-8L.6.23 checksum in doc" "$DOC_FILE" "checksum_sha256"
check_grep "7-8L.6.24 delivery disabled in doc" "$DOC_FILE" "delivery_allowed=false"
check_grep "7-8L.6.25 real provider API closed in doc" "$DOC_FILE" "LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.6.26 real file delivery closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
check_grep "7-8L.6.27 real ERP write closed in doc" "$DOC_FILE" "LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
check_grep "7-8L.6.28 real channel closed in doc" "$DOC_FILE" "LOGO_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.6.29 next step marker in doc" "$DOC_FILE" "FAZ 7-8L.7"

check_grep "7-8L.6.30 module marker in config" "$CONFIG_FILE" "\"module\": \"FAZ_7_8L\""
check_grep "7-8L.6.31 step marker in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.6\""
check_grep "7-8L.6.32 provider code in config" "$CONFIG_FILE" "\"provider_code\": \"LOGO\""
check_grep "7-8L.6.33 provider directory in config" "$CONFIG_FILE" "\"provider_directory\": \"internal/platform/integrations/providers/logo\""
check_grep "7-8L.6.34 runtime file in config" "$CONFIG_FILE" "\"runtime_file\": \"internal/platform/integrations/providers/logo/logo_import_delivery.go\""
check_grep "7-8L.6.35 test file in config" "$CONFIG_FILE" "\"test_file\": \"internal/platform/integrations/providers/logo/logo_import_delivery_test.go\""
check_grep "7-8L.6.36 delivery mode in config" "$CONFIG_FILE" "\"delivery_mode\": \"IMPORT_PACKAGE_DELIVERY_CONTRACT_ONLY\""
check_grep "7-8L.6.37 target system in config" "$CONFIG_FILE" "\"target_system\": \"LOGO_ACCOUNTING_IMPORT_DRY_RUN\""
check_grep "7-8L.6.38 delivery contract status in config" "$CONFIG_FILE" "\"import_delivery_contract_status\": \"READY\""
check_grep "7-8L.6.39 delivery contract object in config" "$CONFIG_FILE" "\"delivery_contract\""
check_grep "7-8L.6.40 delivery channels in config" "$CONFIG_FILE" "\"delivery_channels\""
check_grep "7-8L.6.41 manual upload in config" "$CONFIG_FILE" "\"name\": \"MANUAL_UPLOAD_PLACEHOLDER\""
check_grep "7-8L.6.42 SFTP in config" "$CONFIG_FILE" "\"name\": \"SFTP_PLACEHOLDER\""
check_grep "7-8L.6.43 provider API in config" "$CONFIG_FILE" "\"name\": \"PROVIDER_API_PLACEHOLDER\""
check_grep "7-8L.6.44 dry run only in config" "$CONFIG_FILE" "\"dry_run_only\": true"
check_grep "7-8L.6.45 real delivery disabled in config" "$CONFIG_FILE" "\"real_delivery_allowed\": false"
check_grep "7-8L.6.46 external call disabled in config" "$CONFIG_FILE" "\"external_call_allowed\": false"
check_grep "7-8L.6.47 ERP write disabled in config" "$CONFIG_FILE" "\"erp_write_allowed\": false"
check_grep "7-8L.6.48 checksum required in config" "$CONFIG_FILE" "\"checksum_required\": true"
check_grep "7-8L.6.49 manifest required in config" "$CONFIG_FILE" "\"manifest_required\": true"
check_grep "7-8L.6.50 tenant required in config" "$CONFIG_FILE" "\"tenant_scope_required\": true"
check_grep "7-8L.6.51 correlation required in config" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "7-8L.6.52 idempotency required in config" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "7-8L.6.53 real provider API closed in config" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.6.54 real file delivery closed in config" "$CONFIG_FILE" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\""
check_grep "7-8L.6.55 real ERP write closed in config" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""
check_grep "7-8L.6.56 real channel closed in config" "$CONFIG_FILE" "\"real_delivery_channel_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""

check_grep "7-8L.6.57 package logo" "$CODE_FILE" "package logo"
check_grep "7-8L.6.58 import delivery contract struct" "$CODE_FILE" "type LogoImportDeliveryContract struct"
check_grep "7-8L.6.59 delivery contract type" "$CODE_FILE" "type LogoDeliveryContract struct"
check_grep "7-8L.6.60 delivery channel type" "$CODE_FILE" "type LogoDeliveryChannel struct"
check_grep "7-8L.6.61 delivery envelope type" "$CODE_FILE" "type LogoImportDeliveryEnvelope struct"
check_grep "7-8L.6.62 operation contract type" "$CODE_FILE" "type LogoImportDeliveryOperationContract struct"
check_grep "7-8L.6.63 import delivery constructor" "$CODE_FILE" "func NewLogoImportDeliveryContract() LogoImportDeliveryContract"
check_grep "7-8L.6.64 import delivery validator" "$CODE_FILE" "func (c LogoImportDeliveryContract) Validate() error"
check_grep "7-8L.6.65 real integrations closed guard" "$CODE_FILE" "func (c LogoImportDeliveryContract) RealIntegrationsClosed() bool"
check_grep "7-8L.6.66 delivery channels validator" "$CODE_FILE" "func (c LogoImportDeliveryContract) ValidateDeliveryChannels() error"
check_grep "7-8L.6.67 operations validator" "$CODE_FILE" "func (c LogoImportDeliveryContract) ValidateOperations() error"
check_grep "7-8L.6.68 prepare envelope method" "$CODE_FILE" "func (c LogoImportDeliveryContract) PrepareDryRunDeliveryEnvelope"
check_grep "7-8L.6.69 delivery contract validator" "$CODE_FILE" "func (d LogoDeliveryContract) Validate() error"
check_grep "7-8L.6.70 channel validator" "$CODE_FILE" "func (c LogoDeliveryChannel) Validate() error"
check_grep "7-8L.6.71 envelope validator" "$CODE_FILE" "func (e LogoImportDeliveryEnvelope) Validate() error"
check_grep "7-8L.6.72 manual upload constant" "$CODE_FILE" "MANUAL_UPLOAD_PLACEHOLDER"
check_grep "7-8L.6.73 SFTP constant" "$CODE_FILE" "SFTP_PLACEHOLDER"
check_grep "7-8L.6.74 provider API constant" "$CODE_FILE" "PROVIDER_API_PLACEHOLDER"
check_grep "7-8L.6.75 delivery disabled guard" "$CODE_FILE" "DeliveryAllowed"
check_grep "7-8L.6.76 external call disabled guard" "$CODE_FILE" "ExternalCallAllowed"
check_grep "7-8L.6.77 ERP write disabled guard" "$CODE_FILE" "ERPWriteAllowed"

check_grep "7-8L.6.78 package logo test" "$TEST_FILE" "package logo"
check_grep "7-8L.6.79 import delivery readiness test" "$TEST_FILE" "TestLogoImportDeliveryContractReadiness"
check_grep "7-8L.6.80 integrations closed test" "$TEST_FILE" "TestLogoImportDeliveryKeepsRealIntegrationsClosed"
check_grep "7-8L.6.81 delivery channels test" "$TEST_FILE" "TestLogoDeliveryChannelsDeclaredAsPlaceholders"
check_grep "7-8L.6.82 prepare envelope test" "$TEST_FILE" "TestLogoPrepareDryRunDeliveryEnvelope"
check_grep "7-8L.6.83 real delivery channel rejection test" "$TEST_FILE" "TestLogoImportDeliveryRejectsRealDeliveryChannel"
check_grep "7-8L.6.84 external operation rejection test" "$TEST_FILE" "TestLogoImportDeliveryRejectsExternalOperation"
check_grep "7-8L.6.85 ERP write rejection test" "$TEST_FILE" "TestLogoImportDeliveryRejectsERPWriteOperation"
check_grep "7-8L.6.86 unknown channel rejection test" "$TEST_FILE" "TestLogoImportDeliveryRejectsUnknownChannel"
check_grep "7-8L.6.87 delivery allowed envelope rejection test" "$TEST_FILE" "TestLogoImportDeliveryEnvelopeRejectsDeliveryAllowed"

check_absent_file "7-8L.6.88 runtime flat Logo import delivery file absent" "$FLAT_WRONG_FILE"

{
  echo "# FAZ 7-8L.6 Logo Import Delivery Real Implementation Audit"
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

echo "===== 7-8L.6 LOGO IMPORT DELIVERY REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

rm -f "$TMP_BODY"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8L_6_LOGO_IMPORT_DELIVERY_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8L_6_LOGO_IMPORT_DELIVERY_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
