#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_2_6_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_2_6_MISSION_CONTROL_RUNTIME_TESTS_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.2.6 MISSION CONTROL RUNTIME TESTS REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/restart_action_runtime.go" "2-7.2.6 restart action runtime file"
check_file "internal/platform/ops/runtime/isolate_quarantine_action_runtime.go" "2-7.2.6 isolate quarantine runtime file"
check_file "internal/platform/ops/runtime/maintenance_mode_runtime.go" "2-7.2.6 maintenance mode runtime file"
check_file "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.6 incident note action log runtime file"
check_file "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final integration test file"
check_file "configs/faz2/ops_runtime/mission_control_runtime_tests.v1.json" "2-7.2.6 final closure config"
check_file "docs/faz2/ops_runtime/FAZ_2_7_2_6_MISSION_CONTROL_RUNTIME_TESTS.md" "2-7.2.6 final closure documentation"

check_grep "TestMissionControlRuntimeFinalActionLifecycle" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 mission control final lifecycle test"
check_grep "TestMissionControlRuntimeFinalCrossTenantDenyFlow" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 cross tenant deny final test"
check_grep "TestMissionControlRuntimeFinalUnauthorizedDenyFlow" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 unauthorized operator deny final test"

check_grep "RequestRestart" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test uses restart runtime"
check_grep "RequestIsolateOrQuarantine" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test uses isolate quarantine runtime"
check_grep "ApplyMaintenanceMode" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test uses maintenance mode runtime"
check_grep "CreateIncidentNote" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test uses incident note runtime"
check_grep "RecordIncidentAction" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test uses incident action log runtime"

check_grep "restart_action_id" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks restart metadata bridge"
check_grep "isolate_quarantine_action_state" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks quarantine metadata bridge"
check_grep "maintenance_mode_state" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks maintenance metadata bridge"
check_grep "ListTenantAuditEvents" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks audit bridge"
check_grep "ListInstanceIncidentActionLogs" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks incident log bridge"

check_grep "ErrRestartActionCrossTenant" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks restart cross tenant deny"
check_grep "ErrIsolateQuarantineCrossTenant" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks quarantine cross tenant deny"
check_grep "ErrMaintenanceModeCrossTenant" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks maintenance cross tenant deny"
check_grep "ErrIncidentActionLogCrossTenant" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks incident cross tenant deny"

check_grep "ErrRestartActionUnauthorizedOperator" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks restart unauthorized deny"
check_grep "ErrIsolateQuarantineUnauthorizedOperator" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks quarantine unauthorized deny"
check_grep "ErrMaintenanceModeUnauthorizedOperator" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks maintenance unauthorized deny"
check_grep "ErrIncidentActionLogUnauthorizedOperator" "internal/platform/ops/runtime/mission_control_runtime_final_test.go" "2-7.2.6 final test checks incident unauthorized deny"

echo "===== FAZ 2-7.2.6 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.2.6 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.2.6 go test"
fi

echo "===== FAZ 2-7.2.6 MISSION CONTROL RUNTIME TESTS REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_2_6_MISSION_CONTROL_RUNTIME_TESTS_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_2_6_MISSION_CONTROL_RUNTIME_TESTS_TEST_STATUS=PASS"
  echo "FAZ_2_7_2_6_MISSION_CONTROL_RUNTIME_TESTS_FINAL_STATUS=PASS"
  echo "FAZ_2_7_2_6_MISSION_CONTROL_RUNTIME_TESTS_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_2_MISSION_CONTROL_RUNTIME_BLOCK_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_2_1_READY=YES"
  exit 0
else
  echo "FAZ_2_7_2_6_MISSION_CONTROL_RUNTIME_TESTS_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_2_6_MISSION_CONTROL_RUNTIME_TESTS_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_2_6_MISSION_CONTROL_RUNTIME_TESTS_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_2_6_MISSION_CONTROL_RUNTIME_TESTS_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_2_MISSION_CONTROL_RUNTIME_BLOCK_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_2_1_READY=NO"
  exit 1
fi
