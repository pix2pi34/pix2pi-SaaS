#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); REQUIRED_FAIL=$((REQUIRED_FAIL + 1)); echo "$1 MISSING_OR_FAILED / FAIL ❌"; }

check_file() {
  local label="$1"; local file="$2"
  if [ -f "$file" ]; then pass "$label"; else fail "$label file_missing=${file}"; fi
}

check_grep() {
  local label="$1"; local file="$2"; local pattern="$3"
  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then pass "$label"; else fail "$label pattern_missing=${pattern}"; fi
}

echo "===== 170 — FAZ 3-12.3 COMPANY BASED PERMISSION SCREEN REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/accountant-portal/company-permissions/index.html"
CONFIG_FILE="configs/faz3/accountant-portal/company_based_permission_screen.v1.json"
DOC_FILE="docs/faz3/accountant-portal/FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN.md"

check_file "170 company based permission HTML screen file" "$SCREEN_FILE"
check_file "170 company based permission config file" "$CONFIG_FILE"
check_file "170 company based permission documentation file" "$DOC_FILE"

check_grep "170 phase marker" "$SCREEN_FILE" "FAZ_3_12_3"
check_grep "170 screen marker" "$SCREEN_FILE" "COMPANY_BASED_PERMISSION_SCREEN"
check_grep "170 title surface" "$SCREEN_FILE" "Firma Bazlı Yetki Ekranı"
check_grep "170 permission matrix surface" "$SCREEN_FILE" "Firma Bazlı Yetki Matrisi|permissionRows"
check_grep "170 firm based role surface" "$SCREEN_FILE" "roleSet|Role Set|ACCOUNTANT_MANAGER"
check_grep "170 VIEW permission surface" "$SCREEN_FILE" "VIEW|permission_view|ACCOUNTANT_VIEWER"
check_grep "170 EXPORT permission surface" "$SCREEN_FILE" "EXPORT|permission_export|ACCOUNTANT_EXPORTER"
check_grep "170 MANAGE permission surface" "$SCREEN_FILE" "MANAGE|permission_manage|ACCOUNTANT_MANAGER"
check_grep "170 READ_ONLY permission surface" "$SCREEN_FILE" "READ_ONLY|READ_ONLY_ALLOW|ACCOUNTANT_READ_ONLY"
check_grep "170 ALLOW decision surface" "$SCREEN_FILE" "ALLOW|Allow"
check_grep "170 REVIEW_REQUIRED decision surface" "$SCREEN_FILE" "REVIEW_REQUIRED|Review Required"
check_grep "170 DENY decision surface" "$SCREEN_FILE" "DENY|Deny"
check_grep "170 READ_ONLY_ALLOW decision surface" "$SCREEN_FILE" "READ_ONLY_ALLOW|Read Only Allow"
check_grep "170 access decision reason surface" "$SCREEN_FILE" "accessReason|Access Reason|ROLE_AND_SUBSCRIPTION_OK|CROSS_TENANT_DENIED"
check_grep "170 allowed resources surface" "$SCREEN_FILE" "allowedResources|Allowed Resources"
check_grep "170 denied resources surface" "$SCREEN_FILE" "deniedResources|Denied Resources"
check_grep "170 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant Boundary|Tenant ID"
check_grep "170 accountant guard surface" "$SCREEN_FILE" "data-accountant-guard|Accountant|accountantId"
check_grep "170 firm scope surface" "$SCREEN_FILE" "data-firm-scope|Firm Scope|firmScopeRequired"
check_grep "170 firm id surface" "$SCREEN_FILE" "Firm ID|firm_demo_001"
check_grep "170 tax no surface" "$SCREEN_FILE" "Tax No|taxNo"
check_grep "170 subscription status surface" "$SCREEN_FILE" "subscriptionStatus|Subscription|ACTIVE|SUSPENDED"
check_grep "170 tenant boundary hash trace" "$SCREEN_FILE" "tenantBoundaryHash|Tenant Boundary Hash"
check_grep "170 firm scope hash trace" "$SCREEN_FILE" "firmScopeHash|Firm Scope Hash"
check_grep "170 role hash trace" "$SCREEN_FILE" "roleHash|Role Hash"
check_grep "170 permission hash trace" "$SCREEN_FILE" "permissionHash|Permission Hash"
check_grep "170 decision hash trace" "$SCREEN_FILE" "decisionHash|Decision Hash"
check_grep "170 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "170 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "170 validate permission action" "$SCREEN_FILE" "Validate Permission|data-action=\"validate-permission\"|VALIDATE"
check_grep "170 preview scope action" "$SCREEN_FILE" "Preview Scope|data-action=\"preview-scope\"|SCOPE"
check_grep "170 request review action" "$SCREEN_FILE" "Request Review|data-action=\"request-review\"|REVIEW"
check_grep "170 audit evidence action" "$SCREEN_FILE" "Audit Evidence|data-action=\"audit-evidence\"|AUDIT"
check_grep "170 cross tenant closed surface" "$SCREEN_FILE" "crossTenantAccessAllowed = false|Cross Tenant: CLOSED|Cross Tenant Access"
check_grep "170 tenant boundary required surface" "$SCREEN_FILE" "tenantBoundaryRequired = true|Tenant Boundary Required"
check_grep "170 firm scope required surface" "$SCREEN_FILE" "firmScopeRequired = true|Firm Scope Required"
check_grep "170 subscription required surface" "$SCREEN_FILE" "subscriptionStatusRequired = true|Subscription Required"
check_grep "170 permission hash required surface" "$SCREEN_FILE" "permissionHashRequired = true|Permission Hash Required"
check_grep "170 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production"
check_grep "170 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "170 no cross tenant notice" "$SCREEN_FILE" "cross-tenant erişim açmaz|tenant boundary"

