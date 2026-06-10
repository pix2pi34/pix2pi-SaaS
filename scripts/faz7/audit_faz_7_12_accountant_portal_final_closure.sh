#!/usr/bin/env bash
set -u
set -o pipefail

RUNTIME_FILE="internal/platform/accountantportal/accountant_portal_final_closure.go"
TEST_FILE="internal/platform/accountantportal/accountant_portal_final_closure_test.go"
CONFIG_FILE="configs/faz7/accountant_portal_final_closure.json"
DOC_FILE="docs/faz7/accountant_portal/FAZ_7_12_ACCOUNTANT_PORTAL_FINAL_CLOSURE.md"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_12_ACCOUNTANT_PORTAL_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT.md"

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

echo "===== FAZ 7-12 ACCOUNTANT PORTAL FINAL CLOSURE REAL IMPLEMENTATION AUDIT START ====="

require_file "7-12.6.1 runtime file exists" "$RUNTIME_FILE"
require_file "7-12.6.2 test file exists" "$TEST_FILE"
require_file "7-12.6.3 config file exists" "$CONFIG_FILE"
require_file "7-12.6.4 documentation file exists" "$DOC_FILE"

require_grep "7-12.6.5 module code implemented in runtime" "$RUNTIME_FILE" "FAZ_7_12_ACCOUNTANT_PORTAL_FINAL_CLOSURE"
require_grep "7-12.6.6 final closure mode implemented" "$RUNTIME_FILE" "ACCOUNTANT_PORTAL_FINAL_CLOSURE_COMMERCIAL_HANDOFF_GATE"
require_grep "7-12.6.7 final closure gate implemented" "$RUNTIME_FILE" "type AccountantPortalFinalClosureGate struct"
require_grep "7-12.6.8 final closure report implemented" "$RUNTIME_FILE" "type AccountantPortalFinalClosureReport struct"
require_grep "7-12.6.9 dependency seal implemented" "$RUNTIME_FILE" "type AccountantPortalDependencySeal struct"
require_grep "7-12.6.10 provider closure status implemented" "$RUNTIME_FILE" "type AccountantPortalProviderClosureStatus struct"
require_grep "7-12.6.11 build final closure report implemented" "$RUNTIME_FILE" "BuildFinalClosureReport"
require_grep "7-12.6.12 dependency validation implemented" "$RUNTIME_FILE" "validateDependencies"
require_grep "7-12.6.13 provider validation implemented" "$RUNTIME_FILE" "validateProviders"
require_grep "7-12.6.14 live operation close assertion implemented" "$RUNTIME_FILE" "AssertLiveOperationsClosed"
require_grep "7-12.6.15 final closure audit event implemented" "$RUNTIME_FILE" "AccountantPortalFinalClosureAuditEvent"

require_grep "7-12.6.16 7-9 dependency exists in runtime" "$RUNTIME_FILE" "FAZ_7_9_ACCOUNTANT_PORTAL_COMMERCIAL_SURFACE"
require_grep "7-12.6.17 7-10 dependency exists in runtime" "$RUNTIME_FILE" "FAZ_7_10_ACCOUNTANT_PORTAL_ACCESS_RUNTIME"
require_grep "7-12.6.18 7-11 dependency exists in runtime" "$RUNTIME_FILE" "FAZ_7_11_ACCOUNTANT_PORTAL_REPORTING_EXPORT_PREVIEW"
require_grep "7-12.6.19 PASS dependency status exists in runtime" "$RUNTIME_FILE" "PASS"
require_grep "7-12.6.20 SEALED seal status exists in runtime" "$RUNTIME_FILE" "SEALED"

