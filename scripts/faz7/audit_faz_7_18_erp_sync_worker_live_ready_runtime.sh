#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/commercial/liveready/erp_sync_worker_live_ready_runtime.go"
TEST_FILE="internal/platform/commercial/liveready/erp_sync_worker_live_ready_runtime_test.go"
CONFIG_FILE="configs/faz7/erp_sync_worker_live_ready_runtime.json"
DOC_FILE="docs/faz7/commercial/FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

mkdir -p "$(dirname "$EVIDENCE_FILE")"
exec > >(tee "$EVIDENCE_FILE") 2>&1

ok() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 / FAIL ❌"
}

require_file() {
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

require_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

require_not_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && ! grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 7-18 ERP SYNC WORKER LIVE-READY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

require_file "7-18.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-18.6.2 test file exists" "$TEST_FILE"
require_file "7-18.6.3 config file exists" "$CONFIG_FILE"
require_file "7-18.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-18.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME"
require_grep "7-18.6.6 ERP sync live-ready mode implemented" "$RUNTIME_FILE" "ERP_SYNC_WORKER_LIVE_READY_WITH_REAL_ERP_WRITE_DISABLED"
require_grep "7-18.6.7 ERP sync gate implemented" "$RUNTIME_FILE" "type ERPSyncWorkerLiveReadyGate struct"
require_grep "7-18.6.8 ERP sync input implemented" "$RUNTIME_FILE" "type ERPSyncWorkerLiveReadyInput struct"
require_grep "7-18.6.9 ERP sync requirement model implemented" "$RUNTIME_FILE" "type ERPSyncWorkerRequirement struct"
require_grep "7-18.6.10 ERP sync plan request implemented" "$RUNTIME_FILE" "type ERPSyncPlanRequest struct"
require_grep "7-18.6.11 ERP sync operation step implemented" "$RUNTIME_FILE" "type ERPSyncOperationStep struct"
require_grep "7-18.6.12 ERP sync worker plan implemented" "$RUNTIME_FILE" "type ERPSyncWorkerPlan struct"
require_grep "7-18.6.13 ERP sync report implemented" "$RUNTIME_FILE" "type ERPSyncWorkerLiveReadyReport struct"
require_grep "7-18.6.14 runtime implemented" "$RUNTIME_FILE" "type ERPSyncWorkerLiveReadyRuntime struct"
require_grep "7-18.6.15 build ERP sync report implemented" "$RUNTIME_FILE" "BuildERPSyncWorkerLiveReadyReport"
require_grep "7-18.6.16 build ERP sync plan implemented" "$RUNTIME_FILE" "BuildERPSyncPlan"
require_grep "7-18.6.17 missing ERP sync requirements implemented" "$RUNTIME_FILE" "MissingERPSyncWorkerRequirements"
require_grep "7-18.6.18 audit event implemented" "$RUNTIME_FILE" "ERPSyncWorkerAuditEvent"

require_grep "7-18.6.19 production ERP sync lock implemented" "$RUNTIME_FILE" "PRODUCTION_ERP_SYNC_LOCKED_IN_FAZ_7_18"
require_grep "7-18.6.20 no real ERP write policy implemented" "$RUNTIME_FILE" "NO_REAL_ERP_WRITE_IN_FAZ_7_18"
require_grep "7-18.6.21 no real ledger posting policy implemented" "$RUNTIME_FILE" "NO_REAL_LEDGER_POSTING_IN_FAZ_7_18"
require_grep "7-18.6.22 no real provider API policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_18"
require_grep "7-18.6.23 no real customer payload policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_PAYLOAD_IN_FAZ_7_18"
require_grep "7-18.6.24 no real reconciliation policy implemented" "$RUNTIME_FILE" "NO_REAL_RECONCILIATION_COMMIT_IN_FAZ_7_18"
require_grep "7-18.6.25 no real operator action policy implemented" "$RUNTIME_FILE" "NO_REAL_OPERATOR_ERP_SYNC_ACTION_IN_FAZ_7_18"

require_grep "7-18.6.26 export live-ready requirement implemented" "$RUNTIME_FILE" "export_live_ready"
require_grep "7-18.6.27 provider adapter requirement implemented" "$RUNTIME_FILE" "provider_live_adapter_ready"
require_grep "7-18.6.28 ERP write contract requirement implemented" "$RUNTIME_FILE" "erp_write_contract_ready"
require_grep "7-18.6.29 ERP object mapping requirement implemented" "$RUNTIME_FILE" "erp_object_mapping_ready"
require_grep "7-18.6.30 tenant boundary requirement implemented" "$RUNTIME_FILE" "tenant_boundary_ready"
require_grep "7-18.6.31 event mapping requirement implemented" "$RUNTIME_FILE" "event_mapping_ready"
require_grep "7-18.6.32 idempotency requirement implemented" "$RUNTIME_FILE" "erp_sync_idempotency_ready"
require_grep "7-18.6.33 retry DLQ requirement implemented" "$RUNTIME_FILE" "erp_sync_retry_dlq_ready"
require_grep "7-18.6.34 reconciliation requirement implemented" "$RUNTIME_FILE" "erp_reconciliation_ready"
require_grep "7-18.6.35 ledger posting guard requirement implemented" "$RUNTIME_FILE" "ledger_posting_guard_ready"
require_grep "7-18.6.36 audit requirement implemented" "$RUNTIME_FILE" "erp_sync_audit_ready"
require_grep "7-18.6.37 rollback requirement implemented" "$RUNTIME_FILE" "erp_sync_rollback_ready"
require_grep "7-18.6.38 legal approval requirement implemented" "$RUNTIME_FILE" "legal_approval_gate_ready"
require_grep "7-18.6.39 finance approval requirement implemented" "$RUNTIME_FILE" "finance_approval_gate_ready"
require_grep "7-18.6.40 security gate requirement implemented" "$RUNTIME_FILE" "security_gate_ready"
require_grep "7-18.6.41 observability requirement implemented" "$RUNTIME_FILE" "erp_sync_observability_ready"

require_grep "7-18.6.42 Paraşüt provider implemented" "$RUNTIME_FILE" "PARASUT"
require_grep "7-18.6.43 Logo provider implemented" "$RUNTIME_FILE" "LOGO"
require_grep "7-18.6.44 Mikro provider implemented" "$RUNTIME_FILE" "MIKRO"
require_grep "7-18.6.45 Zirve provider implemented" "$RUNTIME_FILE" "ZIRVE"
require_grep "7-18.6.46 invoice object implemented" "$RUNTIME_FILE" "INVOICE"
require_grep "7-18.6.47 customer object implemented" "$RUNTIME_FILE" "CUSTOMER"
require_grep "7-18.6.48 ledger entry object implemented" "$RUNTIME_FILE" "LEDGER_ENTRY"
require_grep "7-18.6.49 stock item object implemented" "$RUNTIME_FILE" "STOCK_ITEM"

require_grep "7-18.6.50 real ERP write blocker implemented" "$RUNTIME_FILE" "RequestRealERPWrite"
require_grep "7-18.6.51 real ledger posting blocker implemented" "$RUNTIME_FILE" "RequestRealLedgerPosting"
require_grep "7-18.6.52 real provider API blocker implemented" "$RUNTIME_FILE" "RequestRealProviderAPI"
require_grep "7-18.6.53 real customer payload blocker implemented" "$RUNTIME_FILE" "RequestRealCustomerPayload"
require_grep "7-18.6.54 real reconciliation commit blocker implemented" "$RUNTIME_FILE" "RequestRealReconciliationCommit"
require_grep "7-18.6.55 real operator ERP sync action blocker implemented" "$RUNTIME_FILE" "RequestRealOperatorERPSyncAction"

require_grep "7-18.6.56 idempotency key implemented" "$RUNTIME_FILE" "IdempotencyKey"
require_grep "7-18.6.57 mapping status implemented" "$RUNTIME_FILE" "MappingStatus"
require_grep "7-18.6.58 retry policy status implemented" "$RUNTIME_FILE" "RetryPolicyStatus"
require_grep "7-18.6.59 DLQ policy status implemented" "$RUNTIME_FILE" "DLQPolicyStatus"
require_grep "7-18.6.60 reconciliation status implemented" "$RUNTIME_FILE" "ReconciliationStatus"
require_grep "7-18.6.61 synthetic operation steps implemented" "$RUNTIME_FILE" "buildSyntheticERPSyncSteps"
require_grep "7-18.6.62 next module 7-19 implemented" "$RUNTIME_FILE" "FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX"

require_grep "7-18.6.63 ERP sync report test exists" "$TEST_FILE" "TestSevenEighteenBuildERPSyncWorkerLiveReadyReport"
require_grep "7-18.6.64 missing requirements test exists" "$TEST_FILE" "TestSevenEighteenMissingERPSyncWorkerRequirements"
require_grep "7-18.6.65 ERP sync plan test exists" "$TEST_FILE" "TestSevenEighteenBuildERPSyncPlanNoRealWrite"
require_grep "7-18.6.66 idempotency test exists" "$TEST_FILE" "TestSevenEighteenERPSyncPlanIdempotency"
require_grep "7-18.6.67 invalid plan test exists" "$TEST_FILE" "TestSevenEighteenRejectInvalidERPSyncPlan"
require_grep "7-18.6.68 real blocker test exists" "$TEST_FILE" "TestSevenEighteenRealERPSyncOperationBlockers"
require_grep "7-18.6.69 opened gate reject test exists" "$TEST_FILE" "TestSevenEighteenGateRejectsOpenedRealERPSync"
require_grep "7-18.6.70 audit trail test exists" "$TEST_FILE" "TestSevenEighteenAuditTrail"

require_grep "7-18.6.71 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME\""
require_grep "7-18.6.72 config mode exists" "$CONFIG_FILE" "\"mode\": \"ERP_SYNC_WORKER_LIVE_READY_WITH_REAL_ERP_WRITE_DISABLED\""
require_grep "7-18.6.73 config depends on 7-17 PASS" "$CONFIG_FILE" "\"faz_7_17_export_live_ready_pipeline_final_status\": \"PASS\""
require_grep "7-18.6.74 config production ERP sync false" "$CONFIG_FILE" "\"production_erp_sync_allowed\": false"
require_grep "7-18.6.75 config real ERP write false" "$CONFIG_FILE" "\"real_erp_write_allowed\": false"
require_grep "7-18.6.76 config real ledger posting false" "$CONFIG_FILE" "\"real_ledger_posting_allowed\": false"
require_grep "7-18.6.77 config real provider API false" "$CONFIG_FILE" "\"real_provider_api_call_allowed\": false"
require_grep "7-18.6.78 config real customer payload false" "$CONFIG_FILE" "\"real_customer_payload_allowed\": false"
require_grep "7-18.6.79 config next module 7-19 exists" "$CONFIG_FILE" "\"next_module\": \"FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX\""

require_grep "7-18.6.80 documentation says live ERP sync is not this phase" "$DOC_FILE" "Bu faz live ERP sync değildir"
require_grep "7-18.6.81 documentation live-ready requirements exist" "$DOC_FILE" "Live-ready requirements"
require_grep "7-18.6.82 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-18.6.83 runtime does not default production ERP sync true" "$RUNTIME_FILE" "ProductionERPSyncAllowed:        true"
require_not_grep "7-18.6.84 runtime does not default real ERP write true" "$RUNTIME_FILE" "RealERPWriteAllowed:             true"
require_not_grep "7-18.6.85 runtime does not default real ledger true" "$RUNTIME_FILE" "RealLedgerPostingAllowed:        true"
require_not_grep "7-18.6.86 runtime does not default real provider API true" "$RUNTIME_FILE" "RealProviderAPICallAllowed:      true"
require_not_grep "7-18.6.87 runtime does not default real customer payload true" "$RUNTIME_FILE" "RealCustomerPayloadAllowed:      true"
require_not_grep "7-18.6.88 ERP sync plan does not request ERP write" "$RUNTIME_FILE" "RealERPWriteRequested:             true"
require_not_grep "7-18.6.89 ERP sync plan does not request ledger posting" "$RUNTIME_FILE" "RealLedgerPostingRequested:        true"
require_not_grep "7-18.6.90 ERP sync plan does not request provider API" "$RUNTIME_FILE" "RealProviderAPICallRequested:      true"
require_not_grep "7-18.6.91 ERP sync plan does not include customer payload" "$RUNTIME_FILE" "RealCustomerPayloadIncluded:       true"

if go test ./internal/platform/commercial/liveready; then
  ok "7-18.6.92 go test verification PASS"
else
  fail "7-18.6.92 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-18 ERP SYNC WORKER LIVE-READY RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
