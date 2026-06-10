#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_7_6_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_7_6_PLUGIN_RUNTIME_TESTS_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.7.6 PLUGIN RUNTIME TESTS FINAL CLOSURE AUDIT START ====="

check_file "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.6 plugin loader runtime file"
check_file "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.6 plugin lifecycle runtime file"
check_file "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.6 permission enforcement runtime file"
check_file "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.6 plugin sandbox runtime file"
check_file "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.6 version compatibility runtime file"
check_file "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 final test file"
check_file "configs/faz2/plugin_runtime/plugin_runtime_tests_final_closure.v1.json" "2-7.7.6 final closure config"
check_file "docs/faz2/plugin_runtime/FAZ_2_7_7_6_PLUGIN_RUNTIME_TESTS_FINAL_CLOSURE.md" "2-7.7.6 final closure documentation"

check_grep "TestPluginRuntimeFinalEndToEndSandboxExecutionFlow" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 plugin runtime E2E final test"
check_grep "TestPluginRuntimeFinalCrossTenantDenyAcrossModules" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 cross-tenant final test"
check_grep "TestPluginRuntimeFinalDenyCases" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 deny cases final test"

check_grep "PluginLoaderRuntime" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.6 loader runtime implemented"
check_grep "PluginLifecycleRuntime" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.6 lifecycle runtime implemented"
check_grep "PluginPermissionEnforcementRuntime" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.6 permission runtime implemented"
check_grep "PluginSandboxRuntime" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.6 sandbox runtime implemented"
check_grep "PluginVersionCompatibilityRuntime" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.6 version compatibility runtime implemented"

check_grep "ErrPluginLoaderCrossTenant" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.6 loader cross-tenant guard"
check_grep "ErrPluginLifecycleCrossTenant" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.6 lifecycle cross-tenant guard"
check_grep "ErrPluginPermissionCrossTenant" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.6 permission cross-tenant guard"
check_grep "ErrPluginSandboxCrossTenant" "internal/platform/plugin/runtime/plugin_sandbox_runtime.go" "2-7.7.6 sandbox cross-tenant guard"
check_grep "ErrPluginCompatibilityCrossTenant" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.6 compatibility cross-tenant guard"

check_grep "LoadManifestJSON" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 final test uses plugin loader"
check_grep "InstallPlugin" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 final test uses plugin install"
check_grep "EnablePlugin" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 final test uses plugin enable"
check_grep "CheckPermission" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 final test uses permission check"
check_grep "BuildExecutionContext" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 final test uses sandbox execution context"
check_grep "CheckCompatibility" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 final test uses version compatibility"

check_grep "ErrPluginPermissionDenied" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 final test checks permission denied"
check_grep "ErrPluginSandboxProductionDenied" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 final test checks production sandbox denied"
check_grep "ErrPluginCompatibilityAboveMaximum" "internal/platform/plugin/runtime/plugin_runtime_final_test.go" "2-7.7.6 final test checks compatibility above max denied"

echo "===== FAZ 2-7.7.6 GO TEST ====="
if go test ./internal/platform/plugin/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.7.6 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.7.6 go test"
fi

echo "===== FAZ 2-7.7.6 PLUGIN RUNTIME TESTS FINAL CLOSURE AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_7_6_PLUGIN_RUNTIME_TESTS_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_7_6_PLUGIN_RUNTIME_TESTS_TEST_STATUS=PASS"
  echo "FAZ_2_7_7_6_PLUGIN_RUNTIME_TESTS_FINAL_STATUS=PASS"
  echo "FAZ_2_7_7_PLUGIN_RUNTIME_BLOCK_SEAL_STATUS=SEALED"
  echo "ONCELIK_3_LVL15_PLUGIN_RUNTIME_STATUS=SEALED"
  exit 0
else
  echo "FAZ_2_7_7_6_PLUGIN_RUNTIME_TESTS_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_7_6_PLUGIN_RUNTIME_TESTS_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_7_6_PLUGIN_RUNTIME_TESTS_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_7_PLUGIN_RUNTIME_BLOCK_SEAL_STATUS=OPEN"
  echo "ONCELIK_3_LVL15_PLUGIN_RUNTIME_STATUS=OPEN"
  exit 1
fi
