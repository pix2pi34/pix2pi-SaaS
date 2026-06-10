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

run_go_test() {
  local label="$1"
  local pkg="$2"

  if go test "$pkg"; then
    pass "$label"
  else
    fail "$label"
  fi
}

echo "===== 154 — FAZ 3-10.8.2 TAX SMOKE REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/smoke/tax/tax_smoke.go"
TEST_FILE="internal/erp/turkiye/smoke/tax/tax_smoke_test.go"
CONFIG_FILE="configs/faz3/smoke/tax_smoke.v1.json"
DOC_FILE="docs/faz3/smoke/FAZ_3_10_8_2_TAX_SMOKE.md"

check_file "154 tax smoke runtime file" "$RUNTIME_FILE"
check_file "154 tax smoke test file" "$TEST_FILE"
check_file "154 tax smoke config file" "$CONFIG_FILE"
check_file "154 tax smoke documentation file" "$DOC_FILE"

check_file "154 KDV evidence file" "docs/faz3/evidence/FAZ_3_10_2_1_KDV_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md"
check_file "154 stopaj evidence file" "docs/faz3/evidence/FAZ_3_10_2_2_STOPAJ_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md"
check_file "154 exemption evidence file" "docs/faz3/evidence/FAZ_3_10_2_3_TAX_EXEMPTION_RUNTIME_EXECUTION_REAL_IMPLEMENTATION_AUDIT.md"
check_file "154 rule rollout evidence file" "docs/faz3/evidence/FAZ_3_10_2_4_TAX_RULE_VERSION_ROLLOUT_REAL_IMPLEMENTATION_AUDIT.md"
check_file "154 audit persistence evidence file" "docs/faz3/evidence/FAZ_3_10_2_5_TAX_AUDIT_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "154 tax runtime tests evidence file" "docs/faz3/evidence/FAZ_3_10_2_6_TAX_RUNTIME_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

check_grep "154 runtime constructor" "$RUNTIME_FILE" "NewTaxSmokeRuntime"
check_grep "154 smoke run runtime" "$RUNTIME_FILE" "Run"
check_grep "154 request validation runtime" "$RUNTIME_FILE" "validateRequest"
check_grep "154 module evidence runtime" "$RUNTIME_FILE" "moduleEvidence"
check_grep "154 smoke hash builder" "$RUNTIME_FILE" "buildSmokeHash"

check_grep "154 smoke request model" "$RUNTIME_FILE" "type SmokeRequest"
check_grep "154 smoke result model" "$RUNTIME_FILE" "type SmokeResult"
check_grep "154 module evidence model" "$RUNTIME_FILE" "type ModuleEvidence"

check_grep "154 KDV module" "$RUNTIME_FILE" "ModuleKDVRuntime"
check_grep "154 stopaj module" "$RUNTIME_FILE" "ModuleStopajRuntime"
check_grep "154 exemption module" "$RUNTIME_FILE" "ModuleExemptionRuntime"
check_grep "154 rollout module" "$RUNTIME_FILE" "ModuleRuleRollout"
check_grep "154 audit persistence module" "$RUNTIME_FILE" "ModuleAuditPersistence"
check_grep "154 tax runtime tests module" "$RUNTIME_FILE" "ModuleTaxRuntimeTests"

check_grep "154 runtime ready check" "$RUNTIME_FILE" "CheckRuntimeReady"
check_grep "154 go tests pass check" "$RUNTIME_FILE" "CheckGoTestsPass"
check_grep "154 tenant guard check" "$RUNTIME_FILE" "CheckTenantGuard"
check_grep "154 correlation guard check" "$RUNTIME_FILE" "CheckCorrelationGuard"
check_grep "154 idempotency guard check" "$RUNTIME_FILE" "CheckIdempotencyGuard"
check_grep "154 rule version guard check" "$RUNTIME_FILE" "CheckRuleVersionGuard"
check_grep "154 TRY currency guard check" "$RUNTIME_FILE" "CheckTRYCurrencyGuard"
check_grep "154 TDHP account trace check" "$RUNTIME_FILE" "CheckTDHPAccountTrace"
check_grep "154 KDV coverage check" "$RUNTIME_FILE" "CheckKDVRateCoverage"
check_grep "154 stopaj coverage check" "$RUNTIME_FILE" "CheckStopajSubjectCoverage"
check_grep "154 exemption coverage check" "$RUNTIME_FILE" "CheckExemptionCoverage"
check_grep "154 rollout coverage check" "$RUNTIME_FILE" "CheckRolloutCoverage"
check_grep "154 audit persistence check" "$RUNTIME_FILE" "CheckAuditPersistence"
check_grep "154 audit hash check" "$RUNTIME_FILE" "CheckAuditHash"
check_grep "154 real external closed check" "$RUNTIME_FILE" "CheckRealExternalClosed"

