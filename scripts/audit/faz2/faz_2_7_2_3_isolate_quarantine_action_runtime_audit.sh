#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_2_3_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.2.3 ISOLATE / QUARANTINE ACTION RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 runtime file"
check_file "internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go" "2-7.2.3 test file"
check_file "configs/faz2/ops_runtime/isolate_quarantine_action_runtime.v1.json" "2-7.2.3 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME.md" "2-7.2.3 documentation file"

check_grep "IsolateQuarantineActionRuntime" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 IsolateQuarantineActionRuntime type"
check_grep "IsolateQuarantineActionRequest" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 action request model"
check_grep "IsolateQuarantineActionRecord" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 action record model"
check_grep "IsolateQuarantineDecision" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 decision model"
check_grep "IsolateQuarantineAuditEvent" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 audit event model"
check_grep "RequestIsolateOrQuarantine" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 request isolate quarantine function"
check_grep "IsolateQuarantineActionTypeIsolate" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 isolate action type"
check_grep "IsolateQuarantineActionTypeQuarantine" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 quarantine action type"
check_grep "IsolateQuarantineStateIsolateRequested" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 isolate state model"
check_grep "IsolateQuarantineStateQuarantineRequested" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 quarantine state model"
check_grep "ErrIsolateQuarantineCrossTenant" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 tenant-safe quarantine guard"
check_grep "ErrIsolateQuarantineUnauthorizedOperator" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 unauthorized operator guard"
check_grep "ErrIsolateQuarantineInvalidActionType" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 invalid action type guard"
check_grep "UpsertMetadata" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 metadata bridge"
check_grep "isolate_quarantine_action_id" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 quarantine metadata key"
check_grep "appendAudit" "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.3 audit log bridge"

check_grep "TestIsolateQuarantineActionRuntimeRequestsIsolate" "internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go" "2-7.2.3 isolate request test"
check_grep "TestIsolateQuarantineActionRuntimeRequestsQuarantine" "internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go" "2-7.2.3 quarantine request test"
check_grep "TestIsolateQuarantineActionRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go" "2-7.2.3 missing tenant test"
check_grep "TestIsolateQuarantineActionRuntimeRejectsMissingRegistry" "internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go" "2-7.2.3 missing registry test"
check_grep "TestIsolateQuarantineActionRuntimeRejectsInvalidActionType" "internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go" "2-7.2.3 invalid action type test"
check_grep "TestIsolateQuarantineActionRuntimeRejectsUnauthorizedOperator" "internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go" "2-7.2.3 unauthorized operator test"
check_grep "TestIsolateQuarantineActionRuntimeRejectsCrossTenantInstance" "internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go" "2-7.2.3 cross tenant instance test"
check_grep "TestIsolateQuarantineActionRuntimeTenantSafeActionAccess" "internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go" "2-7.2.3 tenant safe action access test"
check_grep "TestIsolateQuarantineStateForType" "internal/platform/ops/runtime/isolate_quarantine_action_runtime_test.go" "2-7.2.3 state for type test"

echo "===== FAZ 2-7.2.3 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.2.3 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.2.3 go test"
fi

echo "===== FAZ 2-7.2.3 ISOLATE / QUARANTINE ACTION RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_2_4_READY=YES"
  exit 0
else
  echo "FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_2_3_ISOLATE_QUARANTINE_ACTION_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_2_4_READY=NO"
  exit 1
fi
