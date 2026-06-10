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

echo "===== 155 — FAZ 3-10.8.4 EXPORT SMOKE REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/smoke/export/export_smoke.go"
TEST_FILE="internal/erp/turkiye/smoke/export/export_smoke_test.go"
CONFIG_FILE="configs/faz3/smoke/export_smoke.v1.json"
DOC_FILE="docs/faz3/smoke/FAZ_3_10_8_4_EXPORT_SMOKE.md"

check_file "155 export smoke runtime file" "$RUNTIME_FILE"
check_file "155 export smoke test file" "$TEST_FILE"
check_file "155 export smoke config file" "$CONFIG_FILE"
check_file "155 export smoke documentation file" "$DOC_FILE"

check_file "155 ETA evidence file" "docs/faz3/evidence/FAZ_3_10_4_4_ETA_REAL_FORMAT_GENERATION_REAL_IMPLEMENTATION_AUDIT.md"
check_file "155 Logo evidence file" "docs/faz3/evidence/FAZ_3_10_4_1_LOGO_REAL_FORMAT_GENERATION_REAL_IMPLEMENTATION_AUDIT.md"
check_file "155 Mikro evidence file" "docs/faz3/evidence/FAZ_3_10_4_2_MIKRO_REAL_FORMAT_GENERATION_REAL_IMPLEMENTATION_AUDIT.md"
check_file "155 Zirve evidence file" "docs/faz3/evidence/FAZ_3_10_4_3_ZIRVE_REAL_FORMAT_GENERATION_REAL_IMPLEMENTATION_AUDIT.md"
check_file "155 format matrix evidence file" "docs/faz3/evidence/FAZ_3_10_4_5_FORMAT_VALIDATION_MATRIX_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_file "155 export adapter tests evidence file" "docs/faz3/evidence/FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

check_grep "155 runtime constructor" "$RUNTIME_FILE" "NewExportSmokeRuntime"
check_grep "155 smoke run runtime" "$RUNTIME_FILE" "Run"
check_grep "155 request validation runtime" "$RUNTIME_FILE" "validateRequest"
check_grep "155 module evidence runtime" "$RUNTIME_FILE" "moduleEvidence"
check_grep "155 smoke hash builder" "$RUNTIME_FILE" "buildSmokeHash"

check_grep "155 smoke request model" "$RUNTIME_FILE" "type SmokeRequest"
check_grep "155 smoke result model" "$RUNTIME_FILE" "type SmokeResult"
check_grep "155 module evidence model" "$RUNTIME_FILE" "type ModuleEvidence"

check_grep "155 ETA module" "$RUNTIME_FILE" "ModuleETAFormat"
check_grep "155 Logo module" "$RUNTIME_FILE" "ModuleLogoFormat"
check_grep "155 Mikro module" "$RUNTIME_FILE" "ModuleMikroFormat"
check_grep "155 Zirve module" "$RUNTIME_FILE" "ModuleZirveFormat"
check_grep "155 format matrix module" "$RUNTIME_FILE" "ModuleFormatMatrix"
check_grep "155 adapter tests module" "$RUNTIME_FILE" "ModuleAdapterTests"

check_grep "155 runtime ready check" "$RUNTIME_FILE" "CheckRuntimeReady"
check_grep "155 go tests pass check" "$RUNTIME_FILE" "CheckGoTestsPass"
check_grep "155 tenant guard check" "$RUNTIME_FILE" "CheckTenantGuard"
check_grep "155 correlation guard check" "$RUNTIME_FILE" "CheckCorrelationGuard"
check_grep "155 idempotency guard check" "$RUNTIME_FILE" "CheckIdempotencyGuard"
check_grep "155 target system guard check" "$RUNTIME_FILE" "CheckTargetSystemGuard"
check_grep "155 format version guard check" "$RUNTIME_FILE" "CheckFormatVersionGuard"
check_grep "155 posting hash guard check" "$RUNTIME_FILE" "CheckPostingHashGuard"
check_grep "155 audit trace guard check" "$RUNTIME_FILE" "CheckAuditTraceGuard"
check_grep "155 package hash check" "$RUNTIME_FILE" "CheckPackageHash"
check_grep "155 file hash check" "$RUNTIME_FILE" "CheckFileHash"
check_grep "155 Turkish normalize check" "$RUNTIME_FILE" "CheckTurkishNormalize"
check_grep "155 journal file check" "$RUNTIME_FILE" "CheckJournalFile"
check_grep "155 ledger file check" "$RUNTIME_FILE" "CheckLedgerFile"
check_grep "155 summary file check" "$RUNTIME_FILE" "CheckSummaryFile"
check_grep "155 all targets covered check" "$RUNTIME_FILE" "CheckAllTargetsCovered"
check_grep "155 negative tests check" "$RUNTIME_FILE" "CheckNegativeTests"
check_grep "155 real delivery closed check" "$RUNTIME_FILE" "CheckRealDeliveryClosed"

