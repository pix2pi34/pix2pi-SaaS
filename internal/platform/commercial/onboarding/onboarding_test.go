package onboarding

import (
	"testing"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/billing"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/subscription"
)

func mustRuntime(t *testing.T) *Runtime {
	t.Helper()

	runtime, err := NewDefaultRuntime()
	if err != nil {
		t.Fatalf("expected runtime to initialize, got error: %v", err)
	}

	return runtime
}

func baseRequest() Request {
	return Request{
		TenantID: "tenant_7",
		AccountID: "account_7",
		BusinessName: "Pix2pi Pilot",
		LegalName: "Pix2pi Pilot Ltd",
		TaxNumber: "1234567890",
		TaxOffice: "Istanbul",
		BillingEmail: "billing@example.com",
		BillingAddress: "Istanbul Turkiye",
		AdminUserID: "user_admin_7",
		AdminEmail: "admin@example.com",
		Plan: catalog.PlanPro,
		StartMode: StartModeDemoData,
		RequestedAt: time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC),
		TrialDays: 14,
	}
}

func TestRuntime_StartTrialOnboarding_Success(t *testing.T) {
	runtime := mustRuntime(t)

	result, decision := runtime.StartTrialOnboarding(baseRequest())

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.ReasonCode != string(ReasonAllowOnboardingReady) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
	if result.Tenant.Status != TenantStatusActive {
		t.Fatalf("expected tenant active, got %s", result.Tenant.Status)
	}
	if result.AdminUser.Role != AdminRoleTenantAdmin {
		t.Fatalf("expected tenant admin role, got %s", result.AdminUser.Role)
	}
	if result.Subscription.Status != subscription.StatusTrialing {
		t.Fatalf("expected trialing subscription, got %s", result.Subscription.Status)
	}
	if result.InvoiceDraft.BillingStatus != billing.BillingStatusSimulationReady {
		t.Fatalf("expected billing simulation ready, got %s", result.InvoiceDraft.BillingStatus)
	}
	if result.InvoiceDraft.RealPaymentEnabled {
		t.Fatal("real payment must be disabled during onboarding readiness")
	}
}

func TestRuntime_StartTrialOnboarding_BlankStartMode(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.StartMode = StartModeBlank

	result, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s", decision.Status)
	}
	if result.Tenant.StartMode != StartModeBlank {
		t.Fatalf("expected blank start mode, got %s", result.Tenant.StartMode)
	}
}

func TestRuntime_StartTrialOnboarding_UsesDefaultTrialDays(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.TrialDays = 0

	result, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s", decision.Status)
	}

	expectedEnd := req.RequestedAt.Add(14 * 24 * time.Hour)
	if !result.Subscription.TrialEndsAt.Equal(expectedEnd) {
		t.Fatalf("expected default trial end %s, got %s", expectedEnd, result.Subscription.TrialEndsAt)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingTenant(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.TenantID = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyTenantRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingAccount(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.AccountID = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyAccountRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingBusinessName(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.BusinessName = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyBusinessRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingLegalName(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.LegalName = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyLegalRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingTaxProfile(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.TaxNumber = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyTaxProfileRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingBillingProfile(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.BillingEmail = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyBillingRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesInvalidBillingEmail(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.BillingEmail = "invalid"

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyBillingRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesMissingAdmin(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.AdminUserID = ""

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyAdminRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesInvalidAdminEmail(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.AdminEmail = "invalid"

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyAdminRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesUnknownPlan(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.Plan = catalog.PlanCode("unknown")

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyPlanUnknown) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_StartTrialOnboarding_DeniesInvalidStartMode(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.StartMode = StartMode("invalid")

	_, decision := runtime.StartTrialOnboarding(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyStartModeInvalid) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CompleteOnboarding(t *testing.T) {
	runtime := mustRuntime(t)

	result, decision := runtime.StartTrialOnboarding(baseRequest())
	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected initial allow, got %s", decision.Status)
	}

	completed, completeDecision := runtime.CompleteOnboarding(result)

	if completeDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected complete allow, got %s", completeDecision.Status)
	}
	if completed.Decision.OnboardingStatus != StatusCompleted {
		t.Fatalf("expected completed onboarding, got %s", completed.Decision.OnboardingStatus)
	}
}
