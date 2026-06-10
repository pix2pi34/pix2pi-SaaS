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

echo "===== 115 — FAZ 3-10.3.5 EBELGE ERROR CANCEL RETRY REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/ebelge/errorretry/error_cancel_retry.go"
TEST_FILE="internal/erp/turkiye/ebelge/errorretry/error_cancel_retry_test.go"
CONFIG_FILE="configs/faz3/ebelge/e_belge_error_cancel_retry.v1.json"
DOC_FILE="docs/faz3/ebelge/FAZ_3_10_3_5_EBELGE_ERROR_CANCEL_RETRY_RUNTIME.md"

check_file "115 error/cancel/retry runtime file" "$RUNTIME_FILE"
check_file "115 error/cancel/retry test file" "$TEST_FILE"
check_file "115 error/cancel/retry config file" "$CONFIG_FILE"
check_file "115 error/cancel/retry documentation file" "$DOC_FILE"

check_grep "115 runtime constructor" "$RUNTIME_FILE" "NewErrorCancelRetryRuntime"
check_grep "115 provider error handler" "$RUNTIME_FILE" "HandleProviderError"
check_grep "115 prepare cancel runtime" "$RUNTIME_FILE" "PrepareCancel"
check_grep "115 register cancel accepted runtime" "$RUNTIME_FILE" "RegisterCancelAccepted"
check_grep "115 retry scheduled decision" "$RUNTIME_FILE" "RETRY_SCHEDULED"
check_grep "115 DLQ decision" "$RUNTIME_FILE" "DLQ"
check_grep "115 no retry decision" "$RUNTIME_FILE" "NO_RETRY"
check_grep "115 duplicate ignored decision" "$RUNTIME_FILE" "DUPLICATE_IGNORED"
check_grep "115 manual review decision" "$RUNTIME_FILE" "MANUAL_REVIEW"
check_grep "115 retry delay function" "$RUNTIME_FILE" "retryDelaySeconds"
check_grep "115 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "115 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "115 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "115 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "115 provider document guard" "$RUNTIME_FILE" "provider_document_id is required"
check_grep "115 provider payload hash guard" "$RUNTIME_FILE" "provider_payload_hash is required"
check_grep "115 cancel reason guard" "$RUNTIME_FILE" "cancel_reason_code is required"
check_grep "115 e-Fatura document support" "$RUNTIME_FILE" "E_FATURA"
check_grep "115 e-Arşiv document support" "$RUNTIME_FILE" "E_ARSIV"
check_grep "115 e-Adisyon document support" "$RUNTIME_FILE" "E_ADISYON"

check_grep "115 config DLQ enabled" "$CONFIG_FILE" "\"dlq_enabled\": true"
check_grep "115 config manual review enabled" "$CONFIG_FILE" "\"manual_review_enabled\": true"
check_grep "115 config cancel reason required" "$CONFIG_FILE" "\"cancel_reason_required\": true"
check_grep "115 config retryable timeout" "$CONFIG_FILE" "PROVIDER_TIMEOUT"
check_grep "115 config fatal invalid UBL" "$CONFIG_FILE" "INVALID_UBL"
check_grep "115 config duplicate idempotency" "$CONFIG_FILE" "DUPLICATE_IDEMPOTENCY_KEY"

if go test ./internal/erp/turkiye/ebelge/errorretry; then
  pass "115 error/cancel/retry Go test status"
else
  fail "115 error/cancel/retry Go test status"
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
# 115 — FAZ 3-10.3.5 — e-Belge Error / Cancel / Retry Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_3_5_EBELGE_ERROR_CANCEL_RETRY_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_3_5_EBELGE_ERROR_CANCEL_RETRY_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_3_RUNTIME_FINAL_CLOSURE_READY=${NEXT_READY}

## Scope

- Provider error handler
- Retry scheduling
- DLQ decision
- Non-retryable decision
- Duplicate ignore decision
- Manual review decision
- Cancel prepare
- Cancel accepted registration
- Tenant / correlation / request / idempotency guards
- Provider document guard
- Provider payload hash guard
- Cancel reason guard
- e-Fatura / e-Arşiv / e-Adisyon support

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 115 — FAZ 3-10.3.5 EBELGE ERROR CANCEL RETRY COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_3_5_EBELGE_ERROR_CANCEL_RETRY_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_3_5_EBELGE_ERROR_CANCEL_RETRY_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_3_RUNTIME_FINAL_CLOSURE_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
