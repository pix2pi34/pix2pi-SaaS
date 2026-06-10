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

echo "===== 114 — FAZ 3-10.3.4 EBELGE STATUS SYNC REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/ebelge/statussync/status_sync.go"
TEST_FILE="internal/erp/turkiye/ebelge/statussync/status_sync_test.go"
CONFIG_FILE="configs/faz3/ebelge/e_belge_status_sync.v1.json"
DOC_FILE="docs/faz3/ebelge/FAZ_3_10_3_4_EBELGE_STATUS_SYNC.md"

check_file "114 status sync runtime file" "$RUNTIME_FILE"
check_file "114 status sync test file" "$TEST_FILE"
check_file "114 status sync config file" "$CONFIG_FILE"
check_file "114 status sync documentation file" "$DOC_FILE"

check_grep "114 HandleCallback runtime" "$RUNTIME_FILE" "HandleCallback"
check_grep "114 HandlePollResult runtime" "$RUNTIME_FILE" "HandlePollResult"
check_grep "114 BuildPollPlan runtime" "$RUNTIME_FILE" "BuildPollPlan"
check_grep "114 callback signature guard" "$RUNTIME_FILE" "callback signature is required"
check_grep "114 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "114 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "114 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "114 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "114 provider document guard" "$RUNTIME_FILE" "provider_document_id is required"
check_grep "114 provider payload hash guard" "$RUNTIME_FILE" "provider_payload_hash is required"
check_grep "114 status canonicalize function" "$RUNTIME_FILE" "func canonicalize"
check_grep "114 retry scheduling behavior" "$RUNTIME_FILE" "RetryScheduled"
check_grep "114 e-Fatura document support" "$RUNTIME_FILE" "E_FATURA"
check_grep "114 e-Arşiv document support" "$RUNTIME_FILE" "E_ARSIV"
check_grep "114 e-Adisyon document support" "$RUNTIME_FILE" "E_ADISYON"

check_grep "114 config callback signature required" "$CONFIG_FILE" "\"callback_signature_required\": true"
check_grep "114 config poll enabled" "$CONFIG_FILE" "\"poll_enabled\": true"
check_grep "114 config e-Fatura allowed" "$CONFIG_FILE" "E_FATURA"
check_grep "114 config e-Arşiv allowed" "$CONFIG_FILE" "E_ARSIV"
check_grep "114 config e-Adisyon allowed" "$CONFIG_FILE" "E_ADISYON"

if go test ./internal/erp/turkiye/ebelge/statussync; then
  pass "114 status sync Go test status"
else
  fail "114 status sync Go test status"
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
# 114 — FAZ 3-10.3.4 — e-Belge Status Sync Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_3_4_EBELGE_STATUS_SYNC_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_3_4_EBELGE_STATUS_SYNC_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_3_5_READY=${NEXT_READY}

## Scope

- Callback status sync
- Poll status sync
- Poll candidate planning
- Provider status canonicalization
- Tenant / correlation / request / idempotency guards
- Provider document guard
- Provider payload hash guard
- Callback signature guard
- Retry scheduling hint
- e-Fatura / e-Arşiv / e-Adisyon support

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 114 — FAZ 3-10.3.4 EBELGE STATUS SYNC COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_3_4_EBELGE_STATUS_SYNC_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_3_4_EBELGE_STATUS_SYNC_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_3_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
