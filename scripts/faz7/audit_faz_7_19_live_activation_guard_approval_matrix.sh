#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/commercial/liveready/live_activation_guard_approval_matrix.go"
TEST_FILE="internal/platform/commercial/liveready/live_activation_guard_approval_matrix_test.go"
CONFIG_FILE="configs/faz7/live_activation_guard_approval_matrix.json"
DOC_FILE="docs/faz7/commercial/FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-19 LIVE ACTIVATION GUARD APPROVAL MATRIX REAL IMPLEMENTATION AUDIT START ====="

require_file "7-19.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-19.6.2 test file exists" "$TEST_FILE"
require_file "7-19.6.3 config file exists" "$CONFIG_FILE"
require_file "7-19.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-19.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX"
require_grep "7-19.6.6 live activation guard mode implemented" "$RUNTIME_FILE" "LIVE_ACTIVATION_GUARD_READY_WITH_PRODUCTION_ACTIVATION_DISABLED"
require_grep "7-19.6.7 activation gate implemented" "$RUNTIME_FILE" "type LiveActivationGuardGate struct"
require_grep "7-19.6.8 approval input implemented" "$RUNTIME_FILE" "type LiveActivationApprovalInput struct"
require_grep "7-19.6.9 requirement model implemented" "$RUNTIME_FILE" "type LiveActivationRequirement struct"
require_grep "7-19.6.10 dependency seal model implemented" "$RUNTIME_FILE" "type LiveActivationDependencySeal struct"
require_grep "7-19.6.11 decision request implemented" "$RUNTIME_FILE" "type LiveActivationDecisionRequest struct"
require_grep "7-19.6.12 decision model implemented" "$RUNTIME_FILE" "type LiveActivationDecision struct"
require_grep "7-19.6.13 guard report implemented" "$RUNTIME_FILE" "type LiveActivationGuardReport struct"
require_grep "7-19.6.14 runtime implemented" "$RUNTIME_FILE" "type LiveActivationGuardRuntime struct"
require_grep "7-19.6.15 build guard report implemented" "$RUNTIME_FILE" "BuildLiveActivationGuardReport"
require_grep "7-19.6.16 evaluate live activation implemented" "$RUNTIME_FILE" "EvaluateLiveActivation"
require_grep "7-19.6.17 missing requirements implemented" "$RUNTIME_FILE" "MissingLiveActivationRequirements"
require_grep "7-19.6.18 audit event implemented" "$RUNTIME_FILE" "LiveActivationGuardAuditEvent"

require_grep "7-19.6.19 production activation lock implemented" "$RUNTIME_FILE" "PRODUCTION_ACTIVATION_LOCKED_IN_FAZ_7_19"
require_grep "7-19.6.20 no production activation policy implemented" "$RUNTIME_FILE" "NO_PRODUCTION_ACTIVATION_IN_FAZ_7_19"
require_grep "7-19.6.21 no real money policy implemented" "$RUNTIME_FILE" "NO_REAL_MONEY_MOVEMENT_IN_FAZ_7_19"
require_grep "7-19.6.22 no real billing policy implemented" "$RUNTIME_FILE" "NO_REAL_BILLING_IN_FAZ_7_19"
require_grep "7-19.6.23 no real payment policy implemented" "$RUNTIME_FILE" "NO_REAL_PAYMENT_CAPTURE_IN_FAZ_7_19"
require_grep "7-19.6.24 no real provider API policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_19"
require_grep "7-19.6.25 no real file delivery policy implemented" "$RUNTIME_FILE" "NO_REAL_FILE_DELIVERY_IN_FAZ_7_19"
require_grep "7-19.6.26 no real ERP write policy implemented" "$RUNTIME_FILE" "NO_REAL_ERP_WRITE_IN_FAZ_7_19"
require_grep "7-19.6.27 no real customer export policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_19"
require_grep "7-19.6.28 no real ledger posting policy implemented" "$RUNTIME_FILE" "NO_REAL_LEDGER_POSTING_IN_FAZ_7_19"
require_grep "7-19.6.29 no real operator action policy implemented" "$RUNTIME_FILE" "NO_REAL_OPERATOR_LIVE_ACTION_IN_FAZ_7_19"

