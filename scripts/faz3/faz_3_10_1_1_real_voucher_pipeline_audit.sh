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

echo "===== 128 — FAZ 3-10.1.1 REAL VOUCHER PIPELINE REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tdhp/voucherpipeline/real_voucher_pipeline.go"
TEST_FILE="internal/erp/turkiye/tdhp/voucherpipeline/real_voucher_pipeline_test.go"
CONFIG_FILE="configs/faz3/tdhp/real_voucher_pipeline.v1.json"
DOC_FILE="docs/faz3/tdhp/FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE.md"

check_file "128 real voucher pipeline runtime file" "$RUNTIME_FILE"
check_file "128 real voucher pipeline test file" "$TEST_FILE"
check_file "128 real voucher pipeline config file" "$CONFIG_FILE"
check_file "128 real voucher pipeline documentation file" "$DOC_FILE"

check_grep "128 runtime constructor" "$RUNTIME_FILE" "NewVoucherPipelineRuntime"
check_grep "128 build voucher runtime" "$RUNTIME_FILE" "BuildVoucher"
check_grep "128 source document model" "$RUNTIME_FILE" "type SourceDocument"
check_grep "128 voucher model" "$RUNTIME_FILE" "type Voucher"
check_grep "128 voucher line model" "$RUNTIME_FILE" "type VoucherLine"
check_grep "128 account mapping model" "$RUNTIME_FILE" "type AccountMapping"
check_grep "128 default TR account mapping" "$RUNTIME_FILE" "DefaultTRAccountMapping"
check_grep "128 source document validation" "$RUNTIME_FILE" "validateSourceDocument"

check_grep "128 sales invoice line builder" "$RUNTIME_FILE" "buildSalesInvoiceLines"
check_grep "128 purchase invoice line builder" "$RUNTIME_FILE" "buildPurchaseInvoiceLines"
check_grep "128 payment collection line builder" "$RUNTIME_FILE" "buildPaymentCollectionLines"
check_grep "128 sales refund line builder" "$RUNTIME_FILE" "buildSalesRefundLines"
check_grep "128 purchase refund line builder" "$RUNTIME_FILE" "buildPurchaseRefundLines"
check_grep "128 opening balance line builder" "$RUNTIME_FILE" "buildOpeningBalanceLines"
check_grep "128 voucher assembler" "$RUNTIME_FILE" "assembleVoucher"

check_grep "128 stage input validated" "$RUNTIME_FILE" "INPUT_VALIDATED"
check_grep "128 stage account mapped" "$RUNTIME_FILE" "ACCOUNT_MAPPED"
check_grep "128 stage lines built" "$RUNTIME_FILE" "LINES_BUILT"
check_grep "128 stage balanced" "$RUNTIME_FILE" "BALANCED"
check_grep "128 stage posting ready" "$RUNTIME_FILE" "POSTING_READY"

check_grep "128 TDHP 120 account trace" "$RUNTIME_FILE" "120"
check_grep "128 TDHP 600 account trace" "$RUNTIME_FILE" "600"
check_grep "128 TDHP 391 account trace" "$RUNTIME_FILE" "391"
check_grep "128 TDHP 191 account trace" "$RUNTIME_FILE" "191"
check_grep "128 TDHP 320 account trace" "$RUNTIME_FILE" "320"
check_grep "128 TDHP 102 account trace" "$RUNTIME_FILE" "102"
check_grep "128 TDHP 153 account trace" "$RUNTIME_FILE" "153"
check_grep "128 TDHP 610 account trace" "$RUNTIME_FILE" "610"

check_grep "128 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "128 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "128 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "128 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "128 document id guard" "$RUNTIME_FILE" "document_id is required"
check_grep "128 document no guard" "$RUNTIME_FILE" "document_no is required"
check_grep "128 document date guard" "$RUNTIME_FILE" "document_date is required"
check_grep "128 party id guard" "$RUNTIME_FILE" "party_id is required"
check_grep "128 party tax no guard" "$RUNTIME_FILE" "party_tax_no is required"
check_grep "128 gross amount guard" "$RUNTIME_FILE" "gross_amount_kurus must be positive"
check_grep "128 net plus tax gross guard" "$RUNTIME_FILE" "net_amount_kurus plus tax_amount_kurus must equal gross_amount_kurus"
check_grep "128 currency guard" "$RUNTIME_FILE" "currency_code mismatch"
check_grep "128 source system guard" "$RUNTIME_FILE" "source_system is required"
check_grep "128 balance guard" "$RUNTIME_FILE" "VOUCHER_NOT_BALANCED"
check_grep "128 audit trace id" "$RUNTIME_FILE" "audit-trace"

check_grep "128 sales invoice test" "$TEST_FILE" "TestBuildSalesInvoiceVoucherBalancedAndPostingReady"
check_grep "128 purchase invoice test" "$TEST_FILE" "TestBuildPurchaseInvoiceVoucherBalanced"
check_grep "128 payment collection test" "$TEST_FILE" "TestBuildPaymentCollectionVoucherBalanced"
check_grep "128 sales refund test" "$TEST_FILE" "TestBuildSalesRefundVoucherBalanced"
check_grep "128 purchase refund test" "$TEST_FILE" "TestBuildPurchaseRefundVoucherBalanced"
check_grep "128 amount mismatch test" "$TEST_FILE" "TestBuildVoucherRejectsAmountMismatch"
check_grep "128 currency mismatch test" "$TEST_FILE" "TestBuildVoucherRejectsCurrencyMismatch"
check_grep "128 invalid mapping test" "$TEST_FILE" "TestRuntimeRejectsInvalidAccountMapping"

check_grep "128 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "128 config TRY currency" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "128 config strict balance" "$CONFIG_FILE" "\"strict_balance_required\": true"
check_grep "128 config 120 account" "$CONFIG_FILE" "120.01"
check_grep "128 config 600 account" "$CONFIG_FILE" "600.01"
check_grep "128 config 391 account" "$CONFIG_FILE" "391.01.20"
check_grep "128 config 191 account" "$CONFIG_FILE" "191.01.20"
check_grep "128 config next gate" "$CONFIG_FILE" "FAZ_3_10_1_2_CHART_OF_ACCOUNTS_LIVE_VERSION_SWITCH"

if go test ./internal/erp/turkiye/tdhp/voucherpipeline; then
  pass "128 real voucher pipeline Go test status"
else
  fail "128 real voucher pipeline Go test status"
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
# 128 — FAZ 3-10.1.1 — Real Voucher Pipeline Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_1_2_READY=${NEXT_READY}

## Scope

- Source document validation
- TDHP account mapping
- Sales invoice voucher generation
- Purchase invoice voucher generation
- Payment collection voucher generation
- Sales refund voucher generation
- Purchase refund voucher generation
- Opening balance voucher generation
- Debit / credit balancing
- Posting-ready decision
- Audit trace ID generation
- Tenant / correlation / request / idempotency guards
- Party trace guard
- Tax trace guard
- TRY currency guard
- TDHP account prefix validation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 128 — FAZ 3-10.1.1 REAL VOUCHER PIPELINE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_1_2_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
