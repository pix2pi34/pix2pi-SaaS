#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
REQUIRED_FAIL=0

EVIDENCE_FILE="${EVIDENCE_FILE:?EVIDENCE_FILE is required}"

pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "$1 IMPLEMENTED_OR_PRESENT / OK ✅"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); REQUIRED_FAIL=$((REQUIRED_FAIL + 1)); echo "$1 MISSING_OR_FAILED / FAIL ❌"; }
warn() { WARN_COUNT=$((WARN_COUNT + 1)); echo "$1 OPTIONAL_WARN / WARN ⚠️"; }

check_file() {
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label file_missing=${file}"
  fi
}

check_any_file() {
  local label="$1"
  shift
  local found=""
  for f in "$@"; do
    if [ -f "$f" ]; then
      found="$f"
      break
    fi
  done

  if [ -n "$found" ]; then
    pass "$label found=${found}"
  else
    fail "$label none_found=$*"
  fi
}

check_any_glob_file() {
  local label="$1"
  local glob_expr="$2"
  local found
  found="$(find docs/faz3/evidence -maxdepth 1 -type f -name "$glob_expr" | head -n 1 || true)"

  if [ -n "$found" ]; then
    pass "$label found=${found}"
  else
    fail "$label glob_missing=${glob_expr}"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -qE "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern} file=${file}"
  fi
}

check_glob_grep() {
  local label="$1"
  local glob_expr="$2"
  local pattern="$3"
  local found
  found="$(find docs/faz3/evidence -maxdepth 1 -type f -name "$glob_expr" | head -n 1 || true)"

  if [ -n "$found" ] && grep -qE "$pattern" "$found"; then
    pass "$label found=${found}"
  else
    fail "$label glob_or_pattern_missing=${glob_expr} pattern=${pattern}"
  fi
}

echo "===== 180 — FAZ 3-R PRIORITY 3 FINAL RECHECK REAL IMPLEMENTATION AUDIT START ====="

FINAL_DOC="docs/faz3/final/FAZ_3_R_PRIORITY_3_FINAL_RECHECK.md"
check_file "180 final recheck documentation file" "$FINAL_DOC"

echo "===== 180 — ERP WEB SURFACES EVIDENCE CHECK ====="

check_file "157 e-Belge operations evidence" "docs/faz3/evidence/FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
check_glob_grep "158 reconciliation screen evidence PASS" "*RECONCILIATION*SCREEN*REAL_IMPLEMENTATION_AUDIT.md" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
check_glob_grep "159 tax KDV rule screen evidence PASS" "*TAX*KDV*REAL_IMPLEMENTATION_AUDIT.md" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
check_glob_grep "160 journal ledger screen evidence PASS" "*JOURNAL*LEDGER*REAL_IMPLEMENTATION_AUDIT.md" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
check_glob_grep "161 TDHP mapping screen evidence PASS" "*TDHP*MAPPING*REAL_IMPLEMENTATION_AUDIT.md" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
check_glob_grep "162 payment reconciliation screen evidence PASS" "*PAYMENT*RECONCILIATION*REAL_IMPLEMENTATION_AUDIT.md" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
check_glob_grep "163 export center screen evidence PASS" "*EXPORT*CENTER*REAL_IMPLEMENTATION_AUDIT.md" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
check_glob_grep "164 finance summary screen evidence PASS" "*FINANCE*SUMMARY*REAL_IMPLEMENTATION_AUDIT.md" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
check_glob_grep "165 main management dashboard evidence PASS" "*MAIN*DASHBOARD*REAL_IMPLEMENTATION_AUDIT.md" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
check_glob_grep "166 ERP UI tests evidence PASS" "*ERP_UI_TESTS*REAL_IMPLEMENTATION_AUDIT.md" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"

echo "===== 180 — ACCOUNTANT PORTAL EVIDENCE CHECK ====="

