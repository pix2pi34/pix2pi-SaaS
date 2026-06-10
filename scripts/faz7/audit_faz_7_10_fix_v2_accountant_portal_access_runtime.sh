#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/accountantportal/accountant_portal_access_runtime.go"
TEST_FILE="internal/platform/accountantportal/accountant_portal_access_runtime_test.go"
CONFIG_FILE="configs/faz7/accountant_portal_access_runtime.json"
DOC_FILE="docs/faz7/accountant_portal/FAZ_7_10_ACCOUNTANT_PORTAL_ACCESS_RUNTIME.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_10_FIX_V2_ACCOUNTANT_PORTAL_ACCESS_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-10 FIX V2 ACCOUNTANT PORTAL ACCESS RUNTIME REAL IMPLEMENTATION AUDIT START ====="

require_file "7-10.8.1 FIX V2 runtime file exists" "$RUNTIME_FILE"
require_file "7-10.8.2 FIX V2 test file exists" "$TEST_FILE"
require_file "7-10.8.3 FIX V2 config file exists" "$CONFIG_FILE"
require_file "7-10.8.4 FIX V2 documentation file exists" "$DOC_FILE"

require_grep "7-10.8.5 FIX V2 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_10_ACCOUNTANT_PORTAL_ACCESS_RUNTIME"
require_grep "7-10.8.6 FIX V2 multi-firm access runtime mode implemented" "$RUNTIME_FILE" "MULTI_FIRM_ACCESS_RUNTIME_DRY_RUN_ONLY"
require_grep "7-10.8.7 FIX V2 access gate implemented" "$RUNTIME_FILE" "type AccountantAccessGate struct"
require_grep "7-10.8.8 FIX V2 live operation close assertion implemented" "$RUNTIME_FILE" "AssertLiveOperationsClosed"
require_grep "7-10.8.9 FIX V2 firm access grant implemented" "$RUNTIME_FILE" "GrantFirmAccess"
require_grep "7-10.8.10 FIX V2 firm context selection implemented" "$RUNTIME_FILE" "SelectFirmContext"
require_grep "7-10.8.11 FIX V2 visible firm list implemented" "$RUNTIME_FILE" "ListVisibleFirms"
require_grep "7-10.8.12 FIX V2 revoke firm access implemented" "$RUNTIME_FILE" "RevokeFirmAccess"
require_grep "7-10.8.13 FIX V2 live customer data export blocker implemented" "$RUNTIME_FILE" "RequestLiveCustomerDataExport"
require_grep "7-10.8.14 FIX V2 real provider operation blocker implemented" "$RUNTIME_FILE" "RequestRealProviderOperation"
require_grep "7-10.8.15 FIX V2 real ERP write blocker implemented" "$RUNTIME_FILE" "RequestRealERPWrite"
require_grep "7-10.8.16 FIX V2 access audit event implemented" "$RUNTIME_FILE" "AccountantAccessAuditEvent"

require_grep "7-10.8.17 FIX V2 real billing gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_BILLING_LIVE_MODULE"
require_grep "7-10.8.18 FIX V2 real provider API gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
require_grep "7-10.8.19 FIX V2 real ERP write gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
require_grep "7-10.8.20 FIX V2 real customer data export gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_EXPORT_LIVE_MODULE"
require_grep "7-10.8.21 FIX V2 billing closed constant is local to 7-10 runtime" "$RUNTIME_FILE" "AccountantAccessClosedUntilBillingLiveModule"
require_grep "7-10.8.22 FIX V2 provider closed constant is local to 7-10 runtime" "$RUNTIME_FILE" "AccountantAccessClosedUntilProviderLiveModule"
require_grep "7-10.8.23 FIX V2 sync worker closed constant is local to 7-10 runtime" "$RUNTIME_FILE" "AccountantAccessClosedUntilSyncWorkerLiveModule"
require_grep "7-10.8.24 FIX V2 export closed constant is local to 7-10 runtime" "$RUNTIME_FILE" "AccountantAccessClosedUntilExportLiveModule"

