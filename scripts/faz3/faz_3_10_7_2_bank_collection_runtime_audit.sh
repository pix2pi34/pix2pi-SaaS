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

echo "===== 118 — FAZ 3-10.7.2 BANK COLLECTION RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/payment/bankcollection/bank_collection.go"
TEST_FILE="internal/erp/turkiye/payment/bankcollection/bank_collection_test.go"
CONFIG_FILE="configs/faz3/payment/bank_collection_runtime.v1.json"
DOC_FILE="docs/faz3/payment/FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME.md"

check_file "118 bank collection runtime file" "$RUNTIME_FILE"
check_file "118 bank collection test file" "$TEST_FILE"
check_file "118 bank collection config file" "$CONFIG_FILE"
check_file "118 bank collection documentation file" "$DOC_FILE"

check_grep "118 runtime constructor" "$RUNTIME_FILE" "NewBankCollectionRuntime"
check_grep "118 register bank transfer operation" "$RUNTIME_FILE" "RegisterBankTransfer"
check_grep "118 match bank statement operation" "$RUNTIME_FILE" "MatchBankStatement"
check_grep "118 reconcile collection operation" "$RUNTIME_FILE" "ReconcileCollection"
check_grep "118 build settlement operation" "$RUNTIME_FILE" "BuildSettlement"
check_grep "118 reverse collection operation" "$RUNTIME_FILE" "ReverseCollection"
check_grep "118 status check operation" "$RUNTIME_FILE" "CheckStatus"
check_grep "118 production real bank gate guard" "$RUNTIME_FILE" "production real bank access is closed"
check_grep "118 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "118 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "118 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "118 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "118 payment transaction guard" "$RUNTIME_FILE" "payment_transaction_id is required"
check_grep "118 collection no guard" "$RUNTIME_FILE" "collection_no is required"
check_grep "118 bank account guard" "$RUNTIME_FILE" "bank_account_id is required"
check_grep "118 provider bank mismatch guard" "$RUNTIME_FILE" "provider_bank_code mismatch"
check_grep "118 bank reference guard" "$RUNTIME_FILE" "bank_reference_no is required"
check_grep "118 statement line guard" "$RUNTIME_FILE" "statement_line_id is required"
check_grep "118 statement payload hash guard" "$RUNTIME_FILE" "statement_payload_hash is required"
check_grep "118 reconciliation tolerance guard" "$RUNTIME_FILE" "reconciliation difference exceeds tolerance"
check_grep "118 reverse reason guard" "$RUNTIME_FILE" "reverse_reason_code is required"

check_grep "118 config real bank gate closed" "$CONFIG_FILE" "\"real_bank_gate_open\": false"
check_grep "118 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "118 config raw secret policy" "$CONFIG_FILE" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"
check_grep "118 config register transfer operation" "$CONFIG_FILE" "REGISTER_BANK_TRANSFER"
check_grep "118 config reconciliation operation" "$CONFIG_FILE" "RECONCILE_COLLECTION"
check_grep "118 config reverse operation" "$CONFIG_FILE" "REVERSE_COLLECTION"

if go test ./internal/erp/turkiye/payment/bankcollection; then
  pass "118 bank collection Go test status"
else
  fail "118 bank collection Go test status"
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
# 118 — FAZ 3-10.7.2 — Bank Collection Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_7_3_READY=${NEXT_READY}

## Scope

- Bank collection runtime
- Register bank transfer
- Match bank statement
- Reconcile collection
- Build settlement
- Reverse collection
- Status check
- Production real bank gate closed
- Tenant / correlation / request / idempotency guards
- Bank account / provider bank / bank reference guards
- Statement line / payload hash guards
- Reconciliation tolerance guard
- Reverse reason guard

## Live Bank Policy

Real bank collection remains closed until provider-specific live module and approvals.

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 118 — FAZ 3-10.7.2 BANK COLLECTION RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_7_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