check_grep "154 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "154 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "154 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "154 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "154 smoke id guard" "$RUNTIME_FILE" "smoke_id is required"
check_grep "154 requested at guard" "$RUNTIME_FILE" "requested_at is required"

check_grep "154 pass test" "$TEST_FILE" "TestTaxSmokePasses"
check_grep "154 all modules test" "$TEST_FILE" "TestTaxSmokeCoversAllModules"
check_grep "154 guard coverage test" "$TEST_FILE" "TestTaxSmokeHasTenantCorrelationIdempotencyGuards"
check_grep "154 KDV stopaj exemption test" "$TEST_FILE" "TestTaxSmokeCoversKDVStopajExemption"
check_grep "154 rollout audit test" "$TEST_FILE" "TestTaxSmokeCoversRolloutAndAuditPersistence"
check_grep "154 real external closed test" "$TEST_FILE" "TestTaxSmokeKeepsRealExternalClosed"
check_grep "154 missing tenant test" "$TEST_FILE" "TestTaxSmokeRejectsMissingTenant"
check_grep "154 minimum pass count test" "$TEST_FILE" "TestTaxSmokeRejectsMinimumPassCount"

check_grep "154 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "154 config require all modules" "$CONFIG_FILE" "\"require_all_modules\": true"
check_grep "154 config KDV required" "$CONFIG_FILE" "\"require_kdv_runtime\": true"
check_grep "154 config stopaj required" "$CONFIG_FILE" "\"require_stopaj_runtime\": true"
check_grep "154 config exemption required" "$CONFIG_FILE" "\"require_exemption_runtime\": true"
check_grep "154 config rollout required" "$CONFIG_FILE" "\"require_rule_rollout\": true"
check_grep "154 config audit persistence required" "$CONFIG_FILE" "\"require_audit_persistence\": true"
check_grep "154 config runtime tests required" "$CONFIG_FILE" "\"require_tax_runtime_tests\": true"
check_grep "154 config smoke hash required" "$CONFIG_FILE" "\"require_smoke_hash\": true"
check_grep "154 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "154 config real external closed" "$CONFIG_FILE" "\"real_external_status\": \"CLOSED\""
check_grep "154 config legal rule status" "$CONFIG_FILE" "\"legal_rule_status\": \"READY_FOR_RULE_VERSION_CONTROL\""
check_grep "154 config previous gate" "$CONFIG_FILE" "FAZ_3_10_8_1_TDHP_SMOKE"
check_grep "154 config next gate" "$CONFIG_FILE" "FAZ_3_10_8_4_EXPORT_SMOKE"

run_go_test "154 KDV runtime go test status" "./internal/erp/turkiye/tax/kdv"
run_go_test "154 stopaj runtime go test status" "./internal/erp/turkiye/tax/withholding"
run_go_test "154 tax exemption runtime go test status" "./internal/erp/turkiye/tax/exemption"
run_go_test "154 tax rule rollout go test status" "./internal/erp/turkiye/tax/rulerollout"
run_go_test "154 tax audit persistence go test status" "./internal/erp/turkiye/tax/auditpersistence"
run_go_test "154 tax runtime tests go test status" "./internal/erp/turkiye/tax/runtimetests"
run_go_test "154 tax smoke go test status" "./internal/erp/turkiye/smoke/tax"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 154 — FAZ 3-10.8.2 — Tax Smoke Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_8_2_TAX_SMOKE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_8_2_TAX_SMOKE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_8_4_READY=${NEXT_READY}

## Scope

- KDV runtime smoke
- Stopaj runtime smoke
- Tax exemption runtime smoke
- Tax rule version rollout smoke
- Tax audit persistence smoke
- Tax runtime tests smoke
- Tenant / correlation / idempotency guard check
- TRY currency guard check
- TDHP account trace check
- Audit hash check
- Real external closed check
- Smoke hash generation

## Live Policy

- Production public/live approval: FALSE
- Real external calls: CLOSED
- Legal rule status: READY_FOR_RULE_VERSION_CONTROL
- This smoke is readiness evidence, not production activation.

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 154 — FAZ 3-10.8.2 TAX SMOKE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_8_2_TAX_SMOKE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_8_2_TAX_SMOKE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_8_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
