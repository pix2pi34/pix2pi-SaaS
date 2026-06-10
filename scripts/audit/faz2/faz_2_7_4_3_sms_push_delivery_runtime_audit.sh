#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_4_3_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.4.3 SMS / PUSH DELIVERY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 runtime file"
check_file "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 test file"
check_file "configs/faz2/ops_runtime/sms_push_delivery_runtime.v1.json" "2-7.4.3 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME.md" "2-7.4.3 documentation file"

check_grep "SMSPushDeliveryRuntime" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 SMSPushDeliveryRuntime type"
check_grep "SMSPushDeliveryRequest" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 sms push request model"
check_grep "SMSPushDeliveryRecord" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 sms push record model"
check_grep "SMSPushDeliveryDecision" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 sms push decision model"
check_grep "DispatchSMS" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 dispatch sms function"
check_grep "DispatchPush" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 dispatch push function"
check_grep "Dispatch" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 generic dispatch function"
check_grep "GetDelivery" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 get delivery function"
check_grep "ListTenantDeliveries" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 tenant delivery list function"
check_grep "ListTenantChannelDeliveries" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 tenant channel delivery list function"
check_grep "SMSPushDeliveryChannelSMS" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 sms channel"
check_grep "SMSPushDeliveryChannelPush" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 push channel"
check_grep "SMSPushDeliveryProviderSimulation" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 simulation provider"
check_grep "SMSPushDeliveryProviderSMSGateway" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 sms gateway provider"
check_grep "SMSPushDeliveryProviderPushGateway" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 push gateway provider"
check_grep "SMSPushDeliveryStateQueued" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 queued state"
check_grep "SMSPushDeliveryStateDelivered" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 delivered state"
check_grep "ErrSMSPushDeliveryCrossTenant" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 tenant-safe delivery guard"
check_grep "ErrSMSPushDeliveryDuplicateIdempotency" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 duplicate idempotency guard"
check_grep "firstInvalidPhoneNumber" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 phone validation helper"
check_grep "firstInvalidDeviceToken" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 device token validation helper"
check_grep "smsPushDeliveryIdempotencyKey" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 tenant channel scoped idempotency key"
check_grep "NewSMSPushDeliveryID" "internal/platform/ops/runtime/sms_push_delivery_runtime.go" "2-7.4.3 delivery id generator"

check_grep "TestSMSPushDeliveryRuntimeDispatchesSMS" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 dispatch sms test"
check_grep "TestSMSPushDeliveryRuntimeDispatchesPush" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 dispatch push test"
check_grep "TestSMSPushDeliveryRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 missing tenant test"
check_grep "TestSMSPushDeliveryRuntimeRejectsInvalidChannel" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 invalid channel test"
check_grep "TestSMSPushDeliveryRuntimeRejectsInvalidProvider" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 invalid provider test"
check_grep "TestSMSPushDeliveryRuntimeRejectsMissingSMSRecipient" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 missing sms recipient test"
check_grep "TestSMSPushDeliveryRuntimeRejectsInvalidPhone" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 invalid phone test"
check_grep "TestSMSPushDeliveryRuntimeRejectsInvalidDeviceToken" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 invalid device token test"
check_grep "TestSMSPushDeliveryRuntimeRejectsTooManyRecipients" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 too many recipients test"
check_grep "TestSMSPushDeliveryRuntimeRejectsMissingMessage" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 missing message test"
check_grep "TestSMSPushDeliveryRuntimeRejectsDuplicateIdempotency" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 duplicate idempotency test"
check_grep "TestSMSPushDeliveryRuntimeIdempotencyIsTenantAndChannelScoped" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 tenant channel scoped idempotency test"
check_grep "TestSMSPushDeliveryRuntimeTenantSafeAccess" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 tenant safe access test"
check_grep "TestSMSPushDeliveryRuntimeQueuedWhenNotDryRunOnly" "internal/platform/ops/runtime/sms_push_delivery_runtime_test.go" "2-7.4.3 queued when not dry-run test"

echo "===== FAZ 2-7.4.3 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.4.3 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.4.3 go test"
fi

echo "===== FAZ 2-7.4.3 SMS / PUSH DELIVERY RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_4_4_READY=YES"
  exit 0
else
  echo "FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_4_3_SMS_PUSH_DELIVERY_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_4_4_READY=NO"
  exit 1
fi
