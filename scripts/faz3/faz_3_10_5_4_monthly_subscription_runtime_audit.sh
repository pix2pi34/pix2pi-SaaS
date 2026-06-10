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

echo "===== 143 — FAZ 3-10.5.4 MONTHLY SUBSCRIPTION RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/accountantportal/subscriptionruntime/monthly_subscription_runtime.go"
TEST_FILE="internal/erp/turkiye/accountantportal/subscriptionruntime/monthly_subscription_runtime_test.go"
CONFIG_FILE="configs/faz3/accountantportal/monthly_subscription_runtime.v1.json"
DOC_FILE="docs/faz3/accountantportal/FAZ_3_10_5_4_MONTHLY_SUBSCRIPTION_RUNTIME.md"

check_file "143 monthly subscription runtime file" "$RUNTIME_FILE"
check_file "143 monthly subscription test file" "$TEST_FILE"
check_file "143 monthly subscription config file" "$CONFIG_FILE"
check_file "143 monthly subscription documentation file" "$DOC_FILE"

check_grep "143 runtime constructor" "$RUNTIME_FILE" "NewMonthlySubscriptionRuntime"
check_grep "143 start trial runtime" "$RUNTIME_FILE" "StartTrial"
check_grep "143 activate monthly runtime" "$RUNTIME_FILE" "ActivateMonthly"
check_grep "143 renew monthly runtime" "$RUNTIME_FILE" "RenewMonthly"
check_grep "143 change plan runtime" "$RUNTIME_FILE" "ChangePlan"
check_grep "143 suspend runtime" "$RUNTIME_FILE" "Suspend"
check_grep "143 resume runtime" "$RUNTIME_FILE" "Resume"
check_grep "143 cancel runtime" "$RUNTIME_FILE" "Cancel"
check_grep "143 access check runtime" "$RUNTIME_FILE" "CheckAccess"

check_grep "143 subscription plan model" "$RUNTIME_FILE" "type SubscriptionPlan"
check_grep "143 subscription account model" "$RUNTIME_FILE" "type SubscriptionAccount"
check_grep "143 command request model" "$RUNTIME_FILE" "type SubscriptionCommandRequest"
check_grep "143 decision model" "$RUNTIME_FILE" "type SubscriptionDecision"
check_grep "143 access check request model" "$RUNTIME_FILE" "type AccessCheckRequest"

check_grep "143 monthly billing cycle" "$RUNTIME_FILE" "BillingCycleMonthly"
check_grep "143 trialing status" "$RUNTIME_FILE" "SubscriptionStatusTrialing"
check_grep "143 active status" "$RUNTIME_FILE" "SubscriptionStatusActive"
check_grep "143 suspended status" "$RUNTIME_FILE" "SubscriptionStatusSuspended"
check_grep "143 canceled status" "$RUNTIME_FILE" "SubscriptionStatusCanceled"
check_grep "143 expired status" "$RUNTIME_FILE" "SubscriptionStatusExpired"

check_grep "143 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "143 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "143 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "143 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "143 command id guard" "$RUNTIME_FILE" "command_id is required"
check_grep "143 subscription id guard" "$RUNTIME_FILE" "subscription_id is required"
check_grep "143 accountant firm guard" "$RUNTIME_FILE" "accountant_firm_id is required"
check_grep "143 billing profile guard" "$RUNTIME_FILE" "billing_profile_id is required"
check_grep "143 actor guard" "$RUNTIME_FILE" "actor_id is required"
check_grep "143 effective at guard" "$RUNTIME_FILE" "effective_at is required"
check_grep "143 plan code guard" "$RUNTIME_FILE" "plan_code is required"
check_grep "143 plan allowed guard" "$RUNTIME_FILE" "plan_code is not allowed"
check_grep "143 monthly cycle guard" "$RUNTIME_FILE" "billing_cycle must be MONTHLY"
check_grep "143 currency guard" "$RUNTIME_FILE" "plan currency_code mismatch"
check_grep "143 firm limit guard" "$RUNTIME_FILE" "included_firm_limit must be positive"
check_grep "143 current tenant mismatch guard" "$RUNTIME_FILE" "current tenant_id mismatch"
check_grep "143 assigned firm limit guard" "$RUNTIME_FILE" "current assigned firm count exceeds limit"
check_grep "143 suspend reason guard" "$RUNTIME_FILE" "suspend reason is required"
check_grep "143 cancel reason guard" "$RUNTIME_FILE" "cancel reason is required"
check_grep "143 access status guard" "$RUNTIME_FILE" "subscription access requires ACTIVE or TRIALING status"
check_grep "143 access firm limit guard" "$RUNTIME_FILE" "required firm count exceeds assigned firm limit"
check_grep "143 month end helper" "$RUNTIME_FILE" "monthEnd"
check_grep "143 decision hash builder" "$RUNTIME_FILE" "buildDecisionHash"

