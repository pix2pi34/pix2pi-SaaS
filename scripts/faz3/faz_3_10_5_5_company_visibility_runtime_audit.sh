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

echo "===== 144 — FAZ 3-10.5.5 COMPANY VISIBILITY RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/accountantportal/companyvisibility/company_visibility_runtime.go"
TEST_FILE="internal/erp/turkiye/accountantportal/companyvisibility/company_visibility_runtime_test.go"
CONFIG_FILE="configs/faz3/accountantportal/company_visibility_runtime.v1.json"
DOC_FILE="docs/faz3/accountantportal/FAZ_3_10_5_5_COMPANY_VISIBILITY_RUNTIME.md"

check_file "144 company visibility runtime file" "$RUNTIME_FILE"
check_file "144 company visibility test file" "$TEST_FILE"
check_file "144 company visibility config file" "$CONFIG_FILE"
check_file "144 company visibility documentation file" "$DOC_FILE"

check_grep "144 runtime constructor" "$RUNTIME_FILE" "NewCompanyVisibilityRuntime"
check_grep "144 build visibility runtime" "$RUNTIME_FILE" "BuildVisibility"
check_grep "144 evaluate company runtime" "$RUNTIME_FILE" "evaluateCompany"
check_grep "144 multi-firm runtime bridge" "$RUNTIME_FILE" "multifirmaccess.NewMultiFirmAccessRuntime"
check_grep "144 subscription runtime bridge" "$RUNTIME_FILE" "subscriptionruntime.NewMonthlySubscriptionRuntime"
check_grep "144 subscription access check bridge" "$RUNTIME_FILE" "subscriptionRuntime.CheckAccess"
check_grep "144 multi-firm visible firms bridge" "$RUNTIME_FILE" "multiFirmRuntime.ListVisibleFirms"

check_grep "144 company profile model" "$RUNTIME_FILE" "type CompanyProfile"
check_grep "144 visibility request model" "$RUNTIME_FILE" "type CompanyVisibilityRequest"
check_grep "144 visibility item model" "$RUNTIME_FILE" "type CompanyVisibilityItem"
check_grep "144 visibility result model" "$RUNTIME_FILE" "type CompanyVisibilityResult"

check_grep "144 active company status" "$RUNTIME_FILE" "CompanyStatusActive"
check_grep "144 suspended company status" "$RUNTIME_FILE" "CompanyStatusSuspended"
check_grep "144 archived company status" "$RUNTIME_FILE" "CompanyStatusArchived"
check_grep "144 visible decision" "$RUNTIME_FILE" "CompanyVisibilityVisible"
check_grep "144 hidden decision" "$RUNTIME_FILE" "CompanyVisibilityHidden"
check_grep "144 denied decision" "$RUNTIME_FILE" "CompanyVisibilityDenied"

check_grep "144 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "144 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "144 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "144 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "144 accountant firm guard" "$RUNTIME_FILE" "accountant_firm_id is required"
check_grep "144 accountant user guard" "$RUNTIME_FILE" "accountant_user_id is required"
check_grep "144 permission guard" "$RUNTIME_FILE" "required_permission is required"
check_grep "144 assignments guard" "$RUNTIME_FILE" "assignments are required"
check_grep "144 companies guard" "$RUNTIME_FILE" "companies are required"
check_grep "144 company profile missing guard" "$RUNTIME_FILE" "COMPANY_PROFILE_MISSING"
check_grep "144 company tenant mismatch guard" "$RUNTIME_FILE" "COMPANY_TENANT_MISMATCH"
check_grep "144 company target tenant mismatch guard" "$RUNTIME_FILE" "COMPANY_TARGET_TENANT_MISMATCH"
check_grep "144 company id mismatch guard" "$RUNTIME_FILE" "COMPANY_ID_MISMATCH"
check_grep "144 company tax no guard" "$RUNTIME_FILE" "tax_no is required"
check_grep "144 company status hidden guard" "$RUNTIME_FILE" "COMPANY_STATUS_NOT_VISIBLE"
check_grep "144 visibility flag guard" "$RUNTIME_FILE" "COMPANY_VISIBILITY_FLAG_OFF"
check_grep "144 permission not visible guard" "$RUNTIME_FILE" "PERMISSION_NOT_VISIBLE"
check_grep "144 visibility hash builder" "$RUNTIME_FILE" "buildVisibilityHash"
check_grep "144 multi firm subscription mapper" "$RUNTIME_FILE" "toMultiFirmSubscription"

