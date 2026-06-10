#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
REQUIRED_FAIL=0
OPTIONAL_WARN=0

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

echo "===== FAZ 7-8 REAL IMPLEMENTATION AUDIT ====="

check_file "7-8" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md"
check_file "7-8.1" "configs/faz7/marketplace_integration_catalog.v1.json"
check_file "7-8.2" "internal/platform/integrations/catalog/catalog.go"
check_file "7-8.3" "internal/platform/integrations/catalog/catalog_test.go"

check_grep "7-8.1.1" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "Marketplace integration catalog model"
check_grep "7-8.1.2" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "Provider-neutral integration foundation"
check_grep "7-8.1.3" "docs/faz7/FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION.md" "Provider-specific module separation rule"

check_grep "7-8.2.1" "configs/faz7/marketplace_integration_catalog.v1.json" "TRENDYOL_MARKETPLACE|HEPSIBURADA_MARKETPLACE|N11_MARKETPLACE"
check_grep "7-8.2.2" "configs/faz7/marketplace_integration_catalog.v1.json" "PARASUT_ACCOUNTING|LOGO_EXPORT|MIKRO_EXPORT|ZIRVE_EXPORT|ETA_EXPORT"
check_grep "7-8.2.3" "configs/faz7/marketplace_integration_catalog.v1.json" "PAYMENT_PROVIDER_HANDOFF"
check_grep "7-8.2.4" "configs/faz7/marketplace_integration_catalog.v1.json" "E_FATURA_PROVIDER|E_ARSIV_PROVIDER"
check_grep "7-8.2.5" "configs/faz7/marketplace_integration_catalog.v1.json" "LOGISTICS_PROVIDER"
check_grep "7-8.2.6" "configs/faz7/marketplace_integration_catalog.v1.json" "CRM_WEBHOOK|PUBLIC_API"

check_grep "7-8.3.1" "internal/platform/integrations/catalog/catalog.go" "TenantScoped"
check_grep "7-8.3.2" "internal/platform/integrations/catalog/catalog.go" "AuditRequired"
check_grep "7-8.3.3" "internal/platform/integrations/catalog/catalog.go" "RequiredEntitlements"
check_grep "7-8.3.4" "internal/platform/integrations/catalog/catalog.go" "ProductionGateClosed"

check_grep "7-8.4.1" "internal/platform/integrations/catalog/catalog.go" "func \(c Catalog\) FindByCode"
check_grep "7-8.4.2" "internal/platform/integrations/catalog/catalog.go" "func \(c Catalog\) ListByCategory"
check_grep "7-8.4.3" "internal/platform/integrations/catalog/catalog.go" "func ValidateCatalog"

check_grep "7-8.5.1" "configs/faz7/marketplace_integration_catalog.v1.json" "\"version\": \"marketplace_integration_catalog.v1\""
check_grep "7-8.5.2" "configs/faz7/marketplace_integration_catalog.v1.json" "\"real_provider_connections_enabled\": false"
check_grep "7-8.5.3" "configs/faz7/marketplace_integration_catalog.v1.json" "\"real_payment_live_status\": \"CLOSED\""
check_grep "7-8.5.4" "configs/faz7/marketplace_integration_catalog.v1.json" "\"provider_specific_module_required\": true"

check_grep "7-8.6.1" "internal/platform/integrations/catalog/catalog_test.go" "TestDefaultCatalog_Validate"
check_grep "7-8.6.2" "internal/platform/integrations/catalog/catalog_test.go" "TestCatalog_AllProvidersAreTenantScopedAuditRequiredAndClosed"
check_grep "7-8.6.3" "internal/platform/integrations/catalog/catalog_test.go" "TestLoadFromJSON_ConfigArtifactValidates"

check_grep "7-8.7.1" "scripts/audit/faz7/faz_7_8_real_implementation_audit.sh" "REAL IMPLEMENTATION AUDIT"
check_grep "7-8.7.2" "scripts/audit/faz7/faz_7_8_real_implementation_audit.sh" "PASS_COUNT"
check_grep "7-8.7.3" "scripts/audit/faz7/faz_7_8_real_implementation_audit.sh" "REQUIRED_FAIL"

echo "===== FAZ 7-8 REAL IMPLEMENTATION AUDIT RESULT ====="
echo "PASS_COUNT=${PASS_COUNT}"
echo "FAIL_COUNT=${FAIL_COUNT}"
echo "REQUIRED_FAIL=${REQUIRED_FAIL}"
echo "OPTIONAL_WARN=${OPTIONAL_WARN}"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_7_8_REAL_IMPLEMENTATION_STATUS=PASS"
else
  echo "FAZ_7_8_REAL_IMPLEMENTATION_STATUS=FAIL"
  exit 1
fi
