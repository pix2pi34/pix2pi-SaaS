#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_8_2_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_8_2_MISSION_CONTROL_SCREEN_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-8.2 MISSION CONTROL SCREEN REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 runtime file"
check_file "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 test file"
check_file "web/ops-console/mission-control/index.html" "2-8.2 html screen file"
check_file "configs/faz2/ops_console/mission_control_screen.v1.json" "2-8.2 config file"
check_file "docs/faz2/ops_console/FAZ_2_8_2_MISSION_CONTROL_SCREEN.md" "2-8.2 documentation file"

check_grep "MissionControlScreenConsoleRuntime" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 console runtime type"
check_grep "MissionControlActionEntry" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 action entry model"
check_grep "MissionControlScreenSnapshot" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 snapshot model"
check_grep "RecordAction" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 record action function"
check_grep "BuildSnapshot" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 build snapshot function"
check_grep "MissionControlActionRestart" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 restart action"
check_grep "MissionControlActionIsolate" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 isolate action"
check_grep "MissionControlActionQuarantine" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 quarantine action"
check_grep "MissionControlActionMaintenance" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 maintenance action"
check_grep "MissionControlActionNote" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 incident note action"
check_grep "MissionControlOperatorRoleViewer" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 viewer role"
check_grep "MissionControlOperatorRoleOperator" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 operator role"
check_grep "MissionControlOperatorRoleAdmin" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 admin role"
check_grep "ErrMissionControlScreenCrossTenant" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 cross tenant guard"
check_grep "ErrMissionControlScreenUnauthorizedRole" "internal/platform/ops/console/mission_control_screen_console.go" "2-8.2 unauthorized role guard"

check_grep "TestMissionControlScreenConsoleRuntimeBuildsSnapshot" "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 build snapshot test"
check_grep "TestMissionControlScreenConsoleRuntimeHidesExecutedWhenDisabled" "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 executed visibility test"
check_grep "TestMissionControlScreenConsoleRuntimeActionFilter" "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 action filter test"
check_grep "TestMissionControlScreenConsoleRuntimeStatusFilter" "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 status filter test"
check_grep "TestMissionControlScreenConsoleRuntimeRejectsMissingTenant" "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 missing tenant test"
check_grep "TestMissionControlScreenConsoleRuntimeRejectsCrossTenantViewer" "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 cross tenant viewer test"
check_grep "TestMissionControlScreenConsoleRuntimeRejectsViewerMutation" "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 viewer mutation deny test"
check_grep "TestMissionControlScreenConsoleRuntimeRejectsInvalidActionType" "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 invalid action type test"
check_grep "TestMissionControlScreenConsoleRuntimeRejectsInvalidStatus" "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 invalid status test"
check_grep "TestMissionControlScreenConsoleRuntimeRejectsMissingMessage" "internal/platform/ops/console/mission_control_screen_console_test.go" "2-8.2 missing message test"

check_grep "Mission Control" "web/ops-console/mission-control/index.html" "2-8.2 html title"
check_grep "Tenant:" "web/ops-console/mission-control/index.html" "2-8.2 tenant indicator"
check_grep "Requested Actions" "web/ops-console/mission-control/index.html" "2-8.2 requested actions metric"
check_grep "Approved" "web/ops-console/mission-control/index.html" "2-8.2 approved metric"
check_grep "Quarantine" "web/ops-console/mission-control/index.html" "2-8.2 quarantine metric"
check_grep "Maintenance" "web/ops-console/mission-control/index.html" "2-8.2 maintenance metric"
check_grep "Mission Actions" "web/ops-console/mission-control/index.html" "2-8.2 mission actions table"
check_grep "Control Actions" "web/ops-console/mission-control/index.html" "2-8.2 control actions panel"
check_grep "responsive" "docs/faz2/ops_console/FAZ_2_8_2_MISSION_CONTROL_SCREEN.md" "2-8.2 responsive documentation trace"

echo "===== FAZ 2-8.2 GO TEST ====="
if go test ./internal/platform/ops/console; then
  GO_TEST_STATUS="PASS"
  pass_check "2-8.2 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-8.2 go test"
fi

echo "===== FAZ 2-8.2 MISSION CONTROL SCREEN REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_8_2_MISSION_CONTROL_SCREEN_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_8_2_MISSION_CONTROL_SCREEN_TEST_STATUS=PASS"
  echo "FAZ_2_8_2_MISSION_CONTROL_SCREEN_FINAL_STATUS=PASS"
  echo "FAZ_2_8_2_MISSION_CONTROL_SCREEN_SEAL_STATUS=SEALED"
  echo "FAZ_2_8_5_READY=YES"
  exit 0
else
  echo "FAZ_2_8_2_MISSION_CONTROL_SCREEN_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_8_2_MISSION_CONTROL_SCREEN_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_8_2_MISSION_CONTROL_SCREEN_FINAL_STATUS=FAIL"
  echo "FAZ_2_8_2_MISSION_CONTROL_SCREEN_SEAL_STATUS=OPEN"
  echo "FAZ_2_8_5_READY=NO"
  exit 1
fi
