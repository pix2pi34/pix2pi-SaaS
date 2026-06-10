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

echo "===== 151 — FAZ 3-10.8.3 EBELGE SMOKE REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/ebelge/smoke/ebelge_smoke.go"
TEST_FILE="internal/erp/turkiye/ebelge/smoke/ebelge_smoke_test.go"
CONFIG_FILE="configs/faz3/smoke/ebelge_smoke.v1.json"
DOC_FILE="docs/faz3/smoke/FAZ_3_10_8_3_EBELGE_SMOKE.md"

check_file "151 e-Belge smoke runtime file" "$RUNTIME_FILE"
check_file "151 e-Belge smoke test file" "$TEST_FILE"
check_file "151 e-Belge smoke config file" "$CONFIG_FILE"
check_file "151 e-Belge smoke documentation file" "$DOC_FILE"

check_file "151 e-Fatura evidence file" "docs/faz3/evidence/FAZ_3_10_3_1_E_FATURA_PROVIDER_INTEGRATION_REAL_IMPLEMENTATION_AUDIT.md"
check_file "151 e-Arşiv evidence file" "docs/faz3/evidence/FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION_REAL_IMPLEMENTATION_AUDIT.md"
check_file "151 e-Adisyon evidence file" "docs/faz3/evidence/FAZ_3_10_3_3_E_ADISYON_PROVIDER_INTEGRATION_REAL_IMPLEMENTATION_AUDIT.md"
check_file "151 status sync evidence file" "docs/faz3/evidence/FAZ_3_10_3_4_EBELGE_STATUS_SYNC_REAL_IMPLEMENTATION_AUDIT.md"
check_file "151 error retry evidence file" "docs/faz3/evidence/FAZ_3_10_3_5_EBELGE_ERROR_CANCEL_RETRY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_file "151 live integration evidence file" "docs/faz3/evidence/FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

check_grep "151 runtime constructor" "$RUNTIME_FILE" "NewEBelgeSmokeRuntime"
check_grep "151 smoke run runtime" "$RUNTIME_FILE" "Run"
check_grep "151 request validation runtime" "$RUNTIME_FILE" "validateRequest"
check_grep "151 module evidence runtime" "$RUNTIME_FILE" "moduleEvidence"
check_grep "151 smoke hash builder" "$RUNTIME_FILE" "buildSmokeHash"

check_grep "151 smoke request model" "$RUNTIME_FILE" "type SmokeRequest"
check_grep "151 smoke result model" "$RUNTIME_FILE" "type SmokeResult"
check_grep "151 module evidence model" "$RUNTIME_FILE" "type ModuleEvidence"

check_grep "151 e-Fatura module" "$RUNTIME_FILE" "ModuleEFaturaProvider"
check_grep "151 e-Arşiv module" "$RUNTIME_FILE" "ModuleEArsivProvider"
check_grep "151 e-Adisyon module" "$RUNTIME_FILE" "ModuleEAdisyonProvider"
check_grep "151 status sync module" "$RUNTIME_FILE" "ModuleStatusSync"
check_grep "151 error retry module" "$RUNTIME_FILE" "ModuleErrorCancelRetry"
check_grep "151 live integration module" "$RUNTIME_FILE" "ModuleLiveIntegrationTests"

check_grep "151 provider runtime check" "$RUNTIME_FILE" "CheckProviderRuntime"
check_grep "151 provider operations check" "$RUNTIME_FILE" "CheckProviderOperations"
check_grep "151 production gate closed check" "$RUNTIME_FILE" "CheckProductionGateClosed"
check_grep "151 tenant guard check" "$RUNTIME_FILE" "CheckTenantGuard"
check_grep "151 correlation guard check" "$RUNTIME_FILE" "CheckCorrelationGuard"
check_grep "151 idempotency guard check" "$RUNTIME_FILE" "CheckIdempotencyGuard"
check_grep "151 document guard check" "$RUNTIME_FILE" "CheckDocumentGuard"
check_grep "151 status sync check" "$RUNTIME_FILE" "CheckStatusSync"
check_grep "151 retry DLQ check" "$RUNTIME_FILE" "CheckRetryDLQ"
check_grep "151 live gate closed check" "$RUNTIME_FILE" "CheckLiveGateClosed"

