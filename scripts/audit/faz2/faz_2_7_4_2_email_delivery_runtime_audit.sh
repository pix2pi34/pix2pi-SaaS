#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_4_2_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.4.2 EMAIL DELIVERY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 runtime file"
check_file "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 test file"
check_file "configs/faz2/ops_runtime/email_delivery_runtime.v1.json" "2-7.4.2 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME.md" "2-7.4.2 documentation file"

check_grep "EmailDeliveryRuntime" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 EmailDeliveryRuntime type"
check_grep "EmailDeliveryRequest" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 email delivery request model"
check_grep "EmailDeliveryRecord" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 email delivery record model"
check_grep "EmailDeliveryDecision" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 email delivery decision model"
check_grep "DispatchEmail" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 dispatch email function"
check_grep "GetDelivery" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 get delivery function"
check_grep "ListTenantDeliveries" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 tenant delivery list function"
check_grep "ListRecipientDeliveries" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 recipient delivery list function"
check_grep "EmailDeliveryProviderSimulation" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 simulation provider"
check_grep "EmailDeliveryProviderSMTP" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 smtp provider"
check_grep "EmailDeliveryStateQueued" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 queued state"
check_grep "EmailDeliveryStateDelivered" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 delivered state"
check_grep "ErrEmailDeliveryCrossTenant" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 tenant-safe email delivery guard"
check_grep "ErrEmailDeliveryDuplicateIdempotency" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 duplicate idempotency guard"
check_grep "firstInvalidEmailRecipient" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 recipient validation helper"
check_grep "emailDeliveryIdempotencyKey" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 tenant scoped idempotency key"
check_grep "NewEmailDeliveryID" "internal/platform/ops/runtime/email_delivery_runtime.go" "2-7.4.2 delivery id generator"

check_grep "TestEmailDeliveryRuntimeDispatchesEmail" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 dispatch email test"
check_grep "TestEmailDeliveryRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 missing tenant test"
check_grep "TestEmailDeliveryRuntimeRejectsMissingRecipient" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 missing recipient test"
check_grep "TestEmailDeliveryRuntimeRejectsInvalidRecipient" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 invalid recipient test"
check_grep "TestEmailDeliveryRuntimeRejectsTooManyRecipients" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 too many recipients test"
check_grep "TestEmailDeliveryRuntimeRejectsMissingSubject" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 missing subject test"
check_grep "TestEmailDeliveryRuntimeRejectsMissingBody" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 missing body test"
check_grep "TestEmailDeliveryRuntimeRejectsInvalidProvider" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 invalid provider test"
check_grep "TestEmailDeliveryRuntimeRejectsDuplicateIdempotency" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 duplicate idempotency test"
check_grep "TestEmailDeliveryRuntimeIdempotencyIsTenantScoped" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 tenant scoped idempotency test"
check_grep "TestEmailDeliveryRuntimeTenantSafeAccess" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 tenant safe access test"
check_grep "TestEmailDeliveryRuntimeQueuedWhenNotDryRunOnly" "internal/platform/ops/runtime/email_delivery_runtime_test.go" "2-7.4.2 queued when not dry-run test"

echo "===== FAZ 2-7.4.2 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.4.2 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.4.2 go test"
fi

echo "===== FAZ 2-7.4.2 EMAIL DELIVERY RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_4_3_READY=YES"
  exit 0
else
  echo "FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_4_2_EMAIL_DELIVERY_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_4_3_READY=NO"
  exit 1
fi
