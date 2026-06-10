#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_6_3_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.6.3 MANUAL APPROVAL RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 runtime file"
check_file "internal/platform/workflow/runtime/manual_approval_runtime_test.go" "2-7.6.3 test file"
check_file "configs/faz2/workflow/manual_approval_runtime.v1.json" "2-7.6.3 config file"
check_file "docs/faz2/workflow/FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME.md" "2-7.6.3 documentation file"

check_grep "ManualApprovalRuntime" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 ManualApprovalRuntime type"
check_grep "ManualApprovalRequest" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 approval request model"
check_grep "ManualApprovalDecision" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 approval decision model"
check_grep "CreateApprovalRequest" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 create approval lifecycle"
check_grep "Decide" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 approve reject lifecycle"
check_grep "RequiredRole|hasApprovalRole" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 role approver guard"
check_grep "ApplyDecisionToWorkflow" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 approval wait state bridge"
check_grep "ErrApprovalCrossTenant" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 tenant-safe approval guard"
check_grep "ApprovalRequestStatusApproved" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 approved status"
check_grep "ApprovalRequestStatusRejected" "internal/platform/workflow/runtime/manual_approval_runtime.go" "2-7.6.3 rejected status"

check_grep "TestManualApprovalRuntimeApproveLifecycle" "internal/platform/workflow/runtime/manual_approval_runtime_test.go" "2-7.6.3 approve lifecycle test"
check_grep "TestManualApprovalRuntimeRejectLifecycle" "internal/platform/workflow/runtime/manual_approval_runtime_test.go" "2-7.6.3 reject lifecycle test"
check_grep "TestManualApprovalRuntimeRejectsWrongRole" "internal/platform/workflow/runtime/manual_approval_runtime_test.go" "2-7.6.3 role guard test"
check_grep "TestManualApprovalRuntimeRejectsCrossTenantAccess" "internal/platform/workflow/runtime/manual_approval_runtime_test.go" "2-7.6.3 cross tenant test"
check_grep "ApprovalWaitStateBridgeApprove" "internal/platform/workflow/runtime/manual_approval_runtime_test.go" "2-7.6.3 approval bridge approve test"
check_grep "ApprovalWaitStateBridgeReject" "internal/platform/workflow/runtime/manual_approval_runtime_test.go" "2-7.6.3 approval bridge reject test"

echo "===== FAZ 2-7.6.3 GO TEST ====="
if go test ./internal/platform/workflow/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.6.3 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.6.3 go test"
fi

echo "===== FAZ 2-7.6.3 MANUAL APPROVAL RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_6_4_READY=YES"
  exit 0
else
  echo "FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_6_3_MANUAL_APPROVAL_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_6_4_READY=NO"
  exit 1
fi
