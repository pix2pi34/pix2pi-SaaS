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

echo "===== 132 — FAZ 3-10.1.5 TDHP RECONCILIATION RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tdhp/reconciliation/tdhp_reconciliation_runtime.go"
TEST_FILE="internal/erp/turkiye/tdhp/reconciliation/tdhp_reconciliation_runtime_test.go"
CONFIG_FILE="configs/faz3/tdhp/tdhp_reconciliation_runtime.v1.json"
DOC_FILE="docs/faz3/tdhp/FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME.md"

check_file "132 reconciliation runtime file" "$RUNTIME_FILE"
check_file "132 reconciliation test file" "$TEST_FILE"
check_file "132 reconciliation config file" "$CONFIG_FILE"
check_file "132 reconciliation documentation file" "$DOC_FILE"

check_grep "132 runtime constructor" "$RUNTIME_FILE" "NewTDHPReconciliationRuntime"
check_grep "132 reconcile runtime" "$RUNTIME_FILE" "Reconcile"
check_grep "132 request validation runtime" "$RUNTIME_FILE" "validateRequest"
check_grep "132 result hash builder" "$RUNTIME_FILE" "buildResultHash"
check_grep "132 request model" "$RUNTIME_FILE" "type ReconciliationRequest"
check_grep "132 result model" "$RUNTIME_FILE" "type ReconciliationResult"
check_grep "132 matched status" "$RUNTIME_FILE" "ReconciliationStatusMatched"
check_grep "132 difference review status" "$RUNTIME_FILE" "ReconciliationStatusDifferenceReview"
check_grep "132 rejected status" "$RUNTIME_FILE" "ReconciliationStatusRejected"

check_grep "132 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "132 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "132 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "132 reconciliation id guard" "$RUNTIME_FILE" "reconciliation_id is required"
check_grep "132 document id guard" "$RUNTIME_FILE" "document_id is required"
check_grep "132 voucher id guard" "$RUNTIME_FILE" "voucher_id is required"
check_grep "132 posting id guard" "$RUNTIME_FILE" "posting_id is required"
check_grep "132 currency guard" "$RUNTIME_FILE" "currency mismatch"
check_grep "132 expected balance guard" "$RUNTIME_FILE" "expected debit and credit must be balanced"
check_grep "132 actual balance guard" "$RUNTIME_FILE" "actual debit and credit must be balanced"
check_grep "132 posting hash guard" "$RUNTIME_FILE" "posting_hash is required"
check_grep "132 audit trace hash guard" "$RUNTIME_FILE" "audit_trace_hash is required"
check_grep "132 ledger ready guard" "$RUNTIME_FILE" "ledger_ready is required"

check_grep "132 matched test" "$TEST_FILE" "TestReconcileMatched"
check_grep "132 difference review test" "$TEST_FILE" "TestReconcileDifferenceReview"
check_grep "132 unbalanced expected test" "$TEST_FILE" "TestReconcileRejectsUnbalancedExpected"
check_grep "132 unbalanced actual test" "$TEST_FILE" "TestReconcileRejectsUnbalancedActual"
check_grep "132 currency mismatch test" "$TEST_FILE" "TestReconcileRejectsCurrencyMismatch"
check_grep "132 posting hash test" "$TEST_FILE" "TestReconcileRejectsMissingPostingHash"
check_grep "132 audit trace hash test" "$TEST_FILE" "TestReconcileRejectsMissingAuditTraceHash"
check_grep "132 ledger ready test" "$TEST_FILE" "TestReconcileRejectsLedgerNotReady"

check_grep "132 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "132 config currency TRY" "$CONFIG_FILE" "\"default_currency\": \"TRY\""
check_grep "132 config posting hash required" "$CONFIG_FILE" "\"require_posting_hash\": true"
check_grep "132 config audit trace hash required" "$CONFIG_FILE" "\"require_audit_trace_hash\": true"
check_grep "132 config ledger ready required" "$CONFIG_FILE" "\"require_ledger_ready\": true"
check_grep "132 config balanced required" "$CONFIG_FILE" "\"require_balanced_amounts\": true"
check_grep "132 config result hash required" "$CONFIG_FILE" "\"require_result_hash\": true"

if go test ./internal/erp/turkiye/tdhp/reconciliation; then
  pass "132 reconciliation go test status"
else
  fail "132 reconciliation go test status"
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
# 132 — FAZ 3-10.1.5 — TDHP Reconciliation Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_1_6_READY=${NEXT_READY}

## Scope

- TDHP reconciliation runtime
- Request/result model
- Expected balance guard
- Actual balance guard
- Posting hash guard
- Audit trace hash guard
- Ledger ready guard
- Currency guard
- Difference review decision
- Result hash generation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 132 — FAZ 3-10.1.5 TDHP RECONCILIATION RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_1_6_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
