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

echo "===== 162 — FAZ 3-11.9 PAYMENT RECONCILIATION SCREEN REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/erp-ui/payment-reconciliation/index.html"
CONFIG_FILE="configs/faz3/web/payment_reconciliation_screen.v1.json"
DOC_FILE="docs/faz3/web/FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN.md"

check_file "162 payment reconciliation HTML screen file" "$SCREEN_FILE"
check_file "162 payment reconciliation config file" "$CONFIG_FILE"
check_file "162 payment reconciliation documentation file" "$DOC_FILE"

check_grep "162 phase marker" "$SCREEN_FILE" "FAZ_3_11_9"
check_grep "162 screen marker" "$SCREEN_FILE" "PAYMENT_RECONCILIATION_SCREEN"
check_grep "162 title surface" "$SCREEN_FILE" "Ödeme / Mutabakat Ekranı"
check_grep "162 queue surface" "$SCREEN_FILE" "Ödeme Mutabakat Kuyruğu|paymentRows"
check_grep "162 POS surface" "$SCREEN_FILE" "POS"
check_grep "162 virtual POS surface" "$SCREEN_FILE" "VIRTUAL_POS|Sanal POS"
check_grep "162 bank transfer surface" "$SCREEN_FILE" "BANK_TRANSFER|Banka transfer"
check_grep "162 bank collection surface" "$SCREEN_FILE" "BANK_COLLECTION|Banka tahsilat"
check_grep "162 marketplace settlement surface" "$SCREEN_FILE" "MARKETPLACE_SETTLEMENT|marketplaceSettlementId"
check_grep "162 authorize surface" "$SCREEN_FILE" "AUTHORIZED|Authorized"
check_grep "162 capture surface" "$SCREEN_FILE" "CAPTURED|Capture|data-op=\"CAPTURE\""
check_grep "162 refund surface" "$SCREEN_FILE" "REFUNDED|Refund|data-op=\"REFUND\""
check_grep "162 void surface" "$SCREEN_FILE" "VOID|Void|data-op=\"VOID\""
check_grep "162 retry surface" "$SCREEN_FILE" "RETRY|Retry|retryCount"
check_grep "162 DLQ surface" "$SCREEN_FILE" "DLQ"
check_grep "162 manual review surface" "$SCREEN_FILE" "MANUAL_REVIEW|Manual Review"
check_grep "162 failed status surface" "$SCREEN_FILE" "FAILED|Failed"
check_grep "162 matched reconciliation surface" "$SCREEN_FILE" "MATCHED|Matched"
check_grep "162 difference review surface" "$SCREEN_FILE" "DIFFERENCE_REVIEW|Difference Review"
check_grep "162 retry scheduled surface" "$SCREEN_FILE" "RETRY_SCHEDULED|Retry Scheduled"
check_grep "162 provider transaction surface" "$SCREEN_FILE" "providerTransactionId|Provider Transaction ID"
check_grep "162 bank reference surface" "$SCREEN_FILE" "bankReference|Bank Reference"
check_grep "162 statement line surface" "$SCREEN_FILE" "statementLineId|Statement Line ID"
check_grep "162 marketplace settlement id surface" "$SCREEN_FILE" "marketplaceSettlementId|Marketplace Settlement ID"
check_grep "162 payment transaction id surface" "$SCREEN_FILE" "paymentTransactionId|Payment Transaction ID"
check_grep "162 merchant id surface" "$SCREEN_FILE" "merchantId|Merchant ID"
check_grep "162 terminal id surface" "$SCREEN_FILE" "terminalId|Terminal ID"
check_grep "162 collection no surface" "$SCREEN_FILE" "collectionNo|Collection No"
check_grep "162 refund no surface" "$SCREEN_FILE" "refundNo|Refund No"
check_grep "162 error code surface" "$SCREEN_FILE" "errorCode|Error Code|PROVIDER_TIMEOUT"
check_grep "162 expected actual amount surface" "$SCREEN_FILE" "expectedMinor|actualMinor|Beklenen|Gerçekleşen"
check_grep "162 provider payload hash trace" "$SCREEN_FILE" "providerPayloadHash|Provider Payload Hash"
check_grep "162 statement payload hash trace" "$SCREEN_FILE" "statementPayloadHash|Statement Payload Hash"
check_grep "162 payment hash trace" "$SCREEN_FILE" "paymentHash|Payment Hash"
check_grep "162 reconciliation hash trace" "$SCREEN_FILE" "reconciliationHash|Reconciliation Hash"
check_grep "162 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "162 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant"
check_grep "162 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|Correlation"
check_grep "162 request id surface" "$SCREEN_FILE" "requestId|Request ID"
check_grep "162 idempotency surface" "$SCREEN_FILE" "idempotencyKey|Idempotency"
check_grep "162 filter bar surface" "$SCREEN_FILE" "searchInput|channelFilter|statusFilter|reconFilter|actionFilter"
check_grep "162 detail drawer surface" "$SCREEN_FILE" "data-detail-drawer"
check_grep "162 operation action panel" "$SCREEN_FILE" "data-operation-actions|Ödeme Operasyonları"
check_grep "162 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "162 real payment gate closed surface" "$SCREEN_FILE" "realPaymentGate = \"CLOSED\"|Real Payment Gate: CLOSED"
check_grep "162 real bank gate closed surface" "$SCREEN_FILE" "realBankGate = \"CLOSED\"|Real Bank Gate: CLOSED"
check_grep "162 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production: FALSE"
check_grep "162 real external false surface" "$SCREEN_FILE" "realExternalProviderCallsAllowed = false"
check_grep "162 no real external call notice" "$SCREEN_FILE" "Gerçek ödeme|gerçek banka|canlı dış sistem"

