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

echo "===== 153 — FAZ 3-10.8.1 TDHP SMOKE REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/smoke/tdhp/tdhp_smoke.go"
TEST_FILE="internal/erp/turkiye/smoke/tdhp/tdhp_smoke_test.go"
CONFIG_FILE="configs/faz3/smoke/tdhp_smoke.v1.json"
DOC_FILE="docs/faz3/smoke/FAZ_3_10_8_1_TDHP_SMOKE.md"

check_file "153 TDHP smoke runtime file" "$RUNTIME_FILE"
check_file "153 TDHP smoke test file" "$TEST_FILE"
check_file "153 TDHP smoke config file" "$CONFIG_FILE"
check_file "153 TDHP smoke documentation file" "$DOC_FILE"

check_file "153 voucher pipeline evidence file" "docs/faz3/evidence/FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "153 account switch evidence file" "docs/faz3/evidence/FAZ_3_10_1_2_ACCOUNT_PLAN_LIVE_VERSION_SWITCH_REAL_IMPLEMENTATION_AUDIT.md"
check_file "153 posting runtime evidence file" "docs/faz3/evidence/FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_file "153 audit trace evidence file" "docs/faz3/evidence/FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "153 reconciliation evidence file" "docs/faz3/evidence/FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_file "153 TDHP live tests evidence file" "docs/faz3/evidence/FAZ_3_10_1_6_TDHP_LIVE_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

check_grep "153 runtime constructor" "$RUNTIME_FILE" "NewTDHPSmokeRuntime"
check_grep "153 smoke run runtime" "$RUNTIME_FILE" "Run"
check_grep "153 request validation runtime" "$RUNTIME_FILE" "validateRequest"
check_grep "153 module evidence runtime" "$RUNTIME_FILE" "moduleEvidence"
check_grep "153 smoke hash builder" "$RUNTIME_FILE" "buildSmokeHash"

check_grep "153 smoke request model" "$RUNTIME_FILE" "type SmokeRequest"
check_grep "153 smoke result model" "$RUNTIME_FILE" "type SmokeResult"
check_grep "153 module evidence model" "$RUNTIME_FILE" "type ModuleEvidence"

check_grep "153 voucher module" "$RUNTIME_FILE" "ModuleVoucherPipeline"
check_grep "153 account switch module" "$RUNTIME_FILE" "ModuleAccountSwitch"
check_grep "153 posting module" "$RUNTIME_FILE" "ModulePostingRuntime"
check_grep "153 audit trace module" "$RUNTIME_FILE" "ModuleAuditTrace"
check_grep "153 reconciliation module" "$RUNTIME_FILE" "ModuleReconciliation"
check_grep "153 TDHP live tests module" "$RUNTIME_FILE" "ModuleTDHPLiveTests"

check_grep "153 runtime ready check" "$RUNTIME_FILE" "CheckRuntimeReady"
check_grep "153 go tests pass check" "$RUNTIME_FILE" "CheckGoTestsPass"
check_grep "153 tenant guard check" "$RUNTIME_FILE" "CheckTenantGuard"
check_grep "153 correlation guard check" "$RUNTIME_FILE" "CheckCorrelationGuard"
check_grep "153 idempotency guard check" "$RUNTIME_FILE" "CheckIdempotencyGuard"
check_grep "153 TDHP accounts check" "$RUNTIME_FILE" "CheckTDHPAccounts"
check_grep "153 voucher balanced check" "$RUNTIME_FILE" "CheckVoucherBalanced"
check_grep "153 posting ready check" "$RUNTIME_FILE" "CheckPostingReady"
check_grep "153 audit hash check" "$RUNTIME_FILE" "CheckAuditHash"
check_grep "153 reconciliation check" "$RUNTIME_FILE" "CheckReconciliation"
check_grep "153 live ready simulation check" "$RUNTIME_FILE" "CheckLiveReadySimulation"
check_grep "153 real external closed check" "$RUNTIME_FILE" "CheckRealExternalClosed"

