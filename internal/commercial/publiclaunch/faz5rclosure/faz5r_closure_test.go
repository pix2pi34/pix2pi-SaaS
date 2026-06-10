package faz5rclosure

import "testing"

func TestFaz5RClosurePasses(t *testing.T) {
	input := validClosureInput()

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if result.Status != "PASS" {
		t.Fatalf("expected PASS got %s findings=%v", result.Status, result.Findings)
	}
	if result.RequiredFailCount != 0 {
		t.Fatalf("expected zero required fails got %d", result.RequiredFailCount)
	}
	if !result.GeneralFinalReviewReady {
		t.Fatal("general final review must be ready")
	}
	if !result.FinalClosureSealed {
		t.Fatal("final closure must be sealed")
	}
	if result.ProductionLaunchAllowed {
		t.Fatal("production launch must remain blocked")
	}
	if result.RealCustomerCollectionOpen {
		t.Fatal("real customer collection must remain closed")
	}
	if result.RealBillingEnabled {
		t.Fatal("real billing must remain closed")
	}
	if result.PaymentCollectionEnabled {
		t.Fatal("payment collection must remain closed")
	}
	if result.PublicDeveloperAccessOpen {
		t.Fatal("developer access must remain closed")
	}
	if result.CheckoutEnabled {
		t.Fatal("checkout must remain closed")
	}
	if result.SandboxLiveEnabled {
		t.Fatal("sandbox live must remain closed")
	}
	if !result.ReadyForNextPhase {
		t.Fatal("next phase must be ready")
	}
	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestFaz5RClosureBlocksProductionLaunch(t *testing.T) {
	input := validClosureInput()
	input.ProductionLaunchAllowed = true

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if result.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", result.Status)
	}
	if result.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestFaz5RClosureRequiresEvidence(t *testing.T) {
	input := validClosureInput()
	input.Items[0].HasEvidence = false

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if result.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", result.Status)
	}
	if result.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestFaz5RClosureRequiresRealImplementationPass(t *testing.T) {
	input := validClosureInput()
	input.Items[1].RealImplementationPass = false

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if result.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", result.Status)
	}
	if result.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestRequiredItemKeysSorted(t *testing.T) {
	input := ClosureInput{RequiredItemKeys: []string{"pricing", "compliance"}}
	keys := RequiredItemKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}
	if keys[0] != "compliance" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validClosureInput() ClosureInput {
	return ClosureInput{
		Phase:                      "FAZ_5_R_FINAL_REVIEW_CLOSURE",
		Target:                     "FAZ_5_R_GENERAL_FINAL_REVIEW_CLOSURE",
		GeneralFinalReviewReady:    true,
		FinalClosureSealRequested:  true,
		ProductionLaunchAllowed:    false,
		RealCustomerCollectionOpen: false,
		RealBillingEnabled:         false,
		PaymentCollectionEnabled:   false,
		PublicDeveloperAccessOpen:  false,
		CheckoutEnabled:            false,
		SandboxLiveEnabled:         false,
		RequiredItemKeys: []string{
			"compliance_contract_consent",
			"support_ops",
			"commercial_gate",
			"billing_tenant_lifecycle_sales_ops",
			"pricing",
			"public_developer_surfaces",
			"public_launch_safety",
			"next_phase_handoff",
		},
		RequiredDomains: []ClosureDomain{
			DomainCompliance,
			DomainSupportOps,
			DomainCommercialGate,
			DomainBillingLifecycle,
			DomainPricing,
			DomainPublicDeveloper,
			DomainLaunchSafety,
			DomainNextPhase,
		},
		RequireEvidence:                true,
		RequireCounterBasedAudit:       true,
		RequireNoRequiredFail:          true,
		RequireNoOptionalWarn:          true,
		RequireDocReady:                true,
		RequireConfigReady:             true,
		RequireCodeReady:               true,
		RequireTestPass:                true,
		RequireRealImplementationPass:  true,
		RequireProductionLaunchBlocked: true,
		RequireRealCustomerClosed:      true,
		RequireRealBillingClosed:       true,
		RequirePaymentClosed:           true,
		RequireDeveloperAccessClosed:   true,
		RequireCheckoutClosed:          true,
		RequireSandboxClosed:           true,
		RequireNextPhaseReady:          true,
		Items: []ClosureItem{
			item("compliance_contract_consent", DomainCompliance, "KVKK / Sözleşme / Consent Closure"),
			item("support_ops", DomainSupportOps, "Support Ops Closure"),
			item("commercial_gate", DomainCommercialGate, "Commercial Gate Closure"),
			item("billing_tenant_lifecycle_sales_ops", DomainBillingLifecycle, "Billing / Tenant Lifecycle / Sales Ops Closure"),
			item("pricing", DomainPricing, "Pricing Closure"),
			item("public_developer_surfaces", DomainPublicDeveloper, "Public / Developer Surfaces Closure"),
			item("public_launch_safety", DomainLaunchSafety, "Public Launch Safety Closure"),
			item("next_phase_handoff", DomainNextPhase, "Next Phase Handoff"),
		},
	}
}

func item(key string, domain ClosureDomain, title string) ClosureItem {
	return ClosureItem{
		Key:                        key,
		Domain:                     domain,
		Title:                      title,
		Owner:                      "commercial_ops",
		Status:                     StatusSealed,
		Required:                   true,
		HasEvidence:                true,
		HasCounterBasedAudit:       true,
		RequiredFailCount:          0,
		OptionalWarnCount:          0,
		DocReady:                   true,
		ConfigReady:                true,
		CodeReady:                  true,
		TestPass:                   true,
		RealImplementationPass:     true,
		ProductionLaunchAllowed:    false,
		RealCustomerCollectionOpen: false,
		RealBillingEnabled:         false,
		PaymentCollectionEnabled:   false,
		PublicDeveloperAccessOpen:  false,
		CheckoutEnabled:            false,
		SandboxLiveEnabled:         false,
		RequiresEvidence:           true,
		RequiresCounterAudit:       true,
		RequiresDocReady:           true,
		RequiresConfigReady:        true,
		RequiresCodeReady:          true,
		RequiresTestPass:           true,
		RequiresRealImplementation: true,
		RequiresLaunchBlocked:      true,
		RequiresCustomerClosed:     true,
		RequiresBillingClosed:      true,
		RequiresPaymentClosed:      true,
		RequiresDeveloperClosed:    true,
		RequiresCheckoutClosed:     true,
		RequiresSandboxClosed:      true,
		BlocksProductionLaunch:     true,
		BlocksRealCustomer:         true,
		BlocksRealBilling:          true,
		BlocksPaymentCollection:    true,
		BlocksDeveloperAccess:      true,
		BlocksCheckout:             true,
		BlocksSandboxLive:          true,
		ReadyForNextPhase:          true,
	}
}
