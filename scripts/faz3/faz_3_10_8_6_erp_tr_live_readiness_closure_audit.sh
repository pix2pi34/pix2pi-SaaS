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

echo "===== 152 — FAZ 3-10.8.6 ERP-TR LIVE READINESS CLOSURE REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/smoke/livereadiness/erp_tr_live_readiness_closure.go"
TEST_FILE="internal/erp/turkiye/smoke/livereadiness/erp_tr_live_readiness_closure_test.go"
CONFIG_FILE="configs/faz3/smoke/erp_tr_live_readiness_closure.v1.json"
DOC_FILE="docs/faz3/smoke/FAZ_3_10_8_6_ERP_TR_LIVE_READINESS_CLOSURE.md"

check_file "152 ERP-TR live readiness runtime file" "$RUNTIME_FILE"
check_file "152 ERP-TR live readiness test file" "$TEST_FILE"
check_file "152 ERP-TR live readiness config file" "$CONFIG_FILE"
check_file "152 ERP-TR live readiness documentation file" "$DOC_FILE"

check_file "152 ERP-TR core final recheck evidence file" "docs/faz3/evidence/FAZ_3_R_ERP_TURKIYE_CORE_FINAL_RECHECK_AUDIT_FIX_V2.md"
check_file "152 TDHP live tests evidence file" "docs/faz3/evidence/FAZ_3_10_1_6_TDHP_LIVE_TESTS_REAL_IMPLEMENTATION_AUDIT.md"
check_file "152 tax runtime tests evidence file" "docs/faz3/evidence/FAZ_3_10_2_6_TAX_RUNTIME_TESTS_REAL_IMPLEMENTATION_AUDIT.md"
check_file "152 payment integration tests evidence file" "docs/faz3/evidence/FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS_REAL_IMPLEMENTATION_AUDIT.md"
check_file "152 export adapter tests evidence file" "docs/faz3/evidence/FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS_REAL_IMPLEMENTATION_AUDIT.md"
check_file "152 Document AI runtime tests evidence file" "docs/faz3/evidence/FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS_REAL_IMPLEMENTATION_AUDIT.md"
check_file "152 e-Belge smoke evidence file" "docs/faz3/evidence/FAZ_3_10_8_3_EBELGE_SMOKE_REAL_IMPLEMENTATION_AUDIT.md"

check_grep "152 runtime constructor" "$RUNTIME_FILE" "NewERPTRLiveReadinessClosureRuntime"
check_grep "152 closure runtime" "$RUNTIME_FILE" "Close"
check_grep "152 request validation runtime" "$RUNTIME_FILE" "validateRequest"
check_grep "152 area evidence runtime" "$RUNTIME_FILE" "areaEvidence"
check_grep "152 closure hash builder" "$RUNTIME_FILE" "buildClosureHash"

check_grep "152 closure request model" "$RUNTIME_FILE" "type ClosureRequest"
check_grep "152 closure result model" "$RUNTIME_FILE" "type ClosureResult"
check_grep "152 area evidence model" "$RUNTIME_FILE" "type AreaEvidence"

check_grep "152 ERP core area" "$RUNTIME_FILE" "AreaERPTRCoreFinalRecheck"
check_grep "152 TDHP live area" "$RUNTIME_FILE" "AreaTDHPLiveTests"
check_grep "152 tax runtime area" "$RUNTIME_FILE" "AreaTaxRuntimeTests"
check_grep "152 payment area" "$RUNTIME_FILE" "AreaPaymentIntegration"
check_grep "152 export area" "$RUNTIME_FILE" "AreaExportAdapterTests"
check_grep "152 Document AI area" "$RUNTIME_FILE" "AreaDocumentAITests"
check_grep "152 e-Belge smoke area" "$RUNTIME_FILE" "AreaEBelgeSmoke"

check_grep "152 provider gates closed policy" "$RUNTIME_FILE" "CLOSED_UNTIL_PROVIDER_LIVE_APPROVALS"
check_grep "152 production approved false field" "$RUNTIME_FILE" "ProductionApproved"
check_grep "152 real payment gate closed" "$RUNTIME_FILE" "REAL_PAYMENT_GATE_CLOSED"
check_grep "152 real eBelge provider gate closed" "$RUNTIME_FILE" "REAL_EBELGE_PROVIDER_GATE_CLOSED"

check_grep "152 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "152 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "152 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "152 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "152 closure id guard" "$RUNTIME_FILE" "closure_id is required"
check_grep "152 requested at guard" "$RUNTIME_FILE" "requested_at is required"

