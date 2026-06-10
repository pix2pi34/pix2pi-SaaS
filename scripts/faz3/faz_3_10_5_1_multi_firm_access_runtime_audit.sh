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

echo "===== 140 — FAZ 3-10.5.1 MULTI FIRM ACCESS RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/accountantportal/multifirmaccess/multi_firm_access_runtime.go"
TEST_FILE="internal/erp/turkiye/accountantportal/multifirmaccess/multi_firm_access_runtime_test.go"
CONFIG_FILE="configs/faz3/accountantportal/multi_firm_access_runtime.v1.json"
DOC_FILE="docs/faz3/accountantportal/FAZ_3_10_5_1_MULTI_FIRM_ACCESS_RUNTIME.md"

check_file "140 multi-firm access runtime file" "$RUNTIME_FILE"
check_file "140 multi-firm access test file" "$TEST_FILE"
check_file "140 multi-firm access config file" "$CONFIG_FILE"
check_file "140 multi-firm access documentation file" "$DOC_FILE"

check_grep "140 runtime constructor" "$RUNTIME_FILE" "NewMultiFirmAccessRuntime"
check_grep "140 evaluate access runtime" "$RUNTIME_FILE" "EvaluateAccess"
check_grep "140 visible firms runtime" "$RUNTIME_FILE" "ListVisibleFirms"
check_grep "140 subscription validation runtime" "$RUNTIME_FILE" "validateSubscription"
check_grep "140 assignment validation runtime" "$RUNTIME_FILE" "validateAssignment"

check_grep "140 subscription model" "$RUNTIME_FILE" "type AccountantSubscription"
check_grep "140 assignment model" "$RUNTIME_FILE" "type FirmAssignment"
check_grep "140 access request model" "$RUNTIME_FILE" "type AccessRequest"
check_grep "140 access decision model" "$RUNTIME_FILE" "type AccessDecision"
check_grep "140 visible firms request model" "$RUNTIME_FILE" "type VisibleFirmsRequest"
check_grep "140 visible firms result model" "$RUNTIME_FILE" "type VisibleFirmsResult"

check_grep "140 active subscription status" "$RUNTIME_FILE" "SubscriptionStatusActive"
check_grep "140 trialing subscription status" "$RUNTIME_FILE" "SubscriptionStatusTrialing"
check_grep "140 suspended subscription status" "$RUNTIME_FILE" "SubscriptionStatusSuspended"
check_grep "140 active assignment status" "$RUNTIME_FILE" "AssignmentStatusActive"
check_grep "140 revoked assignment status" "$RUNTIME_FILE" "AssignmentStatusRevoked"

check_grep "140 accountant owner role" "$RUNTIME_FILE" "ACCOUNTANT_OWNER"
check_grep "140 accountant staff role" "$RUNTIME_FILE" "ACCOUNTANT_STAFF"
check_grep "140 accountant readonly role" "$RUNTIME_FILE" "ACCOUNTANT_READ_ONLY"

check_grep "140 view firm permission" "$RUNTIME_FILE" "VIEW_FIRM"
check_grep "140 view ledger permission" "$RUNTIME_FILE" "VIEW_LEDGER"
check_grep "140 export excel permission" "$RUNTIME_FILE" "EXPORT_EXCEL"
check_grep "140 export pdf permission" "$RUNTIME_FILE" "EXPORT_PDF"
check_grep "140 export TDHP permission" "$RUNTIME_FILE" "EXPORT_TDHP"
check_grep "140 manage assignment permission" "$RUNTIME_FILE" "MANAGE_ASSIGNMENT"

