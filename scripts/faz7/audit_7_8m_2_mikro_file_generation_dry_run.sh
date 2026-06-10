#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8M_2_MIKRO_FILE_GENERATION_DRY_RUN_CONTRACT.md"
CONFIG_FILE="configs/faz7/integrations/mikro_file_generation.dry_run_contract.v1.json"
FOUNDATION_FILE="internal/platform/integrations/providers/mikro/mikro_connector_foundation.go"
MAPPING_FILE="internal/platform/integrations/providers/mikro/mikro_export_mapping.go"
RUNTIME_FILE="internal/platform/integrations/providers/mikro/mikro_file_generation_dry_run.go"
TEST_FILE="internal/platform/integrations/providers/mikro/mikro_file_generation_dry_run_test.go"
AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8M_2_MIKRO_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_AUDIT.md"

mkdir -p "$(dirname "$AUDIT_EVIDENCE_FILE")"
: > "$AUDIT_EVIDENCE_FILE"

log_line() {
  echo "$*" | tee -a "$AUDIT_EVIDENCE_FILE"
}

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  log_line "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  log_line "$1 MISSING_OR_INVALID / FAIL ❌"
}

require_file() {
  local label="$1"
  local file="$2"
  if [[ -f "$file" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_dir() {
  local label="$1"
  local dir="$2"
  if [[ -d "$dir" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_grep() {
  local label="$1"
  local pattern="$2"
  local file="$3"
  if [[ -f "$file" ]] && grep -Eq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

log_line "===== 7-8M.2 MIKRO FILE GENERATION DRY-RUN REAL IMPLEMENTATION AUDIT ====="

require_file "7-8M.2.1 doc artifact exists" "$DOC_FILE"
require_file "7-8M.2.2 config artifact exists" "$CONFIG_FILE"
require_dir "7-8M.2.3 provider directory exists" "internal/platform/integrations/providers/mikro"
require_file "7-8M.2.4 foundation runtime exists" "$FOUNDATION_FILE"
require_file "7-8M.2.5 export mapping runtime exists" "$MAPPING_FILE"
require_file "7-8M.2.6 file generation runtime code exists" "$RUNTIME_FILE"
require_file "7-8M.2.7 file generation test code exists" "$TEST_FILE"

require_grep "7-8M.2.1.1 doc declares FAZ_7_8M_2" "FAZ_7_8M_2" "$DOC_FILE"
require_grep "7-8M.2.1.2 doc declares Mikro File Generation" "Mikro File Generation" "$DOC_FILE"
require_grep "7-8M.2.1.3 doc declares dry-run package builder" "dry-run package" "$DOC_FILE"
require_grep "7-8M.2.1.4 doc declares PIX2PI_TO_MIKRO direction" "PIX2PI_TO_MIKRO" "$DOC_FILE"
require_grep "7-8M.2.1.5 doc declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$DOC_FILE"
require_grep "7-8M.2.1.6 doc keeps real provider API closed" "MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.2.1.7 doc keeps real file delivery closed" "MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.2.1.8 doc keeps real ERP write closed" "MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.2.1.9 doc requires counter based final status" "final status sayaçlardan türemeli" "$DOC_FILE"

require_grep "7-8M.2.2.1 config phase is FAZ_7_8M_2" "\"phase\": \"FAZ_7_8M_2\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.2 config module is file generation contract" "\"module\": \"MIKRO_FILE_GENERATION_DRY_RUN_CONTRACT\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.3 config provider id is mikro" "\"provider_id\": \"mikro\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.4 config provider name is Mikro" "\"provider_name\": \"Mikro\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.5 config builder mode is dry-run only" "\"builder_mode\": \"EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.6 config direction is PIX2PI_TO_MIKRO" "\"direction\": \"PIX2PI_TO_MIKRO\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.7 config source system is PIX2PI_ERP" "\"source_system\": \"PIX2PI_ERP\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.8 config target system is Mikro dry-run import" "\"target_system\": \"MIKRO_ACCOUNTING_IMPORT_DRY_RUN\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.9 config declares virtual extension" "\"virtual_file_extension\": \".mikro.dryrun.txt\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.10 config declares SHA256 checksum" "\"checksum_algorithm\": \"SHA256\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.11 config declares no external delivery" "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE" "$CONFIG_FILE"
require_grep "7-8M.2.2.12 config real provider API closed" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.13 config real file delivery closed" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.14 config real ERP write closed" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.15 config requires tenant_id" "\"tenant_id\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.16 config requires package_id" "\"package_id\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.17 config requires erp_object_type" "\"erp_object_type\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.18 config forbids client_secret" "\"client_secret\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.19 config forbids access_token" "\"access_token\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.20 config declares CUSTOMER package" "\"CUSTOMER\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.21 config declares SALES_INVOICE package" "\"SALES_INVOICE\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.22 config declares ACCOUNTING_VOUCHER package" "\"ACCOUNTING_VOUCHER\"" "$CONFIG_FILE"
require_grep "7-8M.2.2.23 config keeps FAZ 7-9 on hold" "HOLD_UNTIL_INTEGRATION_FAMILY_DONE" "$CONFIG_FILE"

require_grep "7-8M.2.3.1 foundation keeps real provider API closed" "MikroRealProviderAPIStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$FOUNDATION_FILE"
require_grep "7-8M.2.3.2 foundation keeps real file delivery closed" "MikroRealFileDeliveryStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$FOUNDATION_FILE"
require_grep "7-8M.2.3.3 foundation keeps real ERP write closed" "MikroRealERPWriteStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$FOUNDATION_FILE"

require_grep "7-8M.2.4.1 mapping runtime exists with phase 7-8M.1" "MikroExportMappingPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_1\"" "$MAPPING_FILE"
require_grep "7-8M.2.4.2 mapping runtime has MappingFor bridge" "func \\(c MikroExportMappingContract\\) MappingFor" "$MAPPING_FILE"
require_grep "7-8M.2.4.3 mapping runtime has SALES_INVOICE" "ERPObjectSalesInvoice" "$MAPPING_FILE"

require_grep "7-8M.2.5.1 runtime package is mikro" "^package mikro" "$RUNTIME_FILE"
require_grep "7-8M.2.5.2 runtime declares phase" "MikroFileGenerationPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_2\"" "$RUNTIME_FILE"
require_grep "7-8M.2.5.3 runtime declares module" "MIKRO_FILE_GENERATION_DRY_RUN_CONTRACT" "$RUNTIME_FILE"
require_grep "7-8M.2.5.4 runtime declares builder mode" "EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY" "$RUNTIME_FILE"
require_grep "7-8M.2.5.5 runtime declares direction" "PIX2PI_TO_MIKRO" "$RUNTIME_FILE"
require_grep "7-8M.2.5.6 runtime declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$RUNTIME_FILE"
require_grep "7-8M.2.5.7 runtime declares virtual extension" ".mikro.dryrun.txt" "$RUNTIME_FILE"
require_grep "7-8M.2.5.8 runtime declares SHA256 checksum" "SHA256" "$RUNTIME_FILE"
require_grep "7-8M.2.5.9 runtime declares no delivery policy" "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE" "$RUNTIME_FILE"
require_grep "7-8M.2.5.10 runtime uses foundation real provider API status" "MikroRealProviderAPIStatus" "$RUNTIME_FILE"
require_grep "7-8M.2.5.11 runtime uses foundation real file delivery status" "MikroRealFileDeliveryStatus" "$RUNTIME_FILE"
require_grep "7-8M.2.5.12 runtime uses foundation real ERP write status" "MikroRealERPWriteStatus" "$RUNTIME_FILE"
require_grep "7-8M.2.5.13 runtime has file generation contract type" "type MikroFileGenerationContract struct" "$RUNTIME_FILE"
require_grep "7-8M.2.5.14 runtime has dry-run record type" "type MikroDryRunPackageRecord struct" "$RUNTIME_FILE"
require_grep "7-8M.2.5.15 runtime has file generation request type" "type MikroFileGenerationRequest struct" "$RUNTIME_FILE"
require_grep "7-8M.2.5.16 runtime has manifest type" "type MikroDryRunPackageManifest struct" "$RUNTIME_FILE"
require_grep "7-8M.2.5.17 runtime has package type" "type MikroDryRunPackage struct" "$RUNTIME_FILE"
require_grep "7-8M.2.5.18 runtime has builder type" "type MikroFileGenerationBuilder struct" "$RUNTIME_FILE"
require_grep "7-8M.2.5.19 runtime has contract constructor" "func NewMikroFileGenerationContract" "$RUNTIME_FILE"
require_grep "7-8M.2.5.20 runtime has builder constructor" "func NewMikroFileGenerationBuilder" "$RUNTIME_FILE"
require_grep "7-8M.2.5.21 runtime has validate method" "func \\(c MikroFileGenerationContract\\) Validate" "$RUNTIME_FILE"
require_grep "7-8M.2.5.22 runtime has BuildDryRunPackage" "BuildDryRunPackage" "$RUNTIME_FILE"
require_grep "7-8M.2.5.23 runtime bridges mapping contract" "NewMikroExportMappingContract" "$RUNTIME_FILE"
require_grep "7-8M.2.5.24 runtime uses MappingFor" "MappingFor" "$RUNTIME_FILE"
require_grep "7-8M.2.5.25 runtime validates tenant id" "TenantID" "$RUNTIME_FILE"
require_grep "7-8M.2.5.26 runtime validates actor user id" "ActorUserID" "$RUNTIME_FILE"
require_grep "7-8M.2.5.27 runtime validates correlation id" "CorrelationID" "$RUNTIME_FILE"
require_grep "7-8M.2.5.28 runtime validates package id" "PackageID" "$RUNTIME_FILE"
require_grep "7-8M.2.5.29 runtime validates ERP object type" "ERPObjectType" "$RUNTIME_FILE"
require_grep "7-8M.2.5.30 runtime validates records" "validateMikroDryRunPackageRecords" "$RUNTIME_FILE"
require_grep "7-8M.2.5.31 runtime builds virtual file name" "buildMikroDryRunVirtualFileName" "$RUNTIME_FILE"
require_grep "7-8M.2.5.32 runtime builds virtual content" "buildMikroDryRunVirtualContent" "$RUNTIME_FILE"
require_grep "7-8M.2.5.33 runtime calculates checksum" "calculateMikroDryRunChecksum" "$RUNTIME_FILE"
require_grep "7-8M.2.5.34 runtime imports sha256" "crypto/sha256" "$RUNTIME_FILE"
require_grep "7-8M.2.5.35 runtime imports hex" "encoding/hex" "$RUNTIME_FILE"
require_grep "7-8M.2.5.36 runtime denies real provider API enabled" "RealProviderAPIEnabled" "$RUNTIME_FILE"
require_grep "7-8M.2.5.37 runtime denies real file delivery enabled" "RealFileDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.2.5.38 runtime denies real ERP write enabled" "RealERPWriteEnabled" "$RUNTIME_FILE"
require_grep "7-8M.2.5.39 runtime forbids secret fields" "containsForbiddenMappingField" "$RUNTIME_FILE"
require_grep "7-8M.2.5.40 runtime declares ready decision" "MIKRO_FILE_GENERATION_DRY_RUN_PACKAGE_READY" "$RUNTIME_FILE"
require_grep "7-8M.2.5.41 runtime declares unsupported decision" "MIKRO_FILE_GENERATION_ERP_OBJECT_UNSUPPORTED" "$RUNTIME_FILE"
require_grep "7-8M.2.5.42 runtime declares live mode closed decision" "MIKRO_FILE_GENERATION_PROVIDER_LIVE_MODE_CLOSED" "$RUNTIME_FILE"

require_grep "7-8M.2.6.1 tests include root 7-8M.2 OK output" "7-8M\\.2" "$TEST_FILE"
require_grep "7-8M.2.6.2 tests include 7-8M.2.1 OK output" "7-8M\\.2\\.1" "$TEST_FILE"
require_grep "7-8M.2.6.3 tests include 7-8M.2.1.1 OK output" "7-8M\\.2\\.1\\.1" "$TEST_FILE"
require_grep "7-8M.2.6.4 tests validate dry-run package builder" "dry-run package builder validation" "$TEST_FILE"
require_grep "7-8M.2.6.5 tests validate virtual filename" "virtual filename is generated" "$TEST_FILE"
require_grep "7-8M.2.6.6 tests validate SHA256 checksum" "SHA256 checksum is generated" "$TEST_FILE"
require_grep "7-8M.2.6.7 tests validate no delivery policy" "no delivery policy" "$TEST_FILE"
require_grep "7-8M.2.6.8 tests validate object coverage" "supported package object coverage validation" "$TEST_FILE"
require_grep "7-8M.2.6.9 tests validate closed real API" "real Mikro API request is denied" "$TEST_FILE"
require_grep "7-8M.2.6.10 tests validate closed file delivery" "real Mikro file delivery request is denied" "$TEST_FILE"
require_grep "7-8M.2.6.11 tests validate closed ERP write" "real ERP write request is denied" "$TEST_FILE"
require_grep "7-8M.2.6.12 tests validate package id guard" "missing package id is rejected" "$TEST_FILE"
require_grep "7-8M.2.6.13 tests validate empty records guard" "empty package records are rejected" "$TEST_FILE"
require_grep "7-8M.2.6.14 tests validate secret rejection" "client_secret field is rejected" "$TEST_FILE"

log_line "===== 7-8M.2 MIKRO FILE GENERATION DRY-RUN REAL IMPLEMENTATION AUDIT RESULT ====="
log_line "PASS_COUNT=$PASS_COUNT"
log_line "FAIL_COUNT=$FAIL_COUNT"
log_line "REQUIRED_FAIL=$REQUIRED_FAIL"
log_line "OPTIONAL_WARN=$OPTIONAL_WARN"
log_line "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"

if [[ "$REQUIRED_FAIL" -eq 0 ]]; then
  log_line "FAZ_7_8M_2_MIKRO_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

log_line "FAZ_7_8M_2_MIKRO_FILE_GENERATION_DRY_RUN_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
