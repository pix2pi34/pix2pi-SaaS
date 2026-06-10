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

echo "===== 177 — FAZ 3-13.2 RETRY CANCEL RESEND ACTION SURFACE REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/document-integration/retry-cancel-resend/index.html"
CONFIG_FILE="configs/faz3/document-integration/retry_cancel_resend_action_surface.v1.json"
DOC_FILE="docs/faz3/document-integration/FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE.md"

check_file "177 retry cancel resend HTML screen file" "$SCREEN_FILE"
check_file "177 retry cancel resend config file" "$CONFIG_FILE"
check_file "177 retry cancel resend documentation file" "$DOC_FILE"

check_grep "177 phase marker" "$SCREEN_FILE" "FAZ_3_13_2"
check_grep "177 screen marker" "$SCREEN_FILE" "RETRY_CANCEL_RESEND_ACTION_SURFACE"
check_grep "177 title surface" "$SCREEN_FILE" "Retry / Cancel / Resend Aksiyon Yüzeyi"
check_grep "177 action queue surface" "$SCREEN_FILE" "Aksiyon Kuyruğu|actionRows"
check_grep "177 retry action surface" "$SCREEN_FILE" "RETRY|Retry Preview|retryActionDryRunOnly"
check_grep "177 cancel action surface" "$SCREEN_FILE" "CANCEL|Cancel Preview|cancelActionDryRunOnly"
check_grep "177 resend action surface" "$SCREEN_FILE" "RESEND|Resend Preview|resendActionDryRunOnly"
check_grep "177 manual review action surface" "$SCREEN_FILE" "MANUAL_REVIEW|DLQ Review|manualReviewStatus"
check_grep "177 ready action status" "$SCREEN_FILE" "READY"
check_grep "177 waiting backoff status" "$SCREEN_FILE" "WAITING_BACKOFF"
check_grep "177 blocked status" "$SCREEN_FILE" "BLOCKED"
check_grep "177 dlq review status" "$SCREEN_FILE" "DLQ_REVIEW"
check_grep "177 e-Fatura coverage" "$SCREEN_FILE" "E_FATURA"
check_grep "177 e-Arsiv coverage" "$SCREEN_FILE" "E_ARSIV"
check_grep "177 e-Adisyon coverage" "$SCREEN_FILE" "E_ADISYON"
check_grep "177 provider document id surface" "$SCREEN_FILE" "providerDocumentId|Provider Document ID"
check_grep "177 reason code surface" "$SCREEN_FILE" "reasonCode|Reason Code"
check_grep "177 provider error code surface" "$SCREEN_FILE" "providerErrorCode|Provider Error Code"
check_grep "177 lifecycle status surface" "$SCREEN_FILE" "lifecycleStatus|Lifecycle Status"
check_grep "177 retry attempt surface" "$SCREEN_FILE" "retryAttempt|Retry Attempt"
check_grep "177 max retry surface" "$SCREEN_FILE" "maxRetry"
check_grep "177 next retry surface" "$SCREEN_FILE" "nextRetryAt|Next Retry At"
check_grep "177 backoff policy surface" "$SCREEN_FILE" "backoffPolicy|Backoff Policy"
check_grep "177 DLQ status surface" "$SCREEN_FILE" "dlqStatus|DLQ Status"
check_grep "177 manual review status surface" "$SCREEN_FILE" "manualReviewStatus|Manual Review"
check_grep "177 operator id surface" "$SCREEN_FILE" "operatorId|Operator ID"
check_grep "177 operator role surface" "$SCREEN_FILE" "operatorRole|Operator Role"
check_grep "177 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant ID|tenantId"
check_grep "177 idempotency guard surface" "$SCREEN_FILE" "data-idempotency-guard|idempotencyKey|Idempotency Key"
check_grep "177 correlation trace" "$SCREEN_FILE" "correlationId|Correlation ID"
check_grep "177 request id trace" "$SCREEN_FILE" "requestId|Request ID"
check_grep "177 request hash trace" "$SCREEN_FILE" "requestHash|Request Hash"
check_grep "177 payload hash trace" "$SCREEN_FILE" "payloadHash|Payload Hash"
check_grep "177 provider hash trace" "$SCREEN_FILE" "providerHash|Provider Hash"
check_grep "177 action hash trace" "$SCREEN_FILE" "actionHash|Action Hash"
check_grep "177 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "177 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "177 live execute disabled surface" "$SCREEN_FILE" "LIVE_EXECUTE|Live|realProviderCallAllowed = false"
check_grep "177 real GIB closed surface" "$SCREEN_FILE" "realGibCallAllowed = false|Real GİB Call"
check_grep "177 real provider closed surface" "$SCREEN_FILE" "realProviderCallAllowed = false|Real Provider: CLOSED"
check_grep "177 dry run policy surface" "$SCREEN_FILE" "dry-run/evidence|Retry Dry Run|Cancel Dry Run|Resend Dry Run"
check_grep "177 action timeline surface" "$SCREEN_FILE" "Action Timeline|data-audit-trail"
check_grep "177 no real provider notice" "$SCREEN_FILE" "gerçek provider/GİB çağrısı yapmaz|idempotency, reason code ve audit hash zorunludur"

