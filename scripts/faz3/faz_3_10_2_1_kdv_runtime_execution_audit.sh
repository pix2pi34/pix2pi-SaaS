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

echo "===== 124 — FAZ 3-10.2.1 KDV RUNTIME EXECUTION REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tax/kdv/kdv_runtime.go"
TEST_FILE="internal/erp/turkiye/tax/kdv/kdv_runtime_test.go"
CONFIG_FILE="configs/faz3/tax/kdv_runtime_execution.v1.json"
DOC_FILE="docs/faz3/tax/FAZ_3_10_2_1_KDV_RUNTIME_EXECUTION.md"

check_file "124 KDV runtime file" "$RUNTIME_FILE"
check_file "124 KDV test file" "$TEST_FILE"
check_file "124 KDV config file" "$CONFIG_FILE"
check_file "124 KDV documentation file" "$DOC_FILE"

check_grep "124 runtime constructor" "$RUNTIME_FILE" "NewKDVRuntime"
check_grep "124 execute function" "$RUNTIME_FILE" "func (r \\*KDVRuntime) Execute"
check_grep "124 KDV rule model" "$RUNTIME_FILE" "type KDVRule"
check_grep "124 KDV request model" "$RUNTIME_FILE" "type KDVRequest"
check_grep "124 KDV result model" "$RUNTIME_FILE" "type KDVResult"
check_grep "124 active rule version guard" "$RUNTIME_FILE" "active_rule_version is required"
check_grep "124 effective date guard" "$RUNTIME_FILE" "KDV_RULE_NOT_EFFECTIVE"
check_grep "124 BPS calculation" "$RUNTIME_FILE" "calculateBps"
check_grep "124 output KDV direction" "$RUNTIME_FILE" "OUTPUT_KDV"
check_grep "124 input KDV direction" "$RUNTIME_FILE" "INPUT_KDV"
check_grep "124 return KDV direction" "$RUNTIME_FILE" "RETURN_KDV"
check_grep "124 KDV 20 rate support" "$RUNTIME_FILE" "KDV_20"
check_grep "124 KDV 10 rate support" "$RUNTIME_FILE" "KDV_10"
check_grep "124 KDV zero rate support" "$RUNTIME_FILE" "KDV_0"
check_grep "124 zero rated calculation status" "$RUNTIME_FILE" "ZERO_RATED"
check_grep "124 KDV exemption path" "$RUNTIME_FILE" "KDV_EXEMPTION_APPLIED"
check_grep "124 KDV exemption not allowed guard" "$RUNTIME_FILE" "KDV_EXEMPTION_NOT_ALLOWED"
check_grep "124 reverse charge guard" "$RUNTIME_FILE" "KDV_REVERSE_CHARGE_NOT_ALLOWED"
check_grep "124 TDHP output account sample" "$RUNTIME_FILE" "391"
check_grep "124 TDHP input account sample" "$RUNTIME_FILE" "191"

check_grep "124 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "124 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "124 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "124 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "124 document id guard" "$RUNTIME_FILE" "document_id is required"
check_grep "124 party id guard" "$RUNTIME_FILE" "party_id is required"
check_grep "124 party tax no guard" "$RUNTIME_FILE" "party_tax_no is required"
check_grep "124 gross amount guard" "$RUNTIME_FILE" "gross_amount_kurus must be positive"
check_grep "124 net amount guard" "$RUNTIME_FILE" "net_amount_kurus must be positive"
check_grep "124 tax base guard" "$RUNTIME_FILE" "tax_base_amount_kurus must be positive"
check_grep "124 tax base cannot exceed net guard" "$RUNTIME_FILE" "tax_base_amount_kurus cannot exceed net_amount_kurus"
check_grep "124 net cannot exceed gross guard" "$RUNTIME_FILE" "net_amount_kurus cannot exceed gross_amount_kurus"
check_grep "124 currency guard" "$RUNTIME_FILE" "currency_code mismatch"
check_grep "124 exemption reason guard" "$RUNTIME_FILE" "exemption_reason is required when exemption_code is present"

check_grep "124 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "124 config active rule version" "$CONFIG_FILE" "TR_KDV_2026_V1"
check_grep "124 config default currency TRY" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "124 config KDV 20" "$CONFIG_FILE" "KDV_20"
check_grep "124 config KDV 10" "$CONFIG_FILE" "KDV_10"
check_grep "124 config KDV 0" "$CONFIG_FILE" "KDV_0"
check_grep "124 config output account 391" "$CONFIG_FILE" "391.01.20"
check_grep "124 config input account 191" "$CONFIG_FILE" "191.01.20"
check_grep "124 config next gate" "$CONFIG_FILE" "FAZ_3_10_2_4_TAX_RULE_VERSION_ROLLOUT"

if go test ./internal/erp/turkiye/tax/kdv; then
  pass "124 KDV Go test status"
else
  fail "124 KDV Go test status"
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
# 124 — FAZ 3-10.2.1 — KDV Runtime Execution Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_2_1_KDV_RUNTIME_EXECUTION_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_2_1_KDV_RUNTIME_EXECUTION_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_2_4_READY=${NEXT_READY}

## Scope

- KDV runtime config
- KDV rule model
- KDV request / result model
- Active rule version guard
- Effective date guard
- Output KDV
- Input KDV
- Return KDV
- KDV 20 / 10 / 0 rate support
- BPS KDV calculation
- KDV exemption path
- Reverse charge guard
- TDHP account routing
- Tenant / correlation / request / idempotency guards
- Document / party / tax no guards
- Gross / net / tax base guards
- TRY currency guard

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 124 — FAZ 3-10.2.1 KDV RUNTIME EXECUTION COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_2_1_KDV_RUNTIME_EXECUTION_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_2_1_KDV_RUNTIME_EXECUTION_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_2_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
