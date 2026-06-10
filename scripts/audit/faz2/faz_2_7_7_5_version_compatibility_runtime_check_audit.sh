#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_7_5_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.7.5 VERSION COMPATIBILITY RUNTIME CHECK REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 runtime file"
check_file "internal/platform/plugin/runtime/version_compatibility_runtime_test.go" "2-7.7.5 test file"
check_file "configs/faz2/plugin_runtime/version_compatibility_runtime.v1.json" "2-7.7.5 config file"
check_file "docs/faz2/plugin_runtime/FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK.md" "2-7.7.5 documentation file"

check_grep "PluginVersionCompatibilityRuntime" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 PluginVersionCompatibilityRuntime type"
check_grep "PluginHostRuntimeVersion" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 host runtime version model"
check_grep "PluginCompatibilityState" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 compatibility state model"
check_grep "PluginCompatibilityDecision" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 compatibility decision model"
check_grep "CheckCompatibility" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 compatibility check function"
check_grep "MinimumSupportedRuntimeVersion|MinSupported" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 minimum supported runtime guard"
check_grep "MaximumSupportedRuntimeVersion|MaxSupported" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 maximum supported runtime guard"
check_grep "ParsePluginRuntimeVersion" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 runtime version parser"
check_grep "ComparePluginRuntimeVersion" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 runtime version comparator"
check_grep "ErrPluginCompatibilityCrossTenant" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 tenant-safe compatibility guard"
check_grep "ErrPluginCompatibilityBelowMinimum" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 below minimum guard"
check_grep "ErrPluginCompatibilityAboveMaximum" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 above maximum guard"
check_grep "ErrPluginCompatibilityEnvironmentMismatch" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 environment guard"
check_grep "GetCompatibilityState" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 compatibility state get"
check_grep "ListTenantCompatibilityStates" "internal/platform/plugin/runtime/version_compatibility_runtime.go" "2-7.7.5 tenant compatibility state list"

check_grep "TestPluginVersionCompatibilityRuntimeAllowsCompatibleVersion" "internal/platform/plugin/runtime/version_compatibility_runtime_test.go" "2-7.7.5 compatible version test"
check_grep "TestPluginVersionCompatibilityRuntimeRejectsMissingTenant" "internal/platform/plugin/runtime/version_compatibility_runtime_test.go" "2-7.7.5 missing tenant test"
check_grep "TestPluginVersionCompatibilityRuntimeRejectsCrossTenant" "internal/platform/plugin/runtime/version_compatibility_runtime_test.go" "2-7.7.5 cross tenant test"
check_grep "TestPluginVersionCompatibilityRuntimeRejectsBelowMinimum" "internal/platform/plugin/runtime/version_compatibility_runtime_test.go" "2-7.7.5 below minimum test"
check_grep "TestPluginVersionCompatibilityRuntimeRejectsAboveMaximum" "internal/platform/plugin/runtime/version_compatibility_runtime_test.go" "2-7.7.5 above maximum test"
check_grep "TestPluginVersionCompatibilityRuntimeRejectsEnvironmentMismatch" "internal/platform/plugin/runtime/version_compatibility_runtime_test.go" "2-7.7.5 environment mismatch test"
check_grep "TestPluginVersionCompatibilityRuntimeRejectsInvalidRuntimePrefix" "internal/platform/plugin/runtime/version_compatibility_runtime_test.go" "2-7.7.5 invalid runtime prefix test"
check_grep "TestPluginVersionCompatibilityRuntimeTenantSafeStateAccess" "internal/platform/plugin/runtime/version_compatibility_runtime_test.go" "2-7.7.5 tenant-safe state access test"
check_grep "TestParseAndComparePluginRuntimeVersion" "internal/platform/plugin/runtime/version_compatibility_runtime_test.go" "2-7.7.5 parse and compare version test"

echo "===== FAZ 2-7.7.5 GO TEST ====="
if go test ./internal/platform/plugin/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.7.5 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.7.5 go test"
fi

echo "===== FAZ 2-7.7.5 VERSION COMPATIBILITY RUNTIME CHECK REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK_TEST_STATUS=PASS"
  echo "FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK_FINAL_STATUS=PASS"
  echo "FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_7_6_READY=YES"
  exit 0
else
  echo "FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_7_5_VERSION_COMPATIBILITY_RUNTIME_CHECK_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_7_6_READY=NO"
  exit 1
fi
