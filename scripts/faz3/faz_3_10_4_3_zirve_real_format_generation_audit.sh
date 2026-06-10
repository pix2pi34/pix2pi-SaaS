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

  if [ -f "$file" ] && grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label pattern_missing=${pattern}"
  fi
}

echo "===== 137 — FAZ 3-10.4.3 ZIRVE REAL FORMAT GENERATION REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/export/zirve/zirve_real_format.go"
TEST_FILE="internal/erp/turkiye/export/zirve/zirve_real_format_test.go"
CONFIG_FILE="configs/faz3/export/zirve_real_format_generation.v1.json"
DOC_FILE="docs/faz3/export/FAZ_3_10_4_3_ZIRVE_REAL_FORMAT_GENERATION.md"

check_file "137 Zirve real format runtime file" "$RUNTIME_FILE"
check_file "137 Zirve real format test file" "$TEST_FILE"
check_file "137 Zirve real format config file" "$CONFIG_FILE"
check_file "137 Zirve real format documentation file" "$DOC_FILE"

check_grep "137 runtime constructor" "$RUNTIME_FILE" "NewZirveRealFormatRuntime"
check_grep "137 build package runtime" "$RUNTIME_FILE" "BuildPackage"
check_grep "137 validate package runtime" "$RUNTIME_FILE" "ValidatePackage"
check_grep "137 journal row builder" "$RUNTIME_FILE" "buildJournalRows"
check_grep "137 journal file builder" "$RUNTIME_FILE" "buildJournalFile"
check_grep "137 ledger file builder" "$RUNTIME_FILE" "buildLedgerFile"
check_grep "137 summary file builder" "$RUNTIME_FILE" "buildSummaryFile"

check_grep "137 export request model" "$RUNTIME_FILE" "type ZirveExportRequest"
check_grep "137 journal row model" "$RUNTIME_FILE" "type ZirveJournalRow"
check_grep "137 export file model" "$RUNTIME_FILE" "type ZirveExportFile"
check_grep "137 validation issue model" "$RUNTIME_FILE" "type ZirveValidationIssue"
check_grep "137 export package model" "$RUNTIME_FILE" "type ZirveExportPackage"

check_grep "137 target system Zirve" "$RUNTIME_FILE" "ZIRVE"
check_grep "137 format version Zirve TDHP V1" "$RUNTIME_FILE" "ZIRVE_TDHP_V1"
check_grep "137 journal file type" "$RUNTIME_FILE" "ZIRVE_JOURNAL_TXT"
check_grep "137 ledger file type" "$RUNTIME_FILE" "ZIRVE_LEDGER_TXT"
check_grep "137 summary file type" "$RUNTIME_FILE" "ZIRVE_SUMMARY_TXT"

check_grep "137 posting runtime import" "$RUNTIME_FILE" "postingruntime"
check_grep "137 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "137 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "137 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "137 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "137 export id guard" "$RUNTIME_FILE" "export_id is required"
check_grep "137 target system guard" "$RUNTIME_FILE" "target_system must be ZIRVE"
check_grep "137 format version guard" "$RUNTIME_FILE" "format_version mismatch"
check_grep "137 period guard" "$RUNTIME_FILE" "period_code is required"
check_grep "137 postings guard" "$RUNTIME_FILE" "postings are required"
check_grep "137 tenant scope guard" "$RUNTIME_FILE" "posting tenant_id mismatch"
check_grep "137 posting balanced guard" "$RUNTIME_FILE" "posting balanced is required"
check_grep "137 posting hash guard" "$RUNTIME_FILE" "posting_hash is required"
check_grep "137 audit trace guard" "$RUNTIME_FILE" "audit_trace_id is required"
check_grep "137 line debit credit exclusive guard" "$RUNTIME_FILE" "posting line cannot have both debit and credit"
check_grep "137 account prefix validation" "$RUNTIME_FILE" "accountPrefixAllowed"
check_grep "137 Turkish normalization" "$RUNTIME_FILE" "normalizeTurkishASCII"
check_grep "137 package hash builder" "$RUNTIME_FILE" "buildPackageHash"
check_grep "137 file hash builder" "$RUNTIME_FILE" "buildFileHash"

check_grep "137 journal header" "$RUNTIME_FILE" "TARIH"
check_grep "137 ledger header" "$RUNTIME_FILE" "HESAP_KODU"
check_grep "137 summary balanced field" "$RUNTIME_FILE" "BALANCED"

check_grep "137 build package test" "$TEST_FILE" "TestBuildZirvePackageReady"
check_grep "137 journal file test" "$TEST_FILE" "TestZirveJournalFileContainsExpectedRows"
check_grep "137 ledger summary test" "$TEST_FILE" "TestZirveLedgerAndSummaryFilesGenerated"
check_grep "137 invalid account prefix test" "$TEST_FILE" "TestValidatePackageRejectsInvalidAccountPrefix"
check_grep "137 tenant mismatch test" "$TEST_FILE" "TestBuildPackageRejectsTenantMismatch"
check_grep "137 unbalanced posting test" "$TEST_FILE" "TestBuildPackageRejectsUnbalancedPosting"
check_grep "137 missing posting hash test" "$TEST_FILE" "TestBuildPackageRejectsMissingPostingHash"
check_grep "137 Turkish char normalization test" "$TEST_FILE" "TestNormalizeTurkishCharacters"

check_grep "137 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "137 config target Zirve" "$CONFIG_FILE" "\"target_system\": \"ZIRVE\""
check_grep "137 config format version" "$CONFIG_FILE" "\"format_version\": \"ZIRVE_TDHP_V1\""
check_grep "137 config currency TRY" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "137 config journal file" "$CONFIG_FILE" "ZIRVE_JOURNAL_TXT"
check_grep "137 config ledger file" "$CONFIG_FILE" "ZIRVE_LEDGER_TXT"
check_grep "137 config summary file" "$CONFIG_FILE" "ZIRVE_SUMMARY_TXT"
check_grep "137 config next gate" "$CONFIG_FILE" "FAZ_3_10_4_5_FORMAT_VALIDATION_MATRIX_RUNTIME"

if go test ./internal/erp/turkiye/export/zirve; then
  pass "137 Zirve real format Go test status"
else
  fail "137 Zirve real format Go test status"
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
# 137 — FAZ 3-10.4.3 — Zirve Real Format Generation Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_4_3_ZIRVE_REAL_FORMAT_GENERATION_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_4_3_ZIRVE_REAL_FORMAT_GENERATION_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_4_5_READY=${NEXT_READY}

## Scope

- Zirve export request model
- Zirve journal row model
- Zirve export file model
- Zirve export package model
- Zirve validation issue model
- Posting entry to Zirve journal rows
- Journal TXT generation
- Ledger TXT generation
- Summary TXT generation
- Package hash generation
- File hash generation
- Tenant scope guard
- Balance guard
- Posting hash guard
- Audit trace guard
- Account prefix validation
- Turkish char normalization
- TRY currency guard

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 137 — FAZ 3-10.4.3 ZIRVE REAL FORMAT GENERATION COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_4_3_ZIRVE_REAL_FORMAT_GENERATION_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_4_3_ZIRVE_REAL_FORMAT_GENERATION_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_4_5_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
