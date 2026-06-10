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

echo "===== 164 — FAZ 3-11.2 FINANCE SUMMARY SCREEN REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/erp-ui/finance-summary/index.html"
CONFIG_FILE="configs/faz3/web/finance_summary_screen.v1.json"
DOC_FILE="docs/faz3/web/FAZ_3_11_2_FINANCE_SUMMARY_SCREEN.md"

check_file "164 finance summary HTML screen file" "$SCREEN_FILE"
check_file "164 finance summary config file" "$CONFIG_FILE"
check_file "164 finance summary documentation file" "$DOC_FILE"

check_grep "164 phase marker" "$SCREEN_FILE" "FAZ_3_11_2"
check_grep "164 screen marker" "$SCREEN_FILE" "FINANCE_SUMMARY_SCREEN"
check_grep "164 title surface" "$SCREEN_FILE" "Finans Özet Ekranı"
check_grep "164 summary table surface" "$SCREEN_FILE" "Finans Özet Kalemleri|summaryRows"
check_grep "164 gross revenue surface" "$SCREEN_FILE" "Brüt satış|gross_revenue|grossMinor"
check_grep "164 net revenue surface" "$SCREEN_FILE" "netMinor|Net"
check_grep "164 expense surface" "$SCREEN_FILE" "EXPENSE|Gider|Alış maliyetleri"
check_grep "164 gross profit surface" "$SCREEN_FILE" "PROFIT|Kâr|Brüt / net kâr"
check_grep "164 net profit surface" "$SCREEN_FILE" "Net kâr"
check_grep "164 KDV position surface" "$SCREEN_FILE" "KDV|391.01.20|191.01.20"
check_grep "164 stopaj position surface" "$SCREEN_FILE" "stopaj|360.01.20"
check_grep "164 cash bank surface" "$SCREEN_FILE" "CASH_BANK|Kasa / Banka|102.01|100.01"
check_grep "164 receivable payable surface" "$SCREEN_FILE" "RECEIVABLE_PAYABLE|Borç / Alacak|120.01|320.01"
check_grep "164 payment collection surface" "$SCREEN_FILE" "PAYMENT|Tahsilat|Tahsilat ve ödeme kapanışı"
check_grep "164 reconciliation status surface" "$SCREEN_FILE" "reconciliationStatus|Reconciliation"
check_grep "164 export readiness surface" "$SCREEN_FILE" "exportStatus|Export Readiness|LOGO_MIKRO_ZIRVE_ETA_READY"
check_grep "164 source screen link surface" "$SCREEN_FILE" "sourceScreen|Source Screen|FAZ_3_11_3_JOURNAL_LEDGER_SCREEN"
check_grep "164 journal ledger source surface" "$SCREEN_FILE" "FAZ_3_11_3_JOURNAL_LEDGER_SCREEN"
check_grep "164 tax rule source surface" "$SCREEN_FILE" "FAZ_3_11_5_TAX_KDV_RULE_SCREEN"
check_grep "164 reconciliation source surface" "$SCREEN_FILE" "FAZ_3_11_6_RECONCILIATION_SCREEN"
check_grep "164 export center source surface" "$SCREEN_FILE" "FAZ_3_11_7_EXPORT_CENTER_SCREEN"
check_grep "164 payment reconciliation source surface" "$SCREEN_FILE" "FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN"
check_grep "164 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "164 summary hash trace" "$SCREEN_FILE" "summaryHash|Summary Hash"
check_grep "164 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "164 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant"
check_grep "164 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|Correlation"
check_grep "164 period filter surface" "$SCREEN_FILE" "periodFilter|Period: 2026-05|2026-Q2|YTD"
check_grep "164 filter bar surface" "$SCREEN_FILE" "searchInput|categoryFilter|statusFilter|sourceFilter|periodFilter"
check_grep "164 detail drawer surface" "$SCREEN_FILE" "data-detail-drawer"
check_grep "164 operation action panel" "$SCREEN_FILE" "data-operation-actions|Finans Operasyonları"
check_grep "164 drill down surface" "$SCREEN_FILE" "DRILL_DOWN|Drill-down|data-action=\"drill-down\""
check_grep "164 reconcile check surface" "$SCREEN_FILE" "RECONCILE|Reconcile Check|data-action=\"reconcile-check\""
check_grep "164 export readiness action surface" "$SCREEN_FILE" "EXPORT_READINESS|Export Readiness|data-action=\"export-readiness\""
check_grep "164 audit evidence action surface" "$SCREEN_FILE" "AUDIT|Audit Evidence|data-action=\"audit-evidence\""
check_grep "164 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "164 read only summary surface" "$SCREEN_FILE" "readOnlySummary = true|read-only karar destek|Read-only Summary"
check_grep "164 real payment capture false surface" "$SCREEN_FILE" "realPaymentCaptureAllowed = false|Real Payment Capture"
check_grep "164 real export delivery false surface" "$SCREEN_FILE" "realExportDeliveryAllowed = false|Real Export Delivery"
check_grep "164 real tax rule change false surface" "$SCREEN_FILE" "realTaxRuleChangeAllowed = false|Real Tax Rule Change"
check_grep "164 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production: FALSE"
check_grep "164 no write notice" "$SCREEN_FILE" "Muhasebe kaydı|ödeme capture|canlı export|read-only"

