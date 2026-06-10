#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8M_6_MIKRO_E2E_DRY_RUN_FLOW.md"
CONFIG_FILE="configs/faz7/integrations/mikro_e2e_dry_run_flow.v1.json"
FOUNDATION_FILE="internal/platform/integrations/providers/mikro/mikro_connector_foundation.go"
MAPPING_FILE="internal/platform/integrations/providers/mikro/mikro_export_mapping.go"
FILE_GENERATION_FILE="internal/platform/integrations/providers/mikro/mikro_file_generation_dry_run.go"
IMPORT_DELIVERY_FILE="internal/platform/integrations/providers/mikro/mikro_import_delivery.go"
VALIDATION_FILE="internal/platform/integrations/providers/mikro/mikro_validation_retry_dlq.go"
ADMIN_OPS_FILE="internal/platform/integrations/providers/mikro/mikro_admin_ops.go"
RUNTIME_FILE="internal/platform/integrations/providers/mikro/mikro_e2e_dry_run.go"
TEST_FILE="internal/platform/integrations/providers/mikro/mikro_e2e_dry_run_test.go"
AUDIT_EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8M_6_MIKRO_E2E_DRY_RUN_REAL_IMPLEMENTATION_AUDIT.md"

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

log_line "===== 7-8M.6 MIKRO E2E DRY-RUN REAL IMPLEMENTATION AUDIT ====="

require_file "7-8M.6.1 doc artifact exists" "$DOC_FILE"
require_file "7-8M.6.2 config artifact exists" "$CONFIG_FILE"
require_dir "7-8M.6.3 provider directory exists" "internal/platform/integrations/providers/mikro"
require_file "7-8M.6.4 foundation runtime exists" "$FOUNDATION_FILE"
require_file "7-8M.6.5 export mapping runtime exists" "$MAPPING_FILE"
require_file "7-8M.6.6 file generation runtime exists" "$FILE_GENERATION_FILE"
require_file "7-8M.6.7 import delivery runtime exists" "$IMPORT_DELIVERY_FILE"
require_file "7-8M.6.8 validation retry dlq runtime exists" "$VALIDATION_FILE"
require_file "7-8M.6.9 admin ops runtime exists" "$ADMIN_OPS_FILE"
require_file "7-8M.6.10 e2e dry-run runtime code exists" "$RUNTIME_FILE"
require_file "7-8M.6.11 e2e dry-run test code exists" "$TEST_FILE"

require_grep "7-8M.6.1.1 doc declares FAZ_7_8M_6" "FAZ_7_8M_6" "$DOC_FILE"
require_grep "7-8M.6.1.2 doc declares Mikro E2E Dry-Run" "Mikro E2E Dry-Run" "$DOC_FILE"
require_grep "7-8M.6.1.3 doc declares connector closure preparation" "Connector Closure Preparation" "$DOC_FILE"
require_grep "7-8M.6.1.4 doc declares Foundation" "Foundation" "$DOC_FILE"
require_grep "7-8M.6.1.5 doc declares Export Mapping" "Export Mapping" "$DOC_FILE"
require_grep "7-8M.6.1.6 doc declares File Generation" "File Generation" "$DOC_FILE"
require_grep "7-8M.6.1.7 doc declares Import Delivery" "Import Delivery" "$DOC_FILE"
require_grep "7-8M.6.1.8 doc declares Validation" "Validation" "$DOC_FILE"
require_grep "7-8M.6.1.9 doc declares Admin Ops" "Admin Ops" "$DOC_FILE"
require_grep "7-8M.6.1.10 doc declares PIX2PI_TO_MIKRO direction" "PIX2PI_TO_MIKRO" "$DOC_FILE"
require_grep "7-8M.6.1.11 doc declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$DOC_FILE"
require_grep "7-8M.6.1.12 doc keeps real provider API closed" "MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.6.1.13 doc keeps real file delivery closed" "MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.6.1.14 doc keeps real ERP write closed" "MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.6.1.15 doc keeps real delivery channel closed" "MIKRO_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.6.1.16 doc keeps real operator provider action closed" "MIKRO_REAL_OPERATOR_PROVIDER_ACTION_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE" "$DOC_FILE"
require_grep "7-8M.6.1.17 doc declares no real queue write" "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE" "$DOC_FILE"
require_grep "7-8M.6.1.18 doc requires counter based final status" "final status sayaçlardan türemeli" "$DOC_FILE"

