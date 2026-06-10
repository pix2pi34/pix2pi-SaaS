#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8M_7_MIKRO_CONNECTOR_FINAL_CLOSURE.md"
CONFIG_FILE="configs/faz7/integrations/mikro_connector_final_closure.v1.json"
FOUNDATION_FILE="internal/platform/integrations/providers/mikro/mikro_connector_foundation.go"
MAPPING_FILE="internal/platform/integrations/providers/mikro/mikro_export_mapping.go"
FILE_GENERATION_FILE="internal/platform/integrations/providers/mikro/mikro_file_generation_dry_run.go"
IMPORT_DELIVERY_FILE="internal/platform/integrations/providers/mikro/mikro_import_delivery.go"
VALIDATION_FILE="internal/platform/integrations/providers/mikro/mikro_validation_retry_dlq.go"
ADMIN_OPS_FILE="internal/platform/integrations/providers/mikro/mikro_admin_ops.go"
E2E_FILE="internal/platform/integrations/providers/mikro/mikro_e2e_dry_run.go"
RUNTIME_FILE="internal/platform/integrations/providers/mikro/mikro_final_closure.go"
TEST_FILE="internal/platform/integrations/providers/mikro/mikro_final_closure_test.go"
AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8M_7_MIKRO_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

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

log_line "===== 7-8M.7 MIKRO FINAL CLOSURE REAL IMPLEMENTATION AUDIT ====="

require_file "7-8M.7.1 doc artifact exists" "$DOC_FILE"
require_file "7-8M.7.2 config artifact exists" "$CONFIG_FILE"
require_dir "7-8M.7.3 provider directory exists" "internal/platform/integrations/providers/mikro"
require_file "7-8M.7.4 foundation runtime exists" "$FOUNDATION_FILE"
require_file "7-8M.7.5 export mapping runtime exists" "$MAPPING_FILE"
require_file "7-8M.7.6 file generation runtime exists" "$FILE_GENERATION_FILE"
require_file "7-8M.7.7 import delivery runtime exists" "$IMPORT_DELIVERY_FILE"
require_file "7-8M.7.8 validation retry-dlq runtime exists" "$VALIDATION_FILE"
require_file "7-8M.7.9 admin ops runtime exists" "$ADMIN_OPS_FILE"
require_file "7-8M.7.10 e2e dry-run runtime exists" "$E2E_FILE"
require_file "7-8M.7.11 final closure runtime code exists" "$RUNTIME_FILE"
require_file "7-8M.7.12 final closure test code exists" "$TEST_FILE"

require_grep "7-8M.7.1.1 doc declares FAZ_7_8M_7" "FAZ_7_8M_7" "$DOC_FILE"
require_grep "7-8M.7.1.2 doc declares Mikro Connector Final Closure" "Mikro Connector Final Closure" "$DOC_FILE"
require_grep "7-8M.7.1.3 doc declares Provider Live Module Handoff Gate" "Provider Live Module Handoff Gate" "$DOC_FILE"
require_grep "7-8M.7.1.4 doc declares CONNECTOR_DRY_RUN_FINAL_CLOSURE_ONLY" "CONNECTOR_DRY_RUN_FINAL_CLOSURE_ONLY" "$DOC_FILE"
require_grep "7-8M.7.1.5 doc declares SEALED" "SEALED" "$DOC_FILE"
require_grep "7-8M.7.1.6 doc declares READY_FOR_PROVIDER_LIVE_MODULE" "READY_FOR_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.7.1.7 doc declares NOT_STARTED" "NOT_STARTED" "$DOC_FILE"
require_grep "7-8M.7.1.8 doc declares Foundation" "Foundation" "$DOC_FILE"
require_grep "7-8M.7.1.9 doc declares Export Mapping" "Export Mapping" "$DOC_FILE"
require_grep "7-8M.7.1.10 doc declares File Generation" "File Generation" "$DOC_FILE"
require_grep "7-8M.7.1.11 doc declares Import Delivery" "Import Delivery" "$DOC_FILE"
require_grep "7-8M.7.1.12 doc declares Validation Retry-DLQ" "Validation Retry-DLQ" "$DOC_FILE"
require_grep "7-8M.7.1.13 doc declares Admin Ops" "Admin Ops" "$DOC_FILE"
require_grep "7-8M.7.1.14 doc declares E2E Dry-Run" "E2E Dry-Run" "$DOC_FILE"
require_grep "7-8M.7.1.15 doc keeps real provider API closed" "MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.7.1.16 doc keeps real file delivery closed" "MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.7.1.17 doc keeps real ERP write closed" "MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.7.1.18 doc keeps real delivery channel closed" "MIKRO_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.7.1.19 doc keeps real operator provider action closed" "MIKRO_REAL_OPERATOR_PROVIDER_ACTION_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.7.1.20 doc declares no real queue write" "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE" "$DOC_FILE"
require_grep "7-8M.7.1.21 doc requires counter based final status" "final status sayaçlardan türemeli" "$DOC_FILE"

