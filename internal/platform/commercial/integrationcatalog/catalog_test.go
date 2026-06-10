package integrationcatalog

import (
	"os"
	"strings"
	"testing"
)

func TestDefaultCatalog_ProviderCatalogValidation(t *testing.T) {
	c := DefaultCatalog()

	if err := ValidateCatalog(c); err != nil {
		t.Fatalf("expected default catalog to validate: %v", err)
	}

	if c.RealConnectorRuntimeEnabled {
		t.Fatal("real connector runtime must be disabled")
	}
	if c.RealProviderConnectionsEnabled {
		t.Fatal("real provider connections must be disabled")
	}
	if c.RealPaymentLiveStatus != "CLOSED" {
		t.Fatalf("real payment live status must be CLOSED, got %s", c.RealPaymentLiveStatus)
	}
}

func TestDefaultCatalog_IntegrationDomainModelsExist(t *testing.T) {
	c := DefaultCatalog()

	if len(c.Providers) == 0 {
		t.Fatal("expected providers")
	}
	if len(c.Apps) == 0 {
		t.Fatal("expected apps")
	}
	if len(c.Categories) == 0 {
		t.Fatal("expected categories")
	}
	if len(c.Capabilities) == 0 {
		t.Fatal("expected capabilities")
	}
	if len(c.AuthModes) == 0 {
		t.Fatal("expected auth modes")
	}
	if len(c.SyncDirections) == 0 {
		t.Fatal("expected sync directions")
	}
	if len(c.EntitlementRequirements) == 0 {
		t.Fatal("expected entitlement requirements")
	}
}

func TestDefaultCatalog_MarketplaceListingRuntime(t *testing.T) {
	c := DefaultCatalog()

	apps := c.ListAppsByCategory(CatalogCategoryMarketplace)
	if len(apps) < 2 {
		t.Fatalf("expected marketplace apps, got %d", len(apps))
	}

	app, ok := c.FindApp(" app_marketplace_trendyol ")
	if !ok {
		t.Fatal("expected Trendyol marketplace app")
	}

	if app.ProviderCode != "TRENDYOL" {
		t.Fatalf("expected provider TRENDYOL, got %s", app.ProviderCode)
	}
	if app.ModuleCode != "marketplace_trendyol" {
		t.Fatalf("expected module marketplace_trendyol, got %s", app.ModuleCode)
	}
	if app.RequiredPlan != CatalogPlanPro {
		t.Fatalf("expected PRO required plan, got %s", app.RequiredPlan)
	}
	if app.RequiredEntitlement != "marketplace.trendyol" {
		t.Fatalf("unexpected entitlement: %s", app.RequiredEntitlement)
	}
}

func TestDefaultCatalog_CapabilityMatrix(t *testing.T) {
	matrix := CapabilityMatrix()

	required := []Capability{
		CatalogCapabilityReadProducts,
		CatalogCapabilityWriteProducts,
		CatalogCapabilityReadOrders,
		CatalogCapabilityWriteOrders,
		CatalogCapabilityReadCustomers,
		CatalogCapabilityWriteCustomers,
		CatalogCapabilityWebhookIntake,
		CatalogCapabilityFileExport,
		CatalogCapabilityAPISync,
		CatalogCapabilityManualImport,
	}

	for _, cap := range required {
		if _, ok := matrix[cap]; !ok {
			t.Fatalf("expected capability matrix to include %s", cap)
		}
	}

	c := DefaultCatalog()
	if !c.ProviderSupportsCapability("TRENDYOL", CatalogCapabilityReadProducts) {
		t.Fatal("expected Trendyol to support READ_PRODUCTS")
	}
	if !c.AppSupportsCapability("app_marketplace_trendyol", CatalogCapabilityWebhookIntake) {
		t.Fatal("expected Trendyol app to support WEBHOOK_INTAKE")
	}
}

func TestDefaultCatalog_TenantInstallStatusAndSafeInstallKey(t *testing.T) {
	c := DefaultCatalog()

	install, err := c.PrepareTenantInstall("tenant_7", "app_marketplace_trendyol", CatalogPlanPro, []string{"marketplace.trendyol"})
	if err != nil {
		t.Fatalf("expected install readiness: %v", err)
	}

	if install.Status != CatalogTenantIntegrationPendingConfig {
		t.Fatalf("expected PENDING_CONFIG, got %s", install.Status)
	}

	expectedKey := "tenant:tenant_7|provider:trendyol|app:app_marketplace_trendyol"
	if install.InstallKey != expectedKey {
		t.Fatalf("unexpected install key: %s", install.InstallKey)
	}

	if err := ValidateTenantInstall(install); err != nil {
		t.Fatalf("expected tenant install to validate: %v", err)
	}
}

func TestDefaultCatalog_TenantInstallBlockedWhenEntitlementMissing(t *testing.T) {
	c := DefaultCatalog()

	install, err := c.PrepareTenantInstall("tenant_7", "app_marketplace_trendyol", CatalogPlanPro, []string{})
	if err != nil {
		t.Fatalf("expected blocked install without error: %v", err)
	}

	if install.Status != CatalogTenantIntegrationBlocked {
		t.Fatalf("expected BLOCKED, got %s", install.Status)
	}
}

