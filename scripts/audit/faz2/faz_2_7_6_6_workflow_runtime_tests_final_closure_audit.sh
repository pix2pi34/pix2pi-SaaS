#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_6_6_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_6_6_WORKFLOW_RUNTIME_TESTS_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.6.6 WORKFLOW RUNTIME TESTS FINAL CLOSURE AUDIT START ====="

check_file "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.6 state machine runtime file"
check_file "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.6 definition loader runtime file"
check_file "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.6 manual approval runtime file"
check_file "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.6 retry compensation runtime file"
check_file "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.6 observability runtime file"
check_file "internal/platform/workflow/runtime/workflow_runtime_final_test.go" "2-7.6.6 final test file"
check_file "configs/faz2/workflow/workflow_runtime_tests_final_closure.v1.json" "2-7.6.6 final closure config"
check_file "docs/faz2/workflow/FAZ_2_7_6_6_WORKFLOW_RUNTIME_TESTS_FINAL_CLOSURE.md" "2-7.6.6 final closure documentation"

check_grep "TestWorkflowRuntimeFinalEndToEndApprovalRetryCompensationObservability" "internal/platform/workflow/runtime/workflow_runtime_final_test.go" "2-7.6.6 workflow E2E final test"
check_grep "TestWorkflowRuntimeFinalCrossTenantDenyAcrossModules" "internal/platform/workflow/runtime/workflow_runtime_final_test.go" "2-7.6.6 cross-tenant deny final test"

check_grep "WorkflowStateMachine" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.6 state machine implemented"
check_grep "WorkflowDefinitionLoader" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.6 definition loader implemented"
check_grep "ManualApprovalRuntime" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.6 manual approval implemented"
check_grep "WorkflowRetryCompensationRuntime" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.6 retry compensation implemented"
check_grep "WorkflowObservabilityRuntime" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.6 observability implemented"

check_grep "ErrWorkflowCrossTenant" "internal/platform/workflow/runtime/workflow_state_machine.go" "2-7.6.6 state cross-tenant guard"
check_grep "ErrWorkflowDefinitionCrossTenant" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.6 definition cross-tenant guard"
check_grep "ErrApprovalCrossTenant" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.6 approval cross-tenant guard"
check_grep "ErrWorkflowCompensationCrossTenant" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.6 compensation cross-tenant guard"
check_grep "ErrWorkflowObservabilityMissingTenant" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.6 observability tenant guard"

check_grep "LoadJSON" "internal/platform/workflow/runtime/workflow_runtime_final_test.go" "2-7.6.6 final test uses definition loader"
check_grep "CreateApprovalRequest" "internal/platform/workflow/runtime/workflow_runtime_final_test.go" "2-7.6.6 final test uses approval runtime"
check_grep "DecideFailedStep" "internal/platform/workflow/runtime/workflow_runtime_final_test.go" "2-7.6.6 final test uses retry runtime"
check_grep "RequestCompensation" "internal/platform/workflow/runtime/workflow_runtime_final_test.go" "2-7.6.6 final test uses compensation runtime"
check_grep "Snapshot" "internal/platform/workflow/runtime/workflow_runtime_final_test.go" "2-7.6.6 final test uses observability snapshot"

echo "===== FAZ 2-7.6.6 GO TEST ====="
if go test ./internal/platform/workflow/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.6.6 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.6.6 go test"
fi

echo "===== FAZ 2-7.6.6 WORKFLOW RUNTIME TESTS FINAL CLOSURE AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_6_6_WORKFLOW_RUNTIME_TESTS_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_6_6_WORKFLOW_RUNTIME_TESTS_TEST_STATUS=PASS"
  echo "FAZ_2_7_6_6_WORKFLOW_RUNTIME_TESTS_FINAL_STATUS=PASS"
  echo "FAZ_2_7_6_WORKFLOW_RUNTIME_BLOCK_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_8_2_READY=YES"
  exit 0
else
  echo "FAZ_2_7_6_6_WORKFLOW_RUNTIME_TESTS_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_6_6_WORKFLOW_RUNTIME_TESTS_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_6_6_WORKFLOW_RUNTIME_TESTS_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_6_WORKFLOW_RUNTIME_BLOCK_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_8_2_READY=NO"
  exit 1
fi
