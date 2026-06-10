#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

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

echo "===== 173 — FAZ 3-12.7 ACCOUNTANT PORTAL TEST SUITE START ====="

declare -A SCREEN_FILES=(
  ["167"]="web/faz3/accountant-portal/export-workspace/index.html"
  ["168"]="web/faz3/accountant-portal/multi-company-workspace/index.html"
  ["169"]="web/faz3/accountant-portal/company-switcher/index.html"
  ["170"]="web/faz3/accountant-portal/company-permissions/index.html"
  ["171"]="web/faz3/accountant-portal/subscription-status/index.html"
  ["172"]="web/faz3/accountant-portal/audit-history/index.html"
)

declare -A CONFIG_FILES=(
  ["167"]="configs/faz3/accountant-portal/accountant_export_workspace.v1.json"
  ["168"]="configs/faz3/accountant-portal/multi_company_workspace.v1.json"
  ["169"]="configs/faz3/accountant-portal/company_switcher.v1.json"
  ["170"]="configs/faz3/accountant-portal/company_based_permission_screen.v1.json"
  ["171"]="configs/faz3/accountant-portal/subscription_status_view.v1.json"
  ["172"]="configs/faz3/accountant-portal/portal_audit_history.v1.json"
)

declare -A EVIDENCE_FILES=(
  ["167"]="docs/faz3/evidence/FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE_REAL_IMPLEMENTATION_AUDIT.md"
  ["168"]="docs/faz3/evidence/FAZ_3_12_1_MULTI_COMPANY_WORKSPACE_REAL_IMPLEMENTATION_AUDIT.md"
  ["169"]="docs/faz3/evidence/FAZ_3_12_2_COMPANY_SWITCHER_REAL_IMPLEMENTATION_AUDIT.md"
  ["170"]="docs/faz3/evidence/FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
  ["171"]="docs/faz3/evidence/FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW_REAL_IMPLEMENTATION_AUDIT.md"
  ["172"]="docs/faz3/evidence/FAZ_3_12_6_PORTAL_AUDIT_HISTORY_REAL_IMPLEMENTATION_AUDIT.md"
)

declare -A PHASE_MARKERS=(
  ["167"]="FAZ_3_12_4"
  ["168"]="FAZ_3_12_1"
  ["169"]="FAZ_3_12_2"
  ["170"]="FAZ_3_12_3"
  ["171"]="FAZ_3_12_5"
  ["172"]="FAZ_3_12_6"
)

declare -A SCREEN_MARKERS=(
  ["167"]="ACCOUNTANT_EXPORT_WORKSPACE"
  ["168"]="MULTI_COMPANY_WORKSPACE"
  ["169"]="COMPANY_SWITCHER_SCREEN"
  ["170"]="COMPANY_BASED_PERMISSION_SCREEN"
  ["171"]="SUBSCRIPTION_STATUS_VIEW"
  ["172"]="PORTAL_AUDIT_HISTORY"
)

for n in 167 168 169 170 171 172; do
  screen="${SCREEN_FILES[$n]}"
  config="${CONFIG_FILES[$n]}"
  evidence="${EVIDENCE_FILES[$n]}"

  check_file "173 screen ${n} HTML file" "$screen"
  check_file "173 screen ${n} config file" "$config"
  check_file "173 screen ${n} evidence file" "$evidence"

  check_grep "173 screen ${n} phase marker" "$screen" "${PHASE_MARKERS[$n]}"
  check_grep "173 screen ${n} screen marker" "$screen" "${SCREEN_MARKERS[$n]}"
  check_grep "173 screen ${n} tenant/accountant guard" "$screen" "Tenant|tenant|data-tenant-guard|Accountant|accountant|data-accountant-guard"
  check_grep "173 screen ${n} firm scope or firm indicator" "$screen" "Firm|Firma|firm|data-firm|firmScope|firm_scope"
  check_grep "173 screen ${n} audit hash or evidence trace" "$screen" "auditHash|Audit Hash|evidenceFile|Evidence File|AUDIT|Audit"
  check_grep "173 screen ${n} closed/read-only policy" "$screen" "CLOSED|closed|read-only|readonly|FALSE|false|kapalı|yapmaz"
  check_grep "173 screen ${n} config screen enabled" "$config" "\"screen_enabled\"[[:space:]]*:[[:space:]]*true"
  check_grep "173 screen ${n} config route" "$config" "\"route\""
  check_grep "173 screen ${n} evidence final status" "$evidence" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
done

REPORT_FILE="web/faz3/accountant-portal/portal-tests/index.html"
CONFIG_FILE="configs/faz3/accountant-portal/accountant_portal_tests.v1.json"

check_file "173 portal tests report HTML file" "$REPORT_FILE"
check_file "173 portal tests config file" "$CONFIG_FILE"

