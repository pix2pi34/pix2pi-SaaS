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

echo "===== 124 — FAZ 3-10.2 TAX RUNTIME FINAL CLOSURE REAL IMPLEMENTATION AUDIT START ====="

STOPAJ_RUNTIME="internal/erp/turkiye/tax/withholding/stopaj_runtime.go"
STOPAJ_TEST="internal/erp/turkiye/tax/withholding/stopaj_runtime_test.go"
STOPAJ_CONFIG="configs/faz3/tax/stopaj_runtime_execution.v1.json"
STOPAJ_DOC="docs/faz3/tax/FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION.md"
STOPAJ_EVIDENCE="docs/faz3/evidence/FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md"

EXEMPTION_RUNTIME="internal/erp/turkiye/tax/exemption/tax_exemption_runtime.go"
EXEMPTION_TEST="internal/erp/turkiye/tax/exemption/tax_exemption_runtime_test.go"
EXEMPTION_CONFIG="configs/faz3/tax/tax_exemption_runtime_execution.v1.json"
EXEMPTION_DOC="docs/faz3/tax/FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION.md"
EXEMPTION_EVIDENCE="docs/faz3/evidence/FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md"

check_file "124 stopaj runtime file" "$STOPAJ_RUNTIME"
check_file "124 stopaj test file" "$STOPAJ_TEST"
check_file "124 stopaj config file" "$STOPAJ_CONFIG"
check_file "124 stopaj documentation file" "$STOPAJ_DOC"
check_file "124 stopaj evidence file" "$STOPAJ_EVIDENCE"

check_file "124 tax exemption runtime file" "$EXEMPTION_RUNTIME"
check_file "124 tax exemption test file" "$EXEMPTION_TEST"
check_file "124 tax exemption config file" "$EXEMPTION_CONFIG"
check_file "124 tax exemption documentation file" "$EXEMPTION_DOC"
check_file "124 tax exemption evidence file" "$EXEMPTION_EVIDENCE"

check_grep "124 stopaj final evidence PASS" "$STOPAJ_EVIDENCE" "FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION_FINAL_STATUS=PASS"
check_grep "124 tax exemption final evidence PASS" "$EXEMPTION_EVIDENCE" "FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION_FINAL_STATUS=PASS"

check_grep "124 stopaj runtime constructor" "$STOPAJ_RUNTIME" "NewStopajRuntime"
check_grep "124 stopaj execute function" "$STOPAJ_RUNTIME" "Execute(req WithholdingRequest)"
check_grep "124 stopaj rule model" "$STOPAJ_RUNTIME" "type WithholdingRule"
check_grep "124 stopaj request model" "$STOPAJ_RUNTIME" "type WithholdingRequest"
check_grep "124 stopaj result model" "$STOPAJ_RUNTIME" "type WithholdingResult"
check_grep "124 stopaj active rule version guard" "$STOPAJ_RUNTIME" "active_rule_version is required"
check_grep "124 stopaj effective date guard" "$STOPAJ_RUNTIME" "WITHHOLDING_RULE_NOT_EFFECTIVE"
check_grep "124 stopaj BPS calculation" "$STOPAJ_RUNTIME" "calculateBps"
check_grep "124 stopaj minimum base not-applied path" "$STOPAJ_RUNTIME" "STOPAJ_NOT_APPLIED_BELOW_MIN_BASE"
check_grep "124 stopaj exemption applied path" "$STOPAJ_RUNTIME" "STOPAJ_EXEMPTION_APPLIED"
check_grep "124 stopaj exemption not allowed guard" "$STOPAJ_RUNTIME" "EXEMPTION_NOT_ALLOWED"

check_grep "124 tax exemption runtime constructor" "$EXEMPTION_RUNTIME" "NewTaxExemptionRuntime"
check_grep "124 tax exemption execute function" "$EXEMPTION_RUNTIME" "Execute(req ExemptionRequest)"
check_grep "124 tax exemption rule model" "$EXEMPTION_RUNTIME" "type ExemptionRule"
check_grep "124 tax exemption request model" "$EXEMPTION_RUNTIME" "type ExemptionRequest"
check_grep "124 tax exemption result model" "$EXEMPTION_RUNTIME" "type ExemptionResult"
check_grep "124 tax exemption active rule version guard" "$EXEMPTION_RUNTIME" "active_rule_version is required"
check_grep "124 tax exemption effective date guard" "$EXEMPTION_RUNTIME" "EXEMPTION_RULE_NOT_EFFECTIVE"
check_grep "124 tax exemption full exemption scope" "$EXEMPTION_RUNTIME" "FULL_EXEMPTION"
check_grep "124 tax exemption partial exemption scope" "$EXEMPTION_RUNTIME" "PARTIAL_EXEMPTION"
check_grep "124 tax exemption rate override scope" "$EXEMPTION_RUNTIME" "RATE_OVERRIDE"
check_grep "124 tax exemption zero rate scope" "$EXEMPTION_RUNTIME" "ZERO_RATE"
check_grep "124 tax exemption reason guard" "$EXEMPTION_RUNTIME" "EXEMPTION_REASON_REQUIRED"
check_grep "124 tax exemption applied action" "$EXEMPTION_RUNTIME" "TAX_EXEMPTION_APPLIED"

