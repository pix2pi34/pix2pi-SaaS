#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_7_3_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.7.3 PERMISSION ENFORCEMENT RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 runtime file"
check_file "internal/platform/plugin/runtime/permission_enforcement_runtime_test.go" "2-7.7.3 test file"
check_file "configs/faz2/plugin_runtime/permission_enforcement_runtime.v1.json" "2-7.7.3 config file"
check_file "docs/faz2/plugin_runtime/FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME.md" "2-7.7.3 documentation file"

check_grep "PluginPermissionEnforcementRuntime" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 PluginPermissionEnforcementRuntime type"
check_grep "PluginPermissionCheckRequest" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 permission check request model"
check_grep "PluginPermissionDecision" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 permission decision model"
check_grep "CheckPermission" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 check permission function"
check_grep "CanPerform" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 can perform helper"
check_grep "ActionPermissionMap" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 action permission map"
check_grep "PluginInstallStatusEnabled" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 plugin enabled status guard"
check_grep "ErrPluginPermissionCrossTenant" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 tenant-safe permission guard"
check_grep "ErrPluginPermissionDenied" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 permission denied guard"
check_grep "ErrPluginPermissionActionUnknown" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 unknown action guard"
check_grep "PluginPermissionListContains" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 permission list helper"
check_grep "CorrelationID" "internal/platform/plugin/runtime/permission_enforcement_runtime.go" "2-7.7.3 audit decision correlation field"

check_grep "TestPluginPermissionEnforcementRuntimeAllowsGrantedPermission" "internal/platform/plugin/runtime/permission_enforcement_runtime_test.go" "2-7.7.3 granted permission test"
check_grep "TestPluginPermissionEnforcementRuntimeDeniesMissingTenant" "internal/platform/plugin/runtime/permission_enforcement_runtime_test.go" "2-7.7.3 missing tenant test"
check_grep "TestPluginPermissionEnforcementRuntimeDeniesCrossTenant" "internal/platform/plugin/runtime/permission_enforcement_runtime_test.go" "2-7.7.3 cross tenant test"
check_grep "TestPluginPermissionEnforcementRuntimeDeniesDisabledInstall" "internal/platform/plugin/runtime/permission_enforcement_runtime_test.go" "2-7.7.3 disabled install test"
check_grep "TestPluginPermissionEnforcementRuntimeDeniesUnknownAction" "internal/platform/plugin/runtime/permission_enforcement_runtime_test.go" "2-7.7.3 unknown action test"
check_grep "TestPluginPermissionEnforcementRuntimeDeniesPermissionNotGranted" "internal/platform/plugin/runtime/permission_enforcement_runtime_test.go" "2-7.7.3 missing permission test"
check_grep "TestPluginPermissionEnforcementRuntimeCanPerform" "internal/platform/plugin/runtime/permission_enforcement_runtime_test.go" "2-7.7.3 can perform test"

echo "===== FAZ 2-7.7.3 GO TEST ====="
if go test ./internal/platform/plugin/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.7.3 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.7.3 go test"
fi

echo "===== FAZ 2-7.7.3 PERMISSION ENFORCEMENT RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_7_4_READY=YES"
  exit 0
else
  echo "FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_7_3_PERMISSION_ENFORCEMENT_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_7_4_READY=NO"
  exit 1
fi
