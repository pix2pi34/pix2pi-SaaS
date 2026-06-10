package subscription

import (
	"testing"
	"time"

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

func baseAccount(now time.Time) Account {
	return Account{
		TenantID: "tenant_7",
		AccountID: "account_7",
		Plan: catalog.PlanPro,
		Status: StatusActive,
		CurrentPeriodStart: now.Add(-24 * time.Hour),
		CurrentPeriodEnd: now.Add(30 * 24 * time.Hour),
		CurrentUsers: 5,
		CurrentTenants: 1,
		CurrentAPIRequests: 100,
		CurrentExports: 10,
		CurrentIntegrations: 1,
	}
}

func TestRuntime_StartTrial(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account, decision := runtime.StartTrial("tenant_7", "account_7", catalog.PlanStarter, now, 14 * 24 * time.Hour)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if account.Status != StatusTrialing {
		t.Fatalf("expected trialing, got %s", account.Status)
	}
	if account.TrialEndsAt.IsZero() {
		t.Fatal("expected trial end date")
	}
}

func TestRuntime_Activate(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Status = StatusTrialing
	account.TrialEndsAt = now.Add(7 * 24 * time.Hour)

	activated, decision := runtime.Activate(account, now, 30 * 24 * time.Hour)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s", decision.Status)
	}
	if activated.Status != StatusActive {
		t.Fatalf("expected active, got %s", activated.Status)
	}
	if !activated.TrialEndsAt.IsZero() {
		t.Fatal("expected trial end to be cleared after activation")
	}
}

func TestRuntime_ChangePlan(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)

	changed, decision := runtime.ChangePlan(account, catalog.PlanEnterprise)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s", decision.Status)
	}
	if changed.Plan != catalog.PlanEnterprise {
		t.Fatalf("expected enterprise plan, got %s", changed.Plan)
	}
}

func TestRuntime_ChangePlan_DeniesUnknownPlan(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)

	_, decision := runtime.ChangePlan(account, catalog.PlanCode("unknown"))

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyPlanUnknown) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_SuspendAndResume(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)

	suspended, suspendDecision := runtime.Suspend(account)
	if suspendDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected suspend allow, got %s", suspendDecision.Status)
	}
	if suspended.Status != StatusSuspended {
		t.Fatalf("expected suspended, got %s", suspended.Status)
	}

	resumed, resumeDecision := runtime.Resume(suspended)
	if resumeDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected resume allow, got %s", resumeDecision.Status)
	}
	if resumed.Status != StatusActive {
		t.Fatalf("expected active, got %s", resumed.Status)
	}
}

func TestRuntime_CancelCannotResume(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)

	canceled, cancelDecision := runtime.Cancel(account)
	if cancelDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected cancel allow, got %s", cancelDecision.Status)
	}

	_, resumeDecision := runtime.Resume(canceled)
	if resumeDecision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected resume deny, got %s", resumeDecision.Status)
	}
	if resumeDecision.ReasonCode != string(ReasonDenyCanceled) {
		t.Fatalf("unexpected reason: %s", resumeDecision.ReasonCode)
	}
}

func TestRuntime_Renew(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.CurrentAPIRequests = 200
	account.CurrentExports = 20

	renewed, decision := runtime.Renew(account, now, 30 * 24 * time.Hour)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s", decision.Status)
	}
	if renewed.Status != StatusActive {
		t.Fatalf("expected active, got %s", renewed.Status)
	}
	if renewed.CurrentAPIRequests != 0 {
		t.Fatalf("expected api usage reset, got %d", renewed.CurrentAPIRequests)
	}
	if renewed.CurrentExports != 0 {
		t.Fatalf("expected export usage reset, got %d", renewed.CurrentExports)
	}
}

func TestRuntime_CheckFeature_AllowsActiveSubscription(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)

	decision := runtime.CheckFeature(account, "user_1", catalog.FeatureMarketplaceDiscovery, now)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
}

func TestRuntime_CheckFeature_DeniesSuspendedSubscription(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Status = StatusSuspended

	decision := runtime.CheckFeature(account, "user_1", catalog.FeatureMarketplaceDiscovery, now)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenySuspended) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckFeature_DeniesExpiredTrial(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Status = StatusTrialing
	account.TrialEndsAt = now.Add(-1 * time.Hour)

	decision := runtime.CheckFeature(account, "user_1", catalog.FeatureERPCore, now)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyTrialExpired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckLimit_AllowsWithinSubscriptionPlanLimit(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Plan = catalog.PlanStarter

	decision := runtime.CheckLimit(account, "user_1", catalog.LimitMonthlyExports, 9, 1, now)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.NextUsage != 10 {
		t.Fatalf("expected next usage 10, got %d", decision.NextUsage)
	}
}

func TestRuntime_CheckLimit_DeniesExceededSubscriptionPlanLimit(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Plan = catalog.PlanStarter

	decision := runtime.CheckLimit(account, "user_1", catalog.LimitMonthlyExports, 10, 1, now)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(entitlement.ReasonDenyLimitExceeded) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CheckFeatureAndLimit(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Plan = catalog.PlanMarketplace

	decision := runtime.CheckFeatureAndLimit(
		account,
		"user_1",
		catalog.FeatureWebhookAccess,
		catalog.LimitIntegrations,
		24,
		1,
		now,
	)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.FeatureCode != catalog.FeatureWebhookAccess {
		t.Fatal("expected feature code to be attached")
	}
}
