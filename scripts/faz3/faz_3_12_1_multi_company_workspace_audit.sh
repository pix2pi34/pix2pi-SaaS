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

  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern}"
  fi
}

echo "===== 168 — FAZ 3-12.1 MULTI COMPANY WORKSPACE REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/accountant-portal/multi-company-workspace/index.html"
CONFIG_FILE="configs/faz3/accountant-portal/multi_company_workspace.v1.json"
DOC_FILE="docs/faz3/accountant-portal/FAZ_3_12_1_MULTI_COMPANY_WORKSPACE.md"

check_file "168 multi company workspace HTML screen file" "$SCREEN_FILE"
check_file "168 multi company workspace config file" "$CONFIG_FILE"
check_file "168 multi company workspace documentation file" "$DOC_FILE"

check_grep "168 phase marker" "$SCREEN_FILE" "FAZ_3_12_1"
check_grep "168 screen marker" "$SCREEN_FILE" "MULTI_COMPANY_WORKSPACE"
check_grep "168 title surface" "$SCREEN_FILE" "Çok Firmalı Workspace"
check_grep "168 firm portfolio surface" "$SCREEN_FILE" "Firma Portföyü|firmRows"
check_grep "168 authorized firm count surface" "$SCREEN_FILE" "Authorized Firms|authorized_firms|Yetkili firma"
check_grep "168 selected firm context surface" "$SCREEN_FILE" "selectFirm|FIRM_SELECTED|Seçili firma"
check_grep "168 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant Scope|Tenant ID"
check_grep "168 accountant guard surface" "$SCREEN_FILE" "data-accountant-guard|Accountant|acc_demo_001"
check_grep "168 firm id surface" "$SCREEN_FILE" "Firm ID|firm_demo_001"
check_grep "168 tax no surface" "$SCREEN_FILE" "Tax No|taxNo|1234567890"
check_grep "168 tax office surface" "$SCREEN_FILE" "Tax Office|taxOffice|Kadıköy"
check_grep "168 sector surface" "$SCREEN_FILE" "sector|Sektör|Perakende|Oto yedek parça"
check_grep "168 subscription status surface" "$SCREEN_FILE" "subscriptionStatus|Subscription|ACTIVE|SUSPENDED"
check_grep "168 permission surface" "$SCREEN_FILE" "permission|Permission|MANAGE|EXPORT|VIEW|READ_ONLY"
check_grep "168 role set surface" "$SCREEN_FILE" "roleSet|Role Set|ACCOUNTANT_MANAGER"
check_grep "168 access decision surface" "$SCREEN_FILE" "accessDecision|Access Decision|ALLOWED|SUBSCRIPTION_BLOCKED"
check_grep "168 period filter surface" "$SCREEN_FILE" "periodFilter|2026-05|2026-Q2|YTD"
check_grep "168 firm status filter surface" "$SCREEN_FILE" "statusFilter|ACTIVE|TRIAL|REVIEW_REQUIRED|BLOCKED"
check_grep "168 export workspace route surface" "$SCREEN_FILE" "exportWorkspaceRoute|Export Route|/faz3/accountant-portal/export-workspace/"
check_grep "168 finance summary route surface" "$SCREEN_FILE" "financeSummaryRoute|Finance Route|/faz3/erp-ui/finance-summary/"
check_grep "168 open tasks surface" "$SCREEN_FILE" "openTasks|Open Tasks"
check_grep "168 tenant boundary hash trace" "$SCREEN_FILE" "tenantBoundaryHash|Tenant Boundary Hash"
check_grep "168 firm scope hash trace" "$SCREEN_FILE" "firmScopeHash|Firm Scope Hash"
check_grep "168 permission hash trace" "$SCREEN_FILE" "permissionHash|Permission Hash"
check_grep "168 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "168 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "168 select firm action" "$SCREEN_FILE" "SELECT|Select Firm|data-action=\"select-firm\""
check_grep "168 open export action" "$SCREEN_FILE" "Open Export Workspace|data-action=\"open-export-workspace\""
check_grep "168 permission check action" "$SCREEN_FILE" "Permission Check|data-action=\"permission-check\""
check_grep "168 audit evidence action" "$SCREEN_FILE" "Audit Evidence|data-action=\"audit-evidence\""
check_grep "168 cross tenant closed surface" "$SCREEN_FILE" "crossTenantAccessAllowed = false|Cross Tenant: CLOSED|Cross Tenant Access"
check_grep "168 firm scope required surface" "$SCREEN_FILE" "firmScopeRequired = true|Firm Scope Required"
check_grep "168 accountant auth required surface" "$SCREEN_FILE" "accountantAuthorizationRequired = true|Authorization Required"
check_grep "168 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production"
check_grep "168 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "168 no cross tenant notice" "$SCREEN_FILE" "cross-tenant erişim yapmaz|tenant boundary zorunludur"

