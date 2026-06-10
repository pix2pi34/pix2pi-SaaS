#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/commercial/liveready/commercial_master_closure.go"
TEST_FILE="internal/platform/commercial/liveready/commercial_master_closure_test.go"
CONFIG_FILE="configs/faz7/commercial_master_closure.json"
DOC_FILE="docs/faz7/commercial/FAZ_7_20_COMMERCIAL_MASTER_CLOSURE.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_20_COMMERCIAL_MASTER_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-20 COMMERCIAL MASTER CLOSURE REAL IMPLEMENTATION AUDIT START ====="

require_file "7-20.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-20.6.2 test file exists" "$TEST_FILE"
require_file "7-20.6.3 config file exists" "$CONFIG_FILE"
require_file "7-20.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-20.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_20_COMMERCIAL_MASTER_CLOSURE"
require_grep "7-20.6.6 commercial master closure mode implemented" "$RUNTIME_FILE" "COMMERCIAL_MASTER_CLOSURE_WITH_PRODUCTION_ACTIVATION_DISABLED"
require_grep "7-20.6.7 commercial master gate implemented" "$RUNTIME_FILE" "type CommercialMasterClosureGate struct"
require_grep "7-20.6.8 dependency seal model implemented" "$RUNTIME_FILE" "type CommercialMasterDependencySeal struct"
require_grep "7-20.6.9 open live item model implemented" "$RUNTIME_FILE" "type CommercialMasterOpenItem struct"
require_grep "7-20.6.10 commercial master report implemented" "$RUNTIME_FILE" "type CommercialMasterClosureReport struct"
require_grep "7-20.6.11 commercial master decision implemented" "$RUNTIME_FILE" "type CommercialMasterClosureDecision struct"
require_grep "7-20.6.12 runtime implemented" "$RUNTIME_FILE" "type CommercialMasterClosureRuntime struct"
require_grep "7-20.6.13 build master report implemented" "$RUNTIME_FILE" "BuildCommercialMasterClosureReport"
require_grep "7-20.6.14 finalize master closure implemented" "$RUNTIME_FILE" "FinalizeCommercialMasterClosure"
require_grep "7-20.6.15 dependency validation implemented" "$RUNTIME_FILE" "validateCommercialMasterDependencySeals"
require_grep "7-20.6.16 audit event implemented" "$RUNTIME_FILE" "CommercialMasterClosureAuditEvent"

require_grep "7-20.6.17 production activation lock implemented" "$RUNTIME_FILE" "PRODUCTION_ACTIVATION_LOCKED_AFTER_FAZ_7"
require_grep "7-20.6.18 no production activation policy implemented" "$RUNTIME_FILE" "NO_PRODUCTION_ACTIVATION_IN_FAZ_7_20"
require_grep "7-20.6.19 no real money policy implemented" "$RUNTIME_FILE" "NO_REAL_MONEY_MOVEMENT_IN_FAZ_7_20"
require_grep "7-20.6.20 no real billing policy implemented" "$RUNTIME_FILE" "NO_REAL_BILLING_IN_FAZ_7_20"
require_grep "7-20.6.21 no real payment policy implemented" "$RUNTIME_FILE" "NO_REAL_PAYMENT_CAPTURE_IN_FAZ_7_20"
require_grep "7-20.6.22 no real provider API policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_20"
require_grep "7-20.6.23 no real file delivery policy implemented" "$RUNTIME_FILE" "NO_REAL_FILE_DELIVERY_IN_FAZ_7_20"
require_grep "7-20.6.24 no real ERP write policy implemented" "$RUNTIME_FILE" "NO_REAL_ERP_WRITE_IN_FAZ_7_20"
require_grep "7-20.6.25 no real customer export policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_20"
require_grep "7-20.6.26 no real ledger posting policy implemented" "$RUNTIME_FILE" "NO_REAL_LEDGER_POSTING_IN_FAZ_7_20"
require_grep "7-20.6.27 no real operator action policy implemented" "$RUNTIME_FILE" "NO_REAL_OPERATOR_LIVE_ACTION_IN_FAZ_7_20"

