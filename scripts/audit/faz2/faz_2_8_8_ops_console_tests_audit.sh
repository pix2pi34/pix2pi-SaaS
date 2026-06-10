#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_8_8_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_8_8_OPS_CONSOLE_TESTS_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-8.8 OPS CONSOLE TESTS REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 final test file"
check_file "configs/faz2/ops_console/ops_console_tests.v1.json" "2-8.8 config file"
check_file "docs/faz2/ops_console/FAZ_2_8_8_OPS_CONSOLE_TESTS.md" "2-8.8 documentation file"

check_file "internal/platform/ops/console/job_queue_worker_monitor_console.go" "2-8.8 job monitor runtime file"
check_file "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.8 notification monitor runtime file"
check_file "internal/platform/ops/console/incident_audit_center_console.go" "2-8.8 incident audit runtime file"
check_file "internal/platform/ops/console/runtime_health_topology_console.go" "2-8.8 runtime topology runtime file"

check_file "web/ops-console/job-worker-monitor/index.html" "2-8.8 job monitor html file"
check_file "web/ops-console/notification-webhook-monitor/index.html" "2-8.8 notification monitor html file"
check_file "web/ops-console/incident-audit-center/index.html" "2-8.8 incident audit html file"
check_file "web/ops-console/runtime-health-topology/index.html" "2-8.8 runtime topology html file"

check_grep "TestOpsConsoleFinalJobNotificationIncidentTopologyE2E" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 final E2E test"
check_grep "TestOpsConsoleFinalCrossTenantDenySet" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 cross tenant deny final test"
check_grep "TestOpsConsoleFinalHTMLCheckpointsExist" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 html checkpoint final test"
check_grep "TestOpsConsoleFinalConfigAndDocsCheckpointsExist" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 config docs checkpoint final test"

check_grep "NewJobQueueWorkerMonitorConsoleRuntime" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 job runtime usage"
check_grep "NewNotificationWebhookMonitorConsoleRuntime" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 notification runtime usage"
check_grep "NewIncidentAuditCenterConsoleRuntime" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 incident audit runtime usage"
check_grep "NewRuntimeHealthTopologyConsoleRuntime" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 topology runtime usage"

check_grep "ErrJobMonitorCrossTenant" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 job cross tenant guard test"
check_grep "ErrNotificationMonitorCrossTenant" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 notification cross tenant guard test"
check_grep "ErrIncidentAuditCrossTenant" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 incident cross tenant guard test"
check_grep "ErrRuntimeTopologyCrossTenant" "internal/platform/ops/console/ops_console_final_tests_test.go" "2-8.8 topology cross tenant guard test"

check_grep "Job Queue / Worker Monitor" "web/ops-console/job-worker-monitor/index.html" "2-8.8 job html title"
check_grep "Notification / Webhook Monitor" "web/ops-console/notification-webhook-monitor/index.html" "2-8.8 notification html title"
check_grep "Incident / Audit Center" "web/ops-console/incident-audit-center/index.html" "2-8.8 incident html title"
check_grep "Runtime Health / Topology" "web/ops-console/runtime-health-topology/index.html" "2-8.8 topology html title"

check_grep "FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN" "configs/faz2/ops_console/ops_console_tests.v1.json" "2-8.8 covers 2-8.3"
check_grep "FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN" "configs/faz2/ops_console/ops_console_tests.v1.json" "2-8.8 covers 2-8.4"
check_grep "FAZ_2_8_6_INCIDENT_AUDIT_CENTER" "configs/faz2/ops_console/ops_console_tests.v1.json" "2-8.8 covers 2-8.6"
check_grep "FAZ_2_8_7_RUNTIME_HEALTH_TOPOLOGY_VIEW" "configs/faz2/ops_console/ops_console_tests.v1.json" "2-8.8 covers 2-8.7"

echo "===== FAZ 2-8.8 GO TEST ====="
if go test ./internal/platform/ops/console; then
  GO_TEST_STATUS="PASS"
  pass_check "2-8.8 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-8.8 go test"
fi

echo "===== FAZ 2-8.8 OPS CONSOLE TESTS REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_8_8_OPS_CONSOLE_TESTS_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_8_8_OPS_CONSOLE_TESTS_TEST_STATUS=PASS"
  echo "FAZ_2_8_8_OPS_CONSOLE_TESTS_FINAL_STATUS=PASS"
  echo "FAZ_2_8_8_OPS_CONSOLE_TESTS_SEAL_STATUS=SEALED"
  echo "FAZ_2_8_1_READY=YES"
  exit 0
else
  echo "FAZ_2_8_8_OPS_CONSOLE_TESTS_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_8_8_OPS_CONSOLE_TESTS_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_8_8_OPS_CONSOLE_TESTS_FINAL_STATUS=FAIL"
  echo "FAZ_2_8_8_OPS_CONSOLE_TESTS_SEAL_STATUS=OPEN"
  echo "FAZ_2_8_1_READY=NO"
  exit 1
fi
