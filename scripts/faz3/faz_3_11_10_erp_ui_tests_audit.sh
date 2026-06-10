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

echo "===== 166 — FAZ 3-11.10 ERP UI TESTS REAL IMPLEMENTATION AUDIT START ====="

CONFIG_FILE="configs/faz3/web/erp_ui_tests.v1.json"
DOC_FILE="docs/faz3/web/FAZ_3_11_10_ERP_UI_TESTS.md"
TEST_SCRIPT="scripts/faz3/faz_3_11_10_erp_ui_tests_suite.sh"
REPORT_FILE="web/faz3/erp-ui/ui-tests/index.html"

check_file "166 ERP UI tests config file" "$CONFIG_FILE"
check_file "166 ERP UI tests documentation file" "$DOC_FILE"
check_file "166 ERP UI tests suite script file" "$TEST_SCRIPT"
check_file "166 ERP UI tests report HTML file" "$REPORT_FILE"

check_grep "166 report phase marker" "$REPORT_FILE" "FAZ_3_11_10"
check_grep "166 report screen marker" "$REPORT_FILE" "ERP_UI_TESTS_REPORT"
check_grep "166 report title surface" "$REPORT_FILE" "ERP UI Testleri"
check_grep "166 report tenant guard surface" "$REPORT_FILE" "data-tenant-guard|Tenant"
check_grep "166 report correlation guard surface" "$REPORT_FILE" "data-correlation-guard|Correlation"
check_grep "166 report production false surface" "$REPORT_FILE" "Production: FALSE|data-production-approved"
check_grep "166 report read only policy" "$REPORT_FILE" "READ-ONLY|Canlı aksiyon yok"
check_grep "166 report screen 157 coverage" "$REPORT_FILE" "157.*e-Belge|/faz3/erp-ui/ebelge-operations/"
check_grep "166 report screen 158 coverage" "$REPORT_FILE" "158.*Reconciliation|/faz3/erp-ui/reconciliation/"
check_grep "166 report screen 159 coverage" "$REPORT_FILE" "159.*Vergi|/faz3/erp-ui/tax-kdv-rules/"
check_grep "166 report screen 160 coverage" "$REPORT_FILE" "160.*Journal|/faz3/erp-ui/journal-ledger/"
check_grep "166 report screen 161 coverage" "$REPORT_FILE" "161.*TDHP|/faz3/erp-ui/tdhp-mapping/"
check_grep "166 report screen 162 coverage" "$REPORT_FILE" "162.*Ödeme|/faz3/erp-ui/payment-reconciliation/"
check_grep "166 report screen 163 coverage" "$REPORT_FILE" "163.*Export|/faz3/erp-ui/export-center/"
check_grep "166 report screen 164 coverage" "$REPORT_FILE" "164.*Finans|/faz3/erp-ui/finance-summary/"
check_grep "166 report screen 165 coverage" "$REPORT_FILE" "165.*Ana Yönetim|/faz3/erp-ui/main-dashboard/"
check_grep "166 report live policy closed" "$REPORT_FILE" "Ledger write: CLOSED|Payment capture: CLOSED|Export delivery: CLOSED|e-Belge provider call: CLOSED"