require_grep "7-20.6.28 payment module dependency implemented" "$RUNTIME_FILE" "FAZ_7_5P_PAYMENT_PROVIDER_ADAPTER_MODULE"
require_grep "7-20.6.29 marketplace catalog dependency implemented" "$RUNTIME_FILE" "FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION"
require_grep "7-20.6.30 integration family dependency implemented" "$RUNTIME_FILE" "FAZ_7_8_INTEGRATION_FAMILY_MASTER_CLOSURE"
require_grep "7-20.6.31 accountant portal dependency implemented" "$RUNTIME_FILE" "FAZ_7_ACCOUNTANT_PORTAL_FAMILY"
require_grep "7-20.6.32 commercial control dependency implemented" "$RUNTIME_FILE" "FAZ_7_13_COMMERCIAL_LIVE_READY_CONTROL_PLANE"
require_grep "7-20.6.33 billing dependency implemented" "$RUNTIME_FILE" "FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME"
require_grep "7-20.6.34 payment capture dependency implemented" "$RUNTIME_FILE" "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME"
require_grep "7-20.6.35 provider dependency implemented" "$RUNTIME_FILE" "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS"
require_grep "7-20.6.36 export dependency implemented" "$RUNTIME_FILE" "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE"
require_grep "7-20.6.37 ERP sync dependency implemented" "$RUNTIME_FILE" "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME"
require_grep "7-20.6.38 activation guard dependency implemented" "$RUNTIME_FILE" "FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX"

require_grep "7-20.6.39 production activation live handoff implemented" "$RUNTIME_FILE" "PRODUCTION_ACTIVATION"
require_grep "7-20.6.40 real money live handoff implemented" "$RUNTIME_FILE" "REAL_MONEY_MOVEMENT"
require_grep "7-20.6.41 real billing live handoff implemented" "$RUNTIME_FILE" "REAL_BILLING"
require_grep "7-20.6.42 real payment live handoff implemented" "$RUNTIME_FILE" "REAL_PAYMENT_CAPTURE"
require_grep "7-20.6.43 real provider API live handoff implemented" "$RUNTIME_FILE" "REAL_PROVIDER_API"
require_grep "7-20.6.44 real file delivery live handoff implemented" "$RUNTIME_FILE" "REAL_FILE_DELIVERY"
require_grep "7-20.6.45 real ERP write live handoff implemented" "$RUNTIME_FILE" "REAL_ERP_WRITE"
require_grep "7-20.6.46 real customer export live handoff implemented" "$RUNTIME_FILE" "REAL_CUSTOMER_DATA_EXPORT"
require_grep "7-20.6.47 real ledger posting live handoff implemented" "$RUNTIME_FILE" "REAL_LEDGER_POSTING"
require_grep "7-20.6.48 real operator live action handoff implemented" "$RUNTIME_FILE" "REAL_OPERATOR_LIVE_ACTION"

require_grep "7-20.6.49 production activation blocker implemented" "$RUNTIME_FILE" "RequestProductionActivation"
require_grep "7-20.6.50 real money blocker implemented" "$RUNTIME_FILE" "RequestRealMoneyMovement"
require_grep "7-20.6.51 real billing blocker implemented" "$RUNTIME_FILE" "RequestRealBilling"
require_grep "7-20.6.52 real payment blocker implemented" "$RUNTIME_FILE" "RequestRealPaymentCapture"
require_grep "7-20.6.53 real provider API blocker implemented" "$RUNTIME_FILE" "RequestRealProviderAPI"
require_grep "7-20.6.54 real file delivery blocker implemented" "$RUNTIME_FILE" "RequestRealFileDelivery"
require_grep "7-20.6.55 real ERP write blocker implemented" "$RUNTIME_FILE" "RequestRealERPWrite"
require_grep "7-20.6.56 real customer export blocker implemented" "$RUNTIME_FILE" "RequestRealCustomerDataExport"
require_grep "7-20.6.57 real ledger posting blocker implemented" "$RUNTIME_FILE" "RequestRealLedgerPosting"
require_grep "7-20.6.58 real operator action blocker implemented" "$RUNTIME_FILE" "RequestRealOperatorLiveAction"

require_grep "7-20.6.59 provider dry-run set implemented" "$RUNTIME_FILE" "PARASUT_LOGO_MIKRO_ZIRVE"
require_grep "7-20.6.60 handoff ready status implemented" "$RUNTIME_FILE" "READY_FOR_NEXT_PHASE_PLANNING"

