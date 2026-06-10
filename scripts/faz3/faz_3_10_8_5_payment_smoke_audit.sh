#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 MISSING_OR_FAILED / FAIL ❌"
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label file_missing=${file}"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern}"
  fi
}

run_go_test() {
  local label="$1"
  local pkg="$2"

  if go test "$pkg"; then
    pass "$label"
  else
    fail "$label"
  fi
}

echo "===== 156 — FAZ 3-10.8.5 PAYMENT SMOKE REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/smoke/payment/payment_smoke.go"
TEST_FILE="internal/erp/turkiye/smoke/payment/payment_smoke_test.go"
CONFIG_FILE="configs/faz3/smoke/payment_smoke.v1.json"
DOC_FILE="docs/faz3/smoke/FAZ_3_10_8_5_PAYMENT_SMOKE.md"

check_file "156 payment smoke runtime file" "$RUNTIME_FILE"
check_file "156 payment smoke test file" "$TEST_FILE"
check_file "156 payment smoke config file" "$CONFIG_FILE"
check_file "156 payment smoke documentation file" "$DOC_FILE"

check_file "156 POS provider evidence file" "docs/faz3/evidence/FAZ_3_10_7_1_POS_PROVIDER_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_file "156 bank collection evidence file" "docs/faz3/evidence/FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_file "156 reconciliation evidence file" "docs/faz3/evidence/FAZ_3_10_7_3_RECONCILIATION_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_file "156 refund cancel evidence file" "docs/faz3/evidence/FAZ_3_10_7_4_REFUND_CANCEL_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_file "156 status sync evidence file" "docs/faz3/evidence/FAZ_3_10_7_3_PAYMENT_STATUS_SYNC_REAL_IMPLEMENTATION_AUDIT.md"
check_file "156 error retry evidence file" "docs/faz3/evidence/FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_file "156 integration audit evidence file" "docs/faz3/evidence/FAZ_3_10_7_5_INTEGRATION_AUDIT_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"
check_file "156 integration tests evidence file" "docs/faz3/evidence/FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

check_grep "156 runtime constructor" "$RUNTIME_FILE" "NewPaymentSmokeRuntime"
check_grep "156 smoke run runtime" "$RUNTIME_FILE" "Run"
check_grep "156 request validation runtime" "$RUNTIME_FILE" "validateRequest"
check_grep "156 module evidence runtime" "$RUNTIME_FILE" "moduleEvidence"
check_grep "156 smoke hash builder" "$RUNTIME_FILE" "buildSmokeHash"

check_grep "156 smoke request model" "$RUNTIME_FILE" "type SmokeRequest"
check_grep "156 smoke result model" "$RUNTIME_FILE" "type SmokeResult"
check_grep "156 module evidence model" "$RUNTIME_FILE" "type ModuleEvidence"

check_grep "156 POS module" "$RUNTIME_FILE" "ModulePOSProvider"
check_grep "156 bank collection module" "$RUNTIME_FILE" "ModuleBankCollection"
check_grep "156 reconciliation module" "$RUNTIME_FILE" "ModuleReconciliation"
check_grep "156 refund cancel module" "$RUNTIME_FILE" "ModuleRefundCancel"
check_grep "156 status sync module" "$RUNTIME_FILE" "ModuleStatusSync"
check_grep "156 error retry module" "$RUNTIME_FILE" "ModuleErrorRetry"
check_grep "156 integration audit module" "$RUNTIME_FILE" "ModuleIntegrationAudit"
check_grep "156 integration tests module" "$RUNTIME_FILE" "ModuleIntegrationTests"

check_grep "156 real payment gate closed check" "$RUNTIME_FILE" "CheckRealPaymentGateClosed"
check_grep "156 provider operation check" "$RUNTIME_FILE" "CheckProviderOperation"
check_grep "156 bank operation check" "$RUNTIME_FILE" "CheckBankOperation"
check_grep "156 reconciliation check" "$RUNTIME_FILE" "CheckReconciliation"
check_grep "156 refund cancel check" "$RUNTIME_FILE" "CheckRefundCancel"
check_grep "156 status sync check" "$RUNTIME_FILE" "CheckStatusSync"
check_grep "156 retry DLQ check" "$RUNTIME_FILE" "CheckRetryDLQ"
check_grep "156 manual review check" "$RUNTIME_FILE" "CheckManualReview"
check_grep "156 integration audit check" "$RUNTIME_FILE" "CheckIntegrationAudit"
check_grep "156 E2E flow check" "$RUNTIME_FILE" "CheckE2EFlow"

check_grep "156 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "156 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "156 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "156 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "156 smoke id guard" "$RUNTIME_FILE" "smoke_id is required"
check_grep "156 requested at guard" "$RUNTIME_FILE" "requested_at is required"

