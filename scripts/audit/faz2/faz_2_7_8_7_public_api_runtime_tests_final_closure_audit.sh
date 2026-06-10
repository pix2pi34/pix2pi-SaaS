#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_8_7_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_8_7_PUBLIC_API_RUNTIME_TESTS_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.8.7 PUBLIC API RUNTIME TESTS FINAL CLOSURE AUDIT START ====="

check_file "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.7 api key runtime file"
check_file "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.7 app auth runtime file"
check_file "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.7 quota rate limit runtime file"
check_file "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.7 sandbox runtime file"
check_file "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.7 developer docs runtime file"
check_file "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 final test file"
check_file "configs/faz2/public_api/public_api_runtime_tests_final_closure.v1.json" "2-7.8.7 final closure config"
check_file "docs/faz2/public_api/FAZ_2_7_8_7_PUBLIC_API_RUNTIME_TESTS_FINAL_CLOSURE.md" "2-7.8.7 final closure documentation"

check_grep "TestPublicAPIRuntimeFinalEndToEndSandboxFlow" "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 public API E2E final test"
check_grep "TestPublicAPIRuntimeFinalCrossTenantDenyAcrossModules" "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 cross-tenant final test"

check_grep "APIKeyIssuanceRuntime" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.7 api key runtime implemented"
check_grep "AppAuthRuntime" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.7 app auth runtime implemented"
check_grep "QuotaRateLimitRuntime" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.7 quota runtime implemented"
check_grep "SandboxEnvironmentRuntime" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.7 sandbox runtime implemented"
check_grep "DeveloperDocsPublishRuntime" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.7 developer docs runtime implemented"

check_grep "ErrAPIKeyCrossTenant" "internal/platform/publicapi/runtime/api_key_issuance_runtime.go" "2-7.8.7 api key cross-tenant guard"
check_grep "ErrAppAuthCrossTenant" "internal/platform/publicapi/runtime/app_auth_runtime.go" "2-7.8.7 app auth cross-tenant guard"
check_grep "ErrQuotaCrossTenant" "internal/platform/publicapi/runtime/quota_rate_limit_runtime.go" "2-7.8.7 quota cross-tenant guard"
check_grep "ErrSandboxProductionDenied" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.7 sandbox production deny guard"
check_grep "ErrDeveloperDocsDuplicateEndpoint" "internal/platform/publicapi/runtime/developer_docs_publish_runtime.go" "2-7.8.7 developer docs duplicate endpoint guard"

check_grep "IssueKey" "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 final test uses API key issuance"
check_grep "RegisterApp" "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 final test uses app registration"
check_grep "LinkAPIKey" "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 final test uses app key relation"
check_grep "ValidateAppAuth" "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 final test uses app auth validation"
check_grep "CreatePolicy" "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 final test uses quota policy"
check_grep "AllowSandboxQuota" "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 final test uses sandbox quota bridge"
check_grep "PublishMarkdown" "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 final test uses markdown docs publish"
check_grep "PublishOpenAPITrace" "internal/platform/publicapi/runtime/public_api_runtime_final_test.go" "2-7.8.7 final test uses openapi trace publish"

echo "===== FAZ 2-7.8.7 GO TEST ====="
if go test ./internal/platform/publicapi/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.8.7 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.8.7 go test"
fi

echo "===== FAZ 2-7.8.7 PUBLIC API RUNTIME TESTS FINAL CLOSURE AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_8_7_PUBLIC_API_RUNTIME_TESTS_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_8_7_PUBLIC_API_RUNTIME_TESTS_TEST_STATUS=PASS"
  echo "FAZ_2_7_8_7_PUBLIC_API_RUNTIME_TESTS_FINAL_STATUS=PASS"
  echo "FAZ_2_7_8_PUBLIC_API_RUNTIME_BLOCK_READY_FOR_GATEWAY=YES"
  echo "FAZ_2_7_8_1_READY=YES"
  exit 0
else
  echo "FAZ_2_7_8_7_PUBLIC_API_RUNTIME_TESTS_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_8_7_PUBLIC_API_RUNTIME_TESTS_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_8_7_PUBLIC_API_RUNTIME_TESTS_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_8_PUBLIC_API_RUNTIME_BLOCK_READY_FOR_GATEWAY=NO"
  echo "FAZ_2_7_8_1_READY=NO"
  exit 1
fi
