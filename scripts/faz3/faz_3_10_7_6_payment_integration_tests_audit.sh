#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_FAILED / FAIL ❌"
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label file_missing=${file}"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern}"
  fi
}

echo "===== 121 — FAZ 3-10.7.6 PAYMENT INTEGRATION TESTS REAL IMPLEMENTATION AUDIT START ====="

SUITE_FILE="internal/erp/turkiye/payment/integrationtests/payment_integration_suite.go"
TEST_FILE="internal/erp/turkiye/payment/integrationtests/payment_integration_suite_test.go"
CONFIG_FILE="configs/faz3/payment/payment_integration_tests.v1.json"
DOC_FILE="docs/faz3/payment/FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS.md"

check_file "121 payment integration suite file" "$SUITE_FILE"
check_file "121 payment integration test file" "$TEST_FILE"
check_file "121 payment integration config file" "$CONFIG_FILE"
check_file "121 payment integration documentation file" "$DOC_FILE"

check_grep "121 suite constructor" "$SUITE_FILE" "NewPaymentIntegrationSuite"
check_grep "121 POSProviderRuntime wired" "$SUITE_FILE" "POSProviderRuntime"
check_grep "121 BankCollectionRuntime wired" "$SUITE_FILE" "BankCollectionRuntime"
check_grep "121 ReconciliationRuntime wired" "$SUITE_FILE" "ReconciliationRuntime"
check_grep "121 RefundCancelRuntime wired" "$SUITE_FILE" "RefundCancelRuntime"
check_grep "121 PaymentStatusSyncRuntime wired" "$SUITE_FILE" "PaymentStatusSyncRuntime"
check_grep "121 PaymentErrorRetryReversalRuntime wired" "$SUITE_FILE" "PaymentErrorRetryReversalRuntime"
check_grep "121 IntegrationAuditRuntime wired" "$SUITE_FILE" "IntegrationAuditRuntime"

check_grep "121 POS sale request helper" "$SUITE_FILE" "POSSaleRequest"
check_grep "121 payment status webhook helper" "$SUITE_FILE" "PaymentStatusWebhookFromPOS"
check_grep "121 refund request helper" "$SUITE_FILE" "RefundRequest"
check_grep "121 refund reconciliation helper" "$SUITE_FILE" "RefundReconciliationRequest"
check_grep "121 bank collection helper" "$SUITE_FILE" "BankCollectionRequest"
check_grep "121 bank reconciliation helper" "$SUITE_FILE" "BankReconciliationRequest"
check_grep "121 bank manual status helper" "$SUITE_FILE" "BankManualStatusRecheck"
check_grep "121 retryable payment error helper" "$SUITE_FILE" "RetryablePaymentErrorEvent"
check_grep "121 ready audit bundle helper" "$SUITE_FILE" "ReadyAuditBundle"

check_grep "121 POS sale E2E test" "$TEST_FILE" "TestPaymentIntegrationE2EPOSSaleStatusRefundReconciliationAndAudit"
check_grep "121 bank collection E2E test" "$TEST_FILE" "TestPaymentIntegrationE2EBankCollectionReconciliationAndStatusSync"
check_grep "121 failure path E2E test" "$TEST_FILE" "TestPaymentIntegrationE2EFailurePathsProtectClosure"

check_grep "121 POS sale operation test" "$TEST_FILE" "Sale"
check_grep "121 status webhook test" "$TEST_FILE" "HandleWebhook"
check_grep "121 refund prepare test" "$TEST_FILE" "PrepareRefund"
check_grep "121 refund accepted test" "$TEST_FILE" "RegisterRefundAccepted"
check_grep "121 refund reconciliation test" "$TEST_FILE" "ReconcileRefundReversal"
check_grep "121 payment retry test" "$TEST_FILE" "HandleProviderError"
check_grep "121 audit bundle test" "$TEST_FILE" "EvaluateEvidenceBundle"
check_grep "121 bank transfer register test" "$TEST_FILE" "RegisterBankTransfer"
check_grep "121 bank statement match test" "$TEST_FILE" "MatchBankStatement"
check_grep "121 bank collection reconcile test" "$TEST_FILE" "ReconcileCollection"
check_grep "121 bank statement reconciliation test" "$TEST_FILE" "ReconcileBankStatement"
check_grep "121 manual status recheck test" "$TEST_FILE" "HandleManualRecheck"
check_grep "121 invalid POS failure path" "$TEST_FILE" "invalid POS masked PAN"
check_grep "121 reconciliation difference review path" "$TEST_FILE" "DecisionDifferenceReview"
check_grep "121 audit missing scope path" "$TEST_FILE" "REQUIRED_AUDIT_SCOPE_MISSING"

check_grep "121 config real payment gate closed" "$CONFIG_FILE" "\"real_payment_gate_open\": false"
check_grep "121 config real bank gate closed" "$CONFIG_FILE" "\"real_bank_gate_open\": false"
check_grep "121 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "121 config POS scope" "$CONFIG_FILE" "POS_PROVIDER_RUNTIME"
check_grep "121 config bank collection scope" "$CONFIG_FILE" "BANK_COLLECTION_RUNTIME"
check_grep "121 config reconciliation scope" "$CONFIG_FILE" "RECONCILIATION_RUNTIME"
check_grep "121 config refund cancel scope" "$CONFIG_FILE" "REFUND_CANCEL_RUNTIME"
check_grep "121 config payment status scope" "$CONFIG_FILE" "PAYMENT_STATUS_SYNC"
check_grep "121 config payment error retry scope" "$CONFIG_FILE" "PAYMENT_ERROR_RETRY_RUNTIME"
check_grep "121 config integration audit scope" "$CONFIG_FILE" "INTEGRATION_AUDIT_RUNTIME"
check_grep "121 config raw secret policy" "$CONFIG_FILE" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"
check_grep "121 config next gate" "$CONFIG_FILE" "FAZ_3_10_7_PAYMENT_RUNTIME_FINAL_CLOSURE_RECHECK"

if go test ./internal/erp/turkiye/payment/integrationtests; then
  pass "121 payment integration Go test status"
else
  fail "121 payment integration Go test status"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 121 — FAZ 3-10.7.6 — Payment Integration Tests Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_7_PAYMENT_RUNTIME_FINAL_CLOSURE_RECHECK_READY=${NEXT_READY}

## Scope

- POS sale E2E
- Payment status webhook sync E2E
- Refund prepare / accepted E2E
- Refund reconciliation E2E
- Payment error retry E2E
- Bank transfer register E2E
- Bank statement match E2E
- Bank collection reconciliation E2E
- Manual status recheck E2E
- Integration audit bundle E2E
- Failure paths protect closure

## Guardrails

- Real payment gate closed
- Real bank gate closed
- Production approved false
- Invalid POS card mask rejected
- Reconciliation difference requires manual review
- Audit missing scope blocks closure

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 121 — FAZ 3-10.7.6 PAYMENT INTEGRATION TESTS COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_7_PAYMENT_RUNTIME_FINAL_CLOSURE_RECHECK_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
