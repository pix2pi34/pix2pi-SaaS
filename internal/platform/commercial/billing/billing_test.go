package billing

import (
	"testing"
	"time"

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

func baseAccount(now time.Time) subscription.Account {
	return subscription.Account{
		TenantID: "tenant_7",
		AccountID: "account_7",
		Plan: catalog.PlanPro,
		Status: subscription.StatusActive,
		CurrentPeriodStart: now.Add(-24 * time.Hour),
		CurrentPeriodEnd: now.Add(30 * 24 * time.Hour),
		CurrentUsers: 5,
		CurrentTenants: 1,
		CurrentAPIRequests: 100,
		CurrentExports: 10,
		CurrentIntegrations: 1,
	}
}

func baseProfile() BillingProfile {
	return BillingProfile{
		TenantID: "tenant_7",
		AccountID: "account_7",
		LegalName: "Pix2pi Pilot Ltd",
		TaxNumber: "1234567890",
		TaxOffice: "Istanbul",
		BillingEmail: "billing@example.com",
		BillingAddress: "Istanbul Turkiye",
	}
}

func TestRuntime_ValidatePriceCatalog(t *testing.T) {
	runtime := mustRuntime(t)

	if err := runtime.ValidatePriceCatalog(); err != nil {
		t.Fatalf("expected price catalog to validate, got error: %v", err)
	}
}

func TestRuntime_PriceCatalogIncludesAllPlans(t *testing.T) {
	runtime := mustRuntime(t)

	requiredPlans := []catalog.PlanCode{
		catalog.PlanStarter,
		catalog.PlanPro,
		catalog.PlanEnterprise,
		catalog.PlanAccountant,
		catalog.PlanMarketplace,
	}

	for _, planCode := range requiredPlans {
		price, ok := runtime.Price(planCode)
		if !ok {
			t.Fatalf("expected price for plan: %s", planCode)
		}
		if price.MonthlyNetAmountKurus <= 0 {
			t.Fatalf("expected positive price for plan: %s", planCode)
		}
		if price.Currency != CurrencyTRY {
			t.Fatalf("expected TRY currency for plan %s, got %s", planCode, price.Currency)
		}
	}
}

func TestCalculateVAT(t *testing.T) {
	vat := CalculateVAT(100000, 2000)

	if vat != 20000 {
		t.Fatalf("expected vat 20000 kurus, got %d", vat)
	}
}

func TestRuntime_BuildInvoiceDraft(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	draft, decision := runtime.BuildInvoiceDraft(
		baseAccount(now),
		baseProfile(),
		now,
		now.Add(30 * 24 * time.Hour),
	)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if draft.BillingStatus != BillingStatusSimulationReady {
		t.Fatalf("expected simulation ready, got %s", draft.BillingStatus)
	}
	if draft.RealPaymentEnabled {
		t.Fatal("real payment must be disabled in 7-5")
	}
	if !draft.SimulationEnabled {
		t.Fatal("billing simulation must be enabled")
	}
	if draft.NetAmountKurus <= 0 {
		t.Fatal("expected positive net amount")
	}
	if draft.VATAmountKurus <= 0 {
		t.Fatal("expected positive vat amount")
	}
	if draft.GrossAmountKurus != draft.NetAmountKurus+draft.VATAmountKurus {
		t.Fatal("gross amount must equal net + vat")
	}
	if len(draft.Lines) != 1 {
		t.Fatalf("expected one invoice line, got %d", len(draft.Lines))
	}
}

func TestRuntime_BuildInvoiceDraft_DeniesMissingBillingProfile(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	_, decision := runtime.BuildInvoiceDraft(
		baseAccount(now),
		BillingProfile{},
		now,
		now.Add(30 * 24 * time.Hour),
	)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyBillingProfileRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_BuildInvoiceDraft_DeniesInvalidPeriod(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	_, decision := runtime.BuildInvoiceDraft(
		baseAccount(now),
		baseProfile(),
		now,
		now.Add(-1 * time.Hour),
	)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyInvalidPeriod) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_BuildInvoiceDraft_DeniesUnknownPlan(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Plan = catalog.PlanCode("unknown")

	_, decision := runtime.BuildInvoiceDraft(
		account,
		baseProfile(),
		now,
		now.Add(30 * 24 * time.Hour),
	)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyPlanUnknown) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_BuildInvoiceDraft_DeniesCanceledSubscription(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Status = subscription.StatusCanceled

	_, decision := runtime.BuildInvoiceDraft(
		account,
		baseProfile(),
		now,
		now.Add(30 * 24 * time.Hour),
	)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenySubscriptionNotBillable) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_SimulateBilling(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	draft, draftDecision := runtime.BuildInvoiceDraft(
		baseAccount(now),
		baseProfile(),
		now,
		now.Add(30 * 24 * time.Hour),
	)
	if draftDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected draft allow, got %s", draftDecision.Status)
	}

	simulationDecision := runtime.SimulateBilling(draft)
	if simulationDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected simulation allow, got %s", simulationDecision.Status)
	}
	if simulationDecision.ReasonCode != string(ReasonAllowBillingSimulationReady) {
		t.Fatalf("unexpected reason: %s", simulationDecision.ReasonCode)
	}
}

func TestRuntime_CheckRealPaymentGate_DeniesInReadinessPhase(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckRealPaymentGate()

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected real payment deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyRealPaymentDisabled) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_BuildInvoiceDraft_AccountantPlan(t *testing.T) {
	runtime := mustRuntime(t)
	now := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)

	account := baseAccount(now)
	account.Plan = catalog.PlanAccountant
	account.CurrentAccountantFirms = 20

	draft, decision := runtime.BuildInvoiceDraft(
		account,
		baseProfile(),
		now,
		now.Add(30 * 24 * time.Hour),
	)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s", decision.Status)
	}
	if draft.PlanCode != catalog.PlanAccountant {
		t.Fatalf("expected accountant plan, got %s", draft.PlanCode)
	}
	if draft.NetAmountKurus <= 0 {
		t.Fatal("expected accountant plan amount")
	}
}
