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

echo "===== 116 — FAZ 3-10.3 EBELGE RUNTIME FINAL CLOSURE REAL IMPLEMENTATION AUDIT START ====="

EFATURA_RUNTIME="internal/erp/turkiye/ebelge/efatura/efatura_provider.go"
EFATURA_TEST="internal/erp/turkiye/ebelge/efatura/efatura_provider_test.go"
EFATURA_CONFIG="configs/faz3/ebelge/e_fatura_provider_integration.v1.json"
EFATURA_DOC="docs/faz3/ebelge/FAZ_3_10_3_1_E_FATURA_PROVIDER_INTEGRATION.md"
EFATURA_EVIDENCE="docs/faz3/evidence/FAZ_3_10_3_1_E_FATURA_PROVIDER_INTEGRATION_REAL_IMPLEMENTATION_AUDIT.md"

EARSIV_RUNTIME="internal/erp/turkiye/ebelge/earsiv/earsiv_provider.go"
EARSIV_TEST="internal/erp/turkiye/ebelge/earsiv/earsiv_provider_test.go"
EARSIV_CONFIG="configs/faz3/ebelge/e_arsiv_provider_integration.v1.json"
EARSIV_DOC="docs/faz3/ebelge/FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION.md"
EARSIV_EVIDENCE="docs/faz3/evidence/FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION_REAL_IMPLEMENTATION_AUDIT.md"

EADISYON_RUNTIME="internal/erp/turkiye/ebelge/eadisyon/eadisyon_provider.go"
EADISYON_TEST="internal/erp/turkiye/ebelge/eadisyon/eadisyon_provider_test.go"
EADISYON_CONFIG="configs/faz3/ebelge/e_adisyon_provider_integration.v1.json"
EADISYON_DOC="docs/faz3/ebelge/FAZ_3_10_3_3_E_ADISYON_PROVIDER_INTEGRATION.md"
EADISYON_EVIDENCE="docs/faz3/evidence/FAZ_3_10_3_3_E_ADISYON_PROVIDER_INTEGRATION_REAL_IMPLEMENTATION_AUDIT.md"

PROVIDER_FAMILY_DOC="docs/faz3/ebelge/FAZ_3_10_3_PROVIDER_FAMILY_FINAL_CLOSURE.md"
PROVIDER_FAMILY_EVIDENCE="docs/faz3/evidence/FAZ_3_10_3_PROVIDER_FAMILY_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

STATUS_SYNC_RUNTIME="internal/erp/turkiye/ebelge/statussync/status_sync.go"
STATUS_SYNC_TEST="internal/erp/turkiye/ebelge/statussync/status_sync_test.go"
STATUS_SYNC_CONFIG="configs/faz3/ebelge/e_belge_status_sync.v1.json"
STATUS_SYNC_DOC="docs/faz3/ebelge/FAZ_3_10_3_4_EBELGE_STATUS_SYNC.md"
STATUS_SYNC_EVIDENCE="docs/faz3/evidence/FAZ_3_10_3_4_EBELGE_STATUS_SYNC_REAL_IMPLEMENTATION_AUDIT.md"

ERROR_RETRY_RUNTIME="internal/erp/turkiye/ebelge/errorretry/error_cancel_retry.go"
ERROR_RETRY_TEST="internal/erp/turkiye/ebelge/errorretry/error_cancel_retry_test.go"
ERROR_RETRY_CONFIG="configs/faz3/ebelge/e_belge_error_cancel_retry.v1.json"
ERROR_RETRY_DOC="docs/faz3/ebelge/FAZ_3_10_3_5_EBELGE_ERROR_CANCEL_RETRY_RUNTIME.md"
ERROR_RETRY_EVIDENCE="docs/faz3/evidence/FAZ_3_10_3_5_EBELGE_ERROR_CANCEL_RETRY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"

check_file "116 e-Fatura runtime file" "$EFATURA_RUNTIME"
check_file "116 e-Fatura test file" "$EFATURA_TEST"
check_file "116 e-Fatura config file" "$EFATURA_CONFIG"
check_file "116 e-Fatura documentation file" "$EFATURA_DOC"
check_file "116 e-Fatura evidence file" "$EFATURA_EVIDENCE"

check_file "116 e-Arşiv runtime file" "$EARSIV_RUNTIME"
check_file "116 e-Arşiv test file" "$EARSIV_TEST"
check_file "116 e-Arşiv config file" "$EARSIV_CONFIG"
check_file "116 e-Arşiv documentation file" "$EARSIV_DOC"
check_file "116 e-Arşiv evidence file" "$EARSIV_EVIDENCE"

