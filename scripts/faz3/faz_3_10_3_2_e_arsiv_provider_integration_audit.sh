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

echo "===== 111 — FAZ 3-10.3.2 E-ARSIV PROVIDER INTEGRATION REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/ebelge/earsiv/earsiv_provider.go"
TEST_FILE="internal/erp/turkiye/ebelge/earsiv/earsiv_provider_test.go"
CONFIG_FILE="configs/faz3/ebelge/e_arsiv_provider_integration.v1.json"
DOC_FILE="docs/faz3/ebelge/FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION.md"

check_file "111 e-Arşiv runtime file" "$RUNTIME_FILE"
check_file "111 e-Arşiv test file" "$TEST_FILE"
check_file "111 e-Arşiv config file" "$CONFIG_FILE"
check_file "111 e-Arşiv documentation file" "$DOC_FILE"

check_grep "111 ProviderAdapter interface" "$RUNTIME_FILE" "type ProviderAdapter interface"
check_grep "111 SendArchive operation" "$RUNTIME_FILE" "SendArchive"
check_grep "111 CheckStatus operation" "$RUNTIME_FILE" "CheckStatus"
check_grep "111 CancelArchive operation" "$RUNTIME_FILE" "CancelArchive"
check_grep "111 DownloadPDF operation" "$RUNTIME_FILE" "DownloadPDF"
check_grep "111 DownloadUBL operation" "$RUNTIME_FILE" "DownloadUBL"
check_grep "111 production gate guard" "$RUNTIME_FILE" "production provider access is closed"
check_grep "111 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "111 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "111 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "111 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "111 UBL hash guard" "$RUNTIME_FILE" "ubl_hash is required"
check_grep "111 PDF hash guard" "$RUNTIME_FILE" "pdf_hash is required"
check_grep "111 cancel reason guard" "$RUNTIME_FILE" "cancel reason code is required"

check_grep "111 config real api gate closed" "$CONFIG_FILE" "\"real_api_gate_open\": false"
check_grep "111 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "111 config raw secret policy" "$CONFIG_FILE" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"

if go test ./internal/erp/turkiye/ebelge/earsiv; then
  pass "111 e-Arşiv Go test status"
else
  fail "111 e-Arşiv Go test status"
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
# 111 — FAZ 3-10.3.2 — e-Arşiv Provider Integration Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_3_3_READY=${NEXT_READY}

## Scope

- Provider config model
- Provider request / response model
- ProviderAdapter interface
- SendArchive
- CheckStatus
- CancelArchive
- DownloadPDF
- DownloadUBL
- Production real API gate closed
- Tenant / correlation / request / idempotency guards
- UBL hash guard
- PDF hash guard
- Cancel reason guard
- Simulation-safe provider runtime

## Live Provider Policy

Real provider API remains closed until provider-specific live module and approvals.

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 111 — FAZ 3-10.3.2 E-ARSIV PROVIDER INTEGRATION COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_3_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