check_grep "143 trial test" "$TEST_FILE" "TestStartTrialCreatesTrialingSubscription"
check_grep "143 activate test" "$TEST_FILE" "TestActivateMonthlyCreatesActiveSubscription"
check_grep "143 renew test" "$TEST_FILE" "TestRenewMonthlyAdvancesPeriod"
check_grep "143 change plan test" "$TEST_FILE" "TestChangePlanUpdatesLimits"
check_grep "143 change plan limit test" "$TEST_FILE" "TestChangePlanRejectsLimitDowngrade"
check_grep "143 suspend reason test" "$TEST_FILE" "TestSuspendRequiresReason"
check_grep "143 suspend resume test" "$TEST_FILE" "TestSuspendAndResumeSubscription"
check_grep "143 cancel reason test" "$TEST_FILE" "TestCancelRequiresReason"
check_grep "143 cancel test" "$TEST_FILE" "TestCancelSubscription"
check_grep "143 access allowed test" "$TEST_FILE" "TestCheckAccessAllowsActiveSubscription"
check_grep "143 access suspended test" "$TEST_FILE" "TestCheckAccessRejectsSuspendedSubscription"
check_grep "143 access firm limit test" "$TEST_FILE" "TestCheckAccessRejectsFirmLimit"
check_grep "143 invalid currency test" "$TEST_FILE" "TestRejectsInvalidPlanCurrency"
check_grep "143 tenant mismatch test" "$TEST_FILE" "TestRejectsCurrentTenantMismatch"

check_grep "143 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "143 config currency TRY" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "143 config tenant scope required" "$CONFIG_FILE" "\"require_tenant_scope\": true"
check_grep "143 config billing profile required" "$CONFIG_FILE" "\"require_billing_profile\": true"
check_grep "143 config monthly cycle required" "$CONFIG_FILE" "\"require_monthly_cycle\": true"
check_grep "143 config firm limit required" "$CONFIG_FILE" "\"require_firm_limit\": true"
check_grep "143 config audit actor required" "$CONFIG_FILE" "\"require_audit_actor\": true"
check_grep "143 config trial allowed" "$CONFIG_FILE" "\"allow_trial\": true"
check_grep "143 config plan change allowed" "$CONFIG_FILE" "\"allow_plan_change\": true"
check_grep "143 config next gate" "$CONFIG_FILE" "FAZ_3_10_5_5_COMPANY_VISIBILITY_RUNTIME"

if go test ./internal/erp/turkiye/accountantportal/subscriptionruntime; then
  pass "143 monthly subscription runtime Go test status"
else
  fail "143 monthly subscription runtime Go test status"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 143 — FAZ 3-10.5.4 — Monthly Subscription Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_5_4_MONTHLY_SUBSCRIPTION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_5_4_MONTHLY_SUBSCRIPTION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_5_5_READY=${NEXT_READY}

## Scope

- Subscription plan model
- Subscription account model
- Subscription command request model
- Subscription decision model
- Access check request model
- Trial start
- Monthly activation
- Monthly renewal
- Plan change
- Suspend
- Resume
- Cancel
- Subscription access check
- Tenant scope guard
- Billing profile guard
- Monthly billing cycle guard
- Firm limit guard
- Audit actor guard
- Decision hash generation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 143 — FAZ 3-10.5.4 MONTHLY SUBSCRIPTION RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_5_4_MONTHLY_SUBSCRIPTION_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_5_4_MONTHLY_SUBSCRIPTION_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_5_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