check_grep "173 report phase marker" "$REPORT_FILE" "FAZ_3_12_7"
check_grep "173 report screen marker" "$REPORT_FILE" "ACCOUNTANT_PORTAL_TESTS_REPORT"
check_grep "173 report title surface" "$REPORT_FILE" "Muhasebeci Portal Testleri"
check_grep "173 report tenant guard" "$REPORT_FILE" "data-tenant-guard|Tenant Scope"
check_grep "173 report accountant guard" "$REPORT_FILE" "data-accountant-guard|Accountant"
check_grep "173 report firm scope guard" "$REPORT_FILE" "data-firm-scope|Firm Scope"
check_grep "173 report cross tenant closed" "$REPORT_FILE" "data-cross-tenant-access|Cross Tenant: CLOSED"
check_grep "173 report production false" "$REPORT_FILE" "data-production-approved|Production: FALSE"
check_grep "173 report 167 coverage" "$REPORT_FILE" "167.*Export Workspace|/faz3/accountant-portal/export-workspace/"
check_grep "173 report 168 coverage" "$REPORT_FILE" "168.*Çok Firmalı|/faz3/accountant-portal/multi-company-workspace/"
check_grep "173 report 169 coverage" "$REPORT_FILE" "169.*Firma Değiştirici|/faz3/accountant-portal/company-switcher/"
check_grep "173 report 170 coverage" "$REPORT_FILE" "170.*Firma Bazlı|/faz3/accountant-portal/company-permissions/"
check_grep "173 report 171 coverage" "$REPORT_FILE" "171.*Abonelik|/faz3/accountant-portal/subscription-status/"
check_grep "173 report 172 coverage" "$REPORT_FILE" "172.*Portal Audit|/faz3/accountant-portal/audit-history/"
check_grep "173 report live policy closed" "$REPORT_FILE" "Real billing: CLOSED|Audit delete/mutation: CLOSED|Real external delivery: CLOSED"

check_grep "173 config suite enabled" "$CONFIG_FILE" "\"suite_enabled\": true"
check_grep "173 config route" "$CONFIG_FILE" "\"route\": \"/faz3/accountant-portal/portal-tests/\""
check_grep "173 config screen 167 coverage" "$CONFIG_FILE" "\"screen_167_export_workspace\""
check_grep "173 config screen 168 coverage" "$CONFIG_FILE" "\"screen_168_multi_company_workspace\""
check_grep "173 config screen 169 coverage" "$CONFIG_FILE" "\"screen_169_company_switcher\""
check_grep "173 config screen 170 coverage" "$CONFIG_FILE" "\"screen_170_company_permissions\""
check_grep "173 config screen 171 coverage" "$CONFIG_FILE" "\"screen_171_subscription_status\""
check_grep "173 config screen 172 coverage" "$CONFIG_FILE" "\"screen_172_audit_history\""
check_grep "173 config html required" "$CONFIG_FILE" "\"html_file_required\": true"
check_grep "173 config config required" "$CONFIG_FILE" "\"config_file_required\": true"
check_grep "173 config evidence required" "$CONFIG_FILE" "\"evidence_file_required\": true"
check_grep "173 config phase marker required" "$CONFIG_FILE" "\"phase_marker_required\": true"
check_grep "173 config screen marker required" "$CONFIG_FILE" "\"screen_marker_required\": true"
check_grep "173 config tenant guard required" "$CONFIG_FILE" "\"tenant_guard_required\": true"
check_grep "173 config accountant guard required" "$CONFIG_FILE" "\"accountant_guard_required\": true"
check_grep "173 config firm scope required" "$CONFIG_FILE" "\"firm_scope_required\": true"
check_grep "173 config cross tenant closed required" "$CONFIG_FILE" "\"cross_tenant_closed_required\": true"
check_grep "173 config production policy required" "$CONFIG_FILE" "\"production_false_or_readonly_policy_required\": true"
check_grep "173 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "173 config no real billing required" "$CONFIG_FILE" "\"no_real_billing_required\": true"
check_grep "173 config no external delivery required" "$CONFIG_FILE" "\"no_external_delivery_required\": true"
check_grep "173 config append only audit required" "$CONFIG_FILE" "\"append_only_audit_required\": true"

check_grep "173 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "173 config tests readonly true" "$CONFIG_FILE" "\"accountant_portal_tests_are_static_and_readonly\": true"
check_grep "173 config cross tenant false" "$CONFIG_FILE" "\"cross_tenant_access_allowed\": false"
check_grep "173 config real billing false" "$CONFIG_FILE" "\"real_billing_allowed\": false"
check_grep "173 config real payment collection false" "$CONFIG_FILE" "\"real_payment_collection_allowed\": false"
check_grep "173 config real invoice issue false" "$CONFIG_FILE" "\"real_invoice_issue_allowed\": false"
check_grep "173 config external delivery false" "$CONFIG_FILE" "\"real_external_delivery_allowed\": false"
check_grep "173 config audit delete false" "$CONFIG_FILE" "\"audit_delete_allowed\": false"
check_grep "173 config audit mutation false" "$CONFIG_FILE" "\"audit_mutation_allowed\": false"
check_grep "173 config ui actions evidence only" "$CONFIG_FILE" "\"ui_actions_are_navigation_evidence_only\": true"
check_grep "173 config next gate" "$CONFIG_FILE" "FAZ_3_13_1_EBELGE_STATUS_CENTER"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"cross_tenant_access_allowed\"[[:space:]]*:[[:space:]]*true|\"real_billing_allowed\"[[:space:]]*:[[:space:]]*true|\"real_payment_collection_allowed\"[[:space:]]*:[[:space:]]*true|\"real_invoice_issue_allowed\"[[:space:]]*:[[:space:]]*true|\"real_external_delivery_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_delete_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_mutation_allowed\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "173 live policy accountant portal test guard"
else
  pass "173 live policy accountant portal test guard"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

echo "===== 173 — FAZ 3-12.7 ACCOUNTANT PORTAL TEST SUITE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_12_7_ACCOUNTANT_PORTAL_TEST_SUITE_STATUS=${FINAL_STATUS}"
echo "FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_13_1_READY=${NEXT_READY}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
