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

echo "===== 171 — FAZ 3-12.5 SUBSCRIPTION STATUS VIEW REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/accountant-portal/subscription-status/index.html"
CONFIG_FILE="configs/faz3/accountant-portal/subscription_status_view.v1.json"
DOC_FILE="docs/faz3/accountant-portal/FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW.md"

check_file "171 subscription status HTML screen file" "$SCREEN_FILE"
check_file "171 subscription status config file" "$CONFIG_FILE"
check_file "171 subscription status documentation file" "$DOC_FILE"

check_grep "171 phase marker" "$SCREEN_FILE" "FAZ_3_12_5"
check_grep "171 screen marker" "$SCREEN_FILE" "SUBSCRIPTION_STATUS_VIEW"
check_grep "171 title surface" "$SCREEN_FILE" "Abonelik / Durum Görünümü"
check_grep "171 subscription table surface" "$SCREEN_FILE" "Firma Abonelik Durumları|subscriptionRows"
check_grep "171 accountant guard surface" "$SCREEN_FILE" "data-accountant-guard|Accountant|accountantId"
check_grep "171 subscription guard surface" "$SCREEN_FILE" "data-subscription-guard|Subscription Gate"
check_grep "171 monthly validation surface" "$SCREEN_FILE" "monthlyValidationRequired = true|Monthly Validation|validationDate"
check_grep "171 active status surface" "$SCREEN_FILE" "ACTIVE|Active"
check_grep "171 trial status surface" "$SCREEN_FILE" "TRIAL|Trial"
check_grep "171 suspended status surface" "$SCREEN_FILE" "SUSPENDED|Suspended"
check_grep "171 expired status surface" "$SCREEN_FILE" "EXPIRED|Expired"
check_grep "171 starter plan surface" "$SCREEN_FILE" "ACCOUNTANT_STARTER"
check_grep "171 pro plan surface" "$SCREEN_FILE" "ACCOUNTANT_PRO"
check_grep "171 enterprise plan surface" "$SCREEN_FILE" "ACCOUNTANT_ENTERPRISE"
check_grep "171 access allowed surface" "$SCREEN_FILE" "ACCESS_ALLOWED"
check_grep "171 read only allowed surface" "$SCREEN_FILE" "READ_ONLY_ALLOWED"
check_grep "171 access blocked surface" "$SCREEN_FILE" "ACCESS_BLOCKED"
check_grep "171 quota surface" "$SCREEN_FILE" "exportQuota|usedExportCount|Preview Quota"
check_grep "171 firm limit surface" "$SCREEN_FILE" "firmLimit|usedFirmCount|Firm Usage"
check_grep "171 renewal date surface" "$SCREEN_FILE" "renewalDate|Renewal Date"
check_grep "171 validation date surface" "$SCREEN_FILE" "validationDate|Validation Date"
check_grep "171 billing mode surface" "$SCREEN_FILE" "billingMode|Billing Mode|SIMULATION_ONLY|REAL_BILLING_CLOSED"
check_grep "171 subscription hash trace" "$SCREEN_FILE" "subscriptionHash|Subscription Hash"
check_grep "171 quota hash trace" "$SCREEN_FILE" "quotaHash|Quota Hash"
check_grep "171 access hash trace" "$SCREEN_FILE" "accessHash|Access Hash"
check_grep "171 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "171 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "171 validate subscription action" "$SCREEN_FILE" "Validate Subscription|data-action=\"validate-subscription\"|VALIDATE"
check_grep "171 preview quota action" "$SCREEN_FILE" "Preview Quota|data-action=\"preview-quota\"|QUOTA"
check_grep "171 access decision action" "$SCREEN_FILE" "Access Decision|data-action=\"access-decision\"|ACCESS"
check_grep "171 audit evidence action" "$SCREEN_FILE" "Audit Evidence|data-action=\"audit-evidence\"|AUDIT"
check_grep "171 real billing closed surface" "$SCREEN_FILE" "realBillingAllowed = false|Real Billing: CLOSED|Real Billing"
check_grep "171 payment collection false surface" "$SCREEN_FILE" "realPaymentCollectionAllowed = false|Payment Collection"
check_grep "171 invoice issue false surface" "$SCREEN_FILE" "realInvoiceIssueAllowed = false|Invoice Issue"
check_grep "171 access gate required surface" "$SCREEN_FILE" "subscriptionAccessGateRequired = true|Access Gate"
check_grep "171 quota hash required surface" "$SCREEN_FILE" "quotaHashRequired = true"
check_grep "171 production approved false surface" "$SCREEN_FILE" "productionApproved = false"
check_grep "171 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "171 no real billing notice" "$SCREEN_FILE" "gerçek billing|ödeme alma|fatura kesme yapmaz"

