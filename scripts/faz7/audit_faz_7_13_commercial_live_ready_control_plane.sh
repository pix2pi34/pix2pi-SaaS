#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/commercial/liveready/commercial_live_ready_control_plane.go"
TEST_FILE="internal/platform/commercial/liveready/commercial_live_ready_control_plane_test.go"
CONFIG_FILE="configs/faz7/commercial_live_ready_control_plane.json"
DOC_FILE="docs/faz7/commercial/FAZ_7_13_COMMERCIAL_LIVE_READY_CONTROL_PLANE.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_13_COMMERCIAL_LIVE_READY_CONTROL_PLANE_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-13 COMMERCIAL LIVE-READY CONTROL PLANE REAL IMPLEMENTATION AUDIT START ====="

require_file "7-13.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-13.6.2 test file exists" "$TEST_FILE"
require_file "7-13.6.3 config file exists" "$CONFIG_FILE"
require_file "7-13.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-13.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_13_COMMERCIAL_LIVE_READY_CONTROL_PLANE"
require_grep "7-13.6.6 live-ready control plane mode implemented" "$RUNTIME_FILE" "LIVE_READY_CONTROL_PLANE_WITH_PRODUCTION_ACTIVATION_DISABLED"
require_grep "7-13.6.7 commercial live-ready gate implemented" "$RUNTIME_FILE" "type CommercialLiveReadyGate struct"
require_grep "7-13.6.8 activation input implemented" "$RUNTIME_FILE" "type CommercialLiveReadyActivationInput struct"
require_grep "7-13.6.9 activation decision implemented" "$RUNTIME_FILE" "type CommercialLiveReadyActivationDecision struct"
require_grep "7-13.6.10 live-ready report implemented" "$RUNTIME_FILE" "type CommercialLiveReadyReport struct"
require_grep "7-13.6.11 requirement model implemented" "$RUNTIME_FILE" "type CommercialLiveReadyRequirement struct"
require_grep "7-13.6.12 control plane runtime implemented" "$RUNTIME_FILE" "type CommercialLiveReadyControlPlaneRuntime struct"
require_grep "7-13.6.13 build live-ready report implemented" "$RUNTIME_FILE" "BuildLiveReadyReport"
require_grep "7-13.6.14 evaluate production activation implemented" "$RUNTIME_FILE" "EvaluateProductionActivation"
require_grep "7-13.6.15 missing requirements implemented" "$RUNTIME_FILE" "MissingCommercialLiveReadyRequirements"
require_grep "7-13.6.16 audit event implemented" "$RUNTIME_FILE" "CommercialLiveReadyAuditEvent"

require_grep "7-13.6.17 production activation lock implemented" "$RUNTIME_FILE" "PRODUCTION_ACTIVATION_LOCKED_IN_FAZ_7_13"
require_grep "7-13.6.18 provider dry-run set implemented" "$RUNTIME_FILE" "PARASUT_LOGO_MIKRO_ZIRVE"
require_grep "7-13.6.19 billing live-ready requirement implemented" "$RUNTIME_FILE" "billing_live_ready"
require_grep "7-13.6.20 payment capture requirement implemented" "$RUNTIME_FILE" "payment_capture_live_ready"
require_grep "7-13.6.21 provider live-ready requirement implemented" "$RUNTIME_FILE" "provider_live_ready"
require_grep "7-13.6.22 export live-ready requirement implemented" "$RUNTIME_FILE" "export_live_ready"
require_grep "7-13.6.23 ERP sync live-ready requirement implemented" "$RUNTIME_FILE" "erp_sync_live_ready"
require_grep "7-13.6.24 secrets ready requirement implemented" "$RUNTIME_FILE" "secrets_ready"
require_grep "7-13.6.25 legal approval requirement implemented" "$RUNTIME_FILE" "legal_approval_ready"
require_grep "7-13.6.26 finance approval requirement implemented" "$RUNTIME_FILE" "finance_approval_ready"
require_grep "7-13.6.27 security approval requirement implemented" "$RUNTIME_FILE" "security_approval_ready"
require_grep "7-13.6.28 operator approval requirement implemented" "$RUNTIME_FILE" "operator_approval_ready"
require_grep "7-13.6.29 rollback requirement implemented" "$RUNTIME_FILE" "rollback_ready"
require_grep "7-13.6.30 observability requirement implemented" "$RUNTIME_FILE" "observability_ready"
require_grep "7-13.6.31 incident response requirement implemented" "$RUNTIME_FILE" "incident_response_ready"
require_grep "7-13.6.32 tenant isolation requirement implemented" "$RUNTIME_FILE" "tenant_isolation_ready"

require_grep "7-13.6.33 no real money policy implemented" "$RUNTIME_FILE" "NO_REAL_MONEY_MOVEMENT_IN_FAZ_7_13"
require_grep "7-13.6.34 no real billing policy implemented" "$RUNTIME_FILE" "NO_REAL_BILLING_IN_FAZ_7_13"
require_grep "7-13.6.35 no real payment capture policy implemented" "$RUNTIME_FILE" "NO_REAL_PAYMENT_CAPTURE_IN_FAZ_7_13"
require_grep "7-13.6.36 no real provider API policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_13"
require_grep "7-13.6.37 no real file delivery policy implemented" "$RUNTIME_FILE" "NO_REAL_FILE_DELIVERY_IN_FAZ_7_13"
require_grep "7-13.6.38 no real ERP write policy implemented" "$RUNTIME_FILE" "NO_REAL_ERP_WRITE_IN_FAZ_7_13"
require_grep "7-13.6.39 no real customer data export policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_13"

