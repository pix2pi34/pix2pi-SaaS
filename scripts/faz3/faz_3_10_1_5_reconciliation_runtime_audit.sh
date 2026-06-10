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

echo "===== 132 — FAZ 3-10.1.5 RECONCILIATION RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tdhp/reconciliationruntime/reconciliation_runtime.go"
TEST_FILE="internal/erp/turkiye/tdhp/reconciliationruntime/reconciliation_runtime_test.go"
CONFIG_FILE="configs/faz3/tdhp/reconciliation_runtime.v1.json"
DOC_FILE="docs/faz3/tdhp/FAZ_3_10_1_5_RECONCILIATION_RUNTIME.md"

check_file "132 reconciliation runtime file" "$RUNTIME_FILE"
check_file "132 reconciliation test file" "$TEST_FILE"
check_file "132 reconciliation config file" "$CONFIG_FILE"
check_file "132 reconciliation documentation file" "$DOC_FILE"

check_grep "132 runtime constructor" "$RUNTIME_FILE" "NewReconciliationRuntime"
check_grep "132 reconcile runtime" "$RUNTIME_FILE" "Reconcile"
check_grep "132 manual review register runtime" "$RUNTIME_FILE" "RegisterManualReview"
check_grep "132 find reconciliation runtime" "$RUNTIME_FILE" "FindReconciliation"
check_grep "132 list document reconciliations runtime" "$RUNTIME_FILE" "ListDocumentReconciliations"
check_grep "132 list posting reconciliations runtime" "$RUNTIME_FILE" "ListPostingReconciliations"

check_grep "132 reconciliation request model" "$RUNTIME_FILE" "type ReconciliationRequest"
check_grep "132 expected document model" "$RUNTIME_FILE" "type ExpectedDocument"
check_grep "132 reconciliation result model" "$RUNTIME_FILE" "type ReconciliationResult"
check_grep "132 reconciliation difference model" "$RUNTIME_FILE" "type ReconciliationDifference"
check_grep "132 repository interface" "$RUNTIME_FILE" "type ReconciliationRepository interface"
check_grep "132 in-memory repository" "$RUNTIME_FILE" "type InMemoryReconciliationRepository"

check_grep "132 posting runtime import" "$RUNTIME_FILE" "postingruntime"
check_grep "132 audit trace import" "$RUNTIME_FILE" "audittrace"
check_grep "132 append operation" "$RUNTIME_FILE" "Append(result ReconciliationResult)"
check_grep "132 find by reconciliation id operation" "$RUNTIME_FILE" "FindByReconciliationID"
check_grep "132 find by idempotency operation" "$RUNTIME_FILE" "FindByIdempotencyKey"
check_grep "132 list by tenant operation" "$RUNTIME_FILE" "ListByTenant"
check_grep "132 list by document operation" "$RUNTIME_FILE" "ListByDocument"
check_grep "132 list by posting operation" "$RUNTIME_FILE" "ListByPosting"

check_grep "132 matched status" "$RUNTIME_FILE" "MATCHED"
check_grep "132 difference status" "$RUNTIME_FILE" "DIFFERENCE"
check_grep "132 manual review status" "$RUNTIME_FILE" "MANUAL_REVIEW"
check_grep "132 posting vs document action" "$RUNTIME_FILE" "POSTING_VS_DOCUMENT"
check_grep "132 posting vs audit trace action" "$RUNTIME_FILE" "POSTING_VS_AUDIT_TRACE"
check_grep "132 reversal action" "$RUNTIME_FILE" "REVERSAL_VS_POSTING"
check_grep "132 period balance action" "$RUNTIME_FILE" "PERIOD_BALANCE"

check_grep "132 append-only result guard" "$RUNTIME_FILE" "append_only_result must be enabled"
check_grep "132 duplicate reconciliation id guard" "$RUNTIME_FILE" "reconciliation_id already exists"
check_grep "132 duplicate idempotency guard" "$RUNTIME_FILE" "idempotency_key already exists"
check_grep "132 tenant reconciliation key" "$RUNTIME_FILE" "tenantReconciliationKey"
check_grep "132 tenant idempotency key" "$RUNTIME_FILE" "tenantIdempotencyKey"
check_grep "132 result hash builder" "$RUNTIME_FILE" "buildResultHash"

