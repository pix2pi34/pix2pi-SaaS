#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_6_5_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.6.5 WORKFLOW OBSERVABILITY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 runtime file"
check_file "internal/platform/workflow/runtime/workflow_observability_runtime_test.go" "2-7.6.5 test file"
check_file "configs/faz2/workflow/workflow_observability_runtime.v1.json" "2-7.6.5 config file"
check_file "docs/faz2/workflow/FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME.md" "2-7.6.5 documentation file"

check_grep "WorkflowObservabilityRuntime" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 observability runtime type"
check_grep "WorkflowMetricSnapshot" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 metric snapshot model"
check_grep "StateTransitionCounters" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 state transition counters"
check_grep "ApprovalCounters" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 approval counters"
check_grep "RetryCounters" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 retry counters"
check_grep "CompensationCounters" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 compensation counters"
check_grep "FailedWorkflowCounters" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 failed workflow counters"
check_grep "RecordTransition" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 record transition metric"
check_grep "RecordApproval" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 record approval metric"
check_grep "RecordRetryDecision" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 record retry metric"
check_grep "RecordCompensation" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 record compensation metric"
check_grep "Snapshot" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 snapshot runtime"
check_grep "ErrWorkflowObservabilityMissingTenant" "internal/platform/workflow/runtime/workflow_observability_runtime.go" "2-7.6.5 tenant-safe observability guard"

check_grep "TestWorkflowObservabilityRuntimeRecordsStateTransitions" "internal/platform/workflow/runtime/workflow_observability_runtime_test.go" "2-7.6.5 transition counter test"
check_grep "TestWorkflowObservabilityRuntimeRecordsApprovalCounters" "internal/platform/workflow/runtime/workflow_observability_runtime_test.go" "2-7.6.5 approval counter test"
check_grep "TestWorkflowObservabilityRuntimeRecordsRetryCounters" "internal/platform/workflow/runtime/workflow_observability_runtime_test.go" "2-7.6.5 retry counter test"
check_grep "TestWorkflowObservabilityRuntimeRecordsCompensationCounters" "internal/platform/workflow/runtime/workflow_observability_runtime_test.go" "2-7.6.5 compensation counter test"
check_grep "TestWorkflowObservabilityRuntimeTenantSafeSnapshots" "internal/platform/workflow/runtime/workflow_observability_runtime_test.go" "2-7.6.5 tenant-safe snapshot test"
check_grep "TestWorkflowObservabilityRuntimeRejectsMissingTenant" "internal/platform/workflow/runtime/workflow_observability_runtime_test.go" "2-7.6.5 missing tenant test"

echo "===== FAZ 2-7.6.5 GO TEST ====="
if go test ./internal/platform/workflow/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.6.5 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.6.5 go test"
fi

echo "===== FAZ 2-7.6.5 WORKFLOW OBSERVABILITY RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_6_6_READY=YES"
  exit 0
else
  echo "FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_6_5_WORKFLOW_OBSERVABILITY_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_6_6_READY=NO"
  exit 1
fi
