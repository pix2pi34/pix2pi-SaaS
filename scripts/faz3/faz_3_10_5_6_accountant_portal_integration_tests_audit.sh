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

echo "===== 145 — FAZ 3-10.5.6 ACCOUNTANT PORTAL INTEGRATION TESTS REAL IMPLEMENTATION AUDIT START ====="

SUITE_FILE="internal/erp/turkiye/accountantportal/integrationtests/accountant_portal_integration_suite.go"
TEST_FILE="internal/erp/turkiye/accountantportal/integrationtests/accountant_portal_integration_suite_test.go"
CONFIG_FILE="configs/faz3/accountantportal/accountant_portal_integration_tests.v1.json"
DOC_FILE="docs/faz3/accountantportal/FAZ_3_10_5_6_ACCOUNTANT_PORTAL_INTEGRATION_TESTS.md"

check_file "145 accountant portal integration suite file" "$SUITE_FILE"
check_file "145 accountant portal integration test file" "$TEST_FILE"
check_file "145 accountant portal integration config file" "$CONFIG_FILE"
check_file "145 accountant portal integration documentation file" "$DOC_FILE"

check_grep "145 suite constructor" "$SUITE_FILE" "NewAccountantPortalIntegrationSuite"
check_grep "145 full portal flow runtime" "$SUITE_FILE" "RunFullPortalFlow"
check_grep "145 subscription flow runtime" "$SUITE_FILE" "runSubscriptionFlow"
check_grep "145 visibility flow runtime" "$SUITE_FILE" "runVisibilityFlow"
check_grep "145 permission flow runtime" "$SUITE_FILE" "runPermissionFlow"
check_grep "145 export flow runtime" "$SUITE_FILE" "runExportFlow"

check_grep "145 subscription runtime import" "$SUITE_FILE" "accountantportal/subscriptionruntime"
check_grep "145 visibility runtime import" "$SUITE_FILE" "accountantportal/companyvisibility"
check_grep "145 permission runtime import" "$SUITE_FILE" "accountantportal/companypermission"
check_grep "145 export runtime import" "$SUITE_FILE" "accountantportal/exportruntime"
check_grep "145 multi firm runtime import" "$SUITE_FILE" "accountantportal/multifirmaccess"

check_grep "145 suite request model" "$SUITE_FILE" "type IntegrationSuiteRequest"
check_grep "145 suite result model" "$SUITE_FILE" "type IntegrationSuiteResult"
check_grep "145 integration status pass" "$SUITE_FILE" "IntegrationStatusPass"
check_grep "145 integration status fail" "$SUITE_FILE" "IntegrationStatusFail"

check_grep "145 subscription activation operation" "$SUITE_FILE" "ActivateMonthly"
check_grep "145 visibility operation" "$SUITE_FILE" "BuildVisibility"
check_grep "145 permission enforcement operation" "$SUITE_FILE" "Enforce"
check_grep "145 export bundle operation" "$SUITE_FILE" "ExportBundle"

check_grep "145 Excel format coverage" "$SUITE_FILE" "ExportFormatExcel"
check_grep "145 PDF format coverage" "$SUITE_FILE" "ExportFormatPDF"
check_grep "145 TDHP format coverage" "$SUITE_FILE" "ExportFormatTDHP"
check_grep "145 TDHP permission coverage" "$SUITE_FILE" "PermissionExportTDHP"

check_grep "145 tenant guard" "$SUITE_FILE" "tenant_id is required"
check_grep "145 correlation guard" "$SUITE_FILE" "correlation_id is required"
check_grep "145 request guard" "$SUITE_FILE" "request_id is required"
check_grep "145 idempotency guard" "$SUITE_FILE" "idempotency_key is required"
check_grep "145 suite id guard" "$SUITE_FILE" "suite_id is required"
check_grep "145 accountant firm guard" "$SUITE_FILE" "accountant_firm_id is required"
check_grep "145 accountant user guard" "$SUITE_FILE" "accountant_user_id is required"
check_grep "145 actor guard" "$SUITE_FILE" "actor_id is required"
check_grep "145 subscription id guard" "$SUITE_FILE" "subscription_id is required"
check_grep "145 billing profile guard" "$SUITE_FILE" "billing_profile_id is required"
check_grep "145 assignment guard" "$SUITE_FILE" "assignment_id is required"
check_grep "145 target firm guard" "$SUITE_FILE" "target_firm_tenant_id is required"
check_grep "145 target company guard" "$SUITE_FILE" "target_company_id is required"
check_grep "145 company name guard" "$SUITE_FILE" "target_company_name is required"
check_grep "145 company tax no guard" "$SUITE_FILE" "target_company_tax_no is required"
check_grep "145 period guard" "$SUITE_FILE" "period_code is required"
check_grep "145 fiscal year guard" "$SUITE_FILE" "fiscal_year is invalid"
check_grep "145 integration hash builder" "$SUITE_FILE" "buildIntegrationHash"

