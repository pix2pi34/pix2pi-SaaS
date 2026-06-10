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

echo "===== 117 — FAZ 3-10.7.1 POS PROVIDER RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/payment/pos/pos_provider.go"
TEST_FILE="internal/erp/turkiye/payment/pos/pos_provider_test.go"
CONFIG_FILE="configs/faz3/payment/pos_provider_runtime.v1.json"
DOC_FILE="docs/faz3/payment/FAZ_3_10_7_1_POS_PROVIDER_RUNTIME.md"

check_file "117 POS provider runtime file" "$RUNTIME_FILE"
check_file "117 POS provider test file" "$TEST_FILE"
check_file "117 POS provider config file" "$CONFIG_FILE"
check_file "117 POS provider documentation file" "$DOC_FILE"

check_grep "117 POSProviderAdapter interface" "$RUNTIME_FILE" "type POSProviderAdapter interface"
check_grep "117 Authorize operation" "$RUNTIME_FILE" "Authorize"
check_grep "117 Capture operation" "$RUNTIME_FILE" "Capture"
check_grep "117 Sale operation" "$RUNTIME_FILE" "Sale"
check_grep "117 Refund operation" "$RUNTIME_FILE" "Refund"
check_grep "117 Void operation" "$RUNTIME_FILE" "Void"
check_grep "117 CheckStatus operation" "$RUNTIME_FILE" "CheckStatus"
check_grep "117 ThreeDSInit operation" "$RUNTIME_FILE" "ThreeDSInit"
check_grep "117 ThreeDSComplete operation" "$RUNTIME_FILE" "ThreeDSComplete"
check_grep "117 production real payment gate guard" "$RUNTIME_FILE" "production real payment access is closed"
check_grep "117 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "117 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "117 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "117 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "117 payment transaction guard" "$RUNTIME_FILE" "payment_transaction_id is required"
check_grep "117 merchant guard" "$RUNTIME_FILE" "merchant_id is required"
check_grep "117 terminal guard" "$RUNTIME_FILE" "terminal_id is required"
check_grep "117 provider mismatch guard" "$RUNTIME_FILE" "provider_code mismatch"
check_grep "117 card token guard" "$RUNTIME_FILE" "card_token is required"
check_grep "117 masked PAN guard" "$RUNTIME_FILE" "masked_card_pan must be masked"
check_grep "117 refund reason guard" "$RUNTIME_FILE" "refund_reason_code is required"
check_grep "117 void reason guard" "$RUNTIME_FILE" "void_reason_code is required"

check_grep "117 config real payment gate closed" "$CONFIG_FILE" "\"real_payment_gate_open\": false"
check_grep "117 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "117 config raw secret policy" "$CONFIG_FILE" "CREDENTIAL_REF_ONLY_NO_RAW_SECRET"
check_grep "117 config authorize operation" "$CONFIG_FILE" "AUTHORIZE"
check_grep "117 config 3DS operation" "$CONFIG_FILE" "THREE_DS_INIT"

if go test ./internal/erp/turkiye/payment/pos; then
  pass "117 POS provider Go test status"
else
  fail "117 POS provider Go test status"
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
# 117 — FAZ 3-10.7.1 — POS Provider Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_7_1_POS_PROVIDER_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_7_1_POS_PROVIDER_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_7_2_READY=${NEXT_READY}

## Scope

- POS provider config model
- POS request / response model
- POSProviderAdapter interface
- Authorize / capture / sale
- Refund / void / status check
- 3DS init / complete
- Production real payment gate closed
- Tenant / correlation / request / idempotency guards
- Merchant / terminal guards
- Provider mismatch guard
- Card token / masked PAN guards
- Refund / void reason guards

## Live Payment Policy

Real bank/POS payment remains closed until provider-specific live module and approvals.

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 117 — FAZ 3-10.7.1 POS PROVIDER RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_7_1_POS_PROVIDER_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_7_1_POS_PROVIDER_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_7_2_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
