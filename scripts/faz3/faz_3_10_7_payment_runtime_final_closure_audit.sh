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

echo "===== 121 — FAZ 3-10.7 PAYMENT RUNTIME FINAL CLOSURE REAL IMPLEMENTATION AUDIT START ====="

POS_RUNTIME="internal/erp/turkiye/payment/pos/pos_provider.go"
POS_TEST="internal/erp/turkiye/payment/pos/pos_provider_test.go"
POS_CONFIG="configs/faz3/payment/pos_provider_runtime.v1.json"
POS_DOC="docs/faz3/payment/FAZ_3_10_7_1_POS_PROVIDER_RUNTIME.md"
POS_EVIDENCE="docs/faz3/evidence/FAZ_3_10_7_1_POS_PROVIDER_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"

BANK_RUNTIME="internal/erp/turkiye/payment/bankcollection/bank_collection.go"
BANK_TEST="internal/erp/turkiye/payment/bankcollection/bank_collection_test.go"
BANK_CONFIG="configs/faz3/payment/bank_collection_runtime.v1.json"
BANK_DOC="docs/faz3/payment/FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME.md"
BANK_EVIDENCE="docs/faz3/evidence/FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"

STATUS_RUNTIME="internal/erp/turkiye/payment/statussync/payment_status_sync.go"
STATUS_TEST="internal/erp/turkiye/payment/statussync/payment_status_sync_test.go"
STATUS_CONFIG="configs/faz3/payment/payment_status_sync.v1.json"
STATUS_DOC="docs/faz3/payment/FAZ_3_10_7_3_PAYMENT_STATUS_SYNC.md"
STATUS_EVIDENCE="docs/faz3/evidence/FAZ_3_10_7_3_PAYMENT_STATUS_SYNC_REAL_IMPLEMENTATION_AUDIT.md"

ERROR_RUNTIME="internal/erp/turkiye/payment/errorretry/payment_error_retry_reversal.go"
ERROR_TEST="internal/erp/turkiye/payment/errorretry/payment_error_retry_reversal_test.go"
ERROR_CONFIG="configs/faz3/payment/payment_error_retry_reversal.v1.json"
ERROR_DOC="docs/faz3/payment/FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME.md"
ERROR_EVIDENCE="docs/faz3/evidence/FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"

check_file "121 POS runtime file" "$POS_RUNTIME"
check_file "121 POS test file" "$POS_TEST"
check_file "121 POS config file" "$POS_CONFIG"
check_file "121 POS documentation file" "$POS_DOC"
check_file "121 POS evidence file" "$POS_EVIDENCE"

check_file "121 bank collection runtime file" "$BANK_RUNTIME"
check_file "121 bank collection test file" "$BANK_TEST"
check_file "121 bank collection config file" "$BANK_CONFIG"
check_file "121 bank collection documentation file" "$BANK_DOC"
check_file "121 bank collection evidence file" "$BANK_EVIDENCE"

check_file "121 payment status sync runtime file" "$STATUS_RUNTIME"
check_file "121 payment status sync test file" "$STATUS_TEST"
check_file "121 payment status sync config file" "$STATUS_CONFIG"
check_file "121 payment status sync documentation file" "$STATUS_DOC"
check_file "121 payment status sync evidence file" "$STATUS_EVIDENCE"

check_file "121 payment error/retry/reversal runtime file" "$ERROR_RUNTIME"
check_file "121 payment error/retry/reversal test file" "$ERROR_TEST"
check_file "121 payment error/retry/reversal config file" "$ERROR_CONFIG"
check_file "121 payment error/retry/reversal documentation file" "$ERROR_DOC"
check_file "121 payment error/retry/reversal evidence file" "$ERROR_EVIDENCE"

check_grep "121 POS final evidence PASS" "$POS_EVIDENCE" "FAZ_3_10_7_1_POS_PROVIDER_RUNTIME_FINAL_STATUS=PASS"
check_grep "121 bank collection final evidence PASS" "$BANK_EVIDENCE" "FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME_FINAL_STATUS=PASS"
check_grep "121 payment status sync final evidence PASS" "$STATUS_EVIDENCE" "FAZ_3_10_7_3_PAYMENT_STATUS_SYNC_FINAL_STATUS=PASS"
check_grep "121 payment error/retry/reversal final evidence PASS" "$ERROR_EVIDENCE" "FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME_FINAL_STATUS=PASS"