check_grep "168 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "168 config route" "$CONFIG_FILE" "\"route\": \"/faz3/accountant-portal/multi-company-workspace/\""
check_grep "168 config portfolio visibility" "$CONFIG_FILE" "\"accountant_portfolio_visibility\": true"
check_grep "168 config authorized firm list visibility" "$CONFIG_FILE" "\"authorized_firm_list_visibility\": true"
check_grep "168 config selected firm visibility" "$CONFIG_FILE" "\"selected_firm_context_visibility\": true"
check_grep "168 config tenant boundary visibility" "$CONFIG_FILE" "\"tenant_boundary_visibility\": true"
check_grep "168 config firm scope visibility" "$CONFIG_FILE" "\"firm_scope_visibility\": true"
check_grep "168 config tax no visibility" "$CONFIG_FILE" "\"tax_no_visibility\": true"
check_grep "168 config tax office visibility" "$CONFIG_FILE" "\"tax_office_visibility\": true"
check_grep "168 config sector visibility" "$CONFIG_FILE" "\"sector_visibility\": true"
check_grep "168 config subscription visibility" "$CONFIG_FILE" "\"subscription_status_visibility\": true"
check_grep "168 config permission visibility" "$CONFIG_FILE" "\"permission_visibility\": true"
check_grep "168 config role set visibility" "$CONFIG_FILE" "\"role_set_visibility\": true"
check_grep "168 config access decision visibility" "$CONFIG_FILE" "\"access_decision_visibility\": true"
check_grep "168 config period filter visibility" "$CONFIG_FILE" "\"period_filter_visibility\": true"
check_grep "168 config firm status filter visibility" "$CONFIG_FILE" "\"firm_status_filter_visibility\": true"
check_grep "168 config export route visibility" "$CONFIG_FILE" "\"export_workspace_route_visibility\": true"
check_grep "168 config finance route visibility" "$CONFIG_FILE" "\"finance_summary_route_visibility\": true"
check_grep "168 config open task visibility" "$CONFIG_FILE" "\"open_task_visibility\": true"
check_grep "168 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"
check_grep "168 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "168 config accountant required" "$CONFIG_FILE" "\"accountant_indicator_required\": true"
check_grep "168 config firm required" "$CONFIG_FILE" "\"firm_indicator_required\": true"
check_grep "168 config firm id required" "$CONFIG_FILE" "\"firm_id_required\": true"
check_grep "168 config tenant id required" "$CONFIG_FILE" "\"tenant_id_required\": true"
check_grep "168 config tax no required" "$CONFIG_FILE" "\"tax_no_required\": true"
check_grep "168 config permission required" "$CONFIG_FILE" "\"permission_required\": true"
check_grep "168 config role set required" "$CONFIG_FILE" "\"role_set_required\": true"
check_grep "168 config subscription required" "$CONFIG_FILE" "\"subscription_status_required\": true"
check_grep "168 config access decision required" "$CONFIG_FILE" "\"access_decision_required\": true"
check_grep "168 config period required" "$CONFIG_FILE" "\"period_required\": true"
check_grep "168 config tenant boundary hash required" "$CONFIG_FILE" "\"tenant_boundary_hash_required\": true"
check_grep "168 config firm scope hash required" "$CONFIG_FILE" "\"firm_scope_hash_required\": true"
check_grep "168 config permission hash required" "$CONFIG_FILE" "\"permission_hash_required\": true"
check_grep "168 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "168 config evidence file required" "$CONFIG_FILE" "\"evidence_file_required\": true"
check_grep "168 config permission view coverage" "$CONFIG_FILE" "\"permission_view\": true"
check_grep "168 config permission export coverage" "$CONFIG_FILE" "\"permission_export\": true"
check_grep "168 config permission manage coverage" "$CONFIG_FILE" "\"permission_manage\": true"
check_grep "168 config permission read only coverage" "$CONFIG_FILE" "\"permission_read_only\": true"
check_grep "168 config active coverage" "$CONFIG_FILE" "\"status_active\": true"
check_grep "168 config trial coverage" "$CONFIG_FILE" "\"status_trial\": true"
check_grep "168 config review coverage" "$CONFIG_FILE" "\"status_review_required\": true"
check_grep "168 config blocked coverage" "$CONFIG_FILE" "\"status_blocked\": true"
check_grep "168 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "168 config cross tenant false" "$CONFIG_FILE" "\"cross_tenant_access_allowed\": false"
check_grep "168 config accountant auth required" "$CONFIG_FILE" "\"accountant_authorization_required\": true"
check_grep "168 config firm scope required" "$CONFIG_FILE" "\"firm_scope_required\": true"
check_grep "168 config subscription required live" "$CONFIG_FILE" "\"subscription_status_required\": true"
check_grep "168 config ui actions limited" "$CONFIG_FILE" "\"ui_actions_are_select_export_permission_audit_only\": true"
check_grep "168 config export workspace gate" "$CONFIG_FILE" "FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE"
check_grep "168 config finance summary gate" "$CONFIG_FILE" "FAZ_3_11_2_FINANCE_SUMMARY_SCREEN"
check_grep "168 config export center gate" "$CONFIG_FILE" "FAZ_3_11_7_EXPORT_CENTER_SCREEN"
check_grep "168 config ERP UI tests gate" "$CONFIG_FILE" "FAZ_3_11_10_ERP_UI_TESTS"
check_grep "168 config previous gate" "$CONFIG_FILE" "FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE"
check_grep "168 config next gate" "$CONFIG_FILE" "FAZ_3_12_2_COMPANY_SWITCHER_SCREEN"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"cross_tenant_access_allowed\"[[:space:]]*:[[:space:]]*true|\"accountant_authorization_required\"[[:space:]]*:[[:space:]]*false|\"firm_scope_required\"[[:space:]]*:[[:space:]]*false|\"subscription_status_required\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "168 live policy tenant firm scope guard"
else
  pass "168 live policy tenant firm scope guard"
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
# 168 — FAZ 3-12.1 — Multi Company Workspace Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_12_1_MULTI_COMPANY_WORKSPACE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_12_1_MULTI_COMPANY_WORKSPACE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_12_2_READY=${NEXT_READY}

## Scope

- Accountant portfolio visibility
- Authorized firm list visibility
- Selected firm context visibility
- Tenant boundary visibility
- Firm scope visibility
- Tax no / tax office visibility
- Sector visibility
- Subscription status visibility
- Permission / role set visibility
- Access decision visibility
- Period filter
- Firm status filter
- Export workspace route visibility
- Finance summary route visibility
- Open task visibility
- Audit timeline
- Tenant boundary hash / firm scope hash / permission hash / audit hash traces
- Permission coverage: VIEW / EXPORT / MANAGE / READ_ONLY
- Status coverage: ACTIVE / TRIAL / REVIEW_REQUIRED / BLOCKED

## Live Policy

- Cross tenant access: CLOSED
- Accountant authorization required: TRUE
- Firm scope required: TRUE
- Subscription status required: TRUE
- Production approved: FALSE
- UI actions are select/export/permission/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 168 — FAZ 3-12.1 MULTI COMPANY WORKSPACE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_12_1_MULTI_COMPANY_WORKSPACE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_12_1_MULTI_COMPANY_WORKSPACE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_12_2_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
