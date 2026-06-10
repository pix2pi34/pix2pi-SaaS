package publicdemo

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

func baseRequest() DemoRequest {
	return DemoRequest{
		RequestID: "demo_req_7",
		BusinessName: "Pix2pi Pilot Market",
		ContactName: "Ali Veli",
		Email: "demo@example.com",
		Phone: "+905551112233",
		CompanySize: "1-10",
		RequestedPlan: catalog.PlanPro,
		Message: "Demo talep ediyorum",
		ConsentAccepted: true,
		CTA: CTARequestDemo,
		CreatedAt: time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC),
	}
}

func TestRuntime_LandingModel(t *testing.T) {
	runtime := mustRuntime(t)

	model := runtime.LandingModel()

	if model.Title == "" {
		t.Fatal("expected landing title")
	}
	if model.SEOType != "SoftwareApplication" {
		t.Fatalf("expected SoftwareApplication schema, got %s", model.SEOType)
	}
	if len(model.Plans) != 5 {
		t.Fatalf("expected 5 visible plans, got %d", len(model.Plans))
	}
	if len(model.CTAs) < 5 {
		t.Fatalf("expected CTA list, got %d", len(model.CTAs))
	}
}

func TestRuntime_CreateDemoLead_Success(t *testing.T) {
	runtime := mustRuntime(t)

	lead, decision := runtime.CreateDemoLead(baseRequest())

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s with reason %s", decision.Status, decision.ReasonCode)
	}
	if decision.ReasonCode != string(ReasonAllowDemoRequestReady) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
	if lead.Status != LeadStatusNew {
		t.Fatalf("expected lead status NEW, got %s", lead.Status)
	}
	if lead.RequestedPlan != catalog.PlanPro {
		t.Fatalf("expected pro plan, got %s", lead.RequestedPlan)
	}
}

func TestRuntime_CreateDemoLead_DefaultCTA(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.CTA = ""

	lead, decision := runtime.CreateDemoLead(req)

	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected allow, got %s", decision.Status)
	}
	if lead.CTA != CTARequestDemo {
		t.Fatalf("expected default CTA request_demo, got %s", lead.CTA)
	}
}

func TestRuntime_CreateDemoLead_DeniesMissingBusiness(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.BusinessName = ""

	_, decision := runtime.CreateDemoLead(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyBusinessRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CreateDemoLead_DeniesInvalidEmail(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.Email = "invalid"

	_, decision := runtime.CreateDemoLead(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyEmailInvalid) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CreateDemoLead_DeniesMissingPhone(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.Phone = ""

	_, decision := runtime.CreateDemoLead(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyPhoneRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CreateDemoLead_DeniesUnknownPlan(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.RequestedPlan = catalog.PlanCode("unknown")

	_, decision := runtime.CreateDemoLead(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyPlanUnknown) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_CreateDemoLead_DeniesMissingConsent(t *testing.T) {
	runtime := mustRuntime(t)

	req := baseRequest()
	req.ConsentAccepted = false

	_, decision := runtime.CreateDemoLead(req)

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyConsentRequired) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}

func TestRuntime_QualifyLead(t *testing.T) {
	runtime := mustRuntime(t)

	lead, decision := runtime.CreateDemoLead(baseRequest())
	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected initial allow, got %s", decision.Status)
	}

	qualified, qualifyDecision := runtime.QualifyLead(lead)

	if qualifyDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected qualify allow, got %s", qualifyDecision.Status)
	}
	if qualified.Status != LeadStatusQualified {
		t.Fatalf("expected qualified lead, got %s", qualified.Status)
	}
}

func TestRuntime_MarkReadyForOnboarding(t *testing.T) {
	runtime := mustRuntime(t)

	lead, decision := runtime.CreateDemoLead(baseRequest())
	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected initial allow, got %s", decision.Status)
	}

	qualified, qualifyDecision := runtime.QualifyLead(lead)
	if qualifyDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected qualify allow, got %s", qualifyDecision.Status)
	}

	ready, readyDecision := runtime.MarkReadyForOnboarding(qualified)

	if readyDecision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected ready allow, got %s", readyDecision.Status)
	}
	if ready.Status != LeadStatusReadyForOnboarding {
		t.Fatalf("expected ready for onboarding, got %s", ready.Status)
	}
}

func TestRuntime_MarkReadyForOnboarding_DeniesUnqualifiedLead(t *testing.T) {
	runtime := mustRuntime(t)

	lead, decision := runtime.CreateDemoLead(baseRequest())
	if decision.Status != entitlement.DecisionAllow {
		t.Fatalf("expected initial allow, got %s", decision.Status)
	}

	_, readyDecision := runtime.MarkReadyForOnboarding(lead)

	if readyDecision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected ready deny, got %s", readyDecision.Status)
	}
}

func TestRuntime_CheckPublicLaunchGate_DeniesInReadinessPhase(t *testing.T) {
	runtime := mustRuntime(t)

	decision := runtime.CheckPublicLaunchGate()

	if decision.Status != entitlement.DecisionDeny {
		t.Fatalf("expected deny, got %s", decision.Status)
	}
	if decision.ReasonCode != string(ReasonDenyPublicLaunch) {
		t.Fatalf("unexpected reason: %s", decision.ReasonCode)
	}
}
