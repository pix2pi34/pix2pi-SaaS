#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_8_5_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-8.5 EARLY WARNING / ALERT DASHBOARD REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 runtime file"
check_file "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 test file"
check_file "web/ops-console/early-warning-alert-dashboard/index.html" "2-8.5 html screen file"
check_file "configs/faz2/ops_console/early_warning_alert_dashboard.v1.json" "2-8.5 config file"
check_file "docs/faz2/ops_console/FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD.md" "2-8.5 documentation file"

check_grep "EarlyWarningAlertDashboardConsoleRuntime" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 console runtime type"
check_grep "EarlyWarningRuleEntry" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 alert rule model"
check_grep "EarlyWarningAlertEntry" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 alert entry model"
check_grep "EarlyWarningDashboardSnapshot" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 dashboard snapshot model"
check_grep "UpsertRule" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 upsert rule function"
check_grep "RaiseAlert" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 raise alert function"
check_grep "AcknowledgeAlert" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 acknowledge alert function"
check_grep "ResolveAlert" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 resolve alert function"
check_grep "BuildSnapshot" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 build snapshot function"
check_grep "EarlyWarningSourceRuntimeHealth" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 runtime health source"
check_grep "EarlyWarningSourceJobQueue" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 job queue source"
check_grep "EarlyWarningSourceWebhook" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 webhook source"
check_grep "EarlyWarningSourceDatabase" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 database source"
check_grep "EarlyWarningSourceSecurity" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 security source"
check_grep "EarlyWarningSourceEventBus" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 event bus source"
check_grep "ErrEarlyWarningDashboardCrossTenant" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 cross tenant guard"
check_grep "ErrEarlyWarningDashboardMissingOperatorID" "internal/platform/ops/console/early_warning_alert_dashboard_console.go" "2-8.5 missing operator guard"

check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeBuildsSnapshot" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 build snapshot test"
check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeHidesResolvedWhenDisabled" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 resolved visibility test"
check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeFiltersSource" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 source filter test"
check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeFiltersSeverity" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 severity filter test"
check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeAcknowledgeAndResolve" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 acknowledge resolve test"
check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeRejectsMissingTenant" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 missing tenant test"
check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeRejectsCrossTenantViewer" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 cross tenant viewer test"
check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeRejectsInvalidSource" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 invalid source test"
check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeRejectsInvalidSeverity" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 invalid severity test"
check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeRejectsInvalidStatus" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 invalid status test"
check_grep "TestEarlyWarningAlertDashboardConsoleRuntimeRejectsMissingOperatorForTransition" "internal/platform/ops/console/early_warning_alert_dashboard_console_test.go" "2-8.5 missing operator transition test"

check_grep "Early Warning / Alert Dashboard" "web/ops-console/early-warning-alert-dashboard/index.html" "2-8.5 html title"
check_grep "Tenant:" "web/ops-console/early-warning-alert-dashboard/index.html" "2-8.5 tenant indicator"
check_grep "Open Alerts" "web/ops-console/early-warning-alert-dashboard/index.html" "2-8.5 open alerts metric"
check_grep "Critical" "web/ops-console/early-warning-alert-dashboard/index.html" "2-8.5 critical metric"
check_grep "Acknowledged" "web/ops-console/early-warning-alert-dashboard/index.html" "2-8.5 acknowledged metric"
check_grep "Resolved" "web/ops-console/early-warning-alert-dashboard/index.html" "2-8.5 resolved metric"
check_grep "Alert Stream" "web/ops-console/early-warning-alert-dashboard/index.html" "2-8.5 alert stream table"
check_grep "Alert Rules" "web/ops-console/early-warning-alert-dashboard/index.html" "2-8.5 alert rules panel"
check_grep "responsive" "docs/faz2/ops_console/FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD.md" "2-8.5 responsive documentation trace"

echo "===== FAZ 2-8.5 GO TEST ====="
if go test ./internal/platform/ops/console; then
  GO_TEST_STATUS="PASS"
  pass_check "2-8.5 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-8.5 go test"
fi

echo "===== FAZ 2-8.5 EARLY WARNING / ALERT DASHBOARD REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD_TEST_STATUS=PASS"
  echo "FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD_FINAL_STATUS=PASS"
  echo "FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD_SEAL_STATUS=SEALED"
  echo "ONCELIK_5_WEB_L3_PLATFORM_OPERATIONS_CONSOLE_STEP_96_DONE=YES"
  exit 0
else
  echo "FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD_FINAL_STATUS=FAIL"
  echo "FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD_SEAL_STATUS=OPEN"
  echo "ONCELIK_5_WEB_L3_PLATFORM_OPERATIONS_CONSOLE_STEP_96_DONE=NO"
  exit 1
fi