require_grep "7-12.6.21 commercial handoff gate exists in runtime" "$RUNTIME_FILE" "READY_FOR_COMMERCIAL_LIVE_MODULE"
require_grep "7-12.6.22 live module not started status exists in runtime" "$RUNTIME_FILE" "NOT_STARTED"
require_grep "7-12.6.23 provider dry-run set exists in runtime" "$RUNTIME_FILE" "PARASUT_LOGO_MIKRO_ZIRVE"
require_grep "7-12.6.24 Paraşüt provider exists in runtime" "$RUNTIME_FILE" "PARASUT"
require_grep "7-12.6.25 Logo provider exists in runtime" "$RUNTIME_FILE" "LOGO"
require_grep "7-12.6.26 Mikro provider exists in runtime" "$RUNTIME_FILE" "MIKRO"
require_grep "7-12.6.27 Zirve provider exists in runtime" "$RUNTIME_FILE" "ZIRVE"

require_grep "7-12.6.28 real billing gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_BILLING_LIVE_MODULE"
require_grep "7-12.6.29 real provider API gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
require_grep "7-12.6.30 real ERP write gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
require_grep "7-12.6.31 real customer export gate literal exists in runtime" "$RUNTIME_FILE" "CLOSED_UNTIL_EXPORT_LIVE_MODULE"

require_grep "7-12.6.32 no real billing policy implemented" "$RUNTIME_FILE" "NO_REAL_ACCOUNTANT_BILLING_IN_FINAL_CLOSURE"
require_grep "7-12.6.33 no real payment policy implemented" "$RUNTIME_FILE" "NO_REAL_PAYMENT_CAPTURE_IN_FINAL_CLOSURE"
require_grep "7-12.6.34 no real provider API policy implemented" "$RUNTIME_FILE" "NO_REAL_PROVIDER_API_OPERATION_IN_FINAL_CLOSURE"
require_grep "7-12.6.35 no real file delivery policy implemented" "$RUNTIME_FILE" "NO_REAL_FILE_DELIVERY_IN_FINAL_CLOSURE"
require_grep "7-12.6.36 no real ERP write policy implemented" "$RUNTIME_FILE" "NO_REAL_ERP_WRITE_IN_FINAL_CLOSURE"
require_grep "7-12.6.37 no real customer export policy implemented" "$RUNTIME_FILE" "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FINAL_CLOSURE"

require_grep "7-12.6.38 real billing blocker implemented" "$RUNTIME_FILE" "RequestRealAccountantBilling"
require_grep "7-12.6.39 real payment blocker implemented" "$RUNTIME_FILE" "RequestRealPaymentCapture"
require_grep "7-12.6.40 real provider API blocker implemented" "$RUNTIME_FILE" "RequestRealProviderAPI"
require_grep "7-12.6.41 real file delivery blocker implemented" "$RUNTIME_FILE" "RequestRealFileDelivery"
require_grep "7-12.6.42 real ERP write blocker implemented" "$RUNTIME_FILE" "RequestRealERPWrite"
require_grep "7-12.6.43 real customer export blocker implemented" "$RUNTIME_FILE" "RequestRealCustomerDataExport"

require_grep "7-12.6.44 final closure report test exists" "$TEST_FILE" "TestSevenTwelveBuildFinalClosureReport"
require_grep "7-12.6.45 dependency validation test exists" "$TEST_FILE" "TestSevenTwelveDependenciesMustBePassAndSealed"
require_grep "7-12.6.46 provider dry-run set test exists" "$TEST_FILE" "TestSevenTwelveProviderDryRunSetClosedAndSealed"
require_grep "7-12.6.47 live operation blocker test exists" "$TEST_FILE" "TestSevenTwelveLiveOperationBlockers"
require_grep "7-12.6.48 opened live module reject test exists" "$TEST_FILE" "TestSevenTwelveGateRejectsOpenedLiveModule"
require_grep "7-12.6.49 audit trail test exists" "$TEST_FILE" "TestSevenTwelveAuditTrail"