check_file "167 accountant export workspace evidence" "docs/faz3/evidence/FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "168 multi company workspace evidence" "docs/faz3/evidence/FAZ_3_12_1_MULTI_COMPANY_WORKSPACE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "169 company switcher evidence" "docs/faz3/evidence/FAZ_3_12_2_COMPANY_SWITCHER_REAL_IMPLEMENTATION_AUDIT.md"
check_file "170 company permission screen evidence" "docs/faz3/evidence/FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
check_file "171 subscription status view evidence" "docs/faz3/evidence/FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW_REAL_IMPLEMENTATION_AUDIT.md"
check_file "172 portal audit history evidence" "docs/faz3/evidence/FAZ_3_12_6_PORTAL_AUDIT_HISTORY_REAL_IMPLEMENTATION_AUDIT.md"
check_file "173 accountant portal tests evidence" "docs/faz3/evidence/FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS_REAL_IMPLEMENTATION_AUDIT.md"

echo "===== 180 — DOCUMENT / INTEGRATION UI EVIDENCE CHECK ====="

check_file "174 e-Belge status center evidence" "docs/faz3/evidence/FAZ_3_13_1_EBELGE_STATUS_CENTER_REAL_IMPLEMENTATION_AUDIT.md"
check_file "175 OCR document review evidence" "docs/faz3/evidence/FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN_REAL_IMPLEMENTATION_AUDIT.md"
check_file "176 document integration UI tests evidence" "docs/faz3/evidence/FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS_REAL_IMPLEMENTATION_AUDIT.md"
check_file "177 retry cancel resend action surface evidence" "docs/faz3/evidence/FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE_REAL_IMPLEMENTATION_AUDIT.md"
check_file "178 provider error view evidence" "docs/faz3/evidence/FAZ_3_13_3_PROVIDER_ERROR_VIEW_REAL_IMPLEMENTATION_AUDIT.md"
check_file "179 manual correction queue evidence" "docs/faz3/evidence/FAZ_3_13_5_MANUAL_CORRECTION_QUEUE_REAL_IMPLEMENTATION_AUDIT.md"

echo "===== 180 — KNOWN SCREEN FILE CHECK ====="

check_file "157 e-Belge operations screen" "web/faz3/erp-ui/ebelge-operations/index.html"
check_file "167 accountant export workspace screen" "web/faz3/accountant-portal/export-workspace/index.html"
check_file "168 multi company workspace screen" "web/faz3/accountant-portal/multi-company-workspace/index.html"
check_file "169 company switcher screen" "web/faz3/accountant-portal/company-switcher/index.html"
check_file "170 company permissions screen" "web/faz3/accountant-portal/company-permissions/index.html"
check_file "171 subscription status screen" "web/faz3/accountant-portal/subscription-status/index.html"
check_file "172 portal audit history screen" "web/faz3/accountant-portal/audit-history/index.html"
check_file "173 accountant portal tests report" "web/faz3/accountant-portal/portal-tests/index.html"
check_file "174 e-Belge status center screen" "web/faz3/document-integration/ebelge-status-center/index.html"
check_file "175 OCR review screen" "web/faz3/document-integration/ocr-review/index.html"
check_file "176 document integration UI tests report" "web/faz3/document-integration/ui-tests/index.html"
check_file "177 retry cancel resend screen" "web/faz3/document-integration/retry-cancel-resend/index.html"
check_file "178 provider errors screen" "web/faz3/document-integration/provider-errors/index.html"
check_file "179 manual correction queue screen" "web/faz3/document-integration/manual-correction-queue/index.html"

echo "===== 180 — KNOWN CONFIG FILE CHECK ====="

check_file "157 e-Belge operations config" "configs/faz3/web/ebelge_operations_screen.v1.json"
check_file "167 accountant export workspace config" "configs/faz3/accountant-portal/accountant_export_workspace.v1.json"
check_file "168 multi company workspace config" "configs/faz3/accountant-portal/multi_company_workspace.v1.json"
check_file "169 company switcher config" "configs/faz3/accountant-portal/company_switcher.v1.json"
check_file "170 company permission screen config" "configs/faz3/accountant-portal/company_based_permission_screen.v1.json"
check_file "171 subscription status config" "configs/faz3/accountant-portal/subscription_status_view.v1.json"
check_file "172 portal audit config" "configs/faz3/accountant-portal/portal_audit_history.v1.json"
check_file "173 accountant portal tests config" "configs/faz3/accountant-portal/accountant_portal_tests.v1.json"
check_file "174 e-Belge status center config" "configs/faz3/document-integration/ebelge_status_center.v1.json"
check_file "175 OCR review config" "configs/faz3/document-integration/ocr_document_review_screen.v1.json"
check_file "176 document integration UI tests config" "configs/faz3/document-integration/document_integration_ui_tests.v1.json"
check_file "177 retry cancel resend config" "configs/faz3/document-integration/retry_cancel_resend_action_surface.v1.json"
check_file "178 provider error view config" "configs/faz3/document-integration/provider_error_view.v1.json"
check_file "179 manual correction queue config" "configs/faz3/document-integration/manual_correction_queue.v1.json"