check_grep "144 visible companies test" "$TEST_FILE" "TestBuildVisibilityShowsAssignedCompanies"
check_grep "144 visibility flag hidden test" "$TEST_FILE" "TestBuildVisibilityHidesCompanyWhenVisibilityFlagOff"
check_grep "144 suspended company hidden test" "$TEST_FILE" "TestBuildVisibilityHidesSuspendedCompany"
check_grep "144 suspended subscription test" "$TEST_FILE" "TestBuildVisibilityRejectsSuspendedSubscription"
check_grep "144 missing company profile test" "$TEST_FILE" "TestBuildVisibilityDeniesMissingCompanyProfile"
check_grep "144 tenant mismatch test" "$TEST_FILE" "TestBuildVisibilityDeniesCompanyTenantMismatch"
check_grep "144 inactive assignment filter test" "$TEST_FILE" "TestBuildVisibilityFiltersInactiveAssignment"
check_grep "144 assignment limit test" "$TEST_FILE" "TestBuildVisibilityRejectsAssignmentLimit"
check_grep "144 missing permission assignment test" "$TEST_FILE" "TestBuildVisibilityRejectsMissingPermissionFromAssignment"
check_grep "144 max assignment test" "$TEST_FILE" "TestBuildVisibilityRejectsTooManyAssignments"

check_grep "144 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "144 config tenant scope required" "$CONFIG_FILE" "\"require_tenant_scope\": true"
check_grep "144 config company scope required" "$CONFIG_FILE" "\"require_company_scope\": true"
check_grep "144 config active subscription required" "$CONFIG_FILE" "\"require_active_subscription\": true"
check_grep "144 config active assignment required" "$CONFIG_FILE" "\"require_active_assignment\": true"
check_grep "144 config visible flag required" "$CONFIG_FILE" "\"require_visible_company_flag\": true"
check_grep "144 config active company required" "$CONFIG_FILE" "\"require_active_company_status\": true"
check_grep "144 config company profile required" "$CONFIG_FILE" "\"require_company_profile\": true"
check_grep "144 config audit hash required" "$CONFIG_FILE" "\"require_audit_hash\": true"
check_grep "144 config multi firm bridge" "$CONFIG_FILE" "FAZ_3_10_5_1_MULTI_FIRM_ACCESS_RUNTIME"
check_grep "144 config subscription bridge" "$CONFIG_FILE" "FAZ_3_10_5_4_MONTHLY_SUBSCRIPTION_RUNTIME"
check_grep "144 config next gate" "$CONFIG_FILE" "FAZ_3_10_5_6_ACCOUNTANT_PORTAL_INTEGRATION_TESTS"

if go test ./internal/erp/turkiye/accountantportal/companyvisibility; then
  pass "144 company visibility runtime Go test status"
else
  fail "144 company visibility runtime Go test status"
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
# 144 — FAZ 3-10.5.5 — Company Visibility Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_5_5_COMPANY_VISIBILITY_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_5_5_COMPANY_VISIBILITY_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_5_6_READY=${NEXT_READY}

## Scope

- Company profile model
- Company visibility request model
- Company visibility item model
- Company visibility result model
- Monthly subscription runtime bridge
- Multi-firm access runtime bridge
- Active subscription guard
- Active assignment guard
- Tenant scope guard
- Company scope guard
- Company profile guard
- Company status guard
- Visible-in-portal flag guard
- Permission match guard
- Visibility hash generation

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 144 — FAZ 3-10.5.5 COMPANY VISIBILITY RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_5_5_COMPANY_VISIBILITY_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_5_5_COMPANY_VISIBILITY_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_5_6_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
