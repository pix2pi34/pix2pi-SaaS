#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8L_5_LOGO_FILE_GENERATION_DRY_RUN.md"
CONFIG_FILE="configs/faz7/logo_file_generation_dry_run.v1.json"
CODE_DIR="internal/platform/integrations/providers/logo"
FOUNDATION_FILE="internal/platform/integrations/providers/logo/logo_foundation.go"
LIVE_CONTRACT_FILE="internal/platform/integrations/providers/logo/logo_live_contract.go"
CREDENTIAL_FILE="internal/platform/integrations/providers/logo/logo_credential.go"
EXPORT_MAPPING_FILE="internal/platform/integrations/providers/logo/logo_export_mapping.go"
CODE_FILE="internal/platform/integrations/providers/logo/logo_file_generation.go"
TEST_FILE="internal/platform/integrations/providers/logo/logo_file_generation_test.go"
FLAT_WRONG_FILE="internal/platform/integrations/runtime/logo_file_generation.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8L_5_LOGO_FILE_GENERATION_REAL_IMPLEMENTATION_AUDIT.md"
COUNT_FILE="/tmp/faz_7_8l_5_logo_file_generation_audit_counts.env"
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

echo "===== 7-8L.5 LOGO FILE GENERATION REAL IMPLEMENTATION AUDIT ====="

check_file "7-8L.5.1 doc artifact" "$DOC_FILE"
check_file "7-8L.5.2 config artifact" "$CONFIG_FILE"
check_dir "7-8L.5.3 provider logo directory" "$CODE_DIR"
check_file "7-8L.5.4 foundation runtime dependency" "$FOUNDATION_FILE"
check_file "7-8L.5.5 live contract runtime dependency" "$LIVE_CONTRACT_FILE"
check_file "7-8L.5.6 credential runtime dependency" "$CREDENTIAL_FILE"
check_file "7-8L.5.7 export mapping runtime dependency" "$EXPORT_MAPPING_FILE"
check_file "7-8L.5.8 Go runtime code artifact" "$CODE_FILE"
check_file "7-8L.5.9 Go test artifact" "$TEST_FILE"
check_json "7-8L.5.10 config json validity" "$CONFIG_FILE"

check_grep "7-8L.5.11 module marker in doc" "$DOC_FILE" "FAZ 7-8L.5"
check_grep "7-8L.5.12 provider directory in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/"
check_grep "7-8L.5.13 runtime filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_file_generation.go"
check_grep "7-8L.5.14 test filename in doc" "$DOC_FILE" "internal/platform/integrations/providers/logo/logo_file_generation_test.go"
check_grep "7-8L.5.15 provider identity in doc" "$DOC_FILE" "Provider code: LOGO"
check_grep "7-8L.5.16 file generation mode in doc" "$DOC_FILE" "File generation mode: FILE_GENERATION_DRY_RUN_ONLY"
check_grep "7-8L.5.17 target system in doc" "$DOC_FILE" "Target system: LOGO_ACCOUNTING_IMPORT_DRY_RUN"
check_grep "7-8L.5.18 dry-run header line type in doc" "$DOC_FILE" "HEADER"
check_grep "7-8L.5.19 dry-run line type in doc" "$DOC_FILE" "LINE"
check_grep "7-8L.5.20 dry-run party line type in doc" "$DOC_FILE" "PARTY"
check_grep "7-8L.5.21 checksum in doc" "$DOC_FILE" "checksum_sha256"
check_grep "7-8L.5.22 delivery false in doc" "$DOC_FILE" "delivery_allowed=false"
check_grep "7-8L.5.23 real provider API closed in doc" "$DOC_FILE" "LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
check_grep "7-8L.5.24 dry-run file generation ready in doc" "$DOC_FILE" "LOGO_DRY_RUN_FILE_GENERATION_STATUS=READY"
check_grep "7-8L.5.25 real file delivery closed in doc" "$DOC_FILE" "LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
check_grep "7-8L.5.26 real ERP write closed in doc" "$DOC_FILE" "LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
check_grep "7-8L.5.27 next step marker in doc" "$DOC_FILE" "FAZ 7-8L.6"