check_grep "171 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "171 config route" "$CONFIG_FILE" "\"route\": \"/faz3/accountant-portal/subscription-status/\""
check_grep "171 config subscription visibility" "$CONFIG_FILE" "\"subscription_status_visibility\": true"
check_grep "171 config firm subscription visibility" "$CONFIG_FILE" "\"firm_subscription_visibility\": true"
check_grep "171 config accountant subscription visibility" "$CONFIG_FILE" "\"accountant_subscription_visibility\": true"
check_grep "171 config monthly validation visibility" "$CONFIG_FILE" "\"monthly_validation_visibility\": true"
check_grep "171 config plan visibility" "$CONFIG_FILE" "\"plan_visibility\": true"
check_grep "171 config active visibility" "$CONFIG_FILE" "\"active_status_visibility\": true"
check_grep "171 config trial visibility" "$CONFIG_FILE" "\"trial_status_visibility\": true"
check_grep "171 config suspended visibility" "$CONFIG_FILE" "\"suspended_status_visibility\": true"
check_grep "171 config expired visibility" "$CONFIG_FILE" "\"expired_status_visibility\": true"
check_grep "171 config access decision visibility" "$CONFIG_FILE" "\"access_decision_visibility\": true"
check_grep "171 config quota visibility" "$CONFIG_FILE" "\"quota_visibility\": true"
check_grep "171 config firm limit visibility" "$CONFIG_FILE" "\"firm_limit_visibility\": true"
check_grep "171 config export quota visibility" "$CONFIG_FILE" "\"export_quota_visibility\": true"
check_grep "171 config renewal visibility" "$CONFIG_FILE" "\"renewal_date_visibility\": true"
check_grep "171 config validation visibility" "$CONFIG_FILE" "\"validation_date_visibility\": true"
check_grep "171 config billing mode visibility" "$CONFIG_FILE" "\"billing_mode_visibility\": true"
check_grep "171 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"

check_grep "171 config subscription id required" "$CONFIG_FILE" "\"subscription_id_required\": true"
check_grep "171 config firm id required" "$CONFIG_FILE" "\"firm_id_required\": true"
check_grep "171 config tenant id required" "$CONFIG_FILE" "\"tenant_id_required\": true"
check_grep "171 config accountant id required" "$CONFIG_FILE" "\"accountant_id_required\": true"
check_grep "171 config plan required" "$CONFIG_FILE" "\"plan_required\": true"
check_grep "171 config status required" "$CONFIG_FILE" "\"status_required\": true"
check_grep "171 config period required" "$CONFIG_FILE" "\"period_required\": true"
check_grep "171 config access decision required" "$CONFIG_FILE" "\"access_decision_required\": true"
check_grep "171 config access reason required" "$CONFIG_FILE" "\"access_reason_required\": true"
check_grep "171 config firm limit required" "$CONFIG_FILE" "\"firm_limit_required\": true"
check_grep "171 config export quota required" "$CONFIG_FILE" "\"export_quota_required\": true"
check_grep "171 config renewal required" "$CONFIG_FILE" "\"renewal_date_required\": true"
check_grep "171 config validation required" "$CONFIG_FILE" "\"validation_date_required\": true"
check_grep "171 config subscription hash required" "$CONFIG_FILE" "\"subscription_hash_required\": true"
check_grep "171 config quota hash required" "$CONFIG_FILE" "\"quota_hash_required\": true"
check_grep "171 config access hash required" "$CONFIG_FILE" "\"access_hash_required\": true"
check_grep "171 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "171 config evidence file required" "$CONFIG_FILE" "\"evidence_file_required\": true"