check_file "116 e-Adisyon runtime file" "$EADISYON_RUNTIME"
check_file "116 e-Adisyon test file" "$EADISYON_TEST"
check_file "116 e-Adisyon config file" "$EADISYON_CONFIG"
check_file "116 e-Adisyon documentation file" "$EADISYON_DOC"
check_file "116 e-Adisyon evidence file" "$EADISYON_EVIDENCE"

check_file "116 provider family closure documentation file" "$PROVIDER_FAMILY_DOC"
check_file "116 provider family closure evidence file" "$PROVIDER_FAMILY_EVIDENCE"

check_file "116 status sync runtime file" "$STATUS_SYNC_RUNTIME"
check_file "116 status sync test file" "$STATUS_SYNC_TEST"
check_file "116 status sync config file" "$STATUS_SYNC_CONFIG"
check_file "116 status sync documentation file" "$STATUS_SYNC_DOC"
check_file "116 status sync evidence file" "$STATUS_SYNC_EVIDENCE"

check_file "116 error/cancel/retry runtime file" "$ERROR_RETRY_RUNTIME"
check_file "116 error/cancel/retry test file" "$ERROR_RETRY_TEST"
check_file "116 error/cancel/retry config file" "$ERROR_RETRY_CONFIG"
check_file "116 error/cancel/retry documentation file" "$ERROR_RETRY_DOC"
check_file "116 error/cancel/retry evidence file" "$ERROR_RETRY_EVIDENCE"

check_grep "116 e-Fatura final evidence PASS" "$EFATURA_EVIDENCE" "FAZ_3_10_3_1_E_FATURA_PROVIDER_INTEGRATION_FINAL_STATUS=PASS"
check_grep "116 e-Arşiv final evidence PASS" "$EARSIV_EVIDENCE" "FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION_FINAL_STATUS=PASS"
check_grep "116 e-Adisyon final evidence PASS" "$EADISYON_EVIDENCE" "FAZ_3_10_3_3_E_ADISYON_PROVIDER_INTEGRATION_FINAL_STATUS=PASS"
check_grep "116 provider family final evidence PASS" "$PROVIDER_FAMILY_EVIDENCE" "FAZ_3_10_3_PROVIDER_FAMILY_FINAL_STATUS=PASS"
check_grep "116 status sync final evidence PASS" "$STATUS_SYNC_EVIDENCE" "FAZ_3_10_3_4_EBELGE_STATUS_SYNC_FINAL_STATUS=PASS"
check_grep "116 error/cancel/retry final evidence PASS" "$ERROR_RETRY_EVIDENCE" "FAZ_3_10_3_5_EBELGE_ERROR_CANCEL_RETRY_RUNTIME_FINAL_STATUS=PASS"

check_grep "116 e-Fatura ProviderAdapter" "$EFATURA_RUNTIME" "type ProviderAdapter interface"
check_grep "116 e-Arşiv ProviderAdapter" "$EARSIV_RUNTIME" "type ProviderAdapter interface"
check_grep "116 e-Adisyon ProviderAdapter" "$EADISYON_RUNTIME" "type ProviderAdapter interface"

check_grep "116 e-Fatura production gate closed" "$EFATURA_RUNTIME" "production provider access is closed"
check_grep "116 e-Arşiv production gate closed" "$EARSIV_RUNTIME" "production provider access is closed"
check_grep "116 e-Adisyon production gate closed" "$EADISYON_RUNTIME" "production provider access is closed"

check_grep "116 e-Fatura real api gate false" "$EFATURA_CONFIG" "\"real_api_gate_open\": false"
check_grep "116 e-Arşiv real api gate false" "$EARSIV_CONFIG" "\"real_api_gate_open\": false"
check_grep "116 e-Adisyon real api gate false" "$EADISYON_CONFIG" "\"real_api_gate_open\": false"

check_grep "116 e-Fatura production approved false" "$EFATURA_CONFIG" "\"production_approved\": false"
check_grep "116 e-Arşiv production approved false" "$EARSIV_CONFIG" "\"production_approved\": false"
check_grep "116 e-Adisyon production approved false" "$EADISYON_CONFIG" "\"production_approved\": false"

check_grep "116 e-Fatura raw secret policy" "$EFATURA_CONFIG" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"
check_grep "116 e-Arşiv raw secret policy" "$EARSIV_CONFIG" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"
check_grep "116 e-Adisyon raw secret policy" "$EADISYON_CONFIG" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"

