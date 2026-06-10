#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/pix2pi/pix2pi-SaaS}"
cd "$REPO_DIR"

EVIDENCE_FILE="${FAZ_2_7_4_4_EVIDENCE_FILE:-docs/faz2/evidence/FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md}"
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

echo "===== FAZ 2-7.4.4 WEBHOOK SIGNING + DELIVERY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

check_file "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 runtime file"
check_file "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 test file"
check_file "configs/faz2/ops_runtime/webhook_signing_delivery_runtime.v1.json" "2-7.4.4 config file"
check_file "docs/faz2/ops_runtime/FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME.md" "2-7.4.4 documentation file"

check_grep "WebhookSigningDeliveryRuntime" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 WebhookSigningDeliveryRuntime type"
check_grep "WebhookDeliveryRequest" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 webhook request model"
check_grep "WebhookDeliveryRecord" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 webhook record model"
check_grep "WebhookDeliveryDecision" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 webhook decision model"
check_grep "DispatchWebhook" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 dispatch webhook function"
check_grep "VerifySignature" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 verify signature function"
check_grep "BuildWebhookSignature" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 hmac signature builder"
check_grep "BuildWebhookSignatureHeader" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 signature header builder"
check_grep "GetDelivery" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 get delivery function"
check_grep "ListTenantDeliveries" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 tenant delivery list function"
check_grep "ListTenantEventDeliveries" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 tenant event delivery list function"
check_grep "WebhookDeliveryProviderSimulation" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 simulation provider"
check_grep "WebhookDeliveryProviderHTTP" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 http provider"
check_grep "WebhookDeliveryMethodPOST" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 post method"
check_grep "WebhookDeliveryMethodPUT" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 put method"
check_grep "WebhookDeliveryStateQueued" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 queued state"
check_grep "WebhookDeliveryStateDelivered" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 delivered state"
check_grep "ErrWebhookDeliveryCrossTenant" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 tenant-safe webhook guard"
check_grep "ErrWebhookDeliveryDuplicateIdempotency" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 duplicate idempotency guard"
check_grep "ErrWebhookDeliverySignatureMismatch" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 signature mismatch guard"
check_grep "isValidWebhookURL" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 url validation helper"
check_grep "webhookDeliveryIdempotencyKey" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 tenant scoped idempotency key"
check_grep "NewWebhookDeliveryID" "internal/platform/ops/runtime/webhook_signing_delivery_runtime.go" "2-7.4.4 delivery id generator"

check_grep "TestWebhookSigningDeliveryRuntimeDispatchesWebhook" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 dispatch webhook test"
check_grep "TestWebhookSigningDeliveryRuntimeVerifiesSignature" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 verifies signature test"
check_grep "TestWebhookSigningDeliveryRuntimeRejectsSignatureMismatch" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 signature mismatch test"
check_grep "TestWebhookSigningDeliveryRuntimeRejectsMissingTenant" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 missing tenant test"
check_grep "TestWebhookSigningDeliveryRuntimeRejectsMissingURL" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 missing url test"
check_grep "TestWebhookSigningDeliveryRuntimeRejectsInvalidURL" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 invalid url test"
check_grep "TestWebhookSigningDeliveryRuntimeRejectsInvalidProvider" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 invalid provider test"
check_grep "TestWebhookSigningDeliveryRuntimeRejectsInvalidMethod" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 invalid method test"
check_grep "TestWebhookSigningDeliveryRuntimeRejectsMissingEventType" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 missing event type test"
check_grep "TestWebhookSigningDeliveryRuntimeRejectsMissingPayload" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 missing payload test"
check_grep "TestWebhookSigningDeliveryRuntimeRejectsMissingSecret" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 missing secret test"
check_grep "TestWebhookSigningDeliveryRuntimeRejectsDuplicateIdempotency" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 duplicate idempotency test"
check_grep "TestWebhookSigningDeliveryRuntimeIdempotencyIsTenantScoped" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 tenant scoped idempotency test"
check_grep "TestWebhookSigningDeliveryRuntimeTenantSafeAccess" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 tenant safe access test"
check_grep "TestWebhookSigningDeliveryRuntimeQueuedWhenNotDryRunOnly" "internal/platform/ops/runtime/webhook_signing_delivery_runtime_test.go" "2-7.4.4 queued when not dry-run test"

echo "===== FAZ 2-7.4.4 GO TEST ====="
if go test ./internal/platform/ops/runtime; then
  GO_TEST_STATUS="PASS"
  pass_check "2-7.4.4 go test"
else
  GO_TEST_STATUS="FAIL"
  fail_check "2-7.4.4 go test"
fi

echo "===== FAZ 2-7.4.4 WEBHOOK SIGNING + DELIVERY RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "GO_TEST_STATUS=${GO_TEST_STATUS}"
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_STATUS=PASS"
  echo "FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME_TEST_STATUS=PASS"
  echo "FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME_FINAL_STATUS=PASS"
  echo "FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME_SEAL_STATUS=SEALED"
  echo "FAZ_2_7_4_5_READY=YES"
  exit 0
else
  echo "FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME_REAL_IMPLEMENTATION_STATUS=FAIL"
  echo "FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME_TEST_STATUS=${GO_TEST_STATUS}"
  echo "FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME_FINAL_STATUS=FAIL"
  echo "FAZ_2_7_4_4_WEBHOOK_SIGNING_DELIVERY_RUNTIME_SEAL_STATUS=OPEN"
  echo "FAZ_2_7_4_5_READY=NO"
  exit 1
fi
