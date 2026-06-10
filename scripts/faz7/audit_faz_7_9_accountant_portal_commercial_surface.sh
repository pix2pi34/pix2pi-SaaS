#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/accountantportal/accountant_portal_commercial_surface.go"
TEST_FILE="internal/platform/accountantportal/accountant_portal_commercial_surface_test.go"
CONFIG_FILE="configs/faz7/accountant_portal_commercial_surface.json"
DOC_FILE="docs/faz7/accountant_portal/FAZ_7_9_ACCOUNTANT_PORTAL_COMMERCIAL_SURFACE.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_9_ACCOUNTANT_PORTAL_COMMERCIAL_SURFACE_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-9 ACCOUNTANT PORTAL COMMERCIAL SURFACE REAL IMPLEMENTATION AUDIT START ====="

require_file "7-9.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-9.6.2 test file exists" "$TEST_FILE"
require_file "7-9.6.3 config file exists" "$CONFIG_FILE"
require_file "7-9.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-9.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_9_ACCOUNTANT_PORTAL_COMMERCIAL_SURFACE"
require_grep "7-9.6.6 dry-run commercial surface mode implemented" "$RUNTIME_FILE" "COMMERCIAL_SURFACE_DRY_RUN_ONLY"
require_grep "7-9.6.7 commercial gate struct implemented" "$RUNTIME_FILE" "type CommercialGate struct"
require_grep "7-9.6.8 live operation close assertion implemented" "$RUNTIME_FILE" "AssertLiveOperationsClosed"
require_grep "7-9.6.9 live commercial operation blocker implemented" "$RUNTIME_FILE" "RequestLiveCommercialOperation"
require_grep "7-9.6.10 firm slot assignment implemented" "$RUNTIME_FILE" "AssignFirm"
require_grep "7-9.6.11 billing draft implemented" "$RUNTIME_FILE" "CreateBillingDraft"
require_grep "7-9.6.12 export preview implemented" "$RUNTIME_FILE" "BuildExportPreview"
require_grep "7-9.6.13 audit event implemented" "$RUNTIME_FILE" "AuditEvent"

require_grep "7-9.6.14 real accountant billing gate closed in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_BILLING_LIVE_MODULE"
require_grep "7-9.6.15 real provider API gate closed in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
require_grep "7-9.6.16 real ERP write gate closed in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
require_grep "7-9.6.17 real customer export gate closed in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_EXPORT_LIVE_MODULE"

require_grep "7-9.6.18 Paraşüt dry-run provider visible" "$RUNTIME_FILE" "PARASUT"
require_grep "7-9.6.19 Logo dry-run provider visible" "$RUNTIME_FILE" "LOGO"
require_grep "7-9.6.20 Mikro dry-run provider visible" "$RUNTIME_FILE" "MIKRO"
require_grep "7-9.6.21 Zirve dry-run provider visible" "$RUNTIME_FILE" "ZIRVE"

require_grep "7-9.6.22 commercial surface live-closed test exists" "$TEST_FILE" "TestSevenNineCommercialSurfaceKeepsLiveOperationsClosed"
require_grep "7-9.6.23 tenant-safe firm slot test exists" "$TEST_FILE" "TestSevenNineFirmSlotAssignmentTenantSafe"
require_grep "7-9.6.24 billing draft-only test exists" "$TEST_FILE" "TestSevenNineBillingDraftIsDraftOnly"
require_grep "7-9.6.25 export preview no-real-data test exists" "$TEST_FILE" "TestSevenNineExportPreviewNoRealDataProviderAPIsClosed"
require_grep "7-9.6.26 audit trail test exists" "$TEST_FILE" "TestSevenNineAuditTrailCreatedForCommercialActions"

require_grep "7-9.6.27 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_9_ACCOUNTANT_PORTAL_COMMERCIAL_SURFACE\""
require_grep "7-9.6.28 config dry-run mode exists" "$CONFIG_FILE" "\"mode\": \"COMMERCIAL_SURFACE_DRY_RUN_ONLY\""
require_grep "7-9.6.29 config billing gate closed" "$CONFIG_FILE" "\"real_accountant_billing_status\": \"CLOSED_UNTIL_BILLING_LIVE_MODULE\""
require_grep "7-9.6.30 config provider API gate closed" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
require_grep "7-9.6.31 config ERP write gate closed" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""
require_grep "7-9.6.32 config customer export live gate closed" "$CONFIG_FILE" "\"real_customer_data_export_live_status\": \"CLOSED_UNTIL_EXPORT_LIVE_MODULE\""

require_grep "7-9.6.33 documentation declares live operations closed" "$DOC_FILE" "Bu fazda kapalı kalan şey"
require_grep "7-9.6.34 documentation declares provider dry-run family" "$DOC_FILE" "FAZ 7-8 entegrasyon dry-run ailesi mühürlüdür"
require_grep "7-9.6.35 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-9.6.36 runtime does not enable real invoice creation" "$RUNTIME_FILE" "RealInvoiceCreated:        true"
require_not_grep "7-9.6.37 runtime does not enable real payment capture" "$RUNTIME_FILE" "RealPaymentCaptureEnabled: true"
require_not_grep "7-9.6.38 runtime does not request real provider API" "$RUNTIME_FILE" "RealProviderAPIRequested: true"
require_not_grep "7-9.6.39 runtime does not request real ERP write" "$RUNTIME_FILE" "RealERPWriteRequested:    true"
require_not_grep "7-9.6.40 runtime does not include real customer data in preview" "$RUNTIME_FILE" "ContainsRealCustomerData: true"

if go test ./internal/platform/accountantportal; then
  ok "7-9.6.41 go test verification PASS"
else
  fail "7-9.6.41 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-9 ACCOUNTANT PORTAL COMMERCIAL SURFACE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_9_ACCOUNTANT_PORTAL_COMMERCIAL_SURFACE_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
