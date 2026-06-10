#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_2_2_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_2_2_RESTART_ACTION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.2.2 RESTART ACTION RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 runtime file"
check_file "internal/platform/ops/runtime/restart_action_runtime_test.go" "2-7.2.2 test file"
check_file "configs/faz2/ops_runtime/restart_action_runtime.v1.json" "2-7.2.2 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_2_2_RESTART_ACTION_RUNTIME.md" "2-7.2.2 documentation file"

check_grep "RestartActionRuntime" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 RestartActionRuntime type"
check_grep "RestartActionRequest" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 restart action request model"
check_grep "RestartActionRecord" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 restart action record model"
check_grep "RestartActionDecision" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 restart decision model"
check_grep "RestartActionAuditEvent" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 restart audit event model"
check_grep "RequestRestart" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 request restart function"
check_grep "GetAction" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 get action function"
check_grep "ListTenantActions" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 tenant action list function"
check_grep "ListTenantAuditEvents" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 tenant audit list function"
check_grep "OperatorRoleOpsAdmin" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 operator authorization model"
check_grep "RestartActionStateRequested" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 mission control action state bridge"
check_grep "ErrRestartActionCrossTenant" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 tenant-safe restart guard"
check_grep "ErrRestartActionUnauthorizedOperator" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 unauthorized operator guard"
check_grep "ErrRestartActionStatusNotRestartable" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 restartable status guard"
check_grep "UpsertMetadata" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 metadata bridge"
check_grep "restart_action_id" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 restart action metadata key"
check_grep "appendAudit" "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.2 audit log bridge"

check_grep "TestRestartActionRuntimeRequestsRestart" "internal/platform/ops/runtime/restart_action_runtime_test.go" "2-7.2.2 request restart test"
check_grep "TestRestartActionRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/restart_action_runtime_test.go" "2-7.2.2 missing tenant test"
check_grep "TestRestartActionRuntimeRejectsMissingRegistry" "internal/platform/ops/runtime/restart_action_runtime_test.go" "2-7.2.2 missing registry test"
check_grep "TestRestartActionRuntimeRejectsUnauthorizedOperator" "internal/platform/ops/runtime/restart_action_runtime_test.go" "2-7.2.2 unauthorized operator test"
check_grep "TestRestartActionRuntimeRejectsCrossTenantInstance" "internal/platform/ops/runtime/restart_action_runtime_test.go" "2-7.2.2 cross tenant instance test"
check_grep "TestRestartActionRuntimeRejectsInstanceNotFound" "internal/platform/ops/runtime/restart_action_runtime_test.go" "2-7.2.2 instance not found test"
check_grep "TestRestartActionRuntimeRejectsNonRestartableStatus" "internal/platform/ops/runtime/restart_action_runtime_test.go" "2-7.2.2 non restartable status test"
check_grep "TestRestartActionRuntimeTenantSafeActionAccess" "internal/platform/ops/runtime/restart_action_runtime_test.go" "2-7.2.2 tenant safe action access test"

echo "===== FAZ 2-7.2.2 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.2.2 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.2.2 go test"
fi

echo "===== FAZ 2-7.2.2 RESTART ACTION RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_2_2_RESTART_ACTION_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_2_2_RESTART_ACTION_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_2_2_RESTART_ACTION_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_2_2_RESTART_ACTION_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_2_3_READY=YES"
  exit 0
else
  echo "FAZ_2_7_2_2_RESTART_ACTION_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_2_2_RESTART_ACTION_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_2_2_RESTART_ACTION_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_2_2_RESTART_ACTION_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_2_3_READY=NO"
  exit 1
fi
