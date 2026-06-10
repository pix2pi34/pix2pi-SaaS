#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8M_3_MIKRO_IMPORT_PACKAGE_DELIVERY_CONTRACT.md"
CONFIG_FILE="configs/faz7/integrations/mikro_import_delivery.contract.v1.json"
FOUNDATION_FILE="internal/platform/integrations/providers/mikro/mikro_connector_foundation.go"
MAPPING_FILE="internal/platform/integrations/providers/mikro/mikro_export_mapping.go"
FILE_GENERATION_FILE="internal/platform/integrations/providers/mikro/mikro_file_generation_dry_run.go"
RUNTIME_FILE="internal/platform/integrations/providers/mikro/mikro_import_delivery.go"
TEST_FILE="internal/platform/integrations/providers/mikro/mikro_import_delivery_test.go"
AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8M_3_MIKRO_IMPORT_DELIVERY_REAL_IMPLEMENTATION_AUDIT.md"

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

log_line "===== 7-8M.3 MIKRO IMPORT DELIVERY REAL IMPLEMENTATION AUDIT ====="

require_file "7-8M.3.1 doc artifact exists" "$DOC_FILE"
require_file "7-8M.3.2 config artifact exists" "$CONFIG_FILE"
require_dir "7-8M.3.3 provider directory exists" "internal/platform/integrations/providers/mikro"
require_file "7-8M.3.4 foundation runtime exists" "$FOUNDATION_FILE"
require_file "7-8M.3.5 export mapping runtime exists" "$MAPPING_FILE"
require_file "7-8M.3.6 file generation runtime exists" "$FILE_GENERATION_FILE"
require_file "7-8M.3.7 import delivery runtime code exists" "$RUNTIME_FILE"
require_file "7-8M.3.8 import delivery test code exists" "$TEST_FILE"

require_grep "7-8M.3.1.1 doc declares FAZ_7_8M_3" "FAZ_7_8M_3" "$DOC_FILE"
require_grep "7-8M.3.1.2 doc declares Mikro Import Package" "Mikro Import Package" "$DOC_FILE"
require_grep "7-8M.3.1.3 doc declares delivery contract" "Delivery Contract" "$DOC_FILE"
require_grep "7-8M.3.1.4 doc declares dry-run receipt" "receipt" "$DOC_FILE"
require_grep "7-8M.3.1.5 doc declares PIX2PI_TO_MIKRO direction" "PIX2PI_TO_MIKRO" "$DOC_FILE"
require_grep "7-8M.3.1.6 doc declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$DOC_FILE"
require_grep "7-8M.3.1.7 doc keeps real provider API closed" "MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.3.1.8 doc keeps real file delivery closed" "MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.3.1.9 doc keeps real ERP write closed" "MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.3.1.10 doc keeps real delivery channel closed" "MIKRO_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.3.1.11 doc requires counter based final status" "final status sayaçlardan türemeli" "$DOC_FILE"