check_grep "116 status sync callback handler" "$STATUS_SYNC_RUNTIME" "HandleCallback"
check_grep "116 status sync poll handler" "$STATUS_SYNC_RUNTIME" "HandlePollResult"
check_grep "116 status sync poll planner" "$STATUS_SYNC_RUNTIME" "BuildPollPlan"
check_grep "116 status sync callback signature guard" "$STATUS_SYNC_RUNTIME" "callback signature is required"

check_grep "116 error retry provider error handler" "$ERROR_RETRY_RUNTIME" "HandleProviderError"
check_grep "116 error retry cancel prepare" "$ERROR_RETRY_RUNTIME" "PrepareCancel"
check_grep "116 error retry DLQ decision" "$ERROR_RETRY_RUNTIME" "DLQ"
check_grep "116 error retry manual review decision" "$ERROR_RETRY_RUNTIME" "MANUAL_REVIEW"
check_grep "116 error retry duplicate decision" "$ERROR_RETRY_RUNTIME" "DUPLICATE_IGNORED"

check_grep "116 tenant guard in status sync" "$STATUS_SYNC_RUNTIME" "tenant_id is required"
check_grep "116 idempotency guard in status sync" "$STATUS_SYNC_RUNTIME" "idempotency_key is required"
check_grep "116 provider payload hash guard in status sync" "$STATUS_SYNC_RUNTIME" "provider_payload_hash is required"

check_grep "116 tenant guard in error retry" "$ERROR_RETRY_RUNTIME" "tenant_id is required"
check_grep "116 idempotency guard in error retry" "$ERROR_RETRY_RUNTIME" "idempotency_key is required"
check_grep "116 provider payload hash guard in error retry" "$ERROR_RETRY_RUNTIME" "provider_payload_hash is required"
check_grep "116 cancel reason guard in error retry" "$ERROR_RETRY_RUNTIME" "cancel_reason_code is required"

check_grep "116 status sync config callback signature required" "$STATUS_SYNC_CONFIG" "\"callback_signature_required\": true"
check_grep "116 status sync config poll enabled" "$STATUS_SYNC_CONFIG" "\"poll_enabled\": true"
check_grep "116 error retry config DLQ enabled" "$ERROR_RETRY_CONFIG" "\"dlq_enabled\": true"
check_grep "116 error retry config manual review enabled" "$ERROR_RETRY_CONFIG" "\"manual_review_enabled\": true"
check_grep "116 error retry config cancel reason required" "$ERROR_RETRY_CONFIG" "\"cancel_reason_required\": true"

if go test \
  ./internal/erp/turkiye/ebelge/efatura \
  ./internal/erp/turkiye/ebelge/earsiv \
  ./internal/erp/turkiye/ebelge/eadisyon \
  ./internal/erp/turkiye/ebelge/statussync \
  ./internal/erp/turkiye/ebelge/errorretry; then
  pass "116 e-Belge runtime family Go test status"
else
  fail "116 e-Belge runtime family Go test status"
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
# 116 — FAZ 3-10.3 — e-Belge Runtime Final Closure Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_3_EBELGE_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_3_EBELGE_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}
- FAZ_3_10_4_READY=${NEXT_READY}

## Closed Scope

- 110 — e-Fatura provider integration
- 111 — e-Arşiv provider integration
- 112 — e-Adisyon provider integration
- 113 — Provider family final closure
- 114 — Callback / poll status sync
- 115 — Error / cancel / retry runtime

## Runtime Packages

- internal/erp/turkiye/ebelge/efatura
- internal/erp/turkiye/ebelge/earsiv
- internal/erp/turkiye/ebelge/eadisyon
- internal/erp/turkiye/ebelge/statussync
- internal/erp/turkiye/ebelge/errorretry

## Guardrails

- Tenant guard
- Correlation guard
- Request guard
- Idempotency guard
- Provider document guard
- Provider payload hash guard
- Callback signature guard
- UBL hash guard
- PDF hash guard where required
- Cancel reason guard
- Retry / DLQ / manual review / duplicate decision guards
- Production provider real API gate closed

## Live Provider Policy

Real provider API remains closed until provider-specific live module and approvals.

## Audit Notes

Final status is derived from real files, previous evidence files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 116 — FAZ 3-10.3 EBELGE RUNTIME FINAL CLOSURE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_3_EBELGE_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_3_EBELGE_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}"
echo "FAZ_3_10_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