check_grep "151 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "151 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "151 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "151 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "151 smoke id guard" "$RUNTIME_FILE" "smoke_id is required"
check_grep "151 requested at guard" "$RUNTIME_FILE" "requested_at is required"

check_grep "151 pass test" "$TEST_FILE" "TestEBelgeSmokePasses"
check_grep "151 all modules test" "$TEST_FILE" "TestEBelgeSmokeCoversAllModules"
check_grep "151 production gate test" "$TEST_FILE" "TestEBelgeSmokeProviderModulesHaveProductionGateClosed"
check_grep "151 guard coverage test" "$TEST_FILE" "TestEBelgeSmokeHasTenantCorrelationIdempotencyGuards"
check_grep "151 status sync test" "$TEST_FILE" "TestEBelgeSmokeStatusSyncCovered"
check_grep "151 retry DLQ test" "$TEST_FILE" "TestEBelgeSmokeRetryDLQCovered"
check_grep "151 missing tenant test" "$TEST_FILE" "TestEBelgeSmokeRejectsMissingTenant"
check_grep "151 minimum pass count test" "$TEST_FILE" "TestEBelgeSmokeRejectsMinimumPassCount"

check_grep "151 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "151 config require all modules" "$CONFIG_FILE" "\"require_all_modules\": true"
check_grep "151 config provider runtime required" "$CONFIG_FILE" "\"require_provider_runtime\": true"
check_grep "151 config provider operations required" "$CONFIG_FILE" "\"require_provider_operations\": true"
check_grep "151 config production gate required" "$CONFIG_FILE" "\"require_production_gate_closed\": true"
check_grep "151 config tenant guard required" "$CONFIG_FILE" "\"require_tenant_guard\": true"
check_grep "151 config correlation guard required" "$CONFIG_FILE" "\"require_correlation_guard\": true"
check_grep "151 config idempotency guard required" "$CONFIG_FILE" "\"require_idempotency_guard\": true"
check_grep "151 config document guard required" "$CONFIG_FILE" "\"require_document_guard\": true"
check_grep "151 config status sync required" "$CONFIG_FILE" "\"require_status_sync\": true"
check_grep "151 config retry DLQ required" "$CONFIG_FILE" "\"require_retry_dlq\": true"
check_grep "151 config live gate closed required" "$CONFIG_FILE" "\"require_live_gate_closed\": true"
check_grep "151 config smoke hash required" "$CONFIG_FILE" "\"require_smoke_hash\": true"
check_grep "151 config previous gate" "$CONFIG_FILE" "FAZ_3_10_6_5_DOCUMENT_AI_RUNTIME_TESTS"
check_grep "151 config next gate" "$CONFIG_FILE" "FAZ_3_10_8_6_ERP_TR_LIVE_READINESS_CLOSURE"

run_go_test "151 e-Fatura provider go test status" "./internal/erp/turkiye/ebelge/efatura"
run_go_test "151 e-Arşiv provider go test status" "./internal/erp/turkiye/ebelge/earsiv"
run_go_test "151 e-Adisyon provider go test status" "./internal/erp/turkiye/ebelge/eadisyon"
run_go_test "151 e-Belge status sync go test status" "./internal/erp/turkiye/ebelge/statussync"
run_go_test "151 e-Belge error retry go test status" "./internal/erp/turkiye/ebelge/errorretry"
run_go_test "151 e-Belge live integration tests go test status" "./internal/erp/turkiye/ebelge/liveintegrationtests"
run_go_test "151 e-Belge smoke go test status" "./internal/erp/turkiye/ebelge/smoke"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 151 — FAZ 3-10.8.3 — e-Belge Smoke Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_8_3_EBELGE_SMOKE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_8_3_EBELGE_SMOKE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_8_6_READY=${NEXT_READY}

## Scope

- e-Fatura provider smoke
- e-Arşiv provider smoke
- e-Adisyon provider smoke
- e-Belge status sync smoke
- e-Belge error / cancel / retry smoke
- e-Belge live integration tests smoke
- Production real provider gate closed check
- Tenant / correlation / idempotency guard check
- Status callback / poll coverage check
- Retry / DLQ coverage check
- Smoke hash generation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 151 — FAZ 3-10.8.3 EBELGE SMOKE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_8_3_EBELGE_SMOKE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_8_3_EBELGE_SMOKE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_8_6_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