check_grep "7-8L.5.28 module marker in config" "$CONFIG_FILE" "\"module\": \"FAZ_7_8L\""
check_grep "7-8L.5.29 step marker in config" "$CONFIG_FILE" "\"step\": \"FAZ_7_8L.5\""
check_grep "7-8L.5.30 provider code in config" "$CONFIG_FILE" "\"provider_code\": \"LOGO\""
check_grep "7-8L.5.31 provider directory in config" "$CONFIG_FILE" "\"provider_directory\": \"internal/platform/integrations/providers/logo\""
check_grep "7-8L.5.32 runtime file in config" "$CONFIG_FILE" "\"runtime_file\": \"internal/platform/integrations/providers/logo/logo_file_generation.go\""
check_grep "7-8L.5.33 test file in config" "$CONFIG_FILE" "\"test_file\": \"internal/platform/integrations/providers/logo/logo_file_generation_test.go\""
check_grep "7-8L.5.34 file generation mode in config" "$CONFIG_FILE" "\"file_generation_mode\": \"FILE_GENERATION_DRY_RUN_ONLY\""
check_grep "7-8L.5.35 target system in config" "$CONFIG_FILE" "\"target_system\": \"LOGO_ACCOUNTING_IMPORT_DRY_RUN\""
check_grep "7-8L.5.36 dry-run generation ready in config" "$CONFIG_FILE" "\"dry_run_file_generation_status\": \"READY\""
check_grep "7-8L.5.37 dry-run file contract in config" "$CONFIG_FILE" "\"dry_run_file_contract\""
check_grep "7-8L.5.38 format in config" "$CONFIG_FILE" "\"format\": \"LOGO_DRY_RUN_IMPORT_PACKAGE_V1\""
check_grep "7-8L.5.39 dry run only in config" "$CONFIG_FILE" "\"dry_run_only\": true"
check_grep "7-8L.5.40 real file delivery disabled in config" "$CONFIG_FILE" "\"real_file_delivery_allowed\": false"
check_grep "7-8L.5.41 checksum required in config" "$CONFIG_FILE" "\"checksum_required\": true"
check_grep "7-8L.5.42 manifest required in config" "$CONFIG_FILE" "\"manifest_required\": true"
check_grep "7-8L.5.43 tenant required in config" "$CONFIG_FILE" "\"tenant_scope_required\": true"
check_grep "7-8L.5.44 correlation required in config" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "7-8L.5.45 idempotency required in config" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "7-8L.5.46 external call disabled in config" "$CONFIG_FILE" "\"external_call_allowed\": false"
check_grep "7-8L.5.47 ERP write disabled in config" "$CONFIG_FILE" "\"erp_write_allowed\": false"
check_grep "7-8L.5.48 real provider API closed in config" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
check_grep "7-8L.5.49 real file delivery closed in config" "$CONFIG_FILE" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\""
check_grep "7-8L.5.50 real ERP write closed in config" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""