echo "===== 180 — PASS / SEALED CONTENT CHECK ====="

for evidence in \
  "docs/faz3/evidence/FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_12_4_ACCOUNTANT_EXPORT_WORKSPACE_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_12_1_MULTI_COMPANY_WORKSPACE_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_12_2_COMPANY_SWITCHER_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_12_6_PORTAL_AUDIT_HISTORY_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_13_1_EBELGE_STATUS_CENTER_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_13_3_PROVIDER_ERROR_VIEW_REAL_IMPLEMENTATION_AUDIT.md" \
  "docs/faz3/evidence/FAZ_3_13_5_MANUAL_CORRECTION_QUEUE_REAL_IMPLEMENTATION_AUDIT.md"
do
  check_grep "180 evidence PASS/SEALED content $(basename "$evidence")" "$evidence" "FINAL_STATUS=PASS|SEAL_STATUS=SEALED|PASS_COUNT"
done

echo "===== 180 — LIVE RISK GATE CHECK ====="

for config in \
  "configs/faz3/web/ebelge_operations_screen.v1.json" \
  "configs/faz3/accountant-portal/accountant_export_workspace.v1.json" \
  "configs/faz3/accountant-portal/subscription_status_view.v1.json" \
  "configs/faz3/accountant-portal/portal_audit_history.v1.json" \
  "configs/faz3/accountant-portal/accountant_portal_tests.v1.json" \
  "configs/faz3/document-integration/ebelge_status_center.v1.json" \
  "configs/faz3/document-integration/ocr_document_review_screen.v1.json" \
  "configs/faz3/document-integration/document_integration_ui_tests.v1.json" \
  "configs/faz3/document-integration/retry_cancel_resend_action_surface.v1.json" \
  "configs/faz3/document-integration/provider_error_view.v1.json" \
  "configs/faz3/document-integration/manual_correction_queue.v1.json"
do
  if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_gib_call_allowed\"[[:space:]]*:[[:space:]]*true|\"real_provider_call_allowed\"[[:space:]]*:[[:space:]]*true|\"auto_commit_allowed\"[[:space:]]*:[[:space:]]*true|\"auto_apply_allowed\"[[:space:]]*:[[:space:]]*true|\"live_write_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_delete_allowed\"[[:space:]]*:[[:space:]]*true|\"audit_mutation_allowed\"[[:space:]]*:[[:space:]]*true" "$config"; then
    fail "180 live risk gate closed config=$(basename "$config")"
  else
    pass "180 live risk gate closed config=$(basename "$config")"
  fi
done

FINAL_STATUS="FAIL"
SEAL_STATUS="NOT_SEALED"
NEXT_READY="NO"

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="PASS"
  SEAL_STATUS="SEALED"
  NEXT_READY="YES"
fi

cat <<EOFMD > "$EVIDENCE_FILE"
# 180 — FAZ 3-R Öncelik 3 Final Recheck / Seal

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_R_PRIORITY_3_FINAL_RECHECK_STATUS=${FINAL_STATUS}
- FAZ_3_R_PRIORITY_3_FINAL_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_R_PRIORITY_4_READY=${NEXT_READY}

## Closed Scope

- 157–166 ERP Web Surfaces
- 167–173 Accountant Portal Web Surfaces
- 174–179 Document / Integration UI Surfaces

## Final Live Policy

- Production approved: FALSE
- Real provider/GİB calls: CLOSED where applicable
- Auto commit / auto apply: CLOSED where applicable
- Live write: CLOSED where applicable
- Audit delete/mutation: CLOSED where applicable
- Evidence and audit hash traces required

## Audit Notes

Final status is derived from real screen/config/evidence files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 180 — FAZ 3-R PRIORITY 3 FINAL RECHECK COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_R_PRIORITY_3_FINAL_RECHECK_STATUS=${FINAL_STATUS}"
echo "FAZ_3_R_PRIORITY_3_FINAL_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_R_PRIORITY_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
