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

echo "===== 174 — FAZ 3-13.1 EBELGE STATUS CENTER REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/document-integration/ebelge-status-center/index.html"
CONFIG_FILE="configs/faz3/document-integration/ebelge_status_center.v1.json"
DOC_FILE="docs/faz3/document-integration/FAZ_3_13_1_EBELGE_STATUS_CENTER.md"

check_file "174 e-Belge status center HTML screen file" "$SCREEN_FILE"
check_file "174 e-Belge status center config file" "$CONFIG_FILE"
check_file "174 e-Belge status center documentation file" "$DOC_FILE"

check_grep "174 phase marker" "$SCREEN_FILE" "FAZ_3_13_1"
check_grep "174 screen marker" "$SCREEN_FILE" "EBELGE_STATUS_CENTER"
check_grep "174 title surface" "$SCREEN_FILE" "e-Belge Durum Merkezi"
check_grep "174 status table surface" "$SCREEN_FILE" "e-Belge Durum Tablosu|documentRows"
check_grep "174 e-Fatura surface" "$SCREEN_FILE" "E_FATURA|e-Fatura"
check_grep "174 e-Arsiv surface" "$SCREEN_FILE" "E_ARSIV|e-Arşiv"
check_grep "174 e-Adisyon surface" "$SCREEN_FILE" "E_ADISYON|e-Adisyon"
check_grep "174 accepted status surface" "$SCREEN_FILE" "ACCEPTED|Accepted"
check_grep "174 pending status surface" "$SCREEN_FILE" "PENDING|Pending"
check_grep "174 retry required status surface" "$SCREEN_FILE" "RETRY_REQUIRED|Retry"
check_grep "174 DLQ status surface" "$SCREEN_FILE" "DLQ|dlqStatus"
check_grep "174 canceled status surface" "$SCREEN_FILE" "CANCELED|Canceled"
check_grep "174 provider status surface" "$SCREEN_FILE" "providerStatus|Provider Status"
check_grep "174 provider document id surface" "$SCREEN_FILE" "providerDocumentId|Provider Document ID"
check_grep "174 callback status surface" "$SCREEN_FILE" "callbackStatus|Callback Status"
check_grep "174 poll status surface" "$SCREEN_FILE" "pollStatus|Poll Status"
check_grep "174 retry status surface" "$SCREEN_FILE" "retryStatus|Retry Status"
check_grep "174 cancel status surface" "$SCREEN_FILE" "cancelStatus|Cancel Status"
check_grep "174 manual review status surface" "$SCREEN_FILE" "manualReviewStatus|Manual Review"
check_grep "174 next poll surface" "$SCREEN_FILE" "nextPollAt|Next Poll At"
check_grep "174 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant ID|tenantId"
check_grep "174 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|correlationId|Correlation ID"
check_grep "174 request id trace" "$SCREEN_FILE" "requestId|Request ID"
check_grep "174 idempotency trace" "$SCREEN_FILE" "idempotencyKey|Idempotency Key"
check_grep "174 document uuid trace" "$SCREEN_FILE" "documentUuid|Document UUID"
check_grep "174 UBL hash trace" "$SCREEN_FILE" "ublHash|UBL Hash"
check_grep "174 PDF hash trace" "$SCREEN_FILE" "pdfHash|PDF Hash"
check_grep "174 payload hash trace" "$SCREEN_FILE" "payloadHash|Payload Hash"
check_grep "174 callback signature hash trace" "$SCREEN_FILE" "callbackSignatureHash|Callback Signature Hash"
check_grep "174 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "174 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "174 status check action" "$SCREEN_FILE" "Status Check|data-action=\"status-check\"|DETAIL"
check_grep "174 callback verify action" "$SCREEN_FILE" "Callback Verify|data-action=\"callback-verify\"|VERIFY"
check_grep "174 poll plan action" "$SCREEN_FILE" "Poll Plan|data-action=\"poll-plan\"|POLL"
check_grep "174 retry action surface" "$SCREEN_FILE" "RETRY|Retry"
check_grep "174 cancel action surface" "$SCREEN_FILE" "CANCEL|Cancel"
check_grep "174 resend action surface" "$SCREEN_FILE" "RESEND|Resend"
check_grep "174 manual review action" "$SCREEN_FILE" "Manual Review|data-action=\"manual-review\"|MANUAL_REVIEW"
check_grep "174 real GIB closed surface" "$SCREEN_FILE" "realGibCallAllowed = false|Real GİB: CLOSED"
check_grep "174 real provider closed surface" "$SCREEN_FILE" "realProviderCallAllowed = false|REAL_PROVIDER|Live"
check_grep "174 status poll dry-run surface" "$SCREEN_FILE" "statusPollDryRunOnly = true|Status Poll Dry Run"
check_grep "174 callback verify only surface" "$SCREEN_FILE" "callbackVerifyOnly = true|Callback Verify Only"
check_grep "174 audit timeline surface" "$SCREEN_FILE" "Status Timeline|data-audit-trail"
check_grep "174 no real provider notice" "$SCREEN_FILE" "gerçek GİB/provider çağrısı yapmaz|dry-run / evidence"