check_grep "121 POS Authorize operation" "$POS_RUNTIME" "Authorize"
check_grep "121 POS Capture operation" "$POS_RUNTIME" "Capture"
check_grep "121 POS Sale operation" "$POS_RUNTIME" "Sale"
check_grep "121 POS Refund operation" "$POS_RUNTIME" "Refund"
check_grep "121 POS Void operation" "$POS_RUNTIME" "Void"
check_grep "121 POS 3DS init operation" "$POS_RUNTIME" "ThreeDSInit"
check_grep "121 POS 3DS complete operation" "$POS_RUNTIME" "ThreeDSComplete"
check_grep "121 POS production real payment gate guard" "$POS_RUNTIME" "production real payment access is closed"

check_grep "121 bank register transfer operation" "$BANK_RUNTIME" "RegisterBankTransfer"
check_grep "121 bank statement match operation" "$BANK_RUNTIME" "MatchBankStatement"
check_grep "121 bank reconcile operation" "$BANK_RUNTIME" "ReconcileCollection"
check_grep "121 bank settlement operation" "$BANK_RUNTIME" "BuildSettlement"
check_grep "121 bank reverse operation" "$BANK_RUNTIME" "ReverseCollection"
check_grep "121 bank production real bank gate guard" "$BANK_RUNTIME" "production real bank access is closed"

check_grep "121 payment status callback handler" "$STATUS_RUNTIME" "HandleCallback"
check_grep "121 payment status webhook handler" "$STATUS_RUNTIME" "HandleWebhook"
check_grep "121 payment status poll handler" "$STATUS_RUNTIME" "HandlePollResult"
check_grep "121 payment status manual recheck handler" "$STATUS_RUNTIME" "HandleManualRecheck"
check_grep "121 payment status poll planner" "$STATUS_RUNTIME" "BuildPollPlan"
check_grep "121 payment status canonicalize" "$STATUS_RUNTIME" "func canonicalize"

check_grep "121 payment error handler" "$ERROR_RUNTIME" "HandleProviderError"
check_grep "121 payment retry scheduled decision" "$ERROR_RUNTIME" "RETRY_SCHEDULED"
check_grep "121 payment DLQ decision" "$ERROR_RUNTIME" "DLQ"
check_grep "121 payment duplicate decision" "$ERROR_RUNTIME" "DUPLICATE_IGNORED"
check_grep "121 payment manual review decision" "$ERROR_RUNTIME" "MANUAL_REVIEW"
check_grep "121 payment reversal prepare" "$ERROR_RUNTIME" "PrepareReversal"
check_grep "121 payment reversal accepted" "$ERROR_RUNTIME" "RegisterReversalAccepted"

check_grep "121 tenant guard POS" "$POS_RUNTIME" "tenant_id is required"
check_grep "121 idempotency guard POS" "$POS_RUNTIME" "idempotency_key is required"
check_grep "121 merchant guard POS" "$POS_RUNTIME" "merchant_id is required"
check_grep "121 terminal guard POS" "$POS_RUNTIME" "terminal_id is required"
check_grep "121 masked PAN guard POS" "$POS_RUNTIME" "masked_card_pan must be masked"

check_grep "121 tenant guard bank" "$BANK_RUNTIME" "tenant_id is required"
check_grep "121 bank account guard" "$BANK_RUNTIME" "bank_account_id is required"
check_grep "121 bank reference guard" "$BANK_RUNTIME" "bank_reference_no is required"
check_grep "121 statement payload hash guard" "$BANK_RUNTIME" "statement_payload_hash is required"
check_grep "121 reconciliation tolerance guard" "$BANK_RUNTIME" "reconciliation difference exceeds tolerance"