check_grep "162 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "162 config route" "$CONFIG_FILE" "\"route\": \"/faz3/erp-ui/payment-reconciliation/\""
check_grep "162 config POS visibility" "$CONFIG_FILE" "\"pos_provider_visibility\": true"
check_grep "162 config virtual POS visibility" "$CONFIG_FILE" "\"virtual_pos_visibility\": true"
check_grep "162 config bank transfer visibility" "$CONFIG_FILE" "\"bank_transfer_visibility\": true"
check_grep "162 config bank collection visibility" "$CONFIG_FILE" "\"bank_collection_visibility\": true"
check_grep "162 config marketplace settlement visibility" "$CONFIG_FILE" "\"marketplace_settlement_visibility\": true"
check_grep "162 config authorize visibility" "$CONFIG_FILE" "\"authorize_visibility\": true"
check_grep "162 config capture visibility" "$CONFIG_FILE" "\"capture_visibility\": true"
check_grep "162 config refund visibility" "$CONFIG_FILE" "\"refund_visibility\": true"
check_grep "162 config void visibility" "$CONFIG_FILE" "\"void_visibility\": true"
check_grep "162 config cancel visibility" "$CONFIG_FILE" "\"cancel_visibility\": true"
check_grep "162 config status sync visibility" "$CONFIG_FILE" "\"status_sync_visibility\": true"
check_grep "162 config retry DLQ visibility" "$CONFIG_FILE" "\"retry_dlq_visibility\": true"
check_grep "162 config manual review visibility" "$CONFIG_FILE" "\"manual_review_visibility\": true"
check_grep "162 config reconciliation visibility" "$CONFIG_FILE" "\"reconciliation_visibility\": true"
check_grep "162 config provider error visibility" "$CONFIG_FILE" "\"provider_error_visibility\": true"
check_grep "162 config bank statement visibility" "$CONFIG_FILE" "\"bank_statement_visibility\": true"
check_grep "162 config evidence export visibility" "$CONFIG_FILE" "\"evidence_export_visibility\": true"
check_grep "162 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"
check_grep "162 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "162 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "162 config request required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "162 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "162 config payment transaction required" "$CONFIG_FILE" "\"payment_transaction_id_required\": true"
check_grep "162 config provider transaction visible" "$CONFIG_FILE" "\"provider_transaction_id_visible\": true"
check_grep "162 config bank reference visible" "$CONFIG_FILE" "\"bank_reference_visible\": true"
check_grep "162 config statement line visible" "$CONFIG_FILE" "\"statement_line_id_visible\": true"
check_grep "162 config marketplace settlement visible" "$CONFIG_FILE" "\"marketplace_settlement_id_visible\": true"
check_grep "162 config merchant required" "$CONFIG_FILE" "\"merchant_id_required\": true"
check_grep "162 config terminal visible" "$CONFIG_FILE" "\"terminal_id_visible\": true"
check_grep "162 config provider payload hash required" "$CONFIG_FILE" "\"provider_payload_hash_required\": true"
check_grep "162 config statement payload hash visible" "$CONFIG_FILE" "\"statement_payload_hash_visible\": true"
check_grep "162 config payment hash required" "$CONFIG_FILE" "\"payment_hash_required\": true"
check_grep "162 config reconciliation hash required" "$CONFIG_FILE" "\"reconciliation_hash_required\": true"
check_grep "162 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "162 config retry count visible" "$CONFIG_FILE" "\"retry_count_visible\": true"
check_grep "162 config error code visible" "$CONFIG_FILE" "\"error_code_visible\": true"
check_grep "162 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "162 config real payment gate closed" "$CONFIG_FILE" "\"real_payment_gate_status\": \"CLOSED\""
check_grep "162 config real bank gate closed" "$CONFIG_FILE" "\"real_bank_gate_status\": \"CLOSED\""
check_grep "162 config real external false" "$CONFIG_FILE" "\"real_external_provider_calls_allowed\": false"
check_grep "162 config dry run provider live" "$CONFIG_FILE" "\"ui_actions_are_dry_run_until_provider_live_module\": true"
check_grep "162 config POS backend gate" "$CONFIG_FILE" "FAZ_3_10_7_1_POS_PROVIDER_RUNTIME"
check_grep "162 config bank collection backend gate" "$CONFIG_FILE" "FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME"
check_grep "162 config reconciliation backend gate" "$CONFIG_FILE" "FAZ_3_10_7_3_RECONCILIATION_RUNTIME"
check_grep "162 config refund cancel backend gate" "$CONFIG_FILE" "FAZ_3_10_7_4_REFUND_CANCEL_RUNTIME"
check_grep "162 config status sync backend gate" "$CONFIG_FILE" "FAZ_3_10_7_3_PAYMENT_STATUS_SYNC"
check_grep "162 config error retry backend gate" "$CONFIG_FILE" "FAZ_3_10_7_4_PAYMENT_ERROR_RETRY_REVERSAL_RUNTIME"
check_grep "162 config integration audit backend gate" "$CONFIG_FILE" "FAZ_3_10_7_5_INTEGRATION_AUDIT_RUNTIME"
check_grep "162 config payment integration tests gate" "$CONFIG_FILE" "FAZ_3_10_7_6_PAYMENT_INTEGRATION_TESTS"
check_grep "162 config payment smoke gate" "$CONFIG_FILE" "FAZ_3_10_8_5_PAYMENT_SMOKE"
check_grep "162 config next gate" "$CONFIG_FILE" "FAZ_3_11_7_EXPORT_CENTER_SCREEN"