require_grep "7-8M.7.2.1 config phase is FAZ_7_8M_7" "\"phase\": \"FAZ_7_8M_7\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.2 config module is final closure" "\"module\": \"MIKRO_CONNECTOR_FINAL_CLOSURE\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.3 config provider id is mikro" "\"provider_id\": \"mikro\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.4 config provider name is Mikro" "\"provider_name\": \"Mikro\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.5 config final closure mode" "\"final_closure_mode\": \"CONNECTOR_DRY_RUN_FINAL_CLOSURE_ONLY\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.6 config direction is PIX2PI_TO_MIKRO" "\"direction\": \"PIX2PI_TO_MIKRO\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.7 config target system is Mikro dry-run import" "\"target_system\": \"MIKRO_ACCOUNTING_IMPORT_DRY_RUN\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.8 config dry-run module status sealed" "\"dry_run_module_status\": \"SEALED\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.9 config provider live handoff gate ready" "\"provider_live_handoff_gate\": \"READY_FOR_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.10 config provider live module not started" "\"provider_live_module_status\": \"NOT_STARTED\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.11 config declares no real queue write" "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE" "$CONFIG_FILE"
require_grep "7-8M.7.2.12 config has foundation closure chain" "\"FOUNDATION\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.13 config has export mapping closure chain" "\"EXPORT_MAPPING\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.14 config has file generation closure chain" "\"FILE_GENERATION\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.15 config has import delivery closure chain" "\"IMPORT_DELIVERY\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.16 config has validation retry dlq closure chain" "\"VALIDATION_RETRY_DLQ\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.17 config has admin ops closure chain" "\"ADMIN_OPS\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.18 config has e2e dry-run closure chain" "\"E2E_DRY_RUN\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.19 config real provider API closed" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.20 config real file delivery closed" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.21 config real ERP write closed" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.22 config real delivery channel closed" "\"real_delivery_channel_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.23 config real operator provider action closed" "\"real_operator_provider_action_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.24 config requires closure_id" "\"closure_id\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.25 config requires package_id" "\"package_id\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.26 config forbids client_secret" "\"client_secret\"" "$CONFIG_FILE"
require_grep "7-8M.7.2.27 config keeps FAZ 7-9 on hold" "HOLD_UNTIL_INTEGRATION_FAMILY_DONE" "$CONFIG_FILE"

require_grep "7-8M.7.3.1 foundation runtime has phase 7-8M" "Phase[[:space:]]*=[[:space:]]*\"FAZ_7_8M\"" "$FOUNDATION_FILE"
require_grep "7-8M.7.3.2 mapping runtime has phase 7-8M.1" "MikroExportMappingPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_1\"" "$MAPPING_FILE"
require_grep "7-8M.7.3.3 file generation runtime has phase 7-8M.2" "MikroFileGenerationPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_2\"" "$FILE_GENERATION_FILE"
require_grep "7-8M.7.3.4 import delivery runtime has phase 7-8M.3" "MikroImportDeliveryPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_3\"" "$IMPORT_DELIVERY_FILE"
require_grep "7-8M.7.3.5 validation runtime has phase 7-8M.4" "MikroValidationRetryDLQPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_4\"" "$VALIDATION_FILE"
require_grep "7-8M.7.3.6 admin ops runtime has phase 7-8M.5" "MikroAdminOpsPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_5\"" "$ADMIN_OPS_FILE"
require_grep "7-8M.7.3.7 e2e runtime has phase 7-8M.6" "MikroE2EDryRunPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_6\"" "$E2E_FILE"