check_grep "177 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "177 config route" "$CONFIG_FILE" "\"route\": \"/faz3/document-integration/retry-cancel-resend/\""
check_grep "177 config retry visibility" "$CONFIG_FILE" "\"retry_action_surface_visibility\": true"
check_grep "177 config cancel visibility" "$CONFIG_FILE" "\"cancel_action_surface_visibility\": true"
check_grep "177 config resend visibility" "$CONFIG_FILE" "\"resend_action_surface_visibility\": true"
check_grep "177 config manual review visibility" "$CONFIG_FILE" "\"manual_review_action_visibility\": true"
check_grep "177 config provider document visibility" "$CONFIG_FILE" "\"provider_document_id_visibility\": true"
check_grep "177 config reason code visibility" "$CONFIG_FILE" "\"reason_code_visibility\": true"
check_grep "177 config provider error visibility" "$CONFIG_FILE" "\"provider_error_code_visibility\": true"
check_grep "177 config lifecycle visibility" "$CONFIG_FILE" "\"lifecycle_status_visibility\": true"
check_grep "177 config retry attempt visibility" "$CONFIG_FILE" "\"retry_attempt_visibility\": true"
check_grep "177 config max retry visibility" "$CONFIG_FILE" "\"max_retry_visibility\": true"
check_grep "177 config next retry visibility" "$CONFIG_FILE" "\"next_retry_at_visibility\": true"
check_grep "177 config backoff visibility" "$CONFIG_FILE" "\"backoff_policy_visibility\": true"
check_grep "177 config DLQ visibility" "$CONFIG_FILE" "\"dlq_status_visibility\": true"
check_grep "177 config operator visibility" "$CONFIG_FILE" "\"operator_visibility\": true"
check_grep "177 config idempotency visibility" "$CONFIG_FILE" "\"idempotency_visibility\": true"
check_grep "177 config request hash visibility" "$CONFIG_FILE" "\"request_hash_visibility\": true"
check_grep "177 config payload hash visibility" "$CONFIG_FILE" "\"payload_hash_visibility\": true"
check_grep "177 config provider hash visibility" "$CONFIG_FILE" "\"provider_hash_visibility\": true"
check_grep "177 config action hash visibility" "$CONFIG_FILE" "\"action_hash_visibility\": true"
check_grep "177 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"

check_grep "177 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "177 config firm required" "$CONFIG_FILE" "\"firm_indicator_required\": true"
check_grep "177 config action id required" "$CONFIG_FILE" "\"action_id_required\": true"
check_grep "177 config document no required" "$CONFIG_FILE" "\"document_no_required\": true"
check_grep "177 config document type required" "$CONFIG_FILE" "\"document_type_required\": true"
check_grep "177 config provider required" "$CONFIG_FILE" "\"provider_required\": true"
check_grep "177 config provider document id required" "$CONFIG_FILE" "\"provider_document_id_required\": true"
check_grep "177 config action type required" "$CONFIG_FILE" "\"action_type_required\": true"
check_grep "177 config action status required" "$CONFIG_FILE" "\"action_status_required\": true"
check_grep "177 config reason code required" "$CONFIG_FILE" "\"reason_code_required\": true"
check_grep "177 config provider error code required" "$CONFIG_FILE" "\"provider_error_code_required\": true"
check_grep "177 config lifecycle required" "$CONFIG_FILE" "\"lifecycle_status_required\": true"
check_grep "177 config retry attempt required" "$CONFIG_FILE" "\"retry_attempt_required\": true"
check_grep "177 config max retry required" "$CONFIG_FILE" "\"max_retry_required\": true"
check_grep "177 config backoff required" "$CONFIG_FILE" "\"backoff_policy_required\": true"
check_grep "177 config DLQ required" "$CONFIG_FILE" "\"dlq_status_required\": true"
check_grep "177 config manual review required" "$CONFIG_FILE" "\"manual_review_status_required\": true"
check_grep "177 config operator id required" "$CONFIG_FILE" "\"operator_id_required\": true"
check_grep "177 config operator role required" "$CONFIG_FILE" "\"operator_role_required\": true"
check_grep "177 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "177 config request id required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "177 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "177 config request hash required" "$CONFIG_FILE" "\"request_hash_required\": true"
check_grep "177 config payload hash required" "$CONFIG_FILE" "\"payload_hash_required\": true"
check_grep "177 config provider hash required" "$CONFIG_FILE" "\"provider_hash_required\": true"
check_grep "177 config action hash required" "$CONFIG_FILE" "\"action_hash_required\": true"
check_grep "177 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "177 config evidence required" "$CONFIG_FILE" "\"evidence_file_required\": true"