require_grep "7-10.8.25 FIX V2 tenant isolation policy implemented" "$RUNTIME_FILE" "ACCOUNTANT_TENANT_AND_FIRM_TENANT_BOUNDARY_ENFORCED"
require_grep "7-10.8.26 FIX V2 no real customer data export policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_EXPORT_IN_THIS_PHASE"
require_grep "7-10.8.27 FIX V2 no real provider operation policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_OPERATION_IN_THIS_PHASE"
require_grep "7-10.8.28 FIX V2 no real ERP write policy implemented" "$RUNTIME_FILE" "NO_REAL_ERP_WRITE_IN_THIS_PHASE"

require_grep "7-10.8.29 FIX V2 grant and select test exists" "$TEST_FILE" "TestSevenTenGrantAndSelectFirmContext"
require_grep "7-10.8.30 FIX V2 permission enforcement test exists" "$TEST_FILE" "TestSevenTenPermissionEnforcement"
require_grep "7-10.8.31 FIX V2 cross-tenant isolation test exists" "$TEST_FILE" "TestSevenTenCrossTenantIsolation"
require_grep "7-10.8.32 FIX V2 period isolation and revoke test exists" "$TEST_FILE" "TestSevenTenPeriodIsolationAndRevoke"
require_grep "7-10.8.33 FIX V2 live operations closed test exists" "$TEST_FILE" "TestSevenTenLiveOperationsRemainClosed"
require_grep "7-10.8.34 FIX V2 audit trail test exists" "$TEST_FILE" "TestSevenTenAuditTrailForAccessDecisions"

require_grep "7-10.8.35 FIX V2 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_10_ACCOUNTANT_PORTAL_ACCESS_RUNTIME\""
require_grep "7-10.8.36 FIX V2 config dry-run mode exists" "$CONFIG_FILE" "\"mode\": \"MULTI_FIRM_ACCESS_RUNTIME_DRY_RUN_ONLY\""
require_grep "7-10.8.37 FIX V2 config depends on 7-9 PASS" "$CONFIG_FILE" "\"faz_7_9_accountant_portal_commercial_surface_final_status\": \"PASS\""
require_grep "7-10.8.38 FIX V2 config tenant isolation policy exists" "$CONFIG_FILE" "\"tenant_isolation_policy\": \"ACCOUNTANT_TENANT_AND_FIRM_TENANT_BOUNDARY_ENFORCED\""
require_grep "7-10.8.39 FIX V2 config billing gate closed" "$CONFIG_FILE" "\"real_accountant_billing_status\": \"CLOSED_UNTIL_BILLING_LIVE_MODULE\""
require_grep "7-10.8.40 FIX V2 config provider API gate closed" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
require_grep "7-10.8.41 FIX V2 config ERP write gate closed" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""
require_grep "7-10.8.42 FIX V2 config customer export gate closed" "$CONFIG_FILE" "\"real_customer_data_export_live_status\": \"CLOSED_UNTIL_EXPORT_LIVE_MODULE\""

require_grep "7-10.8.43 FIX V2 documentation declares runtime rules" "$DOC_FILE" "Runtime kuralı"
require_grep "7-10.8.44 FIX V2 documentation declares closed live operations" "$DOC_FILE" "Kapalı kalan live işlemler"
require_grep "7-10.8.45 FIX V2 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-10.8.46 FIX V2 runtime does not allow real customer data in firm context" "$RUNTIME_FILE" "ContainsRealCustomerData:     true"
require_not_grep "7-10.8.47 FIX V2 runtime does not allow real provider API" "$RUNTIME_FILE" "RealProviderAPIAllowed:       true"
require_not_grep "7-10.8.48 FIX V2 runtime does not allow real ERP write" "$RUNTIME_FILE" "RealERPWriteAllowed:          true"

if go test ./internal/platform/accountantportal; then
  ok "7-10.8.49 FIX V2 go test verification PASS"
else
  fail "7-10.8.49 FIX V2 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-10 FIX V2 ACCOUNTANT PORTAL ACCESS RUNTIME REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_10_FIX_V2_ACCOUNTANT_PORTAL_ACCESS_RUNTIME_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
