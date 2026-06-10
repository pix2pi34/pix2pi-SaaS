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

echo "===== 141 — FAZ 3-10.5.2 COMPANY PERMISSION ENFORCEMENT REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/accountantportal/companypermission/company_permission_enforcement.go"
TEST_FILE="internal/erp/turkiye/accountantportal/companypermission/company_permission_enforcement_test.go"
CONFIG_FILE="configs/faz3/accountantportal/company_permission_enforcement.v1.json"
DOC_FILE="docs/faz3/accountantportal/FAZ_3_10_5_2_COMPANY_PERMISSION_ENFORCEMENT.md"

check_file "141 company permission runtime file" "$RUNTIME_FILE"
check_file "141 company permission test file" "$TEST_FILE"
check_file "141 company permission config file" "$CONFIG_FILE"
check_file "141 company permission documentation file" "$DOC_FILE"

check_grep "141 runtime constructor" "$RUNTIME_FILE" "NewCompanyPermissionEnforcementRuntime"
check_grep "141 enforce runtime" "$RUNTIME_FILE" "Enforce"
check_grep "141 bulk enforce runtime" "$RUNTIME_FILE" "EnforceBulk"
check_grep "141 grant scope validation runtime" "$RUNTIME_FILE" "validateGrantScope"
check_grep "141 role permission map runtime" "$RUNTIME_FILE" "defaultRolePermissionMap"
check_grep "141 resource permission map runtime" "$RUNTIME_FILE" "defaultResourcePermissionMap"

check_grep "141 company permission grant model" "$RUNTIME_FILE" "type CompanyPermissionGrant"
check_grep "141 enforcement request model" "$RUNTIME_FILE" "type EnforcementRequest"
check_grep "141 enforcement decision model" "$RUNTIME_FILE" "type EnforcementDecision"
check_grep "141 bulk request model" "$RUNTIME_FILE" "type BulkEnforcementRequest"
check_grep "141 bulk result model" "$RUNTIME_FILE" "type BulkEnforcementResult"

check_grep "141 firm resource type" "$RUNTIME_FILE" "ResourceTypeFirm"
check_grep "141 ledger resource type" "$RUNTIME_FILE" "ResourceTypeLedger"
check_grep "141 export resource type" "$RUNTIME_FILE" "ResourceTypeExport"
check_grep "141 assignment resource type" "$RUNTIME_FILE" "ResourceTypeAssignment"
check_grep "141 subscription resource type" "$RUNTIME_FILE" "ResourceTypeSubscription"

check_grep "141 owner role" "$RUNTIME_FILE" "ACCOUNTANT_OWNER"
check_grep "141 staff role" "$RUNTIME_FILE" "ACCOUNTANT_STAFF"
check_grep "141 readonly role" "$RUNTIME_FILE" "ACCOUNTANT_READ_ONLY"
check_grep "141 super admin role" "$RUNTIME_FILE" "SUPER_ADMIN"

check_grep "141 view firm permission" "$RUNTIME_FILE" "VIEW_FIRM"
check_grep "141 view ledger permission" "$RUNTIME_FILE" "VIEW_LEDGER"
check_grep "141 export excel permission" "$RUNTIME_FILE" "EXPORT_EXCEL"
check_grep "141 export pdf permission" "$RUNTIME_FILE" "EXPORT_PDF"
check_grep "141 export TDHP permission" "$RUNTIME_FILE" "EXPORT_TDHP"
check_grep "141 manage assignment permission" "$RUNTIME_FILE" "MANAGE_ASSIGNMENT"