require_grep "7-19.6.30 control plane requirement implemented" "$RUNTIME_FILE" "commercial_live_ready_control_plane_ready"
require_grep "7-19.6.31 billing requirement implemented" "$RUNTIME_FILE" "accountant_billing_live_ready"
require_grep "7-19.6.32 payment requirement implemented" "$RUNTIME_FILE" "payment_capture_live_ready"
require_grep "7-19.6.33 provider requirement implemented" "$RUNTIME_FILE" "provider_live_adapter_ready"
require_grep "7-19.6.34 export requirement implemented" "$RUNTIME_FILE" "export_live_ready"
require_grep "7-19.6.35 ERP sync requirement implemented" "$RUNTIME_FILE" "erp_sync_worker_live_ready"
require_grep "7-19.6.36 secrets requirement implemented" "$RUNTIME_FILE" "production_secrets_ready"
require_grep "7-19.6.37 legal approval requirement implemented" "$RUNTIME_FILE" "legal_approval_ready"
require_grep "7-19.6.38 finance approval requirement implemented" "$RUNTIME_FILE" "finance_approval_ready"
require_grep "7-19.6.39 security approval requirement implemented" "$RUNTIME_FILE" "security_approval_ready"
require_grep "7-19.6.40 operator approval requirement implemented" "$RUNTIME_FILE" "operator_approval_ready"
require_grep "7-19.6.41 rollback requirement implemented" "$RUNTIME_FILE" "rollback_ready"
require_grep "7-19.6.42 observability requirement implemented" "$RUNTIME_FILE" "observability_ready"
require_grep "7-19.6.43 incident response requirement implemented" "$RUNTIME_FILE" "incident_response_ready"
require_grep "7-19.6.44 tenant isolation requirement implemented" "$RUNTIME_FILE" "tenant_isolation_ready"
require_grep "7-19.6.45 backup restore requirement implemented" "$RUNTIME_FILE" "backup_restore_ready"
require_grep "7-19.6.46 rate limit requirement implemented" "$RUNTIME_FILE" "rate_limit_ready"
require_grep "7-19.6.47 audit trail requirement implemented" "$RUNTIME_FILE" "audit_trail_ready"
require_grep "7-19.6.48 customer consent requirement implemented" "$RUNTIME_FILE" "customer_data_consent_ready"

require_grep "7-19.6.49 dependency seal 7-13 implemented" "$RUNTIME_FILE" "FAZ_7_13_COMMERCIAL_LIVE_READY_CONTROL_PLANE"
require_grep "7-19.6.50 dependency seal 7-14 implemented" "$RUNTIME_FILE" "FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME"
require_grep "7-19.6.51 dependency seal 7-15 implemented" "$RUNTIME_FILE" "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME"
require_grep "7-19.6.52 dependency seal 7-16 implemented" "$RUNTIME_FILE" "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS"
require_grep "7-19.6.53 dependency seal 7-17 implemented" "$RUNTIME_FILE" "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE"
require_grep "7-19.6.54 dependency seal 7-18 implemented" "$RUNTIME_FILE" "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME"

require_grep "7-19.6.55 production activation blocker implemented" "$RUNTIME_FILE" "RequestProductionActivation"
require_grep "7-19.6.56 real money blocker implemented" "$RUNTIME_FILE" "RequestRealMoneyMovement"
require_grep "7-19.6.57 real billing blocker implemented" "$RUNTIME_FILE" "RequestRealBilling"
require_grep "7-19.6.58 real payment blocker implemented" "$RUNTIME_FILE" "RequestRealPaymentCapture"
require_grep "7-19.6.59 real provider API blocker implemented" "$RUNTIME_FILE" "RequestRealProviderAPI"
require_grep "7-19.6.60 real file delivery blocker implemented" "$RUNTIME_FILE" "RequestRealFileDelivery"
require_grep "7-19.6.61 real ERP write blocker implemented" "$RUNTIME_FILE" "RequestRealERPWrite"
require_grep "7-19.6.62 real customer export blocker implemented" "$RUNTIME_FILE" "RequestRealCustomerDataExport"
require_grep "7-19.6.63 real ledger posting blocker implemented" "$RUNTIME_FILE" "RequestRealLedgerPosting"
require_grep "7-19.6.64 real operator live action blocker implemented" "$RUNTIME_FILE" "RequestRealOperatorLiveAction"

require_grep "7-19.6.65 armed but locked decision implemented" "$RUNTIME_FILE" "LIVE_ACTIVATION_ARMED_BUT_LOCKED"
require_grep "7-19.6.66 next module 7-20 implemented" "$RUNTIME_FILE" "FAZ_7_20_COMMERCIAL_MASTER_CLOSURE"

