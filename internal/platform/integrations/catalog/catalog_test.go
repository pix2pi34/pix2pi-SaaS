package catalog

import (
	"os"
	"testing"
)

func TestDefaultCatalog_Validate(t *testing.T) {
	c := DefaultCatalog()

	if err := ValidateCatalog(c); err != nil {
		t.Fatalf("expected default catalog to validate, got: %v", err)
	}

	if c.RealProviderConnectionsEnabled {
		t.Fatal("real provider connections must be disabled in FAZ 7-8")
	}

	if c.RealPaymentLiveStatus != "CLOSED" {
		t.Fatalf("real payment live status must be CLOSED, got %s", c.RealPaymentLiveStatus)
	}

	if !c.ProviderSpecificModuleRequired {
		t.Fatal("provider specific module rule must be enabled")
	}
}

func TestDefaultCatalog_ContainsMarketplaceAccountingPaymentAndPublicAPI(t *testing.T) {
	c := DefaultCatalog()

	requiredCodes := []string{
		"TRENDYOL_MARKETPLACE",
		"HEPSIBURADA_MARKETPLACE",
		"N11_MARKETPLACE",
		"PARASUT_ACCOUNTING",
		"LOGO_EXPORT",
		"MIKRO_EXPORT",
		"ZIRVE_EXPORT",
		"ETA_EXPORT",
		"PAYMENT_PROVIDER_HANDOFF",
		"E_FATURA_PROVIDER",
		"E_ARSIV_PROVIDER",
		"LOGISTICS_PROVIDER",
		"CRM_WEBHOOK",
		"PUBLIC_API",
	}

	for _, code := range requiredCodes {
		if _, ok := c.FindByCode(code); !ok {
			t.Fatalf("expected provider code %s in default catalog", code)
		}
	}
}

func TestCatalog_FindByCode_IsCaseAndWhitespaceSafe(t *testing.T) {
	c := DefaultCatalog()

	p, ok := c.FindByCode("  trendyol_marketplace  ")
	if !ok {
		t.Fatal("expected case-insensitive provider lookup to work")
	}

	if p.Category != CategoryMarketplace {
		t.Fatalf("expected marketplace category, got %s", p.Category)
	}
}

func TestCatalog_ListByCategory(t *testing.T) {
	c := DefaultCatalog()

	marketplaceProviders := c.ListByCategory(CategoryMarketplace)
	if len(marketplaceProviders) < 3 {
		t.Fatalf("expected at least 3 marketplace providers, got %d", len(marketplaceProviders))
	}

	accountingProviders := c.ListByCategory(CategoryAccountingExport)
	if len(accountingProviders) < 5 {
		t.Fatalf("expected at least 5 accounting/export providers, got %d", len(accountingProviders))
	}
}

func TestCatalog_AllProvidersAreTenantScopedAuditRequiredAndClosed(t *testing.T) {
	c := DefaultCatalog()

	for _, p := range c.Providers {
		if !p.TenantScoped {
			t.Fatalf("provider %s must be tenant scoped", p.Code)
		}
		if !p.AuditRequired {
			t.Fatalf("provider %s must be audit required", p.Code)
		}
		if p.ProductionGate != ProductionGateClosed {
			t.Fatalf("provider %s production gate must be closed", p.Code)
		}
		if len(p.RequiredEntitlements) == 0 {
			t.Fatalf("provider %s must have required entitlements", p.Code)
		}
	}
}

func TestCatalog_ProductionCandidatesEmptyInFoundation(t *testing.T) {
	c := DefaultCatalog()

	candidates := c.ProductionCandidates()
	if len(candidates) != 0 {
		t.Fatalf("expected no production candidates in FAZ 7-8, got %d", len(candidates))
	}
}

func TestCatalog_ProviderSpecificModuleRequiredForExternalCriticalProviders(t *testing.T) {
	c := DefaultCatalog()

	codes := []string{
		"TRENDYOL_MARKETPLACE",
		"HEPSIBURADA_MARKETPLACE",
		"N11_MARKETPLACE",
		"PAYMENT_PROVIDER_HANDOFF",
		"E_FATURA_PROVIDER",
		"E_ARSIV_PROVIDER",
		"LOGISTICS_PROVIDER",
	}

	for _, code := range codes {
		p, ok := c.FindByCode(code)
		if !ok {
			t.Fatalf("provider %s not found", code)
		}
		if !p.RequiresProviderSpecificModule() {
			t.Fatalf("provider %s must require provider-specific module", code)
		}
	}
}

func TestValidateCatalog_DuplicateCodeFails(t *testing.T) {
	c := DefaultCatalog()
	c.Providers = append(c.Providers, c.Providers[0])

	if err := ValidateCatalog(c); err == nil {
		t.Fatal("expected duplicate provider code validation failure")
	}
}

func TestValidateCatalog_TenantScopedRequired(t *testing.T) {
	c := DefaultCatalog()
	c.Providers[0].TenantScoped = false

	if err := ValidateCatalog(c); err == nil {
		t.Fatal("expected tenant scoped validation failure")
	}
}

func TestValidateCatalog_AuditRequired(t *testing.T) {
	c := DefaultCatalog()
	c.Providers[0].AuditRequired = false

	if err := ValidateCatalog(c); err == nil {
		t.Fatal("expected audit required validation failure")
	}
}

func TestValidateCatalog_ProductionGateOpenRequiresProductionReady(t *testing.T) {
	c := DefaultCatalog()
	c.Providers[0].ProductionGate = ProductionGateOpen

	if err := ValidateCatalog(c); err == nil {
		t.Fatal("expected production gate validation failure")
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
		t.Fatalf("unexpected config version: %s", c.Version)
	}

	if _, ok := c.FindByCode("PAYMENT_PROVIDER_HANDOFF"); !ok {
		t.Fatal("expected payment provider handoff in config artifact")
	}
}