check_grep "155 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "155 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "155 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "155 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "155 smoke id guard" "$RUNTIME_FILE" "smoke_id is required"
check_grep "155 requested at guard" "$RUNTIME_FILE" "requested_at is required"

check_grep "155 pass test" "$TEST_FILE" "TestExportSmokePasses"
check_grep "155 all modules test" "$TEST_FILE" "TestExportSmokeCoversAllModules"
check_grep "155 all targets test" "$TEST_FILE" "TestExportSmokeCoversAllExportTargets"
check_grep "155 hashes files test" "$TEST_FILE" "TestExportSmokeCoversHashesAndFiles"
check_grep "155 matrix adapter test" "$TEST_FILE" "TestExportSmokeCoversMatrixAndAdapterTests"
check_grep "155 real delivery closed test" "$TEST_FILE" "TestExportSmokeKeepsRealDeliveryClosed"
check_grep "155 missing tenant test" "$TEST_FILE" "TestExportSmokeRejectsMissingTenant"
check_grep "155 minimum pass count test" "$TEST_FILE" "TestExportSmokeRejectsMinimumPassCount"

check_grep "155 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "155 config require all modules" "$CONFIG_FILE" "\"require_all_modules\": true"
check_grep "155 config ETA required" "$CONFIG_FILE" "\"require_eta_format\": true"
check_grep "155 config Logo required" "$CONFIG_FILE" "\"require_logo_format\": true"
check_grep "155 config Mikro required" "$CONFIG_FILE" "\"require_mikro_format\": true"
check_grep "155 config Zirve required" "$CONFIG_FILE" "\"require_zirve_format\": true"
check_grep "155 config matrix required" "$CONFIG_FILE" "\"require_format_matrix\": true"
check_grep "155 config adapter tests required" "$CONFIG_FILE" "\"require_adapter_tests\": true"
check_grep "155 config smoke hash required" "$CONFIG_FILE" "\"require_smoke_hash\": true"
check_grep "155 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "155 config real delivery closed" "$CONFIG_FILE" "\"real_delivery_status\": \"CLOSED\""
check_grep "155 config previous gate" "$CONFIG_FILE" "FAZ_3_10_8_2_TAX_SMOKE"
check_grep "155 config next gate" "$CONFIG_FILE" "FAZ_3_10_8_5_PAYMENT_SMOKE"

run_go_test "155 ETA format go test status" "./internal/erp/turkiye/export/eta"
run_go_test "155 Logo format go test status" "./internal/erp/turkiye/export/logo"
run_go_test "155 Mikro format go test status" "./internal/erp/turkiye/export/mikro"
run_go_test "155 Zirve format go test status" "./internal/erp/turkiye/export/zirve"
run_go_test "155 format matrix go test status" "./internal/erp/turkiye/export/formatmatrix"
run_go_test "155 export adapter tests go test status" "./internal/erp/turkiye/export/adaptertests"
run_go_test "155 export smoke go test status" "./internal/erp/turkiye/smoke/export"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 155 — FAZ 3-10.8.4 — Export Smoke Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_8_4_EXPORT_SMOKE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_8_4_EXPORT_SMOKE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_8_5_READY=${NEXT_READY}

## Scope

- ETA real format smoke
- Logo real format smoke
- Mikro real format smoke
- Zirve real format smoke
- Format validation matrix smoke
- Export adapter tests smoke
- Tenant / correlation / idempotency guard check
- Target system / format version guard check
- Posting hash / audit trace guard check
- Package hash / file hash check
- Journal / ledger / summary file coverage
- Real delivery closed check
- Smoke hash generation

## Live Policy

- Production public/live approval: FALSE
- Real delivery calls: CLOSED
- This smoke is readiness evidence, not production activation.

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 155 — FAZ 3-10.8.4 EXPORT SMOKE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_8_4_EXPORT_SMOKE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_8_4_EXPORT_SMOKE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_8_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