check_grep "174 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "174 config route" "$CONFIG_FILE" "\"route\": \"/faz3/document-integration/ebelge-status-center/\""
check_grep "174 config status center visibility" "$CONFIG_FILE" "\"ebelge_status_center_visibility\": true"
check_grep "174 config efatura visibility" "$CONFIG_FILE" "\"efatura_status_visibility\": true"
check_grep "174 config earsiv visibility" "$CONFIG_FILE" "\"earsiv_status_visibility\": true"
check_grep "174 config eadisyon visibility" "$CONFIG_FILE" "\"eadisyon_status_visibility\": true"
check_grep "174 config provider status visibility" "$CONFIG_FILE" "\"provider_status_visibility\": true"
check_grep "174 config provider document visibility" "$CONFIG_FILE" "\"provider_document_id_visibility\": true"
check_grep "174 config callback visibility" "$CONFIG_FILE" "\"callback_status_visibility\": true"
check_grep "174 config poll visibility" "$CONFIG_FILE" "\"poll_status_visibility\": true"
check_grep "174 config retry visibility" "$CONFIG_FILE" "\"retry_status_visibility\": true"
check_grep "174 config cancel visibility" "$CONFIG_FILE" "\"cancel_status_visibility\": true"
check_grep "174 config DLQ visibility" "$CONFIG_FILE" "\"dlq_status_visibility\": true"
check_grep "174 config manual review visibility" "$CONFIG_FILE" "\"manual_review_status_visibility\": true"
check_grep "174 config UBL hash visibility" "$CONFIG_FILE" "\"ubl_hash_visibility\": true"
check_grep "174 config PDF hash visibility" "$CONFIG_FILE" "\"pdf_hash_visibility\": true"
check_grep "174 config payload hash visibility" "$CONFIG_FILE" "\"payload_hash_visibility\": true"
check_grep "174 config callback signature hash visibility" "$CONFIG_FILE" "\"callback_signature_hash_visibility\": true"
check_grep "174 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"

check_grep "174 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "174 config firm required" "$CONFIG_FILE" "\"firm_indicator_required\": true"
check_grep "174 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "174 config request required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "174 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "174 config document id required" "$CONFIG_FILE" "\"document_id_required\": true"
check_grep "174 config document no required" "$CONFIG_FILE" "\"document_no_required\": true"
check_grep "174 config document uuid required" "$CONFIG_FILE" "\"document_uuid_required\": true"
check_grep "174 config document type required" "$CONFIG_FILE" "\"document_type_required\": true"
check_grep "174 config provider required" "$CONFIG_FILE" "\"provider_required\": true"
check_grep "174 config provider document id required" "$CONFIG_FILE" "\"provider_document_id_required\": true"
check_grep "174 config provider status required" "$CONFIG_FILE" "\"provider_status_required\": true"
check_grep "174 config callback status required" "$CONFIG_FILE" "\"callback_status_required\": true"
check_grep "174 config poll status required" "$CONFIG_FILE" "\"poll_status_required\": true"
check_grep "174 config retry status required" "$CONFIG_FILE" "\"retry_status_required\": true"
check_grep "174 config cancel status required" "$CONFIG_FILE" "\"cancel_status_required\": true"
check_grep "174 config DLQ status required" "$CONFIG_FILE" "\"dlq_status_required\": true"
check_grep "174 config manual review required" "$CONFIG_FILE" "\"manual_review_status_required\": true"
check_grep "174 config UBL hash required" "$CONFIG_FILE" "\"ubl_hash_required\": true"
check_grep "174 config PDF hash required" "$CONFIG_FILE" "\"pdf_hash_required\": true"
check_grep "174 config payload hash required" "$CONFIG_FILE" "\"payload_hash_required\": true"
check_grep "174 config callback signature hash required" "$CONFIG_FILE" "\"callback_signature_hash_required\": true"
check_grep "174 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "174 config evidence required" "$CONFIG_FILE" "\"evidence_file_required\": true"