check_grep "124 tenant guard stopaj" "$STOPAJ_RUNTIME" "tenant_id is required"
check_grep "124 correlation guard stopaj" "$STOPAJ_RUNTIME" "correlation_id is required"
check_grep "124 request guard stopaj" "$STOPAJ_RUNTIME" "request_id is required"
check_grep "124 idempotency guard stopaj" "$STOPAJ_RUNTIME" "idempotency_key is required"
check_grep "124 document guard stopaj" "$STOPAJ_RUNTIME" "document_id is required"
check_grep "124 party tax no guard stopaj" "$STOPAJ_RUNTIME" "party_tax_no is required"
check_grep "124 gross amount guard stopaj" "$STOPAJ_RUNTIME" "gross_amount_kurus must be positive"
check_grep "124 tax base guard stopaj" "$STOPAJ_RUNTIME" "tax_base_amount_kurus must be positive"
check_grep "124 tax base cannot exceed gross stopaj" "$STOPAJ_RUNTIME" "tax_base_amount_kurus cannot exceed gross_amount_kurus"
check_grep "124 currency guard stopaj" "$STOPAJ_RUNTIME" "currency_code mismatch"

check_grep "124 tenant guard exemption" "$EXEMPTION_RUNTIME" "tenant_id is required"
check_grep "124 correlation guard exemption" "$EXEMPTION_RUNTIME" "correlation_id is required"
check_grep "124 request guard exemption" "$EXEMPTION_RUNTIME" "request_id is required"
check_grep "124 idempotency guard exemption" "$EXEMPTION_RUNTIME" "idempotency_key is required"
check_grep "124 document guard exemption" "$EXEMPTION_RUNTIME" "document_id is required"
check_grep "124 party tax no guard exemption" "$EXEMPTION_RUNTIME" "party_tax_no is required"
check_grep "124 gross amount guard exemption" "$EXEMPTION_RUNTIME" "gross_amount_kurus must be positive"
check_grep "124 tax base guard exemption" "$EXEMPTION_RUNTIME" "tax_base_amount_kurus must be positive"
check_grep "124 tax base cannot exceed gross exemption" "$EXEMPTION_RUNTIME" "tax_base_amount_kurus cannot exceed gross_amount_kurus"
check_grep "124 currency guard exemption" "$EXEMPTION_RUNTIME" "currency_code mismatch"

check_grep "124 stopaj config runtime enabled" "$STOPAJ_CONFIG" "\"runtime_enabled\": true"
check_grep "124 stopaj config active version" "$STOPAJ_CONFIG" "TR_STOPAJ_2026_V1"
check_grep "124 stopaj config TRY" "$STOPAJ_CONFIG" "\"default_currency_code\": \"TRY\""
check_grep "124 stopaj config rent subject" "$STOPAJ_CONFIG" "RENT"
check_grep "124 stopaj config professional service subject" "$STOPAJ_CONFIG" "PROFESSIONAL_SERVICE"

check_grep "124 tax exemption config runtime enabled" "$EXEMPTION_CONFIG" "\"runtime_enabled\": true"
check_grep "124 tax exemption config active version" "$EXEMPTION_CONFIG" "TR_TAX_EXEMPTION_2026_V1"
check_grep "124 tax exemption config TRY" "$EXEMPTION_CONFIG" "\"default_currency_code\": \"TRY\""
check_grep "124 tax exemption config KDV" "$EXEMPTION_CONFIG" "KDV"
check_grep "124 tax exemption config STOPAJ" "$EXEMPTION_CONFIG" "STOPAJ"
check_grep "124 tax exemption config full exemption rule" "$EXEMPTION_CONFIG" "KDV_EXPORT_FULL"
check_grep "124 tax exemption config partial exemption rule" "$EXEMPTION_CONFIG" "KDV_PARTIAL_50"
check_grep "124 tax exemption config rate override rule" "$EXEMPTION_CONFIG" "KDV_RATE_10"

if go test \
  ./internal/erp/turkiye/tax/withholding \
  ./internal/erp/turkiye/tax/exemption; then
  pass "124 tax runtime family Go test status"
else
  fail "124 tax runtime family Go test status"
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
# 124 — FAZ 3-10.2 — Tax Runtime Final Closure Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_2_TAX_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_2_TAX_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}
- FAZ_3_10_4_READY=${NEXT_READY}

## Closed Scope

- 122 — Stopaj runtime execution
- 123 — Tax exemption runtime execution

## Runtime Packages

- internal/erp/turkiye/tax/withholding
- internal/erp/turkiye/tax/exemption

## Guardrails

- Tenant guard
- Correlation guard
- Request guard
- Idempotency guard
- Document guard
- Party / tax no guard
- Gross amount guard
- Tax base amount guard
- Tax base cannot exceed gross guard
- TRY currency guard
- Active rule version guard
- Effective date guard
- Exemption reason guard

## Runtime Capabilities

- Stopaj BPS calculation
- Stopaj minimum base not-applied path
- Stopaj exemption path
- Tax full exemption path
- Tax partial exemption path
- Tax rate override path
- Tax zero rate scope
- KDV / STOPAJ tax type support

## Audit Notes

Final status is derived from real files, previous evidence files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 124 — FAZ 3-10.2 TAX RUNTIME FINAL CLOSURE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_2_TAX_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_2_TAX_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_R_NEXT_PRIORITY_READY=${NEXT_READY}"
echo "FAZ_3_10_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