check_grep "152 pass test" "$TEST_FILE" "TestERPTRLiveReadinessClosurePasses"
check_grep "152 all areas test" "$TEST_FILE" "TestERPTRLiveReadinessCoversAllAreas"
check_grep "152 provider gates closed test" "$TEST_FILE" "TestERPTRLiveReadinessKeepsRealProviderGatesClosed"
check_grep "152 e-Belge smoke test" "$TEST_FILE" "TestERPTRLiveReadinessIncludesEBelgeSmoke"
check_grep "152 Document AI test" "$TEST_FILE" "TestERPTRLiveReadinessIncludesDocumentAI"
check_grep "152 payment integration test" "$TEST_FILE" "TestERPTRLiveReadinessIncludesPaymentIntegration"
check_grep "152 missing tenant test" "$TEST_FILE" "TestERPTRLiveReadinessRejectsMissingTenant"
check_grep "152 minimum pass count test" "$TEST_FILE" "TestERPTRLiveReadinessRejectsMinimumPassCount"

check_grep "152 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "152 config require all areas" "$CONFIG_FILE" "\"require_all_areas\": true"
check_grep "152 config core final recheck required" "$CONFIG_FILE" "\"require_core_final_recheck\": true"
check_grep "152 config TDHP live required" "$CONFIG_FILE" "\"require_tdhp_live_tests\": true"
check_grep "152 config tax runtime required" "$CONFIG_FILE" "\"require_tax_runtime_tests\": true"
check_grep "152 config payment required" "$CONFIG_FILE" "\"require_payment_integration\": true"
check_grep "152 config export required" "$CONFIG_FILE" "\"require_export_adapter_tests\": true"
check_grep "152 config Document AI required" "$CONFIG_FILE" "\"require_document_ai_tests\": true"
check_grep "152 config eBelge smoke required" "$CONFIG_FILE" "\"require_ebelge_smoke\": true"
check_grep "152 config provider gates closed required" "$CONFIG_FILE" "\"require_real_provider_gates_closed\": true"
check_grep "152 config closure hash required" "$CONFIG_FILE" "\"require_closure_hash\": true"
check_grep "152 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "152 config real external false" "$CONFIG_FILE" "\"real_external_provider_calls_allowed\": false"
check_grep "152 config previous gate" "$CONFIG_FILE" "FAZ_3_10_8_3_EBELGE_SMOKE"
check_grep "152 config next gate" "$CONFIG_FILE" "FAZ_3_10_8_1_TDHP_SMOKE"

run_go_test "152 TDHP live tests go test status" "./internal/erp/turkiye/tdhp/livetests"
run_go_test "152 tax runtime tests go test status" "./internal/erp/turkiye/tax/runtimetests"
run_go_test "152 payment integration tests go test status" "./internal/erp/turkiye/payment/integrationtests"
run_go_test "152 export adapter tests go test status" "./internal/erp/turkiye/export/adaptertests"
run_go_test "152 Document AI runtime tests go test status" "./internal/erp/turkiye/documentai/runtimetests"
run_go_test "152 e-Belge smoke go test status" "./internal/erp/turkiye/ebelge/smoke"
run_go_test "152 ERP-TR live readiness closure go test status" "./internal/erp/turkiye/smoke/livereadiness"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 152 — FAZ 3-10.8.6 — ERP-TR Live Readiness Closure Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_8_6_ERP_TR_LIVE_READINESS_CLOSURE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_8_6_ERP_TR_LIVE_READINESS_CLOSURE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_8_1_READY=${NEXT_READY}

## Scope

- ERP-TR core final recheck evidence
- TDHP live tests evidence
- Tax runtime tests evidence
- Payment integration tests evidence
- Export adapter tests evidence
- Document AI runtime tests evidence
- e-Belge smoke evidence
- Real provider gates closed policy
- Production approved=false policy
- Closure hash generation

## Live Policy

- Production public/live approval: FALSE
- Real provider calls: CLOSED
- Real payment calls: CLOSED
- Real e-Belge/GIB provider calls: CLOSED
- This closure is readiness evidence, not production activation.

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 152 — FAZ 3-10.8.6 ERP-TR LIVE READINESS CLOSURE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_8_6_ERP_TR_LIVE_READINESS_CLOSURE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_8_6_ERP_TR_LIVE_READINESS_CLOSURE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_8_1_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