if grep -RqiE "\"real_external_provider_calls_allowed\"[[:space:]]*:[[:space:]]*true|\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_payment_gate_status\"[[:space:]]*:[[:space:]]*\"OPEN\"|\"real_bank_gate_status\"[[:space:]]*:[[:space:]]*\"OPEN\"" "$CONFIG_FILE"; then
  fail "162 live policy closed guard"
else
  pass "162 live policy closed guard"
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
# 162 — FAZ 3-11.9 — Payment / Reconciliation Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_11_7_READY=${NEXT_READY}

## Scope

- POS provider surface
- Virtual POS surface
- Bank transfer surface
- Bank collection surface
- Marketplace settlement surface
- Authorize / capture / refund / void / cancel surfaces
- Status sync surface
- Retry / DLQ surface
- Manual review surface
- Payment reconciliation surface
- Provider error surface
- Bank statement surface
- Evidence export surface
- Audit timeline
- Provider transaction / bank reference / statement line / settlement id traces
- Provider payload hash / statement hash / payment hash / reconciliation hash / audit hash traces
- Real payment gate CLOSED
- Real bank gate CLOSED
- Production approved FALSE

## Live Policy

- Real payment calls: CLOSED
- Real bank calls: CLOSED
- Real external provider calls: CLOSED
- Production approval: FALSE
- UI actions are dry-run until provider-live module
- This screen is readiness/UI evidence, not production activation.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 162 — FAZ 3-11.9 PAYMENT RECONCILIATION SCREEN COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_11_7_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
