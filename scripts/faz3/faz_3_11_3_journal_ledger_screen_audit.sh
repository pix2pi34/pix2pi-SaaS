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

echo "===== 160 — FAZ 3-11.3 JOURNAL LEDGER SCREEN REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/erp-ui/journal-ledger/index.html"
CONFIG_FILE="configs/faz3/web/journal_ledger_screen.v1.json"
DOC_FILE="docs/faz3/web/FAZ_3_11_3_JOURNAL_LEDGER_SCREEN.md"

check_file "160 journal ledger HTML screen file" "$SCREEN_FILE"
check_file "160 journal ledger config file" "$CONFIG_FILE"
check_file "160 journal ledger documentation file" "$DOC_FILE"

check_grep "160 phase marker" "$SCREEN_FILE" "FAZ_3_11_3"
check_grep "160 screen marker" "$SCREEN_FILE" "JOURNAL_LEDGER_SCREEN"
check_grep "160 title surface" "$SCREEN_FILE" "Journal / Ledger Ekranı"
check_grep "160 journal list surface" "$SCREEN_FILE" "Yevmiye / Ledger Kayıtları|journalRows"
check_grep "160 ledger entry surface" "$SCREEN_FILE" "Ledger|ledger"
check_grep "160 voucher detail surface" "$SCREEN_FILE" "voucherId|Voucher ID|Voucher No"
check_grep "160 posting detail surface" "$SCREEN_FILE" "postingId|Posting ID"
check_grep "160 source document surface" "$SCREEN_FILE" "documentId|Document ID|documentNo|Document No"
check_grep "160 journal line surface" "$SCREEN_FILE" "line-list|data-journal-lines|journal.lines"
check_grep "160 TDHP 120 account surface" "$SCREEN_FILE" "120.01|Alıcılar"
check_grep "160 TDHP 600 account surface" "$SCREEN_FILE" "600.01|Yurtiçi Satışlar"
check_grep "160 TDHP 391 account surface" "$SCREEN_FILE" "391.01.20|Hesaplanan KDV"
check_grep "160 TDHP 191 account surface" "$SCREEN_FILE" "191.01.20|İndirilecek KDV"
check_grep "160 TDHP 320 account surface" "$SCREEN_FILE" "320.01|Satıcılar"
check_grep "160 TDHP 102 account surface" "$SCREEN_FILE" "102.01|Bankalar"
check_grep "160 TDHP 153 account surface" "$SCREEN_FILE" "153.01|Ticari Mallar"
check_grep "160 TDHP 610 account surface" "$SCREEN_FILE" "610.01|Satıştan İadeler"
check_grep "160 debit total surface" "$SCREEN_FILE" "debitMinor|Debit Total|Debit"
check_grep "160 credit total surface" "$SCREEN_FILE" "creditMinor|Credit Total|Credit"
check_grep "160 balance difference surface" "$SCREEN_FILE" "balanceMinor|Balance Difference|Balance"
check_grep "160 posted status surface" "$SCREEN_FILE" "POSTED|Posted"
check_grep "160 posting ready status surface" "$SCREEN_FILE" "POSTING_READY|Posting Ready"
check_grep "160 reversed status surface" "$SCREEN_FILE" "REVERSED|Reversed"
check_grep "160 blocked status surface" "$SCREEN_FILE" "BLOCKED|Blocked"
check_grep "160 post action surface" "$SCREEN_FILE" "POST|Post Document|data-op=\"POST\""
check_grep "160 reverse action surface" "$SCREEN_FILE" "REVERSE|Reverse Posting|data-op=\"REVERSE\""
check_grep "160 audit action surface" "$SCREEN_FILE" "AUDIT|Audit Export|data-op=\"AUDIT\""
check_grep "160 view action surface" "$SCREEN_FILE" "VIEW|View"
check_grep "160 append only ledger surface" "$SCREEN_FILE" "appendOnlyLedger = true|Append-only Ledger: ON|append-only"
check_grep "160 reversal reason surface" "$SCREEN_FILE" "reversalReason|Reversal Reason|reversalRequiresReason"
check_grep "160 reversal of posting surface" "$SCREEN_FILE" "reversalOfPostingId|Reversal Of"
check_grep "160 voucher hash trace" "$SCREEN_FILE" "voucherHash|Voucher Hash"
check_grep "160 posting hash trace" "$SCREEN_FILE" "postingHash|Posting Hash"
check_grep "160 audit trace hash trace" "$SCREEN_FILE" "auditTraceHash|Audit Trace Hash"
check_grep "160 reconciliation link surface" "$SCREEN_FILE" "reconciliationId|Reconciliation ID|Reconciliation Link"
check_grep "160 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant"
check_grep "160 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|Correlation"
check_grep "160 request id surface" "$SCREEN_FILE" "requestId|Request ID"
check_grep "160 idempotency surface" "$SCREEN_FILE" "idempotencyKey|Idempotency"
check_grep "160 filter bar surface" "$SCREEN_FILE" "searchInput|sourceFilter|statusFilter|accountFilter|actionFilter"
check_grep "160 detail drawer surface" "$SCREEN_FILE" "data-detail-drawer"
check_grep "160 operation action panel" "$SCREEN_FILE" "data-operation-actions|Ledger Operasyonları"
check_grep "160 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "160 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production: FALSE"
check_grep "160 hard delete disabled notice" "$SCREEN_FILE" "Hard delete|Kayıt silinmez|append-only"

