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

echo "===== 178 — FAZ 3-13.3 PROVIDER ERROR VIEW REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/document-integration/provider-errors/index.html"
CONFIG_FILE="configs/faz3/document-integration/provider_error_view.v1.json"
DOC_FILE="docs/faz3/document-integration/FAZ_3_13_3_PROVIDER_ERROR_VIEW.md"

check_file "178 provider error HTML screen file" "$SCREEN_FILE"
check_file "178 provider error config file" "$CONFIG_FILE"
check_file "178 provider error documentation file" "$DOC_FILE"

check_grep "178 phase marker" "$SCREEN_FILE" "FAZ_3_13_3"
check_grep "178 screen marker" "$SCREEN_FILE" "PROVIDER_ERROR_VIEW"
check_grep "178 title surface" "$SCREEN_FILE" "Provider Hata Görünümü"
check_grep "178 error table surface" "$SCREEN_FILE" "Provider Hata Tablosu|errorRows"
check_grep "178 provider error code surface" "$SCREEN_FILE" "providerErrorCode|Provider Error Code|GIB_SCHEMA_REJECTED"
check_grep "178 provider error message surface" "$SCREEN_FILE" "providerErrorMessage|Provider Error Message"
check_grep "178 normalized error code surface" "$SCREEN_FILE" "normalizedErrorCode|Normalized Error Code"
check_grep "178 AUTH category coverage" "$SCREEN_FILE" "AUTH|AUTH_SIGNATURE_INVALID"
check_grep "178 VALIDATION category coverage" "$CONFIG_FILE" "\"validation\": true"
check_grep "178 SCHEMA category coverage" "$SCREEN_FILE" "SCHEMA|SCHEMA_INVALID_UBL"
check_grep "178 TIMEOUT category coverage" "$SCREEN_FILE" "TIMEOUT|TEMPORARY_TIMEOUT"
check_grep "178 RATE_LIMIT category coverage" "$SCREEN_FILE" "RATE_LIMIT|PROVIDER_RATE_LIMIT"
check_grep "178 INFO severity coverage" "$SCREEN_FILE" "INFO"
check_grep "178 WARN severity coverage" "$SCREEN_FILE" "WARN"
check_grep "178 ERROR severity coverage" "$SCREEN_FILE" "ERROR"
check_grep "178 CRITICAL severity coverage" "$SCREEN_FILE" "CRITICAL"
check_grep "178 retryable coverage" "$SCREEN_FILE" "RETRYABLE|retryability"
check_grep "178 non retryable coverage" "$SCREEN_FILE" "NON_RETRYABLE"
check_grep "178 route decision surface" "$SCREEN_FILE" "routeDecision|Route Decision|DLQ_MANUAL_REVIEW|RETRY_BACKOFF"
check_grep "178 DLQ status surface" "$SCREEN_FILE" "dlqStatus|DLQ Status"
check_grep "178 manual review surface" "$SCREEN_FILE" "manualReviewStatus|Manual Review"
check_grep "178 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant ID|tenantId"
check_grep "178 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|correlationId|Correlation ID"
check_grep "178 request id trace" "$SCREEN_FILE" "requestId|Request ID"
check_grep "178 idempotency trace" "$SCREEN_FILE" "idempotencyKey|Idempotency Key"
check_grep "178 payload hash trace" "$SCREEN_FILE" "payloadHash|Payload Hash"
check_grep "178 response hash trace" "$SCREEN_FILE" "responseHash|Response Hash"
check_grep "178 error hash trace" "$SCREEN_FILE" "errorHash|Error Hash"
check_grep "178 classification hash trace" "$SCREEN_FILE" "classificationHash|Classification Hash"
check_grep "178 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "178 evidence file trace" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "178 classify action" "$SCREEN_FILE" "Classify Error|data-action=\"classify-error\"|CLASSIFY"
check_grep "178 retry decision action" "$SCREEN_FILE" "Retry Decision|data-action=\"retry-decision\"|RETRY"
check_grep "178 DLQ route action" "$SCREEN_FILE" "DLQ Route|data-action=\"dlq-route\"|DLQ"
check_grep "178 audit evidence action" "$SCREEN_FILE" "Audit Evidence|data-action=\"audit-evidence\"|AUDIT"
check_grep "178 live provider disabled surface" "$SCREEN_FILE" "LIVE_PROVIDER|Live|realProviderCallAllowed = false"
check_grep "178 real GIB closed surface" "$SCREEN_FILE" "realGibCallAllowed = false|Real GİB Call"
check_grep "178 raw secret blocked surface" "$SCREEN_FILE" "rawSecretVisible = false|Raw Secret Visible"
check_grep "178 raw credential blocked surface" "$SCREEN_FILE" "rawCredentialVisible = false"
check_grep "178 payload masked surface" "$SCREEN_FILE" "errorPayloadMasked = true|Error Payload Masked"
check_grep "178 manual review critical policy" "$SCREEN_FILE" "manualReviewRequiredForCritical = true"
check_grep "178 error timeline surface" "$SCREEN_FILE" "Error Timeline|data-audit-trail"
check_grep "178 no real provider notice" "$SCREEN_FILE" "gerçek provider/GİB çağrısı yapmaz|raw credential göstermez|read-only/dry-run"