check_grep "156 pass test" "$TEST_FILE" "TestPaymentSmokePasses"
check_grep "156 all modules test" "$TEST_FILE" "TestPaymentSmokeCoversAllModules"
check_grep "156 real payment gate test" "$TEST_FILE" "TestPaymentSmokeKeepsRealPaymentGateClosed"
check_grep "156 provider bank reconciliation test" "$TEST_FILE" "TestPaymentSmokeCoversProviderBankReconciliation"
check_grep "156 refund status retry audit E2E test" "$TEST_FILE" "TestPaymentSmokeCoversRefundStatusRetryAuditE2E"
check_grep "156 guard coverage test" "$TEST_FILE" "TestPaymentSmokeHasTenantCorrelationIdempotencyGuards"
check_grep "156 missing tenant test" "$TEST_FILE" "TestPaymentSmokeRejectsMissingTenant"
check_grep "156 minimum pass count test" "$TEST_FILE" "TestPaymentSmokeRejectsMinimumPassCount"

check_grep "156 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "156 config require all modules" "$CONFIG_FILE" "\"require_all_modules\": true"
check_grep "156 config POS required" "$CONFIG_FILE" "\"require_pos_provider\": true"
check_grep "156 config bank collection required" "$CONFIG_FILE" "\"require_bank_collection\": true"
check_grep "156 config reconciliation required" "$CONFIG_FILE" "\"require_reconciliation\": true"
check_grep "156 config refund cancel required" "$CONFIG_FILE" "\"require_refund_cancel\": true"
check_grep "156 config status sync required" "$CONFIG_FILE" "\"require_status_sync\": true"
check_grep "156 config error retry required" "$CONFIG_FILE" "\"require_error_retry\": true"
check_grep "156 config integration audit required" "$CONFIG_FILE" "\"require_integration_audit\": true"
check_grep "156 config integration tests required" "$CONFIG_FILE" "\"require_integration_tests\": true"
check_grep "156 config real payment gate closed required" "$CONFIG_FILE" "\"require_real_payment_gate_closed\": true"
check_grep "156 config smoke hash required" "$CONFIG_FILE" "\"require_smoke_hash\": true"
check_grep "156 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "156 config real payment closed" "$CONFIG_FILE" "\"real_payment_gate_status\": \"CLOSED\""
check_grep "156 config real bank closed" "$CONFIG_FILE" "\"real_bank_gate_status\": \"CLOSED\""
check_grep "156 config previous gate" "$CONFIG_FILE" "FAZ_3_10_8_4_EXPORT_SMOKE"
check_grep "156 config next gate" "$CONFIG_FILE" "FAZ_3_R_FINAL_CLOSURE"

run_go_test "156 POS provider go test status" "./internal/erp/turkiye/payment/pos"
run_go_test "156 bank collection go test status" "./internal/erp/turkiye/payment/bankcollection"
run_go_test "156 reconciliation go test status" "./internal/erp/turkiye/payment/reconciliation"
run_go_test "156 refund cancel go test status" "./internal/erp/turkiye/payment/refundcancel"
run_go_test "156 payment status sync go test status" "./internal/erp/turkiye/payment/statussync"
run_go_test "156 payment error retry go test status" "./internal/erp/turkiye/payment/errorretry"
run_go_test "156 integration audit go test status" "./internal/erp/turkiye/payment/integrationaudit"
run_go_test "156 payment integration tests go test status" "./internal/erp/turkiye/payment/integrationtests"
run_go_test "156 payment smoke go test status" "./internal/erp/turkiye/smoke/payment"

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 156 — FAZ 3-10.8.5 — Payment Smoke Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_8_5_PAYMENT_SMOKE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_8_5_PAYMENT_SMOKE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_R_FINAL_CLOSURE_READY=${NEXT_READY}

## Scope

- POS provider runtime smoke
- Bank collection runtime smoke
- Reconciliation runtime smoke
- Refund / cancel runtime smoke
- Payment status sync smoke
- Payment error / retry / reversal smoke
- Payment integration audit runtime smoke
- Payment integration tests smoke
- Tenant / correlation / idempotency guard check
- Real payment gate closed check
- Real bank gate closed check
- Production approved false check
- Smoke hash generation

## Live Policy

- Production public/live approval: FALSE
- Real payment calls: CLOSED
- Real bank calls: CLOSED
- This smoke is readiness evidence, not production activation.

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 156 — FAZ 3-10.8.5 PAYMENT SMOKE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_8_5_PAYMENT_SMOKE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_8_5_PAYMENT_SMOKE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_R_FINAL_CLOSURE_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