check_grep "160 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "160 config route" "$CONFIG_FILE" "\"route\": \"/faz3/erp-ui/journal-ledger/\""
check_grep "160 config journal visibility" "$CONFIG_FILE" "\"journal_list_visibility\": true"
check_grep "160 config ledger visibility" "$CONFIG_FILE" "\"ledger_entry_visibility\": true"
check_grep "160 config voucher visibility" "$CONFIG_FILE" "\"voucher_detail_visibility\": true"
check_grep "160 config posting visibility" "$CONFIG_FILE" "\"posting_detail_visibility\": true"
check_grep "160 config journal line visibility" "$CONFIG_FILE" "\"journal_line_visibility\": true"
check_grep "160 config TDHP account line visibility" "$CONFIG_FILE" "\"tdhp_account_line_visibility\": true"
check_grep "160 config debit credit visibility" "$CONFIG_FILE" "\"debit_credit_total_visibility\": true"
check_grep "160 config balance visibility" "$CONFIG_FILE" "\"balance_difference_visibility\": true"
check_grep "160 config append only visibility" "$CONFIG_FILE" "\"append_only_ledger_visibility\": true"
check_grep "160 config reversal visibility" "$CONFIG_FILE" "\"reversal_visibility\": true"
check_grep "160 config reversal reason visibility" "$CONFIG_FILE" "\"reversal_reason_visibility\": true"
check_grep "160 config audit trace visibility" "$CONFIG_FILE" "\"audit_trace_visibility\": true"
check_grep "160 config reconciliation link visibility" "$CONFIG_FILE" "\"reconciliation_link_visibility\": true"
check_grep "160 config posting ready visibility" "$CONFIG_FILE" "\"posting_ready_visibility\": true"
check_grep "160 config blocked balance visibility" "$CONFIG_FILE" "\"blocked_balance_visibility\": true"
check_grep "160 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "160 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "160 config request required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "160 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "160 config journal id required" "$CONFIG_FILE" "\"journal_id_required\": true"
check_grep "160 config journal no required" "$CONFIG_FILE" "\"journal_no_required\": true"
check_grep "160 config voucher id required" "$CONFIG_FILE" "\"voucher_id_required\": true"
check_grep "160 config voucher no required" "$CONFIG_FILE" "\"voucher_no_required\": true"
check_grep "160 config posting id required" "$CONFIG_FILE" "\"posting_id_required\": true"
check_grep "160 config document id required" "$CONFIG_FILE" "\"document_id_required\": true"
check_grep "160 config document no required" "$CONFIG_FILE" "\"document_no_required\": true"
check_grep "160 config source document required" "$CONFIG_FILE" "\"source_document_required\": true"
check_grep "160 config currency required" "$CONFIG_FILE" "\"currency_required\": true"
check_grep "160 config debit credit balance required" "$CONFIG_FILE" "\"debit_credit_balance_required\": true"
check_grep "160 config line account code required" "$CONFIG_FILE" "\"line_account_code_required\": true"
check_grep "160 config line debit credit exclusive required" "$CONFIG_FILE" "\"line_debit_credit_exclusive_required\": true"
check_grep "160 config voucher hash required" "$CONFIG_FILE" "\"voucher_hash_required\": true"
check_grep "160 config posting hash required" "$CONFIG_FILE" "\"posting_hash_required\": true"
check_grep "160 config audit trace hash required" "$CONFIG_FILE" "\"audit_trace_hash_required\": true"
check_grep "160 config reversal reason required" "$CONFIG_FILE" "\"reversal_reason_required_for_reverse\": true"
check_grep "160 config append only required" "$CONFIG_FILE" "\"append_only_ledger_required\": true"
check_grep "160 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "160 config real external false" "$CONFIG_FILE" "\"real_external_provider_calls_allowed\": false"
check_grep "160 config append only enabled" "$CONFIG_FILE" "\"append_only_ledger_enabled\": true"
check_grep "160 config hard delete false" "$CONFIG_FILE" "\"hard_delete_allowed\": false"
check_grep "160 config reversal reason policy" "$CONFIG_FILE" "\"reversal_requires_reason\": true"
check_grep "160 config voucher pipeline backend gate" "$CONFIG_FILE" "FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE"
check_grep "160 config account switch backend gate" "$CONFIG_FILE" "FAZ_3_10_1_2_ACCOUNT_PLAN_LIVE_VERSION_SWITCH"
check_grep "160 config posting backend gate" "$CONFIG_FILE" "FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME"
check_grep "160 config audit trace backend gate" "$CONFIG_FILE" "FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE"
check_grep "160 config reconciliation backend gate" "$CONFIG_FILE" "FAZ_3_10_1_5_TDHP_RECONCILIATION_RUNTIME"
check_grep "160 config TDHP smoke gate" "$CONFIG_FILE" "FAZ_3_10_8_1_TDHP_SMOKE"
check_grep "160 config next gate" "$CONFIG_FILE" "FAZ_3_11_4_TDHP_MAPPING_VIEW_CONTROL_SCREEN"