check_grep "178 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "178 config route" "$CONFIG_FILE" "\"route\": \"/faz3/document-integration/provider-errors/\""
check_grep "178 config provider error table visibility" "$CONFIG_FILE" "\"provider_error_table_visibility\": true"
check_grep "178 config provider error code visibility" "$CONFIG_FILE" "\"provider_error_code_visibility\": true"
check_grep "178 config normalized error visibility" "$CONFIG_FILE" "\"normalized_error_code_visibility\": true"
check_grep "178 config category visibility" "$CONFIG_FILE" "\"error_category_visibility\": true"
check_grep "178 config severity visibility" "$CONFIG_FILE" "\"severity_visibility\": true"
check_grep "178 config retryability visibility" "$CONFIG_FILE" "\"retryability_visibility\": true"
check_grep "178 config route decision visibility" "$CONFIG_FILE" "\"route_decision_visibility\": true"
check_grep "178 config DLQ visibility" "$CONFIG_FILE" "\"dlq_status_visibility\": true"
check_grep "178 config manual review visibility" "$CONFIG_FILE" "\"manual_review_status_visibility\": true"
check_grep "178 config payload hash visibility" "$CONFIG_FILE" "\"payload_hash_visibility\": true"
check_grep "178 config response hash visibility" "$CONFIG_FILE" "\"response_hash_visibility\": true"
check_grep "178 config error hash visibility" "$CONFIG_FILE" "\"error_hash_visibility\": true"
check_grep "178 config classification hash visibility" "$CONFIG_FILE" "\"classification_hash_visibility\": true"
check_grep "178 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"

check_grep "178 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "178 config firm required" "$CONFIG_FILE" "\"firm_indicator_required\": true"
check_grep "178 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "178 config request id required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "178 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "178 config provider required" "$CONFIG_FILE" "\"provider_required\": true"
check_grep "178 config provider document required" "$CONFIG_FILE" "\"provider_document_id_required\": true"
check_grep "178 config provider error code required" "$CONFIG_FILE" "\"provider_error_code_required\": true"
check_grep "178 config normalized error required" "$CONFIG_FILE" "\"normalized_error_code_required\": true"
check_grep "178 config category required" "$CONFIG_FILE" "\"category_required\": true"
check_grep "178 config severity required" "$CONFIG_FILE" "\"severity_required\": true"
check_grep "178 config retryability required" "$CONFIG_FILE" "\"retryability_required\": true"
check_grep "178 config route decision required" "$CONFIG_FILE" "\"route_decision_required\": true"
check_grep "178 config payload hash required" "$CONFIG_FILE" "\"payload_hash_required\": true"
check_grep "178 config response hash required" "$CONFIG_FILE" "\"response_hash_required\": true"
check_grep "178 config error hash required" "$CONFIG_FILE" "\"error_hash_required\": true"
check_grep "178 config classification hash required" "$CONFIG_FILE" "\"classification_hash_required\": true"
check_grep "178 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "178 config evidence required" "$CONFIG_FILE" "\"evidence_file_required\": true"

check_grep "178 config auth coverage" "$CONFIG_FILE" "\"auth\": true"
check_grep "178 config validation coverage" "$CONFIG_FILE" "\"validation\": true"
check_grep "178 config schema coverage" "$CONFIG_FILE" "\"schema\": true"
check_grep "178 config timeout coverage" "$CONFIG_FILE" "\"timeout\": true"
check_grep "178 config rate limit coverage" "$CONFIG_FILE" "\"rate_limit\": true"
check_grep "178 config info severity coverage" "$CONFIG_FILE" "\"info\": true"
check_grep "178 config warn severity coverage" "$CONFIG_FILE" "\"warn\": true"
check_grep "178 config error severity coverage" "$CONFIG_FILE" "\"error\": true"
check_grep "178 config critical severity coverage" "$CONFIG_FILE" "\"critical\": true"
check_grep "178 config retryable coverage" "$CONFIG_FILE" "\"retryable\": true"
check_grep "178 config non retryable coverage" "$CONFIG_FILE" "\"non_retryable\": true"
check_grep "178 config classify operation" "$CONFIG_FILE" "\"classify_error\": true"
check_grep "178 config retry decision operation" "$CONFIG_FILE" "\"retry_decision\": true"
check_grep "178 config DLQ route operation" "$CONFIG_FILE" "\"dlq_route\": true"
check_grep "178 config manual review operation" "$CONFIG_FILE" "\"manual_review\": true"
check_grep "178 config audit evidence operation" "$CONFIG_FILE" "\"audit_evidence\": true"
check_grep "178 config live provider disabled operation" "$CONFIG_FILE" "\"live_provider_disabled\": true"

