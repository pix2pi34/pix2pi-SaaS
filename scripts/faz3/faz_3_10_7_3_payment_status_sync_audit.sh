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

echo "===== 119 — FAZ 3-10.7.3 PAYMENT STATUS SYNC REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/payment/statussync/payment_status_sync.go"
TEST_FILE="internal/erp/turkiye/payment/statussync/payment_status_sync_test.go"
CONFIG_FILE="configs/faz3/payment/payment_status_sync.v1.json"
DOC_FILE="docs/faz3/payment/FAZ_3_10_7_3_PAYMENT_STATUS_SYNC.md"

check_file "119 payment status sync runtime file" "$RUNTIME_FILE"
check_file "119 payment status sync test file" "$TEST_FILE"
check_file "119 payment status sync config file" "$CONFIG_FILE"
check_file "119 payment status sync documentation file" "$DOC_FILE"

check_grep "119 runtime constructor" "$RUNTIME_FILE" "NewPaymentStatusSyncRuntime"
check_grep "119 callback handler" "$RUNTIME_FILE" "HandleCallback"
check_grep "119 webhook handler" "$RUNTIME_FILE" "HandleWebhook"
check_grep "119 poll handler" "$RUNTIME_FILE" "HandlePollResult"
check_grep "119 manual recheck handler" "$RUNTIME_FILE" "HandleManualRecheck"
check_grep "119 poll planner" "$RUNTIME_FILE" "BuildPollPlan"
check_grep "119 canonicalize function" "$RUNTIME_FILE" "func canonicalize"
check_grep "119 POS channel support" "$RUNTIME_FILE" "POS"
check_grep "119 virtual POS channel support" "$RUNTIME_FILE" "VIRTUAL_POS"
check_grep "119 bank transfer channel support" "$RUNTIME_FILE" "BANK_TRANSFER"
check_grep "119 bank collection channel support" "$RUNTIME_FILE" "BANK_COLLECTION"
check_grep "119 marketplace settlement channel support" "$RUNTIME_FILE" "MARKETPLACE_SETTLEMENT"
check_grep "119 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "119 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "119 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "119 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "119 payment transaction guard" "$RUNTIME_FILE" "payment_transaction_id is required"
check_grep "119 provider transaction guard" "$RUNTIME_FILE" "provider_transaction_id is required"
check_grep "119 provider payload hash guard" "$RUNTIME_FILE" "provider_payload_hash is required"
check_grep "119 callback signature guard" "$RUNTIME_FILE" "callback_signature is required"
check_grep "119 webhook signature guard" "$RUNTIME_FILE" "webhook_signature is required"
check_grep "119 bank reference guard" "$RUNTIME_FILE" "bank_reference_no is required for bank collection"
check_grep "119 retry scheduling behavior" "$RUNTIME_FILE" "RetryScheduled"
check_grep "119 payment completed flag" "$RUNTIME_FILE" "PaymentCompleted"
check_grep "119 reconciliation completed flag" "$RUNTIME_FILE" "ReconciliationCompleted"

check_grep "119 config callback signature required" "$CONFIG_FILE" "\"callback_signature_required\": true"
check_grep "119 config webhook signature required" "$CONFIG_FILE" "\"webhook_signature_required\": true"
check_grep "119 config poll enabled" "$CONFIG_FILE" "\"poll_enabled\": true"
check_grep "119 config manual recheck enabled" "$CONFIG_FILE" "\"manual_recheck_enabled\": true"
check_grep "119 config POS channel" "$CONFIG_FILE" "POS"
check_grep "119 config bank collection channel" "$CONFIG_FILE" "BANK_COLLECTION"
check_grep "119 config SIM_BANK_POS provider" "$CONFIG_FILE" "SIM_BANK_POS"
check_grep "119 config SIM_BANK provider" "$CONFIG_FILE" "SIM_BANK"

if go test ./internal/erp/turkiye/payment/statussync; then
  pass "119 payment status sync Go test status"
else
  fail "119 payment status sync Go test status"
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
# 119 — FAZ 3-10.7.3 — Payment Status Sync Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_7_3_PAYMENT_STATUS_SYNC_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_7_3_PAYMENT_STATUS_SYNC_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_7_4_READY=${NEXT_READY}

## Scope

- Callback status sync
- Webhook status sync
- Poll status sync
- Manual recheck status sync
- Poll candidate planning
- Provider status canonicalization
- POS / Virtual POS / Bank transfer / Bank collection / Marketplace settlement support
- Tenant / correlation / request / idempotency guards
- Payment transaction / provider transaction guards
- Provider payload hash guard
- Callback / webhook signature guards
- Bank reference guard for bank collection
- Retry scheduling hint
- Payment/reconciliation/refund/reversal completion flags

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 119 — FAZ 3-10.7.3 PAYMENT STATUS SYNC COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_7_3_PAYMENT_STATUS_SYNC_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_7_3_PAYMENT_STATUS_SYNC_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_7_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
