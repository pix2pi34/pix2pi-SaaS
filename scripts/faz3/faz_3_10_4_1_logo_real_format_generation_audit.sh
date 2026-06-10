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

echo "===== 135 — FAZ 3-10.4.1 LOGO REAL FORMAT GENERATION REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/export/logo/logo_real_format.go"
TEST_FILE="internal/erp/turkiye/export/logo/logo_real_format_test.go"
CONFIG_FILE="configs/faz3/export/logo_real_format_generation.v1.json"
DOC_FILE="docs/faz3/export/FAZ_3_10_4_1_LOGO_REAL_FORMAT_GENERATION.md"

check_file "135 Logo real format runtime file" "$RUNTIME_FILE"
check_file "135 Logo real format test file" "$TEST_FILE"
check_file "135 Logo real format config file" "$CONFIG_FILE"
check_file "135 Logo real format documentation file" "$DOC_FILE"

check_grep "135 runtime constructor" "$RUNTIME_FILE" "NewLogoRealFormatRuntime"
check_grep "135 build package runtime" "$RUNTIME_FILE" "BuildPackage"
check_grep "135 validate package runtime" "$RUNTIME_FILE" "ValidatePackage"
check_grep "135 journal row builder" "$RUNTIME_FILE" "buildJournalRows"
check_grep "135 journal file builder" "$RUNTIME_FILE" "buildJournalFile"
check_grep "135 ledger file builder" "$RUNTIME_FILE" "buildLedgerFile"
check_grep "135 summary file builder" "$RUNTIME_FILE" "buildSummaryFile"

check_grep "135 export request model" "$RUNTIME_FILE" "type LogoExportRequest"
check_grep "135 journal row model" "$RUNTIME_FILE" "type LogoJournalRow"
check_grep "135 export file model" "$RUNTIME_FILE" "type LogoExportFile"
check_grep "135 validation issue model" "$RUNTIME_FILE" "type LogoValidationIssue"
check_grep "135 export package model" "$RUNTIME_FILE" "type LogoExportPackage"

check_grep "135 target system Logo" "$RUNTIME_FILE" "LOGO"
check_grep "135 format version Logo TDHP V1" "$RUNTIME_FILE" "LOGO_TDHP_V1"
check_grep "135 journal file type" "$RUNTIME_FILE" "LOGO_JOURNAL_CSV"
check_grep "135 ledger file type" "$RUNTIME_FILE" "LOGO_LEDGER_CSV"
check_grep "135 summary file type" "$RUNTIME_FILE" "LOGO_SUMMARY_TXT"

check_grep "135 posting runtime import" "$RUNTIME_FILE" "postingruntime"
check_grep "135 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "135 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "135 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "135 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "135 export id guard" "$RUNTIME_FILE" "export_id is required"
check_grep "135 target system guard" "$RUNTIME_FILE" "target_system must be LOGO"
check_grep "135 format version guard" "$RUNTIME_FILE" "format_version mismatch"
check_grep "135 period guard" "$RUNTIME_FILE" "period_code is required"
check_grep "135 postings guard" "$RUNTIME_FILE" "postings are required"
check_grep "135 tenant scope guard" "$RUNTIME_FILE" "posting tenant_id mismatch"
check_grep "135 posting balanced guard" "$RUNTIME_FILE" "posting balanced is required"
check_grep "135 posting hash guard" "$RUNTIME_FILE" "posting_hash is required"
check_grep "135 audit trace guard" "$RUNTIME_FILE" "audit_trace_id is required"
check_grep "135 line debit credit exclusive guard" "$RUNTIME_FILE" "posting line cannot have both debit and credit"
check_grep "135 account prefix validation" "$RUNTIME_FILE" "accountPrefixAllowed"
check_grep "135 Turkish normalization" "$RUNTIME_FILE" "normalizeTurkishASCII"
check_grep "135 package hash builder" "$RUNTIME_FILE" "buildPackageHash"
check_grep "135 file hash builder" "$RUNTIME_FILE" "buildFileHash"

check_grep "135 journal header" "$RUNTIME_FILE" "DATE"
check_grep "135 ledger header" "$RUNTIME_FILE" "ACCOUNTCODE"
check_grep "135 summary balanced field" "$RUNTIME_FILE" "BALANCED"

check_grep "135 build package test" "$TEST_FILE" "TestBuildLogoPackageReady"
check_grep "135 journal file test" "$TEST_FILE" "TestLogoJournalFileContainsExpectedRows"
check_grep "135 ledger summary test" "$TEST_FILE" "TestLogoLedgerAndSummaryFilesGenerated"
check_grep "135 invalid account prefix test" "$TEST_FILE" "TestValidatePackageRejectsInvalidAccountPrefix"
check_grep "135 tenant mismatch test" "$TEST_FILE" "TestBuildPackageRejectsTenantMismatch"
check_grep "135 unbalanced posting test" "$TEST_FILE" "TestBuildPackageRejectsUnbalancedPosting"
check_grep "135 missing posting hash test" "$TEST_FILE" "TestBuildPackageRejectsMissingPostingHash"
check_grep "135 Turkish char normalization test" "$TEST_FILE" "TestNormalizeTurkishCharacters"

check_grep "135 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "135 config target Logo" "$CONFIG_FILE" "\"target_system\": \"LOGO\""
check_grep "135 config format version" "$CONFIG_FILE" "\"format_version\": \"LOGO_TDHP_V1\""
check_grep "135 config currency TRY" "$CONFIG_FILE" "\"default_currency_code\": \"TRY\""
check_grep "135 config journal file" "$CONFIG_FILE" "LOGO_JOURNAL_CSV"
check_grep "135 config ledger file" "$CONFIG_FILE" "LOGO_LEDGER_CSV"
check_grep "135 config summary file" "$CONFIG_FILE" "LOGO_SUMMARY_TXT"
check_grep "135 config next gate" "$CONFIG_FILE" "FAZ_3_10_4_2_MIKRO_REAL_FORMAT_GENERATION"

if go test ./internal/erp/turkiye/export/logo; then
  pass "135 Logo real format Go test status"
else
  fail "135 Logo real format Go test status"
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
# 135 — FAZ 3-10.4.1 — Logo Real Format Generation Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_4_1_LOGO_REAL_FORMAT_GENERATION_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_4_1_LOGO_REAL_FORMAT_GENERATION_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_4_2_READY=${NEXT_READY}

## Scope

- Logo export request model
- Logo journal row model
- Logo export file model
- Logo export package model
- Logo validation issue model
- Posting entry to Logo journal rows
- Journal CSV generation
- Ledger CSV generation
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

echo "===== 135 — FAZ 3-10.4.1 LOGO REAL FORMAT GENERATION COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_4_1_LOGO_REAL_FORMAT_GENERATION_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_4_1_LOGO_REAL_FORMAT_GENERATION_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_4_2_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
