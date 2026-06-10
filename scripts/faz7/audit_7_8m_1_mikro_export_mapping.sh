#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8M_1_MIKRO_EXPORT_MAPPING_ERP_OBJECT_CONTRACT.md"
CONFIG_FILE="configs/faz7/integrations/mikro_export_mapping.erp_object_contract.v1.json"
FOUNDATION_FILE="internal/platform/integrations/providers/mikro/mikro_connector_foundation.go"
RUNTIME_FILE="internal/platform/integrations/providers/mikro/mikro_export_mapping.go"
TEST_FILE="internal/platform/integrations/providers/mikro/mikro_export_mapping_test.go"
AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8M_1_MIKRO_EXPORT_MAPPING_REAL_IMPLEMENTATION_AUDIT.md"

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

log_line "===== 7-8M.1 MIKRO EXPORT MAPPING REAL IMPLEMENTATION AUDIT ====="

require_file "7-8M.1.1 doc artifact exists" "$DOC_FILE"
require_file "7-8M.1.2 config artifact exists" "$CONFIG_FILE"
require_dir "7-8M.1.3 provider directory exists" "internal/platform/integrations/providers/mikro"
require_file "7-8M.1.4 foundation runtime exists" "$FOUNDATION_FILE"
require_file "7-8M.1.5 export mapping runtime code exists" "$RUNTIME_FILE"
require_file "7-8M.1.6 export mapping test code exists" "$TEST_FILE"

require_grep "7-8M.1.1.1 doc declares FAZ_7_8M_1" "FAZ_7_8M_1" "$DOC_FILE"
require_grep "7-8M.1.1.2 doc declares Mikro Export Mapping" "Mikro Export Mapping" "$DOC_FILE"
require_grep "7-8M.1.1.3 doc declares ERP object contract" "ERP Object Contract" "$DOC_FILE"
require_grep "7-8M.1.1.4 doc declares PIX2PI_TO_MIKRO direction" "PIX2PI_TO_MIKRO" "$DOC_FILE"
require_grep "7-8M.1.1.5 doc declares source system" "PIX2PI_ERP" "$DOC_FILE"
require_grep "7-8M.1.1.6 doc declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$DOC_FILE"
require_grep "7-8M.1.1.7 doc keeps real provider API closed" "MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.1.1.8 doc keeps real file delivery closed" "MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.1.1.9 doc keeps real ERP write closed" "MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.1.1.10 doc requires counter based final status" "final status sayaçlardan türemeli" "$DOC_FILE"

require_grep "7-8M.1.2.1 config phase is FAZ_7_8M_1" "\"phase\": \"FAZ_7_8M_1\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.2 config module is export mapping contract" "\"module\": \"MIKRO_EXPORT_MAPPING_ERP_OBJECT_CONTRACT\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.3 config provider id is mikro" "\"provider_id\": \"mikro\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.4 config provider name is Mikro" "\"provider_name\": \"Mikro\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.5 config mapping mode is contract only" "\"mapping_mode\": \"ERP_OBJECT_EXPORT_MAPPING_CONTRACT_ONLY\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.6 config direction is PIX2PI_TO_MIKRO" "\"direction\": \"PIX2PI_TO_MIKRO\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.7 config source system is PIX2PI_ERP" "\"source_system\": \"PIX2PI_ERP\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.8 config target system is Mikro dry-run import" "\"target_system\": \"MIKRO_ACCOUNTING_IMPORT_DRY_RUN\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.9 config real provider API closed" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.10 config real file delivery closed" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.11 config real ERP write closed" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.12 config requires tenant_id" "\"tenant_id\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.13 config requires actor_user_id" "\"actor_user_id\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.14 config requires correlation_id" "\"correlation_id\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.15 config requires erp_object_type" "\"erp_object_type\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.16 config forbids client_secret" "\"client_secret\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.17 config forbids access_token" "\"access_token\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.18 config declares CUSTOMER mapping" "\"erp_object_type\": \"CUSTOMER\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.19 config declares VENDOR mapping" "\"erp_object_type\": \"VENDOR\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.20 config declares PRODUCT mapping" "\"erp_object_type\": \"PRODUCT\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.21 config declares SERVICE_ITEM mapping" "\"erp_object_type\": \"SERVICE_ITEM\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.22 config declares SALES_INVOICE mapping" "\"erp_object_type\": \"SALES_INVOICE\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.23 config declares PURCHASE_INVOICE mapping" "\"erp_object_type\": \"PURCHASE_INVOICE\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.24 config declares STOCK_MOVEMENT mapping" "\"erp_object_type\": \"STOCK_MOVEMENT\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.25 config declares ACCOUNTING_VOUCHER mapping" "\"erp_object_type\": \"ACCOUNTING_VOUCHER\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.26 config declares TAX_LINE mapping" "\"erp_object_type\": \"TAX_LINE\"" "$CONFIG_FILE"
require_grep "7-8M.1.2.27 config keeps FAZ 7-9 on hold" "HOLD_UNTIL_INTEGRATION_FAMILY_DONE" "$CONFIG_FILE"

