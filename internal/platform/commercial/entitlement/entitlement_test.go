package entitlement

import (
	"testing"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
)

func mustRuntime(t *testing.T) *Runtime {
	t.Helper()

	runtime, err := NewDefaultRuntime()
	if err != nil {
		t.Fatalf("expected runtime to initialize, got error: %v", err)
	}

	return runtime
}

func TestRuntime_CheckFeature_AllowsIncludedFeature(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckFeature(RuntimeContext{
		TenantID: "tenant_7",
		UserID:   "user_1",
		Plan:     catalog.PlanPro,
	}, catalog.FeatureMarketplaceDiscovery)

	if decision.Status != DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.ReasonCode != ReasonAllowFeatureIncluded {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckFeature_DeniesMissingFeature(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckFeature(RuntimeContext{
		TenantID: "tenant_7",
		UserID:   "user_1",
		Plan:     catalog.PlanStarter,
	}, catalog.FeatureAPIAccessAdvanced)

	if decision.Status != DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != ReasonDenyFeatureMissing {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckFeature_RequiresTenantID(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckFeature(RuntimeContext{
		UserID: "user_1",
		Plan:   catalog.PlanPro,
	}, catalog.FeatureERPCore)

	if decision.Status != DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != ReasonDenyTenantRequired {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckFeature_RequiresUserID(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckFeature(RuntimeContext{
		TenantID: "tenant_7",
		Plan:     catalog.PlanPro,
	}, catalog.FeatureERPCore)

	if decision.Status != DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != ReasonDenyUserRequired {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckFeature_RequiresPlanCode(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckFeature(RuntimeContext{
		TenantID: "tenant_7",
		UserID:   "user_1",
	}, catalog.FeatureERPCore)

	if decision.Status != DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != ReasonDenyPlanRequired {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckLimit_AllowsWithinLimit(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckLimit(RuntimeContext{
		TenantID: "tenant_7",
		UserID:   "user_1",
		Plan:     catalog.PlanStarter,
	}, catalog.LimitMonthlyExports, 9, 1)

	if decision.Status != DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.NextUsage != 10 {
		t.Fatalf("expected next usage 10, got %d", decision.NextUsage)
	}
}

func TestRuntime_CheckLimit_DeniesExceededLimit(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckLimit(RuntimeContext{
		TenantID: "tenant_7",
		UserID:   "user_1",
		Plan:     catalog.PlanStarter,
	}, catalog.LimitMonthlyExports, 10, 1)

	if decision.Status != DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != ReasonDenyLimitExceeded {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckFeatureAndLimit_AllowsFeatureAndLimit(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckFeatureAndLimit(RuntimeContext{
		TenantID: "tenant_7",
		UserID:   "user_1",
		Plan:     catalog.PlanMarketplace,
	}, catalog.FeatureWebhookAccess, catalog.LimitIntegrations, 24, 1)

	if decision.Status != DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.FeatureCode != catalog.FeatureWebhookAccess {
		t.Fatalf("expected feature code to be attached")
	}
}

func TestRuntime_CheckFeatureAndLimit_DeniesIfFeatureMissing(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckFeatureAndLimit(RuntimeContext{
		TenantID: "tenant_7",
		UserID:   "user_1",
		Plan:     catalog.PlanStarter,
	}, catalog.FeatureWebhookAccess, catalog.LimitIntegrations, 0, 1)

	if decision.Status != DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != ReasonDenyFeatureMissing {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckFeature_UnknownPlan(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckFeature(RuntimeContext{
		TenantID: "tenant_7",
		UserID:   "user_1",
		Plan:     catalog.PlanCode("unknown"),
	}, catalog.FeatureERPCore)

	if decision.Status != DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != ReasonDenyPlanUnknown {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}