require_grep "7-13.6.40 real billing blocker implemented" "$RUNTIME_FILE" "RequestRealBilling"
require_grep "7-13.6.41 real payment capture blocker implemented" "$RUNTIME_FILE" "RequestRealPaymentCapture"
require_grep "7-13.6.42 real provider API blocker implemented" "$RUNTIME_FILE" "RequestRealProviderAPI"
require_grep "7-13.6.43 real file delivery blocker implemented" "$RUNTIME_FILE" "RequestRealFileDelivery"
require_grep "7-13.6.44 real ERP write blocker implemented" "$RUNTIME_FILE" "RequestRealERPWrite"
require_grep "7-13.6.45 real customer data export blocker implemented" "$RUNTIME_FILE" "RequestRealCustomerDataExport"

require_grep "7-13.6.46 next module 7-14 implemented" "$RUNTIME_FILE" "FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME"
require_grep "7-13.6.47 next module 7-15 implemented" "$RUNTIME_FILE" "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME"
require_grep "7-13.6.48 next module 7-16 implemented" "$RUNTIME_FILE" "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS"
require_grep "7-13.6.49 next module 7-17 implemented" "$RUNTIME_FILE" "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE"
require_grep "7-13.6.50 next module 7-18 implemented" "$RUNTIME_FILE" "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME"
require_grep "7-13.6.51 next module 7-19 implemented" "$RUNTIME_FILE" "FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX"
require_grep "7-13.6.52 next module 7-20 implemented" "$RUNTIME_FILE" "FAZ_7_20_COMMERCIAL_MASTER_CLOSURE"

require_grep "7-13.6.53 live-ready report test exists" "$TEST_FILE" "TestSevenThirteenBuildLiveReadyReportKeepsRealOperationsClosed"
require_grep "7-13.6.54 missing requirements activation test exists" "$TEST_FILE" "TestSevenThirteenActivationBlockedWhenRequirementsMissing"
require_grep "7-13.6.55 phase lock activation test exists" "$TEST_FILE" "TestSevenThirteenActivationStillBlockedWhenAllRequirementsReadyBecausePhaseLock"
require_grep "7-13.6.56 requirements and next modules test exists" "$TEST_FILE" "TestSevenThirteenRequirementsAndNextModules"
require_grep "7-13.6.57 real operation blockers test exists" "$TEST_FILE" "TestSevenThirteenRealOperationBlockers"
require_grep "7-13.6.58 opened gate reject test exists" "$TEST_FILE" "TestSevenThirteenGateRejectsOpenedRealOperation"
require_grep "7-13.6.59 audit trail test exists" "$TEST_FILE" "TestSevenThirteenAuditTrail"

require_grep "7-13.6.60 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_13_COMMERCIAL_LIVE_READY_CONTROL_PLANE\""
require_grep "7-13.6.61 config mode exists" "$CONFIG_FILE" "\"mode\": \"LIVE_READY_CONTROL_PLANE_WITH_PRODUCTION_ACTIVATION_DISABLED\""
require_grep "7-13.6.62 config accountant portal family dependency exists" "$CONFIG_FILE" "\"faz_7_accountant_portal_family_final_status\": \"PASS\""
require_grep "7-13.6.63 config production activation false" "$CONFIG_FILE" "\"production_activation_allowed\": false"
require_grep "7-13.6.64 config real money false" "$CONFIG_FILE" "\"real_money_movement_allowed\": false"
require_grep "7-13.6.65 config real provider API false" "$CONFIG_FILE" "\"real_provider_api_call_allowed\": false"
require_grep "7-13.6.66 config real customer data export false" "$CONFIG_FILE" "\"real_customer_data_export_allowed\": false"
require_grep "7-13.6.67 config next module 7-20 exists" "$CONFIG_FILE" "\"FAZ_7_20_COMMERCIAL_MASTER_CLOSURE\""

require_grep "7-13.6.68 documentation says live modules will not wait" "$DOC_FILE" "Live modüller gelmesini beklemeyeceğiz"
require_grep "7-13.6.69 documentation says live activation is not this phase" "$DOC_FILE" "Bu faz live activation değildir"
require_grep "7-13.6.70 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-13.6.71 runtime does not default production activation true" "$RUNTIME_FILE" "ProductionActivationAllowed: true"
require_not_grep "7-13.6.72 runtime does not default real money true" "$RUNTIME_FILE" "RealMoneyMovementAllowed:    true"
require_not_grep "7-13.6.73 runtime does not default real provider API true" "$RUNTIME_FILE" "RealProviderAPICallAllowed:  true"
require_not_grep "7-13.6.74 runtime does not default real file delivery true" "$RUNTIME_FILE" "RealFileDeliveryAllowed:     true"
require_not_grep "7-13.6.75 runtime does not default real ERP write true" "$RUNTIME_FILE" "RealERPWriteAllowed:         true"
require_not_grep "7-13.6.76 runtime does not default customer export true" "$RUNTIME_FILE" "RealCustomerDataExport:      true"

if go test ./internal/platform/commercial/liveready; then
  ok "7-13.6.77 go test verification PASS"
else
  fail "7-13.6.77 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-13 COMMERCIAL LIVE-READY CONTROL PLANE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_13_COMMERCIAL_LIVE_READY_CONTROL_PLANE_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
