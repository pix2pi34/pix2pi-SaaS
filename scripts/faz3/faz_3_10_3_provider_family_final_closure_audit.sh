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

echo "===== 113 — FAZ 3-10.3 PROVIDER FAMILY FINAL CLOSURE REAL IMPLEMENTATION AUDIT START ====="

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

check_file "113 e-Fatura runtime file" "$EFATURA_RUNTIME"
check_file "113 e-Fatura test file" "$EFATURA_TEST"
check_file "113 e-Fatura config file" "$EFATURA_CONFIG"
check_file "113 e-Fatura documentation file" "$EFATURA_DOC"
check_file "113 e-Fatura evidence file" "$EFATURA_EVIDENCE"

check_file "113 e-Arşiv runtime file" "$EARSIV_RUNTIME"
check_file "113 e-Arşiv test file" "$EARSIV_TEST"
check_file "113 e-Arşiv config file" "$EARSIV_CONFIG"
check_file "113 e-Arşiv documentation file" "$EARSIV_DOC"
check_file "113 e-Arşiv evidence file" "$EARSIV_EVIDENCE"

check_file "113 e-Adisyon runtime file" "$EADISYON_RUNTIME"
check_file "113 e-Adisyon test file" "$EADISYON_TEST"
check_file "113 e-Adisyon config file" "$EADISYON_CONFIG"
check_file "113 e-Adisyon documentation file" "$EADISYON_DOC"
check_file "113 e-Adisyon evidence file" "$EADISYON_EVIDENCE"

check_grep "113 e-Fatura ProviderAdapter interface" "$EFATURA_RUNTIME" "type ProviderAdapter interface"
check_grep "113 e-Fatura SendInvoice operation" "$EFATURA_RUNTIME" "SendInvoice"
check_grep "113 e-Fatura CheckStatus operation" "$EFATURA_RUNTIME" "CheckStatus"
check_grep "113 e-Fatura CancelInvoice operation" "$EFATURA_RUNTIME" "CancelInvoice"
check_grep "113 e-Fatura DownloadUBL operation" "$EFATURA_RUNTIME" "DownloadUBL"
check_grep "113 e-Fatura production gate guard" "$EFATURA_RUNTIME" "production provider access is closed"
check_grep "113 e-Fatura tenant guard" "$EFATURA_RUNTIME" "tenant_id is required"
check_grep "113 e-Fatura idempotency guard" "$EFATURA_RUNTIME" "idempotency_key is required"
check_grep "113 e-Fatura UBL hash guard" "$EFATURA_RUNTIME" "ubl_hash is required"
check_grep "113 e-Fatura cancel reason guard" "$EFATURA_RUNTIME" "cancel reason code is required"

check_grep "113 e-Arşiv ProviderAdapter interface" "$EARSIV_RUNTIME" "type ProviderAdapter interface"
check_grep "113 e-Arşiv SendArchive operation" "$EARSIV_RUNTIME" "SendArchive"
check_grep "113 e-Arşiv CheckStatus operation" "$EARSIV_RUNTIME" "CheckStatus"
check_grep "113 e-Arşiv CancelArchive operation" "$EARSIV_RUNTIME" "CancelArchive"
check_grep "113 e-Arşiv DownloadPDF operation" "$EARSIV_RUNTIME" "DownloadPDF"
check_grep "113 e-Arşiv DownloadUBL operation" "$EARSIV_RUNTIME" "DownloadUBL"
check_grep "113 e-Arşiv production gate guard" "$EARSIV_RUNTIME" "production provider access is closed"
check_grep "113 e-Arşiv tenant guard" "$EARSIV_RUNTIME" "tenant_id is required"
check_grep "113 e-Arşiv idempotency guard" "$EARSIV_RUNTIME" "idempotency_key is required"
check_grep "113 e-Arşiv UBL hash guard" "$EARSIV_RUNTIME" "ubl_hash is required"
check_grep "113 e-Arşiv PDF hash guard" "$EARSIV_RUNTIME" "pdf_hash is required"
check_grep "113 e-Arşiv cancel reason guard" "$EARSIV_RUNTIME" "cancel reason code is required"