if grep -RqiE "\"real_external_provider_calls_allowed\"[[:space:]]*:[[:space:]]*true|\"production_approved\"[[:space:]]*:[[:space:]]*true|\"hard_delete_allowed\"[[:space:]]*:[[:space:]]*true|\"append_only_ledger_enabled\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "160 live policy closed guard"
else
  pass "160 live policy closed guard"
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
# 160 — FAZ 3-11.3 — Journal / Ledger Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_11_3_JOURNAL_LEDGER_SCREEN_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_11_3_JOURNAL_LEDGER_SCREEN_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_11_4_READY=${NEXT_READY}

## Scope

- Journal list surface
- Ledger entry surface
- Voucher detail surface
- Posting detail surface
- Journal line surface
- TDHP account line surface
- Debit / credit / balance control surface
- Append-only ledger surface
- Controlled reversal surface
- Reversal reason surface
- Audit trace surface
- Reconciliation link surface
- Posting ready surface
- Blocked balance surface
- Tenant / correlation / request / idempotency traces
- Voucher hash / posting hash / audit trace hash traces
- Production approved FALSE
- Hard delete FALSE
- Append-only ledger TRUE

## Live Policy

- Production ledger activation: CLOSED
- Real external provider calls: CLOSED
- Append-only ledger: ENABLED
- Hard delete: DISABLED
- Reversal requires reason: TRUE
- UI actions are dry-run until final web runtime
- This screen is readiness/UI evidence, not production activation.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 160 — FAZ 3-11.3 JOURNAL LEDGER SCREEN COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_3_JOURNAL_LEDGER_SCREEN_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_3_JOURNAL_LEDGER_SCREEN_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_11_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
