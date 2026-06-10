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

echo "===== 142 — FAZ 3-10.5.3 EXCEL PDF TDHP EXPORT RUNTIME REAL IMPLEMENTATION AUDIT START ====="

RUNTIME_FILE="internal/erp/turkiye/accountantportal/exportruntime/excel_pdf_tdhp_export_runtime.go"
TEST_FILE="internal/erp/turkiye/accountantportal/exportruntime/excel_pdf_tdhp_export_runtime_test.go"
CONFIG_FILE="configs/faz3/accountantportal/excel_pdf_tdhp_export_runtime.v1.json"
DOC_FILE="docs/faz3/accountantportal/FAZ_3_10_5_3_EXCEL_PDF_TDHP_EXPORT_RUNTIME.md"

check_file "142 export runtime file" "$RUNTIME_FILE"
check_file "142 export test file" "$TEST_FILE"
check_file "142 export config file" "$CONFIG_FILE"
check_file "142 export documentation file" "$DOC_FILE"

check_grep "142 runtime constructor" "$RUNTIME_FILE" "NewExcelPDFTDHPExportRuntime"
check_grep "142 export runtime" "$RUNTIME_FILE" "Export"
check_grep "142 export bundle runtime" "$RUNTIME_FILE" "ExportBundle"
check_grep "142 permission runtime bridge" "$RUNTIME_FILE" "companypermission.NewCompanyPermissionEnforcementRuntime"
check_grep "142 permission for format runtime" "$RUNTIME_FILE" "permissionForFormat"
check_grep "142 ledger row validation runtime" "$RUNTIME_FILE" "validateRows"

check_grep "142 ledger row model" "$RUNTIME_FILE" "type LedgerExportRow"
check_grep "142 portal export request model" "$RUNTIME_FILE" "type PortalExportRequest"
check_grep "142 portal export file model" "$RUNTIME_FILE" "type PortalExportFile"
check_grep "142 portal export result model" "$RUNTIME_FILE" "type PortalExportResult"
check_grep "142 export bundle request model" "$RUNTIME_FILE" "type ExportBundleRequest"
check_grep "142 export bundle result model" "$RUNTIME_FILE" "type ExportBundleResult"

check_grep "142 Excel format support" "$RUNTIME_FILE" "ExportFormatExcel"
check_grep "142 PDF format support" "$RUNTIME_FILE" "ExportFormatPDF"
check_grep "142 TDHP format support" "$RUNTIME_FILE" "ExportFormatTDHP"
check_grep "142 Excel builder" "$RUNTIME_FILE" "buildExcelFile"
check_grep "142 PDF builder" "$RUNTIME_FILE" "buildPDFFile"
check_grep "142 TDHP builder" "$RUNTIME_FILE" "buildTDHPFile"

check_grep "142 Excel permission bridge" "$RUNTIME_FILE" "PermissionExportExcel"
check_grep "142 PDF permission bridge" "$RUNTIME_FILE" "PermissionExportPDF"
check_grep "142 TDHP permission bridge" "$RUNTIME_FILE" "PermissionExportTDHP"
check_grep "142 export resource bridge" "$RUNTIME_FILE" "ResourceTypeExport"

