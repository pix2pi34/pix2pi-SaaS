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

echo "===== 161 — FAZ 3-11.4 TDHP MAPPING VIEW CONTROL SCREEN REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/erp-ui/tdhp-mapping/index.html"
CONFIG_FILE="configs/faz3/web/tdhp_mapping_screen.v1.json"
DOC_FILE="docs/faz3/web/FAZ_3_11_4_TDHP_MAPPING_VIEW_CONTROL_SCREEN.md"

check_file "161 TDHP mapping HTML screen file" "$SCREEN_FILE"
check_file "161 TDHP mapping config file" "$CONFIG_FILE"
check_file "161 TDHP mapping documentation file" "$DOC_FILE"

check_grep "161 phase marker" "$SCREEN_FILE" "FAZ_3_11_4"
check_grep "161 screen marker" "$SCREEN_FILE" "TDHP_MAPPING_VIEW_CONTROL_SCREEN"
check_grep "161 title surface" "$SCREEN_FILE" "TDHP Mapping Görüntüleme ve Kontrol"
check_grep "161 mapping catalog surface" "$SCREEN_FILE" "TDHP Mapping Kataloğu|mappingRows"
check_grep "161 document type mapping surface" "$SCREEN_FILE" "documentType|Document Type|Belge tipi"
check_grep "161 transaction type mapping surface" "$SCREEN_FILE" "transactionType|Transaction Type|İşlem tipi"
check_grep "161 mapping code surface" "$SCREEN_FILE" "mapping.code|Mapping Code|code"
check_grep "161 account code surface" "$SCREEN_FILE" "accountCode|Account Code"
check_grep "161 account name surface" "$SCREEN_FILE" "accountName|Account Name"
check_grep "161 direction surface" "$SCREEN_FILE" "direction|Direction|DEBIT|CREDIT"
check_grep "161 active version surface" "$SCREEN_FILE" "activeMappingVersion|Active Mapping|activeVersion"
check_grep "161 effective date surface" "$SCREEN_FILE" "effectiveFrom|Effective From"
check_grep "161 account prefix guard surface" "$SCREEN_FILE" "accountPrefixGuard|Account Prefix Guard"
check_grep "161 unmapped guard surface" "$SCREEN_FILE" "unmappedGuard|Unmapped Guard|Unmapped"
check_grep "161 debit credit exclusive surface" "$SCREEN_FILE" "debitCreditExclusive|Debit/Credit Exclusive"
check_grep "161 tax related mapping surface" "$SCREEN_FILE" "taxRelated|Tax Related"
check_grep "161 posting ready surface" "$SCREEN_FILE" "postingReady|Posting Ready"
check_grep "161 voucher pipeline used surface" "$SCREEN_FILE" "voucherPipelineUsed|Voucher Pipeline Used"
check_grep "161 validation surface" "$SCREEN_FILE" "VALIDATE|Validate Mapping|data-action=\"validate-mapping\""
check_grep "161 compare version surface" "$SCREEN_FILE" "COMPARE_VERSION|Compare Version|data-action=\"compare-version\""
check_grep "161 switch version surface" "$SCREEN_FILE" "SWITCH_VERSION|Switch Version|data-action=\"switch-version\""
check_grep "161 rollback surface" "$SCREEN_FILE" "ROLLBACK|Rollback"
check_grep "161 audit export surface" "$SCREEN_FILE" "AUDIT|Export Evidence|data-action=\"export-evidence\""
check_grep "161 sales invoice mapping surface" "$SCREEN_FILE" "SALES_INVOICE|Satış faturası"
check_grep "161 purchase invoice mapping surface" "$SCREEN_FILE" "PURCHASE_INVOICE|Alış faturası"
check_grep "161 payment collection mapping surface" "$SCREEN_FILE" "PAYMENT_COLLECTION|Tahsilat"
check_grep "161 sales refund mapping surface" "$SCREEN_FILE" "SALES_REFUND|Satış iade"
check_grep "161 opening balance mapping surface" "$SCREEN_FILE" "OPENING_BALANCE|Açılış"
check_grep "161 TDHP 120 account surface" "$SCREEN_FILE" "120.01|Alıcılar"
check_grep "161 TDHP 600 account surface" "$SCREEN_FILE" "600.01|Yurtiçi Satışlar"
check_grep "161 TDHP 391 account surface" "$SCREEN_FILE" "391.01.20|Hesaplanan KDV"
check_grep "161 TDHP 191 account surface" "$SCREEN_FILE" "191.01.20|İndirilecek KDV"
check_grep "161 TDHP 320 account surface" "$SCREEN_FILE" "320.01|Satıcılar"
check_grep "161 TDHP 102 account surface" "$SCREEN_FILE" "102.01|Bankalar"
check_grep "161 TDHP 153 account surface" "$SCREEN_FILE" "153.01|Ticari Mallar"
check_grep "161 TDHP 610 account surface" "$SCREEN_FILE" "610.01|Satıştan İadeler"
check_grep "161 mapping hash trace" "$SCREEN_FILE" "mappingHash|Mapping Hash"
check_grep "161 config hash trace" "$SCREEN_FILE" "configHash|Config Hash"
check_grep "161 audit hash trace" "$SCREEN_FILE" "auditHash|Audit Hash"
check_grep "161 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant"
check_grep "161 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|Correlation"
check_grep "161 filter bar surface" "$SCREEN_FILE" "searchInput|documentFilter|accountFilter|statusFilter|directionFilter"
check_grep "161 detail drawer surface" "$SCREEN_FILE" "data-detail-drawer"
check_grep "161 operation action panel" "$SCREEN_FILE" "data-operation-actions|Mapping Operasyonları"
check_grep "161 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "161 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production: FALSE"
check_grep "161 mapping switch dry run surface" "$SCREEN_FILE" "mappingSwitchDryRun = true|dry-run/readiness"
check_grep "161 unmapped blocker surface" "$SCREEN_FILE" "UNMAPPED_BLOCKED|Unmapped Blocked|unmapped blocker"
check_grep "161 no production activation notice" "$SCREEN_FILE" "production activation değildir|dry-run"

