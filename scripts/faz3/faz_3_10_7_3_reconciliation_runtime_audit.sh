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

echo "===== 118 — FAZ 3-10.7.3 RECONCILIATION RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/payment/reconciliation/reconciliation_runtime.go"
TEST_FILE="internal/erp/turkiye/payment/reconciliation/reconciliation_runtime_test.go"
CONFIG_FILE="configs/faz3/payment/reconciliation_runtime.v1.json"
DOC_FILE="docs/faz3/payment/FAZ_3_10_7_3_RECONCILIATION_RUNTIME.md"

check_file "118 reconciliation runtime file" "$RUNTIME_FILE"
check_file "118 reconciliation test file" "$TEST_FILE"
check_file "118 reconciliation config file" "$CONFIG_FILE"
check_file "118 reconciliation documentation file" "$DOC_FILE"

check_grep "118 runtime constructor" "$RUNTIME_FILE" "NewReconciliationRuntime"
check_grep "118 payment capture reconciliation" "$RUNTIME_FILE" "ReconcilePaymentCapture"
check_grep "118 bank statement reconciliation" "$RUNTIME_FILE" "ReconcileBankStatement"
check_grep "118 marketplace settlement reconciliation" "$RUNTIME_FILE" "ReconcileMarketplaceSettlement"
check_grep "118 refund reversal reconciliation" "$RUNTIME_FILE" "ReconcileRefundReversal"
check_grep "118 manual review register" "$RUNTIME_FILE" "RegisterManualReview"
check_grep "118 amount reconciliation function" "$RUNTIME_FILE" "applyAmountReconciliation"
check_grep "118 net settlement reconciliation function" "$RUNTIME_FILE" "applyNetSettlementReconciliation"
check_grep "118 tolerance check" "$RUNTIME_FILE" "ReconciliationToleranceKurus"
check_grep "118 matched decision" "$RUNTIME_FILE" "MATCHED"
check_grep "118 difference review decision" "$RUNTIME_FILE" "DIFFERENCE_REVIEW"
check_grep "118 manual review required status" "$RUNTIME_FILE" "MANUAL_REVIEW_REQUIRED"
check_grep "118 ledger posting readiness" "$RUNTIME_FILE" "LedgerPostingReady"
check_grep "118 payment closure readiness" "$RUNTIME_FILE" "PaymentClosureReady"

check_grep "118 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "118 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "118 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "118 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "118 reconciliation id guard" "$RUNTIME_FILE" "reconciliation_id is required"
check_grep "118 payment transaction guard" "$RUNTIME_FILE" "payment_transaction_id is required"
check_grep "118 provider transaction guard" "$RUNTIME_FILE" "provider_transaction_id is required"
check_grep "118 provider payload hash guard" "$RUNTIME_FILE" "provider_payload_hash is required"
check_grep "118 bank account guard" "$RUNTIME_FILE" "bank_account_id is required"
check_grep "118 bank reference guard" "$RUNTIME_FILE" "bank_reference_no is required"
check_grep "118 statement line guard" "$RUNTIME_FILE" "statement_line_id is required"
check_grep "118 statement payload hash guard" "$RUNTIME_FILE" "statement_payload_hash is required"
check_grep "118 marketplace settlement guard" "$RUNTIME_FILE" "marketplace_settlement_id is required"
check_grep "118 expected amount guard" "$RUNTIME_FILE" "expected_amount_kurus must be positive"
check_grep "118 actual amount guard" "$RUNTIME_FILE" "actual_amount_kurus must be positive"
check_grep "118 currency guard" "$RUNTIME_FILE" "currency_code mismatch"

check_grep "118 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "118 config default currency TRY" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "118 config tolerance" "$CONFIG_FILE" "\"reconciliation_tolerance_kurus\": 100"
check_grep "118 config POS channel" "$CONFIG_FILE" "POS"
check_grep "118 config bank collection channel" "$CONFIG_FILE" "BANK_COLLECTION"
check_grep "118 config marketplace channel" "$CONFIG_FILE" "MARKETPLACE_SETTLEMENT"
check_grep "118 config next gate" "$CONFIG_FILE" "FAZ_3_10_7_4_REFUND_CANCEL_RUNTIME"

if go test ./internal/erp/turkiye/payment/reconciliation; then
  pass "118 reconciliation Go test status"
else
  fail "118 reconciliation Go test status"
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
# 118 — FAZ 3-10.7.3 — Reconciliation Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_7_3_RECONCILIATION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_7_3_RECONCILIATION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_7_4_READY=${NEXT_READY}

## Scope

- POS / Virtual POS payment capture reconciliation
- Bank statement reconciliation
- Marketplace settlement reconciliation
- Refund / reversal reconciliation
- Manual review register
- Amount difference tolerance
- Net settlement reconciliation
- Ledger posting readiness
- Payment closure readiness
- Tenant / correlation / request / idempotency guards
- Provider transaction / provider payload hash guards
- Bank reference / statement hash guards
- Marketplace settlement id guard
- TRY currency guard

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 118 — FAZ 3-10.7.3 RECONCILIATION RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_7_3_RECONCILIATION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_7_3_RECONCILIATION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_7_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
