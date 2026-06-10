#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_2_5_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.2.5 INCIDENT NOTE / ACTION LOG RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 runtime file"
check_file "internal/platform/ops/runtime/incident_note_action_log_runtime_test.go" "2-7.2.5 test file"
check_file "configs/faz2/ops_runtime/incident_note_action_log_runtime.v1.json" "2-7.2.5 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME.md" "2-7.2.5 documentation file"

check_grep "IncidentNoteActionLogRuntime" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 IncidentNoteActionLogRuntime type"
check_grep "IncidentNoteRequest" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 incident note request model"
check_grep "IncidentActionLogRequest" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 action log request model"
check_grep "IncidentActionLogRecord" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 action log record model"
check_grep "IncidentActionLogDecision" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 action log decision model"
check_grep "CreateIncidentNote" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 create incident note function"
check_grep "RecordIncidentAction" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 record incident action function"
check_grep "GetIncidentActionLog" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 get incident action log function"
check_grep "ListTenantIncidentActionLogs" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 tenant log list function"
check_grep "ListInstanceIncidentActionLogs" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 instance log list function"
check_grep "IncidentActionTypeNote" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 incident note action type"
check_grep "IncidentActionTypeOperatorAction" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 operator action type"
check_grep "IncidentActionSeverityCritical" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 severity model"
check_grep "ErrIncidentActionLogCrossTenant" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 tenant-safe incident log guard"
check_grep "ErrIncidentActionLogUnauthorizedOperator" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 unauthorized operator guard"
check_grep "ErrIncidentActionLogMissingMessage" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 missing message guard"
check_grep "UpsertMetadata" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 metadata bridge"
check_grep "incident_action_log_id" "internal/platform/ops/runtime/incident_note_action_log_runtime.go" "2-7.2.5 incident metadata key"

check_grep "TestIncidentNoteActionLogRuntimeCreatesIncidentNote" "internal/platform/ops/runtime/incident_note_action_log_runtime_test.go" "2-7.2.5 create incident note test"
check_grep "TestIncidentNoteActionLogRuntimeRecordsOperatorAction" "internal/platform/ops/runtime/incident_note_action_log_runtime_test.go" "2-7.2.5 record operator action test"
check_grep "TestIncidentNoteActionLogRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/incident_note_action_log_runtime_test.go" "2-7.2.5 missing tenant test"
check_grep "TestIncidentNoteActionLogRuntimeRejectsMissingRegistry" "internal/platform/ops/runtime/incident_note_action_log_runtime_test.go" "2-7.2.5 missing registry test"
check_grep "TestIncidentNoteActionLogRuntimeRejectsMissingMessage" "internal/platform/ops/runtime/incident_note_action_log_runtime_test.go" "2-7.2.5 missing message test"
check_grep "TestIncidentNoteActionLogRuntimeRejectsInvalidSeverity" "internal/platform/ops/runtime/incident_note_action_log_runtime_test.go" "2-7.2.5 invalid severity test"
check_grep "TestIncidentNoteActionLogRuntimeRejectsUnauthorizedOperator" "internal/platform/ops/runtime/incident_note_action_log_runtime_test.go" "2-7.2.5 unauthorized operator test"
check_grep "TestIncidentNoteActionLogRuntimeRejectsCrossTenantInstance" "internal/platform/ops/runtime/incident_note_action_log_runtime_test.go" "2-7.2.5 cross tenant instance test"
check_grep "TestIncidentNoteActionLogRuntimeTenantSafeLogAccess" "internal/platform/ops/runtime/incident_note_action_log_runtime_test.go" "2-7.2.5 tenant safe log access test"

echo "===== FAZ 2-7.2.5 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.2.5 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.2.5 go test"
fi

echo "===== FAZ 2-7.2.5 INCIDENT NOTE / ACTION LOG RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_2_6_READY=YES"
  exit 0
else
  echo "FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_2_6_READY=NO"
  exit 1
fi