check_grep "161 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "161 config route" "$CONFIG_FILE" "\"route\": \"/faz3/erp-ui/tdhp-mapping/\""
check_grep "161 config mapping catalog visibility" "$CONFIG_FILE" "\"mapping_catalog_visibility\": true"
check_grep "161 config document type visibility" "$CONFIG_FILE" "\"document_type_mapping_visibility\": true"
check_grep "161 config transaction type visibility" "$CONFIG_FILE" "\"transaction_type_mapping_visibility\": true"
check_grep "161 config TDHP account code visibility" "$CONFIG_FILE" "\"tdhp_account_code_visibility\": true"
check_grep "161 config account name visibility" "$CONFIG_FILE" "\"account_name_visibility\": true"
check_grep "161 config direction visibility" "$CONFIG_FILE" "\"debit_credit_direction_visibility\": true"
check_grep "161 config active version visibility" "$CONFIG_FILE" "\"active_mapping_version_visibility\": true"
check_grep "161 config account prefix guard visibility" "$CONFIG_FILE" "\"account_prefix_guard_visibility\": true"
check_grep "161 config unmapped guard visibility" "$CONFIG_FILE" "\"unmapped_guard_visibility\": true"
check_grep "161 config debit credit exclusive visibility" "$CONFIG_FILE" "\"debit_credit_exclusive_visibility\": true"
check_grep "161 config tax related visibility" "$CONFIG_FILE" "\"tax_related_mapping_visibility\": true"
check_grep "161 config posting ready visibility" "$CONFIG_FILE" "\"posting_ready_visibility\": true"
check_grep "161 config voucher pipeline visibility" "$CONFIG_FILE" "\"voucher_pipeline_mapping_visibility\": true"
check_grep "161 config validation visibility" "$CONFIG_FILE" "\"mapping_validation_visibility\": true"
check_grep "161 config version compare visibility" "$CONFIG_FILE" "\"version_compare_visibility\": true"
check_grep "161 config version switch visibility" "$CONFIG_FILE" "\"version_switch_visibility\": true"
check_grep "161 config rollback visibility" "$CONFIG_FILE" "\"rollback_visibility\": true"
check_grep "161 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"
check_grep "161 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "161 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "161 config request required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "161 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "161 config mapping id required" "$CONFIG_FILE" "\"mapping_id_required\": true"
check_grep "161 config mapping code required" "$CONFIG_FILE" "\"mapping_code_required\": true"
check_grep "161 config document type required" "$CONFIG_FILE" "\"document_type_required\": true"
check_grep "161 config transaction type required" "$CONFIG_FILE" "\"transaction_type_required\": true"
check_grep "161 config account code required" "$CONFIG_FILE" "\"account_code_required\": true"
check_grep "161 config account name required" "$CONFIG_FILE" "\"account_name_required\": true"
check_grep "161 config direction required" "$CONFIG_FILE" "\"direction_required\": true"
check_grep "161 config active version required" "$CONFIG_FILE" "\"active_version_required\": true"
check_grep "161 config effective date required" "$CONFIG_FILE" "\"effective_date_required\": true"
check_grep "161 config account prefix required" "$CONFIG_FILE" "\"account_prefix_guard_required\": true"
check_grep "161 config debit credit exclusive required" "$CONFIG_FILE" "\"debit_credit_exclusive_required\": true"
check_grep "161 config unmapped guard required" "$CONFIG_FILE" "\"unmapped_guard_required\": true"
check_grep "161 config mapping hash required" "$CONFIG_FILE" "\"mapping_hash_required\": true"
check_grep "161 config config hash required" "$CONFIG_FILE" "\"config_hash_required\": true"
check_grep "161 config audit hash required" "$CONFIG_FILE" "\"audit_hash_required\": true"
check_grep "161 config 120 coverage" "$CONFIG_FILE" "\"account_120_receivables\": true"
check_grep "161 config 600 coverage" "$CONFIG_FILE" "\"account_600_sales\": true"
check_grep "161 config 391 coverage" "$CONFIG_FILE" "\"account_391_output_kdv\": true"
check_grep "161 config 191 coverage" "$CONFIG_FILE" "\"account_191_input_kdv\": true"
check_grep "161 config 320 coverage" "$CONFIG_FILE" "\"account_320_vendors\": true"
check_grep "161 config 102 coverage" "$CONFIG_FILE" "\"account_102_banks\": true"
check_grep "161 config 153 coverage" "$CONFIG_FILE" "\"account_153_inventory\": true"
check_grep "161 config 610 coverage" "$CONFIG_FILE" "\"account_610_sales_returns\": true"
check_grep "161 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "161 config real external false" "$CONFIG_FILE" "\"real_external_provider_calls_allowed\": false"
check_grep "161 config mapping switch dry run" "$CONFIG_FILE" "\"mapping_switch_dry_run\": true"
check_grep "161 config active version approval required" "$CONFIG_FILE" "\"active_version_switch_requires_approval\": true"
check_grep "161 config unmapped blocks posting" "$CONFIG_FILE" "\"unmapped_blocks_posting\": true"
check_grep "161 config voucher pipeline backend gate" "$CONFIG_FILE" "FAZ_3_10_1_1_REAL_VOUCHER_PIPELINE"
check_grep "161 config account switch backend gate" "$CONFIG_FILE" "FAZ_3_10_1_2_ACCOUNT_PLAN_LIVE_VERSION_SWITCH"
check_grep "161 config posting backend gate" "$CONFIG_FILE" "FAZ_3_10_1_3_DOCUMENT_BASED_POSTING_RUNTIME"
check_grep "161 config audit trace backend gate" "$CONFIG_FILE" "FAZ_3_10_1_4_AUDIT_TRACE_PERSISTENCE"
check_grep "161 config TDHP smoke gate" "$CONFIG_FILE" "FAZ_3_10_8_1_TDHP_SMOKE"
check_grep "161 config next gate" "$CONFIG_FILE" "FAZ_3_11_9_PAYMENT_RECONCILIATION_SCREEN"