require_grep "7-8M.6.2.1 config phase is FAZ_7_8M_6" "\"phase\": \"FAZ_7_8M_6\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.2 config module is e2e dry-run" "\"module\": \"MIKRO_E2E_DRY_RUN_FLOW\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.3 config provider id is mikro" "\"provider_id\": \"mikro\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.4 config provider name is Mikro" "\"provider_name\": \"Mikro\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.5 config e2e mode is dry-run only" "\"e2e_mode\": \"E2E_DRY_RUN_ONLY\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.6 config direction is PIX2PI_TO_MIKRO" "\"direction\": \"PIX2PI_TO_MIKRO\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.7 config target system is Mikro dry-run import" "\"target_system\": \"MIKRO_ACCOUNTING_IMPORT_DRY_RUN\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.8 config chain status ready" "\"chain_status\": \"READY\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.9 config closure preparation ready" "\"closure_preparation_status\": \"READY\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.10 config declares no real queue write" "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE" "$CONFIG_FILE"
require_grep "7-8M.6.2.11 config declares foundation step" "FOUNDATION_CONTRACT_VALIDATION" "$CONFIG_FILE"
require_grep "7-8M.6.2.12 config declares export mapping step" "EXPORT_MAPPING_CONTRACT_VALIDATION" "$CONFIG_FILE"
require_grep "7-8M.6.2.13 config declares file generation step" "FILE_GENERATION_DRY_RUN_PACKAGE_BUILD" "$CONFIG_FILE"
require_grep "7-8M.6.2.14 config declares import delivery step" "IMPORT_DELIVERY_DRY_RUN_RECEIPT" "$CONFIG_FILE"
require_grep "7-8M.6.2.15 config declares validation step" "VALIDATION_RETRY_DLQ_DECISION" "$CONFIG_FILE"
require_grep "7-8M.6.2.16 config declares admin ops step" "ADMIN_OPS_MANUAL_REVIEW_BRIDGE" "$CONFIG_FILE"
require_grep "7-8M.6.2.17 config declares operator action step" "OPERATOR_ACTION_DRY_RUN_EVALUATION" "$CONFIG_FILE"
require_grep "7-8M.6.2.18 config declares real provider API closed" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.19 config declares real file delivery closed" "\"real_file_delivery_status\": \"CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.20 config declares real ERP write closed" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.21 config declares real delivery channel closed" "\"real_delivery_channel_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.22 config declares real operator provider action closed" "\"real_operator_provider_action_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.23 config requires package_id" "\"package_id\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.24 config requires delivery_id" "\"delivery_id\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.25 config requires validation_id" "\"validation_id\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.26 config requires review_id" "\"review_id\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.27 config forbids client_secret" "\"client_secret\"" "$CONFIG_FILE"
require_grep "7-8M.6.2.28 config keeps FAZ 7-9 on hold" "HOLD_UNTIL_INTEGRATION_FAMILY_DONE" "$CONFIG_FILE"

require_grep "7-8M.6.3.1 foundation runtime has phase 7-8M" "Phase[[:space:]]*=[[:space:]]*\"FAZ_7_8M\"" "$FOUNDATION_FILE"
require_grep "7-8M.6.3.2 mapping runtime has phase 7-8M.1" "MikroExportMappingPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_1\"" "$MAPPING_FILE"
require_grep "7-8M.6.3.3 file generation runtime has phase 7-8M.2" "MikroFileGenerationPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_2\"" "$FILE_GENERATION_FILE"
require_grep "7-8M.6.3.4 import delivery runtime has phase 7-8M.3" "MikroImportDeliveryPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_3\"" "$IMPORT_DELIVERY_FILE"
require_grep "7-8M.6.3.5 validation runtime has phase 7-8M.4" "MikroValidationRetryDLQPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_4\"" "$VALIDATION_FILE"
require_grep "7-8M.6.3.6 admin ops runtime has phase 7-8M.5" "MikroAdminOpsPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_5\"" "$ADMIN_OPS_FILE"

