#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8L_4_LOGO_EXPORT_MAPPING_CONTRACT.md"
CONFIG_FILE="configs/faz7/logo_export_mapping_contract.v1.json"
CODE_DIR="internal/platform/integrations/providers/logo"
FOUNDATION_FILE="internal/platform/integrations/providers/logo/logo_foundation.go"
LIVE_CONTRACT_FILE="internal/platform/integrations/providers/logo/logo_live_contract.go"
CREDENTIAL_FILE="internal/platform/integrations/providers/logo/logo_credential.go"
CODE_FILE="internal/platform/integrations/providers/logo/logo_export_mapping.go"
TEST_FILE="internal/platform/integrations/providers/logo/logo_export_mapping_test.go"
FLAT_WRONG_FILE="internal/platform/integrations/runtime/logo_export_mapping.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8L_4_LOGO_EXPORT_MAPPING_REAL_IMPLEMENTATION_AUDIT.md"
COUNT_FILE="/tmp/faz_7_8l_4_logo_export_mapping_audit_counts.env"
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

echo "===== 7-8L.4 LOGO EXPORT MAPPING REAL IMPLEMENTATION AUDIT ====="

check_file "7-8L.4.1 doc artifact" "$DOC_FILE"
check_file "7-8L.4.2 config artifact" "$CONFIG_FILE"
check_dir "7-8L.4.3 provider logo directory" "$CODE_DIR"
check_file "7-8L.4.4 foundation runtime dependency" "$FOUNDATION_FILE"
check_file "7-8L.4.5 live contract runtime dependency" "$LIVE_CONTRACT_FILE"
check_file "7-8L.4.6 credential runtime dependency" "$CREDENTIAL_FILE"
check_file "7-8L.4.7 Go runtime code artifact" "$CODE_FILE"
check_file "7-8L.4.8 Go test artifact" "$TEST_FILE"
check_json "7-8L.4.9 config json validity" "$CONFIG_FILE"

check_grep "7-8L.4.10 module marker in doc" "$DOC_FILE" "FAZ 7-8L.4"
check_grep "7-8L.4.11 provider directory in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/"
check_grep "7-8L.4.12 runtime filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_export_mapping.go"
check_grep "7-8L.4.13 test filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_export_mapping_test.go"
check_grep "7-8L.4.14 provider identity in doc" "$DOC_FILE" "Provider code: LOGO"
check_grep "7-8L.4.15 mapping mode in doc" "$DOC_FILE" "Mapping mode: EXPORT_MAPPING_CONTRACT_ONLY"
check_grep "7-8L.4.16 mapping direction in doc" "$DOC_FILE" "Mapping direction: PIX2PI_TO_LOGO"
check_grep "7-8L.4.17 target system in doc" "$DOC_FILE" "Target system: LOGO_ACCOUNTING_IMPORT_DRY_RUN"
check_grep "7-8L.4.18 journal header mapping in doc" "$DOC_FILE" "PIX2PI_JOURNAL_HEADER -> LOGO_FICHE_HEADER"
check_grep "7-8L.4.19 journal line mapping in doc" "$DOC_FILE" "PIX2PI_JOURNAL_LINE -> LOGO_FICHE_LINE"
check_grep "7-8L.4.20 cari mapping in doc" "$DOC_FILE" "PIX2PI_PARTY_ACCOUNT -> LOGO_CARI_CARD"
check_grep "7-8L.4.21 tax mapping in doc" "$DOC_FILE" "PIX2PI_TAX_DETAIL -> LOGO_TAX_LINE"
check_grep "7-8L.4.22 invoice mapping in doc" "$DOC_FILE" "PIX2PI_INVOICE_SUMMARY -> LOGO_INVOICE_REFERENCE"
check_grep "7-8L.4.23 TDHP sales mapping in doc" "$DOC_FILE" "SATIS_FATURASI"
check_grep "7-8L.4.24 real provider API closed in doc" "$DOC_FILE" "LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.4.25 real file generation closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_GENERATION_STATUS=CLOSED_UNTIL_FILE_GENERATION_DRY_RUN_MODULE"
check_grep "7-8L.4.26 real file delivery closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
check_grep "7-8L.4.27 real ERP write closed in doc" "$DOC_FILE" "LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
check_grep "7-8L.4.28 next step marker in doc" "$DOC_FILE" "FAZ 7-8L.5"

