#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_6_4_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.6.4 RETRY / COMPENSATION RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 runtime file"
check_file "internal/platform/workflow/runtime/retry_compensation_runtime_test.go" "2-7.6.4 test file"
check_file "configs/faz2/workflow/retry_compensation_runtime.v1.json" "2-7.6.4 config file"
check_file "docs/faz2/workflow/FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME.md" "2-7.6.4 documentation file"

check_grep "WorkflowRetryCompensationRuntime" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 retry compensation runtime type"
check_grep "WorkflowRetryAttempt" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 retry attempt model"
check_grep "WorkflowRetryRuntimePolicy" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 retry policy model"
check_grep "CalculateRetryBackoffSeconds" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 backoff calculator"
check_grep "WorkflowRetryBackoffFixed|WorkflowRetryBackoffLinear|WorkflowRetryBackoffExponential" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 backoff strategies"
check_grep "DecideFailedStep" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 failed step decision runtime"
check_grep "WorkflowRetryActionRetry|WorkflowRetryActionCompensate" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 retry or compensation decision"
check_grep "WorkflowCompensationRecord" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 compensation record model"
check_grep "RequestCompensation" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 request compensation runtime"
check_grep "StartCompensation" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 start compensation runtime"
check_grep "CompleteCompensation" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 complete compensation runtime"
check_grep "ErrWorkflowCompensationCrossTenant" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 tenant-safe compensation guard"
check_grep "ApplyCompensationStartToWorkflow" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 compensation start workflow bridge"
check_grep "ApplyCompensationCompleteToWorkflow" "internal/platform/workflow/runtime/retry_compensation_runtime.go" "2-7.6.4 compensation complete workflow bridge"

check_grep "TestWorkflowRetryRuntimeSchedulesRetryWithExponentialBackoff" "internal/platform/workflow/runtime/retry_compensation_runtime_test.go" "2-7.6.4 retry scheduling test"
check_grep "TestWorkflowRetryRuntimeExhaustionRequiresCompensation" "internal/platform/workflow/runtime/retry_compensation_runtime_test.go" "2-7.6.4 retry exhaustion compensation test"
check_grep "TestCalculateRetryBackoffSeconds" "internal/platform/workflow/runtime/retry_compensation_runtime_test.go" "2-7.6.4 backoff test"
check_grep "TestWorkflowCompensationRuntimeLifecycle" "internal/platform/workflow/runtime/retry_compensation_runtime_test.go" "2-7.6.4 compensation lifecycle test"
check_grep "TestWorkflowCompensationRuntimeRejectsCrossTenantAccess" "internal/platform/workflow/runtime/retry_compensation_runtime_test.go" "2-7.6.4 cross tenant compensation test"
check_grep "TestWorkflowCompensationRuntimeBridgeToStateMachine" "internal/platform/workflow/runtime/retry_compensation_runtime_test.go" "2-7.6.4 compensation workflow bridge test"

echo "===== FAZ 2-7.6.4 GO TEST ====="
if go test ./internal/platform/workflow/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.6.4 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.6.4 go test"
fi

echo "===== FAZ 2-7.6.4 RETRY / COMPENSATION RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_6_5_READY=YES"
  exit 0
else
  echo "FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_6_4_RETRY_COMPENSATION_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_6_5_READY=NO"
  exit 1
fi
