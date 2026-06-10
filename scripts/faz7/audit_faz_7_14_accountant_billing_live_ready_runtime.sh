#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/commercial/liveready/accountant_billing_live_ready_runtime.go"
TEST_FILE="internal/platform/commercial/liveready/accountant_billing_live_ready_runtime_test.go"
CONFIG_FILE="configs/faz7/accountant_billing_live_ready_runtime.json"
DOC_FILE="docs/faz7/commercial/FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

mkdir -p "$(dirname "$EVIDENCE_FILE")"
exec > >(tee "$EVIDENCE_FILE") 2>&1

ok() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 / FAIL ❌"
}

require_file() {
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

require_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

require_not_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && ! grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 7-14 ACCOUNTANT BILLING LIVE-READY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

require_file "7-14.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-14.6.2 test file exists" "$TEST_FILE"
require_file "7-14.6.3 config file exists" "$CONFIG_FILE"
require_file "7-14.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-14.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME"
require_grep "7-14.6.6 billing live-ready mode implemented" "$RUNTIME_FILE" "ACCOUNTANT_BILLING_LIVE_READY_WITH_REAL_BILLING_DISABLED"
require_grep "7-14.6.7 billing gate implemented" "$RUNTIME_FILE" "type AccountantBillingLiveReadyGate struct"
require_grep "7-14.6.8 billing input implemented" "$RUNTIME_FILE" "type AccountantBillingLiveReadyInput struct"
require_grep "7-14.6.9 billing requirement model implemented" "$RUNTIME_FILE" "type AccountantBillingLiveReadyRequirement struct"
require_grep "7-14.6.10 billing issue plan request implemented" "$RUNTIME_FILE" "type AccountantBillingIssuePlanRequest struct"
require_grep "7-14.6.11 billing issue plan implemented" "$RUNTIME_FILE" "type AccountantBillingIssuePlan struct"
require_grep "7-14.6.12 billing report implemented" "$RUNTIME_FILE" "type AccountantBillingLiveReadyReport struct"
require_grep "7-14.6.13 runtime implemented" "$RUNTIME_FILE" "type AccountantBillingLiveReadyRuntime struct"
require_grep "7-14.6.14 build billing report implemented" "$RUNTIME_FILE" "BuildBillingLiveReadyReport"
require_grep "7-14.6.15 build invoice issue plan implemented" "$RUNTIME_FILE" "BuildInvoiceIssuePlan"
require_grep "7-14.6.16 missing billing requirements implemented" "$RUNTIME_FILE" "MissingAccountantBillingLiveReadyRequirements"
require_grep "7-14.6.17 audit event implemented" "$RUNTIME_FILE" "AccountantBillingAuditEvent"

require_grep "7-14.6.18 production billing lock implemented" "$RUNTIME_FILE" "PRODUCTION_BILLING_LOCKED_IN_FAZ_7_14"
require_grep "7-14.6.19 no real invoice policy implemented" "$RUNTIME_FILE" "NO_REAL_INVOICE_ISSUE_IN_FAZ_7_14"
require_grep "7-14.6.20 no real billing policy implemented" "$RUNTIME_FILE" "NO_REAL_BILLING_COMMIT_IN_FAZ_7_14"
require_grep "7-14.6.21 no real payment policy implemented" "$RUNTIME_FILE" "NO_REAL_PAYMENT_CAPTURE_IN_FAZ_7_14"
require_grep "7-14.6.22 no real money policy implemented" "$RUNTIME_FILE" "NO_REAL_MONEY_MOVEMENT_IN_FAZ_7_14"
require_grep "7-14.6.23 no real tax submission policy implemented" "$RUNTIME_FILE" "NO_REAL_TAX_SUBMISSION_IN_FAZ_7_14"
require_grep "7-14.6.24 no real provider API policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_14"
require_grep "7-14.6.25 no real customer data policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_14"

require_grep "7-14.6.26 plan catalog requirement implemented" "$RUNTIME_FILE" "plan_catalog_ready"
require_grep "7-14.6.27 subscription runtime requirement implemented" "$RUNTIME_FILE" "subscription_runtime_ready"
require_grep "7-14.6.28 invoice draft requirement implemented" "$RUNTIME_FILE" "invoice_draft_runtime_ready"
require_grep "7-14.6.29 tenant account requirement implemented" "$RUNTIME_FILE" "tenant_account_binding_ready"
require_grep "7-14.6.30 tax config requirement implemented" "$RUNTIME_FILE" "tax_config_ready"
require_grep "7-14.6.31 idempotency requirement implemented" "$RUNTIME_FILE" "billing_idempotency_ready"
require_grep "7-14.6.32 audit requirement implemented" "$RUNTIME_FILE" "billing_audit_ready"
require_grep "7-14.6.33 rollback requirement implemented" "$RUNTIME_FILE" "billing_rollback_ready"
require_grep "7-14.6.34 legal approval requirement implemented" "$RUNTIME_FILE" "legal_approval_gate_ready"
require_grep "7-14.6.35 finance approval requirement implemented" "$RUNTIME_FILE" "finance_approval_gate_ready"
require_grep "7-14.6.36 security gate requirement implemented" "$RUNTIME_FILE" "security_gate_ready"
require_grep "7-14.6.37 observability requirement implemented" "$RUNTIME_FILE" "billing_observability_ready"

require_grep "7-14.6.38 real invoice blocker implemented" "$RUNTIME_FILE" "RequestRealInvoiceIssue"
require_grep "7-14.6.39 real billing commit blocker implemented" "$RUNTIME_FILE" "RequestRealBillingCommit"
require_grep "7-14.6.40 real payment capture blocker implemented" "$RUNTIME_FILE" "RequestRealPaymentCapture"
require_grep "7-14.6.41 real tax submission blocker implemented" "$RUNTIME_FILE" "RequestRealTaxSubmission"
require_grep "7-14.6.42 real provider API blocker implemented" "$RUNTIME_FILE" "RequestRealProviderAPI"

require_grep "7-14.6.43 VAT calculation implemented" "$RUNTIME_FILE" "VatAmountTRY"
require_grep "7-14.6.44 gross amount calculation implemented" "$RUNTIME_FILE" "GrossAmountTRY"
require_grep "7-14.6.45 idempotency key implemented" "$RUNTIME_FILE" "IdempotencyKey"
require_grep "7-14.6.46 next module 7-15 implemented" "$RUNTIME_FILE" "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME"

require_grep "7-14.6.47 billing report test exists" "$TEST_FILE" "TestSevenFourteenBuildBillingLiveReadyReport"
require_grep "7-14.6.48 missing requirements test exists" "$TEST_FILE" "TestSevenFourteenMissingBillingRequirements"
require_grep "7-14.6.49 invoice issue plan test exists" "$TEST_FILE" "TestSevenFourteenBuildInvoiceIssuePlanNoRealInvoice"
require_grep "7-14.6.50 idempotency test exists" "$TEST_FILE" "TestSevenFourteenInvoiceIssuePlanIdempotency"
require_grep "7-14.6.51 invalid plan test exists" "$TEST_FILE" "TestSevenFourteenRejectInvalidInvoiceIssuePlan"
require_grep "7-14.6.52 real blocker test exists" "$TEST_FILE" "TestSevenFourteenRealBillingOperationBlockers"
require_grep "7-14.6.53 opened gate reject test exists" "$TEST_FILE" "TestSevenFourteenGateRejectsOpenedRealBilling"
require_grep "7-14.6.54 audit trail test exists" "$TEST_FILE" "TestSevenFourteenAuditTrail"

require_grep "7-14.6.55 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME\""
require_grep "7-14.6.56 config mode exists" "$CONFIG_FILE" "\"mode\": \"ACCOUNTANT_BILLING_LIVE_READY_WITH_REAL_BILLING_DISABLED\""
require_grep "7-14.6.57 config depends on 7-13 PASS" "$CONFIG_FILE" "\"faz_7_13_commercial_live_ready_control_plane_final_status\": \"PASS\""
require_grep "7-14.6.58 config production billing false" "$CONFIG_FILE" "\"production_billing_allowed\": false"
require_grep "7-14.6.59 config real invoice false" "$CONFIG_FILE" "\"real_invoice_issue_allowed\": false"
require_grep "7-14.6.60 config real billing commit false" "$CONFIG_FILE" "\"real_billing_commit_allowed\": false"
require_grep "7-14.6.61 config real payment capture false" "$CONFIG_FILE" "\"real_payment_capture_allowed\": false"
require_grep "7-14.6.62 config real money false" "$CONFIG_FILE" "\"real_money_movement_allowed\": false"
require_grep "7-14.6.63 config next module 7-15 exists" "$CONFIG_FILE" "\"next_module\": \"FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME\""

require_grep "7-14.6.64 documentation says live billing is not this phase" "$DOC_FILE" "Bu faz live billing değildir"
require_grep "7-14.6.65 documentation live-ready requirements exist" "$DOC_FILE" "Live-ready requirements"
require_grep "7-14.6.66 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-14.6.67 runtime does not default production billing true" "$RUNTIME_FILE" "ProductionBillingAllowed:      true"
require_not_grep "7-14.6.68 runtime does not default real invoice true" "$RUNTIME_FILE" "RealInvoiceIssueAllowed:       true"
require_not_grep "7-14.6.69 runtime does not default real billing commit true" "$RUNTIME_FILE" "RealBillingCommitAllowed:      true"
require_not_grep "7-14.6.70 runtime does not default real payment capture true" "$RUNTIME_FILE" "RealPaymentCaptureAllowed:     true"
require_not_grep "7-14.6.71 runtime does not default real money true" "$RUNTIME_FILE" "RealMoneyMovementAllowed:      true"
require_not_grep "7-14.6.72 runtime issue plan does not issue real invoice" "$RUNTIME_FILE" "RealInvoiceIssued:            true"
require_not_grep "7-14.6.73 runtime issue plan does not commit billing" "$RUNTIME_FILE" "RealBillingCommitted:         true"
require_not_grep "7-14.6.74 runtime issue plan does not request payment capture" "$RUNTIME_FILE" "RealPaymentCaptureRequested:  true"
require_not_grep "7-14.6.75 runtime issue plan does not request real provider API" "$RUNTIME_FILE" "RealProviderAPICallRequested: true"

if go test ./internal/platform/commercial/liveready; then
  ok "7-14.6.76 go test verification PASS"
else
  fail "7-14.6.76 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-14 ACCOUNTANT BILLING LIVE-READY RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