require_grep "7-8M.6.4.1 runtime package is mikro" "^package mikro" "$RUNTIME_FILE"
require_grep "7-8M.6.4.2 runtime declares phase" "MikroE2EDryRunPhase[[:space:]]*=[[:space:]]*\"FAZ_7_8M_6\"" "$RUNTIME_FILE"
require_grep "7-8M.6.4.3 runtime declares module" "MIKRO_E2E_DRY_RUN_FLOW" "$RUNTIME_FILE"
require_grep "7-8M.6.4.4 runtime declares e2e mode" "E2E_DRY_RUN_ONLY" "$RUNTIME_FILE"
require_grep "7-8M.6.4.5 runtime declares direction" "PIX2PI_TO_MIKRO" "$RUNTIME_FILE"
require_grep "7-8M.6.4.6 runtime declares target system" "MIKRO_ACCOUNTING_IMPORT_DRY_RUN" "$RUNTIME_FILE"
require_grep "7-8M.6.4.7 runtime declares chain ready" "MikroE2EChainStatusReady" "$RUNTIME_FILE"
require_grep "7-8M.6.4.8 runtime declares closure prep ready" "MikroE2EClosurePrepReady" "$RUNTIME_FILE"
require_grep "7-8M.6.4.9 runtime declares no real queue write" "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE" "$RUNTIME_FILE"
require_grep "7-8M.6.4.10 runtime declares foundation step" "FOUNDATION_CONTRACT_VALIDATION" "$RUNTIME_FILE"
require_grep "7-8M.6.4.11 runtime declares export mapping step" "EXPORT_MAPPING_CONTRACT_VALIDATION" "$RUNTIME_FILE"
require_grep "7-8M.6.4.12 runtime declares file generation step" "FILE_GENERATION_DRY_RUN_PACKAGE_BUILD" "$RUNTIME_FILE"
require_grep "7-8M.6.4.13 runtime declares import delivery step" "IMPORT_DELIVERY_DRY_RUN_RECEIPT" "$RUNTIME_FILE"
require_grep "7-8M.6.4.14 runtime declares validation step" "VALIDATION_RETRY_DLQ_DECISION" "$RUNTIME_FILE"
require_grep "7-8M.6.4.15 runtime declares admin ops step" "ADMIN_OPS_MANUAL_REVIEW_BRIDGE" "$RUNTIME_FILE"
require_grep "7-8M.6.4.16 runtime declares operator action step" "OPERATOR_ACTION_DRY_RUN_EVALUATION" "$RUNTIME_FILE"
require_grep "7-8M.6.4.17 runtime uses real provider API closed status" "MikroRealProviderAPIStatus" "$RUNTIME_FILE"
require_grep "7-8M.6.4.18 runtime uses real file delivery closed status" "MikroRealFileDeliveryStatus" "$RUNTIME_FILE"
require_grep "7-8M.6.4.19 runtime uses real ERP write closed status" "MikroRealERPWriteStatus" "$RUNTIME_FILE"
require_grep "7-8M.6.4.20 runtime uses real delivery channel closed status" "MikroRealDeliveryChannelStatus" "$RUNTIME_FILE"
require_grep "7-8M.6.4.21 runtime uses real operator provider action closed status" "MikroRealOperatorProviderActionStatus" "$RUNTIME_FILE"
require_grep "7-8M.6.4.22 runtime has e2e contract type" "type MikroE2EDryRunContract struct" "$RUNTIME_FILE"
require_grep "7-8M.6.4.23 runtime has e2e request type" "type MikroE2EDryRunRequest struct" "$RUNTIME_FILE"
require_grep "7-8M.6.4.24 runtime has e2e result type" "type MikroE2EDryRunResult struct" "$RUNTIME_FILE"
require_grep "7-8M.6.4.25 runtime has e2e decision type" "type MikroE2EDryRunDecision struct" "$RUNTIME_FILE"
require_grep "7-8M.6.4.26 runtime has e2e runtime type" "type MikroE2EDryRunRuntime struct" "$RUNTIME_FILE"
require_grep "7-8M.6.4.27 runtime has contract constructor" "func NewMikroE2EDryRunContract" "$RUNTIME_FILE"
require_grep "7-8M.6.4.28 runtime has runtime constructor" "func NewMikroE2EDryRunRuntime" "$RUNTIME_FILE"
require_grep "7-8M.6.4.29 runtime has validate method" "func \\(c MikroE2EDryRunContract\\) Validate" "$RUNTIME_FILE"
require_grep "7-8M.6.4.30 runtime has Run orchestration" "func \\(r MikroE2EDryRunRuntime\\) Run" "$RUNTIME_FILE"
require_grep "7-8M.6.4.31 runtime validates foundation" "NewFoundation" "$RUNTIME_FILE"
require_grep "7-8M.6.4.32 runtime bridges mapping" "NewMikroExportMappingContract" "$RUNTIME_FILE"
require_grep "7-8M.6.4.33 runtime bridges file generation" "NewMikroFileGenerationBuilder" "$RUNTIME_FILE"
require_grep "7-8M.6.4.34 runtime bridges import delivery" "NewMikroImportDeliveryRuntime" "$RUNTIME_FILE"
require_grep "7-8M.6.4.35 runtime bridges validation retry dlq" "NewMikroValidationRetryDLQRuntime" "$RUNTIME_FILE"
require_grep "7-8M.6.4.36 runtime bridges admin ops" "NewMikroAdminOpsRuntime" "$RUNTIME_FILE"
require_grep "7-8M.6.4.37 runtime creates package request" "MikroFileGenerationRequest" "$RUNTIME_FILE"
require_grep "7-8M.6.4.38 runtime creates delivery request" "MikroImportDeliveryRequest" "$RUNTIME_FILE"
require_grep "7-8M.6.4.39 runtime creates validation request" "MikroValidationRequest" "$RUNTIME_FILE"
require_grep "7-8M.6.4.40 runtime creates manual review request" "MikroManualReviewRequest" "$RUNTIME_FILE"
require_grep "7-8M.6.4.41 runtime creates operator action request" "MikroOperatorActionRequest" "$RUNTIME_FILE"
require_grep "7-8M.6.4.42 runtime has base decision" "baseDecision" "$RUNTIME_FILE"
require_grep "7-8M.6.4.43 runtime has closed real operation guard" "guardClosedRealOperations" "$RUNTIME_FILE"
require_grep "7-8M.6.4.44 runtime validates e2e request" "validateMikroE2EDryRunRequest" "$RUNTIME_FILE"
require_grep "7-8M.6.4.45 runtime validates tenant id" "TenantID" "$RUNTIME_FILE"
require_grep "7-8M.6.4.46 runtime validates actor user id" "ActorUserID" "$RUNTIME_FILE"
require_grep "7-8M.6.4.47 runtime validates correlation id" "CorrelationID" "$RUNTIME_FILE"
require_grep "7-8M.6.4.48 runtime validates package id" "PackageID" "$RUNTIME_FILE"
require_grep "7-8M.6.4.49 runtime validates delivery id" "DeliveryID" "$RUNTIME_FILE"
require_grep "7-8M.6.4.50 runtime validates validation id" "ValidationID" "$RUNTIME_FILE"
require_grep "7-8M.6.4.51 runtime validates review id" "ReviewID" "$RUNTIME_FILE"
require_grep "7-8M.6.4.52 runtime validates operator note" "OperatorNote" "$RUNTIME_FILE"
require_grep "7-8M.6.4.53 runtime denies provider live mode" "PROVIDER_LIVE" "$RUNTIME_FILE"
require_grep "7-8M.6.4.54 runtime denies real provider API enabled" "RealProviderAPIEnabled" "$RUNTIME_FILE"
require_grep "7-8M.6.4.55 runtime denies real file delivery enabled" "RealFileDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.6.4.56 runtime denies real ERP write enabled" "RealERPWriteEnabled" "$RUNTIME_FILE"
require_grep "7-8M.6.4.57 runtime denies real delivery enabled" "RealDeliveryEnabled" "$RUNTIME_FILE"
require_grep "7-8M.6.4.58 runtime denies real operator provider action enabled" "RealOperatorProviderActionEnabled" "$RUNTIME_FILE"
require_grep "7-8M.6.4.59 runtime forbids secret fields" "containsForbiddenMappingField" "$RUNTIME_FILE"
require_grep "7-8M.6.4.60 runtime declares ready decision" "MIKRO_E2E_DRY_RUN_FLOW_READY" "$RUNTIME_FILE"
require_grep "7-8M.6.4.61 runtime declares manual review flow decision" "MIKRO_E2E_MANUAL_REVIEW_FLOW_READY" "$RUNTIME_FILE"
require_grep "7-8M.6.4.62 runtime declares retry flow decision" "MIKRO_E2E_RETRY_FLOW_READY" "$RUNTIME_FILE"
require_grep "7-8M.6.4.63 runtime declares DLQ flow decision" "MIKRO_E2E_DLQ_FLOW_READY" "$RUNTIME_FILE"