check_grep "174 config e-fatura coverage" "$CONFIG_FILE" "\"e_fatura\": true"
check_grep "174 config e-arsiv coverage" "$CONFIG_FILE" "\"e_arsiv\": true"
check_grep "174 config e-adisyon coverage" "$CONFIG_FILE" "\"e_adisyon\": true"
check_grep "174 config accepted coverage" "$CONFIG_FILE" "\"status_accepted\": true"
check_grep "174 config pending coverage" "$CONFIG_FILE" "\"status_pending\": true"
check_grep "174 config retry required coverage" "$CONFIG_FILE" "\"status_retry_required\": true"
check_grep "174 config dlq coverage" "$CONFIG_FILE" "\"status_dlq\": true"
check_grep "174 config canceled coverage" "$CONFIG_FILE" "\"status_canceled\": true"
check_grep "174 config status check operation" "$CONFIG_FILE" "\"status_check\": true"
check_grep "174 config callback verify operation" "$CONFIG_FILE" "\"callback_verify\": true"
check_grep "174 config poll plan operation" "$CONFIG_FILE" "\"poll_plan\": true"
check_grep "174 config retry visibility operation" "$CONFIG_FILE" "\"retry_visibility\": true"
check_grep "174 config cancel visibility operation" "$CONFIG_FILE" "\"cancel_visibility\": true"
check_grep "174 config resend visibility operation" "$CONFIG_FILE" "\"resend_visibility\": true"
check_grep "174 config manual review operation" "$CONFIG_FILE" "\"manual_review\": true"
check_grep "174 config audit evidence operation" "$CONFIG_FILE" "\"audit_evidence\": true"

check_grep "174 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "174 config real GIB false" "$CONFIG_FILE" "\"real_gib_call_allowed\": false"
check_grep "174 config real provider false" "$CONFIG_FILE" "\"real_provider_call_allowed\": false"
check_grep "174 config status poll dry-run true" "$CONFIG_FILE" "\"status_poll_dry_run_only\": true"
check_grep "174 config callback verify only true" "$CONFIG_FILE" "\"callback_verify_only\": true"
check_grep "174 config retry dry-run true" "$CONFIG_FILE" "\"retry_action_dry_run_only\": true"
check_grep "174 config cancel dry-run true" "$CONFIG_FILE" "\"cancel_action_dry_run_only\": true"
check_grep "174 config resend dry-run true" "$CONFIG_FILE" "\"resend_action_dry_run_only\": true"
check_grep "174 config audit hash required live" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "174 config ui actions limited" "$CONFIG_FILE" "\"ui_actions_are_status_callback_poll_review_audit_only\": true"
check_grep "174 config live integration backend gate" "$CONFIG_FILE" "FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS"
check_grep "174 config ebelge operations screen gate" "$CONFIG_FILE" "FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN"
check_grep "174 config ERP UI tests gate" "$CONFIG_FILE" "FAZ_3_11_10_ERP_UI_TESTS"
check_grep "174 config accountant portal tests gate" "$CONFIG_FILE" "FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS"
check_grep "174 config previous gate" "$CONFIG_FILE" "FAZ_3_12_7_ACCOUNTANT_PORTAL_TESTS"
check_grep "174 config next gate" "$CONFIG_FILE" "FAZ_3_13_4_OCR_DOCUMENT_REVIEW_SCREEN"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_gib_call_allowed\"[[:space:]]*:[[:space:]]*true|\"real_provider_call_allowed\"[[:space:]]*:[[:space:]]*true|\"status_poll_dry_run_only\"[[:space:]]*:[[:space:]]*false|\"callback_verify_only\"[[:space:]]*:[[:space:]]*false|\"retry_action_dry_run_only\"[[:space:]]*:[[:space:]]*false|\"cancel_action_dry_run_only\"[[:space:]]*:[[:space:]]*false|\"resend_action_dry_run_only\"[[:space:]]*:[[:space:]]*false|\"audit_hash_required\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "174 live policy e-Belge status center guard"
else
  pass "174 live policy e-Belge status center guard"
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
# 174 — FAZ 3-13.1 — e-Belge Status Center Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_13_1_EBELGE_STATUS_CENTER_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_13_1_EBELGE_STATUS_CENTER_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_13_4_READY=${NEXT_READY}

## Scope

- e-Belge status center visibility
- e-Fatura / e-Arşiv / e-Adisyon coverage
- ACCEPTED / PENDING / RETRY_REQUIRED / DLQ / CANCELED status coverage
- Provider status / provider document id visibility
- Callback / poll / retry / cancel / DLQ / manual review visibility
- UBL hash / PDF hash / payload hash / callback signature hash / audit hash traces
- Evidence file trace
- Status timeline
- Status check / callback verify / poll plan / manual review operations

## Live Policy

- Real GİB call: CLOSED
- Real provider call: CLOSED
- Status poll: DRY-RUN ONLY
- Callback verify: VERIFY ONLY
- Retry/cancel/resend: DRY-RUN ONLY
- Audit hash required: TRUE
- Production approved: FALSE
- UI actions are status/callback/poll/review/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 174 — FAZ 3-13.1 EBELGE STATUS CENTER COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_13_1_EBELGE_STATUS_CENTER_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_13_1_EBELGE_STATUS_CENTER_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_13_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
