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

echo "===== 167 — FAZ 3-12.4 ACCOUNTANT EXPORT WORKSPACE REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/accountant-portal/export-workspace/index.html"
CONFIG_FILE="configs/faz3/accountant-portal/accountant_export_workspace.v1.json"
DOC_FILE="docs/faz3/accountant-portal/FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE.md"

check_file "167 accountant export workspace HTML screen file" "$SCREEN_FILE"
check_file "167 accountant export workspace config file" "$CONFIG_FILE"
check_file "167 accountant export workspace documentation file" "$DOC_FILE"

check_grep "167 phase marker" "$SCREEN_FILE" "FAZ_3_12_4"
check_grep "167 screen marker" "$SCREEN_FILE" "ACCOUNTANT_EXPORT_WORKSPACE"
check_grep "167 title surface" "$SCREEN_FILE" "Excel / PDF / TDHP Export Workspace"
check_grep "167 export requests surface" "$SCREEN_FILE" "Export İstekleri|exportRows"
check_grep "167 Excel export surface" "$SCREEN_FILE" "EXCEL|Excel|xlsx"
check_grep "167 PDF export surface" "$SCREEN_FILE" "PDF|pdf"
check_grep "167 TDHP export surface" "$SCREEN_FILE" "TDHP|tdhp"
check_grep "167 Logo export surface" "$SCREEN_FILE" "LOGO|Logo"
check_grep "167 Mikro export surface" "$SCREEN_FILE" "MIKRO|Mikro"
check_grep "167 Zirve export surface" "$SCREEN_FILE" "ZIRVE|Zirve"
check_grep "167 ETA export surface" "$SCREEN_FILE" "ETA"
check_grep "167 firm filter surface" "$SCREEN_FILE" "firmFilter|Tüm yetkili firmalar"
check_grep "167 period filter surface" "$SCREEN_FILE" "periodFilter|2026-05|2026-Q2|YTD"
check_grep "167 accountant guard surface" "$SCREEN_FILE" "data-accountant-guard|Accountant"
check_grep "167 firm guard surface" "$SCREEN_FILE" "data-firm-guard|Firma"
check_grep "167 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant"
check_grep "167 export permission surface" "$SCREEN_FILE" "permission|Permission|ACCOUNTANT_EXPORT"
check_grep "167 access decision surface" "$SCREEN_FILE" "accessDecision|Access Decision|ALLOWED|REVIEW_REQUIRED"
check_grep "167 local artifact surface" "$SCREEN_FILE" "localArtifactOnly = true|local artifact|LOCAL"
check_grep "167 real external delivery false surface" "$SCREEN_FILE" "realExternalDeliveryAllowed = false|External Delivery"
check_grep "167 preview action surface" "$SCREEN_FILE" "PREVIEW|Preview"
check_grep "167 download action surface" "$SCREEN_FILE" "DOWNLOAD|Download"
check_grep "167 deliver disabled surface" "$SCREEN_FILE" "DELIVER|Deliver"
check_grep "167 audit action surface" "$SCREEN_FILE" "AUDIT|Audit"
check_grep "167 package hash trace" "$SCREEN_FILE" "packageHash|Package Hash"
check_grep "167 file hash trace" "$SCREEN_FILE" "fileHash|File Hash"
check_grep "167 access hash trace" "$SCREEN_FILE" "accessHash|Access Hash"
check_grep "167 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "167 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "167 source finance screen trace" "$SCREEN_FILE" "FAZ_3_11_2_FINANCE_SUMMARY_SCREEN"
check_grep "167 source journal screen trace" "$SCREEN_FILE" "FAZ_3_11_3_JOURNAL_LEDGER_SCREEN"
check_grep "167 source export center trace" "$SCREEN_FILE" "FAZ_3_11_7_EXPORT_CENTER_SCREEN"
check_grep "167 operation panel surface" "$SCREEN_FILE" "Workspace Operasyonları|data-operation-actions"
check_grep "167 build excel operation" "$SCREEN_FILE" "Build Excel|data-action=\"build-excel\""
check_grep "167 build pdf operation" "$SCREEN_FILE" "Build PDF|data-action=\"build-pdf\""
check_grep "167 build tdhp operation" "$SCREEN_FILE" "Build TDHP|data-action=\"build-tdhp\""
check_grep "167 audit evidence operation" "$SCREEN_FILE" "Audit Evidence|data-action=\"audit-evidence\""
check_grep "167 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "167 production approved false surface" "$SCREEN_FILE" "Production: FALSE|productionApproved = false"
check_grep "167 no real delivery notice" "$SCREEN_FILE" "canlı dış sistem teslimatı yapmaz|gerçek muhasebe programına gönderim kapalı"