require_grep "7-12.6.50 config module code exists" "$CONFIG_FILE" "\"module_code\": \"FAZ_7_12_ACCOUNTANT_PORTAL_FINAL_CLOSURE\""
require_grep "7-12.6.51 config final closure mode exists" "$CONFIG_FILE" "\"mode\": \"ACCOUNTANT_PORTAL_FINAL_CLOSURE_COMMERCIAL_HANDOFF_GATE\""
require_grep "7-12.6.52 config depends on 7-9 PASS" "$CONFIG_FILE" "\"faz_7_9_accountant_portal_commercial_surface_final_status\": \"PASS\""
require_grep "7-12.6.53 config depends on 7-10 PASS" "$CONFIG_FILE" "\"faz_7_10_accountant_portal_access_runtime_final_status\": \"PASS\""
require_grep "7-12.6.54 config depends on 7-11 PASS" "$CONFIG_FILE" "\"faz_7_11_accountant_portal_reporting_export_preview_final_status\": \"PASS\""
require_grep "7-12.6.55 config provider dry-run set exists" "$CONFIG_FILE" "\"provider_dry_run_set\": \"PARASUT_LOGO_MIKRO_ZIRVE\""
require_grep "7-12.6.56 config commercial handoff gate exists" "$CONFIG_FILE" "\"commercial_handoff_gate\": \"READY_FOR_COMMERCIAL_LIVE_MODULE\""
require_grep "7-12.6.57 config provider live modules not started" "$CONFIG_FILE" "\"provider_live_modules_status\": \"NOT_STARTED\""
require_grep "7-12.6.58 config billing gate closed" "$CONFIG_FILE" "\"real_accountant_billing_status\": \"CLOSED_UNTIL_BILLING_LIVE_MODULE\""
require_grep "7-12.6.59 config provider API gate closed" "$CONFIG_FILE" "\"real_provider_api_status\": \"CLOSED_UNTIL_PROVIDER_LIVE_MODULE\""
require_grep "7-12.6.60 config ERP write gate closed" "$CONFIG_FILE" "\"real_erp_write_status\": \"CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE\""
require_grep "7-12.6.61 config customer export gate closed" "$CONFIG_FILE" "\"real_customer_data_export_live_status\": \"CLOSED_UNTIL_EXPORT_LIVE_MODULE\""

require_grep "7-12.6.62 documentation declares not live opening" "$DOC_FILE" "Bu faz live açılış değildir"
require_grep "7-12.6.63 documentation declares handoff decision" "$DOC_FILE" "Handoff kararı"
require_grep "7-12.6.64 documentation acceptance criteria exists" "$DOC_FILE" "Acceptance criteria"

require_not_grep "7-12.6.65 runtime does not mark commercial live module started" "$RUNTIME_FILE" "CommercialLiveModuleStatus:  \"STARTED\""
require_not_grep "7-12.6.66 runtime does not mark provider live module started" "$RUNTIME_FILE" "ProviderLiveStatus:    \"STARTED\""
require_not_grep "7-12.6.67 runtime does not open real provider API" "$RUNTIME_FILE" "RealProviderAPIStatus: \"OPEN\""
require_not_grep "7-12.6.68 runtime does not open real file delivery" "$RUNTIME_FILE" "RealFileDelivery:      \"OPEN\""
require_not_grep "7-12.6.69 runtime does not open real ERP write" "$RUNTIME_FILE" "RealERPWriteStatus:    \"OPEN\""

if go test ./internal/platform/accountantportal; then
  ok "7-12.6.70 go test verification PASS"
else
  fail "7-12.6.70 go test verification PASS"
fi

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  REAL_IMPLEMENTATION_STATUS="PASS"
else
  REAL_IMPLEMENTATION_STATUS="FAIL"
fi

echo "===== FAZ 7-12 ACCOUNTANT PORTAL FINAL CLOSURE REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"
echo "AUDIT_EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FAZ_7_12_ACCOUNTANT_PORTAL_FINAL_CLOSURE_REAL_IMPLEMENTATION_STATUS=$REAL_IMPLEMENTATION_STATUS"

if [ "$REAL_IMPLEMENTATION_STATUS" = "PASS" ]; then
  exit 0
fi

exit 1
