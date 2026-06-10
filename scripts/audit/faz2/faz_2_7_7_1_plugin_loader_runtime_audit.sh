#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_7_1_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.7.1 PLUGIN LOADER RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 runtime file"
check_file "internal/platform/plugin/runtime/plugin_loader_runtime_test.go" "2-7.7.1 test file"
check_file "configs/faz2/plugin_runtime/plugin_loader_runtime.v1.json" "2-7.7.1 config file"
check_file "docs/faz2/plugin_runtime/FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME.md" "2-7.7.1 documentation file"

check_grep "PluginLoaderRuntime" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 PluginLoaderRuntime type"
check_grep "PluginManifest" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 plugin manifest model"
check_grep "PluginCapability" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 plugin capability model"
check_grep "LoadManifestJSON" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 manifest JSON loader"
check_grep "validateManifest" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 manifest validation"
check_grep "normalizeAndValidatePermissions" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 permission validation"
check_grep "ErrPluginLoaderCrossTenant" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 tenant-safe plugin load guard"
check_grep "RequiredRuntimePrefix" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 runtime version compatibility trace"
check_grep "GetLoadedPlugin" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 loaded plugin get"
check_grep "ListTenantPlugins" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 tenant plugin list"
check_grep "PluginManifestKey" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 plugin manifest key"
check_grep "NewPluginRuntimeLoadID" "internal/platform/plugin/runtime/plugin_loader_runtime.go" "2-7.7.1 load id generator"

check_grep "TestPluginLoaderRuntimeLoadsValidManifest" "internal/platform/plugin/runtime/plugin_loader_runtime_test.go" "2-7.7.1 valid manifest load test"
check_grep "TestPluginLoaderRuntimeRejectsMissingTenant" "internal/platform/plugin/runtime/plugin_loader_runtime_test.go" "2-7.7.1 missing tenant test"
check_grep "TestPluginLoaderRuntimeRejectsCrossTenantManifest" "internal/platform/plugin/runtime/plugin_loader_runtime_test.go" "2-7.7.1 cross tenant manifest test"
check_grep "TestPluginLoaderRuntimeRejectsMissingRequiredFields" "internal/platform/plugin/runtime/plugin_loader_runtime_test.go" "2-7.7.1 missing required fields test"
check_grep "TestPluginLoaderRuntimeRejectsInvalidPermission" "internal/platform/plugin/runtime/plugin_loader_runtime_test.go" "2-7.7.1 invalid permission test"
check_grep "TestPluginLoaderRuntimeRejectsInvalidEnvironment" "internal/platform/plugin/runtime/plugin_loader_runtime_test.go" "2-7.7.1 invalid environment test"
check_grep "TestPluginLoaderRuntimeTenantSafeRegistry" "internal/platform/plugin/runtime/plugin_loader_runtime_test.go" "2-7.7.1 tenant-safe registry test"

echo "===== FAZ 2-7.7.1 GO TEST ====="
if go test ./internal/platform/plugin/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.7.1 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.7.1 go test"
fi

echo "===== FAZ 2-7.7.1 PLUGIN LOADER RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_7_2_READY=YES"
  exit 0
else
  echo "FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_7_1_PLUGIN_LOADER_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_7_2_READY=NO"
  exit 1
fi