require_grep "7-20.6.61 master report test exists" "$TEST_FILE" "TestSevenTwentyBuildCommercialMasterClosureReport"
require_grep "7-20.6.62 finalize test exists" "$TEST_FILE" "TestSevenTwentyFinalizeCommercialMasterClosure"
require_grep "7-20.6.63 dependency seal test exists" "$TEST_FILE" "TestSevenTwentyDependencySealsArePassAndSealed"
require_grep "7-20.6.64 open live items test exists" "$TEST_FILE" "TestSevenTwentyOpenLiveItemsRemainClosed"
require_grep "7-20.6.65 real blocker test exists" "$TEST_FILE" "TestSevenTwentyRealOperationBlockers"
require_grep "7-20.6.66 opened gate reject test exists" "$TEST_FILE" "TestSevenTwentyGateRejectsOpenedRealOperation"
require_grep "7-20.6.67 audit trail test exists" "$TEST_FILE" "TestSevenTwentyAuditTrail"

require_grep "7-20.6.68 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_20_COMMERCIAL_MASTER_CLOSURE\""
require_grep "7-20.6.69 config mode exists" "$CONFIG_FILE" "\"mode\": \"COMMERCIAL_MASTER_CLOSURE_WITH_PRODUCTION_ACTIVATION_DISABLED\""
require_grep "7-20.6.70 config depends on 7-13 PASS" "$CONFIG_FILE" "\"faz_7_13_commercial_live_ready_control_plane_final_status\": \"PASS\""
require_grep "7-20.6.71 config depends on 7-19 PASS" "$CONFIG_FILE" "\"faz_7_19_live_activation_guard_approval_matrix_final_status\": \"PASS\""
require_grep "7-20.6.72 config production activation false" "$CONFIG_FILE" "\"production_activation_allowed\": false"
require_grep "7-20.6.73 config real money false" "$CONFIG_FILE" "\"real_money_movement_allowed\": false"
require_grep "7-20.6.74 config real billing false" "$CONFIG_FILE" "\"real_billing_allowed\": false"
require_grep "7-20.6.75 config real payment false" "$CONFIG_FILE" "\"real_payment_capture_allowed\": false"
require_grep "7-20.6.76 config real provider API false" "$CONFIG_FILE" "\"real_provider_api_call_allowed\": false"
require_grep "7-20.6.77 config real ERP write false" "$CONFIG_FILE" "\"real_erp_write_allowed\": false"
require_grep "7-20.6.78 config final status PASS" "$CONFIG_FILE" "\"faz_7_commercial_final_status\": \"PASS\""
require_grep "7-20.6.79 config seal status SEALED" "$CONFIG_FILE" "\"faz_7_commercial_seal_status\": \"SEALED\""
require_grep "7-20.6.80 config next phase planning ready" "$CONFIG_FILE" "\"next_phase_planning_status\": \"READY_FOR_NEXT_PHASE_PLANNING\""

require_grep "7-20.6.81 documentation says production activation is not this phase" "$DOC_FILE" "Bu faz production activation değildir"
require_grep "7-20.6.82 documentation open live handoff exists" "$DOC_FILE" "Açık kalan live handoff işleri"
require_grep "7-20.6.83 documentation final decision exists" "$DOC_FILE" "Final karar"
require_grep "7-20.6.84 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-20.6.85 runtime does not default production activation true" "$RUNTIME_FILE" "ProductionActivationAllowed:   true"
require_not_grep "7-20.6.86 runtime does not default real money true" "$RUNTIME_FILE" "RealMoneyMovementAllowed:      true"
require_not_grep "7-20.6.87 runtime does not default real billing true" "$RUNTIME_FILE" "RealBillingAllowed:            true"
require_not_grep "7-20.6.88 runtime does not default real payment true" "$RUNTIME_FILE" "RealPaymentCaptureAllowed:     true"
require_not_grep "7-20.6.89 runtime does not default real provider API true" "$RUNTIME_FILE" "RealProviderAPICallAllowed:    true"
require_not_grep "7-20.6.90 runtime does not default real file delivery true" "$RUNTIME_FILE" "RealFileDeliveryAllowed:       true"
require_not_grep "7-20.6.91 runtime does not default real ERP write true" "$RUNTIME_FILE" "RealERPWriteAllowed:           true"
require_not_grep "7-20.6.92 runtime does not default real customer export true" "$RUNTIME_FILE" "RealCustomerDataExportAllowed: true"
require_not_grep "7-20.6.93 runtime does not default real ledger true" "$RUNTIME_FILE" "RealLedgerPostingAllowed:      true"

if go test ./internal/platform/commercial/liveready; then
  ok "7-20.6.94 go test verification PASS"
else
  fail "7-20.6.94 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-20 COMMERCIAL MASTER CLOSURE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_20_COMMERCIAL_MASTER_CLOSURE_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