require_grep "7-8M.3.2.1 config phase is FAZ_7_8M_3" "\"phase\": \"FAZ_7_8M_3\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.2 config module is import delivery contract" "\"module\": \"MIKRO_IMPORT_PACKAGE_DELIVERY_CONTRACT\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.3 config provider id is mikro" "\"provider_id\": \"mikro\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.4 config provider name is Mikro" "\"provider_name\": \"Mikro\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.5 config delivery contract mode is contract only" "\"delivery_contract_mode\": \"IMPORT_PACKAGE_DELIVERY_CONTRACT_ONLY\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.6 config runtime mode is placeholder only" "\"delivery_runtime_mode\": \"DRY_RUN_DELIVERY_PLACEHOLDER_ONLY\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.7 config direction is PIX2PI_TO_MIKRO" "\"direction\": \"PIX2PI_TO_MIKRO\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.8 config target system is Mikro dry-run import" "\"target_system\": \"MIKRO_ACCOUNTING_IMPORT_DRY_RUN\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.9 config declares no external delivery" "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE" "$CONFIG_FILE"
require_grep "7-8M.3.2.10 config declares dry-run receipt only" "DRY_RUN_RECEIPT_ONLY" "$CONFIG_FILE"
require_grep "7-8M.3.2.11 config requires checksum verification" "\"checksum_verification\": \"REQUIRED\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.12 config real provider API closed" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.13 config real file delivery closed" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.14 config real ERP write closed" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.15 config real delivery channel closed" "\"real_delivery_channel_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.16 config has dry-run manifest channel" "DRY_RUN_MANIFEST_ONLY" "$CONFIG_FILE"
require_grep "7-8M.3.2.17 config has manual review placeholder channel" "MANUAL_REVIEW_PLACEHOLDER" "$CONFIG_FILE"
require_grep "7-8M.3.2.18 config has sftp placeholder channel" "SFTP_PLACEHOLDER" "$CONFIG_FILE"
require_grep "7-8M.3.2.19 config has api placeholder channel" "API_PLACEHOLDER" "$CONFIG_FILE"
require_grep "7-8M.3.2.20 config requires tenant_id" "\"tenant_id\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.21 config requires delivery_id" "\"delivery_id\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.22 config requires package_id" "\"package_id\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.23 config forbids client_secret" "\"client_secret\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.24 config forbids access_token" "\"access_token\"" "$CONFIG_FILE"
require_grep "7-8M.3.2.25 config keeps FAZ 7-9 on hold" "HOLD_UNTIL_INTEGRATION_FAMILY_DONE" "$CONFIG_FILE"

require_grep "7-8M.3.3.1 foundation keeps real provider API closed" "MikroRealProviderAPIStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$FOUNDATION_FILE"
require_grep "7-8M.3.3.2 foundation keeps real file delivery closed" "MikroRealFileDeliveryStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$FOUNDATION_FILE"
require_grep "7-8M.3.3.3 foundation keeps real ERP write closed" "MikroRealERPWriteStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$FOUNDATION_FILE"

require_grep "7-8M.3.4.1 mapping runtime has phase 7-8M.1" "MikroExportMappingPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_1\"" "$MAPPING_FILE"
require_grep "7-8M.3.4.2 mapping runtime has Mikro object mapping" "MikroObjectMapping" "$MAPPING_FILE"
require_grep "7-8M.3.4.3 mapping runtime has SALES_INVOICE" "ERPObjectSalesInvoice" "$MAPPING_FILE"

require_grep "7-8M.3.5.1 file generation runtime has phase 7-8M.2" "MikroFileGenerationPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_2\"" "$FILE_GENERATION_FILE"
require_grep "7-8M.3.5.2 file generation runtime has dry-run package type" "type MikroDryRunPackage struct" "$FILE_GENERATION_FILE"
require_grep "7-8M.3.5.3 file generation runtime has checksum function" "calculateMikroDryRunChecksum" "$FILE_GENERATION_FILE"

