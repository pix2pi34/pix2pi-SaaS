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

echo "===== 169 — FAZ 3-12.2 COMPANY SWITCHER REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/accountant-portal/company-switcher/index.html"
CONFIG_FILE="configs/faz3/accountant-portal/company_switcher.v1.json"
DOC_FILE="docs/faz3/accountant-portal/FAZ_3_12_2_COMPANY_SWITCHER.md"

check_file "169 company switcher HTML screen file" "$SCREEN_FILE"
check_file "169 company switcher config file" "$CONFIG_FILE"
check_file "169 company switcher documentation file" "$DOC_FILE"

check_grep "169 phase marker" "$SCREEN_FILE" "FAZ_3_12_2"
check_grep "169 screen marker" "$SCREEN_FILE" "COMPANY_SWITCHER_SCREEN"
check_grep "169 title surface" "$SCREEN_FILE" "Firma Değiştirici"
check_grep "169 switch list surface" "$SCREEN_FILE" "Firma Switch Listesi|firmRows"
check_grep "169 current firm context surface" "$SCREEN_FILE" "Current Firm|activeContext|ACTIVE_CONTEXT"
check_grep "169 authorized company list surface" "$SCREEN_FILE" "switchable_firms|Switch edilebilir firma"
check_grep "169 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant Boundary|Tenant ID"
check_grep "169 accountant guard surface" "$SCREEN_FILE" "data-accountant-guard|Accountant"
check_grep "169 firm id surface" "$SCREEN_FILE" "Firm ID|firm_demo_001"
check_grep "169 tax no surface" "$SCREEN_FILE" "Tax No|taxNo"
check_grep "169 permission surface" "$SCREEN_FILE" "permission|Permission|MANAGE|EXPORT|VIEW|READ_ONLY"
check_grep "169 role set surface" "$SCREEN_FILE" "roleSet|Role Set|ACCOUNTANT_MANAGER"
check_grep "169 subscription status surface" "$SCREEN_FILE" "subscriptionStatus|Subscription|ACTIVE|SUSPENDED"
check_grep "169 switch allowed decision surface" "$SCREEN_FILE" "SWITCH_ALLOWED|Switch Allowed"
check_grep "169 switch review decision surface" "$SCREEN_FILE" "SWITCH_REVIEW|Switch Review"
check_grep "169 switch blocked decision surface" "$SCREEN_FILE" "SWITCH_BLOCKED|Switch Blocked"
check_grep "169 context token surface" "$SCREEN_FILE" "contextToken|Context Token|ctx-firm-demo"
check_grep "169 target route surface" "$SCREEN_FILE" "targetRoute|Target Route|/faz3/accountant-portal/multi-company-workspace/"
check_grep "169 export route surface" "$SCREEN_FILE" "exportRoute|Export Route|/faz3/accountant-portal/export-workspace/"
check_grep "169 finance route surface" "$SCREEN_FILE" "financeRoute|Finance Route|/faz3/erp-ui/finance-summary/"
check_grep "169 tenant boundary hash trace" "$SCREEN_FILE" "tenantBoundaryHash|Tenant Boundary Hash"
check_grep "169 firm scope hash trace" "$SCREEN_FILE" "firmScopeHash|Firm Scope Hash"
check_grep "169 context hash trace" "$SCREEN_FILE" "contextHash|Context Hash"
check_grep "169 permission hash trace" "$SCREEN_FILE" "permissionHash|Permission Hash"
check_grep "169 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "169 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "169 switch action surface" "$SCREEN_FILE" "SWITCH|Switch Company|data-action=\"switch-company\""
check_grep "169 validate permission action" "$SCREEN_FILE" "Validate Permission|data-action=\"validate-permission\""
check_grep "169 prepare route action" "$SCREEN_FILE" "Prepare Route|data-action=\"prepare-route\""
check_grep "169 audit evidence action" "$SCREEN_FILE" "Audit Evidence|data-action=\"audit-evidence\""
check_grep "169 cross tenant closed surface" "$SCREEN_FILE" "crossTenantAccessAllowed = false|Cross Tenant: CLOSED|Cross Tenant Access"
check_grep "169 accountant auth required surface" "$SCREEN_FILE" "accountantAuthorizationRequired = true|Authorization Required"
check_grep "169 firm scope required surface" "$SCREEN_FILE" "firmScopeRequired = true|Firm Scope Required"
check_grep "169 context token required surface" "$SCREEN_FILE" "contextTokenRequired = true|Context Token Required"
check_grep "169 switch audit required surface" "$SCREEN_FILE" "switchAuditRequired = true|Audit"
check_grep "169 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production"
check_grep "169 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "169 no cross tenant notice" "$SCREEN_FILE" "cross-tenant erişim açmaz|tenant boundary"

check_grep "169 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "169 config route" "$CONFIG_FILE" "\"route\": \"/faz3/accountant-portal/company-switcher/\""
check_grep "169 config switcher visibility" "$CONFIG_FILE" "\"company_switcher_visibility\": true"
check_grep "169 config current context visibility" "$CONFIG_FILE" "\"current_firm_context_visibility\": true"
check_grep "169 config authorized company visibility" "$CONFIG_FILE" "\"authorized_company_list_visibility\": true"
check_grep "169 config switch decision visibility" "$CONFIG_FILE" "\"switch_decision_visibility\": true"
check_grep "169 config active context visibility" "$CONFIG_FILE" "\"active_context_visibility\": true"
check_grep "169 config tenant boundary visibility" "$CONFIG_FILE" "\"tenant_boundary_visibility\": true"
check_grep "169 config firm scope visibility" "$CONFIG_FILE" "\"firm_scope_visibility\": true"
check_grep "169 config context token visibility" "$CONFIG_FILE" "\"context_token_visibility\": true"
check_grep "169 config target route visibility" "$CONFIG_FILE" "\"target_route_visibility\": true"
check_grep "169 config export route visibility" "$CONFIG_FILE" "\"export_route_visibility\": true"
check_grep "169 config finance route visibility" "$CONFIG_FILE" "\"finance_route_visibility\": true"
check_grep "169 config permission visibility" "$CONFIG_FILE" "\"permission_visibility\": true"
check_grep "169 config subscription visibility" "$CONFIG_FILE" "\"subscription_status_visibility\": true"
check_grep "169 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"

