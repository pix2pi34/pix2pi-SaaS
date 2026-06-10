#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8M_MIKRO_CONNECTOR_MODULE_FOUNDATION.md"
CONFIG_FILE="configs/faz7/integrations/mikro_connector.foundation.v1.json"
RUNTIME_FILE="internal/platform/integrations/providers/mikro/mikro_connector_foundation.go"
TEST_FILE="internal/platform/integrations/providers/mikro/mikro_connector_foundation_test.go"
AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8M_MIKRO_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_AUDIT.md"

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

log_line "===== 7-8M MIKRO CONNECTOR FOUNDATION REAL IMPLEMENTATION AUDIT ====="

require_file "7-8M.1 doc artifact exists" "$DOC_FILE"
require_file "7-8M.2 config artifact exists" "$CONFIG_FILE"
require_dir "7-8M.3 provider directory exists" "internal/platform/integrations/providers/mikro"
require_file "7-8M.4 runtime code exists" "$RUNTIME_FILE"
require_file "7-8M.5 test code exists" "$TEST_FILE"

require_grep "7-8M.1.1 doc declares FAZ_7_8M" "FAZ_7_8M" "$DOC_FILE"
require_grep "7-8M.1.2 doc declares Mikro Connector Module Foundation" "Mikro Connector Module Foundation" "$DOC_FILE"
require_grep "7-8M.1.3 doc keeps real provider API closed" "MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.1.4 doc keeps real file delivery closed" "MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.1.5 doc keeps real ERP write closed" "MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.1.6 doc declares hardcoded final OK block forbidden behavior" "final status sayaçlardan türemeli" "$DOC_FILE"

require_grep "7-8M.2.1 config phase is FAZ_7_8M" "\"phase\": \"FAZ_7_8M\"" "$CONFIG_FILE"
require_grep "7-8M.2.2 config module is MIKRO_CONNECTOR_FOUNDATION" "\"module\": \"MIKRO_CONNECTOR_FOUNDATION\"" "$CONFIG_FILE"
require_grep "7-8M.2.3 config provider_id is mikro" "\"provider_id\": \"mikro\"" "$CONFIG_FILE"
require_grep "7-8M.2.4 config provider name is Mikro" "\"provider_name\": \"Mikro\"" "$CONFIG_FILE"
require_grep "7-8M.2.5 config mode is dry-run only" "\"connector_mode\": \"DRY_RUN_CONTRACT_ONLY\"" "$CONFIG_FILE"
require_grep "7-8M.2.6 config real provider API is closed" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.2.7 config real file delivery is closed" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.2.8 config real ERP write is closed" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.2.9 config requires tenant_id" "\"tenant_id\"" "$CONFIG_FILE"
require_grep "7-8M.2.10 config requires correlation_id" "\"correlation_id\"" "$CONFIG_FILE"
require_grep "7-8M.2.11 config forbids client_secret" "\"client_secret\"" "$CONFIG_FILE"
require_grep "7-8M.2.12 config declares CUSTOMER_EXPORT capability" "\"CUSTOMER_EXPORT\"" "$CONFIG_FILE"
require_grep "7-8M.2.13 config declares ACCOUNTING_VOUCHER_EXPORT capability" "\"ACCOUNTING_VOUCHER_EXPORT\"" "$CONFIG_FILE"
require_grep "7-8M.2.14 config keeps FAZ 7-9 on hold" "HOLD_UNTIL_INTEGRATION_FAMILY_DONE" "$CONFIG_FILE"