check_grep "141 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "141 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "141 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "141 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "141 accountant firm guard" "$RUNTIME_FILE" "accountant_firm_id is required"
check_grep "141 accountant user guard" "$RUNTIME_FILE" "accountant_user_id is required"
check_grep "141 assignment guard" "$RUNTIME_FILE" "assignment_id is required"
check_grep "141 target firm guard" "$RUNTIME_FILE" "target_firm_tenant_id is required"
check_grep "141 target company guard" "$RUNTIME_FILE" "target_company_id is required"
check_grep "141 resource type guard" "$RUNTIME_FILE" "resource_type is required"
check_grep "141 permission guard" "$RUNTIME_FILE" "required_permission is required"
check_grep "141 audit subject guard" "$RUNTIME_FILE" "audit_subject is required"
check_grep "141 grant tenant mismatch guard" "$RUNTIME_FILE" "grant tenant_id mismatch"
check_grep "141 grant company mismatch guard" "$RUNTIME_FILE" "grant target_company_id mismatch"
check_grep "141 grant assignment mismatch guard" "$RUNTIME_FILE" "grant assignment_id mismatch"
check_grep "141 role permission denied guard" "$RUNTIME_FILE" "role is not allowed to use required permission"
check_grep "141 resource permission denied guard" "$RUNTIME_FILE" "permission is not allowed for requested resource type"
check_grep "141 explicit grant denied guard" "$RUNTIME_FILE" "required permission is not explicitly granted"
check_grep "141 resource type denied guard" "$RUNTIME_FILE" "resource type is not explicitly granted"
check_grep "141 decision hash builder" "$RUNTIME_FILE" "buildDecisionHash"
check_grep "141 bulk hash builder" "$RUNTIME_FILE" "buildBulkHash"

check_grep "141 allow test" "$TEST_FILE" "TestEnforceAllowsExplicitCompanyPermission"
check_grep "141 tenant mismatch test" "$TEST_FILE" "TestEnforceRejectsTenantMismatch"
check_grep "141 company mismatch test" "$TEST_FILE" "TestEnforceRejectsCompanyMismatch"
check_grep "141 inactive grant test" "$TEST_FILE" "TestEnforceRejectsInactiveGrant"
check_grep "141 expired grant test" "$TEST_FILE" "TestEnforceRejectsExpiredGrant"
check_grep "141 role permission test" "$TEST_FILE" "TestEnforceRejectsRolePermissionMismatch"
check_grep "141 resource permission test" "$TEST_FILE" "TestEnforceRejectsResourcePermissionMismatch"
check_grep "141 explicit grant test" "$TEST_FILE" "TestEnforceRejectsMissingExplicitGrant"
check_grep "141 resource type grant test" "$TEST_FILE" "TestEnforceRejectsResourceTypeNotGranted"
check_grep "141 audit subject test" "$TEST_FILE" "TestEnforceRejectsMissingAuditSubject"
check_grep "141 bulk allow test" "$TEST_FILE" "TestEnforceBulkAllowsAllChecks"
check_grep "141 bulk deny test" "$TEST_FILE" "TestEnforceBulkReturnsDeniedWhenOneCheckFails"

check_grep "141 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "141 config tenant scope required" "$CONFIG_FILE" "\"require_tenant_scope\": true"
check_grep "141 config company scope required" "$CONFIG_FILE" "\"require_company_scope\": true"
check_grep "141 config assignment scope required" "$CONFIG_FILE" "\"require_assignment_scope\": true"
check_grep "141 config resource permission required" "$CONFIG_FILE" "\"require_resource_permission\": true"
check_grep "141 config role permission map required" "$CONFIG_FILE" "\"require_role_permission_map\": true"
check_grep "141 config explicit grant required" "$CONFIG_FILE" "\"require_explicit_grant\": true"
check_grep "141 config audit subject required" "$CONFIG_FILE" "\"require_audit_subject\": true"
check_grep "141 config next gate" "$CONFIG_FILE" "FAZ_3_10_5_3_EXCEL_PDF_TDHP_EXPORT_RUNTIME"

if go test ./internal/erp/turkiye/accountantportal/companypermission; then
  pass "141 company permission enforcement Go test status"
else
  fail "141 company permission enforcement Go test status"
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
# 141 — FAZ 3-10.5.2 — Company Permission Enforcement Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_5_2_COMPANY_PERMISSION_ENFORCEMENT_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_5_2_COMPANY_PERMISSION_ENFORCEMENT_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_5_3_READY=${NEXT_READY}

## Scope

- Company permission grant model
- Enforcement request model
- Enforcement decision model
- Bulk enforcement request/result model
- Role permission map
- Resource permission map
- Tenant scope guard
- Company scope guard
- Assignment scope guard
- Explicit grant guard
- Resource permission guard
- Role permission guard
- Audit subject guard
- Bulk permission enforcement

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 141 — FAZ 3-10.5.2 COMPANY PERMISSION ENFORCEMENT COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_5_2_COMPANY_PERMISSION_ENFORCEMENT_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_5_2_COMPANY_PERMISSION_ENFORCEMENT_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_5_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