require_grep "7-19.6.67 guard report test exists" "$TEST_FILE" "TestSevenNineteenBuildLiveActivationGuardReport"
require_grep "7-19.6.68 missing requirements test exists" "$TEST_FILE" "TestSevenNineteenMissingLiveActivationRequirements"
require_grep "7-19.6.69 missing decision test exists" "$TEST_FILE" "TestSevenNineteenEvaluateActivationBlockedWhenMissing"
require_grep "7-19.6.70 armed locked decision test exists" "$TEST_FILE" "TestSevenNineteenEvaluateActivationArmedButStillLocked"
require_grep "7-19.6.71 invalid decision request test exists" "$TEST_FILE" "TestSevenNineteenRejectInvalidDecisionRequest"
require_grep "7-19.6.72 real blocker test exists" "$TEST_FILE" "TestSevenNineteenRealLiveOperationBlockers"
require_grep "7-19.6.73 opened gate reject test exists" "$TEST_FILE" "TestSevenNineteenGateRejectsOpenedActivation"
require_grep "7-19.6.74 audit trail test exists" "$TEST_FILE" "TestSevenNineteenAuditTrail"

require_grep "7-19.6.75 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX\""
require_grep "7-19.6.76 config mode exists" "$CONFIG_FILE" "\"mode\": \"LIVE_ACTIVATION_GUARD_READY_WITH_PRODUCTION_ACTIVATION_DISABLED\""
require_grep "7-19.6.77 config depends on 7-13 PASS" "$CONFIG_FILE" "\"faz_7_13_commercial_live_ready_control_plane_final_status\": \"PASS\""
require_grep "7-19.6.78 config depends on 7-18 PASS" "$CONFIG_FILE" "\"faz_7_18_erp_sync_worker_live_ready_runtime_final_status\": \"PASS\""
require_grep "7-19.6.79 config production activation false" "$CONFIG_FILE" "\"production_activation_allowed\": false"
require_grep "7-19.6.80 config real money false" "$CONFIG_FILE" "\"real_money_movement_allowed\": false"
require_grep "7-19.6.81 config real provider API false" "$CONFIG_FILE" "\"real_provider_api_call_allowed\": false"
require_grep "7-19.6.82 config real ERP write false" "$CONFIG_FILE" "\"real_erp_write_allowed\": false"
require_grep "7-19.6.83 config real customer export false" "$CONFIG_FILE" "\"real_customer_data_export_allowed\": false"
require_grep "7-19.6.84 config next module 7-20 exists" "$CONFIG_FILE" "\"next_module\": \"FAZ_7_20_COMMERCIAL_MASTER_CLOSURE\""

require_grep "7-19.6.85 documentation says live activation is not this phase" "$DOC_FILE" "Bu faz live activation değildir"
require_grep "7-19.6.86 documentation live activation requirements exist" "$DOC_FILE" "Live activation requirements"
require_grep "7-19.6.87 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-19.6.88 runtime does not default production activation true" "$RUNTIME_FILE" "ProductionActivationAllowed:   true"
require_not_grep "7-19.6.89 runtime does not default real money true" "$RUNTIME_FILE" "RealMoneyMovementAllowed:      true"
require_not_grep "7-19.6.90 runtime does not default real billing true" "$RUNTIME_FILE" "RealBillingAllowed:            true"
require_not_grep "7-19.6.91 runtime does not default real payment true" "$RUNTIME_FILE" "RealPaymentCaptureAllowed:     true"
require_not_grep "7-19.6.92 runtime does not default real provider API true" "$RUNTIME_FILE" "RealProviderAPICallAllowed:    true"
require_not_grep "7-19.6.93 runtime does not default real file delivery true" "$RUNTIME_FILE" "RealFileDeliveryAllowed:       true"
require_not_grep "7-19.6.94 runtime does not default real ERP write true" "$RUNTIME_FILE" "RealERPWriteAllowed:           true"
require_not_grep "7-19.6.95 runtime does not default real customer export true" "$RUNTIME_FILE" "RealCustomerDataExportAllowed: true"
require_not_grep "7-19.6.96 decision does not allow activation" "$RUNTIME_FILE" "Allowed:                       true"

if go test ./internal/platform/commercial/liveready; then
  ok "7-19.6.97 go test verification PASS"
else
  fail "7-19.6.97 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-19 LIVE ACTIVATION GUARD APPROVAL MATRIX REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