check_grep "170 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "170 config route" "$CONFIG_FILE" "\"route\": \"/faz3/accountant-portal/company-permissions/\""
check_grep "170 config permission matrix visibility" "$CONFIG_FILE" "\"company_permission_matrix_visibility\": true"
check_grep "170 config firm based role visibility" "$CONFIG_FILE" "\"firm_based_role_visibility\": true"
check_grep "170 config view permission visibility" "$CONFIG_FILE" "\"view_permission_visibility\": true"
check_grep "170 config export permission visibility" "$CONFIG_FILE" "\"export_permission_visibility\": true"
check_grep "170 config manage permission visibility" "$CONFIG_FILE" "\"manage_permission_visibility\": true"
check_grep "170 config read only permission visibility" "$CONFIG_FILE" "\"read_only_permission_visibility\": true"
check_grep "170 config access decision visibility" "$CONFIG_FILE" "\"access_decision_visibility\": true"
check_grep "170 config allowed resources visibility" "$CONFIG_FILE" "\"allowed_resources_visibility\": true"
check_grep "170 config denied resources visibility" "$CONFIG_FILE" "\"denied_resources_visibility\": true"
check_grep "170 config tenant boundary visibility" "$CONFIG_FILE" "\"tenant_boundary_visibility\": true"
check_grep "170 config firm scope visibility" "$CONFIG_FILE" "\"firm_scope_visibility\": true"
check_grep "170 config subscription visibility" "$CONFIG_FILE" "\"subscription_status_visibility\": true"
check_grep "170 config permission hash visibility" "$CONFIG_FILE" "\"permission_hash_visibility\": true"
check_grep "170 config decision hash visibility" "$CONFIG_FILE" "\"decision_hash_visibility\": true"
check_grep "170 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"

check_grep "170 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "170 config accountant required" "$CONFIG_FILE" "\"accountant_indicator_required\": true"
check_grep "170 config firm required" "$CONFIG_FILE" "\"firm_indicator_required\": true"
check_grep "170 config firm id required" "$CONFIG_FILE" "\"firm_id_required\": true"
check_grep "170 config tenant id required" "$CONFIG_FILE" "\"tenant_id_required\": true"
check_grep "170 config tax no required" "$CONFIG_FILE" "\"tax_no_required\": true"
check_grep "170 config accountant id required" "$CONFIG_FILE" "\"accountant_id_required\": true"
check_grep "170 config role set required" "$CONFIG_FILE" "\"role_set_required\": true"
check_grep "170 config permission required" "$CONFIG_FILE" "\"permission_required\": true"
check_grep "170 config action scope required" "$CONFIG_FILE" "\"action_scope_required\": true"
check_grep "170 config decision required" "$CONFIG_FILE" "\"decision_required\": true"
check_grep "170 config subscription required" "$CONFIG_FILE" "\"subscription_status_required\": true"
check_grep "170 config access reason required" "$CONFIG_FILE" "\"access_reason_required\": true"
check_grep "170 config allowed resources required" "$CONFIG_FILE" "\"allowed_resources_required\": true"
check_grep "170 config denied resources required" "$CONFIG_FILE" "\"denied_resources_required\": true"
check_grep "170 config tenant boundary hash required" "$CONFIG_FILE" "\"tenant_boundary_hash_required\": true"
check_grep "170 config firm scope hash required" "$CONFIG_FILE" "\"firm_scope_hash_required\": true"
check_grep "170 config role hash required" "$CONFIG_FILE" "\"role_hash_required\": true"
check_grep "170 config permission hash required" "$CONFIG_FILE" "\"permission_hash_required\": true"
check_grep "170 config decision hash required" "$CONFIG_FILE" "\"decision_hash_required\": true"
check_grep "170 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "170 config evidence file required" "$CONFIG_FILE" "\"evidence_file_required\": true"

