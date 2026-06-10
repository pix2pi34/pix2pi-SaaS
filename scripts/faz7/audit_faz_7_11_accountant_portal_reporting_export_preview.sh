#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/accountantportal/accountant_portal_reporting_export_preview.go"
TEST_FILE="internal/platform/accountantportal/accountant_portal_reporting_export_preview_test.go"
CONFIG_FILE="configs/faz7/accountant_portal_reporting_export_preview.json"
DOC_FILE="docs/faz7/accountant_portal/FAZ_7_11_ACCOUNTANT_PORTAL_REPORTING_EXPORT_PREVIEW.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_11_ACCOUNTANT_PORTAL_REPORTING_EXPORT_PREVIEW_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

mkdir -p "$(dirname "$EVIDENCE_FILE")"
exec > >(tee "$EVIDENCE_FILE") 2>&1

ok() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "$1 / OK ✅"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
  echo "$1 / FAIL ❌"
}

require_file() {
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

require_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

require_not_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && ! grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 7-11 ACCOUNTANT PORTAL REPORTING EXPORT PREVIEW REAL IMPLEMENTATION AUDIT START ====="

require_file "7-11.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-11.6.2 test file exists" "$TEST_FILE"
require_file "7-11.6.3 config file exists" "$CONFIG_FILE"
require_file "7-11.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-11.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_11_ACCOUNTANT_PORTAL_REPORTING_EXPORT_PREVIEW"
require_grep "7-11.6.6 preview dry-run mode implemented" "$RUNTIME_FILE" "REPORTING_EXPORT_PREVIEW_DRY_RUN_ONLY"
require_grep "7-11.6.7 reporting gate implemented" "$RUNTIME_FILE" "type AccountantReportingGate struct"
require_grep "7-11.6.8 live operation close assertion implemented" "$RUNTIME_FILE" "AssertLiveOperationsClosed"
require_grep "7-11.6.9 report preview runtime implemented" "$RUNTIME_FILE" "BuildReportPreview"
require_grep "7-11.6.10 export package preview runtime implemented" "$RUNTIME_FILE" "BuildExportPackagePreview"
require_grep "7-11.6.11 access runtime dependency implemented" "$RUNTIME_FILE" "accessRuntime *AccountantPortalAccessRuntime"
require_grep "7-11.6.12 firm context selection dependency implemented" "$RUNTIME_FILE" "SelectFirmContext"
require_grep "7-11.6.13 synthetic report rows implemented" "$RUNTIME_FILE" "syntheticReportRows"
require_grep "7-11.6.14 synthetic export manifest implemented" "$RUNTIME_FILE" "syntheticExportManifest"
require_grep "7-11.6.15 reporting audit event implemented" "$RUNTIME_FILE" "AccountantReportingAuditEvent"

require_grep "7-11.6.16 real billing gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_BILLING_LIVE_MODULE"
require_grep "7-11.6.17 real provider API gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
require_grep "7-11.6.18 real ERP write gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
require_grep "7-11.6.19 real customer export gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_EXPORT_LIVE_MODULE"
require_grep "7-11.6.20 no real customer data policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_IN_REPORT_PREVIEW"
require_grep "7-11.6.21 no real export policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_EXPORT_IN_THIS_PHASE"
require_grep "7-11.6.22 no real provider API policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_OPERATION_IN_THIS_PHASE"
require_grep "7-11.6.23 no real file delivery policy implemented" "$RUNTIME_FILE" "NO_REAL_FILE_DELIVERY_IN_THIS_PHASE"
require_grep "7-11.6.24 no real ERP write policy implemented" "$RUNTIME_FILE" "NO_REAL_ERP_WRITE_IN_THIS_PHASE"

require_grep "7-11.6.25 Paraşüt dry-run provider supported" "$RUNTIME_FILE" "PARASUT"
require_grep "7-11.6.26 Logo dry-run provider supported" "$RUNTIME_FILE" "LOGO"
require_grep "7-11.6.27 Mikro dry-run provider supported" "$RUNTIME_FILE" "MIKRO"
require_grep "7-11.6.28 Zirve dry-run provider supported" "$RUNTIME_FILE" "ZIRVE"

require_grep "7-11.6.29 report preview access test exists" "$TEST_FILE" "TestSevenElevenBuildReportPreviewRequiresAccess"
require_grep "7-11.6.30 report preview denied test exists" "$TEST_FILE" "TestSevenElevenReportPreviewDeniedWithoutAccess"
require_grep "7-11.6.31 export provider preview test exists" "$TEST_FILE" "TestSevenElevenExportPackagePreviewForSealedDryRunProviders"
require_grep "7-11.6.32 export permission test exists" "$TEST_FILE" "TestSevenElevenExportPreviewRequiresExportPermission"
require_grep "7-11.6.33 live operations closed test exists" "$TEST_FILE" "TestSevenElevenLiveOperationsRemainClosed"
require_grep "7-11.6.34 reporting audit trail test exists" "$TEST_FILE" "TestSevenElevenReportingAuditTrail"

require_grep "7-11.6.35 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_11_ACCOUNTANT_PORTAL_REPORTING_EXPORT_PREVIEW\""
require_grep "7-11.6.36 config dry-run mode exists" "$CONFIG_FILE" "\"mode\": \"REPORTING_EXPORT_PREVIEW_DRY_RUN_ONLY\""
require_grep "7-11.6.37 config depends on 7-10 PASS" "$CONFIG_FILE" "\"faz_7_10_accountant_portal_access_runtime_final_status\": \"PASS\""
require_grep "7-11.6.38 config report permission exists" "$CONFIG_FILE" "\"report_permission\": \"report.view\""
require_grep "7-11.6.39 config export permission exists" "$CONFIG_FILE" "\"export_permission\": \"export.preview\""
require_grep "7-11.6.40 config billing gate closed" "$CONFIG_FILE" "\"real_accountant_billing_status\": \"CLOSED_UNTIL_BILLING_LIVE_MODULE\""
require_grep "7-11.6.41 config provider API gate closed" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
require_grep "7-11.6.42 config ERP write gate closed" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""
require_grep "7-11.6.43 config customer export gate closed" "$CONFIG_FILE" "\"real_customer_data_export_live_status\": \"CLOSED_UNTIL_EXPORT_LIVE_MODULE\""

require_grep "7-11.6.44 documentation declares runtime rules" "$DOC_FILE" "Runtime kuralları"
require_grep "7-11.6.45 documentation declares closed live operations" "$DOC_FILE" "Kapalı kalan live işlemler"
require_grep "7-11.6.46 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-11.6.47 runtime does not allow real customer data in report preview" "$RUNTIME_FILE" "ContainsRealCustomerData:      true"
require_not_grep "7-11.6.48 runtime does not allow real customer export" "$RUNTIME_FILE" "RealCustomerDataExportAllowed: true"
require_not_grep "7-11.6.49 runtime does not allow real provider API" "$RUNTIME_FILE" "RealProviderAPIAllowed:        true"
require_not_grep "7-11.6.50 runtime does not allow real ERP write" "$RUNTIME_FILE" "RealERPWriteAllowed:           true"
require_not_grep "7-11.6.51 runtime does not request live delivery" "$RUNTIME_FILE" "LiveDeliveryRequested:    true"
require_not_grep "7-11.6.52 runtime does not request provider API" "$RUNTIME_FILE" "RealProviderAPIRequested: true"
require_not_grep "7-11.6.53 runtime does not request ERP write" "$RUNTIME_FILE" "RealERPWriteRequested:    true"
require_not_grep "7-11.6.54 runtime manifest does not contain real data" "$RUNTIME_FILE" "ContainsRealData:    true"

if go test ./internal/platform/accountantportal; then
  ok "7-11.6.55 go test verification PASS"
else
  fail "7-11.6.55 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-11 ACCOUNTANT PORTAL REPORTING EXPORT PREVIEW REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_11_ACCOUNTANT_PORTAL_REPORTING_EXPORT_PREVIEW_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