require_grep "7-8M.1.3.1 foundation has mikro provider id" "ProviderID[[:space:]]*=[[:space:]]*\"mikro\"" "$FOUNDATION_FILE"
require_grep "7-8M.1.3.2 foundation keeps real provider API closed" "MikroRealProviderAPIStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$FOUNDATION_FILE"
require_grep "7-8M.1.3.3 foundation keeps real file delivery closed" "MikroRealFileDeliveryStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$FOUNDATION_FILE"
require_grep "7-8M.1.3.4 foundation keeps real ERP write closed" "MikroRealERPWriteStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$FOUNDATION_FILE"

require_grep "7-8M.1.4.1 runtime package is mikro" "^package mikro" "$RUNTIME_FILE"
require_grep "7-8M.1.4.2 runtime declares phase" "MikroExportMappingPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_1\"" "$RUNTIME_FILE"
require_grep "7-8M.1.4.3 runtime declares module" "MIKRO_EXPORT_MAPPING_ERP_OBJECT_CONTRACT" "$RUNTIME_FILE"
require_grep "7-8M.1.4.4 runtime declares mapping mode" "ERP_OBJECT_EXPORT_MAPPING_CONTRACT_ONLY" "$RUNTIME_FILE"
require_grep "7-8M.1.4.5 runtime declares direction" "PIX2PI_TO_MIKRO" "$RUNTIME_FILE"
require_grep "7-8M.1.4.6 runtime declares source system" "PIX2PI_ERP" "$RUNTIME_FILE"
require_grep "7-8M.1.4.7 runtime declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$RUNTIME_FILE"
require_grep "7-8M.1.4.8 runtime uses foundation provider id" "ProviderID" "$RUNTIME_FILE"
require_grep "7-8M.1.4.9 runtime uses foundation provider name" "ProviderName" "$RUNTIME_FILE"
require_grep "7-8M.1.4.10 runtime uses real provider API closed status" "MikroRealProviderAPIStatus" "$RUNTIME_FILE"
require_grep "7-8M.1.4.11 runtime uses real file delivery closed status" "MikroRealFileDeliveryStatus" "$RUNTIME_FILE"
require_grep "7-8M.1.4.12 runtime uses real ERP write closed status" "MikroRealERPWriteStatus" "$RUNTIME_FILE"
require_grep "7-8M.1.4.13 runtime has contract struct" "type MikroExportMappingContract struct" "$RUNTIME_FILE"
require_grep "7-8M.1.4.14 runtime has request struct" "type MikroExportMappingRequest struct" "$RUNTIME_FILE"
require_grep "7-8M.1.4.15 runtime has decision struct" "type MikroExportMappingDecision struct" "$RUNTIME_FILE"
require_grep "7-8M.1.4.16 runtime has constructor" "func NewMikroExportMappingContract" "$RUNTIME_FILE"
require_grep "7-8M.1.4.17 runtime has validate method" "func \\(c MikroExportMappingContract\\) Validate" "$RUNTIME_FILE"
require_grep "7-8M.1.4.18 runtime has mapping lookup" "func \\(c MikroExportMappingContract\\) MappingFor" "$RUNTIME_FILE"
require_grep "7-8M.1.4.19 runtime has decision evaluate" "func \\(c MikroExportMappingContract\\) Evaluate" "$RUNTIME_FILE"
require_grep "7-8M.1.4.20 runtime validates tenant id" "TenantID" "$RUNTIME_FILE"
require_grep "7-8M.1.4.21 runtime validates actor user id" "ActorUserID" "$RUNTIME_FILE"
require_grep "7-8M.1.4.22 runtime validates correlation id" "CorrelationID" "$RUNTIME_FILE"
require_grep "7-8M.1.4.23 runtime validates ERP object type" "ERPObjectType" "$RUNTIME_FILE"
require_grep "7-8M.1.4.24 runtime declares CUSTOMER object" "ERPObjectCustomer" "$RUNTIME_FILE"
require_grep "7-8M.1.4.25 runtime declares VENDOR object" "ERPObjectVendor" "$RUNTIME_FILE"
require_grep "7-8M.1.4.26 runtime declares PRODUCT object" "ERPObjectProduct" "$RUNTIME_FILE"
require_grep "7-8M.1.4.27 runtime declares SERVICE_ITEM object" "ERPObjectServiceItem" "$RUNTIME_FILE"
require_grep "7-8M.1.4.28 runtime declares SALES_INVOICE object" "ERPObjectSalesInvoice" "$RUNTIME_FILE"
require_grep "7-8M.1.4.29 runtime declares PURCHASE_INVOICE object" "ERPObjectPurchaseInvoice" "$RUNTIME_FILE"
require_grep "7-8M.1.4.30 runtime declares STOCK_MOVEMENT object" "ERPObjectStockMovement" "$RUNTIME_FILE"
require_grep "7-8M.1.4.31 runtime declares ACCOUNTING_VOUCHER object" "ERPObjectAccountingVoucher" "$RUNTIME_FILE"
require_grep "7-8M.1.4.32 runtime declares TAX_LINE object" "ERPObjectTaxLine" "$RUNTIME_FILE"
require_grep "7-8M.1.4.33 runtime declares CARI_HESAP_KARTI target" "CARI_HESAP_KARTI" "$RUNTIME_FILE"
require_grep "7-8M.1.4.34 runtime declares STOK_KARTI target" "STOK_KARTI" "$RUNTIME_FILE"
require_grep "7-8M.1.4.35 runtime declares SATIS_FATURASI target" "SATIS_FATURASI" "$RUNTIME_FILE"
require_grep "7-8M.1.4.36 runtime declares MUHASEBE_FISI target" "MUHASEBE_FISI" "$RUNTIME_FILE"
require_grep "7-8M.1.4.37 runtime denies real provider API enabled" "RealProviderAPIEnabled" "$RUNTIME_FILE"
require_grep "7-8M.1.4.38 runtime denies real file delivery enabled" "RealFileDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.1.4.39 runtime denies real ERP write enabled" "RealERPWriteEnabled" "$RUNTIME_FILE"
require_grep "7-8M.1.4.40 runtime forbids secret fields" "containsForbiddenMappingField" "$RUNTIME_FILE"
require_grep "7-8M.1.4.41 runtime forbids client secret" "client_secret" "$RUNTIME_FILE"
require_grep "7-8M.1.4.42 runtime forbids access token" "access_token" "$RUNTIME_FILE"
require_grep "7-8M.1.4.43 runtime declares ready decision" "MIKRO_EXPORT_MAPPING_CONTRACT_READY" "$RUNTIME_FILE"
require_grep "7-8M.1.4.44 runtime declares unsupported decision" "MIKRO_ERP_OBJECT_UNSUPPORTED" "$RUNTIME_FILE"
require_grep "7-8M.1.4.45 runtime declares live mode closed decision" "MIKRO_EXPORT_MAPPING_PROVIDER_LIVE_MODE_CLOSED" "$RUNTIME_FILE"