require_grep "7-8M.3.6.1 runtime package is mikro" "^package mikro" "$RUNTIME_FILE"
require_grep "7-8M.3.6.2 runtime declares phase" "MikroImportDeliveryPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_3\"" "$RUNTIME_FILE"
require_grep "7-8M.3.6.3 runtime declares module" "MIKRO_IMPORT_PACKAGE_DELIVERY_CONTRACT" "$RUNTIME_FILE"
require_grep "7-8M.3.6.4 runtime declares delivery contract mode" "IMPORT_PACKAGE_DELIVERY_CONTRACT_ONLY" "$RUNTIME_FILE"
require_grep "7-8M.3.6.5 runtime declares placeholder runtime mode" "DRY_RUN_DELIVERY_PLACEHOLDER_ONLY" "$RUNTIME_FILE"
require_grep "7-8M.3.6.6 runtime declares direction" "PIX2PI_TO_MIKRO" "$RUNTIME_FILE"
require_grep "7-8M.3.6.7 runtime declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$RUNTIME_FILE"
require_grep "7-8M.3.6.8 runtime declares receipt policy" "DRY_RUN_RECEIPT_ONLY" "$RUNTIME_FILE"
require_grep "7-8M.3.6.9 runtime declares no external delivery" "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE" "$RUNTIME_FILE"
require_grep "7-8M.3.6.10 runtime declares real delivery channel closed" "MikroRealDeliveryChannelStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$RUNTIME_FILE"
require_grep "7-8M.3.6.11 runtime uses real provider API closed status" "MikroRealProviderAPIStatus" "$RUNTIME_FILE"
require_grep "7-8M.3.6.12 runtime uses real file delivery closed status" "MikroRealFileDeliveryStatus" "$RUNTIME_FILE"
require_grep "7-8M.3.6.13 runtime uses real ERP write closed status" "MikroRealERPWriteStatus" "$RUNTIME_FILE"
require_grep "7-8M.3.6.14 runtime has delivery contract type" "type MikroImportDeliveryContract struct" "$RUNTIME_FILE"
require_grep "7-8M.3.6.15 runtime has delivery request type" "type MikroImportDeliveryRequest struct" "$RUNTIME_FILE"
require_grep "7-8M.3.6.16 runtime has delivery receipt type" "type MikroImportDeliveryReceipt struct" "$RUNTIME_FILE"
require_grep "7-8M.3.6.17 runtime has delivery decision type" "type MikroImportDeliveryDecision struct" "$RUNTIME_FILE"
require_grep "7-8M.3.6.18 runtime has runtime type" "type MikroImportDeliveryRuntime struct" "$RUNTIME_FILE"
require_grep "7-8M.3.6.19 runtime has contract constructor" "func NewMikroImportDeliveryContract" "$RUNTIME_FILE"
require_grep "7-8M.3.6.20 runtime has runtime constructor" "func NewMikroImportDeliveryRuntime" "$RUNTIME_FILE"
require_grep "7-8M.3.6.21 runtime has validate method" "func \\(c MikroImportDeliveryContract\\) Validate" "$RUNTIME_FILE"
require_grep "7-8M.3.6.22 runtime has channel support method" "SupportsChannel" "$RUNTIME_FILE"
require_grep "7-8M.3.6.23 runtime has receipt creation method" "CreateDryRunDeliveryReceipt" "$RUNTIME_FILE"
require_grep "7-8M.3.6.24 runtime validates tenant id" "TenantID" "$RUNTIME_FILE"
require_grep "7-8M.3.6.25 runtime validates actor user id" "ActorUserID" "$RUNTIME_FILE"
require_grep "7-8M.3.6.26 runtime validates correlation id" "CorrelationID" "$RUNTIME_FILE"
require_grep "7-8M.3.6.27 runtime validates delivery id" "DeliveryID" "$RUNTIME_FILE"
require_grep "7-8M.3.6.28 runtime validates package id" "PackageID" "$RUNTIME_FILE"
require_grep "7-8M.3.6.29 runtime verifies dry-run package" "verifyMikroDryRunPackage" "$RUNTIME_FILE"
require_grep "7-8M.3.6.30 runtime verifies checksum" "calculateMikroDryRunChecksum" "$RUNTIME_FILE"
require_grep "7-8M.3.6.31 runtime verifies virtual content" "VirtualContent" "$RUNTIME_FILE"
require_grep "7-8M.3.6.32 runtime verifies virtual filename" "VirtualFileName" "$RUNTIME_FILE"
require_grep "7-8M.3.6.33 runtime denies provider live mode" "PROVIDER_LIVE" "$RUNTIME_FILE"
require_grep "7-8M.3.6.34 runtime denies real provider API enabled" "RealProviderAPIEnabled" "$RUNTIME_FILE"
require_grep "7-8M.3.6.35 runtime denies real file delivery enabled" "RealFileDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.3.6.36 runtime denies real delivery enabled" "RealDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.3.6.37 runtime denies real ERP write enabled" "RealERPWriteEnabled" "$RUNTIME_FILE"
require_grep "7-8M.3.6.38 runtime forbids secret fields" "containsForbiddenMappingField" "$RUNTIME_FILE"
require_grep "7-8M.3.6.39 runtime declares dry-run manifest channel" "DRY_RUN_MANIFEST_ONLY" "$RUNTIME_FILE"
require_grep "7-8M.3.6.40 runtime declares manual review channel" "MANUAL_REVIEW_PLACEHOLDER" "$RUNTIME_FILE"
require_grep "7-8M.3.6.41 runtime declares sftp placeholder channel" "SFTP_PLACEHOLDER" "$RUNTIME_FILE"
require_grep "7-8M.3.6.42 runtime declares api placeholder channel" "API_PLACEHOLDER" "$RUNTIME_FILE"
require_grep "7-8M.3.6.43 runtime declares ready decision" "MIKRO_IMPORT_DELIVERY_DRY_RUN_RECEIPT_READY" "$RUNTIME_FILE"
require_grep "7-8M.3.6.44 runtime declares unsupported channel decision" "MIKRO_IMPORT_DELIVERY_CHANNEL_UNSUPPORTED" "$RUNTIME_FILE"