check_grep "166 config suite enabled" "$CONFIG_FILE" "\"suite_enabled\": true"
check_grep "166 config route" "$CONFIG_FILE" "\"route\": \"/faz3/erp-ui/ui-tests/\""
check_grep "166 config report file" "$CONFIG_FILE" "\"report_file\": \"web/faz3/erp-ui/ui-tests/index.html\""
check_grep "166 config test script" "$CONFIG_FILE" "faz_3_11_10_erp_ui_tests_suite.sh"
check_grep "166 config audit script" "$CONFIG_FILE" "faz_3_11_10_erp_ui_tests_audit.sh"
check_grep "166 config screen 157 coverage" "$CONFIG_FILE" "\"screen_157_ebelge_operations\""
check_grep "166 config screen 158 coverage" "$CONFIG_FILE" "\"screen_158_reconciliation\""
check_grep "166 config screen 159 coverage" "$CONFIG_FILE" "\"screen_159_tax_kdv_rule\""
check_grep "166 config screen 160 coverage" "$CONFIG_FILE" "\"screen_160_journal_ledger\""
check_grep "166 config screen 161 coverage" "$CONFIG_FILE" "\"screen_161_tdhp_mapping\""
check_grep "166 config screen 162 coverage" "$CONFIG_FILE" "\"screen_162_payment_reconciliation\""
check_grep "166 config screen 163 coverage" "$CONFIG_FILE" "\"screen_163_export_center\""
check_grep "166 config screen 164 coverage" "$CONFIG_FILE" "\"screen_164_finance_summary\""
check_grep "166 config screen 165 coverage" "$CONFIG_FILE" "\"screen_165_main_dashboard\""
check_grep "166 config html file required" "$CONFIG_FILE" "\"html_file_required\": true"
check_grep "166 config config file required" "$CONFIG_FILE" "\"config_file_required\": true"
check_grep "166 config evidence required" "$CONFIG_FILE" "\"evidence_file_required\": true"
check_grep "166 config tenant required" "$CONFIG_FILE" "\"tenant_guard_required\": true"
check_grep "166 config correlation required" "$CONFIG_FILE" "\"correlation_guard_required\": true"
check_grep "166 config production false required" "$CONFIG_FILE" "\"production_false_required\": true"
check_grep "166 config route trace required" "$CONFIG_FILE" "\"route_trace_required\": true"
check_grep "166 config main dashboard links required" "$CONFIG_FILE" "\"main_dashboard_links_required\": true"
check_grep "166 config no real external action required" "$CONFIG_FILE" "\"no_real_external_action_required\": true"
check_grep "166 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "166 config readonly tests true" "$CONFIG_FILE" "\"ui_tests_are_static_and_readonly\": true"
check_grep "166 config ledger write false" "$CONFIG_FILE" "\"real_ledger_write_allowed\": false"
check_grep "166 config tax rule activation false" "$CONFIG_FILE" "\"real_tax_rule_activation_allowed\": false"
check_grep "166 config payment capture false" "$CONFIG_FILE" "\"real_payment_capture_allowed\": false"
check_grep "166 config export delivery false" "$CONFIG_FILE" "\"real_export_delivery_allowed\": false"
check_grep "166 config eBelge provider false" "$CONFIG_FILE" "\"real_ebelge_provider_call_allowed\": false"
check_grep "166 config previous gate" "$CONFIG_FILE" "FAZ_3_11_1_MAIN_MANAGEMENT_DASHBOARD"
check_grep "166 config next gate" "$CONFIG_FILE" "FAZ_3_12_4_EXCEL_PDF_TDHP_EXPORT_WORKSPACE"

echo "===== 166 — RUN ERP UI TEST SUITE FROM AUDIT ====="
if "$TEST_SCRIPT"; then
  pass "166 ERP UI test suite execution"
else
  fail "166 ERP UI test suite execution"
fi

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_ledger_write_allowed\"[[:space:]]*:[[:space:]]*true|\"real_tax_rule_activation_allowed\"[[:space:]]*:[[:space:]]*true|\"real_payment_capture_allowed\"[[:space:]]*:[[:space:]]*true|\"real_export_delivery_allowed\"[[:space:]]*:[[:space:]]*true|\"real_ebelge_provider_call_allowed\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "166 live policy readonly guard"
else
  pass "166 live policy readonly guard"
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
# 166 — FAZ 3-11.10 — ERP UI Tests Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_11_10_ERP_UI_TESTS_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_11_10_ERP_UI_TESTS_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_12_4_READY=${NEXT_READY}

## Scope

- 157 e-Belge operations screen
- 158 reconciliation screen
- 159 tax/KDV rule screen
- 160 journal/ledger screen
- 161 TDHP mapping screen
- 162 payment/reconciliation screen
- 163 export center screen
- 164 finance summary screen
- 165 main management dashboard
- Main dashboard link coverage
- Route/config/evidence coverage
- Tenant/correlation/production false checks
- Static/read-only UI test report

## Live Policy

- ERP UI tests are static/read-only.
- Real ledger write: CLOSED
- Real tax rule activation: CLOSED
- Real payment capture: CLOSED
- Real export delivery: CLOSED
- Real e-Belge provider call: CLOSED
- UI actions are navigation/evidence only.

## Audit Notes

Final status is derived from real files, real suite execution, and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 166 — FAZ 3-11.10 ERP UI TESTS COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_10_ERP_UI_TESTS_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_10_ERP_UI_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_12_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