check_grep "145 full flow test" "$TEST_FILE" "TestFullAccountantPortalIntegrationFlowPasses"
check_grep "145 subscription flow test" "$TEST_FILE" "TestIntegrationFlowActivatesSubscription"
check_grep "145 visibility flow test" "$TEST_FILE" "TestIntegrationFlowBuildsVisibleCompanyList"
check_grep "145 permission flow test" "$TEST_FILE" "TestIntegrationFlowAllowsTDHPPermission"
check_grep "145 export flow test" "$TEST_FILE" "TestIntegrationFlowBuildsExcelPDFTDHPExports"
check_grep "145 missing tenant test" "$TEST_FILE" "TestIntegrationFlowRejectsMissingTenant"
check_grep "145 missing tax no test" "$TEST_FILE" "TestIntegrationFlowRejectsMissingCompanyTaxNo"
check_grep "145 missing billing profile test" "$TEST_FILE" "TestIntegrationFlowRejectsMissingBillingProfile"

check_grep "145 config runtime enabled" "$CONFIG_FILE" "\"runtime_enabled\": true"
check_grep "145 config subscription flow required" "$CONFIG_FILE" "\"require_subscription_flow\": true"
check_grep "145 config visibility flow required" "$CONFIG_FILE" "\"require_visibility_flow\": true"
check_grep "145 config permission flow required" "$CONFIG_FILE" "\"require_permission_flow\": true"
check_grep "145 config export flow required" "$CONFIG_FILE" "\"require_export_flow\": true"
check_grep "145 config all formats required" "$CONFIG_FILE" "\"require_all_formats\": true"
check_grep "145 config audit hash required" "$CONFIG_FILE" "\"require_audit_hash\": true"
check_grep "145 config multi firm module coverage" "$CONFIG_FILE" "FAZ_3_10_5_1_MULTI_FIRM_ACCESS_RUNTIME"
check_grep "145 config permission module coverage" "$CONFIG_FILE" "FAZ_3_10_5_2_COMPANY_PERMISSION_ENFORCEMENT"
check_grep "145 config export module coverage" "$CONFIG_FILE" "FAZ_3_10_5_3_EXCEL_PDF_TDHP_EXPORT_RUNTIME"
check_grep "145 config subscription module coverage" "$CONFIG_FILE" "FAZ_3_10_5_4_MONTHLY_SUBSCRIPTION_RUNTIME"
check_grep "145 config visibility module coverage" "$CONFIG_FILE" "FAZ_3_10_5_5_COMPANY_VISIBILITY_RUNTIME"
check_grep "145 config next gate" "$CONFIG_FILE" "FAZ_3_10_6_1_OCR_LENS_PROCESSING_RUNTIME"

if go test ./internal/erp/turkiye/accountantportal/integrationtests; then
  pass "145 accountant portal integration Go test status"
else
  fail "145 accountant portal integration Go test status"
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
# 145 — FAZ 3-10.5.6 — Accountant Portal Integration Tests Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- WARN_COUNT=${WARN_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- FAZ_3_10_5_6_ACCOUNTANT_PORTAL_INTEGRATION_TESTS_FINAL_STATUS=${FINAL_STATUS}
- FAZ_3_10_5_6_ACCOUNTANT_PORTAL_INTEGRATION_TESTS_SEAL_STATUS=${SEAL_STATUS}
- FAZ_3_10_6_1_READY=${NEXT_READY}

## Scope

- Monthly subscription activation flow
- Company visibility flow
- Company permission enforcement flow
- Excel/PDF/TDHP export bundle flow
- Subscription runtime bridge
- Company visibility runtime bridge
- Company permission enforcement bridge
- Export runtime bridge
- Integration hash generation
- Validation guard tests

## Audit Notes

Final status is derived from real files, Go tests and audit counters.
Hardcoded OK evidence is not accepted.
EOFMD

echo "===== 145 — FAZ 3-10.5.6 ACCOUNTANT PORTAL INTEGRATION TESTS COUNTER BASED FINAL STATUS ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "WARN_COUNT=${WARN_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "FAZ_3_10_5_6_ACCOUNTANT_PORTAL_INTEGRATION_TESTS_FINAL_STATUS=${FINAL_STATUS}"
echo "FAZ_3_10_5_6_ACCOUNTANT_PORTAL_INTEGRATION_TESTS_SEAL_STATUS=${SEAL_STATUS}"
echo "FAZ_3_10_6_1_READY=${NEXT_READY}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$FINAL_STATUS" != "PASS" ]; then
  exit 1
fi