check_grep "7-8L.5.51 package logo" "$CODE_FILE" "package logo"
check_grep "7-8L.5.52 file generation contract struct" "$CODE_FILE" "type LogoFileGenerationContract struct"
check_grep "7-8L.5.53 dry-run export input type" "$CODE_FILE" "type LogoDryRunExportInput struct"
check_grep "7-8L.5.54 generated dry-run file type" "$CODE_FILE" "type LogoGeneratedDryRunFile struct"
check_grep "7-8L.5.55 dry-run import package type" "$CODE_FILE" "type LogoDryRunImportPackage struct"
check_grep "7-8L.5.56 operation contract type" "$CODE_FILE" "type LogoFileGenerationOperationContract struct"
check_grep "7-8L.5.57 file generation constructor" "$CODE_FILE" "func NewLogoFileGenerationContract() LogoFileGenerationContract"
check_grep "7-8L.5.58 sample input constructor" "$CODE_FILE" "func NewLogoSampleDryRunExportInput() LogoDryRunExportInput"
check_grep "7-8L.5.59 file generation validator" "$CODE_FILE" "func (c LogoFileGenerationContract) Validate() error"
check_grep "7-8L.5.60 generate dry-run package method" "$CODE_FILE" "func (c LogoFileGenerationContract) GenerateDryRunImportPackage"
check_grep "7-8L.5.61 input validator" "$CODE_FILE" "func (i LogoDryRunExportInput) Validate() error"
check_grep "7-8L.5.62 content builder" "$CODE_FILE" "func (i LogoDryRunExportInput) BuildDryRunFileContent() string"
check_grep "7-8L.5.63 package validator" "$CODE_FILE" "func (p LogoDryRunImportPackage) Validate() error"
check_grep "7-8L.5.64 file validator" "$CODE_FILE" "func (f LogoGeneratedDryRunFile) Validate() error"
check_grep "7-8L.5.65 checksum function" "$CODE_FILE" "func CalculateLogoDryRunChecksum"
check_grep "7-8L.5.66 sha256 usage" "$CODE_FILE" "sha256.Sum256"
check_grep "7-8L.5.67 HEADER content" "$CODE_FILE" "HEADER|"
check_grep "7-8L.5.68 LINE content" "$CODE_FILE" "LINE|"
check_grep "7-8L.5.69 PARTY content" "$CODE_FILE" "PARTY|"
check_grep "7-8L.5.70 TAX content" "$CODE_FILE" "TAX|"
check_grep "7-8L.5.71 INVOICE content" "$CODE_FILE" "INVOICE|"
check_grep "7-8L.5.72 MANIFEST guard content" "$CODE_FILE" "MANIFEST|DRY_RUN_ONLY|NO_REAL_DELIVERY|NO_ERP_WRITE"
check_grep "7-8L.5.73 real integrations closed guard" "$CODE_FILE" "func (c LogoFileGenerationContract) RealIntegrationsClosed() bool"
check_grep "7-8L.5.74 delivery denied model" "$CODE_FILE" "RealFileDeliveryAllowed"
check_grep "7-8L.5.75 ERP write denied model" "$CODE_FILE" "ERPWriteAllowed"

check_grep "7-8L.5.76 package logo test" "$TEST_FILE" "package logo"
check_grep "7-8L.5.77 file generation readiness test" "$TEST_FILE" "TestLogoFileGenerationDryRunReadiness"
check_grep "7-8L.5.78 integrations closed test" "$TEST_FILE" "TestLogoFileGenerationKeepsRealIntegrationsClosed"
check_grep "7-8L.5.79 generate package test" "$TEST_FILE" "TestLogoGenerateDryRunImportPackage"
check_grep "7-8L.5.80 missing tenant rejection test" "$TEST_FILE" "TestLogoFileGenerationRejectsMissingTenant"
check_grep "7-8L.5.81 missing journal lines rejection test" "$TEST_FILE" "TestLogoFileGenerationRejectsMissingJournalLines"
check_grep "7-8L.5.82 real delivery rejection test" "$TEST_FILE" "TestLogoFileGenerationRejectsRealDeliveryOperation"
check_grep "7-8L.5.83 external operation rejection test" "$TEST_FILE" "TestLogoFileGenerationRejectsExternalOperation"
check_grep "7-8L.5.84 ERP write rejection test" "$TEST_FILE" "TestLogoFileGenerationRejectsERPWriteOperation"

check_absent_file "7-8L.5.85 runtime flat Logo file generation file absent" "$FLAT_WRONG_FILE"

{
  echo "# FAZ 7-8L.5 Logo File Generation Real Implementation Audit"
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

echo "===== 7-8L.5 LOGO FILE GENERATION REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

rm -f "$TMP_BODY"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8L_5_LOGO_FILE_GENERATION_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

echo "FAZ_7_8L_5_LOGO_FILE_GENERATION_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
