#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/commercial/liveready/payment_capture_live_ready_runtime.go"
TEST_FILE="internal/platform/commercial/liveready/payment_capture_live_ready_runtime_test.go"
CONFIG_FILE="configs/faz7/payment_capture_live_ready_runtime.json"
DOC_FILE="docs/faz7/commercial/FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-15 PAYMENT CAPTURE LIVE-READY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

require_file "7-15.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-15.6.2 test file exists" "$TEST_FILE"
require_file "7-15.6.3 config file exists" "$CONFIG_FILE"
require_file "7-15.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-15.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME"
require_grep "7-15.6.6 payment live-ready mode implemented" "$RUNTIME_FILE" "PAYMENT_CAPTURE_LIVE_READY_WITH_REAL_CAPTURE_DISABLED"
require_grep "7-15.6.7 payment gate implemented" "$RUNTIME_FILE" "type PaymentCaptureLiveReadyGate struct"
require_grep "7-15.6.8 payment input implemented" "$RUNTIME_FILE" "type PaymentCaptureLiveReadyInput struct"
require_grep "7-15.6.9 payment requirement model implemented" "$RUNTIME_FILE" "type PaymentCaptureLiveReadyRequirement struct"
require_grep "7-15.6.10 capture plan request implemented" "$RUNTIME_FILE" "type PaymentCapturePlanRequest struct"
require_grep "7-15.6.11 capture plan implemented" "$RUNTIME_FILE" "type PaymentCapturePlan struct"
require_grep "7-15.6.12 payment report implemented" "$RUNTIME_FILE" "type PaymentCaptureLiveReadyReport struct"
require_grep "7-15.6.13 runtime implemented" "$RUNTIME_FILE" "type PaymentCaptureLiveReadyRuntime struct"
require_grep "7-15.6.14 build payment report implemented" "$RUNTIME_FILE" "BuildPaymentCaptureLiveReadyReport"
require_grep "7-15.6.15 build capture plan implemented" "$RUNTIME_FILE" "BuildCapturePlan"
require_grep "7-15.6.16 missing payment requirements implemented" "$RUNTIME_FILE" "MissingPaymentCaptureLiveReadyRequirements"
require_grep "7-15.6.17 audit event implemented" "$RUNTIME_FILE" "PaymentCaptureAuditEvent"

require_grep "7-15.6.18 production payment lock implemented" "$RUNTIME_FILE" "PRODUCTION_PAYMENT_CAPTURE_LOCKED_IN_FAZ_7_15"
require_grep "7-15.6.19 no real authorization policy implemented" "$RUNTIME_FILE" "NO_REAL_PAYMENT_AUTHORIZATION_IN_FAZ_7_15"
require_grep "7-15.6.20 no real capture policy implemented" "$RUNTIME_FILE" "NO_REAL_PAYMENT_CAPTURE_IN_FAZ_7_15"
require_grep "7-15.6.21 no real refund policy implemented" "$RUNTIME_FILE" "NO_REAL_PAYMENT_REFUND_IN_FAZ_7_15"
require_grep "7-15.6.22 no real void policy implemented" "$RUNTIME_FILE" "NO_REAL_PAYMENT_VOID_IN_FAZ_7_15"
require_grep "7-15.6.23 no real money policy implemented" "$RUNTIME_FILE" "NO_REAL_MONEY_MOVEMENT_IN_FAZ_7_15"
require_grep "7-15.6.24 no real provider API policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_15"
require_grep "7-15.6.25 no real settlement policy implemented" "$RUNTIME_FILE" "NO_REAL_SETTLEMENT_IN_FAZ_7_15"
require_grep "7-15.6.26 no real webhook ingestion policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_WEBHOOK_INGESTION_IN_FAZ_7_15"

require_grep "7-15.6.27 billing live-ready requirement implemented" "$RUNTIME_FILE" "billing_live_ready"
require_grep "7-15.6.28 provider contract requirement implemented" "$RUNTIME_FILE" "provider_contract_ready"
require_grep "7-15.6.29 payment attempt requirement implemented" "$RUNTIME_FILE" "payment_attempt_model_ready"
require_grep "7-15.6.30 authorization requirement implemented" "$RUNTIME_FILE" "authorization_plan_ready"
require_grep "7-15.6.31 capture policy requirement implemented" "$RUNTIME_FILE" "capture_policy_ready"
require_grep "7-15.6.32 refund void policy requirement implemented" "$RUNTIME_FILE" "refund_void_policy_ready"
require_grep "7-15.6.33 idempotency requirement implemented" "$RUNTIME_FILE" "payment_idempotency_ready"
require_grep "7-15.6.34 retry DLQ requirement implemented" "$RUNTIME_FILE" "payment_retry_dlq_ready"
require_grep "7-15.6.35 webhook verification requirement implemented" "$RUNTIME_FILE" "webhook_verification_ready"
require_grep "7-15.6.36 audit requirement implemented" "$RUNTIME_FILE" "payment_audit_ready"
require_grep "7-15.6.37 rollback requirement implemented" "$RUNTIME_FILE" "payment_rollback_ready"
require_grep "7-15.6.38 legal approval requirement implemented" "$RUNTIME_FILE" "legal_approval_gate_ready"
require_grep "7-15.6.39 finance approval requirement implemented" "$RUNTIME_FILE" "finance_approval_gate_ready"
require_grep "7-15.6.40 security gate requirement implemented" "$RUNTIME_FILE" "security_gate_ready"
require_grep "7-15.6.41 observability requirement implemented" "$RUNTIME_FILE" "payment_observability_ready"

