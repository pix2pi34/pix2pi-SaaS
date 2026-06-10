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

echo "===== 165 — FAZ 3-11.1 MAIN MANAGEMENT DASHBOARD REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/erp-ui/main-dashboard/index.html"
CONFIG_FILE="configs/faz3/web/main_management_dashboard.v1.json"
DOC_FILE="docs/faz3/web/FAZ_3_11_1_MAIN_MANAGEMENT_DASHBOARD.md"

check_file "165 main dashboard HTML screen file" "$SCREEN_FILE"
check_file "165 main dashboard config file" "$CONFIG_FILE"
check_file "165 main dashboard documentation file" "$DOC_FILE"

check_grep "165 phase marker" "$SCREEN_FILE" "FAZ_3_11_1"
check_grep "165 screen marker" "$SCREEN_FILE" "MAIN_MANAGEMENT_DASHBOARD"
check_grep "165 title surface" "$SCREEN_FILE" "Ana Yönetim Dashboard"
check_grep "165 central navigation surface" "$SCREEN_FILE" "ERP Yönetim Modülleri|moduleGrid"
check_grep "165 screen readiness KPI surface" "$SCREEN_FILE" "screen_readiness|8/8|157–164"
check_grep "165 finance health KPI surface" "$SCREEN_FILE" "finance_health|Finans health"
check_grep "165 open review KPI surface" "$SCREEN_FILE" "open_review|Review kalemi"
check_grep "165 production gate KPI surface" "$SCREEN_FILE" "production_gate|Production gate"
check_grep "165 finance summary link surface" "$SCREEN_FILE" "finance-summary|164 — Finans Özet|FAZ_3_11_2_FINANCE_SUMMARY_SCREEN"
check_grep "165 export center link surface" "$SCREEN_FILE" "export-center|163 — Export Center|FAZ_3_11_7_EXPORT_CENTER_SCREEN"
check_grep "165 payment reconciliation link surface" "$SCREEN_FILE" "payment-reconciliation|162 — Ödeme / Mutabakat|FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN"
check_grep "165 TDHP mapping link surface" "$SCREEN_FILE" "tdhp-mapping|161 — TDHP Mapping|FAZ_3_11_4_TDHP_MAPPING_VIEW_CONTROL_SCREEN"
check_grep "165 journal ledger link surface" "$SCREEN_FILE" "journal-ledger|160 — Journal / Ledger|FAZ_3_11_3_JOURNAL_LEDGER_SCREEN"
check_grep "165 tax KDV rule link surface" "$SCREEN_FILE" "tax-kdv-rules|159 — Vergi / KDV Rule|FAZ_3_11_5_TAX_KDV_RULE_SCREEN"
check_grep "165 reconciliation link surface" "$SCREEN_FILE" "reconciliation|158 — Reconciliation|FAZ_3_11_6_RECONCILIATION_SCREEN"
check_grep "165 eBelge operations link surface" "$SCREEN_FILE" "ebelge-operations|157 — e-Belge Operasyon|FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN"
check_grep "165 module detail drawer surface" "$SCREEN_FILE" "data-detail-drawer|Seçili Modül Detayı"
check_grep "165 backend gate detail surface" "$SCREEN_FILE" "Backend Gate|backendGate"
check_grep "165 evidence file detail surface" "$SCREEN_FILE" "Evidence File|evidenceFile"
check_grep "165 gate health panel surface" "$SCREEN_FILE" "data-health-panel|Gate Health"
check_grep "165 ledger write gate surface" "$SCREEN_FILE" "data-gate=\"ledger-write\"|Ledger Write"
check_grep "165 tax rule activation gate surface" "$SCREEN_FILE" "data-gate=\"tax-rule-activation\"|Tax Rule Activation"
check_grep "165 payment capture gate surface" "$SCREEN_FILE" "data-gate=\"payment-capture\"|Real Payment Capture"
check_grep "165 export delivery gate surface" "$SCREEN_FILE" "data-gate=\"export-delivery\"|Real Export Delivery"
check_grep "165 eBelge provider gate surface" "$SCREEN_FILE" "data-gate=\"ebelge-provider\"|e-Belge Provider"
check_grep "165 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "165 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant"
check_grep "165 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|Correlation"
check_grep "165 readonly dashboard surface" "$SCREEN_FILE" "readonlyDashboard = true|read-only yönetim yüzeyi"
check_grep "165 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production: FALSE"
check_grep "165 real ledger write false surface" "$SCREEN_FILE" "realLedgerWriteAllowed = false"
check_grep "165 real tax rule activation false surface" "$SCREEN_FILE" "realTaxRuleActivationAllowed = false"
check_grep "165 real payment capture false surface" "$SCREEN_FILE" "realPaymentCaptureAllowed = false"
check_grep "165 real export delivery false surface" "$SCREEN_FILE" "realExportDeliveryAllowed = false"
check_grep "165 real eBelge provider false surface" "$SCREEN_FILE" "realEbelgeProviderCallAllowed = false"
check_grep "165 no write notice" "$SCREEN_FILE" "ledger write|tax rule activation|payment capture|export delivery|provider çağrısı"

