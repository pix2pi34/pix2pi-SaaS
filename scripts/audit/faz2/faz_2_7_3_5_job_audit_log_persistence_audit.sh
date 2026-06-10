#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_3_5_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.3.5 JOB AUDIT LOG PERSISTENCE REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 runtime file"
check_file "internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go" "2-7.3.5 test file"
check_file "configs/faz2/ops_runtime/job_audit_log_persistence.v1.json" "2-7.3.5 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE.md" "2-7.3.5 documentation file"

check_grep "JobAuditLogPersistenceRuntime" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 JobAuditLogPersistenceRuntime type"
check_grep "JobAuditLogRequest" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 audit request model"
check_grep "JobAuditLogRecord" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 audit record model"
check_grep "JobAuditLogDecision" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 audit decision model"
check_grep "RecordJobAuditLog" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 record audit log function"
check_grep "RecordFromJob" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 record from job bridge"
check_grep "GetAuditLog" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 get audit log function"
check_grep "ListTenantAuditLogs" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 tenant audit list function"
check_grep "ListJobAuditLogs" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 job audit list function"
check_grep "JobAuditEventQueued" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 queued audit event"
check_grep "JobAuditEventDispatched" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 dispatched audit event"
check_grep "JobAuditEventFailed" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 failed audit event"
check_grep "JobAuditSeverityError" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 severity model"
check_grep "ErrJobAuditCrossTenant" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 tenant-safe audit guard"
check_grep "ErrJobAuditMissingMessage" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 missing message guard"
check_grep "NewJobAuditLogID" "internal/platform/ops/runtime/job_audit_log_persistence_runtime.go" "2-7.3.5 audit id generator"

check_grep "TestJobAuditLogPersistenceRuntimeRecordsAuditLog" "internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go" "2-7.3.5 record audit log test"
check_grep "TestJobAuditLogPersistenceRuntimeRecordsFromJob" "internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go" "2-7.3.5 record from job test"
check_grep "TestJobAuditLogPersistenceRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go" "2-7.3.5 missing tenant test"
check_grep "TestJobAuditLogPersistenceRuntimeRejectsMissingJobID" "internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go" "2-7.3.5 missing job id test"
check_grep "TestJobAuditLogPersistenceRuntimeRejectsInvalidEventType" "internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go" "2-7.3.5 invalid event type test"
check_grep "TestJobAuditLogPersistenceRuntimeRejectsInvalidSeverity" "internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go" "2-7.3.5 invalid severity test"
check_grep "TestJobAuditLogPersistenceRuntimeRejectsMissingMessage" "internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go" "2-7.3.5 missing message test"
check_grep "TestJobAuditLogPersistenceRuntimeTenantSafeAccess" "internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go" "2-7.3.5 tenant safe access test"
check_grep "TestJobAuditLogPersistenceRuntimeMultipleEventsForJob" "internal/platform/ops/runtime/job_audit_log_persistence_runtime_test.go" "2-7.3.5 multiple events for job test"

echo "===== FAZ 2-7.3.5 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.3.5 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.3.5 go test"
fi

echo "===== FAZ 2-7.3.5 JOB AUDIT LOG PERSISTENCE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE_TEST_STATUS=PASS"
  echo "FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE_FINAL_STATUS=PASS"
  echo "FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_3_6_READY=YES"
  exit 0
else
  echo "FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_3_5_JOB_AUDIT_LOG_PERSISTENCE_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_3_6_READY=NO"
  exit 1
fi
