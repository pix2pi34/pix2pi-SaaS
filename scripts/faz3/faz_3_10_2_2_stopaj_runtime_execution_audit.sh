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

echo "===== 122 — FAZ 3-10.2.2 STOPAJ RUNTIME EXECUTION REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tax/withholding/stopaj_runtime.go"
TEST_FILE="internal/erp/turkiye/tax/withholding/stopaj_runtime_test.go"
CONFIG_FILE="configs/faz3/tax/stopaj_runtime_execution.v1.json"
DOC_FILE="docs/faz3/tax/FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION.md"

check_file "122 stopaj runtime file" "$RUNTIME_FILE"
check_file "122 stopaj test file" "$TEST_FILE"
check_file "122 stopaj config file" "$CONFIG_FILE"
check_file "122 stopaj documentation file" "$DOC_FILE"

check_grep "122 runtime constructor" "$RUNTIME_FILE" "NewStopajRuntime"
check_grep "122 execute function" "$RUNTIME_FILE" "func (r \\*StopajRuntime) Execute"
check_grep "122 withholding rule model" "$RUNTIME_FILE" "type WithholdingRule"
check_grep "122 withholding request model" "$RUNTIME_FILE" "type WithholdingRequest"
check_grep "122 withholding result model" "$RUNTIME_FILE" "type WithholdingResult"
check_grep "122 active rule version guard" "$RUNTIME_FILE" "active_rule_version is required"
check_grep "122 effective date guard" "$RUNTIME_FILE" "WITHHOLDING_RULE_NOT_EFFECTIVE"
check_grep "122 bps calculation" "$RUNTIME_FILE" "calculateBps"
check_grep "122 minimum base not applied" "$RUNTIME_FILE" "STOPAJ_NOT_APPLIED_BELOW_MIN_BASE"
check_grep "122 exemption applied path" "$RUNTIME_FILE" "STOPAJ_EXEMPTION_APPLIED"
check_grep "122 exemption not allowed guard" "$RUNTIME_FILE" "EXEMPTION_NOT_ALLOWED"
check_grep "122 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "122 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "122 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "122 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "122 document id guard" "$RUNTIME_FILE" "document_id is required"
check_grep "122 party id guard" "$RUNTIME_FILE" "party_id is required"
check_grep "122 party tax no guard" "$RUNTIME_FILE" "party_tax_no is required"
check_grep "122 gross amount guard" "$RUNTIME_FILE" "gross_amount_kurus must be positive"
check_grep "122 tax base guard" "$RUNTIME_FILE" "tax_base_amount_kurus must be positive"
check_grep "122 tax base cannot exceed gross guard" "$RUNTIME_FILE" "tax_base_amount_kurus cannot exceed gross_amount_kurus"
check_grep "122 currency mismatch guard" "$RUNTIME_FILE" "currency_code mismatch"
check_grep "122 rent subject support" "$RUNTIME_FILE" "RENT"
check_grep "122 professional service subject support" "$RUNTIME_FILE" "PROFESSIONAL_SERVICE"

check_grep "122 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "122 config active rule version" "$CONFIG_FILE" "TR_STOPAJ_2026_V1"
check_grep "122 config default currency TRY" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "122 config rent subject" "$CONFIG_FILE" "RENT"
check_grep "122 config professional service subject" "$CONFIG_FILE" "PROFESSIONAL_SERVICE"
check_grep "122 config account code 360" "$CONFIG_FILE" "360.01"
check_grep "122 config next gate" "$CONFIG_FILE" "FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION"

if go test ./internal/erp/turkiye/tax/withholding; then
  pass "122 stopaj Go test status"
else
  fail "122 stopaj Go test status"
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
# 122 — FAZ 3-10.2.2 — Stopaj Runtime Execution Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_2_3_READY=${NEXT_READY}

## Scope

- Stopaj runtime config
- Stopaj rule model
- Stopaj request / result model
- Active rule version guard
- Effective date guard
- BPS withholding calculation
- Minimum base not-applied path
- Exemption path
- Tenant / correlation / request / idempotency guards
- Document / party / tax no guards
- Gross / tax base amount guards
- TRY currency guard
- Rent / professional service subject support

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 122 — FAZ 3-10.2.2 STOPAJ RUNTIME EXECUTION COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_2_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
