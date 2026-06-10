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

echo "===== 120 — FAZ 3-10.7.4 PAYMENT ERROR RETRY REVERSAL REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/payment/errorretry/payment_error_retry_reversal.go"
TEST_FILE="internal/erp/turkiye/payment/errorretry/payment_error_retry_reversal_test.go"
CONFIG_FILE="configs/faz3/payment/payment_error_retry_reversal.v1.json"
DOC_FILE="docs/faz3/payment/FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME.md"

check_file "120 payment error/retry/reversal runtime file" "$RUNTIME_FILE"
check_file "120 payment error/retry/reversal test file" "$TEST_FILE"
check_file "120 payment error/retry/reversal config file" "$CONFIG_FILE"
check_file "120 payment error/retry/reversal documentation file" "$DOC_FILE"

check_grep "120 runtime constructor" "$RUNTIME_FILE" "NewPaymentErrorRetryReversalRuntime"
check_grep "120 provider error handler" "$RUNTIME_FILE" "HandleProviderError"
check_grep "120 prepare reversal runtime" "$RUNTIME_FILE" "PrepareReversal"
check_grep "120 register reversal accepted runtime" "$RUNTIME_FILE" "RegisterReversalAccepted"
check_grep "120 retry scheduled decision" "$RUNTIME_FILE" "RETRY_SCHEDULED"
check_grep "120 DLQ decision" "$RUNTIME_FILE" "DLQ"
check_grep "120 no retry decision" "$RUNTIME_FILE" "NO_RETRY"
check_grep "120 duplicate ignored decision" "$RUNTIME_FILE" "DUPLICATE_IGNORED"
check_grep "120 manual review decision" "$RUNTIME_FILE" "MANUAL_REVIEW"
check_grep "120 reversal queued decision" "$RUNTIME_FILE" "REVERSAL_QUEUED"
check_grep "120 reversal accepted decision" "$RUNTIME_FILE" "REVERSAL_ACCEPTED"
check_grep "120 production real payment gate guard" "$RUNTIME_FILE" "production real payment access is closed"
check_grep "120 retry delay function" "$RUNTIME_FILE" "retryDelaySeconds"
check_grep "120 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "120 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "120 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "120 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "120 payment transaction guard" "$RUNTIME_FILE" "payment_transaction_id is required"
check_grep "120 provider transaction guard" "$RUNTIME_FILE" "provider_transaction_id is required"
check_grep "120 provider payload hash guard" "$RUNTIME_FILE" "provider_payload_hash is required"
check_grep "120 reversal reason guard" "$RUNTIME_FILE" "reversal_reason_code is required"
check_grep "120 POS channel support" "$RUNTIME_FILE" "POS"
check_grep "120 virtual POS channel support" "$RUNTIME_FILE" "VIRTUAL_POS"
check_grep "120 bank collection channel support" "$RUNTIME_FILE" "BANK_COLLECTION"
check_grep "120 marketplace channel support" "$RUNTIME_FILE" "MARKETPLACE_SETTLEMENT"

check_grep "120 config real payment gate closed" "$CONFIG_FILE" "\"real_payment_gate_open\": false"
check_grep "120 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "120 config DLQ enabled" "$CONFIG_FILE" "\"dlq_enabled\": true"
check_grep "120 config manual review enabled" "$CONFIG_FILE" "\"manual_review_enabled\": true"
check_grep "120 config reversal reason required" "$CONFIG_FILE" "\"reversal_reason_required\": true"
check_grep "120 config retryable timeout" "$CONFIG_FILE" "PROVIDER_TIMEOUT"
check_grep "120 config fatal insufficient funds" "$CONFIG_FILE" "INSUFFICIENT_FUNDS"
check_grep "120 config duplicate provider transaction" "$CONFIG_FILE" "DUPLICATE_PROVIDER_TRANSACTION"
check_grep "120 config raw secret policy" "$CONFIG_FILE" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"

if go test ./internal/erp/turkiye/payment/errorretry; then
  pass "120 payment error/retry/reversal Go test status"
else
  fail "120 payment error/retry/reversal Go test status"
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
# 120 — FAZ 3-10.7.4 — Payment Error / Retry / Reversal Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_7_PAYMENT_RUNTIME_FINAL_CLOSURE_READY=${NEXT_READY}

## Scope

- Payment provider error handler
- Retry scheduling
- DLQ decision
- Non-retryable decision
- Duplicate ignore decision
- Manual review decision
- Reversal prepare
- Reversal accepted registration
- Production real payment gate closed
- Tenant / correlation / request / idempotency guards
- Payment transaction / provider transaction guards
- Provider payload hash guard
- Reversal reason guard
- POS / Virtual POS / Bank collection / Bank transfer / Marketplace settlement support

## Live Payment Policy

Real bank/POS payment remains closed until provider-specific live module and approvals.

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 120 — FAZ 3-10.7.4 PAYMENT ERROR RETRY REVERSAL COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_7_PAYMENT_RUNTIME_FINAL_CLOSURE_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