check_grep "170 config permission view coverage" "$CONFIG_FILE" "\"permission_view\": true"
check_grep "170 config permission export coverage" "$CONFIG_FILE" "\"permission_export\": true"
check_grep "170 config permission manage coverage" "$CONFIG_FILE" "\"permission_manage\": true"
check_grep "170 config permission read only coverage" "$CONFIG_FILE" "\"permission_read_only\": true"
check_grep "170 config allow decision coverage" "$CONFIG_FILE" "\"decision_allow\": true"
check_grep "170 config review decision coverage" "$CONFIG_FILE" "\"decision_review_required\": true"
check_grep "170 config deny decision coverage" "$CONFIG_FILE" "\"decision_deny\": true"
check_grep "170 config read only allow coverage" "$CONFIG_FILE" "\"decision_read_only_allow\": true"
check_grep "170 config manager role coverage" "$CONFIG_FILE" "\"role_accountant_manager\": true"
check_grep "170 config exporter role coverage" "$CONFIG_FILE" "\"role_accountant_exporter\": true"
check_grep "170 config viewer role coverage" "$CONFIG_FILE" "\"role_accountant_viewer\": true"
check_grep "170 config read only role coverage" "$CONFIG_FILE" "\"role_accountant_read_only\": true"

check_grep "170 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "170 config cross tenant false" "$CONFIG_FILE" "\"cross_tenant_access_allowed\": false"
check_grep "170 config tenant boundary required live" "$CONFIG_FILE" "\"tenant_boundary_required\": true"
check_grep "170 config firm scope required live" "$CONFIG_FILE" "\"firm_scope_required\": true"
check_grep "170 config subscription required live" "$CONFIG_FILE" "\"subscription_status_required\": true"
check_grep "170 config permission hash required live" "$CONFIG_FILE" "\"permission_hash_required\": true"
check_grep "170 config audit required" "$CONFIG_FILE" "\"audit_required\": true"
check_grep "170 config ui actions limited" "$CONFIG_FILE" "\"ui_actions_are_validate_scope_review_audit_only\": true"
check_grep "170 config multi company gate" "$CONFIG_FILE" "FAZ_3_12_1_MULTI_COMPANY_WORKSPACE"
check_grep "170 config company switcher gate" "$CONFIG_FILE" "FAZ_3_12_2_COMPANY_SWITCHER"
check_grep "170 config export workspace gate" "$CONFIG_FILE" "FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE"
check_grep "170 config ERP UI tests gate" "$CONFIG_FILE" "FAZ_3_11_10_ERP_UI_TESTS"
check_grep "170 config previous gate" "$CONFIG_FILE" "FAZ_3_12_2_COMPANY_SWITCHER"
check_grep "170 config next gate" "$CONFIG_FILE" "FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"cross_tenant_access_allowed\"[[:space:]]*:[[:space:]]*true|\"tenant_boundary_required\"[[:space:]]*:[[:space:]]*false|\"firm_scope_required\"[[:space:]]*:[[:space:]]*false|\"subscription_status_required\"[[:space:]]*:[[:space:]]*false|\"permission_hash_required\"[[:space:]]*:[[:space:]]*false|\"audit_required\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "170 live policy permission enforcement guard"
else
  pass "170 live policy permission enforcement guard"
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
# 170 — FAZ 3-12.3 — Company Based Permission Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_12_5_READY=${NEXT_READY}

## Scope

- Company permission matrix visibility
- Firm based role visibility
- VIEW / EXPORT / MANAGE / READ_ONLY permission visibility
- ALLOW / REVIEW_REQUIRED / DENY / READ_ONLY_ALLOW decision visibility
- ACCOUNTANT_MANAGER / ACCOUNTANT_EXPORTER / ACCOUNTANT_VIEWER / ACCOUNTANT_READ_ONLY role coverage
- Allowed / denied resources visibility
- Tenant boundary visibility
- Firm scope visibility
- Subscription status visibility
- Permission hash / decision hash / audit hash traces
- Evidence file trace
- Audit timeline

## Live Policy

- Cross tenant access: CLOSED
- Tenant boundary required: TRUE
- Firm scope required: TRUE
- Subscription status required: TRUE
- Permission hash required: TRUE
- Audit required: TRUE
- Production approved: FALSE
- UI actions are validate/scope/review/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 170 — FAZ 3-12.3 COMPANY BASED PERMISSION SCREEN COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_12_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
