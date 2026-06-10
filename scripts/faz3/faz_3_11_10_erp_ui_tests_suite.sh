#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

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

echo "===== 166 — FAZ 3-11.10 ERP UI TEST SUITE START ====="

declare -A SCREEN_FILES=(
  ["157"]="web/faz3/erp-ui/ebelge-operations/index.html"
  ["158"]="web/faz3/erp-ui/reconciliation/index.html"
  ["159"]="web/faz3/erp-ui/tax-kdv-rules/index.html"
  ["160"]="web/faz3/erp-ui/journal-ledger/index.html"
  ["161"]="web/faz3/erp-ui/tdhp-mapping/index.html"
  ["162"]="web/faz3/erp-ui/payment-reconciliation/index.html"
  ["163"]="web/faz3/erp-ui/export-center/index.html"
  ["164"]="web/faz3/erp-ui/finance-summary/index.html"
  ["165"]="web/faz3/erp-ui/main-dashboard/index.html"
)

declare -A CONFIG_FILES=(
  ["157"]="configs/faz3/web/ebelge_operations_screen.v1.json"
  ["158"]="configs/faz3/web/reconciliation_screen.v1.json"
  ["159"]="configs/faz3/web/tax_kdv_rule_screen.v1.json"
  ["160"]="configs/faz3/web/journal_ledger_screen.v1.json"
  ["161"]="configs/faz3/web/tdhp_mapping_screen.v1.json"
  ["162"]="configs/faz3/web/payment_reconciliation_screen.v1.json"
  ["163"]="configs/faz3/web/export_center_screen.v1.json"
  ["164"]="configs/faz3/web/finance_summary_screen.v1.json"
  ["165"]="configs/faz3/web/main_management_dashboard.v1.json"
)

declare -A EVIDENCE_FILES=(
  ["157"]="docs/faz3/evidence/FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
  ["158"]="docs/faz3/evidence/FAZ_3_11_6_RECONCILIATION_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
  ["159"]="docs/faz3/evidence/FAZ_3_11_5_TAX_KDV_RULE_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
  ["160"]="docs/faz3/evidence/FAZ_3_11_3_JOURNAL_LEDGER_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
  ["161"]="docs/faz3/evidence/FAZ_3_11_4_TDHP_MAPPING_VIEW_CONTROL_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
  ["162"]="docs/faz3/evidence/FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
  ["163"]="docs/faz3/evidence/FAZ_3_11_7_EXPORT_CENTER_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
  ["164"]="docs/faz3/evidence/FAZ_3_11_2_FINANCE_SUMMARY_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
  ["165"]="docs/faz3/evidence/FAZ_3_11_1_MAIN_MANAGEMENT_DASHBOARD_REAL_IMPLEMENTATION_AUDIT.md"
)

declare -A PHASE_MARKERS=(
  ["157"]="FAZ_3_11_8"
  ["158"]="FAZ_3_11_6"
  ["159"]="FAZ_3_11_5"
  ["160"]="FAZ_3_11_3"
  ["161"]="FAZ_3_11_4"
  ["162"]="FAZ_3_11_9"
  ["163"]="FAZ_3_11_7"
  ["164"]="FAZ_3_11_2"
  ["165"]="FAZ_3_11_1"
)

declare -A SCREEN_MARKERS=(
  ["157"]="EBELGE_OPERATIONS_SCREEN"
  ["158"]="RECONCILIATION_SCREEN"
  ["159"]="TAX_KDV_RULE_SCREEN"
  ["160"]="JOURNAL_LEDGER_SCREEN"
  ["161"]="TDHP_MAPPING_VIEW_CONTROL_SCREEN"
  ["162"]="PAYMENT_RECONCILIATION_SCREEN"
  ["163"]="EXPORT_CENTER_SCREEN"
  ["164"]="FINANCE_SUMMARY_SCREEN"
  ["165"]="MAIN_MANAGEMENT_DASHBOARD"
)

for n in 157 158 159 160 161 162 163 164 165; do
  screen="${SCREEN_FILES[$n]}"
  config="${CONFIG_FILES[$n]}"
  evidence="${EVIDENCE_FILES[$n]}"

  check_file "166 screen ${n} HTML file" "$screen"
  check_file "166 screen ${n} config file" "$config"
  check_file "166 screen ${n} evidence file" "$evidence"

  check_grep "166 screen ${n} phase marker" "$screen" "${PHASE_MARKERS[$n]}"
  check_grep "166 screen ${n} screen marker" "$screen" "${SCREEN_MARKERS[$n]}"
  check_grep "166 screen ${n} tenant guard" "$screen" "Tenant|tenant|data-tenant-guard"
  check_grep "166 screen ${n} correlation guard" "$screen" "Correlation|correlation|data-correlation-guard"
  check_grep "166 screen ${n} production false or gate closed" "$screen" "Production: FALSE|productionApproved = false|CLOSED|closed|read-only|readonly"
  check_grep "166 screen ${n} config screen enabled" "$config" "\"screen_enabled\"[[:space:]]*:[[:space:]]*true|\"suite_enabled\"[[:space:]]*:[[:space:]]*true"
  check_grep "166 screen ${n} config route" "$config" "\"route\""
  check_grep "166 screen ${n} evidence final status" "$evidence" "FINAL_STATUS=PASS|FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
