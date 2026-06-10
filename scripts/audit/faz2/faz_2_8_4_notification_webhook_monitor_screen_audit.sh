#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_8_4_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-8.4 NOTIFICATION / WEBHOOK MONITOR SCREEN REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 runtime file"
check_file "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 test file"
check_file "web/ops-console/notification-webhook-monitor/index.html" "2-8.4 html screen file"
check_file "configs/faz2/ops_console/notification_webhook_monitor_screen.v1.json" "2-8.4 config file"
check_file "docs/faz2/ops_console/FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN.md" "2-8.4 documentation file"

check_grep "NotificationWebhookMonitorConsoleRuntime" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 console runtime type"
check_grep "NotificationWebhookMonitorEntry" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 monitor entry model"
check_grep "NotificationWebhookMonitorSnapshot" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 snapshot model"
check_grep "UpsertDelivery" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 upsert delivery function"
check_grep "BuildSnapshot" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 build snapshot function"
check_grep "NotificationMonitorChannelEmail" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 email channel"
check_grep "NotificationMonitorChannelSMS" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 sms channel"
check_grep "NotificationMonitorChannelPush" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 push channel"
check_grep "NotificationMonitorChannelWebhook" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 webhook channel"
check_grep "NotificationMonitorStateRetryScheduled" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 retry scheduled state"
check_grep "NotificationMonitorStateDLQ" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 dlq state"
check_grep "ErrNotificationMonitorCrossTenant" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 cross tenant guard"
check_grep "SignatureTrace" "internal/platform/ops/console/notification_webhook_monitor_console.go" "2-8.4 signature trace field"

check_grep "TestNotificationWebhookMonitorConsoleRuntimeBuildsSnapshot" "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 build snapshot test"
check_grep "TestNotificationWebhookMonitorConsoleRuntimeChannelFilter" "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 channel filter test"
check_grep "TestNotificationWebhookMonitorConsoleRuntimeStateFilter" "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 state filter test"
check_grep "TestNotificationWebhookMonitorConsoleRuntimeWebhookOnly" "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 webhook only test"
check_grep "TestNotificationWebhookMonitorConsoleRuntimeHidesFailedWhenDisabled" "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 failed dlq visibility test"
check_grep "TestNotificationWebhookMonitorConsoleRuntimeRejectsMissingTenant" "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 missing tenant test"
check_grep "TestNotificationWebhookMonitorConsoleRuntimeRejectsCrossTenantViewer" "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 cross tenant viewer test"
check_grep "TestNotificationWebhookMonitorConsoleRuntimeRejectsInvalidChannel" "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 invalid channel test"
check_grep "TestNotificationWebhookMonitorConsoleRuntimeRejectsInvalidState" "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 invalid state test"
check_grep "TestNotificationWebhookMonitorConsoleRuntimeRejectsMissingDestination" "internal/platform/ops/console/notification_webhook_monitor_console_test.go" "2-8.4 missing destination test"

check_grep "Notification / Webhook Monitor" "web/ops-console/notification-webhook-monitor/index.html" "2-8.4 html title"
check_grep "Tenant:" "web/ops-console/notification-webhook-monitor/index.html" "2-8.4 tenant indicator"
check_grep "Delivered" "web/ops-console/notification-webhook-monitor/index.html" "2-8.4 delivered metric"
check_grep "Webhook" "web/ops-console/notification-webhook-monitor/index.html" "2-8.4 webhook metric"
check_grep "Retry Scheduled" "web/ops-console/notification-webhook-monitor/index.html" "2-8.4 retry metric"
check_grep "Failed" "web/ops-console/notification-webhook-monitor/index.html" "2-8.4 failed metric"
check_grep "DLQ" "web/ops-console/notification-webhook-monitor/index.html" "2-8.4 dlq metric"
check_grep "Delivery Stream" "web/ops-console/notification-webhook-monitor/index.html" "2-8.4 delivery stream table"
check_grep "Webhook Detail" "web/ops-console/notification-webhook-monitor/index.html" "2-8.4 webhook detail panel"
check_grep "responsive" "docs/faz2/ops_console/FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN.md" "2-8.4 responsive documentation trace"

echo "===== FAZ 2-8.4 GO TEST ====="
if go test ./internal/platform/ops/console; then
  GO_TEST_STATUS="PASS"
  pass_check "2-8.4 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-8.4 go test"
fi

echo "===== FAZ 2-8.4 NOTIFICATION / WEBHOOK MONITOR SCREEN REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN_TEST_STATUS=PASS"
  echo "FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN_FINAL_STATUS=PASS"
  echo "FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN_SEAL_STATUS=SEALED"
  echo "FAZ_2_8_6_READY=YES"
  exit 0
else
  echo "FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN_FINAL_STATUS=FAIL"
  echo "FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN_SEAL_STATUS=OPEN"
  echo "FAZ_2_8_6_READY=NO"
  exit 1
fi