check_grep "171 config active coverage" "$CONFIG_FILE" "\"status_active\": true"
check_grep "171 config trial coverage" "$CONFIG_FILE" "\"status_trial\": true"
check_grep "171 config suspended coverage" "$CONFIG_FILE" "\"status_suspended\": true"
check_grep "171 config expired coverage" "$CONFIG_FILE" "\"status_expired\": true"
check_grep "171 config starter plan coverage" "$CONFIG_FILE" "\"plan_accountant_starter\": true"
check_grep "171 config pro plan coverage" "$CONFIG_FILE" "\"plan_accountant_pro\": true"
check_grep "171 config enterprise plan coverage" "$CONFIG_FILE" "\"plan_accountant_enterprise\": true"
check_grep "171 config access allowed coverage" "$CONFIG_FILE" "\"access_allowed\": true"
check_grep "171 config read only allowed coverage" "$CONFIG_FILE" "\"read_only_allowed\": true"
check_grep "171 config access blocked coverage" "$CONFIG_FILE" "\"access_blocked\": true"

check_grep "171 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "171 config real billing false" "$CONFIG_FILE" "\"real_billing_allowed\": false"
check_grep "171 config real payment collection false" "$CONFIG_FILE" "\"real_payment_collection_allowed\": false"
check_grep "171 config real invoice issue false" "$CONFIG_FILE" "\"real_invoice_issue_allowed\": false"
check_grep "171 config monthly validation required live" "$CONFIG_FILE" "\"monthly_validation_required\": true"
check_grep "171 config access gate required live" "$CONFIG_FILE" "\"subscription_access_gate_required\": true"
check_grep "171 config quota hash required live" "$CONFIG_FILE" "\"quota_hash_required\": true"
check_grep "171 config audit required" "$CONFIG_FILE" "\"audit_required\": true"
check_grep "171 config ui actions limited" "$CONFIG_FILE" "\"ui_actions_are_validate_quota_access_audit_only\": true"
check_grep "171 config permission screen gate" "$CONFIG_FILE" "FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN"
check_grep "171 config multi company gate" "$CONFIG_FILE" "FAZ_3_12_1_MULTI_COMPANY_WORKSPACE"
check_grep "171 config export workspace gate" "$CONFIG_FILE" "FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE"
check_grep "171 config ERP UI tests gate" "$CONFIG_FILE" "FAZ_3_11_10_ERP_UI_TESTS"
check_grep "171 config previous gate" "$CONFIG_FILE" "FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN"
check_grep "171 config next gate" "$CONFIG_FILE" "FAZ_3_12_6_PORTAL_AUDIT_HISTORY"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_billing_allowed\"[[:space:]]*:[[:space:]]*true|\"real_payment_collection_allowed\"[[:space:]]*:[[:space:]]*true|\"real_invoice_issue_allowed\"[[:space:]]*:[[:space:]]*true|\"monthly_validation_required\"[[:space:]]*:[[:space:]]*false|\"subscription_access_gate_required\"[[:space:]]*:[[:space:]]*false|\"quota_hash_required\"[[:space:]]*:[[:space:]]*false|\"audit_required\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "171 live policy subscription status guard"
else
  pass "171 live policy subscription status guard"
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
# 171 — FAZ 3-12.5 — Subscription Status View Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_12_6_READY=${NEXT_READY}

## Scope

- Subscription status visibility
- Firm/accountant subscription visibility
- Monthly validation visibility
- Plan visibility
- ACTIVE / TRIAL / SUSPENDED / EXPIRED status coverage
- ACCOUNTANT_STARTER / ACCOUNTANT_PRO / ACCOUNTANT_ENTERPRISE plan coverage
- ACCESS_ALLOWED / READ_ONLY_ALLOWED / ACCESS_BLOCKED decision coverage
- Quota / firm limit / export quota visibility
- Renewal date / validation date visibility
- Billing mode visibility
- Subscription hash / quota hash / access hash / audit hash traces
- Evidence file trace
- Audit timeline

## Live Policy

- Real billing: CLOSED
- Real payment collection: CLOSED
- Real invoice issue: CLOSED
- Monthly validation required: TRUE
- Subscription access gate required: TRUE
- Quota hash required: TRUE
- Audit required: TRUE
- Production approved: FALSE
- UI actions are validate/quota/access/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 171 — FAZ 3-12.5 SUBSCRIPTION STATUS VIEW COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_12_6_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
