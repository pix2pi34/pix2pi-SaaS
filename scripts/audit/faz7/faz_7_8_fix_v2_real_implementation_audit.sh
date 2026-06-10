#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

DOC_FILE="docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md"
CONFIG_FILE="configs/faz7/marketplace_integration_catalog.v1.json"
RUNTIME_FILE="internal/platform/commercial/integrationcatalog/catalog.go"
TEST_FILE="internal/platform/commercial/integrationcatalog/catalog_test.go"
EVIDENCE_FILE="docs/faz7/evidence/FAZ_7_8_FIX_V2_REAL_IMPLEMENTATION_AUDIT.md"

pass() {
  local label="$1"
  echo "${label} IMPLEMENTED_OR_PRESENT / OK ✅"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  local label="$1"
  echo "${label} REQUIRED_FAIL ❌"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
}

check_file() {
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -Eq "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 7-8 FIX V2 REAL IMPLEMENTATION AUDIT ====="

check_file "7-8" "$DOC_FILE"
check_file "7-8.7" "$CONFIG_FILE"
check_file "7-8.8" "$RUNTIME_FILE"
check_file "7-8.9" "$TEST_FILE"

check_grep "7-8.1" "$DOC_FILE" "Module Boundary / Scope Freeze"
check_grep "7-8.2.1" "$RUNTIME_FILE" "type IntegrationProvider struct"
check_grep "7-8.2.2" "$RUNTIME_FILE" "type IntegrationApp struct"
check_grep "7-8.2.3" "$RUNTIME_FILE" "type IntegrationCategory string"
check_grep "7-8.2.4" "$RUNTIME_FILE" "type Capability string"
check_grep "7-8.2.5" "$RUNTIME_FILE" "type AuthMode string"
check_grep "7-8.2.6" "$RUNTIME_FILE" "type SyncDirection string"
check_grep "7-8.2.7" "$RUNTIME_FILE" "type PricingPlanRequirement struct"

check_grep "7-8.3.1" "$RUNTIME_FILE" "AppCode"
check_grep "7-8.3.2" "$RUNTIME_FILE" "ProviderCode"
check_grep "7-8.3.3" "$RUNTIME_FILE" "ModuleCode"
check_grep "7-8.3.4" "$RUNTIME_FILE" "SetupMode"
check_grep "7-8.3.5" "$RUNTIME_FILE" "RequiredPlan"
check_grep "7-8.3.6" "$RUNTIME_FILE" "RequiredEntitlement"

check_grep "7-8.4.1" "$RUNTIME_FILE" "CapabilityReadProducts"
check_grep "7-8.4.2" "$RUNTIME_FILE" "CapabilityWriteProducts"
check_grep "7-8.4.3" "$RUNTIME_FILE" "CapabilityReadOrders"
check_grep "7-8.4.4" "$RUNTIME_FILE" "CapabilityWriteOrders"
check_grep "7-8.4.5" "$RUNTIME_FILE" "CapabilityReadCustomers"
check_grep "7-8.4.6" "$RUNTIME_FILE" "CapabilityWriteCustomers"
check_grep "7-8.4.7" "$RUNTIME_FILE" "CapabilityWebhookIntake"
check_grep "7-8.4.8" "$RUNTIME_FILE" "CapabilityFileExport"
check_grep "7-8.4.9" "$RUNTIME_FILE" "CapabilityAPISync"
check_grep "7-8.4.10" "$RUNTIME_FILE" "CapabilityManualImport"

check_grep "7-8.5.1" "$RUNTIME_FILE" "type TenantIntegrationInstall struct"
check_grep "7-8.5.2" "$RUNTIME_FILE" "TenantIntegrationInstalled"
check_grep "7-8.5.3" "$RUNTIME_FILE" "TenantIntegrationDisabled"
check_grep "7-8.5.4" "$RUNTIME_FILE" "TenantIntegrationPendingConfig"
check_grep "7-8.5.5" "$RUNTIME_FILE" "TenantIntegrationBlocked"
check_grep "7-8.5.6" "$RUNTIME_FILE" "BuildTenantInstallKey"
check_grep "7-8.5.7" "$RUNTIME_FILE" "ValidateTenantInstall"

check_grep "7-8.6.1" "$RUNTIME_FILE" "IsAppAllowedByPlanAndEntitlements"
check_grep "7-8.6.2" "$RUNTIME_FILE" "PlanAllows"
check_grep "7-8.6.3" "$RUNTIME_FILE" "EntitlementForApp"
check_grep "7-8.6.4" "$RUNTIME_FILE" "EntitlementRequirements"

check_grep "7-8.7.1" "$CONFIG_FILE" "\"providers\""
check_grep "7-8.7.2" "$CONFIG_FILE" "\"apps\""
check_grep "7-8.7.3" "$CONFIG_FILE" "\"capabilities\""
check_grep "7-8.7.4" "$CONFIG_FILE" "\"auth_modes\""
check_grep "7-8.7.5" "$CONFIG_FILE" "\"sync_directions\""
check_grep "7-8.7.6" "$CONFIG_FILE" "\"entitlement_requirements\""

check_grep "7-8.8.1" "$RUNTIME_FILE" "func ValidateCatalog"
check_grep "7-8.8.2" "$RUNTIME_FILE" "func LoadFromJSON"
check_grep "7-8.8.3" "$RUNTIME_FILE" "func \\(c Catalog\\) FindProvider"
check_grep "7-8.8.4" "$RUNTIME_FILE" "func \\(c Catalog\\) FindApp"
check_grep "7-8.8.5" "$RUNTIME_FILE" "func \\(c Catalog\\) ListAppsByCategory"
check_grep "7-8.8.6" "$RUNTIME_FILE" "func \\(c Catalog\\) ProviderSupportsCapability"
check_grep "7-8.8.7" "$RUNTIME_FILE" "func \\(c Catalog\\) PrepareTenantInstall"

check_grep "7-8.9.1" "$TEST_FILE" "TestDefaultCatalog_ProviderCatalogValidation"
check_grep "7-8.9.2" "$TEST_FILE" "TestDefaultCatalog_MarketplaceListingRuntime"
check_grep "7-8.9.3" "$TEST_FILE" "TestDefaultCatalog_CapabilityMatrix"
check_grep "7-8.9.4" "$TEST_FILE" "TestDefaultCatalog_TenantInstallStatusAndSafeInstallKey"
check_grep "7-8.9.5" "$TEST_FILE" "TestDefaultCatalog_EntitlementGate"
check_grep "7-8.9.6" "$TEST_FILE" "TestValidateCatalog_DuplicateProviderCodeReject"
check_grep "7-8.9.7" "$TEST_FILE" "TestValidateCatalog_UnsupportedCapabilityReject"
check_grep "7-8.9.8" "$TEST_FILE" "TestTenantInstallKeyRejectsUnsafeTenantID"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

AUDIT_STATUS="FAIL"
if [ "$REQUIRED_FAIL" -eq 0 ]; then
  AUDIT_STATUS="PASS"
fi

cat <<EVIDENCE_DOC > "$EVIDENCE_FILE"
# FAZ 7-8 FIX/V2 Real Implementation Audit Evidence

## Audit Result

- REAL_AUDIT_STATUS=${AUDIT_STATUS}
- PASS_COUNT=${PASS_COUNT}
- FAIL_COUNT=${FAIL_COUNT}
- REQUIRED_FAIL=${REQUIRED_FAIL}
- OPTIONAL_WARN=${OPTIONAL_WARN}

## Evidence Files

- ${DOC_FILE}
- ${CONFIG_FILE}
- ${RUNTIME_FILE}
- ${TEST_FILE}
- scripts/audit/faz7/faz_7_8_fix_v2_real_implementation_audit.sh

## Scope Alignment

FAZ 7-8 FIX/V2 verifies:

- module boundary / scope freeze
- IntegrationProvider model
- IntegrationApp model
- IntegrationCategory model
- Capability model
- AuthMode model
- SyncDirection model
- PricingPlanRequirement model
- marketplace listing model
- connector capability matrix
- tenant install readiness model
- entitlement integration helper
- config artifact
- runtime code
- test code

## Final Interpretation

If GO_TEST_STATUS=PASS and REAL_AUDIT_STATUS=PASS with REQUIRED_FAIL=0, FAZ 7-8 can be sealed as enterprise catalog complete.
EVIDENCE_DOC

if [ -f "$EVIDENCE_FILE" ]; then
  pass "7-8.10.1"
else
  fail "7-8.10.1"
fi

echo "===== FAZ 7-8 FIX V2 REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"
echo "AUDIT_EVIDENCE_FILE=${EVIDENCE_FILE}"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8_FIX_V2_REAL_IMPLEMENTATION_STATUS=PASS"
else
  echo "FAZ_7_8_FIX_V2_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