check_grep "153 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "153 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "153 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "153 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "153 smoke id guard" "$RUNTIME_FILE" "smoke_id is required"
check_grep "153 requested at guard" "$RUNTIME_FILE" "requested_at is required"

check_grep "153 pass test" "$TEST_FILE" "TestTDHPSmokePasses"
check_grep "153 all modules test" "$TEST_FILE" "TestTDHPSmokeCoversAllModules"
check_grep "153 guard coverage test" "$TEST_FILE" "TestTDHPSmokeHasTenantCorrelationIdempotencyGuards"
check_grep "153 voucher posting test" "$TEST_FILE" "TestTDHPSmokeCoversVoucherAndPosting"
check_grep "153 audit reconciliation test" "$TEST_FILE" "TestTDHPSmokeCoversAuditAndReconciliation"
check_grep "153 real external closed test" "$TEST_FILE" "TestTDHPSmokeKeepsRealExternalClosed"
check_grep "153 missing tenant test" "$TEST_FILE" "TestTDHPSmokeRejectsMissingTenant"
check_grep "153 minimum pass count test" "$TEST_FILE" "TestTDHPSmokeRejectsMinimumPassCount"

check_grep "153 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "153 config require all modules" "$CONFIG_FILE" "\"require_all_modules\": true"
check_grep "153 config voucher required" "$CONFIG_FILE" "\"require_voucher_pipeline\": true"
check_grep "153 config account switch required" "$CONFIG_FILE" "\"require_account_switch\": true"
check_grep "153 config posting required" "$CONFIG_FILE" "\"require_posting_runtime\": true"
check_grep "153 config audit required" "$CONFIG_FILE" "\"require_audit_trace\": true"
check_grep "153 config reconciliation required" "$CONFIG_FILE" "\"require_reconciliation\": true"
check_grep "153 config live tests required" "$CONFIG_FILE" "\"require_tdhp_live_tests\": true"
check_grep "153 config smoke hash required" "$CONFIG_FILE" "\"require_smoke_hash\": true"
check_grep "153 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "153 config real external closed" "$CONFIG_FILE" "\"real_external_status\": \"CLOSED\""
check_grep "153 config previous gate" "$CONFIG_FILE" "FAZ_3_10_8_6_ERP_TR_LIVE_READINESS_CLOSURE"
check_grep "153 config next gate" "$CONFIG_FILE" "FAZ_3_10_8_2_TAX_SMOKE"

run_go_test "153 voucher pipeline go test status" "./internal/erp/turkiye/tdhp/voucherpipeline"
run_go_test "153 account switch go test status" "./internal/erp/turkiye/tdhp/accountswitch"
run_go_test "153 posting runtime go test status" "./internal/erp/turkiye/tdhp/postingruntime"
run_go_test "153 audit trace go test status" "./internal/erp/turkiye/tdhp/audittrace"
run_go_test "153 reconciliation go test status" "./internal/erp/turkiye/tdhp/reconciliation"
run_go_test "153 TDHP live tests go test status" "./internal/erp/turkiye/tdhp/livetests"
run_go_test "153 TDHP smoke go test status" "./internal/erp/turkiye/smoke/tdhp"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 153 — FAZ 3-10.8.1 — TDHP Smoke Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_8_1_TDHP_SMOKE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_8_1_TDHP_SMOKE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_8_2_READY=${NEXT_READY}

## Scope

- Real voucher pipeline smoke
- Account plan live version switch smoke
- Document based posting runtime smoke
- Audit trace persistence smoke
- TDHP reconciliation runtime smoke
- TDHP live tests smoke
- Tenant / correlation / idempotency guard check
- TDHP account trace check
- Voucher balanced / posting ready check
- Audit hash check
- Real external closed check
- Smoke hash generation

## Live Policy

- Production public/live approval: FALSE
- Real external calls: CLOSED
- This smoke is readiness evidence, not production activation.

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 153 — FAZ 3-10.8.1 TDHP SMOKE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_8_1_TDHP_SMOKE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_8_1_TDHP_SMOKE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_8_2_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
