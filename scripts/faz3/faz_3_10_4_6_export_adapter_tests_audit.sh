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

echo "===== 139 — FAZ 3-10.4.6 EXPORT ADAPTER TESTS REAL IMPLEMENTATION AUDIT START ====="

SUITE_FILE="internal/erp/turkiye/export/adaptertests/export_adapter_test_suite.go"
TEST_FILE="internal/erp/turkiye/export/adaptertests/export_adapter_test_suite_test.go"
CONFIG_FILE="configs/faz3/export/export_adapter_tests.v1.json"
DOC_FILE="docs/faz3/export/FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS.md"

check_file "139 export adapter suite file" "$SUITE_FILE"
check_file "139 export adapter test file" "$TEST_FILE"
check_file "139 export adapter config file" "$CONFIG_FILE"
check_file "139 export adapter documentation file" "$DOC_FILE"

check_grep "139 suite constructor" "$SUITE_FILE" "NewExportAdapterTestSuite"
check_grep "139 run all runtime" "$SUITE_FILE" "RunAll"
check_grep "139 ETA adapter run" "$SUITE_FILE" "runETA"
check_grep "139 Logo adapter run" "$SUITE_FILE" "runLogo"
check_grep "139 Mikro adapter run" "$SUITE_FILE" "runMikro"
check_grep "139 Zirve adapter run" "$SUITE_FILE" "runZirve"
check_grep "139 negative tests runtime" "$SUITE_FILE" "runNegativeTests"
check_grep "139 invalid account prefix negative" "$SUITE_FILE" "runInvalidAccountPrefixNegative"
check_grep "139 tenant mismatch negative" "$SUITE_FILE" "runTenantMismatchNegative"
check_grep "139 missing posting hash negative" "$SUITE_FILE" "runMissingPostingHashNegative"

check_grep "139 adapter request model" "$SUITE_FILE" "type AdapterTestRequest"
check_grep "139 adapter result model" "$SUITE_FILE" "type AdapterResult"
check_grep "139 negative test result model" "$SUITE_FILE" "type NegativeTestResult"
check_grep "139 suite result model" "$SUITE_FILE" "type AdapterSuiteResult"

check_grep "139 ETA runtime import" "$SUITE_FILE" "export/eta"
check_grep "139 Logo runtime import" "$SUITE_FILE" "export/logo"
check_grep "139 Mikro runtime import" "$SUITE_FILE" "export/mikro"
check_grep "139 Zirve runtime import" "$SUITE_FILE" "export/zirve"
check_grep "139 format matrix runtime import" "$SUITE_FILE" "export/formatmatrix"

check_grep "139 ETA config function" "$SUITE_FILE" "etaConfig"
check_grep "139 Logo config function" "$SUITE_FILE" "logoConfig"
check_grep "139 Mikro config function" "$SUITE_FILE" "mikroConfig"
check_grep "139 Zirve config function" "$SUITE_FILE" "zirveConfig"
check_grep "139 matrix config function" "$SUITE_FILE" "matrixConfig"

check_grep "139 tenant guard" "$SUITE_FILE" "tenant_id is required"
check_grep "139 correlation guard" "$SUITE_FILE" "correlation_id is required"
check_grep "139 request guard" "$SUITE_FILE" "request_id is required"
check_grep "139 idempotency guard" "$SUITE_FILE" "idempotency_key is required"
check_grep "139 suite id guard" "$SUITE_FILE" "suite_id is required"
check_grep "139 period guard" "$SUITE_FILE" "period_code is required"
check_grep "139 postings guard" "$SUITE_FILE" "postings are required"
check_grep "139 file count guard" "$SUITE_FILE" "adapter file count below required minimum"
check_grep "139 row count guard" "$SUITE_FILE" "adapter row count below required minimum"
check_grep "139 package hash guard" "$SUITE_FILE" "adapter package hash is required"
check_grep "139 balance guard" "$SUITE_FILE" "adapter package must be balanced"
check_grep "139 debit credit total guard" "$SUITE_FILE" "adapter debit and credit totals must match"
check_grep "139 closure readiness field" "$SUITE_FILE" "ReadyForExportFamilyClosure"
check_grep "139 suite hash builder" "$SUITE_FILE" "buildSuiteHash"

check_grep "139 all providers test" "$TEST_FILE" "TestExportAdapterSuiteAllProvidersPass"
check_grep "139 adapter output test" "$TEST_FILE" "TestExportAdapterSuiteAdapterOutputsHaveFilesRowsAndHashes"
check_grep "139 negative tests pass test" "$TEST_FILE" "TestExportAdapterSuiteNegativeTestsPass"
check_grep "139 invalid account prefix rejection test" "$TEST_FILE" "TestExportAdapterSuiteRejectsInvalidAccountPrefix"
check_grep "139 tenant mismatch rejection test" "$TEST_FILE" "TestExportAdapterSuiteRejectsTenantMismatch"
check_grep "139 missing posting hash rejection test" "$TEST_FILE" "TestExportAdapterSuiteRejectsMissingPostingHash"
check_grep "139 missing postings rejection test" "$TEST_FILE" "TestExportAdapterSuiteRejectsMissingPostings"

check_grep "139 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "139 config ETA adapter" "$CONFIG_FILE" "\"ETA\""
check_grep "139 config Logo adapter" "$CONFIG_FILE" "\"LOGO\""
check_grep "139 config Mikro adapter" "$CONFIG_FILE" "\"MIKRO\""
check_grep "139 config Zirve adapter" "$CONFIG_FILE" "\"ZIRVE\""
check_grep "139 config ETA coverage" "$CONFIG_FILE" "FAZ_3_10_4_4_ETA_REAL_FORMAT_GENERATION"
check_grep "139 config Logo coverage" "$CONFIG_FILE" "FAZ_3_10_4_1_LOGO_REAL_FORMAT_GENERATION"
check_grep "139 config Mikro coverage" "$CONFIG_FILE" "FAZ_3_10_4_2_MIKRO_REAL_FORMAT_GENERATION"
check_grep "139 config Zirve coverage" "$CONFIG_FILE" "FAZ_3_10_4_3_ZIRVE_REAL_FORMAT_GENERATION"
check_grep "139 config matrix coverage" "$CONFIG_FILE" "FAZ_3_10_4_5_FORMAT_VALIDATION_MATRIX_RUNTIME"
check_grep "139 config next gate" "$CONFIG_FILE" "FAZ_3_10_5_1_ACCOUNTANT_MULTI_FIRM_ACCESS_RUNTIME"

if go test ./internal/erp/turkiye/export/adaptertests; then
  pass "139 export adapter tests Go test status"
else
  fail "139 export adapter tests Go test status"
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
# 139 — FAZ 3-10.4.6 — Export Adapter Tests Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_5_1_READY=${NEXT_READY}

## Scope

- ETA adapter package generation test
- Logo adapter package generation test
- Mikro adapter package generation test
- Zirve adapter package generation test
- Format matrix ready test
- Adapter file count validation
- Adapter row count validation
- Adapter package hash validation
- Adapter balance validation
- Invalid account prefix negative test
- Tenant mismatch negative test
- Missing posting hash negative test
- Export family closure readiness decision

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 139 — FAZ 3-10.4.6 EXPORT ADAPTER TESTS COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_5_1_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
