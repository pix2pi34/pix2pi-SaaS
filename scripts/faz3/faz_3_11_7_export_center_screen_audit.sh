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

echo "===== 163 — FAZ 3-11.7 EXPORT CENTER SCREEN REAL IMPLEMENTATION AUDIT START ====="

SCREEN_FILE="web/faz3/erp-ui/export-center/index.html"
CONFIG_FILE="configs/faz3/web/export_center_screen.v1.json"
DOC_FILE="docs/faz3/web/FAZ_3_11_7_EXPORT_CENTER_SCREEN.md"

check_file "163 export center HTML screen file" "$SCREEN_FILE"
check_file "163 export center config file" "$CONFIG_FILE"
check_file "163 export center documentation file" "$DOC_FILE"

check_grep "163 phase marker" "$SCREEN_FILE" "FAZ_3_11_7"
check_grep "163 screen marker" "$SCREEN_FILE" "EXPORT_CENTER_SCREEN"
check_grep "163 title surface" "$SCREEN_FILE" "Export Center"
check_grep "163 package queue surface" "$SCREEN_FILE" "Export Paket Kuyruğu|exportRows"
check_grep "163 Logo surface" "$SCREEN_FILE" "LOGO|Logo"
check_grep "163 Mikro surface" "$SCREEN_FILE" "MIKRO|Mikro"
check_grep "163 Zirve surface" "$SCREEN_FILE" "ZIRVE|Zirve"
check_grep "163 ETA surface" "$SCREEN_FILE" "ETA"
check_grep "163 TDHP format version surface" "$SCREEN_FILE" "TDHP_V1|LOGO_TDHP_V1|MIKRO_TDHP_V1|ZIRVE_TDHP_V1|ETA_TDHP_V1"
check_grep "163 journal file surface" "$SCREEN_FILE" "journalFile|Journal File|journal"
check_grep "163 ledger file surface" "$SCREEN_FILE" "ledgerFile|Ledger File|ledger"
check_grep "163 summary file surface" "$SCREEN_FILE" "summaryFile|Summary File|summary"
check_grep "163 journal header surface" "$SCREEN_FILE" "journalHeader|Journal Header"
check_grep "163 ledger header surface" "$SCREEN_FILE" "ledgerHeader|Ledger Header"
check_grep "163 summary balanced field surface" "$SCREEN_FILE" "summaryBalancedField|Summary Balanced Field|BALANCED=true"
check_grep "163 file count surface" "$SCREEN_FILE" "fileCount|File Count"
check_grep "163 row count surface" "$SCREEN_FILE" "rowCount|Row Count"
check_grep "163 debit total surface" "$SCREEN_FILE" "totalDebitMinor|Total Debit"
check_grep "163 credit total surface" "$SCREEN_FILE" "totalCreditMinor|Total Credit"
check_grep "163 balance surface" "$SCREEN_FILE" "balanceMinor|Balance"
check_grep "163 package hash trace" "$SCREEN_FILE" "packageHash|Package Hash"
check_grep "163 journal file hash trace" "$SCREEN_FILE" "journalFileHash|Journal File Hash"
check_grep "163 ledger file hash trace" "$SCREEN_FILE" "ledgerFileHash|Ledger File Hash"
check_grep "163 summary file hash trace" "$SCREEN_FILE" "summaryFileHash|Summary File Hash"
check_grep "163 validation matrix hash trace" "$SCREEN_FILE" "validationMatrixHash|Validation Matrix Hash"
check_grep "163 adapter test hash trace" "$SCREEN_FILE" "adapterTestHash|Adapter Test Hash"
check_grep "163 evidence file surface" "$SCREEN_FILE" "evidenceFile|Evidence File"
check_grep "163 build package surface" "$SCREEN_FILE" "BUILD|Build Package|data-action=\"build-package\""
check_grep "163 validate matrix surface" "$SCREEN_FILE" "VALIDATE|Validate Matrix|data-action=\"validate-matrix\""
check_grep "163 adapter tests surface" "$SCREEN_FILE" "Adapter Tests|adapterTestHash|data-action=\"adapter-tests\""
check_grep "163 download surface" "$SCREEN_FILE" "DOWNLOAD|Download"
check_grep "163 audit surface" "$SCREEN_FILE" "AUDIT|Audit"
check_grep "163 deliver disabled surface" "$SCREEN_FILE" "DELIVER|Deliver"
check_grep "163 ready status surface" "$SCREEN_FILE" "READY|Ready"
check_grep "163 validating status surface" "$SCREEN_FILE" "VALIDATING|Validating"
check_grep "163 review required status surface" "$SCREEN_FILE" "REVIEW_REQUIRED|Review Required"
check_grep "163 tenant guard surface" "$SCREEN_FILE" "data-tenant-guard|Tenant"
check_grep "163 correlation guard surface" "$SCREEN_FILE" "data-correlation-guard|Correlation"
check_grep "163 request id surface" "$SCREEN_FILE" "requestId|Request ID"
check_grep "163 idempotency surface" "$SCREEN_FILE" "idempotencyKey|Idempotency"
check_grep "163 filter bar surface" "$SCREEN_FILE" "searchInput|targetFilter|statusFilter|formatFilter|actionFilter"
check_grep "163 detail drawer surface" "$SCREEN_FILE" "data-detail-drawer"
check_grep "163 operation action panel" "$SCREEN_FILE" "data-operation-actions|Export Operasyonları"
check_grep "163 audit timeline surface" "$SCREEN_FILE" "Audit Timeline|data-audit-trail"
check_grep "163 production approved false surface" "$SCREEN_FILE" "productionApproved = false|Production: FALSE"
check_grep "163 real external delivery false surface" "$SCREEN_FILE" "realExternalDeliveryAllowed = false|Dış teslimat"
check_grep "163 real accounting write false surface" "$SCREEN_FILE" "realAccountingProgramWriteAllowed = false"
check_grep "163 no real delivery notice" "$SCREEN_FILE" "Gerçek muhasebe programına dosya teslimi kapalıdır|canlı dış sistem"