check_grep "121 tenant guard status sync" "$STATUS_RUNTIME" "tenant_id is required"
check_grep "121 provider transaction guard status sync" "$STATUS_RUNTIME" "provider_transaction_id is required"
check_grep "121 provider payload hash guard status sync" "$STATUS_RUNTIME" "provider_payload_hash is required"
check_grep "121 callback signature guard status sync" "$STATUS_RUNTIME" "callback_signature is required"
check_grep "121 webhook signature guard status sync" "$STATUS_RUNTIME" "webhook_signature is required"

check_grep "121 tenant guard error retry" "$ERROR_RUNTIME" "tenant_id is required"
check_grep "121 provider transaction guard error retry" "$ERROR_RUNTIME" "provider_transaction_id is required"
check_grep "121 provider payload hash guard error retry" "$ERROR_RUNTIME" "provider_payload_hash is required"
check_grep "121 reversal reason guard" "$ERROR_RUNTIME" "reversal_reason_code is required"

check_grep "121 POS real payment gate closed" "$POS_CONFIG" "\"real_payment_gate_open\": false"
check_grep "121 POS production approved false" "$POS_CONFIG" "\"production_approved\": false"
check_grep "121 POS raw secret policy" "$POS_CONFIG" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"

check_grep "121 bank real bank gate closed" "$BANK_CONFIG" "\"real_bank_gate_open\": false"
check_grep "121 bank production approved false" "$BANK_CONFIG" "\"production_approved\": false"
check_grep "121 bank raw secret policy" "$BANK_CONFIG" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"

check_grep "121 payment status callback signature required" "$STATUS_CONFIG" "\"callback_signature_required\": true"
check_grep "121 payment status webhook signature required" "$STATUS_CONFIG" "\"webhook_signature_required\": true"
check_grep "121 payment status poll enabled" "$STATUS_CONFIG" "\"poll_enabled\": true"

check_grep "121 payment error real payment gate closed" "$ERROR_CONFIG" "\"real_payment_gate_open\": false"
check_grep "121 payment error production approved false" "$ERROR_CONFIG" "\"production_approved\": false"
check_grep "121 payment error DLQ enabled" "$ERROR_CONFIG" "\"dlq_enabled\": true"
check_grep "121 payment error manual review enabled" "$ERROR_CONFIG" "\"manual_review_enabled\": true"
check_grep "121 payment error raw secret policy" "$ERROR_CONFIG" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"

if go test \
  ./internal/erp/turkiye/payment/pos \
  ./internal/erp/turkiye/payment/bankcollection \
  ./internal/erp/turkiye/payment/statussync \
  ./internal/erp/turkiye/payment/errorretry; then
  pass "121 payment runtime family Go test status"
else
  fail "121 payment runtime family Go test status"
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
# 121 — FAZ 3-10.7 — Payment Runtime Final Closure Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_7_PAYMENT_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_7_PAYMENT_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}
- FAZ_3_10_8_READY=${NEXT_READY}

## Closed Scope

- 117 — POS provider runtime
- 118 — Bank collection runtime
- 119 — Payment status sync
- 120 — Payment error / retry / reversal runtime

## Runtime Packages

- internal/erp/turkiye/payment/pos
- internal/erp/turkiye/payment/bankcollection
- internal/erp/turkiye/payment/statussync
- internal/erp/turkiye/payment/errorretry

## Guardrails

- Tenant guard
- Correlation guard
- Request guard
- Idempotency guard
- Payment transaction guard
- Provider transaction guard
- Provider payload hash guard
- Merchant / terminal guard
- Bank account / bank reference guard
- Statement payload hash guard
- Reconciliation tolerance guard
- Callback / webhook signature guard
- Refund / void / reversal reason guard
- Retry / DLQ / manual review / duplicate decision guards
- Production real payment / real bank gates closed

## Live Payment Policy

Real bank/POS payment remains closed until provider-specific live module and approvals.

## Audit Notes

Final status is derived from real files, previous evidence files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 121 — FAZ 3-10.7 PAYMENT RUNTIME FINAL CLOSURE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_7_PAYMENT_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_7_PAYMENT_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}"
echo "FAZ_3_10_8_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