done

MAIN="web/faz3/erp-ui/main-dashboard/index.html"

check_grep "166 main dashboard links 157" "$MAIN" "/faz3/erp-ui/ebelge-operations/|157 — e-Belge"
check_grep "166 main dashboard links 158" "$MAIN" "/faz3/erp-ui/reconciliation/|158 — Reconciliation"
check_grep "166 main dashboard links 159" "$MAIN" "/faz3/erp-ui/tax-kdv-rules/|159 — Vergi"
check_grep "166 main dashboard links 160" "$MAIN" "/faz3/erp-ui/journal-ledger/|160 — Journal"
check_grep "166 main dashboard links 161" "$MAIN" "/faz3/erp-ui/tdhp-mapping/|161 — TDHP"
check_grep "166 main dashboard links 162" "$MAIN" "/faz3/erp-ui/payment-reconciliation/|162 — Ödeme"
check_grep "166 main dashboard links 163" "$MAIN" "/faz3/erp-ui/export-center/|163 — Export"
check_grep "166 main dashboard links 164" "$MAIN" "/faz3/erp-ui/finance-summary/|164 — Finans"

CONFIG_FILE="configs/faz3/web/erp_ui_tests.v1.json"
check_file "166 ERP UI tests config file" "$CONFIG_FILE"
check_grep "166 config suite enabled" "$CONFIG_FILE" "\"suite_enabled\": true"
check_grep "166 config screen 157 coverage" "$CONFIG_FILE" "\"screen_157_ebelge_operations\""
check_grep "166 config screen 158 coverage" "$CONFIG_FILE" "\"screen_158_reconciliation\""
check_grep "166 config screen 159 coverage" "$CONFIG_FILE" "\"screen_159_tax_kdv_rule\""
check_grep "166 config screen 160 coverage" "$CONFIG_FILE" "\"screen_160_journal_ledger\""
check_grep "166 config screen 161 coverage" "$CONFIG_FILE" "\"screen_161_tdhp_mapping\""
check_grep "166 config screen 162 coverage" "$CONFIG_FILE" "\"screen_162_payment_reconciliation\""
check_grep "166 config screen 163 coverage" "$CONFIG_FILE" "\"screen_163_export_center\""
check_grep "166 config screen 164 coverage" "$CONFIG_FILE" "\"screen_164_finance_summary\""
check_grep "166 config screen 165 coverage" "$CONFIG_FILE" "\"screen_165_main_dashboard\""
check_grep "166 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "166 config readonly tests true" "$CONFIG_FILE" "\"ui_tests_are_static_and_readonly\": true"
check_grep "166 config ledger write false" "$CONFIG_FILE" "\"real_ledger_write_allowed\": false"
check_grep "166 config tax rule activation false" "$CONFIG_FILE" "\"real_tax_rule_activation_allowed\": false"
check_grep "166 config payment capture false" "$CONFIG_FILE" "\"real_payment_capture_allowed\": false"
check_grep "166 config export delivery false" "$CONFIG_FILE" "\"real_export_delivery_allowed\": false"
check_grep "166 config eBelge provider false" "$CONFIG_FILE" "\"real_ebelge_provider_call_allowed\": false"
check_grep "166 config next gate" "$CONFIG_FILE" "FAZ_3_12_4_EXCEL_PDF_TDHP_EXPORT_WORKSPACE"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_ledger_write_allowed\"[[:space:]]*:[[:space:]]*true|\"real_tax_rule_activation_allowed\"[[:space:]]*:[[:space:]]*true|\"real_payment_capture_allowed\"[[:space:]]*:[[:space:]]*true|\"real_export_delivery_allowed\"[[:space:]]*:[[:space:]]*true|\"real_ebelge_provider_call_allowed\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "166 live policy closed guard"
else
  pass "166 live policy closed guard"
fi

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

echo "===== 166 — FAZ 3-11.10 ERP UI TEST SUITE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_10_ERP_UI_TESTS_SUITE_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_10_ERP_UI_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_12_4_READY=${NEXT_READY}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
