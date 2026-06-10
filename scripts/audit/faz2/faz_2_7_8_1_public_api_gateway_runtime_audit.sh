#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_8_1_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.8.1 PUBLIC API GATEWAY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 runtime file"
check_file "internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go" "2-7.8.1 test file"
check_file "configs/faz2/public_api/public_api_gateway_runtime.v1.json" "2-7.8.1 config file"
check_file "docs/faz2/public_api/FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME.md" "2-7.8.1 documentation file"

check_grep "PublicAPIGatewayRuntime" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 PublicAPIGatewayRuntime type"
check_grep "HandleRequest" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 gateway handle request function"
check_grep "ExtractPublicAPIKeySecret" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 API key extraction"
check_grep "Authorization" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 authorization bearer support"
check_grep "X-API-Key" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 x api key support"
check_grep "findAPIKeyByRawSecret" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 api key hash lookup"
check_grep "ValidateAppAuth" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 app auth bridge"
check_grep "BuildContext" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 sandbox request bridge"
check_grep "AllowSandboxQuota|AllowRequest" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 quota rate limit bridge"
check_grep "HandleDeveloperDocsRequest" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 developer docs endpoint bridge"
check_grep "PublishMarkdown" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 developer markdown docs bridge"
check_grep "PublishOpenAPITrace" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 developer openapi trace bridge"
check_grep "ErrPublicAPIGatewayCrossTenant" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 tenant-safe gateway guard"
check_grep "ErrPublicAPIGatewayQuotaDenied" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 quota deny guard"
check_grep "ErrPublicAPIGatewaySandboxDenied" "internal/platform/publicapi/runtime/public_api_gateway_runtime.go" "2-7.8.1 sandbox deny guard"

check_grep "TestPublicAPIGatewayRuntimeHandlesSandboxRequest" "internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go" "2-7.8.1 sandbox request test"
check_grep "TestPublicAPIGatewayRuntimeExtractsAPIKeyFromXAPIKeyHeader" "internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go" "2-7.8.1 x-api-key extraction test"
check_grep "TestPublicAPIGatewayRuntimeRejectsMissingAPIKey" "internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go" "2-7.8.1 missing api key test"
check_grep "TestPublicAPIGatewayRuntimeRejectsInvalidAPIKey" "internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go" "2-7.8.1 invalid api key test"
check_grep "TestPublicAPIGatewayRuntimeRejectsCrossTenantAPIKey" "internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go" "2-7.8.1 cross tenant api key test"
check_grep "TestPublicAPIGatewayRuntimeRejectsScopeDenied" "internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go" "2-7.8.1 scope deny test"
check_grep "TestPublicAPIGatewayRuntimeQuotaBridgeDeniesAfterLimit" "internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go" "2-7.8.1 quota bridge deny test"
check_grep "TestPublicAPIGatewayRuntimeDeveloperDocsBridgeMarkdown" "internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go" "2-7.8.1 developer docs markdown test"
check_grep "TestPublicAPIGatewayRuntimeDeveloperDocsBridgeOpenAPITrace" "internal/platform/publicapi/runtime/public_api_gateway_runtime_test.go" "2-7.8.1 developer docs openapi test"

echo "===== FAZ 2-7.8.1 GO TEST ====="
if go test ./internal/platform/publicapi/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.8.1 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.8.1 go test"
fi

echo "===== FAZ 2-7.8.1 PUBLIC API GATEWAY RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_8_PUBLIC_API_RUNTIME_BLOCK_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_PUBLIC_API_WORKFLOW_READY=YES"
  exit 0
else
  echo "FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_8_1_PUBLIC_API_GATEWAY_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_8_PUBLIC_API_RUNTIME_BLOCK_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_PUBLIC_API_WORKFLOW_READY=NO"
  exit 1
fi