check_grep "165 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "165 config route" "$CONFIG_FILE" "\"route\": \"/faz3/erp-ui/main-dashboard/\""
check_grep "165 config central navigation visibility" "$CONFIG_FILE" "\"central_navigation_visibility\": true"
check_grep "165 config finance summary link visibility" "$CONFIG_FILE" "\"finance_summary_link_visibility\": true"
check_grep "165 config export center link visibility" "$CONFIG_FILE" "\"export_center_link_visibility\": true"
check_grep "165 config payment reconciliation link visibility" "$CONFIG_FILE" "\"payment_reconciliation_link_visibility\": true"
check_grep "165 config TDHP mapping link visibility" "$CONFIG_FILE" "\"tdhp_mapping_link_visibility\": true"
check_grep "165 config journal ledger link visibility" "$CONFIG_FILE" "\"journal_ledger_link_visibility\": true"
check_grep "165 config tax KDV rule link visibility" "$CONFIG_FILE" "\"tax_kdv_rule_link_visibility\": true"
check_grep "165 config reconciliation link visibility" "$CONFIG_FILE" "\"reconciliation_link_visibility\": true"
check_grep "165 config eBelge operations link visibility" "$CONFIG_FILE" "\"ebelge_operations_link_visibility\": true"
check_grep "165 config screen readiness KPI visibility" "$CONFIG_FILE" "\"screen_readiness_kpi_visibility\": true"
check_grep "165 config finance health KPI visibility" "$CONFIG_FILE" "\"finance_health_kpi_visibility\": true"
check_grep "165 config open review KPI visibility" "$CONFIG_FILE" "\"open_review_kpi_visibility\": true"
check_grep "165 config production gate KPI visibility" "$CONFIG_FILE" "\"production_gate_kpi_visibility\": true"
check_grep "165 config module detail drawer visibility" "$CONFIG_FILE" "\"module_detail_drawer_visibility\": true"
check_grep "165 config gate health panel visibility" "$CONFIG_FILE" "\"gate_health_panel_visibility\": true"
check_grep "165 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"
check_grep "165 config readonly dashboard visibility" "$CONFIG_FILE" "\"readonly_dashboard_visibility\": true"
check_grep "165 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "165 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "165 config request required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "165 config screen route required" "$CONFIG_FILE" "\"screen_route_required\": true"
check_grep "165 config module status required" "$CONFIG_FILE" "\"module_status_required\": true"
check_grep "165 config backend gate required" "$CONFIG_FILE" "\"backend_gate_required\": true"
check_grep "165 config evidence file required" "$CONFIG_FILE" "\"evidence_file_required\": true"
check_grep "165 config production gate visible" "$CONFIG_FILE" "\"production_gate_visible\": true"
check_grep "165 config readonly gate required" "$CONFIG_FILE" "\"readonly_gate_required\": true"
check_grep "165 config screen 157 coverage" "$CONFIG_FILE" "\"screen_157_ebelge_operations\": true"
check_grep "165 config screen 158 coverage" "$CONFIG_FILE" "\"screen_158_reconciliation\": true"
check_grep "165 config screen 159 coverage" "$CONFIG_FILE" "\"screen_159_tax_kdv_rule\": true"
check_grep "165 config screen 160 coverage" "$CONFIG_FILE" "\"screen_160_journal_ledger\": true"
check_grep "165 config screen 161 coverage" "$CONFIG_FILE" "\"screen_161_tdhp_mapping\": true"
check_grep "165 config screen 162 coverage" "$CONFIG_FILE" "\"screen_162_payment_reconciliation\": true"
check_grep "165 config screen 163 coverage" "$CONFIG_FILE" "\"screen_163_export_center\": true"
check_grep "165 config screen 164 coverage" "$CONFIG_FILE" "\"screen_164_finance_summary\": true"
check_grep "165 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "165 config readonly dashboard true" "$CONFIG_FILE" "\"readonly_dashboard\": true"
check_grep "165 config ledger write false" "$CONFIG_FILE" "\"real_ledger_write_allowed\": false"
check_grep "165 config tax rule activation false" "$CONFIG_FILE" "\"real_tax_rule_activation_allowed\": false"
check_grep "165 config payment capture false" "$CONFIG_FILE" "\"real_payment_capture_allowed\": false"
check_grep "165 config export delivery false" "$CONFIG_FILE" "\"real_export_delivery_allowed\": false"
check_grep "165 config eBelge provider call false" "$CONFIG_FILE" "\"real_ebelge_provider_call_allowed\": false"
check_grep "165 config navigation evidence only" "$CONFIG_FILE" "\"ui_actions_are_navigation_and_evidence_only\": true"
check_grep "165 config eBelge screen gate" "$CONFIG_FILE" "FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN"
check_grep "165 config reconciliation screen gate" "$CONFIG_FILE" "FAZ_3_11_6_RECONCILIATION_SCREEN"
check_grep "165 config tax screen gate" "$CONFIG_FILE" "FAZ_3_11_5_TAX_KDV_RULE_SCREEN"
check_grep "165 config journal screen gate" "$CONFIG_FILE" "FAZ_3_11_3_JOURNAL_LEDGER_SCREEN"
check_grep "165 config TDHP mapping screen gate" "$CONFIG_FILE" "FAZ_3_11_4_TDHP_MAPPING_VIEW_CONTROL_SCREEN"
check_grep "165 config payment screen gate" "$CONFIG_FILE" "FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN"
check_grep "165 config export screen gate" "$CONFIG_FILE" "FAZ_3_11_7_EXPORT_CENTER_SCREEN"
check_grep "165 config finance screen gate" "$CONFIG_FILE" "FAZ_3_11_2_FINANCE_SUMMARY_SCREEN"
check_grep "165 config next gate" "$CONFIG_FILE" "FAZ_3_11_10_ERP_UI_TESTS"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"readonly_dashboard\"[[:space:]]*:[[:space:]]*false|\"real_ledger_write_allowed\"[[:space:]]*:[[:space:]]*true|\"real_tax_rule_activation_allowed\"[[:space:]]*:[[:space:]]*true|\"real_payment_capture_allowed\"[[:space:]]*:[[:space:]]*true|\"real_export_delivery_allowed\"[[:space:]]*:[[:space:]]*true|\"real_ebelge_provider_call_allowed\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "165 live policy readonly guard"
else
  pass "165 live policy readonly guard"
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
# 165 — FAZ 3-11.1 — Main Management Dashboard Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_11_1_MAIN_MANAGEMENT_DASHBOARD_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_11_1_MAIN_MANAGEMENT_DASHBOARD_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_11_10_READY=${NEXT_READY}

## Scope

- Central navigation surface
- 157 e-Belge operations link
- 158 reconciliation link
- 159 tax/KDV rule link
- 160 journal/ledger link
- 161 TDHP mapping link
- 162 payment/reconciliation link
- 163 export center link
- 164 finance summary link
- Screen readiness KPI
- Finance health KPI
- Open review KPI
- Production gate KPI
- Module detail drawer
- Gate health panel
- Audit timeline
- Evidence file traces
- Read-only dashboard policy
- Production approved FALSE

## Live Policy

- Main dashboard is read-only.
- Real ledger write: CLOSED
- Real tax rule activation: CLOSED
- Real payment capture: CLOSED
- Real export delivery: CLOSED
- Real e-Belge provider call: CLOSED
- UI actions are navigation/evidence only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 165 — FAZ 3-11.1 MAIN MANAGEMENT DASHBOARD COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_1_MAIN_MANAGEMENT_DASHBOARD_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_1_MAIN_MANAGEMENT_DASHBOARD_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_11_10_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
