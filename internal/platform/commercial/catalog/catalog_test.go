package catalog

import "testing"

func TestDefaultCatalog_Validate(t *testing.T) {
	c := DefaultCatalog()

	if err := c.Validate(); err != nil {
		t.Fatalf("expected catalog to validate, got error: %v", err)
	}
}

func TestDefaultCatalog_PlansExist(t *testing.T) {
	c := DefaultCatalog()

	requiredPlans := []PlanCode{
		PlanStarter,
		PlanPro,
		PlanEnterprise,
		PlanAccountant,
		PlanMarketplace,
	}

	for _, planCode := range requiredPlans {
		if _, ok := c.Plan(planCode); !ok {
			t.Fatalf("expected plan to exist: %s", planCode)
		}
	}
}

func TestDefaultCatalog_FeatureMatrix(t *testing.T) {
	c := DefaultCatalog()

	if !c.HasFeature(PlanStarter, FeatureERPCore) {
		t.Fatal("starter must have erp_core")
	}

	if c.HasFeature(PlanStarter, FeatureAPIAccessAdvanced) {
		t.Fatal("starter must not have advanced api access")
	}

	if !c.HasFeature(PlanPro, FeatureMarketplaceDiscovery) {
		t.Fatal("pro must have marketplace discovery")
	}

	if !c.HasFeature(PlanEnterprise, FeatureWebhookAccess) {
		t.Fatal("enterprise must have webhook access")
	}
}

func TestDefaultCatalog_AccountantPlan(t *testing.T) {
	c := DefaultCatalog()

	if !c.HasFeature(PlanAccountant, FeatureAccountantPortal) {
		t.Fatal("accountant plan must have accountant portal")
	}

	if !c.HasFeature(PlanAccountant, FeatureMultiCompanyAccess) {
		t.Fatal("accountant plan must have multi company access")
	}

	firms, ok := c.Limit(PlanAccountant, LimitAccountantFirms)
	if !ok {
		t.Fatal("accountant_firms limit missing")
	}
	if firms < 100 {
		t.Fatalf("expected accountant plan to support at least 100 firms, got %d", firms)
	}
}

func TestDefaultCatalog_MarketplacePlan(t *testing.T) {
	c := DefaultCatalog()

	if !c.HasFeature(PlanMarketplace, FeatureIntegrationCatalog) {
		t.Fatal("marketplace plan must have integration catalog")
	}

	if !c.HasFeature(PlanMarketplace, FeatureWebhookAccess) {
		t.Fatal("marketplace plan must have webhook access")
	}

	integrations, ok := c.Limit(PlanMarketplace, LimitIntegrations)
	if !ok {
		t.Fatal("integrations limit missing")
	}
	if integrations < 25 {
		t.Fatalf("expected marketplace plan to support at least 25 integrations, got %d", integrations)
	}
}

func TestDefaultCatalog_Limits(t *testing.T) {
	c := DefaultCatalog()

	starterUsers, ok := c.Limit(PlanStarter, LimitUsers)
	if !ok {
		t.Fatal("starter users limit missing")
	}
	if starterUsers != 3 {
		t.Fatalf("expected starter users limit 3, got %d", starterUsers)
	}

	proAPI, ok := c.Limit(PlanPro, LimitAPIMonthlyRequests)
	if !ok {
		t.Fatal("pro api limit missing")
	}
	if proAPI <= 0 {
		t.Fatalf("expected pro api limit to be positive, got %d", proAPI)
	}

	enterpriseUsers, ok := c.Limit(PlanEnterprise, LimitUsers)
	if !ok {
		t.Fatal("enterprise users limit missing")
	}
	if enterpriseUsers < 250 {
		t.Fatalf("expected enterprise users limit at least 250, got %d", enterpriseUsers)
	}
}