check_grep "113 e-Adisyon ProviderAdapter interface" "$EADISYON_RUNTIME" "type ProviderAdapter interface"
check_grep "113 e-Adisyon OpenAdisyon operation" "$EADISYON_RUNTIME" "OpenAdisyon"
check_grep "113 e-Adisyon CloseAdisyon operation" "$EADISYON_RUNTIME" "CloseAdisyon"
check_grep "113 e-Adisyon SendAdisyon operation" "$EADISYON_RUNTIME" "SendAdisyon"
check_grep "113 e-Adisyon CheckStatus operation" "$EADISYON_RUNTIME" "CheckStatus"
check_grep "113 e-Adisyon CancelAdisyon operation" "$EADISYON_RUNTIME" "CancelAdisyon"
check_grep "113 e-Adisyon DownloadPDF operation" "$EADISYON_RUNTIME" "DownloadPDF"
check_grep "113 e-Adisyon DownloadUBL operation" "$EADISYON_RUNTIME" "DownloadUBL"
check_grep "113 e-Adisyon production gate guard" "$EADISYON_RUNTIME" "production provider access is closed"
check_grep "113 e-Adisyon venue guard" "$EADISYON_RUNTIME" "venue_id is required"
check_grep "113 e-Adisyon table guard" "$EADISYON_RUNTIME" "table_no is required"
check_grep "113 e-Adisyon opened_at guard" "$EADISYON_RUNTIME" "opened_at is required"
check_grep "113 e-Adisyon closed_at guard" "$EADISYON_RUNTIME" "closed_at is required"
check_grep "113 e-Adisyon UBL hash guard" "$EADISYON_RUNTIME" "ubl_hash is required"
check_grep "113 e-Adisyon PDF hash guard" "$EADISYON_RUNTIME" "pdf_hash is required"

check_grep "113 e-Fatura real api gate closed" "$EFATURA_CONFIG" "\"real_api_gate_open\": false"
check_grep "113 e-Fatura production approved false" "$EFATURA_CONFIG" "\"production_approved\": false"
check_grep "113 e-Fatura raw secret policy" "$EFATURA_CONFIG" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"

check_grep "113 e-Arşiv real api gate closed" "$EARSIV_CONFIG" "\"real_api_gate_open\": false"
check_grep "113 e-Arşiv production approved false" "$EARSIV_CONFIG" "\"production_approved\": false"
check_grep "113 e-Arşiv raw secret policy" "$EARSIV_CONFIG" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"

check_grep "113 e-Adisyon real api gate closed" "$EADISYON_CONFIG" "\"real_api_gate_open\": false"
check_grep "113 e-Adisyon production approved false" "$EADISYON_CONFIG" "\"production_approved\": false"
check_grep "113 e-Adisyon raw secret policy" "$EADISYON_CONFIG" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"

check_grep "113 e-Fatura final evidence PASS" "$EFATURA_EVIDENCE" "FAZ_3_10_3_1_E_FATURA_PROVIDER_INTEGRATION_FINAL_STATUS=PASS"
check_grep "113 e-Arşiv final evidence PASS" "$EARSIV_EVIDENCE" "FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION_FINAL_STATUS=PASS"
check_grep "113 e-Adisyon final evidence PASS" "$EADISYON_EVIDENCE" "FAZ_3_10_3_3_E_ADISYON_PROVIDER_INTEGRATION_FINAL_STATUS=PASS"

if go test ./internal/erp/turkiye/ebelge/efatura ./internal/erp/turkiye/ebelge/earsiv ./internal/erp/turkiye/ebelge/eadisyon; then
  pass "113 provider family Go test status"
else
  fail "113 provider family Go test status"
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
# 113 — FAZ 3-10.3 — e-Belge Provider Family Final Closure Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_3_PROVIDER_FAMILY_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_3_PROVIDER_FAMILY_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_R_NEXT_STEP_READY=${NEXT_READY}

## Closed Scope

- 110 — e-Fatura provider integration
- 111 — e-Arşiv provider integration
- 112 — e-Adisyon provider integration

## Provider Family Capabilities

- e-Fatura: SendInvoice / CheckStatus / CancelInvoice / DownloadUBL
- e-Arşiv: SendArchive / CheckStatus / CancelArchive / DownloadPDF / DownloadUBL
- e-Adisyon: OpenAdisyon / CloseAdisyon / SendAdisyon / CheckStatus / CancelAdisyon / DownloadPDF / DownloadUBL

## Guardrails

- Tenant guard
- Correlation guard
- Request guard
- Idempotency guard
- UBL hash guard
- PDF hash guard where required
- Cancel reason guard
- Venue/table/adisyon guard for e-Adisyon
- Production provider real API gate closed

## Live Provider Policy

Real provider API remains closed until provider-specific live module and approvals.

## Audit Notes

Final status is derived from real files, previous evidence files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 113 — FAZ 3-10.3 PROVIDER FAMILY FINAL CLOSURE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_3_PROVIDER_FAMILY_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_3_PROVIDER_FAMILY_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_R_NEXT_STEP_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
