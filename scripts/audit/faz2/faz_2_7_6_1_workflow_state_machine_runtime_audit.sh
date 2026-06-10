#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_6_1_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.6.1 WORKFLOW STATE MACHINE RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 runtime file"
check_file "internal/platform/workflow/runtime/workflow_state_machine_test.go" "2-7.6.1 test file"
check_file "configs/faz2/workflow/workflow_state_machine_runtime.v1.json" "2-7.6.1 config file"
check_file "docs/faz2/workflow/FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME.md" "2-7.6.1 documentation file"

check_grep "WorkflowStateMachine" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 state machine type"
check_grep "CanTransition" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 transition guard"
check_grep "Transition\\(" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 transition function"
check_grep "WorkflowStateWaitingApproval" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 approval wait state"
check_grep "WorkflowStateFailed" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 failed state"
check_grep "WorkflowStateCompensating|WorkflowStateCompensated" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 compensation states"
check_grep "ErrWorkflowCrossTenant" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 tenant-safe guard"
check_grep "WorkflowTransitionEvent" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 audit event model"
check_grep "WorkflowReasonInvalidTransition" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 invalid transition reason"
check_grep "WorkflowReasonTerminalState" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.1 terminal transition guard"
check_grep "TestWorkflowStateMachineHappyPath" "internal/platform/workflow/runtime/workflow_state_machine_test.go" "2-7.6.1 happy path test"
check_grep "TestWorkflowStateMachineRejectsCrossTenant" "internal/platform/workflow/runtime/workflow_state_machine_test.go" "2-7.6.1 cross tenant test"
check_grep "TestWorkflowStateMachineFailedCompensationPath" "internal/platform/workflow/runtime/workflow_state_machine_test.go" "2-7.6.1 compensation path test"

echo "===== FAZ 2-7.6.1 GO TEST ====="
if go test ./internal/platform/workflow/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.6.1 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.6.1 go test"
fi

echo "===== FAZ 2-7.6.1 WORKFLOW STATE MACHINE RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_6_2_READY=YES"
  exit 0
else
  echo "FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_6_1_WORKFLOW_STATE_MACHINE_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_6_2_READY=NO"
  exit 1
fi
