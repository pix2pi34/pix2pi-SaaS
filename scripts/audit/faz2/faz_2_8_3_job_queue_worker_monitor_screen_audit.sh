#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_8_3_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-8.3 JOB QUEUE / WORKER MONITOR SCREEN REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 runtime file"
check_file "internal/platform/ops/console/job_queue_worker_monitor_console_test.go" "2-8.3 test file"
check_file "web/ops-console/job-worker-monitor/index.html" "2-8.3 html screen file"
check_file "configs/faz2/ops_console/job_queue_worker_monitor_screen.v1.json" "2-8.3 config file"
check_file "docs/faz2/ops_console/FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN.md" "2-8.3 documentation file"

check_grep "JobQueueWorkerMonitorConsoleRuntime" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 console runtime type"
check_grep "JobMonitorEntry" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 job monitor entry model"
check_grep "WorkerMonitorEntry" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 worker monitor entry model"
check_grep "JobQueueWorkerMonitorSnapshot" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 snapshot model"
check_grep "UpsertJob" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 upsert job function"
check_grep "UpsertWorker" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 upsert worker function"
check_grep "BuildSnapshot" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 build snapshot function"
check_grep "JobMonitorStateQueued" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 queued state"
check_grep "JobMonitorStateFailed" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 failed state"
check_grep "JobMonitorStateDLQ" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 dlq state"
check_grep "WorkerMonitorStatusActive" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 active worker status"
check_grep "WorkerMonitorStatusStale" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 stale worker status"
check_grep "ErrJobMonitorCrossTenant" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 cross tenant guard"
check_grep "isWorkerHeartbeatStale" "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.3 stale heartbeat helper"

check_grep "TestJobQueueWorkerMonitorConsoleRuntimeBuildsSnapshot" "internal/platform/ops/console/job_queue_worker_monitor_console_test.go" "2-8.3 build snapshot test"
check_grep "TestJobQueueWorkerMonitorConsoleRuntimeQueueFilter" "internal/platform/ops/console/job_queue_worker_monitor_console_test.go" "2-8.3 queue filter test"
check_grep "TestJobQueueWorkerMonitorConsoleRuntimeHidesFailedJobsWhenDisabled" "internal/platform/ops/console/job_queue_worker_monitor_console_test.go" "2-8.3 failed jobs visibility test"
check_grep "TestJobQueueWorkerMonitorConsoleRuntimeRejectsMissingTenant" "internal/platform/ops/console/job_queue_worker_monitor_console_test.go" "2-8.3 missing tenant test"
check_grep "TestJobQueueWorkerMonitorConsoleRuntimeRejectsCrossTenantViewer" "internal/platform/ops/console/job_queue_worker_monitor_console_test.go" "2-8.3 cross tenant viewer test"
check_grep "TestJobQueueWorkerMonitorConsoleRuntimeRejectsInvalidJobState" "internal/platform/ops/console/job_queue_worker_monitor_console_test.go" "2-8.3 invalid job state test"
check_grep "TestJobQueueWorkerMonitorConsoleRuntimeRejectsInvalidWorkerStatus" "internal/platform/ops/console/job_queue_worker_monitor_console_test.go" "2-8.3 invalid worker status test"
check_grep "TestJobQueueWorkerMonitorConsoleRuntimeDetectsStaleWorker" "internal/platform/ops/console/job_queue_worker_monitor_console_test.go" "2-8.3 stale worker test"

check_grep "Job Queue / Worker Monitor" "web/ops-console/job-worker-monitor/index.html" "2-8.3 html title"
check_grep "Tenant:" "web/ops-console/job-worker-monitor/index.html" "2-8.3 tenant indicator"
check_grep "Queued Jobs" "web/ops-console/job-worker-monitor/index.html" "2-8.3 queued jobs card"
check_grep "Active Workers" "web/ops-console/job-worker-monitor/index.html" "2-8.3 active workers card"
check_grep "Failed Jobs" "web/ops-console/job-worker-monitor/index.html" "2-8.3 failed jobs card"
check_grep "DLQ" "web/ops-console/job-worker-monitor/index.html" "2-8.3 dlq card"
check_grep "Job Queue" "web/ops-console/job-worker-monitor/index.html" "2-8.3 job queue table"
check_grep "Workers" "web/ops-console/job-worker-monitor/index.html" "2-8.3 workers table"
check_grep "responsive" "docs/faz2/ops_console/FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN.md" "2-8.3 responsive documentation trace"

echo "===== FAZ 2-8.3 GO TEST ====="
if go test ./internal/platform/ops/console; then
  GO_TEST_STATUS="PASS"
  pass_check "2-8.3 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-8.3 go test"
fi

echo "===== FAZ 2-8.3 JOB QUEUE / WORKER MONITOR SCREEN REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN_TEST_STATUS=PASS"
  echo "FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN_FINAL_STATUS=PASS"
  echo "FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN_SEAL_STATUS=SEALED"
  echo "FAZ_2_8_4_READY=YES"
  exit 0
else
  echo "FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN_FINAL_STATUS=FAIL"
  echo "FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN_SEAL_STATUS=OPEN"
  echo "FAZ_2_8_4_READY=NO"
  exit 1
fi