if grep -RqiE "\"real_external_provider_calls_allowed\"[[:space:]]*:[[:space:]]*true|\"production_approved\"[[:space:]]*:[[:space:]]*true|\"mapping_switch_dry_run\"[[:space:]]*:[[:space:]]*false|\"unmapped_blocks_posting\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "161 live policy closed guard"
else
  pass "161 live policy closed guard"
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
# 161 — FAZ 3-11.4 — TDHP Mapping View Control Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_11_4_TDHP_MAPPING_VIEW_CONTROL_SCREEN_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_11_4_TDHP_MAPPING_VIEW_CONTROL_SCREEN_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_11_9_READY=${NEXT_READY}

## Scope

- TDHP mapping catalog surface
- Document type mapping surface
- Transaction type mapping surface
- Account code / account name surface
- Debit / credit direction surface
- Active mapping version surface
- Account prefix guard surface
- Unmapped guard surface
- Debit / credit exclusive control surface
- Tax related mapping surface
- Posting ready surface
- Voucher pipeline mapping surface
- Mapping validation surface
- Version compare surface
- Version switch surface
- Rollback surface
- Audit timeline
- TDHP 120 / 600 / 391 / 191 / 320 / 102 / 153 / 610 account coverage
- Mapping hash / config hash / audit hash traces
- Production approved FALSE
- Mapping switch dry-run TRUE
- Unmapped blocks posting TRUE

## Live Policy

- Production mapping switch: CLOSED
- Real external provider calls: CLOSED
- Mapping switch dry-run: TRUE
- Active version switch requires approval: TRUE
- Unmapped mapping blocks posting: TRUE
- UI actions are dry-run until final web runtime
- This screen is readiness/UI evidence, not production activation.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 161 — FAZ 3-11.4 TDHP MAPPING VIEW CONTROL SCREEN COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_4_TDHP_MAPPING_VIEW_CONTROL_SCREEN_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_4_TDHP_MAPPING_VIEW_CONTROL_SCREEN_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_11_9_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
