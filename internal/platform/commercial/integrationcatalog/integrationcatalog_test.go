package integrationcatalog

import (
	"testing"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
)

func mustRuntime(t *testing.T) *Runtime {
	t.Helper()

	runtime, err := NewDefaultRuntime()
	if err != nil {
		t.Fatalf("expected runtime to initialize, got error: %v", err)
	}

	return runtime
}

func baseContext(plan catalog.PlanCode) RuntimeContext {
	return RuntimeContext{
		TenantID: "tenant_7",
		UserID:   "user_1",
		Plan:     plan,
	}
}

func TestRuntime_Validate(t *testing.T) {
	runtime := mustRuntime(t)

	if err := runtime.Validate(); err != nil {
		t.Fatalf("expected runtime to validate, got error: %v", err)
	}
}

func TestRuntime_RequiredIntegrationsExist(t *testing.T) {
	runtime := mustRuntime(t)

	required := []IntegrationCode{
		IntegrationParasut,
		IntegrationMarketplaceDiscovery,
		IntegrationMarketplaceOrders,
		IntegrationMarketplaceStockSync,
		IntegrationWebhook,
		IntegrationPublicAPI,
		IntegrationTDHPExport,
		IntegrationAccountantPortalBridge,
	}

	for _, code := range required {
		if _, ok := runtime.Integration(code); !ok {
			t.Fatalf("expected integration to exist: %s", code)
		}
	}
}

func TestRuntime_ListByCategory(t *testing.T) {
	runtime := mustRuntime(t)

	marketplaceIntegrations := runtime.ListByCategory(CategoryMarketplace)

	if len(marketplaceIntegrations) < 3 {
		t.Fatalf("expected at least 3 marketplace integrations, got %d", len(marketplaceIntegrations))
	}
}

func TestRuntime_CheckAccess_AllowsEnterpriseParasut(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanEnterprise), IntegrationParasut)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.IntegrationCode != IntegrationParasut {
		t.Fatalf("expected parasut integration, got %s", decision.IntegrationCode)
	}
}

func TestRuntime_CheckAccess_DeniesStarterParasut(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanStarter), IntegrationParasut)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyFeatureMissing) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_AllowsProMarketplaceDiscovery(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanPro), IntegrationMarketplaceDiscovery)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_AllowsMarketplaceWebhook(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanMarketplace), IntegrationWebhook)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_AllowsAccountantTDHPExport(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanAccountant), IntegrationTDHPExport)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_RequiresTenant(t *testing.T) {
	runtime := mustRuntime(t)

	ctx := baseContext(catalog.PlanEnterprise)
	ctx.TenantID = ""

	decision := runtime.CheckAccess(ctx, IntegrationParasut)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyTenantRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_RequiresUser(t *testing.T) {
	runtime := mustRuntime(t)

	ctx := baseContext(catalog.PlanEnterprise)
	ctx.UserID = ""

	decision := runtime.CheckAccess(ctx, IntegrationParasut)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyUserRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_DeniesUnknownPlan(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanCode("unknown")), IntegrationParasut)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyPlanUnknown) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckAccess_DeniesUnknownIntegration(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccess(baseContext(catalog.PlanEnterprise), IntegrationCode("unknown"))

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyIntegrationUnknown) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckIntegrationLimit_AllowsWithinLimit(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckIntegrationLimit(baseContext(catalog.PlanMarketplace), IntegrationWebhook, 24, 1)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.NextUsage != 25 {
		t.Fatalf("expected next usage 25, got %d", decision.NextUsage)
	}
}

func TestRuntime_CheckIntegrationLimit_DeniesExceededLimit(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckIntegrationLimit(baseContext(catalog.PlanMarketplace), IntegrationWebhook, 25, 1)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyLimitExceeded) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckAccessAndLimit_Allows(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccessAndLimit(baseContext(catalog.PlanMarketplace), IntegrationWebhook, 24, 1)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.IntegrationCode != IntegrationWebhook {
		t.Fatalf("expected webhook integration, got %s", decision.IntegrationCode)
	}
}

func TestRuntime_CheckAccessAndLimit_DeniesFeatureFirst(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckAccessAndLimit(baseContext(catalog.PlanStarter), IntegrationWebhook, 0, 1)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyFeatureMissing) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}