require_grep "7-15.6.42 real authorization blocker implemented" "$RUNTIME_FILE" "RequestRealAuthorization"
require_grep "7-15.6.43 real capture blocker implemented" "$RUNTIME_FILE" "RequestRealCapture"
require_grep "7-15.6.44 real refund blocker implemented" "$RUNTIME_FILE" "RequestRealRefund"
require_grep "7-15.6.45 real void blocker implemented" "$RUNTIME_FILE" "RequestRealVoid"
require_grep "7-15.6.46 real provider API blocker implemented" "$RUNTIME_FILE" "RequestRealProviderAPI"
require_grep "7-15.6.47 real settlement blocker implemented" "$RUNTIME_FILE" "RequestRealSettlement"

require_grep "7-15.6.48 idempotency key implemented" "$RUNTIME_FILE" "IdempotencyKey"
require_grep "7-15.6.49 retry policy status implemented" "$RUNTIME_FILE" "RetryPolicyStatus"
require_grep "7-15.6.50 DLQ policy status implemented" "$RUNTIME_FILE" "DLQPolicyStatus"
require_grep "7-15.6.51 webhook verification status implemented" "$RUNTIME_FILE" "WebhookVerificationStatus"
require_grep "7-15.6.52 next module 7-16 implemented" "$RUNTIME_FILE" "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS"

require_grep "7-15.6.53 payment report test exists" "$TEST_FILE" "TestSevenFifteenBuildPaymentCaptureLiveReadyReport"
require_grep "7-15.6.54 missing requirements test exists" "$TEST_FILE" "TestSevenFifteenMissingPaymentRequirements"
require_grep "7-15.6.55 capture plan test exists" "$TEST_FILE" "TestSevenFifteenBuildCapturePlanNoRealCapture"
require_grep "7-15.6.56 idempotency test exists" "$TEST_FILE" "TestSevenFifteenCapturePlanIdempotency"
require_grep "7-15.6.57 invalid plan test exists" "$TEST_FILE" "TestSevenFifteenRejectInvalidCapturePlan"
require_grep "7-15.6.58 real blocker test exists" "$TEST_FILE" "TestSevenFifteenRealPaymentOperationBlockers"
require_grep "7-15.6.59 opened gate reject test exists" "$TEST_FILE" "TestSevenFifteenGateRejectsOpenedRealPayment"
require_grep "7-15.6.60 audit trail test exists" "$TEST_FILE" "TestSevenFifteenAuditTrail"

require_grep "7-15.6.61 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME\""
require_grep "7-15.6.62 config mode exists" "$CONFIG_FILE" "\"mode\": \"PAYMENT_CAPTURE_LIVE_READY_WITH_REAL_CAPTURE_DISABLED\""
require_grep "7-15.6.63 config depends on 7-14 PASS" "$CONFIG_FILE" "\"faz_7_14_accountant_billing_live_ready_runtime_final_status\": \"PASS\""
require_grep "7-15.6.64 config production payment false" "$CONFIG_FILE" "\"production_payment_allowed\": false"
require_grep "7-15.6.65 config real authorization false" "$CONFIG_FILE" "\"real_authorization_allowed\": false"
require_grep "7-15.6.66 config real capture false" "$CONFIG_FILE" "\"real_capture_allowed\": false"
require_grep "7-15.6.67 config real refund false" "$CONFIG_FILE" "\"real_refund_allowed\": false"
require_grep "7-15.6.68 config real void false" "$CONFIG_FILE" "\"real_void_allowed\": false"
require_grep "7-15.6.69 config real money false" "$CONFIG_FILE" "\"real_money_movement_allowed\": false"
require_grep "7-15.6.70 config next module 7-16 exists" "$CONFIG_FILE" "\"next_module\": \"FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS\""

require_grep "7-15.6.71 documentation says live payment is not this phase" "$DOC_FILE" "Bu faz live payment değildir"
require_grep "7-15.6.72 documentation live-ready requirements exist" "$DOC_FILE" "Live-ready requirements"
require_grep "7-15.6.73 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-15.6.74 runtime does not default production payment true" "$RUNTIME_FILE" "ProductionPaymentAllowed:    true"
require_not_grep "7-15.6.75 runtime does not default real capture true" "$RUNTIME_FILE" "RealCaptureAllowed:          true"
require_not_grep "7-15.6.76 runtime does not default real money true" "$RUNTIME_FILE" "RealMoneyMovementAllowed:    true"
require_not_grep "7-15.6.77 runtime capture plan does not request authorization" "$RUNTIME_FILE" "RealAuthorizationRequested:    true"
require_not_grep "7-15.6.78 runtime capture plan does not request capture" "$RUNTIME_FILE" "RealCaptureRequested:          true"
require_not_grep "7-15.6.79 runtime capture plan does not request provider API" "$RUNTIME_FILE" "RealProviderAPICallRequested:  true"
require_not_grep "7-15.6.80 runtime capture plan does not request settlement" "$RUNTIME_FILE" "RealSettlementRequested:       true"

if go test ./internal/platform/commercial/liveready; then
  ok "7-15.6.81 go test verification PASS"
else
  fail "7-15.6.81 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-15 PAYMENT CAPTURE LIVE-READY RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
