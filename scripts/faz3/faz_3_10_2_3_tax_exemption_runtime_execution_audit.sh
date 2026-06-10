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

echo "===== 123 — FAZ 3-10.2.3 TAX EXEMPTION RUNTIME EXECUTION REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/tax/exemption/tax_exemption_runtime.go"
TEST_FILE="internal/erp/turkiye/tax/exemption/tax_exemption_runtime_test.go"
CONFIG_FILE="configs/faz3/tax/tax_exemption_runtime_execution.v1.json"
DOC_FILE="docs/faz3/tax/FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION.md"

check_file "123 tax exemption runtime file" "$RUNTIME_FILE"
check_file "123 tax exemption test file" "$TEST_FILE"
check_file "123 tax exemption config file" "$CONFIG_FILE"
check_file "123 tax exemption documentation file" "$DOC_FILE"

check_grep "123 runtime constructor" "$RUNTIME_FILE" "NewTaxExemptionRuntime"
check_grep "123 execute function" "$RUNTIME_FILE" "func (r \\*TaxExemptionRuntime) Execute"
check_grep "123 exemption rule model" "$RUNTIME_FILE" "type ExemptionRule"
check_grep "123 exemption request model" "$RUNTIME_FILE" "type ExemptionRequest"
check_grep "123 exemption result model" "$RUNTIME_FILE" "type ExemptionResult"
check_grep "123 active rule version guard" "$RUNTIME_FILE" "active_rule_version is required"
check_grep "123 effective date guard" "$RUNTIME_FILE" "EXEMPTION_RULE_NOT_EFFECTIVE"
check_grep "123 full exemption scope" "$RUNTIME_FILE" "FULL_EXEMPTION"
check_grep "123 partial exemption scope" "$RUNTIME_FILE" "PARTIAL_EXEMPTION"
check_grep "123 rate override scope" "$RUNTIME_FILE" "RATE_OVERRIDE"
check_grep "123 zero rate scope" "$RUNTIME_FILE" "ZERO_RATE"
check_grep "123 minimum base not applied" "$RUNTIME_FILE" "TAX_EXEMPTION_NOT_APPLIED_BELOW_MIN_BASE"
check_grep "123 exemption reason guard" "$RUNTIME_FILE" "EXEMPTION_REASON_REQUIRED"
check_grep "123 tax exemption applied action" "$RUNTIME_FILE" "TAX_EXEMPTION_APPLIED"
check_grep "123 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "123 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "123 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "123 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "123 document id guard" "$RUNTIME_FILE" "document_id is required"
check_grep "123 party id guard" "$RUNTIME_FILE" "party_id is required"
check_grep "123 party tax no guard" "$RUNTIME_FILE" "party_tax_no is required"
check_grep "123 gross amount guard" "$RUNTIME_FILE" "gross_amount_kurus must be positive"
check_grep "123 tax base guard" "$RUNTIME_FILE" "tax_base_amount_kurus must be positive"
check_grep "123 tax base cannot exceed gross guard" "$RUNTIME_FILE" "tax_base_amount_kurus cannot exceed gross_amount_kurus"
check_grep "123 currency mismatch guard" "$RUNTIME_FILE" "currency_code mismatch"
check_grep "123 KDV tax type support" "$RUNTIME_FILE" "KDV"
check_grep "123 stopaj tax type support" "$RUNTIME_FILE" "STOPAJ"

check_grep "123 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "123 config active rule version" "$CONFIG_FILE" "TR_TAX_EXEMPTION_2026_V1"
check_grep "123 config default currency TRY" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "123 config KDV tax type" "$CONFIG_FILE" "KDV"
check_grep "123 config STOPAJ tax type" "$CONFIG_FILE" "STOPAJ"
check_grep "123 config full exemption rule" "$CONFIG_FILE" "KDV_EXPORT_FULL"
check_grep "123 config partial exemption rule" "$CONFIG_FILE" "KDV_PARTIAL_50"
check_grep "123 config rate override rule" "$CONFIG_FILE" "KDV_RATE_10"
check_grep "123 config next gate" "$CONFIG_FILE" "FAZ_3_10_2_TAX_RUNTIME_FINAL_CLOSURE"

if go test ./internal/erp/turkiye/tax/exemption; then
  pass "123 tax exemption Go test status"
else
  fail "123 tax exemption Go test status"
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
# 123 — FAZ 3-10.2.3 — Tax Exemption Runtime Execution Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_2_TAX_RUNTIME_FINAL_CLOSURE_READY=${NEXT_READY}

## Scope

- Tax exemption runtime config
- Exemption rule model
- Exemption request / result model
- Active rule version guard
- Effective date guard
- Full exemption path
- Partial exemption path
- Rate override path
- Zero rate scope
- Minimum base not-applied path
- Exemption reason required guard
- Tenant / correlation / request / idempotency guards
- Document / party / tax no guards
- Gross / tax base amount guards
- TRY currency guard
- KDV / STOPAJ tax type support

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 123 — FAZ 3-10.2.3 TAX EXEMPTION RUNTIME EXECUTION COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_2_TAX_RUNTIME_FINAL_CLOSURE_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