require_grep "7-8M.7.4.1 runtime package is mikro" "^package mikro" "$RUNTIME_FILE"
require_grep "7-8M.7.4.2 runtime declares phase" "MikroFinalClosurePhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_7\"" "$RUNTIME_FILE"
require_grep "7-8M.7.4.3 runtime declares module" "MIKRO_CONNECTOR_FINAL_CLOSURE" "$RUNTIME_FILE"
require_grep "7-8M.7.4.4 runtime declares final closure mode" "CONNECTOR_DRY_RUN_FINAL_CLOSURE_ONLY" "$RUNTIME_FILE"
require_grep "7-8M.7.4.5 runtime declares direction" "PIX2PI_TO_MIKRO" "$RUNTIME_FILE"
require_grep "7-8M.7.4.6 runtime declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$RUNTIME_FILE"
require_grep "7-8M.7.4.7 runtime declares connector module sealed" "MikroConnectorModuleFinalSealStatus" "$RUNTIME_FILE"
require_grep "7-8M.7.4.8 runtime declares dry-run module sealed" "MikroDryRunModuleStatus" "$RUNTIME_FILE"
require_grep "7-8M.7.4.9 runtime declares provider live handoff gate" "MikroFinalClosureProviderLiveHandoffGate" "$RUNTIME_FILE"
require_grep "7-8M.7.4.10 runtime declares provider live not started" "MikroProviderLiveModuleStatus" "$RUNTIME_FILE"
require_grep "7-8M.7.4.11 runtime declares no real queue write" "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE" "$RUNTIME_FILE"
require_grep "7-8M.7.4.12 runtime uses real provider API closed status" "MikroRealProviderAPIStatus" "$RUNTIME_FILE"
require_grep "7-8M.7.4.13 runtime uses real file delivery closed status" "MikroRealFileDeliveryStatus" "$RUNTIME_FILE"
require_grep "7-8M.7.4.14 runtime uses real ERP write closed status" "MikroRealERPWriteStatus" "$RUNTIME_FILE"
require_grep "7-8M.7.4.15 runtime uses real delivery channel closed status" "MikroRealDeliveryChannelStatus" "$RUNTIME_FILE"
require_grep "7-8M.7.4.16 runtime uses real operator provider action closed status" "MikroRealOperatorProviderActionStatus" "$RUNTIME_FILE"
require_grep "7-8M.7.4.17 runtime has final closure contract type" "type MikroFinalClosureContract struct" "$RUNTIME_FILE"
require_grep "7-8M.7.4.18 runtime has final closure request type" "type MikroFinalClosureRequest struct" "$RUNTIME_FILE"
require_grep "7-8M.7.4.19 runtime has final closure result type" "type MikroFinalClosureResult struct" "$RUNTIME_FILE"
require_grep "7-8M.7.4.20 runtime has final closure decision type" "type MikroFinalClosureDecision struct" "$RUNTIME_FILE"
require_grep "7-8M.7.4.21 runtime has final closure runtime type" "type MikroFinalClosureRuntime struct" "$RUNTIME_FILE"
require_grep "7-8M.7.4.22 runtime has contract constructor" "func NewMikroFinalClosureContract" "$RUNTIME_FILE"
require_grep "7-8M.7.4.23 runtime has runtime constructor" "func NewMikroFinalClosureRuntime" "$RUNTIME_FILE"
require_grep "7-8M.7.4.24 runtime has validate method" "func \\(c MikroFinalClosureContract\\) Validate" "$RUNTIME_FILE"
require_grep "7-8M.7.4.25 runtime has BuildFinalClosure" "BuildFinalClosure" "$RUNTIME_FILE"
require_grep "7-8M.7.4.26 runtime validates foundation" "NewFoundation" "$RUNTIME_FILE"
require_grep "7-8M.7.4.27 runtime validates export mapping" "NewMikroExportMappingContract" "$RUNTIME_FILE"
require_grep "7-8M.7.4.28 runtime validates file generation" "NewMikroFileGenerationContract" "$RUNTIME_FILE"
require_grep "7-8M.7.4.29 runtime validates import delivery" "NewMikroImportDeliveryContract" "$RUNTIME_FILE"
require_grep "7-8M.7.4.30 runtime validates validation retry-dlq" "NewMikroValidationRetryDLQContract" "$RUNTIME_FILE"
require_grep "7-8M.7.4.31 runtime validates admin ops" "NewMikroAdminOpsContract" "$RUNTIME_FILE"
require_grep "7-8M.7.4.32 runtime validates e2e smoke" "NewMikroE2EDryRunRuntime" "$RUNTIME_FILE"
require_grep "7-8M.7.4.33 runtime has base decision" "baseDecision" "$RUNTIME_FILE"
require_grep "7-8M.7.4.34 runtime has closed real operation guard" "guardClosedRealOperations" "$RUNTIME_FILE"
require_grep "7-8M.7.4.35 runtime validates final closure request" "validateMikroFinalClosureRequest" "$RUNTIME_FILE"
require_grep "7-8M.7.4.36 runtime validates tenant id" "TenantID" "$RUNTIME_FILE"
require_grep "7-8M.7.4.37 runtime validates actor user id" "ActorUserID" "$RUNTIME_FILE"
require_grep "7-8M.7.4.38 runtime validates correlation id" "CorrelationID" "$RUNTIME_FILE"
require_grep "7-8M.7.4.39 runtime validates closure id" "ClosureID" "$RUNTIME_FILE"
require_grep "7-8M.7.4.40 runtime validates package id" "PackageID" "$RUNTIME_FILE"
require_grep "7-8M.7.4.41 runtime validates delivery id" "DeliveryID" "$RUNTIME_FILE"
require_grep "7-8M.7.4.42 runtime validates validation id" "ValidationID" "$RUNTIME_FILE"
require_grep "7-8M.7.4.43 runtime validates review id" "ReviewID" "$RUNTIME_FILE"
require_grep "7-8M.7.4.44 runtime denies provider live mode" "PROVIDER_LIVE" "$RUNTIME_FILE"
require_grep "7-8M.7.4.45 runtime denies real provider API enabled" "RealProviderAPIEnabled" "$RUNTIME_FILE"
require_grep "7-8M.7.4.46 runtime denies real file delivery enabled" "RealFileDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.7.4.47 runtime denies real ERP write enabled" "RealERPWriteEnabled" "$RUNTIME_FILE"
require_grep "7-8M.7.4.48 runtime denies real delivery enabled" "RealDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.7.4.49 runtime denies real operator provider action enabled" "RealOperatorProviderActionEnabled" "$RUNTIME_FILE"
require_grep "7-8M.7.4.50 runtime forbids secret fields" "containsForbiddenMappingField" "$RUNTIME_FILE"
require_grep "7-8M.7.4.51 runtime declares final ready decision" "MIKRO_CONNECTOR_FINAL_CLOSURE_READY" "$RUNTIME_FILE"