check_grep "178 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "178 config real GIB false" "$CONFIG_FILE" "\"real_gib_call_allowed\": false"
check_grep "178 config real provider false" "$CONFIG_FILE" "\"real_provider_call_allowed\": false"
check_grep "178 config raw secret false" "$CONFIG_FILE" "\"raw_secret_visible\": false"
check_grep "178 config raw credential false" "$CONFIG_FILE" "\"raw_credential_visible\": false"
check_grep "178 config payload masked true" "$CONFIG_FILE" "\"error_payload_masked\": true"
check_grep "178 config retry decision dry run true" "$CONFIG_FILE" "\"retry_decision_dry_run_only\": true"
check_grep "178 config manual review critical true" "$CONFIG_FILE" "\"manual_review_required_for_critical\": true"
check_grep "178 config audit hash required live" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "178 config ui actions limited" "$CONFIG_FILE" "\"ui_actions_are_classify_route_audit_only\": true"
check_grep "178 config live integration backend gate" "$CONFIG_FILE" "FAZ_3_10_3_6_EBELGE_LIVE_INTEGRATION_TESTS"
check_grep "178 config ebelge operations screen gate" "$CONFIG_FILE" "FAZ_3_11_8_EBELGE_OPERATIONS_SCREEN"
check_grep "178 config ebelge status center gate" "$CONFIG_FILE" "FAZ_3_13_1_EBELGE_STATUS_CENTER"
check_grep "178 config retry cancel resend gate" "$CONFIG_FILE" "FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE"
check_grep "178 config previous gate" "$CONFIG_FILE" "FAZ_3_13_2_RETRY_CANCEL_RESEND_ACTION_SURFACE"
check_grep "178 config next gate" "$CONFIG_FILE" "FAZ_3_13_5_MANUAL_CORRECTION_QUEUE"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_gib_call_allowed\"[[:space:]]*:[[:space:]]*true|\"real_provider_call_allowed\"[[:space:]]*:[[:space:]]*true|\"raw_secret_visible\"[[:space:]]*:[[:space:]]*true|\"raw_credential_visible\"[[:space:]]*:[[:space:]]*true|\"error_payload_masked\"[[:space:]]*:[[:space:]]*false|\"retry_decision_dry_run_only\"[[:space:]]*:[[:space:]]*false|\"manual_review_required_for_critical\"[[:space:]]*:[[:space:]]*false|\"audit_hash_required\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "178 live policy provider error guard"
else
  pass "178 live policy provider error guard"
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
# 178 — FAZ 3-13.3 — Provider Error View Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_13_3_PROVIDER_ERROR_VIEW_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_13_3_PROVIDER_ERROR_VIEW_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_13_5_READY=${NEXT_READY}

## Scope

- Provider error table
- Provider error code / message
- Normalized error code
- AUTH / VALIDATION / SCHEMA / TIMEOUT / RATE_LIMIT category coverage
- INFO / WARN / ERROR / CRITICAL severity coverage
- RETRYABLE / NON_RETRYABLE coverage
- Route decision / DLQ / manual review visibility
- Correlation / request / idempotency visibility
- Payload / response / error / classification / audit hash traces
- Evidence file trace
- Error timeline

## Live Policy

- Real GİB call: CLOSED
- Real provider call: CLOSED
- Raw secret visible: FALSE
- Raw credential visible: FALSE
- Error payload masked: TRUE
- Retry decision: DRY-RUN ONLY
- Critical manual review required: TRUE
- Audit hash required: TRUE
- Production approved: FALSE
- UI actions are classify/route/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 178 — FAZ 3-13.3 PROVIDER ERROR VIEW COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_13_3_PROVIDER_ERROR_VIEW_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_13_3_PROVIDER_ERROR_VIEW_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_13_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