check_grep "132 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "132 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "132 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "132 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "132 reconciliation id guard" "$RUNTIME_FILE" "reconciliation_id is required"
check_grep "132 action guard" "$RUNTIME_FILE" "reconciliation action is not allowed"
check_grep "132 expected document id guard" "$RUNTIME_FILE" "expected document_id is required"
check_grep "132 expected currency guard" "$RUNTIME_FILE" "expected currency_code mismatch"
check_grep "132 expected posting id guard" "$RUNTIME_FILE" "expected_posting_id is required"
check_grep "132 expected voucher id guard" "$RUNTIME_FILE" "expected_voucher_id is required"
check_grep "132 posting balanced guard" "$RUNTIME_FILE" "posting balanced is required"
check_grep "132 posting totals guard" "$RUNTIME_FILE" "posting debit and credit totals must match"
check_grep "132 posting hash guard" "$RUNTIME_FILE" "posting_hash is required"
check_grep "132 audit trace id guard" "$RUNTIME_FILE" "audit trace_id is required"
check_grep "132 audit trace posting hash guard" "$RUNTIME_FILE" "audit trace posting_hash is required"
check_grep "132 manual review reason guard" "$RUNTIME_FILE" "manual review reason is required"

check_grep "132 matched reconciliation test" "$TEST_FILE" "TestReconcileMatchedPostingVsAuditTrace"
check_grep "132 amount difference test" "$TEST_FILE" "TestReconcileDetectsAmountDifference"
check_grep "132 audit trace difference test" "$TEST_FILE" "TestReconcileDetectsAuditTracePostingHashDifference"
check_grep "132 duplicate idempotency test" "$TEST_FILE" "TestDuplicateIdempotencyRejected"
check_grep "132 tenant scoped test" "$TEST_FILE" "TestTenantScopedFindAndListing"
check_grep "132 manual review test" "$TEST_FILE" "TestRegisterManualReview"
check_grep "132 unbalanced posting test" "$TEST_FILE" "TestRejectsUnbalancedPosting"
check_grep "132 missing audit trace test" "$TEST_FILE" "TestRejectsMissingAuditTraceWhenRequired"

check_grep "132 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "132 config currency TRY" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "132 config append only result" "$CONFIG_FILE" "\"append_only_result\": true"
check_grep "132 config require audit trace" "$CONFIG_FILE" "\"require_audit_trace\": true"
check_grep "132 config manual review enabled" "$CONFIG_FILE" "\"manual_review_enabled\": true"
check_grep "132 config posting vs audit trace action" "$CONFIG_FILE" "POSTING_VS_AUDIT_TRACE"
check_grep "132 config next gate" "$CONFIG_FILE" "FAZ_3_10_1_6_TDHP_LIVE_TESTS"

if go test ./internal/erp/turkiye/tdhp/reconciliationruntime; then
  pass "132 reconciliation runtime Go test status"
else
  fail "132 reconciliation runtime Go test status"
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
# 132 — FAZ 3-10.1.5 — Reconciliation Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_1_5_RECONCILIATION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_1_5_RECONCILIATION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_1_6_READY=${NEXT_READY}

## Scope

- Reconciliation request model
- Expected document model
- Reconciliation result model
- Reconciliation difference model
- Reconciliation repository contract
- In-memory repository implementation
- Posting vs document reconciliation
- Posting vs audit trace reconciliation
- Amount difference detection
- Posting hash difference detection
- Tenant-scoped lookup/listing
- Idempotency uniqueness guard
- Reconciliation ID uniqueness guard
- Manual review register
- Ledger closure readiness decision

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 132 — FAZ 3-10.1.5 RECONCILIATION RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_1_5_RECONCILIATION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_1_5_RECONCILIATION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_1_6_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