func TestDefaultCatalog_EntitlementGate(t *testing.T) {
	c := DefaultCatalog()

	if !c.IsAppAllowedByPlanAndEntitlements("app_accounting_logo_export", CatalogPlanStarter, []string{"accounting.logo_export"}) {
		t.Fatal("expected starter plan with logo export entitlement to be allowed")
	}

	if c.IsAppAllowedByPlanAndEntitlements("app_public_api_platform", CatalogPlanPro, []string{"integration.public_api"}) {
		t.Fatal("expected PRO plan to be denied for ENTERPRISE public API")
	}

	if c.IsAppAllowedByPlanAndEntitlements("app_marketplace_trendyol", CatalogPlanPro, []string{"wrong.feature"}) {
		t.Fatal("expected missing entitlement to be denied")
	}

	e, ok := c.EntitlementForApp("app_marketplace_trendyol")
	if !ok {
		t.Fatal("expected entitlement mapping for Trendyol app")
	}
	if e.FeatureCode != "marketplace.trendyol" {
		t.Fatalf("unexpected feature code: %s", e.FeatureCode)
	}
}

func TestValidateCatalog_DuplicateProviderCodeReject(t *testing.T) {
	c := DefaultCatalog()
	c.Providers = append(c.Providers, c.Providers[0])

	if err := ValidateCatalog(c); err == nil {
		t.Fatal("expected duplicate provider_code reject")
	}
}

func TestValidateCatalog_DuplicateAppCodeReject(t *testing.T) {
	c := DefaultCatalog()
	c.Apps = append(c.Apps, c.Apps[0])

	if err := ValidateCatalog(c); err == nil {
		t.Fatal("expected duplicate app_code reject")
	}
}

func TestValidateCatalog_UnsupportedCapabilityReject(t *testing.T) {
	c := DefaultCatalog()
	c.Providers[0].Capabilities = append(c.Providers[0].Capabilities, Capability("UNSUPPORTED_CAPABILITY"))

	if err := ValidateCatalog(c); err == nil {
		t.Fatal("expected unsupported capability reject")
	}
}

func TestValidateCatalog_UnsupportedAuthModeReject(t *testing.T) {
	c := DefaultCatalog()
	c.Providers[0].AuthModes = append(c.Providers[0].AuthModes, AuthMode("UNSUPPORTED_AUTH"))

	if err := ValidateCatalog(c); err == nil {
		t.Fatal("expected unsupported auth mode reject")
	}
}

func TestValidateCatalog_UnsupportedSyncDirectionReject(t *testing.T) {
	c := DefaultCatalog()
	c.Providers[0].SyncDirections = append(c.Providers[0].SyncDirections, SyncDirection("UNSUPPORTED_DIRECTION"))

	if err := ValidateCatalog(c); err == nil {
		t.Fatal("expected unsupported sync direction reject")
	}
}

func TestValidateCatalog_ProviderProductionGateClosed(t *testing.T) {
	c := DefaultCatalog()
	c.Providers[0].ProductionGate = CatalogProductionGateOpen

	if err := ValidateCatalog(c); err == nil {
		t.Fatal("expected production gate open before production-ready to fail")
	}
}

func TestTenantInstallKeyRejectsUnsafeTenantID(t *testing.T) {
	c := DefaultCatalog()

	_, err := c.PrepareTenantInstall("tenant 7 unsafe", "app_marketplace_trendyol", CatalogPlanPro, []string{"marketplace.trendyol"})
	if err == nil {
		t.Fatal("expected unsafe tenant id to be rejected")
	}
}

func TestValidateTenantInstallRejectsKeyMismatch(t *testing.T) {
	install := TenantIntegrationInstall{
		TenantID:     "tenant_7",
		ProviderCode: "TRENDYOL",
		AppCode:      "app_marketplace_trendyol",
		Status:       CatalogTenantIntegrationInstalled,
		InstallKey:   "wrong-key",
	}

	if err := ValidateTenantInstall(install); err == nil {
		t.Fatal("expected key mismatch reject")
	}
}

func TestLoadFromJSON_ConfigArtifactValidates(t *testing.T) {
	data, err := os.ReadFile("../../../../configs/faz7/marketplace_integration_catalog.v1.json")
	if err != nil {
		t.Fatalf("expected config artifact to be readable: %v", err)
	}

	c, err := LoadFromJSON(data)
	if err != nil {
		t.Fatalf("expected config artifact to validate: %v", err)
	}

	if c.Version != "marketplace_integration_catalog.v1" {
		t.Fatalf("unexpected version: %s", c.Version)
	}

	if _, ok := c.FindProvider("PAYMENT_PROVIDER_HANDOFF"); !ok {
		t.Fatal("expected payment provider handoff provider")
	}

	if _, ok := c.FindApp("app_payment_provider_handoff"); !ok {
		t.Fatal("expected payment provider handoff app")
	}
}

func TestSortedCapabilityCodes(t *testing.T) {
	codes := SortedCapabilityCodes()
	if len(codes) != len(SupportedCapabilities()) {
		t.Fatalf("unexpected capability code count: %d", len(codes))
	}

	joined := strings.Join(codes, ",")
	for _, expected := range []string{"READ_PRODUCTS", "WRITE_PRODUCTS", "WEBHOOK_INTAKE", "FILE_EXPORT", "API_SYNC", "MANUAL_IMPORT"} {
		if !strings.Contains(joined, expected) {
			t.Fatalf("expected %s in sorted capability codes", expected)
		}
	}
}
