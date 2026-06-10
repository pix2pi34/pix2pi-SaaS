#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_6_2_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.6.2 WORKFLOW DEFINITION LOADER RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 runtime file"
check_file "internal/platform/workflow/runtime/workflow_definition_loader_test.go" "2-7.6.2 test file"
check_file "configs/faz2/workflow/workflow_definition_loader_runtime.v1.json" "2-7.6.2 config file"
check_file "docs/faz2/workflow/FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME.md" "2-7.6.2 documentation file"

check_grep "WorkflowDefinition" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 workflow definition model"
check_grep "WorkflowStepDefinition" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 step definition model"
check_grep "WorkflowApprovalStepDefinition" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 approval step definition"
check_grep "WorkflowRetryPolicyDefinition" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 retry policy definition"
check_grep "WorkflowCompensationDefinition" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 compensation definition"
check_grep "LoadJSON" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 JSON loader"
check_grep "ValidateWorkflowDefinition" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 definition validation"
check_grep "ErrWorkflowDefinitionCrossTenant" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 tenant-safe loader guard"
check_grep "WorkflowDefinitionReasonDuplicateStep" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 duplicate step guard"
check_grep "WorkflowDefinitionReasonMissingApprovalPolicy" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 approval policy guard"
check_grep "WorkflowDefinitionReasonMissingCompensationStep" "internal/platform/workflow/runtime/workflow_definition_loader.go" "2-7.6.2 compensation guard"

check_grep "TestWorkflowDefinitionLoaderLoadsValidDefinition" "internal/platform/workflow/runtime/workflow_definition_loader_test.go" "2-7.6.2 valid definition test"
check_grep "TestWorkflowDefinitionLoaderRejectsCrossTenantDefinition" "internal/platform/workflow/runtime/workflow_definition_loader_test.go" "2-7.6.2 cross tenant test"
check_grep "TestWorkflowDefinitionLoaderRejectsApprovalWithoutPolicy" "internal/platform/workflow/runtime/workflow_definition_loader_test.go" "2-7.6.2 approval policy test"
check_grep "TestWorkflowDefinitionLoaderRejectsMissingCompensationStep" "internal/platform/workflow/runtime/workflow_definition_loader_test.go" "2-7.6.2 compensation validation test"

echo "===== FAZ 2-7.6.2 GO TEST ====="
if go test ./internal/platform/workflow/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.6.2 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.6.2 go test"
fi

echo "===== FAZ 2-7.6.2 WORKFLOW DEFINITION LOADER RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_6_3_READY=YES"
  exit 0
else
  echo "FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_6_2_WORKFLOW_DEFINITION_LOADER_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_6_3_READY=NO"
  exit 1
fi