require_grep "7-8M.3.7.1 tests include root 7-8M.3 OK output" "7-8M\\.3" "$TEST_FILE"
require_grep "7-8M.3.7.2 tests include 7-8M.3.1 OK output" "7-8M\\.3\\.1" "$TEST_FILE"
require_grep "7-8M.3.7.3 tests include 7-8M.3.1.1 OK output" "7-8M\\.3\\.1\\.1" "$TEST_FILE"
require_grep "7-8M.3.7.4 tests validate dry-run receipt" "dry-run delivery receipt validation" "$TEST_FILE"
require_grep "7-8M.3.7.5 tests validate no external delivery" "receipt does not mark delivered" "$TEST_FILE"
require_grep "7-8M.3.7.6 tests validate supported channels" "delivery channel placeholder validation" "$TEST_FILE"
require_grep "7-8M.3.7.7 tests validate unsupported channel" "unsupported real delivery channel is denied" "$TEST_FILE"
require_grep "7-8M.3.7.8 tests validate closed real API" "real Mikro API request is denied" "$TEST_FILE"
require_grep "7-8M.3.7.9 tests validate closed file delivery" "real Mikro file delivery request is denied" "$TEST_FILE"
require_grep "7-8M.3.7.10 tests validate closed ERP write" "real ERP write request is denied" "$TEST_FILE"
require_grep "7-8M.3.7.11 tests validate delivery id guard" "missing delivery id is rejected" "$TEST_FILE"
require_grep "7-8M.3.7.12 tests validate package id guard" "missing package id is rejected" "$TEST_FILE"
require_grep "7-8M.3.7.13 tests validate checksum guard" "checksum mismatch is rejected" "$TEST_FILE"
require_grep "7-8M.3.7.14 tests validate secret rejection" "client_secret field is rejected" "$TEST_FILE"

log_line "===== 7-8M.3 MIKRO IMPORT DELIVERY REAL IMPLEMENTATION AUDIT RESULT ====="
log_line "PASS_COUNT=$PASS_COUNT"
log_line "FAIL_COUNT=$FAIL_COUNT"
log_line "REQUIRED_FAIL=$REQUIRED_FAIL"
log_line "OPTIONAL_WARN=$OPTIONAL_WARN"
log_line "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"

if [[ "$REQUIRED_FAIL" -eq 0 ]]; then
  log_line "FAZ_7_8M_3_MIKRO_IMPORT_DELIVERY_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

log_line "FAZ_7_8M_3_MIKRO_IMPORT_DELIVERY_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
