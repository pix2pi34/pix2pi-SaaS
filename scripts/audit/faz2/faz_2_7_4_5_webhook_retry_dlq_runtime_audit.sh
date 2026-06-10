#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_4_5_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.4.5 WEBHOOK RETRY / DLQ RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 runtime file"
check_file "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 test file"
check_file "configs/faz2/ops_runtime/webhook_retry_dlq_runtime.v1.json" "2-7.4.5 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME.md" "2-7.4.5 documentation file"

check_grep "WebhookRetryDLQRuntime" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 WebhookRetryDLQRuntime type"
check_grep "WebhookRetryRequest" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 webhook retry request model"
check_grep "WebhookRetryRecord" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 webhook retry record model"
check_grep "WebhookDLQRecord" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 webhook dlq record model"
check_grep "WebhookRetryDLQDecision" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 retry dlq decision model"
check_grep "ScheduleRetry" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 schedule retry function"
check_grep "MarkRetryCompleted" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 mark retry completed function"
check_grep "MoveToDLQ" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 move to dlq function"
check_grep "GetRetry" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 get retry function"
check_grep "GetDLQ" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 get dlq function"
check_grep "ListTenantRetries" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 tenant retries list function"
check_grep "ListTenantDLQ" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 tenant dlq list function"
check_grep "ListDeliveryRetries" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 delivery retries list function"
check_grep "CalculateWebhookRetryBackoffSeconds" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 exponential backoff calculator"
check_grep "WebhookRetryStateScheduled" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 retry scheduled state"
check_grep "WebhookRetryStateCompleted" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 retry completed state"
check_grep "WebhookRetryStateDLQ" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 dlq state"
check_grep "ErrWebhookRetryCrossTenant" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 tenant-safe retry dlq guard"
check_grep "ErrWebhookRetryDuplicateRetry" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 duplicate retry guard"
check_grep "ErrWebhookRetryDLQDisabled" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 dlq disabled guard"
check_grep "NewWebhookRetryID" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 retry id generator"
check_grep "NewWebhookDLQID" "internal/platform/ops/runtime/webhook_retry_dlq_runtime.go" "2-7.4.5 dlq id generator"

check_grep "TestWebhookRetryDLQRuntimeSchedulesRetry" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 schedule retry test"
check_grep "TestWebhookRetryDLQRuntimeCalculatesBackoff" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 backoff calculator test"
check_grep "TestWebhookRetryDLQRuntimeMarksRetryCompleted" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 mark retry completed test"
check_grep "TestWebhookRetryDLQRuntimeMovesToDLQ" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 move to dlq test"
check_grep "TestWebhookRetryDLQRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 missing tenant test"
check_grep "TestWebhookRetryDLQRuntimeRejectsMissingDeliveryID" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 missing delivery id test"
check_grep "TestWebhookRetryDLQRuntimeRejectsMissingEventType" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 missing event type test"
check_grep "TestWebhookRetryDLQRuntimeRejectsMissingPayloadHash" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 missing payload hash test"
check_grep "TestWebhookRetryDLQRuntimeRejectsMissingError" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 missing error test"
check_grep "TestWebhookRetryDLQRuntimeRejectsInvalidAttempt" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 invalid attempt test"
check_grep "TestWebhookRetryDLQRuntimeRejectsMaxAttemptsExceeded" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 max attempts exceeded test"
check_grep "TestWebhookRetryDLQRuntimeRejectsDuplicateRetry" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 duplicate retry test"
check_grep "TestWebhookRetryDLQRuntimeTenantSafeAccess" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 tenant safe retry access test"
check_grep "TestWebhookRetryDLQRuntimeTenantSafeDLQAccess" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 tenant safe dlq access test"
check_grep "TestWebhookRetryDLQRuntimeRejectsDLQWhenDisabled" "internal/platform/ops/runtime/webhook_retry_dlq_runtime_test.go" "2-7.4.5 dlq disabled test"

echo "===== FAZ 2-7.4.5 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.4.5 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.4.5 go test"
fi

echo "===== FAZ 2-7.4.5 WEBHOOK RETRY / DLQ RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_4_NOTIFICATION_RUNTIME_BLOCK_SEAL_STATUS=SEALED"
  echo "ONCELIK_4_LVL15_OPS_RUNTIME_CLOSURE_STEP_88_DONE=YES"
  exit 0
else
  echo "FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_4_5_WEBHOOK_RETRY_DLQ_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_4_NOTIFICATION_RUNTIME_BLOCK_SEAL_STATUS=OPEN"
  echo "ONCELIK_4_LVL15_OPS_RUNTIME_CLOSURE_STEP_88_DONE=NO"
  exit 1
fi