check_grep "163 config screen enabled" "$CONFIG_FILE" "\"screen_enabled\": true"
check_grep "163 config route" "$CONFIG_FILE" "\"route\": \"/faz3/erp-ui/export-center/\""
check_grep "163 config Logo visibility" "$CONFIG_FILE" "\"logo_export_visibility\": true"
check_grep "163 config Mikro visibility" "$CONFIG_FILE" "\"mikro_export_visibility\": true"
check_grep "163 config Zirve visibility" "$CONFIG_FILE" "\"zirve_export_visibility\": true"
check_grep "163 config ETA visibility" "$CONFIG_FILE" "\"eta_export_visibility\": true"
check_grep "163 config journal file visibility" "$CONFIG_FILE" "\"journal_file_visibility\": true"
check_grep "163 config ledger file visibility" "$CONFIG_FILE" "\"ledger_file_visibility\": true"
check_grep "163 config summary file visibility" "$CONFIG_FILE" "\"summary_file_visibility\": true"
check_grep "163 config format version visibility" "$CONFIG_FILE" "\"format_version_visibility\": true"
check_grep "163 config validation matrix visibility" "$CONFIG_FILE" "\"format_validation_matrix_visibility\": true"
check_grep "163 config adapter test visibility" "$CONFIG_FILE" "\"adapter_test_visibility\": true"
check_grep "163 config negative test visibility" "$CONFIG_FILE" "\"negative_test_visibility\": true"
check_grep "163 config tenant validation visibility" "$CONFIG_FILE" "\"tenant_scope_validation_visibility\": true"
check_grep "163 config posting hash validation visibility" "$CONFIG_FILE" "\"posting_hash_validation_visibility\": true"
check_grep "163 config package hash visibility" "$CONFIG_FILE" "\"package_hash_visibility\": true"
check_grep "163 config file hash visibility" "$CONFIG_FILE" "\"file_hash_visibility\": true"
check_grep "163 config evidence export visibility" "$CONFIG_FILE" "\"evidence_export_visibility\": true"
check_grep "163 config download visibility" "$CONFIG_FILE" "\"download_visibility\": true"
check_grep "163 config external delivery visibility" "$CONFIG_FILE" "\"external_delivery_visibility\": true"
check_grep "163 config audit timeline visibility" "$CONFIG_FILE" "\"audit_timeline_visibility\": true"
check_grep "163 config tenant required" "$CONFIG_FILE" "\"tenant_indicator_required\": true"
check_grep "163 config correlation required" "$CONFIG_FILE" "\"correlation_id_required\": true"
check_grep "163 config request required" "$CONFIG_FILE" "\"request_id_required\": true"
check_grep "163 config idempotency required" "$CONFIG_FILE" "\"idempotency_key_required\": true"
check_grep "163 config export id required" "$CONFIG_FILE" "\"export_id_required\": true"
check_grep "163 config package no required" "$CONFIG_FILE" "\"package_no_required\": true"
check_grep "163 config target system required" "$CONFIG_FILE" "\"target_system_required\": true"
check_grep "163 config format version required" "$CONFIG_FILE" "\"format_version_required\": true"
check_grep "163 config period required" "$CONFIG_FILE" "\"period_required\": true"
check_grep "163 config file count required" "$CONFIG_FILE" "\"file_count_required\": true"
check_grep "163 config row count required" "$CONFIG_FILE" "\"row_count_required\": true"
check_grep "163 config debit credit required" "$CONFIG_FILE" "\"debit_credit_total_required\": true"
check_grep "163 config balanced required" "$CONFIG_FILE" "\"balanced_total_required\": true"
check_grep "163 config journal required" "$CONFIG_FILE" "\"journal_file_required\": true"
check_grep "163 config ledger required" "$CONFIG_FILE" "\"ledger_file_required\": true"
check_grep "163 config summary required" "$CONFIG_FILE" "\"summary_file_required\": true"
check_grep "163 config package hash required" "$CONFIG_FILE" "\"package_hash_required\": true"
check_grep "163 config file hash required" "$CONFIG_FILE" "\"file_hash_required\": true"
check_grep "163 config matrix hash required" "$CONFIG_FILE" "\"validation_matrix_hash_required\": true"
check_grep "163 config adapter hash required" "$CONFIG_FILE" "\"adapter_test_hash_required\": true"
check_grep "163 config evidence required" "$CONFIG_FILE" "\"evidence_file_required\": true"
check_grep "163 config Logo coverage" "$CONFIG_FILE" "\"logo_real_format_generation\": true"
check_grep "163 config Mikro coverage" "$CONFIG_FILE" "\"mikro_real_format_generation\": true"
check_grep "163 config Zirve coverage" "$CONFIG_FILE" "\"zirve_real_format_generation\": true"
check_grep "163 config ETA coverage" "$CONFIG_FILE" "\"eta_real_format_generation\": true"
check_grep "163 config production approved false" "$CONFIG_FILE" "\"production_approved\": false"
check_grep "163 config real external delivery false" "$CONFIG_FILE" "\"real_external_delivery_allowed\": false"
check_grep "163 config accounting program write false" "$CONFIG_FILE" "\"real_accounting_program_write_allowed\": false"
check_grep "163 config local download only" "$CONFIG_FILE" "\"download_is_local_artifact_only\": true"
check_grep "163 config dry run export delivery" "$CONFIG_FILE" "\"ui_actions_are_dry_run_until_export_delivery_live_module\": true"
check_grep "163 config Logo backend gate" "$CONFIG_FILE" "FAZ_3_10_4_1_LOGO_REAL_FORMAT_GENERATION"
check_grep "163 config Mikro backend gate" "$CONFIG_FILE" "FAZ_3_10_4_2_MIKRO_REAL_FORMAT_GENERATION"
check_grep "163 config Zirve backend gate" "$CONFIG_FILE" "FAZ_3_10_4_3_ZIRVE_REAL_FORMAT_GENERATION"
check_grep "163 config ETA backend gate" "$CONFIG_FILE" "FAZ_3_10_4_4_ETA_REAL_FORMAT_GENERATION"
check_grep "163 config matrix backend gate" "$CONFIG_FILE" "FAZ_3_10_4_5_FORMAT_VALIDATION_MATRIX_RUNTIME"
check_grep "163 config adapter tests backend gate" "$CONFIG_FILE" "FAZ_3_10_4_6_EXPORT_ADAPTER_TESTS"
check_grep "163 config export smoke gate" "$CONFIG_FILE" "FAZ_3_10_8_4_EXPORT_SMOKE"
check_grep "163 config next gate" "$CONFIG_FILE" "FAZ_3_11_2_FINANCE_SUMMARY_SCREEN"

