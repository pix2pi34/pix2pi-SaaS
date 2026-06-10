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

echo "===== 158 — FAZ 3-11.6 RECONCILIATION SCREEN REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/erp-ui/reconciliation/index.html"
CONFIG_FILE="configs/faz3/web/reconciliation_screen.v1.json"
DOC_FILE="docs/faz3/web/FAZ_3_11_6_RECONCILIATION_SCREEN.md"

check_file "158 reconciliation HTML screen file" "$SCREEN_FILE"
check_file "158 reconciliation config file" "$CONFIG_FILE"
check_file "158 reconciliation documentation file" "$DOC_FILE"

check_grep "158 phase marker" "$SCREEN_FILE" "FAZ_3_11_6"
check_grep "158 screen marker" "$SCREEN_FILE" "RECONCILIATION_SCREEN"
check_grep "158 reconciliation title" "$SCREEN_FILE" "Reconciliation Ekranı"
check_grep "158 queue surface" "$SCREEN_FILE" "Mutabakat Kuyruğu"
check_grep "158 TDHP surface" "$SCREEN_FILE" "TDHP"
check_grep "158 payment surface" "$SCREEN_FILE" "PAYMENT|Ödeme"
check_grep "158 bank surface" "$SCREEN_FILE" "BANK|Banka|bankReference"
check_grep "158 marketplace surface" "$SCREEN_FILE" "MARKETPLACE|marketplaceSettlementId"
check_grep "158 export surface" "$SCREEN_FILE" "EXPORT|Export"
check_grep "158 matched status surface" "$SCREEN_FILE" "MATCHED|Matched"
check_grep "158 difference review surface" "$SCREEN_FILE" "DIFFERENCE_REVIEW|Difference Review"
check_grep "158 pending status surface" "$SCREEN_FILE" "PENDING|Pending"
check_grep "158 blocked status surface" "$SCREEN_FILE" "BLOCKED|Blocked"
check_grep "158 auto close surface" "$SCREEN_FILE" "AUTO_CLOSE|Auto Close"
check_grep "158 manual review surface" "$SCREEN_FILE" "MANUAL_REVIEW|Manual Review"
check_grep "158 block closure surface" "$SCREEN_FILE" "BLOCK_CLOSURE|Block Closure"
check_grep "158 evidence export surface" "$SCREEN_FILE" "EXPORT_EVIDENCE|Export Evidence"
check_grep "158 ledger ready surface" "$SCREEN_FILE" "ledgerReady|Ledger Ready|Ledger ready"
check_grep "158 payment closure surface" "$SCREEN_FILE" "paymentClosureReady|Payment Closure Ready|Payment closure"
check_grep "158 expected actual amount surface" "$SCREEN_FILE" "expectedMinor|actualMinor|Beklenen|Gerçekleşen"
check_grep "158 difference amount surface" "$SCREEN_FILE" "diffMinor|Difference|Fark"
check_grep "158 document id surface" "$SCREEN_FILE" "documentId|Document ID"
check_grep "158 voucher id surface" "$SCREEN_FILE" "voucherId|Voucher ID"
check_grep "158 posting id surface" "$SCREEN_FILE" "postingId|Posting ID"
check_grep "158 provider transaction surface" "$SCREEN_FILE" "providerTransactionId|Provider Transaction"
check_grep "158 bank reference surface" "$SCREEN_FILE" "bankReference|Bank Reference"
check_grep "158 statement line surface" "$SCREEN_FILE" "statementLineId|Statement Line"
check_grep "158 marketplace settlement surface" "$SCREEN_FILE" "marketplaceSettlementId|Marketplace Settlement"
check_grep "158 posting hash trace" "$SCREEN_FILE" "postingHash|Posting Hash"
check_grep "158 audit trace hash trace" "$SCREEN_FILE" "auditTraceHash|Audit Trace Hash"
check_grep "158 reconciliation hash trace" "$SCREEN_FILE" "reconciliationHash|Reconciliation Hash"
check_grep "158 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant"
check_grep "158 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|Correlation"
check_grep "158 filter bar surface" "$SCREEN_FILE" "searchInput|scopeFilter|statusFilter|decisionFilter|riskFilter"
check_grep "158 detail drawer surface" "$SCREEN_FILE" "data-detail-drawer"
check_grep "158 action panel surface" "$SCREEN_FILE" "data-operation-actions"
check_grep "158 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "158 real bank gate closed surface" "$SCREEN_FILE" "realBankGate = \"CLOSED\"|Real Bank Gate: CLOSED"
check_grep "158 real provider gate closed surface" "$SCREEN_FILE" "realProviderGate = \"CLOSED\""
check_grep "158 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production: FALSE"
check_grep "158 no real external call notice" "$SCREEN_FILE" "no-real-bank-or-provider-call|Gerçek banka|provider çağrıları kapalı"