check_grep "140 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "140 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "140 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "140 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "140 accountant firm guard" "$RUNTIME_FILE" "accountant_firm_id is required"
check_grep "140 accountant user guard" "$RUNTIME_FILE" "accountant_user_id is required"
check_grep "140 target firm guard" "$RUNTIME_FILE" "target_firm_tenant_id is required"
check_grep "140 target company guard" "$RUNTIME_FILE" "target_company_id is required"
check_grep "140 permission guard" "$RUNTIME_FILE" "required_permission is required"
check_grep "140 subscription tenant mismatch guard" "$RUNTIME_FILE" "subscription tenant_id mismatch"
check_grep "140 subscription status guard" "$RUNTIME_FILE" "subscription status must be ACTIVE or TRIALING"
check_grep "140 subscription expired guard" "$RUNTIME_FILE" "subscription is expired"
check_grep "140 assignment tenant mismatch guard" "$RUNTIME_FILE" "assignment tenant_id mismatch"
check_grep "140 assignment company mismatch guard" "$RUNTIME_FILE" "assignment target_company_id mismatch"
check_grep "140 assignment status guard" "$RUNTIME_FILE" "assignment status must be ACTIVE"
check_grep "140 assignment expired guard" "$RUNTIME_FILE" "assignment is expired"
check_grep "140 permission denied guard" "$RUNTIME_FILE" "required permission is not assigned"
check_grep "140 visible firm hash builder" "$RUNTIME_FILE" "buildVisibleFirmsHash"
check_grep "140 access hash builder" "$RUNTIME_FILE" "buildAccessHash"

check_grep "140 allow access test" "$TEST_FILE" "TestEvaluateAccessAllowsAssignedFirm"
check_grep "140 inactive subscription test" "$TEST_FILE" "TestEvaluateAccessRejectsInactiveSubscription"
check_grep "140 expired subscription test" "$TEST_FILE" "TestEvaluateAccessRejectsExpiredSubscription"
check_grep "140 inactive assignment test" "$TEST_FILE" "TestEvaluateAccessRejectsInactiveAssignment"
check_grep "140 tenant mismatch test" "$TEST_FILE" "TestEvaluateAccessRejectsTenantMismatch"
check_grep "140 company mismatch test" "$TEST_FILE" "TestEvaluateAccessRejectsCompanyMismatch"
check_grep "140 missing permission test" "$TEST_FILE" "TestEvaluateAccessRejectsMissingPermission"
check_grep "140 expired assignment test" "$TEST_FILE" "TestEvaluateAccessRejectsExpiredAssignment"
check_grep "140 visible firm filter test" "$TEST_FILE" "TestListVisibleFirmsFiltersDeniedAssignments"
check_grep "140 assignment limit test" "$TEST_FILE" "TestListVisibleFirmsRejectsAssignmentLimit"

check_grep "140 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "140 config country TR" "$CONFIG_FILE" "\"default_country_code\": \"TR\""
check_grep "140 config active subscription required" "$CONFIG_FILE" "\"require_active_subscription\": true"
check_grep "140 config active assignment required" "$CONFIG_FILE" "\"require_active_assignment\": true"
check_grep "140 config tenant scope required" "$CONFIG_FILE" "\"require_tenant_scope\": true"
check_grep "140 config company scope required" "$CONFIG_FILE" "\"require_company_scope\": true"
check_grep "140 config permission match required" "$CONFIG_FILE" "\"require_permission_match\": true"
check_grep "140 config next gate" "$CONFIG_FILE" "FAZ_3_10_5_2_COMPANY_PERMISSION_ENFORCEMENT"

if go test ./internal/erp/turkiye/accountantportal/multifirmaccess; then
  pass "140 multi-firm access Go test status"
else
  fail "140 multi-firm access Go test status"
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
# 140 — FAZ 3-10.5.1 — Multi Firm Access Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_5_1_MULTI_FIRM_ACCESS_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_5_1_MULTI_FIRM_ACCESS_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_5_2_READY=${NEXT_READY}

## Scope

- Accountant subscription model
- Firm assignment model
- Access request model
- Access decision model
- Visible firms request/result model
- Multi-firm access decision
- Visible firm list filtering
- Active subscription guard
- Active assignment guard
- Tenant scope guard
- Company scope guard
- Permission match guard
- Assignment validity date guard
- Subscription firm limit guard
- Audit hash generation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 140 — FAZ 3-10.5.1 MULTI FIRM ACCESS RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_5_1_MULTI_FIRM_ACCESS_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_5_1_MULTI_FIRM_ACCESS_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_5_2_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
