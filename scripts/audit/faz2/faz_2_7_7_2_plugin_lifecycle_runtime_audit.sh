#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_7_2_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.7.2 PLUGIN LIFECYCLE RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 runtime file"
check_file "internal/platform/plugin/runtime/plugin_lifecycle_runtime_test.go" "2-7.7.2 test file"
check_file "configs/faz2/plugin_runtime/plugin_lifecycle_runtime.v1.json" "2-7.7.2 config file"
check_file "docs/faz2/plugin_runtime/FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME.md" "2-7.7.2 documentation file"

check_grep "PluginLifecycleRuntime" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 PluginLifecycleRuntime type"
check_grep "TenantPluginInstall" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 tenant plugin install model"
check_grep "InstallPlugin" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 install plugin function"
check_grep "EnablePlugin" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 enable plugin function"
check_grep "DisablePlugin" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 disable plugin function"
check_grep "SuspendPlugin" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 suspend plugin function"
check_grep "UninstallPlugin" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 uninstall plugin function"
check_grep "validPluginLifecycleTransition" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 lifecycle transition guard"
check_grep "ErrPluginLifecycleCrossTenant" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 tenant-safe lifecycle guard"
check_grep "ErrPluginLifecycleInvalidTransition" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 invalid transition guard"
check_grep "ErrPluginLifecycleTerminalInstall" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 terminal install guard"
check_grep "ListTenantInstalls" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 tenant install list"
check_grep "NewTenantPluginInstallID" "internal/platform/plugin/runtime/plugin_lifecycle_runtime.go" "2-7.7.2 install id generator"

check_grep "TestPluginLifecycleRuntimeInstallsLoadedPlugin" "internal/platform/plugin/runtime/plugin_lifecycle_runtime_test.go" "2-7.7.2 install loaded plugin test"
check_grep "TestPluginLifecycleRuntimeRejectsManifestNotLoaded" "internal/platform/plugin/runtime/plugin_lifecycle_runtime_test.go" "2-7.7.2 manifest not loaded test"
check_grep "TestPluginLifecycleRuntimeRejectsCrossTenantInstall" "internal/platform/plugin/runtime/plugin_lifecycle_runtime_test.go" "2-7.7.2 cross tenant install test"
check_grep "TestPluginLifecycleRuntimeEnableDisableSuspendUninstallFlow" "internal/platform/plugin/runtime/plugin_lifecycle_runtime_test.go" "2-7.7.2 lifecycle flow test"
check_grep "TestPluginLifecycleRuntimeRejectsInvalidTransition" "internal/platform/plugin/runtime/plugin_lifecycle_runtime_test.go" "2-7.7.2 invalid transition test"
check_grep "TestPluginLifecycleRuntimeRejectsTerminalTransition" "internal/platform/plugin/runtime/plugin_lifecycle_runtime_test.go" "2-7.7.2 terminal transition test"
check_grep "TestPluginLifecycleRuntimeRejectsCrossTenantAccess" "internal/platform/plugin/runtime/plugin_lifecycle_runtime_test.go" "2-7.7.2 cross tenant access test"
check_grep "TestPluginLifecycleRuntimeTenantSafeList" "internal/platform/plugin/runtime/plugin_lifecycle_runtime_test.go" "2-7.7.2 tenant-safe list test"

echo "===== FAZ 2-7.7.2 GO TEST ====="
if go test ./internal/platform/plugin/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.7.2 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.7.2 go test"
fi

echo "===== FAZ 2-7.7.2 PLUGIN LIFECYCLE RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_7_3_READY=YES"
  exit 0
else
  echo "FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_7_2_PLUGIN_LIFECYCLE_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_7_3_READY=NO"
  exit 1
fi