check_grep "158 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "158 config route" "$CONFIG_FILE" "\"route\": \"/faz3/erp-ui/reconciliation/\""
check_grep "158 config TDHP visibility" "$CONFIG_FILE" "\"tdhp_reconciliation_visibility\": true"
check_grep "158 config payment visibility" "$CONFIG_FILE" "\"payment_reconciliation_visibility\": true"
check_grep "158 config bank visibility" "$CONFIG_FILE" "\"bank_statement_reconciliation_visibility\": true"
check_grep "158 config marketplace visibility" "$CONFIG_FILE" "\"marketplace_settlement_reconciliation_visibility\": true"
check_grep "158 config export visibility" "$CONFIG_FILE" "\"export_reconciliation_visibility\": true"
check_grep "158 config difference review visibility" "$CONFIG_FILE" "\"difference_review_visibility\": true"
check_grep "158 config manual review visibility" "$CONFIG_FILE" "\"manual_review_visibility\": true"
check_grep "158 config closure block visibility" "$CONFIG_FILE" "\"closure_block_visibility\": true"
check_grep "158 config ledger readiness visibility" "$CONFIG_FILE" "\"ledger_posting_readiness_visibility\": true"
check_grep "158 config payment closure visibility" "$CONFIG_FILE" "\"payment_closure_readiness_visibility\": true"
check_grep "158 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"
check_grep "158 config evidence export visibility" "$CONFIG_FILE" "\"evidence_export_visibility\": true"
check_grep "158 config tenant indicator required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "158 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "158 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "158 config document required" "$CONFIG_FILE" "\"document_id_required\": true"
check_grep "158 config voucher required" "$CONFIG_FILE" "\"voucher_id_required\": true"
check_grep "158 config posting required" "$CONFIG_FILE" "\"posting_id_required\": true"
check_grep "158 config provider transaction visible" "$CONFIG_FILE" "\"provider_transaction_id_visible\": true"
check_grep "158 config bank reference visible" "$CONFIG_FILE" "\"bank_reference_visible\": true"
check_grep "158 config statement line visible" "$CONFIG_FILE" "\"statement_line_id_visible\": true"
check_grep "158 config marketplace settlement visible" "$CONFIG_FILE" "\"marketplace_settlement_id_visible\": true"
check_grep "158 config posting hash required" "$CONFIG_FILE" "\"posting_hash_required\": true"
check_grep "158 config audit trace hash required" "$CONFIG_FILE" "\"audit_trace_hash_required\": true"
check_grep "158 config reconciliation hash required" "$CONFIG_FILE" "\"reconciliation_hash_required\": true"
check_grep "158 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "158 config real bank gate closed" "$CONFIG_FILE" "\"real_bank_gate_status\": \"CLOSED\""
check_grep "158 config real payment gate closed" "$CONFIG_FILE" "\"real_payment_gate_status\": \"CLOSED\""
check_grep "158 config real provider gate closed" "$CONFIG_FILE" "\"real_provider_gate_status\": \"CLOSED\""
check_grep "158 config real external false" "$CONFIG_FILE" "\"real_external_provider_calls_allowed\": false"
check_grep "158 config TDHP backend gate" "$CONFIG_FILE" "FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME"
check_grep "158 config payment backend gate" "$CONFIG_FILE" "FAZ_3_10_7_3_RECONCILIATION_RUNTIME"
check_grep "158 config bank backend gate" "$CONFIG_FILE" "FAZ_3_10_7_2_BANK_COLLECTION_RUNTIME"
check_grep "158 config TDHP smoke gate" "$CONFIG_FILE" "FAZ_3_10_8_1_TDHP_SMOKE"
check_grep "158 config payment smoke gate" "$CONFIG_FILE" "FAZ_3_10_8_5_PAYMENT_SMOKE"
check_grep "158 config next gate" "$CONFIG_FILE" "FAZ_3_11_5_TAX_KDV_RULE_SCREEN"

if grep -RqiE "\"real_external_provider_calls_allowed\"[[:space:]]*:[[:space:]]*true|\"real_bank_gate_status\"[[:space:]]*:[[:space:]]*\"OPEN\"|\"real_payment_gate_status\"[[:space:]]*:[[:space:]]*\"OPEN\"|\"production_approved\"[[:space:]]*:[[:space:]]*true" "$CONFIG_FILE"; then
  fail "158 live policy closed guard"
else
  pass "158 live policy closed guard"
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
# 158 — FAZ 3-11.6 — Reconciliation Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_11_6_RECONCILIATION_SCREEN_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_11_6_RECONCILIATION_SCREEN_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_11_5_READY=${NEXT_READY}

## Scope

- TDHP reconciliation surface
- Payment reconciliation surface
- Bank statement reconciliation surface
- Marketplace settlement reconciliation surface
- Export reconciliation surface
- Difference review surface
- Manual review surface
- Closure block surface
- Ledger posting readiness surface
- Payment closure readiness surface
- Evidence export surface
- Tenant / correlation / request / idempotency traces
- Document / voucher / posting / provider / bank / statement / settlement traces
- Posting hash / audit trace hash / reconciliation hash traces
- Audit timeline
- Real bank/payment/provider gate CLOSED
- Production approved FALSE

## Live Policy

- Real bank calls: CLOSED
- Real payment calls: CLOSED
- Real provider calls: CLOSED
- Real external provider calls: CLOSED
- UI actions are dry-run until provider-live module
- This screen is readiness/UI evidence, not production activation.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 158 — FAZ 3-11.6 RECONCILIATION SCREEN COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_6_RECONCILIATION_SCREEN_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_6_RECONCILIATION_SCREEN_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_11_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