if grep -RqiE "\"production_approved\"[[:space:]]*:[[:space:]]*true|\"real_external_delivery_allowed\"[[:space:]]*:[[:space:]]*true|\"real_accounting_program_write_allowed\"[[:space:]]*:[[:space:]]*true|\"download_is_local_artifact_only\"[[:space:]]*:[[:space:]]*false" "$CONFIG_FILE"; then
  fail "163 live policy closed guard"
else
  pass "163 live policy closed guard"
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
# 163 — FAZ 3-11.7 — Export Center Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_11_7_EXPORT_CENTER_SCREEN_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_11_7_EXPORT_CENTER_SCREEN_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_11_2_READY=${NEXT_READY}

## Scope

- Logo export surface
- Mikro export surface
- Zirve export surface
- ETA export surface
- Journal / ledger / summary file surfaces
- Format version surface
- Format validation matrix surface
- Adapter test surface
- Negative test visibility
- Tenant scope validation visibility
- Posting hash validation visibility
- Package hash / file hash traces
- Evidence export surface
- Download surface
- External delivery surface
- Audit timeline
- Real external delivery CLOSED
- Real accounting program write CLOSED
- Production approved FALSE

## Live Policy

- Real accounting package delivery: CLOSED
- Real accounting program write: CLOSED
- Production approval: FALSE
- Download is local artifact only: TRUE
- UI actions are dry-run until export delivery live module
- This screen is readiness/UI evidence, not production activation.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 163 — FAZ 3-11.7 EXPORT CENTER SCREEN COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_11_7_EXPORT_CENTER_SCREEN_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_11_7_EXPORT_CENTER_SCREEN_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_11_2_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
