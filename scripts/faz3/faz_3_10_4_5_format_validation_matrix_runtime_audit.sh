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

echo "===== 138 — FAZ 3-10.4.5 FORMAT VALIDATION MATRIX RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/export/formatmatrix/format_validation_matrix.go"
TEST_FILE="internal/erp/turkiye/export/formatmatrix/format_validation_matrix_test.go"
CONFIG_FILE="configs/faz3/export/format_validation_matrix_runtime.v1.json"
DOC_FILE="docs/faz3/export/FAZ_3_10_4_5_FORMAT_VALIDATION_MATRIX_RUNTIME.md"

check_file "138 format matrix runtime file" "$RUNTIME_FILE"
check_file "138 format matrix test file" "$TEST_FILE"
check_file "138 format matrix config file" "$CONFIG_FILE"
check_file "138 format matrix documentation file" "$DOC_FILE"

check_grep "138 runtime constructor" "$RUNTIME_FILE" "NewFormatValidationMatrixRuntime"
check_grep "138 build matrix runtime" "$RUNTIME_FILE" "BuildMatrix"
check_grep "138 validate matrix result runtime" "$RUNTIME_FILE" "ValidateMatrixResult"
check_grep "138 target validation runtime" "$RUNTIME_FILE" "runTargetValidation"

check_grep "138 matrix request model" "$RUNTIME_FILE" "type MatrixRequest"
check_grep "138 matrix result model" "$RUNTIME_FILE" "type MatrixResult"
check_grep "138 target check result model" "$RUNTIME_FILE" "type TargetCheckResult"
check_grep "138 matrix issue model" "$RUNTIME_FILE" "type MatrixIssue"

check_grep "138 ETA target support" "$RUNTIME_FILE" "TargetETA"
check_grep "138 Logo target support" "$RUNTIME_FILE" "TargetLogo"
check_grep "138 Mikro target support" "$RUNTIME_FILE" "TargetMikro"
check_grep "138 Zirve target support" "$RUNTIME_FILE" "TargetZirve"

check_grep "138 ETA runtime import" "$RUNTIME_FILE" "export/eta"
check_grep "138 Logo runtime import" "$RUNTIME_FILE" "export/logo"
check_grep "138 Mikro runtime import" "$RUNTIME_FILE" "export/mikro"
check_grep "138 Zirve runtime import" "$RUNTIME_FILE" "export/zirve"

check_grep "138 ETA run function" "$RUNTIME_FILE" "runETA"
check_grep "138 Logo run function" "$RUNTIME_FILE" "runLogo"
check_grep "138 Mikro run function" "$RUNTIME_FILE" "runMikro"
check_grep "138 Zirve run function" "$RUNTIME_FILE" "runZirve"

check_grep "138 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "138 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "138 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "138 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "138 matrix id guard" "$RUNTIME_FILE" "matrix_id is required"
check_grep "138 period guard" "$RUNTIME_FILE" "period_code is required"
check_grep "138 postings guard" "$RUNTIME_FILE" "postings are required"

check_grep "138 all targets guard" "$RUNTIME_FILE" "TARGET_COUNT_MISMATCH"
check_grep "138 missing target guard" "$RUNTIME_FILE" "TARGET_MISSING"
check_grep "138 file count guard" "$RUNTIME_FILE" "FILE_COUNT_TOO_LOW"
check_grep "138 row count guard" "$RUNTIME_FILE" "ROW_COUNT_TOO_LOW"
check_grep "138 balanced guard" "$RUNTIME_FILE" "PACKAGE_NOT_BALANCED"
check_grep "138 package hash guard" "$RUNTIME_FILE" "PACKAGE_HASH_MISSING"
check_grep "138 total mismatch guard" "$RUNTIME_FILE" "TOTAL_MISMATCH"
check_grep "138 matrix hash builder" "$RUNTIME_FILE" "buildMatrixHash"
check_grep "138 ready for adapter tests field" "$RUNTIME_FILE" "ReadyForAdapterTests"

check_grep "138 all targets ready test" "$TEST_FILE" "TestBuildMatrixAllTargetsReady"
check_grep "138 target order test" "$TEST_FILE" "TestBuildMatrixValidatesTargetOrder"
check_grep "138 invalid account prefix test" "$TEST_FILE" "TestBuildMatrixRejectsInvalidAccountPrefixAcrossProviders"
check_grep "138 tenant mismatch test" "$TEST_FILE" "TestBuildMatrixRejectsTenantMismatchAcrossProviders"
check_grep "138 missing posting hash test" "$TEST_FILE" "TestBuildMatrixRejectsMissingPostingHashAcrossProviders"
check_grep "138 missing target validation test" "$TEST_FILE" "TestValidateMatrixResultDetectsMissingTarget"
check_grep "138 missing package hash validation test" "$TEST_FILE" "TestValidateMatrixResultDetectsMissingPackageHash"

check_grep "138 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "138 config ETA target" "$CONFIG_FILE" "\"ETA\""
check_grep "138 config Logo target" "$CONFIG_FILE" "\"LOGO\""
check_grep "138 config Mikro target" "$CONFIG_FILE" "\"MIKRO\""
check_grep "138 config Zirve target" "$CONFIG_FILE" "\"ZIRVE\""
check_grep "138 config ETA coverage" "$CONFIG_FILE" "FAZ_3_10_4_4_ETA_REAL_FORMAT_GENERATION"
check_grep "138 config Logo coverage" "$CONFIG_FILE" "FAZ_3_10_4_1_LOGO_REAL_FORMAT_GENERATION"
check_grep "138 config Mikro coverage" "$CONFIG_FILE" "FAZ_3_10_4_2_MIKRO_REAL_FORMAT_GENERATION"
check_grep "138 config Zirve coverage" "$CONFIG_FILE" "FAZ_3_10_4_3_ZIRVE_REAL_FORMAT_GENERATION"
check_grep "138 config next gate" "$CONFIG_FILE" "FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS"

if go test ./internal/erp/turkiye/export/formatmatrix; then
  pass "138 format validation matrix Go test status"
else
  fail "138 format validation matrix Go test status"
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
# 138 — FAZ 3-10.4.5 — Format Validation Matrix Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_4_5_FORMAT_VALIDATION_MATRIX_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_4_5_FORMAT_VALIDATION_MATRIX_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_4_6_READY=${NEXT_READY}

## Scope

- ETA format runtime matrix validation
- Logo format runtime matrix validation
- Mikro format runtime matrix validation
- Zirve format runtime matrix validation
- Target file count validation
- Target row count validation
- Target balance validation
- Target package hash validation
- Provider issue to matrix fail policy
- Adapter test readiness decision

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 138 — FAZ 3-10.4.5 FORMAT VALIDATION MATRIX RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_4_5_FORMAT_VALIDATION_MATRIX_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_4_5_FORMAT_VALIDATION_MATRIX_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_4_6_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