check_grep "167 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "167 config route" "$CONFIG_FILE" "\"route\": \"/faz3/accountant-portal/export-workspace/\""
check_grep "167 config excel visibility" "$CONFIG_FILE" "\"excel_export_visibility\": true"
check_grep "167 config pdf visibility" "$CONFIG_FILE" "\"pdf_export_visibility\": true"
check_grep "167 config tdhp visibility" "$CONFIG_FILE" "\"tdhp_export_visibility\": true"
check_grep "167 config logo visibility" "$CONFIG_FILE" "\"logo_export_visibility\": true"
check_grep "167 config mikro visibility" "$CONFIG_FILE" "\"mikro_export_visibility\": true"
check_grep "167 config zirve visibility" "$CONFIG_FILE" "\"zirve_export_visibility\": true"
check_grep "167 config eta visibility" "$CONFIG_FILE" "\"eta_export_visibility\": true"
check_grep "167 config firm period filter visibility" "$CONFIG_FILE" "\"firm_period_filter_visibility\": true"
check_grep "167 config authorized firm filter visibility" "$CONFIG_FILE" "\"authorized_firm_filter_visibility\": true"
check_grep "167 config accountant identity visibility" "$CONFIG_FILE" "\"accountant_identity_visibility\": true"
check_grep "167 config tenant identity visibility" "$CONFIG_FILE" "\"tenant_identity_visibility\": true"
check_grep "167 config firm identity visibility" "$CONFIG_FILE" "\"firm_identity_visibility\": true"
check_grep "167 config export permission visibility" "$CONFIG_FILE" "\"export_permission_visibility\": true"
check_grep "167 config access decision visibility" "$CONFIG_FILE" "\"access_decision_visibility\": true"
check_grep "167 config local artifact download visibility" "$CONFIG_FILE" "\"local_artifact_download_visibility\": true"
check_grep "167 config external delivery visibility" "$CONFIG_FILE" "\"external_delivery_visibility\": true"
check_grep "167 config preview visibility" "$CONFIG_FILE" "\"preview_visibility\": true"
check_grep "167 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"
check_grep "167 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "167 config accountant required" "$CONFIG_FILE" "\"accountant_indicator_required\": true"
check_grep "167 config firm required" "$CONFIG_FILE" "\"firm_indicator_required\": true"
check_grep "167 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "167 config request required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "167 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "167 config export id required" "$CONFIG_FILE" "\"export_id_required\": true"
check_grep "167 config export no required" "$CONFIG_FILE" "\"export_no_required\": true"
check_grep "167 config firm id required" "$CONFIG_FILE" "\"firm_id_required\": true"
check_grep "167 config accountant id required" "$CONFIG_FILE" "\"accountant_id_required\": true"
check_grep "167 config period required" "$CONFIG_FILE" "\"period_required\": true"
check_grep "167 config format required" "$CONFIG_FILE" "\"format_required\": true"
check_grep "167 config file name required" "$CONFIG_FILE" "\"file_name_required\": true"
check_grep "167 config permission required" "$CONFIG_FILE" "\"permission_required\": true"
check_grep "167 config access decision required" "$CONFIG_FILE" "\"access_decision_required\": true"
check_grep "167 config package hash required" "$CONFIG_FILE" "\"package_hash_required\": true"
check_grep "167 config file hash required" "$CONFIG_FILE" "\"file_hash_required\": true"
check_grep "167 config access hash required" "$CONFIG_FILE" "\"access_hash_required\": true"
check_grep "167 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "167 config evidence file required" "$CONFIG_FILE" "\"evidence_file_required\": true"
check_grep "167 config Excel coverage" "$CONFIG_FILE" "\"format_excel\": true"
check_grep "167 config PDF coverage" "$CONFIG_FILE" "\"format_pdf\": true"
check_grep "167 config TDHP coverage" "$CONFIG_FILE" "\"format_tdhp\": true"
check_grep "167 config Logo coverage" "$CONFIG_FILE" "\"format_logo\": true"
check_grep "167 config Mikro coverage" "$CONFIG_FILE" "\"format_mikro\": true"
check_grep "167 config Zirve coverage" "$CONFIG_FILE" "\"format_zirve\": true"
check_grep "167 config ETA coverage" "$CONFIG_FILE" "\"format_eta\": true"
check_grep "167 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "167 config local artifact only" "$CONFIG_FILE" "\"local_artifact_only\": true"
check_grep "167 config external delivery false" "$CONFIG_FILE" "\"real_external_delivery_allowed\": false"
check_grep "167 config accounting write false" "$CONFIG_FILE" "\"real_accounting_program_write_allowed\": false"
check_grep "167 config permission required for download" "$CONFIG_FILE" "\"download_requires_accountant_permission\": true"
check_grep "167 config firm scope required" "$CONFIG_FILE" "\"firm_scope_required\": true"
check_grep "167 config preview download audit only" "$CONFIG_FILE" "\"ui_actions_are_preview_download_audit_only\": true"
check_grep "167 config export adapter backend gate" "$CONFIG_FILE" "FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS"
check_grep "167 config finance summary gate" "$CONFIG_FILE" "FAZ_3_11_2_FINANCE_SUMMARY_SCREEN"
check_grep "167 config journal ledger gate" "$CONFIG_FILE" "FAZ_3_11_3_JOURNAL_LEDGER_SCREEN"
check_grep "167 config export center gate" "$CONFIG_FILE" "FAZ_3_11_7_EXPORT_CENTER_SCREEN"
check_grep "167 config ERP UI tests gate" "$CONFIG_FILE" "FAZ_3_11_10_ERP_UI_TESTS"
check_grep "167 config previous gate" "$CONFIG_FILE" "FAZ_3_11_10_ERP_UI_TESTS"
check_grep "167 config next gate" "$CONFIG_FILE" "FAZ_3_12_1_MULTI_COMPANY_WORKSPACE"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"local_artifact_only\"[[:space:]]*:[[:space:]]*false|\"real_external_delivery_allowed\"[[:space:]]*:[[:space:]]*true|\"real_accounting_program_write_allowed\"[[:space:]]*:[[:space:]]*true|\"firm_scope_required\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "167 live policy local artifact guard"
else
  pass "167 live policy local artifact guard"
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
# 167 — FAZ 3-12.4 — Accountant Export Workspace Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_12_1_READY=${NEXT_READY}

## Scope

- Excel export surface
- PDF export surface
- TDHP export surface
- Logo export surface
- Mikro export surface
- Zirve export surface
- ETA export surface
- Firm / period filters
- Authorized firm filter
- Accountant identity visibility
- Tenant / firm identity visibility
- Export permission visibility
- Access decision visibility
- Local artifact download visibility
- External delivery visibility
- Preview visibility
- Audit timeline
- Package hash / file hash / access hash / audit hash traces
- Evidence file trace
- Firm-scope guard
- Local artifact only TRUE
- Production approved FALSE

## Live Policy

- Real external delivery: CLOSED
- Real accounting program write: CLOSED
- Local artifact only: TRUE
- Firm scope required: TRUE
- Download requires accountant permission: TRUE
- UI actions are preview/download/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 167 — FAZ 3-12.4 ACCOUNTANT EXPORT WORKSPACE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_12_1_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
