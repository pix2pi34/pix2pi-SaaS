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

echo "===== 119 — FAZ 3-10.7.4 REFUND CANCEL RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/payment/refundcancel/refund_cancel_runtime.go"
TEST_FILE="internal/erp/turkiye/payment/refundcancel/refund_cancel_runtime_test.go"
CONFIG_FILE="configs/faz3/payment/refund_cancel_runtime.v1.json"
DOC_FILE="docs/faz3/payment/FAZ_3_10_7_4_REFUND_CANCEL_RUNTIME.md"

check_file "119 refund/cancel runtime file" "$RUNTIME_FILE"
check_file "119 refund/cancel test file" "$TEST_FILE"
check_file "119 refund/cancel config file" "$CONFIG_FILE"
check_file "119 refund/cancel documentation file" "$DOC_FILE"

check_grep "119 runtime constructor" "$RUNTIME_FILE" "NewRefundCancelRuntime"
check_grep "119 prepare refund runtime" "$RUNTIME_FILE" "PrepareRefund"
check_grep "119 register refund accepted runtime" "$RUNTIME_FILE" "RegisterRefundAccepted"
check_grep "119 prepare cancel runtime" "$RUNTIME_FILE" "PrepareCancel"
check_grep "119 register cancel accepted runtime" "$RUNTIME_FILE" "RegisterCancelAccepted"
check_grep "119 prepare void runtime" "$RUNTIME_FILE" "PrepareVoid"
check_grep "119 register void accepted runtime" "$RUNTIME_FILE" "RegisterVoidAccepted"
check_grep "119 prepare reversal runtime" "$RUNTIME_FILE" "PrepareReversal"
check_grep "119 register reversal accepted runtime" "$RUNTIME_FILE" "RegisterReversalAccepted"
check_grep "119 status check runtime" "$RUNTIME_FILE" "CheckStatus"

check_grep "119 refund queued lifecycle" "$RUNTIME_FILE" "REFUND_QUEUED"
check_grep "119 refund accepted lifecycle" "$RUNTIME_FILE" "REFUND_ACCEPTED"
check_grep "119 cancel queued lifecycle" "$RUNTIME_FILE" "CANCEL_QUEUED"
check_grep "119 cancel accepted lifecycle" "$RUNTIME_FILE" "CANCEL_ACCEPTED"
check_grep "119 void queued lifecycle" "$RUNTIME_FILE" "VOID_QUEUED"
check_grep "119 void accepted lifecycle" "$RUNTIME_FILE" "VOID_ACCEPTED"
check_grep "119 reversal queued lifecycle" "$RUNTIME_FILE" "REVERSAL_QUEUED"
check_grep "119 reversal accepted lifecycle" "$RUNTIME_FILE" "REVERSAL_ACCEPTED"

check_grep "119 production real payment gate guard" "$RUNTIME_FILE" "production real payment access is closed"
check_grep "119 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "119 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "119 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "119 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "119 payment transaction guard" "$RUNTIME_FILE" "payment_transaction_id is required"
check_grep "119 provider transaction guard" "$RUNTIME_FILE" "provider_transaction_id is required"
check_grep "119 provider payload hash guard" "$RUNTIME_FILE" "provider_payload_hash is required"
check_grep "119 original amount guard" "$RUNTIME_FILE" "original_amount_kurus must be positive"
check_grep "119 requested amount guard" "$RUNTIME_FILE" "requested_amount_kurus must be positive"
check_grep "119 refund remaining guard" "$RUNTIME_FILE" "requested_amount_kurus exceeds remaining refundable amount"
check_grep "119 refund captured guard" "$RUNTIME_FILE" "refund requires captured payment"
check_grep "119 cancel after capture guard" "$RUNTIME_FILE" "cancel is not allowed after capture"
check_grep "119 void after settlement guard" "$RUNTIME_FILE" "void is not allowed after settlement"
check_grep "119 reversal settlement guard" "$RUNTIME_FILE" "reversal requires settled payment"
check_grep "119 reason code guard" "$RUNTIME_FILE" "reason_code is required"
check_grep "119 currency guard" "$RUNTIME_FILE" "currency_code mismatch"

check_grep "119 config real payment gate closed" "$CONFIG_FILE" "\"real_payment_gate_open\": false"
check_grep "119 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "119 config partial refund allowed" "$CONFIG_FILE" "\"partial_refund_allowed\": true"
check_grep "119 config full refund allowed" "$CONFIG_FILE" "\"full_refund_allowed\": true"
check_grep "119 config void allowed" "$CONFIG_FILE" "\"void_allowed_before_settlement\": true"
check_grep "119 config cancel allowed" "$CONFIG_FILE" "\"cancel_allowed_before_capture\": true"
check_grep "119 config reversal allowed" "$CONFIG_FILE" "\"reversal_allowed_after_settlement\": true"
check_grep "119 config raw secret policy" "$CONFIG_FILE" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"
check_grep "119 config next gate" "$CONFIG_FILE" "FAZ_3_10_7_5_INTEGRATION_AUDIT_RUNTIME"

if go test ./internal/erp/turkiye/payment/refundcancel; then
  pass "119 refund/cancel Go test status"
else
  fail "119 refund/cancel Go test status"
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
# 119 — FAZ 3-10.7.4 — Refund / Cancel Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_7_4_REFUND_CANCEL_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_7_4_REFUND_CANCEL_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_7_5_READY=${NEXT_READY}

## Scope

- Prepare refund
- Register refund accepted
- Prepare cancel
- Register cancel accepted
- Prepare void
- Register void accepted
- Prepare reversal
- Register reversal accepted
- Status check
- Partial / full refund guard
- Remaining refundable amount guard
- Cancel before capture guard
- Void before settlement guard
- Reversal after settlement guard
- Tenant / correlation / request / idempotency guards
- Provider transaction / provider payload hash guards
- Reason code guard
- TRY currency guard
- Production real payment gate closed

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 119 — FAZ 3-10.7.4 REFUND CANCEL RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_7_4_REFUND_CANCEL_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_7_4_REFUND_CANCEL_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_7_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