check_grep "177 config e-fatura coverage" "$CONFIG_FILE" "\"e_fatura\": true"
check_grep "177 config e-arsiv coverage" "$CONFIG_FILE" "\"e_arsiv\": true"
check_grep "177 config e-adisyon coverage" "$CONFIG_FILE" "\"e_adisyon\": true"
check_grep "177 config retry coverage" "$CONFIG_FILE" "\"retry\": true"
check_grep "177 config cancel coverage" "$CONFIG_FILE" "\"cancel\": true"
check_grep "177 config resend coverage" "$CONFIG_FILE" "\"resend\": true"
check_grep "177 config manual review coverage" "$CONFIG_FILE" "\"manual_review\": true"
check_grep "177 config ready status coverage" "$CONFIG_FILE" "\"ready\": true"
check_grep "177 config waiting backoff status coverage" "$CONFIG_FILE" "\"waiting_backoff\": true"
check_grep "177 config blocked status coverage" "$CONFIG_FILE" "\"blocked\": true"
check_grep "177 config dlq review status coverage" "$CONFIG_FILE" "\"dlq_review\": true"
check_grep "177 config retry preview operation" "$CONFIG_FILE" "\"retry_preview\": true"
check_grep "177 config cancel preview operation" "$CONFIG_FILE" "\"cancel_preview\": true"
check_grep "177 config resend preview operation" "$CONFIG_FILE" "\"resend_preview\": true"
check_grep "177 config dlq review operation" "$CONFIG_FILE" "\"dlq_review\": true"
check_grep "177 config audit evidence operation" "$CONFIG_FILE" "\"audit_evidence\": true"
check_grep "177 config live execute disabled operation" "$CONFIG_FILE" "\"live_execute_disabled\": true"

check_grep "177 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "177 config real GIB false" "$CONFIG_FILE" "\"real_gib_call_allowed\": false"
check_grep "177 config real provider false" "$CONFIG_FILE" "\"real_provider_call_allowed\": false"
check_grep "177 config retry dry run true" "$CONFIG_FILE" "\"retry_action_dry_run_only\": true"
check_grep "177 config cancel dry run true" "$CONFIG_FILE" "\"cancel_action_dry_run_only\": true"
check_grep "177 config resend dry run true" "$CONFIG_FILE" "\"resend_action_dry_run_only\": true"
check_grep "177 config idempotency required live" "$CONFIG_FILE" "\"idempotency_required\": true"
check_grep "177 config reason code required live" "$CONFIG_FILE" "\"reason_code_required\": true"
check_grep "177 config audit hash required live" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "177 config ui actions limited" "$CONFIG_FILE" "\"ui_actions_are_preview_review_audit_only\": true"
check_grep "177 config live integration backend gate" "$CONFIG_FILE" "FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS"
check_grep "177 config ebelge operations screen gate" "$CONFIG_FILE" "FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN"
check_grep "177 config ebelge status center gate" "$CONFIG_FILE" "FAZ_3_13_1_EBELGE_STATUS_CENTER"
check_grep "177 config document integration UI tests gate" "$CONFIG_FILE" "FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS"
check_grep "177 config previous gate" "$CONFIG_FILE" "FAZ_3_13_6_DOCUMENT_INTEGRATION_UI_TESTS"
check_grep "177 config next gate" "$CONFIG_FILE" "FAZ_3_13_3_PROVIDER_ERROR_VIEW"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_gib_call_allowed\"[[:space:]]*:[[:space:]]*true|\"real_provider_call_allowed\"[[:space:]]*:[[:space:]]*true|\"retry_action_dry_run_only\"[[:space:]]*:[[:space:]]*false|\"cancel_action_dry_run_only\"[[:space:]]*:[[:space:]]*false|\"resend_action_dry_run_only\"[[:space:]]*:[[:space:]]*false|\"idempotency_required\"[[:space:]]*:[[:space:]]*false|\"reason_code_required\"[[:space:]]*:[[:space:]]*false|\"audit_hash_required\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "177 live policy retry cancel resend dry-run guard"
else
  pass "177 live policy retry cancel resend dry-run guard"
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
# 177 — FAZ 3-13.2 — Retry Cancel Resend Action Surface Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_13_3_READY=${NEXT_READY}

## Scope

- Retry action surface
- Cancel action surface
- Resend action surface
- Manual review action visibility
- READY / WAITING_BACKOFF / BLOCKED / DLQ_REVIEW action status coverage
- e-Fatura / e-Arşiv / e-Adisyon document type coverage
- Provider document ID / reason code / provider error code / lifecycle status visibility
- Retry attempt / max retry / next retry / backoff policy visibility
- DLQ / manual review / operator visibility
- Correlation / request / idempotency visibility
- Request hash / payload hash / provider hash / action hash / audit hash traces
- Evidence file trace
- Action timeline

## Live Policy

- Real GİB call: CLOSED
- Real provider call: CLOSED
- Retry action: DRY-RUN ONLY
- Cancel action: DRY-RUN ONLY
- Resend action: DRY-RUN ONLY
- Idempotency required: TRUE
- Reason code required: TRUE
- Audit hash required: TRUE
- Production approved: FALSE
- UI actions are preview/review/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 177 — FAZ 3-13.2 RETRY CANCEL RESEND ACTION SURFACE COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_13_3_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