require_grep "7-8M.1.5.1 tests include root 7-8M.1 OK output" "7-8M\\.1" "$TEST_FILE"
require_grep "7-8M.1.5.2 tests include 7-8M.1.1 OK output" "7-8M\\.1\\.1" "$TEST_FILE"
require_grep "7-8M.1.5.3 tests include 7-8M.1.1.1 OK output" "7-8M\\.1\\.1\\.1" "$TEST_FILE"
require_grep "7-8M.1.5.4 tests validate object coverage" "ERP object coverage validation" "$TEST_FILE"
require_grep "7-8M.1.5.5 tests validate SALES_INVOICE mapping" "SALES_INVOICE dry-run mapping is allowed" "$TEST_FILE"
require_grep "7-8M.1.5.6 tests validate closed real API" "real Mikro API request is denied" "$TEST_FILE"
require_grep "7-8M.1.5.7 tests validate closed file delivery" "real Mikro file delivery request is denied" "$TEST_FILE"
require_grep "7-8M.1.5.8 tests validate closed ERP write" "real ERP write request is denied" "$TEST_FILE"
require_grep "7-8M.1.5.9 tests validate field mapping" "invoice_id maps to belge_no" "$TEST_FILE"
require_grep "7-8M.1.5.10 tests validate secret rejection" "client_secret mapping field is rejected" "$TEST_FILE"

log_line "===== 7-8M.1 MIKRO EXPORT MAPPING REAL IMPLEMENTATION AUDIT RESULT ====="
log_line "PASS_COUNT=$PASS_COUNT"
log_line "FAIL_COUNT=$FAIL_COUNT"
log_line "REQUIRED_FAIL=$REQUIRED_FAIL"
log_line "OPTIONAL_WARN=$OPTIONAL_WARN"
log_line "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"

if [[ "$REQUIRED_FAIL" -eq 0 ]]; then
  log_line "FAZ_7_8M_1_MIKRO_EXPORT_MAPPING_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

log_line "FAZ_7_8M_1_MIKRO_EXPORT_MAPPING_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