check_grep "7-8L.4.29 module marker in config" "$CONFIG_FILE" "\"module\": \"FAZ_7_8L\""
check_grep "7-8L.4.30 step marker in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.4\""
check_grep "7-8L.4.31 provider code in config" "$CONFIG_FILE" "\"provider_code\": \"LOGO\""
check_grep "7-8L.4.32 provider directory in config" "$CONFIG_FILE" "\"provider_directory\": \"internal/platform/integrations/providers/logo\""
check_grep "7-8L.4.33 runtime file in config" "$CONFIG_FILE" "\"runtime_file\": \"internal/platform/integrations/providers/logo/logo_export_mapping.go\""
check_grep "7-8L.4.34 test file in config" "$CONFIG_FILE" "\"test_file\": \"internal/platform/integrations/providers/logo/logo_export_mapping_test.go\""
check_grep "7-8L.4.35 mapping mode in config" "$CONFIG_FILE" "\"mapping_mode\": \"EXPORT_MAPPING_CONTRACT_ONLY\""
check_grep "7-8L.4.36 mapping direction in config" "$CONFIG_FILE" "\"mapping_direction\": \"PIX2PI_TO_LOGO\""
check_grep "7-8L.4.37 target system in config" "$CONFIG_FILE" "\"target_system\": \"LOGO_ACCOUNTING_IMPORT_DRY_RUN\""
check_grep "7-8L.4.38 entity mappings in config" "$CONFIG_FILE" "\"entity_mappings\""
check_grep "7-8L.4.39 TDHP mappings in config" "$CONFIG_FILE" "\"tdhp_mappings\""
check_grep "7-8L.4.40 tenant mapping in config" "$CONFIG_FILE" "\"source_field\": \"tenant_id\""
check_grep "7-8L.4.41 correlation mapping in config" "$CONFIG_FILE" "\"source_field\": \"correlation_id\""
check_grep "7-8L.4.42 idempotency mapping in config" "$CONFIG_FILE" "\"source_field\": \"idempotency_key\""
check_grep "7-8L.4.43 account code mapping in config" "$CONFIG_FILE" "\"source_field\": \"account_code\""
check_grep "7-8L.4.44 tax rate mapping in config" "$CONFIG_FILE" "\"source_field\": \"tax_rate\""
check_grep "7-8L.4.45 file generation disabled in config" "$CONFIG_FILE" "\"file_generation_allowed\": false"
check_grep "7-8L.4.46 file delivery disabled in config" "$CONFIG_FILE" "\"file_delivery_allowed\": false"
check_grep "7-8L.4.47 ERP write disabled in config" "$CONFIG_FILE" "\"erp_write_allowed\": false"
check_grep "7-8L.4.48 real file generation closed in config" "$CONFIG_FILE" "\"real_file_generation_status\": \"CLOSED_UNTIL_FILE_GENERATION_DRY_RUN_MODULE\""

check_grep "7-8L.4.49 package logo" "$CODE_FILE" "package logo"
check_grep "7-8L.4.50 export mapping contract struct" "$CODE_FILE" "type LogoExportMappingContract struct"
check_grep "7-8L.4.51 field mapping type" "$CODE_FILE" "type LogoFieldMapping struct"
check_grep "7-8L.4.52 entity mapping type" "$CODE_FILE" "type LogoEntityMapping struct"
check_grep "7-8L.4.53 TDHP mapping type" "$CODE_FILE" "type LogoTDHPMapping struct"
check_grep "7-8L.4.54 operation contract type" "$CODE_FILE" "type LogoExportMappingOperationContract struct"
check_grep "7-8L.4.55 export mapping constructor" "$CODE_FILE" "func NewLogoExportMappingContract() LogoExportMappingContract"
check_grep "7-8L.4.56 export mapping validator" "$CODE_FILE" "func (c LogoExportMappingContract) Validate() error"
check_grep "7-8L.4.57 entity mapping validator" "$CODE_FILE" "func (c LogoExportMappingContract) ValidateEntityMappings() error"
check_grep "7-8L.4.58 TDHP mapping validator" "$CODE_FILE" "func (c LogoExportMappingContract) ValidateTDHPMappings() error"
check_grep "7-8L.4.59 operations validator" "$CODE_FILE" "func (c LogoExportMappingContract) ValidateOperations() error"
check_grep "7-8L.4.60 real integrations closed guard" "$CODE_FILE" "func (c LogoExportMappingContract) RealIntegrationsClosed() bool"
check_grep "7-8L.4.61 tenant required field guard" "$CODE_FILE" "tenant_id mapping is required"
check_grep "7-8L.4.62 TDHP sales value" "$CODE_FILE" "SATIS_FATURASI"
check_grep "7-8L.4.63 TDHP purchase value" "$CODE_FILE" "ALIS_FATURASI"
check_grep "7-8L.4.64 file generation denied model" "$CODE_FILE" "FileGenerationAllowed"
check_grep "7-8L.4.65 file delivery denied model" "$CODE_FILE" "FileDeliveryAllowed"
check_grep "7-8L.4.66 ERP write denied model" "$CODE_FILE" "ERPWriteAllowed"

check_grep "7-8L.4.67 package logo test" "$TEST_FILE" "package logo"
check_grep "7-8L.4.68 export mapping readiness test" "$TEST_FILE" "TestLogoExportMappingContractReadiness"
check_grep "7-8L.4.69 integrations closed test" "$TEST_FILE" "TestLogoExportMappingKeepsRealIntegrationsClosed"
check_grep "7-8L.4.70 entity mappings test" "$TEST_FILE" "TestLogoExportEntityMappingsDeclared"
check_grep "7-8L.4.71 TDHP mappings test" "$TEST_FILE" "TestLogoTDHPMappingsDeclared"
check_grep "7-8L.4.72 open provider API rejection test" "$TEST_FILE" "TestLogoExportMappingRejectsOpenProviderAPI"
check_grep "7-8L.4.73 file generation rejection test" "$TEST_FILE" "TestLogoExportMappingRejectsFileGeneration"
check_grep "7-8L.4.74 missing tenant mapping rejection test" "$TEST_FILE" "TestLogoExportMappingRejectsMissingTenantMapping"
check_grep "7-8L.4.75 external operation rejection test" "$TEST_FILE" "TestLogoExportMappingRejectsExternalOperation"

check_absent_file "7-8L.4.76 runtime flat Logo export mapping file absent" "$FLAT_WRONG_FILE"

{
  echo "# FAZ 7-8L.4 Logo Export Mapping Real Implementation Audit"
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

echo "===== 7-8L.4 LOGO EXPORT MAPPING REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

rm -f "$TMP_BODY"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8L_4_LOGO_EXPORT_MAPPING_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8L_4_LOGO_EXPORT_MAPPING_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