check_grep "142 tenant guard" "$RUNTIME_FILE" "tenant_id is required"
check_grep "142 correlation guard" "$RUNTIME_FILE" "correlation_id is required"
check_grep "142 request guard" "$RUNTIME_FILE" "request_id is required"
check_grep "142 idempotency guard" "$RUNTIME_FILE" "idempotency_key is required"
check_grep "142 export id guard" "$RUNTIME_FILE" "export_id is required"
check_grep "142 format allowed guard" "$RUNTIME_FILE" "export format is not allowed"
check_grep "142 accountant firm guard" "$RUNTIME_FILE" "accountant_firm_id is required"
check_grep "142 accountant user guard" "$RUNTIME_FILE" "accountant_user_id is required"
check_grep "142 assignment guard" "$RUNTIME_FILE" "assignment_id is required"
check_grep "142 target firm guard" "$RUNTIME_FILE" "target_firm_tenant_id is required"
check_grep "142 target company guard" "$RUNTIME_FILE" "target_company_id is required"
check_grep "142 target company name guard" "$RUNTIME_FILE" "target_company_name is required"
check_grep "142 period guard" "$RUNTIME_FILE" "period_code is required"
check_grep "142 ledger rows guard" "$RUNTIME_FILE" "ledger_rows are required"
check_grep "142 max rows guard" "$RUNTIME_FILE" "ledger_rows exceed max_rows"
check_grep "142 ledger row tenant mismatch guard" "$RUNTIME_FILE" "ledger row tenant_id mismatch"
check_grep "142 ledger row company mismatch guard" "$RUNTIME_FILE" "ledger row target_company_id mismatch"
check_grep "142 ledger row balance guard" "$RUNTIME_FILE" "ledger row cannot have both debit and credit"
check_grep "142 ledger row posting hash guard" "$RUNTIME_FILE" "ledger row posting_hash is required"
check_grep "142 ledger row audit trace guard" "$RUNTIME_FILE" "ledger row audit_trace_id is required"
check_grep "142 export balance guard" "$RUNTIME_FILE" "export debit and credit totals must match"
check_grep "142 file hash builder" "$RUNTIME_FILE" "buildFileHash"
check_grep "142 export hash builder" "$RUNTIME_FILE" "buildExportHash"
check_grep "142 bundle hash builder" "$RUNTIME_FILE" "buildBundleHash"

check_grep "142 Excel allowed test" "$TEST_FILE" "TestExportExcelAllowed"
check_grep "142 PDF allowed test" "$TEST_FILE" "TestExportPDFAllowed"
check_grep "142 TDHP allowed test" "$TEST_FILE" "TestExportTDHPAllowed"
check_grep "142 bundle test" "$TEST_FILE" "TestExportBundleAllFormatsAllowed"
check_grep "142 permission denied test" "$TEST_FILE" "TestExportRejectsPermissionDenied"
check_grep "142 company mismatch test" "$TEST_FILE" "TestExportRejectsCompanyMismatchGrant"
check_grep "142 unbalanced rows test" "$TEST_FILE" "TestExportRejectsUnbalancedRows"
check_grep "142 tenant mismatch row test" "$TEST_FILE" "TestExportRejectsTenantMismatchRow"
check_grep "142 unsupported format test" "$TEST_FILE" "TestExportRejectsUnsupportedFormat"
check_grep "142 too many rows test" "$TEST_FILE" "TestExportRejectsTooManyRows"

check_grep "142 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "142 config Excel format" "$CONFIG_FILE" "\"EXCEL\""
check_grep "142 config PDF format" "$CONFIG_FILE" "\"PDF\""
check_grep "142 config TDHP format" "$CONFIG_FILE" "\"TDHP\""
check_grep "142 config permission bridge" "$CONFIG_FILE" "\"permission_bridge\""
check_grep "142 config export hash required" "$CONFIG_FILE" "\"require_export_hash\": true"
check_grep "142 config bundle support" "$CONFIG_FILE" "\"bundle_export_supported\": true"
check_grep "142 config next gate" "$CONFIG_FILE" "FAZ_3_10_5_4_MONTHLY_SUBSCRIPTION_RUNTIME"

if go test ./internal/erp/turkiye/accountantportal/exportruntime; then
  pass "142 Excel/PDF/TDHP export runtime Go test status"
else
  fail "142 Excel/PDF/TDHP export runtime Go test status"
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
# 142 — FAZ 3-10.5.3 — Excel PDF TDHP Export Runtime Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_5_3_EXCEL_PDF_TDHP_EXPORT_RUNTIME_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_5_3_EXCEL_PDF_TDHP_EXPORT_RUNTIME_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_5_4_READY=${NEXT_READY}

## Scope

- Portal export request model
- Portal export file model
- Portal export result model
- Export bundle request/result model
- Ledger export row model
- Excel CSV export generation
- PDF simulation export generation
- TDHP TXT export generation
- Company permission enforcement bridge
- Format to permission map
- Tenant scope guard
- Company scope guard
- Ledger row validation
- Balance guard
- Export hash guard
- Bundle export support

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 142 — FAZ 3-10.5.3 EXCEL PDF TDHP EXPORT RUNTIME COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_5_3_EXCEL_PDF_TDHP_EXPORT_RUNTIME_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_5_3_EXCEL_PDF_TDHP_EXPORT_RUNTIME_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_5_4_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
