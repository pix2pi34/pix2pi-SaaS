#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_8_2_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

exec > >(tee "$EVIDENCE_FILE") 2>&1

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0
GO_TEST_STATUS="NOT_RUN"

pass_check() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail_check() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_INVALID / FAIL ❌"
}

check_file() {
  local file="$1"
  local label="$2"
  if [ -s "$file" ]; then
    pass_check "$label"
  else
    fail_check "$label"
  fi
}

check_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if grep -Eq "$pattern" "$file"; then
    pass_check "$label"
  else
    fail_check "$label"
  fi
}

echo "===== FAZ 2-7.8.2 API KEY ISSUANCE RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 runtime file"
check_file "internal/platform/publicapi/runtime/api_key_issuance_runtime_test.go" "2-7.8.2 test file"
check_file "configs/faz2/public_api/api_key_issuance_runtime.v1.json" "2-7.8.2 config file"
check_file "docs/faz2/public_api/FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME.md" "2-7.8.2 documentation file"

check_grep "APIKeyIssuanceRuntime" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 APIKeyIssuanceRuntime type"
check_grep "IssueKey" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 issue key function"
check_grep "HashAPIKeySecret" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 secret hash function"
check_grep "SecretHash" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 secret hash storage field"
check_grep "NewAPIKeyRawSecret" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 raw secret generator"
check_grep "KeyPrefix|pix2pi" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 key prefix support"
check_grep "APIKeyEnvironmentSandbox|APIKeyEnvironmentProduction" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 environment model"
check_grep "AllowedScopes|normalizeAndValidateScopes" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 scope validation"
check_grep "ErrAPIKeyCrossTenant" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 tenant-safe ownership guard"
check_grep "RevokeKey" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 revoke lifecycle"
check_grep "RotateKey" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 rotate lifecycle"
check_grep "ListTenantKeys" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.2 tenant filtered list"

check_grep "TestAPIKeyIssuanceRuntimeIssuesKeyWithHashedSecret" "internal/platform/publicapi/runtime/api_key_issuance_runtime_test.go" "2-7.8.2 issue hashed secret test"
check_grep "TestAPIKeyIssuanceRuntimeRejectsMissingTenant" "internal/platform/publicapi/runtime/api_key_issuance_runtime_test.go" "2-7.8.2 missing tenant test"
check_grep "TestAPIKeyIssuanceRuntimeRejectsInvalidScope" "internal/platform/publicapi/runtime/api_key_issuance_runtime_test.go" "2-7.8.2 invalid scope test"
check_grep "TestAPIKeyIssuanceRuntimeTenantSafeGetAndList" "internal/platform/publicapi/runtime/api_key_issuance_runtime_test.go" "2-7.8.2 tenant-safe get/list test"
check_grep "TestAPIKeyIssuanceRuntimeRevokesKey" "internal/platform/publicapi/runtime/api_key_issuance_runtime_test.go" "2-7.8.2 revoke test"
check_grep "TestAPIKeyIssuanceRuntimeRotateKey" "internal/platform/publicapi/runtime/api_key_issuance_runtime_test.go" "2-7.8.2 rotate test"

echo "===== FAZ 2-7.8.2 GO TEST ====="
if go test ./internal/platform/publicapi/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.8.2 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.8.2 go test"
fi

echo "===== FAZ 2-7.8.2 API KEY ISSUANCE RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_8_3_READY=YES"
  exit 0
else
  echo "FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_8_2_API_KEY_ISSUANCE_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_8_3_READY=NO"
  exit 1
fi
