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

echo "===== 130 — FAZ 3-10.1.3 DOCUMENT BASED POSTING RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tdhp/postingruntime/document_based_posting_runtime.go"
TEST_FILE="internal/erp/turkiye/tdhp/postingruntime/document_based_posting_runtime_test.go"
CONFIG_FILE="configs/faz3/tdhp/document_based_posting_runtime.v1.json"
DOC_FILE="docs/faz3/tdhp/FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME.md"

check_file "130 document based posting runtime file" "$RUNTIME_FILE"
check_file "130 document based posting test file" "$TEST_FILE"
check_file "130 document based posting config file" "$CONFIG_FILE"
check_file "130 document based posting documentation file" "$DOC_FILE"

check_grep "130 runtime constructor" "$RUNTIME_FILE" "NewDocumentPostingRuntime"
check_grep "130 prepare posting runtime" "$RUNTIME_FILE" "PreparePosting"
check_grep "130 post document runtime" "$RUNTIME_FILE" "PostDocument"
check_grep "130 reverse posting runtime" "$RUNTIME_FILE" "ReversePosting"
check_grep "130 find posting runtime" "$RUNTIME_FILE" "FindPosting"
check_grep "130 list document postings runtime" "$RUNTIME_FILE" "ListDocumentPostings"

check_grep "130 posting request model" "$RUNTIME_FILE" "type PostingRequest"
check_grep "130 posting entry model" "$RUNTIME_FILE" "type PostingEntry"
check_grep "130 posting line model" "$RUNTIME_FILE" "type PostingLine"
check_grep "130 reversal request model" "$RUNTIME_FILE" "type ReversalRequest"
check_grep "130 repository interface" "$RUNTIME_FILE" "type PostingRepository interface"
check_grep "130 in-memory repository" "$RUNTIME_FILE" "type InMemoryPostingRepository"

check_grep "130 append operation" "$RUNTIME_FILE" "Append(entry PostingEntry)"
check_grep "130 find by posting id operation" "$RUNTIME_FILE" "FindByPostingID"
check_grep "130 find by idempotency operation" "$RUNTIME_FILE" "FindByIdempotencyKey"
check_grep "130 list by tenant operation" "$RUNTIME_FILE" "ListByTenant"
check_grep "130 list by document operation" "$RUNTIME_FILE" "ListByDocument"

check_grep "130 voucher pipeline import" "$RUNTIME_FILE" "voucherpipeline"
check_grep "130 append-only ledger guard" "$RUNTIME_FILE" "append_only_ledger must be enabled"
check_grep "130 duplicate posting id guard" "$RUNTIME_FILE" "posting_id already exists"
check_grep "130 duplicate idempotency guard" "$RUNTIME_FILE" "idempotency_key already exists"
check_grep "130 tenant posting key" "$RUNTIME_FILE" "tenantPostingKey"
check_grep "130 tenant idempotency key" "$RUNTIME_FILE" "tenantIdempotencyKey"
check_grep "130 posting hash builder" "$RUNTIME_FILE" "buildPostingHash"

check_grep "130 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "130 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "130 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "130 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "130 posting id guard" "$RUNTIME_FILE" "posting_id is required"
check_grep "130 posting source guard" "$RUNTIME_FILE" "posting_source is not allowed"
check_grep "130 voucher id guard" "$RUNTIME_FILE" "voucher_id is required"
check_grep "130 voucher no guard" "$RUNTIME_FILE" "voucher_no is required"
check_grep "130 voucher document id guard" "$RUNTIME_FILE" "voucher document_id is required"
check_grep "130 voucher document no guard" "$RUNTIME_FILE" "voucher document_no is required"
check_grep "130 voucher currency guard" "$RUNTIME_FILE" "voucher currency_code mismatch"
check_grep "130 voucher posting ready guard" "$RUNTIME_FILE" "voucher posting_ready is required"
check_grep "130 voucher balanced guard" "$RUNTIME_FILE" "voucher balanced is required"
check_grep "130 debit credit totals guard" "$RUNTIME_FILE" "voucher debit and credit totals must match"
check_grep "130 voucher lines guard" "$RUNTIME_FILE" "voucher lines are required"
check_grep "130 line account code guard" "$RUNTIME_FILE" "voucher line account_code is required"
check_grep "130 line debit credit exclusive guard" "$RUNTIME_FILE" "voucher line cannot have both debit and credit"
check_grep "130 audit trace guard" "$RUNTIME_FILE" "voucher audit_trace_id is required"
check_grep "130 reversal reason guard" "$RUNTIME_FILE" "reason_code is required"

check_grep "130 prepare posting test" "$TEST_FILE" "TestPreparePostingFromVoucher"
check_grep "130 post document test" "$TEST_FILE" "TestPostDocumentPersistsEntry"
check_grep "130 duplicate idempotency test" "$TEST_FILE" "TestPostDocumentRejectsDuplicateIdempotency"
check_grep "130 tenant scoped listing test" "$TEST_FILE" "TestListDocumentPostingsIsTenantScoped"
check_grep "130 reversal test" "$TEST_FILE" "TestReversePostingMirrorsDebitCredit"
check_grep "130 unbalanced voucher test" "$TEST_FILE" "TestRejectsUnbalancedVoucher"
check_grep "130 posting ready guard test" "$TEST_FILE" "TestRejectsVoucherWithoutPostingReady"
check_grep "130 invalid posting source test" "$TEST_FILE" "TestRejectsInvalidPostingSource"

check_grep "130 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "130 config currency TRY" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "130 config append only ledger" "$CONFIG_FILE" "\"append_only_ledger\": true"
check_grep "130 config allow reversal" "$CONFIG_FILE" "\"allow_reversal\": true"
check_grep "130 config voucher pipeline source" "$CONFIG_FILE" "REAL_VOUCHER_PIPELINE"
check_grep "130 config next gate" "$CONFIG_FILE" "FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE"

if go test ./internal/erp/turkiye/tdhp/postingruntime; then
  pass "130 document based posting Go test status"
else
  fail "130 document based posting Go test status"
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
# 130 — FAZ 3-10.1.3 — Document Based Posting Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_1_4_READY=${NEXT_READY}

## Scope

- Posting request model
- Posting entry model
- Posting line model
- Posting repository contract
- In-memory repository implementation
- Prepare posting
- Post document
- Reverse posting
- Tenant-scoped lookup
- Tenant-scoped document listing
- Idempotency uniqueness guard
- Posting ID uniqueness guard
- Voucher posting-ready guard
- Voucher balanced guard
- Debit / credit totals guard
- Line account guard
- Audit trace guard
- Append-only ledger guard

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 130 — FAZ 3-10.1.3 DOCUMENT BASED POSTING RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_1_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