require_grep "7-8M.7.5.1 tests include root 7-8M.7 OK output" "7-8M\\.7" "$TEST_FILE"
require_grep "7-8M.7.5.2 tests include 7-8M.7.1 OK output" "7-8M\\.7\\.1" "$TEST_FILE"
require_grep "7-8M.7.5.3 tests include 7-8M.7.1.1 OK output" "7-8M\\.7\\.1\\.1" "$TEST_FILE"
require_grep "7-8M.7.5.4 tests validate sealed result" "final closure sealed result validation" "$TEST_FILE"
require_grep "7-8M.7.5.5 tests validate provider handoff gate" "provider live handoff gate is READY_FOR_PROVIDER_LIVE_MODULE" "$TEST_FILE"
require_grep "7-8M.7.5.6 tests validate previous module chain" "previous module chain validation" "$TEST_FILE"
require_grep "7-8M.7.5.7 tests validate foundation" "Foundation is validated" "$TEST_FILE"
require_grep "7-8M.7.5.8 tests validate export mapping" "Export Mapping is validated" "$TEST_FILE"
require_grep "7-8M.7.5.9 tests validate file generation" "File Generation is validated" "$TEST_FILE"
require_grep "7-8M.7.5.10 tests validate import delivery" "Import Delivery is validated" "$TEST_FILE"
require_grep "7-8M.7.5.11 tests validate validation retry-dlq" "Validation Retry-DLQ is validated" "$TEST_FILE"
require_grep "7-8M.7.5.12 tests validate admin ops" "Admin Ops is validated" "$TEST_FILE"
require_grep "7-8M.7.5.13 tests validate e2e dry-run" "E2E Dry-Run is validated" "$TEST_FILE"
require_grep "7-8M.7.5.14 tests validate closed real API" "real Mikro API request is denied" "$TEST_FILE"
require_grep "7-8M.7.5.15 tests validate closed file delivery" "real Mikro file delivery request is denied" "$TEST_FILE"
require_grep "7-8M.7.5.16 tests validate closed ERP write" "real ERP write request is denied" "$TEST_FILE"
require_grep "7-8M.7.5.17 tests validate closed real provider action" "real operator provider action request is denied" "$TEST_FILE"
require_grep "7-8M.7.5.18 tests validate closure id guard" "missing closure id is rejected" "$TEST_FILE"
require_grep "7-8M.7.5.19 tests validate package id guard" "missing package id is rejected" "$TEST_FILE"
require_grep "7-8M.7.5.20 tests validate provider live denied" "provider live mode is denied" "$TEST_FILE"
require_grep "7-8M.7.5.21 tests validate secret rejection" "client_secret field is rejected" "$TEST_FILE"

log_line "===== 7-8M.7 MIKRO FINAL CLOSURE REAL IMPLEMENTATION AUDIT RESULT ====="
log_line "PASS_COUNT=$PASS_COUNT"
log_line "FAIL_COUNT=$FAIL_COUNT"
log_line "REQUIRED_FAIL=$REQUIRED_FAIL"
log_line "OPTIONAL_WARN=$OPTIONAL_WARN"
log_line "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"

if [[ "$REQUIRED_FAIL" -eq 0 ]]; then
  log_line "FAZ_7_8M_7_MIKRO_FINAL_CLOSURE_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

log_line "FAZ_7_8M_7_MIKRO_FINAL_CLOSURE_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
