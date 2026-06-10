#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_7_4_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.7.4 TENANT-SAFE PLUGIN SANDBOX RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 runtime file"
check_file "internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go" "2-7.7.4 test file"
check_file "configs/faz2/plugin_runtime/plugin_sandbox_runtime.v1.json" "2-7.7.4 config file"
check_file "docs/faz2/plugin_runtime/FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME.md" "2-7.7.4 documentation file"

check_grep "PluginSandboxRuntime" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 PluginSandboxRuntime type"
check_grep "PluginSandboxExecutionContext" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 sandbox execution context model"
check_grep "PluginSandboxDecision" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 sandbox decision model"
check_grep "BuildExecutionContext" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 build execution context function"
check_grep "BuildPluginSandboxNamespace" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 sandbox namespace builder"
check_grep "PluginSandboxContextMatchesTenant" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 tenant context match helper"
check_grep "ErrPluginSandboxCrossTenant" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 tenant-safe sandbox guard"
check_grep "ErrPluginSandboxInstallNotEnabled" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 lifecycle status bridge"
check_grep "ErrPluginSandboxProductionDenied" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 production deny guard"
check_grep "ErrPluginSandboxPermissionDenied" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 permission enforcement bridge"
check_grep "CheckPermission" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 permission runtime check call"
check_grep "CanExecute" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.4 can execute helper"

check_grep "TestPluginSandboxRuntimeBuildsExecutionContext" "internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go" "2-7.7.4 build execution context test"
check_grep "TestPluginSandboxRuntimeRejectsMissingTenant" "internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go" "2-7.7.4 missing tenant test"
check_grep "TestPluginSandboxRuntimeRejectsCrossTenant" "internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go" "2-7.7.4 cross tenant test"
check_grep "TestPluginSandboxRuntimeRejectsDisabledInstall" "internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go" "2-7.7.4 disabled install test"
check_grep "TestPluginSandboxRuntimeRejectsPermissionDenied" "internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go" "2-7.7.4 permission denied test"
check_grep "TestPluginSandboxRuntimeRejectsProductionEnvironment" "internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go" "2-7.7.4 production denied test"
check_grep "TestPluginSandboxRuntimeRejectsEnvironmentMismatch" "internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go" "2-7.7.4 environment mismatch test"
check_grep "TestPluginSandboxRuntimeCanExecute" "internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go" "2-7.7.4 can execute test"
check_grep "TestPluginSandboxNamespaceAndTenantMatch" "internal/platform/plugin/runtime/plugin_sandbox_runtime_test.go" "2-7.7.4 namespace tenant match test"

echo "===== FAZ 2-7.7.4 GO TEST ====="
if go test ./internal/platform/plugin/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.7.4 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.7.4 go test"
fi

echo "===== FAZ 2-7.7.4 TENANT-SAFE PLUGIN SANDBOX RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_7_5_READY=YES"
  exit 0
else
  echo "FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_7_4_TENANT_SAFE_PLUGIN_SANDBOX_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_7_5_READY=NO"
  exit 1
fi