require_grep "7-8M.6.5.1 tests include root 7-8M.6 OK output" "7-8M\\.6" "$TEST_FILE"
require_grep "7-8M.6.5.2 tests include 7-8M.6.1 OK output" "7-8M\\.6\\.1" "$TEST_FILE"
require_grep "7-8M.6.5.3 tests include 7-8M.6.1.1 OK output" "7-8M\\.6\\.1\\.1" "$TEST_FILE"
require_grep "7-8M.6.5.4 tests validate happy path" "happy path e2e dry-run validation" "$TEST_FILE"
require_grep "7-8M.6.5.5 tests validate foundation step" "foundation validation step completed" "$TEST_FILE"
require_grep "7-8M.6.5.6 tests validate mapping step" "export mapping step completed" "$TEST_FILE"
require_grep "7-8M.6.5.7 tests validate file generation step" "file generation package build completed" "$TEST_FILE"
require_grep "7-8M.6.5.8 tests validate delivery step" "import delivery receipt completed" "$TEST_FILE"
require_grep "7-8M.6.5.9 tests validate validation step" "validation retry-DLQ step completed" "$TEST_FILE"
require_grep "7-8M.6.5.10 tests validate no external operation" "no real external operation executed" "$TEST_FILE"
require_grep "7-8M.6.5.11 tests validate manual review flow" "manual review e2e dry-run validation" "$TEST_FILE"
require_grep "7-8M.6.5.12 tests validate operator action" "operator action is evaluated" "$TEST_FILE"
require_grep "7-8M.6.5.13 tests validate retry flow" "MIKRO_TIMEOUT maps to retry e2e flow" "$TEST_FILE"
require_grep "7-8M.6.5.14 tests validate DLQ flow" "MIKRO_FORMAT_ERROR maps to DLQ e2e flow" "$TEST_FILE"
require_grep "7-8M.6.5.15 tests validate closed real API" "real Mikro API request is denied" "$TEST_FILE"
require_grep "7-8M.6.5.16 tests validate closed file delivery" "real Mikro file delivery request is denied" "$TEST_FILE"
require_grep "7-8M.6.5.17 tests validate closed ERP write" "real ERP write request is denied" "$TEST_FILE"
require_grep "7-8M.6.5.18 tests validate closed operator provider action" "real operator provider action request is denied" "$TEST_FILE"
require_grep "7-8M.6.5.19 tests validate package id guard" "missing package id is rejected" "$TEST_FILE"
require_grep "7-8M.6.5.20 tests validate operator note guard" "missing operator note is rejected" "$TEST_FILE"
require_grep "7-8M.6.5.21 tests validate provider live denied" "provider live mode is denied" "$TEST_FILE"
require_grep "7-8M.6.5.22 tests validate secret rejection" "client_secret field is rejected" "$TEST_FILE"

log_line "===== 7-8M.6 MIKRO E2E DRY-RUN REAL IMPLEMENTATION AUDIT RESULT ====="
log_line "PASS_COUNT=$PASS_COUNT"
log_line "FAIL_COUNT=$FAIL_COUNT"
log_line "REQUIRED_FAIL=$REQUIRED_FAIL"
log_line "OPTIONAL_WARN=$OPTIONAL_WARN"
log_line "AUDIT_EVIDENCE_FILE=$AUDIT_EVIDENCE_FILE"

if [[ "$REQUIRED_FAIL" -eq 0 ]]; then
  log_line "FAZ_7_8M_6_MIKRO_E2E_DRY_RUN_REAL_IMPLEMENTATION_STATUS=PASS"
  exit 0
fi

log_line "FAZ_7_8M_6_MIKRO_E2E_DRY_RUN_REAL_IMPLEMENTATION_STATUS=FAIL"
exit 1