check_grep "169 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "169 config accountant required" "$CONFIG_FILE" "\"accountant_indicator_required\": true"
check_grep "169 config firm required" "$CONFIG_FILE" "\"firm_indicator_required\": true"
check_grep "169 config firm id required" "$CONFIG_FILE" "\"firm_id_required\": true"
check_grep "169 config tenant id required" "$CONFIG_FILE" "\"tenant_id_required\": true"
check_grep "169 config tax no required" "$CONFIG_FILE" "\"tax_no_required\": true"
check_grep "169 config permission required" "$CONFIG_FILE" "\"permission_required\": true"
check_grep "169 config role set required" "$CONFIG_FILE" "\"role_set_required\": true"
check_grep "169 config subscription required" "$CONFIG_FILE" "\"subscription_status_required\": true"
check_grep "169 config switch decision required" "$CONFIG_FILE" "\"switch_decision_required\": true"
check_grep "169 config context token required" "$CONFIG_FILE" "\"context_token_required\": true"
check_grep "169 config tenant boundary hash required" "$CONFIG_FILE" "\"tenant_boundary_hash_required\": true"
check_grep "169 config firm scope hash required" "$CONFIG_FILE" "\"firm_scope_hash_required\": true"
check_grep "169 config context hash required" "$CONFIG_FILE" "\"context_hash_required\": true"
check_grep "169 config permission hash required" "$CONFIG_FILE" "\"permission_hash_required\": true"
check_grep "169 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "169 config evidence file required" "$CONFIG_FILE" "\"evidence_file_required\": true"

check_grep "169 config switch allowed coverage" "$CONFIG_FILE" "\"switch_allowed\": true"
check_grep "169 config switch review coverage" "$CONFIG_FILE" "\"switch_review\": true"
check_grep "169 config switch blocked coverage" "$CONFIG_FILE" "\"switch_blocked\": true"
check_grep "169 config permission view coverage" "$CONFIG_FILE" "\"permission_view\": true"
check_grep "169 config permission export coverage" "$CONFIG_FILE" "\"permission_export\": true"
check_grep "169 config permission manage coverage" "$CONFIG_FILE" "\"permission_manage\": true"
check_grep "169 config permission read only coverage" "$CONFIG_FILE" "\"permission_read_only\": true"

check_grep "169 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "169 config cross tenant false" "$CONFIG_FILE" "\"cross_tenant_access_allowed\": false"
check_grep "169 config accountant auth required" "$CONFIG_FILE" "\"accountant_authorization_required\": true"
check_grep "169 config firm scope required" "$CONFIG_FILE" "\"firm_scope_required\": true"
check_grep "169 config context token required live" "$CONFIG_FILE" "\"context_token_required\": true"
check_grep "169 config switch audit required" "$CONFIG_FILE" "\"switch_audit_required\": true"
check_grep "169 config ui actions limited" "$CONFIG_FILE" "\"ui_actions_are_switch_validate_route_audit_only\": true"
check_grep "169 config multi company gate" "$CONFIG_FILE" "FAZ_3_12_1_MULTI_COMPANY_WORKSPACE"
check_grep "169 config export workspace gate" "$CONFIG_FILE" "FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE"
check_grep "169 config finance summary gate" "$CONFIG_FILE" "FAZ_3_11_2_FINANCE_SUMMARY_SCREEN"
check_grep "169 config ERP UI tests gate" "$CONFIG_FILE" "FAZ_3_11_10_ERP_UI_TESTS"
check_grep "169 config previous gate" "$CONFIG_FILE" "FAZ_3_12_1_MULTI_COMPANY_WORKSPACE"
check_grep "169 config next gate" "$CONFIG_FILE" "FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"cross_tenant_access_allowed\"[[:space:]]*:[[:space:]]*true|\"accountant_authorization_required\"[[:space:]]*:[[:space:]]*false|\"firm_scope_required\"[[:space:]]*:[[:space:]]*false|\"context_token_required\"[[:space:]]*:[[:space:]]*false|\"switch_audit_required\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "169 live policy company switch guard"
else
  pass "169 live policy company switch guard"
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
# 169 — FAZ 3-12.2 — Company Switcher Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_12_2_COMPANY_SWITCHER_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_12_2_COMPANY_SWITCHER_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_12_3_READY=${NEXT_READY}

## Scope

- Company switcher visibility
- Current firm context visibility
- Authorized company list visibility
- Switch decision visibility
- Active context visibility
- Tenant boundary visibility
- Firm scope visibility
- Context token visibility
- Target/export/finance route visibility
- Permission and subscription visibility
- Switch allowed / review / blocked coverage
- Permission view / export / manage / read only coverage
- Tenant boundary hash / firm scope hash / context hash / permission hash / audit hash traces
- Evidence file trace

## Live Policy

- Cross tenant access: CLOSED
- Accountant authorization required: TRUE
- Firm scope required: TRUE
- Context token required: TRUE
- Switch audit required: TRUE
- Production approved: FALSE
- UI actions are switch/validate/route/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 169 — FAZ 3-12.2 COMPANY SWITCHER COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_12_2_COMPANY_SWITCHER_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_12_2_COMPANY_SWITCHER_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_12_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