check_grep "164 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "164 config route" "$CONFIG_FILE" "\"route\": \"/faz3/erp-ui/finance-summary/\""
check_grep "164 config gross revenue visibility" "$CONFIG_FILE" "\"gross_revenue_visibility\": true"
check_grep "164 config net revenue visibility" "$CONFIG_FILE" "\"net_revenue_visibility\": true"
check_grep "164 config expense visibility" "$CONFIG_FILE" "\"expense_visibility\": true"
check_grep "164 config gross profit visibility" "$CONFIG_FILE" "\"gross_profit_visibility\": true"
check_grep "164 config net profit visibility" "$CONFIG_FILE" "\"net_profit_visibility\": true"
check_grep "164 config KDV position visibility" "$CONFIG_FILE" "\"kdv_position_visibility\": true"
check_grep "164 config stopaj position visibility" "$CONFIG_FILE" "\"stopaj_position_visibility\": true"
check_grep "164 config cash bank visibility" "$CONFIG_FILE" "\"cash_bank_visibility\": true"
check_grep "164 config receivable payable visibility" "$CONFIG_FILE" "\"receivable_payable_visibility\": true"
check_grep "164 config payment collection visibility" "$CONFIG_FILE" "\"payment_collection_visibility\": true"
check_grep "164 config reconciliation visibility" "$CONFIG_FILE" "\"reconciliation_status_visibility\": true"
check_grep "164 config export readiness visibility" "$CONFIG_FILE" "\"export_readiness_visibility\": true"
check_grep "164 config source screen visibility" "$CONFIG_FILE" "\"source_screen_link_visibility\": true"
check_grep "164 config audit evidence visibility" "$CONFIG_FILE" "\"audit_evidence_visibility\": true"
check_grep "164 config period filter visibility" "$CONFIG_FILE" "\"period_filter_visibility\": true"
check_grep "164 config tenant finance scope visibility" "$CONFIG_FILE" "\"tenant_finance_scope_visibility\": true"
check_grep "164 config readonly decision surface" "$CONFIG_FILE" "\"readonly_decision_surface\": true"
check_grep "164 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "164 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "164 config request required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "164 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "164 config finance row id required" "$CONFIG_FILE" "\"finance_row_id_required\": true"
check_grep "164 config period required" "$CONFIG_FILE" "\"period_required\": true"
check_grep "164 config account code visibility required" "$CONFIG_FILE" "\"account_code_visibility_required\": true"
check_grep "164 config gross amount required" "$CONFIG_FILE" "\"gross_amount_required\": true"
check_grep "164 config net amount required" "$CONFIG_FILE" "\"net_amount_required\": true"
check_grep "164 config tax amount required" "$CONFIG_FILE" "\"tax_amount_required\": true"
check_grep "164 config source screen required" "$CONFIG_FILE" "\"source_screen_required\": true"
check_grep "164 config readiness required" "$CONFIG_FILE" "\"readiness_status_required\": true"
check_grep "164 config reconciliation required" "$CONFIG_FILE" "\"reconciliation_status_required\": true"
check_grep "164 config export status required" "$CONFIG_FILE" "\"export_status_required\": true"
check_grep "164 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "164 config summary hash required" "$CONFIG_FILE" "\"summary_hash_required\": true"
check_grep "164 config evidence file required" "$CONFIG_FILE" "\"evidence_file_required\": true"
check_grep "164 config account 600 coverage" "$CONFIG_FILE" "\"account_600_revenue\": true"
check_grep "164 config account 153 coverage" "$CONFIG_FILE" "\"account_153_inventory_cost\": true"
check_grep "164 config account 391 coverage" "$CONFIG_FILE" "\"account_391_output_kdv\": true"
check_grep "164 config account 191 coverage" "$CONFIG_FILE" "\"account_191_input_kdv\": true"
check_grep "164 config account 360 coverage" "$CONFIG_FILE" "\"account_360_stopaj\": true"
check_grep "164 config account 120 coverage" "$CONFIG_FILE" "\"account_120_receivables\": true"
check_grep "164 config account 320 coverage" "$CONFIG_FILE" "\"account_320_payables\": true"
check_grep "164 config account 102 coverage" "$CONFIG_FILE" "\"account_102_bank\": true"
check_grep "164 config account 100 coverage" "$CONFIG_FILE" "\"account_100_cash\": true"
check_grep "164 config account 610 coverage" "$CONFIG_FILE" "\"account_610_sales_returns\": true"
check_grep "164 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "164 config readonly summary true" "$CONFIG_FILE" "\"readonly_summary\": true"
check_grep "164 config payment capture false" "$CONFIG_FILE" "\"real_payment_capture_allowed\": false"
check_grep "164 config export delivery false" "$CONFIG_FILE" "\"real_export_delivery_allowed\": false"
check_grep "164 config tax rule change false" "$CONFIG_FILE" "\"real_tax_rule_change_allowed\": false"
check_grep "164 config ledger write false" "$CONFIG_FILE" "\"real_ledger_write_allowed\": false"
check_grep "164 config navigation evidence only" "$CONFIG_FILE" "\"ui_actions_are_navigation_and_evidence_only\": true"
check_grep "164 config voucher pipeline backend gate" "$CONFIG_FILE" "FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE"
check_grep "164 config posting backend gate" "$CONFIG_FILE" "FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME"
check_grep "164 config audit trace backend gate" "$CONFIG_FILE" "FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE"
check_grep "164 config TDHP reconciliation backend gate" "$CONFIG_FILE" "FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME"
check_grep "164 config tax runtime tests gate" "$CONFIG_FILE" "FAZ_3_10_2_6_TAX_RUNTIME_TESTS"
check_grep "164 config export adapter tests gate" "$CONFIG_FILE" "FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS"
check_grep "164 config payment integration tests gate" "$CONFIG_FILE" "FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS"
check_grep "164 config ERP TR readiness gate" "$CONFIG_FILE" "FAZ_3_10_8_6_ERP_TR_LIVE_READINESS_CLOSURE"
check_grep "164 config journal screen gate" "$CONFIG_FILE" "FAZ_3_11_3_JOURNAL_LEDGER_SCREEN"
check_grep "164 config tax screen gate" "$CONFIG_FILE" "FAZ_3_11_5_TAX_KDV_RULE_SCREEN"
check_grep "164 config reconciliation screen gate" "$CONFIG_FILE" "FAZ_3_11_6_RECONCILIATION_SCREEN"
check_grep "164 config export screen gate" "$CONFIG_FILE" "FAZ_3_11_7_EXPORT_CENTER_SCREEN"
check_grep "164 config payment screen gate" "$CONFIG_FILE" "FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN"
check_grep "164 config next gate" "$CONFIG_FILE" "FAZ_3_11_1_MAIN_MANAGEMENT_DASHBOARD"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"readonly_summary\"[[:space:]]*:[[:space:]]*false|\"real_payment_capture_allowed\"[[:space:]]*:[[:space:]]*true|\"real_export_delivery_allowed\"[[:space:]]*:[[:space:]]*true|\"real_tax_rule_change_allowed\"[[:space:]]*:[[:space:]]*true|\"real_ledger_write_allowed\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "164 live policy readonly guard"
else
  pass "164 live policy readonly guard"
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
# 164 — FAZ 3-11.2 — Finance Summary Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_11_2_FINANCE_SUMMARY_SCREEN_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_11_2_FINANCE_SUMMARY_SCREEN_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_11_1_READY=${NEXT_READY}

## Scope

- Gross revenue surface
- Net revenue surface
- Expense surface
- Gross profit surface
- Net profit surface
- KDV position surface
- Stopaj position surface
- Cash / bank surface
- Receivable / payable surface
- Payment collection surface
- Reconciliation status surface
- Export readiness surface
- Source screen link surface
- Audit evidence surface
- Period filter surface
- Tenant finance scope surface
- Read-only decision surface
- Account coverage: 600 / 153 / 391 / 191 / 360 / 120 / 320 / 102 / 100 / 610
- Audit hash / summary hash / evidence file traces
- Production approved FALSE
- Read-only summary TRUE

## Live Policy

- Finance summary is read-only.
- Real payment capture: CLOSED
- Real export delivery: CLOSED
- Real tax rule change: CLOSED
- Real ledger write: CLOSED
- UI actions are navigation/evidence only.
- This screen is decision support/UI evidence, not production activation.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 164 — FAZ 3-11.2 FINANCE SUMMARY SCREEN COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_2_FINANCE_SUMMARY_SCREEN_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_2_FINANCE_SUMMARY_SCREEN_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_11_1_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
