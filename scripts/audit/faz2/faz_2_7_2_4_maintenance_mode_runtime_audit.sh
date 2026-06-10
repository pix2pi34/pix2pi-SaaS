#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_2_4_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.2.4 MAINTENANCE MODE RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 runtime file"
check_file "internal/platform/ops/runtime/maintenance_mode_runtime_test.go" "2-7.2.4 test file"
check_file "configs/faz2/ops_runtime/maintenance_mode_runtime.v1.json" "2-7.2.4 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME.md" "2-7.2.4 documentation file"

check_grep "MaintenanceModeRuntime" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 MaintenanceModeRuntime type"
check_grep "MaintenanceModeRequest" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 maintenance mode request model"
check_grep "MaintenanceModeRecord" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 maintenance mode record model"
check_grep "MaintenanceModeDecision" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 maintenance decision model"
check_grep "MaintenanceModeAuditEvent" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 maintenance audit event model"
check_grep "ApplyMaintenanceMode" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 apply maintenance mode function"
check_grep "MaintenanceModeActionEnable" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 enable maintenance action"
check_grep "MaintenanceModeActionDisable" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 disable maintenance action"
check_grep "MaintenanceModeStateEnabled" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 maintenance enabled state"
check_grep "MaintenanceModeStateDisabled" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 maintenance disabled state"
check_grep "ErrMaintenanceModeCrossTenant" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 tenant-safe maintenance guard"
check_grep "ErrMaintenanceModeUnauthorizedOperator" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 unauthorized operator guard"
check_grep "ErrMaintenanceModeInvalidAction" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 invalid action guard"
check_grep "UpsertMetadata" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 metadata bridge"
check_grep "maintenance_mode_id" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 maintenance metadata key"
check_grep "appendAudit" "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.4 audit log bridge"

check_grep "TestMaintenanceModeRuntimeEnablesMaintenanceMode" "internal/platform/ops/runtime/maintenance_mode_runtime_test.go" "2-7.2.4 enable maintenance test"
check_grep "TestMaintenanceModeRuntimeDisablesMaintenanceMode" "internal/platform/ops/runtime/maintenance_mode_runtime_test.go" "2-7.2.4 disable maintenance test"
check_grep "TestMaintenanceModeRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/maintenance_mode_runtime_test.go" "2-7.2.4 missing tenant test"
check_grep "TestMaintenanceModeRuntimeRejectsMissingRegistry" "internal/platform/ops/runtime/maintenance_mode_runtime_test.go" "2-7.2.4 missing registry test"
check_grep "TestMaintenanceModeRuntimeRejectsInvalidAction" "internal/platform/ops/runtime/maintenance_mode_runtime_test.go" "2-7.2.4 invalid action test"
check_grep "TestMaintenanceModeRuntimeRejectsUnauthorizedOperator" "internal/platform/ops/runtime/maintenance_mode_runtime_test.go" "2-7.2.4 unauthorized operator test"
check_grep "TestMaintenanceModeRuntimeRejectsCrossTenantInstance" "internal/platform/ops/runtime/maintenance_mode_runtime_test.go" "2-7.2.4 cross tenant instance test"
check_grep "TestMaintenanceModeRuntimeTenantSafeRecordAccess" "internal/platform/ops/runtime/maintenance_mode_runtime_test.go" "2-7.2.4 tenant safe record access test"
check_grep "TestMaintenanceModeStateForAction" "internal/platform/ops/runtime/maintenance_mode_runtime_test.go" "2-7.2.4 state for action test"

echo "===== FAZ 2-7.2.4 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.2.4 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.2.4 go test"
fi

echo "===== FAZ 2-7.2.4 MAINTENANCE MODE RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_2_5_READY=YES"
  exit 0
else
  echo "FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_2_4_MAINTENANCE_MODE_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_2_5_READY=NO"
  exit 1
fi
