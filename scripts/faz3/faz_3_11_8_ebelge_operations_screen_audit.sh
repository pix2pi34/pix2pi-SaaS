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

echo "===== 157 — FAZ 3-11.8 EBELGE OPERATIONS SCREEN REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/erp-ui/ebelge-operations/index.html"
CONFIG_FILE="configs/faz3/web/ebelge_operations_screen.v1.json"
DOC_FILE="docs/faz3/web/FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN.md"

check_file "157 e-Belge operations HTML screen file" "$SCREEN_FILE"
check_file "157 e-Belge operations config file" "$CONFIG_FILE"
check_file "157 e-Belge operations documentation file" "$DOC_FILE"

check_grep "157 phase marker" "$SCREEN_FILE" "FAZ_3_11_8"
check_grep "157 screen marker" "$SCREEN_FILE" "EBELGE_OPERATION_SCREEN"
check_grep "157 e-Fatura surface" "$SCREEN_FILE" "e-Fatura|E_FATURA"
check_grep "157 e-Arşiv surface" "$SCREEN_FILE" "e-Arşiv|E_ARSIV"
check_grep "157 e-Adisyon surface" "$SCREEN_FILE" "e-Adisyon|E_ADISYON"
check_grep "157 operation queue surface" "$SCREEN_FILE" "Operasyon Kuyruğu"
check_grep "157 status callback surface" "$SCREEN_FILE" "CALLBACK_SYNC|callback|Callback"
check_grep "157 poll surface" "$SCREEN_FILE" "POLL|Status Poll"
check_grep "157 retry surface" "$SCREEN_FILE" "RETRY|Retry"
check_grep "157 resend surface" "$SCREEN_FILE" "RESEND|Resend"
check_grep "157 cancel surface" "$SCREEN_FILE" "CANCEL|Cancel"
check_grep "157 DLQ surface" "$SCREEN_FILE" "DLQ"
check_grep "157 manual review surface" "$SCREEN_FILE" "MANUAL_REVIEW|Manual Review|Manuel"
check_grep "157 provider error surface" "$SCREEN_FILE" "Error Code|PROVIDER_TIMEOUT|CANCEL_REASON_REQUIRED"
check_grep "157 UBL artifact surface" "$SCREEN_FILE" "DOWNLOAD_UBL|UBL"
check_grep "157 PDF artifact surface" "$SCREEN_FILE" "DOWNLOAD_PDF|PDF"
check_grep "157 artifact hash trace" "$SCREEN_FILE" "artifactHash|Artifact Hash"
check_grep "157 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "157 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "157 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant"
check_grep "157 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|Correlation"
check_grep "157 request id surface" "$SCREEN_FILE" "requestId|Request ID"
check_grep "157 idempotency surface" "$SCREEN_FILE" "idempotencyKey|Idempotency"
check_grep "157 provider document id surface" "$SCREEN_FILE" "providerDocumentId|Provider ID"
check_grep "157 filter bar surface" "$SCREEN_FILE" "searchInput|typeFilter|statusFilter|actionFilter"
check_grep "157 detail drawer surface" "$SCREEN_FILE" "data-detail-drawer"
check_grep "157 action panel surface" "$SCREEN_FILE" "data-operation-actions"
check_grep "157 real provider gate closed surface" "$SCREEN_FILE" "realProviderGate = \"CLOSED\"|Real Provider Gate: CLOSED"
check_grep "157 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production: FALSE"
check_grep "157 no real external call notice" "$SCREEN_FILE" "no-real-external-call|gerçek GİB|özel entegratör"

check_grep "157 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "157 config route" "$CONFIG_FILE" "\"route\": \"/faz3/erp-ui/ebelge-operations/\""
check_grep "157 config e-Fatura scope" "$CONFIG_FILE" "\"e_fatura_operations\": true"
check_grep "157 config e-Arşiv scope" "$CONFIG_FILE" "\"e_arsiv_operations\": true"
check_grep "157 config e-Adisyon scope" "$CONFIG_FILE" "\"e_adisyon_operations\": true"
check_grep "157 config callback visibility" "$CONFIG_FILE" "\"status_callback_visibility\": true"
check_grep "157 config poll visibility" "$CONFIG_FILE" "\"poll_visibility\": true"
check_grep "157 config retry visibility" "$CONFIG_FILE" "\"retry_visibility\": true"
check_grep "157 config cancel visibility" "$CONFIG_FILE" "\"cancel_visibility\": true"
check_grep "157 config resend visibility" "$CONFIG_FILE" "\"resend_visibility\": true"
check_grep "157 config DLQ visibility" "$CONFIG_FILE" "\"dlq_visibility\": true"
check_grep "157 config manual review visibility" "$CONFIG_FILE" "\"manual_review_visibility\": true"
check_grep "157 config provider error visibility" "$CONFIG_FILE" "\"provider_error_visibility\": true"
check_grep "157 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"
check_grep "157 config tenant indicator required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "157 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "157 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "157 config provider document required" "$CONFIG_FILE" "\"provider_document_id_required\": true"
check_grep "157 config artifact hash required" "$CONFIG_FILE" "\"artifact_hash_required\": true"
check_grep "157 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "157 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "157 config real provider gate closed" "$CONFIG_FILE" "\"real_provider_gate_status\": \"CLOSED\""
check_grep "157 config real external false" "$CONFIG_FILE" "\"real_external_provider_calls_allowed\": false"
check_grep "157 config real GIB false" "$CONFIG_FILE" "\"real_gib_call_allowed\": false"
check_grep "157 config provider live dry-run" "$CONFIG_FILE" "\"ui_actions_are_dry_run_until_provider_live_module\": true"
check_grep "157 config backend e-Fatura gate" "$CONFIG_FILE" "FAZ_3_10_3_1_E_FATURA_PROVIDER_INTEGRATION"
check_grep "157 config backend e-Arşiv gate" "$CONFIG_FILE" "FAZ_3_10_3_2_E_ARSIV_PROVIDER_INTEGRATION"
check_grep "157 config backend e-Adisyon gate" "$CONFIG_FILE" "FAZ_3_10_3_3_E_ADISYON_PROVIDER_INTEGRATION"
check_grep "157 config e-Belge smoke gate" "$CONFIG_FILE" "FAZ_3_10_8_3_EBELGE_SMOKE"
check_grep "157 config next gate" "$CONFIG_FILE" "FAZ_3_11_6_RECONCILIATION_SCREEN"

if grep -RqiE "\"real_external_provider_calls_allowed\"[[:space:]]*:[[:space:]]*true|\"real_gib_call_allowed\"[[:space:]]*:[[:space:]]*true|\"production_approved\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "157 live policy closed guard"
else
  pass "157 live policy closed guard"
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
# 157 — FAZ 3-11.8 — e-Belge Operations Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_11_6_READY=${NEXT_READY}

## Scope

- e-Fatura operation screen
- e-Arşiv operation screen
- e-Adisyon operation screen
- Status callback / poll visibility
- Retry / resend / cancel action surface
- DLQ and manual review visibility
- Provider error visibility
- UBL / PDF artifact visibility
- Tenant / correlation / request / idempotency traces
- Provider document id / artifact hash / audit hash traces
- Audit timeline
- Real provider gate CLOSED
- Production approved FALSE

## Live Policy

- Real GIB call: CLOSED
- Real special integrator call: CLOSED
- Real external provider calls: CLOSED
- UI actions are dry-run until provider-live module
- This screen is readiness/UI evidence, not production activation.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 157 — FAZ 3-11.8 EBELGE OPERATIONS SCREEN COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_11_6_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
