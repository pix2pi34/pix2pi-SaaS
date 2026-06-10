#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_8_5_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.8.5 SANDBOX ENVIRONMENT RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.5 runtime file"
check_file "internal/platform/publicapi/runtime/sandbox_environment_runtime_test.go" "2-7.8.5 test file"
check_file "configs/faz2/public_api/sandbox_environment_runtime.v1.json" "2-7.8.5 config file"
check_file "docs/faz2/public_api/FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME.md" "2-7.8.5 documentation file"

check_grep "SandboxEnvironmentRuntime" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.5 SandboxEnvironmentRuntime type"
check_grep "SandboxRequestContext" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.5 sandbox request context"
check_grep "BuildContext" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.5 build sandbox context function"
check_grep "SandboxDataNamespacePrefix|BuildSandboxDataNamespace" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.5 sandbox data boundary"
check_grep "ErrSandboxProductionDenied|SandboxReasonProductionDenied" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.5 production deny guard"
check_grep "ValidateAppAuthBoundary" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.5 app auth bridge"
check_grep "AllowSandboxQuota" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.5 sandbox quota bridge"
check_grep "ErrSandboxCrossTenant" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.5 tenant-safe sandbox guard"
check_grep "SandboxContextMatchesTenant" "internal/platform/publicapi/runtime/sandbox_environment_runtime.go" "2-7.8.5 tenant context match helper"

check_grep "TestSandboxEnvironmentRuntimeBuildsSandboxContext" "internal/platform/publicapi/runtime/sandbox_environment_runtime_test.go" "2-7.8.5 build context test"
check_grep "TestSandboxEnvironmentRuntimeRejectsProductionByDefault" "internal/platform/publicapi/runtime/sandbox_environment_runtime_test.go" "2-7.8.5 production deny test"
check_grep "TestSandboxEnvironmentRuntimeRejectsMissingTenant" "internal/platform/publicapi/runtime/sandbox_environment_runtime_test.go" "2-7.8.5 missing tenant test"
check_grep "TestSandboxEnvironmentRuntimeValidateAppAuthBoundary" "internal/platform/publicapi/runtime/sandbox_environment_runtime_test.go" "2-7.8.5 app auth bridge test"
check_grep "TestSandboxEnvironmentRuntimeRejectsProductionAppAuthBoundary" "internal/platform/publicapi/runtime/sandbox_environment_runtime_test.go" "2-7.8.5 production app auth boundary test"
check_grep "TestSandboxEnvironmentRuntimeRejectsCrossTenantAppAuthBoundary" "internal/platform/publicapi/runtime/sandbox_environment_runtime_test.go" "2-7.8.5 cross tenant app auth test"
check_grep "TestSandboxEnvironmentRuntimeQuotaBridgeAllowsAndDenies" "internal/platform/publicapi/runtime/sandbox_environment_runtime_test.go" "2-7.8.5 sandbox quota bridge test"
check_grep "TestSandboxEnvironmentRuntimeTenantNamespaceIsolation" "internal/platform/publicapi/runtime/sandbox_environment_runtime_test.go" "2-7.8.5 namespace isolation test"

echo "===== FAZ 2-7.8.5 GO TEST ====="
if go test ./internal/platform/publicapi/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.8.5 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.8.5 go test"
fi

echo "===== FAZ 2-7.8.5 SANDBOX ENVIRONMENT RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_8_6_READY=YES"
  exit 0
else
  echo "FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_8_5_SANDBOX_ENVIRONMENT_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_8_6_READY=NO"
  exit 1
fi