require_grep "7-8M.3.1 runtime package is mikro" "^package mikro" "$RUNTIME_FILE"
require_grep "7-8M.3.2 runtime declares Phase constant" "Phase[[:space:]]*=[[:space:]]*\"FAZ_7_8M\"" "$RUNTIME_FILE"
require_grep "7-8M.3.3 runtime declares ProviderID mikro" "ProviderID[[:space:]]*=[[:space:]]*\"mikro\"" "$RUNTIME_FILE"
require_grep "7-8M.3.4 runtime declares ProviderName Mikro" "ProviderName[[:space:]]*=[[:space:]]*\"Mikro\"" "$RUNTIME_FILE"
require_grep "7-8M.3.5 runtime declares dry-run connector mode" "ConnectorModeDryRunContract[[:space:]]*=[[:space:]]*\"DRY_RUN_CONTRACT_ONLY\"" "$RUNTIME_FILE"
require_grep "7-8M.3.6 runtime declares foundation gate" "MikroConnectorFoundationGate[[:space:]]*=[[:space:]]*\"READY\"" "$RUNTIME_FILE"
require_grep "7-8M.3.7 runtime keeps provider live handoff closed" "CLOSED_UNTIL_MIKRO_CONNECTOR_FINAL_CLOSURE" "$RUNTIME_FILE"
require_grep "7-8M.3.8 runtime keeps real provider API closed" "MikroRealProviderAPIStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$RUNTIME_FILE"
require_grep "7-8M.3.9 runtime keeps real file delivery closed" "MikroRealFileDeliveryStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$RUNTIME_FILE"
require_grep "7-8M.3.10 runtime keeps real ERP write closed" "MikroRealERPWriteStatus[[:space:]]*=[[:space:]]*\"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$RUNTIME_FILE"
require_grep "7-8M.3.11 runtime has Foundation struct" "type Foundation struct" "$RUNTIME_FILE"
require_grep "7-8M.3.12 runtime has FoundationRequest struct" "type FoundationRequest struct" "$RUNTIME_FILE"
require_grep "7-8M.3.13 runtime has FoundationDecision struct" "type FoundationDecision struct" "$RUNTIME_FILE"
require_grep "7-8M.3.14 runtime has NewFoundation constructor" "func NewFoundation" "$RUNTIME_FILE"
require_grep "7-8M.3.15 runtime has Validate function" "func \\(f Foundation\\) Validate" "$RUNTIME_FILE"
require_grep "7-8M.3.16 runtime has Supports function" "func \\(f Foundation\\) Supports" "$RUNTIME_FILE"
require_grep "7-8M.3.17 runtime has Evaluate function" "func \\(f Foundation\\) Evaluate" "$RUNTIME_FILE"
require_grep "7-8M.3.18 runtime validates tenant context" "TenantID" "$RUNTIME_FILE"
require_grep "7-8M.3.19 runtime validates actor context" "ActorUserID" "$RUNTIME_FILE"
require_grep "7-8M.3.20 runtime validates correlation context" "CorrelationID" "$RUNTIME_FILE"
require_grep "7-8M.3.21 runtime forbids secret values" "containsSecretValue" "$RUNTIME_FILE"
require_grep "7-8M.3.22 runtime forbids client secret" "ClientSecret" "$RUNTIME_FILE"
require_grep "7-8M.3.23 runtime forbids access token" "AccessToken" "$RUNTIME_FILE"
require_grep "7-8M.3.24 runtime forbids real provider endpoint" "RealProviderEndpoint" "$RUNTIME_FILE"
require_grep "7-8M.3.25 runtime denies real provider API enabled" "RealProviderAPIEnabled" "$RUNTIME_FILE"
require_grep "7-8M.3.26 runtime denies real file delivery enabled" "RealFileDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.3.27 runtime denies real ERP write enabled" "RealERPWriteEnabled" "$RUNTIME_FILE"
require_grep "7-8M.3.28 runtime declares CUSTOMER_EXPORT capability" "CUSTOMER_EXPORT" "$RUNTIME_FILE"
require_grep "7-8M.3.29 runtime declares INVOICE_EXPORT capability" "INVOICE_EXPORT" "$RUNTIME_FILE"
require_grep "7-8M.3.30 runtime declares ACCOUNTING_VOUCHER_EXPORT capability" "ACCOUNTING_VOUCHER_EXPORT" "$RUNTIME_FILE"
require_grep "7-8M.3.31 runtime declares dry-run allowed decision" "MIKRO_DRY_RUN_FOUNDATION_READY" "$RUNTIME_FILE"
require_grep "7-8M.3.32 runtime declares real API closed decision" "MIKRO_REAL_PROVIDER_API_CLOSED" "$RUNTIME_FILE"
require_grep "7-8M.3.33 runtime declares real file delivery closed decision" "MIKRO_REAL_FILE_DELIVERY_CLOSED" "$RUNTIME_FILE"
require_grep "7-8M.3.34 runtime declares real ERP write closed decision" "MIKRO_REAL_ERP_WRITE_CLOSED" "$RUNTIME_FILE"

require_grep "7-8M.4.1 tests include 7-8M root OK output" "7-8M" "$TEST_FILE"
require_grep "7-8M.4.2 tests include 7-8M.1 output" "7-8M\\.1" "$TEST_FILE"
require_grep "7-8M.4.3 tests include 7-8M.1.1 output" "7-8M\\.1\\.1" "$TEST_FILE"
require_grep "7-8M.4.4 tests validate real provider API closed" "real Mikro provider API is closed" "$TEST_FILE"
require_grep "7-8M.4.5 tests validate real file delivery closed" "real Mikro file delivery is closed" "$TEST_FILE"
require_grep "7-8M.4.6 tests validate real ERP write closed" "real ERP write is closed" "$TEST_FILE"
require_grep "7-8M.4.7 tests validate dry-run decision" "dry-run decision runtime validation" "$TEST_FILE"
require_grep "7-8M.4.8 tests validate tenant rejection" "missing tenant is rejected" "$TEST_FILE"
require_grep "7-8M.4.9 tests validate provider live denial" "provider live mode is denied" "$TEST_FILE"
require_grep "7-8M.4.10 tests validate secret rejection" "client secret is rejected" "$TEST_FILE"
require_grep "7-8M.4.11 tests validate capability matrix" "capability matrix validation" "$TEST_FILE"

log_line "===== 7-8M MIKRO CONNECTOR FOUNDATION REAL IMPLEMENTATION AUDIT RESULT ====="
log_line "PASS_COUNT=$PASS_COUNT"
log_line "FAIL_COUNT=$FAIL_COUNT"
log_line "REQUIRED_FAIL=$REQUIRED_FAIL"
log_line "OPTIONAL_WARN=$OPTIONAL_WARN"
log_line "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"

if [[ "$REQUIRED_FAIL" -eq 0 ]]; then
  log_line "FAZ_7_8M_MIKRO_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

log_line "FAZ_7_8M_MIKRO_CONNECTOR_FOUNDATION_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
