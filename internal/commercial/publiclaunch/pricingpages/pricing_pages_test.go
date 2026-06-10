package pricingpages

import "testing"

func TestPricingPagesPassesInternalReadiness(t *testing.T) {
	input := validPageInput()

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
	if !result.InternalPricingPagesReady {
		t.Fatal("internal pricing pages readiness must be true")
	}
	if !result.StaticHTMLReady {
		t.Fatal("static HTML readiness must be true")
	}
	if result.ProductionPagePublished {
		t.Fatal("production pricing page must remain unpublished")
	}
	if result.RealCustomerSignupEnabled {
		t.Fatal("real customer signup must remain disabled")
	}
	if result.CheckoutEnabled {
		t.Fatal("checkout must remain disabled")
	}
	if result.PaymentCollectionEnabled {
		t.Fatal("payment collection must remain disabled")
	}
	if result.PublicPricingVisible {
		t.Fatal("public pricing visible must remain disabled")
	}
	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestPricingPagesBlocksCheckout(t *testing.T) {
	input := validPageInput()
	input.CheckoutEnabled = true

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

func TestPricingPagesRequiresValidatedPricing(t *testing.T) {
	input := validPageInput()
	input.Sections[0].RequiresValidatedPricing = false

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

func TestPricingPagesRequiresDeferredReason(t *testing.T) {
	input := validPageInput()
	for idx := range input.Sections {
		if input.Sections[idx].DeferredToWebTests {
			input.Sections[idx].DeferredReason = ""
		}
	}

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

func TestRequiredSectionKeysSorted(t *testing.T) {
	input := PageInput{RequiredSectionKeys: []string{"starter_plan_public_copy", "pricing_landing_page"}}
	keys := RequiredSectionKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}
	if keys[0] != "pricing_landing_page" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validPageInput() PageInput {
	return PageInput{
		Phase:                     "FAZ_5_19_2",
		Target:                    "FAZ_5_R_PRICING_PAGES",
		InternalPricingPagesReady: true,
		StaticHTMLReady:           true,
		ProductionPagePublished:   false,
		RealCustomerSignupEnabled: false,
		CheckoutEnabled:           false,
		PaymentCollectionEnabled:  false,
		PublicPricingVisible:      false,
		RequiredSectionKeys: []string{
			"pricing_landing_page",
			"plan_comparison_table",
			"vat_notice_panel",
			"free_plan_public_copy",
			"starter_plan_public_copy",
			"pro_plan_public_copy",
			"enterprise_plan_public_copy",
			"accountant_package_public_copy",
			"launch_guard_panel",
			"public_developer_web_tests_deferred_marker",
		},
		RequiredDomains: []PageDomain{
			DomainPricingOverview,
			DomainPlanComparison,
			DomainPublicCopy,
			DomainVATNotice,
			DomainCTA,
			DomainAccountant,
			DomainLaunchGuard,
			DomainWebTestsNext,
		},
		RequireEvidence:                true,
		RequireCounterBasedAudit:       true,
		RequireNoRequiredFail:          true,
		RequireNoOptionalWarn:          true,
		RequirePricingTableSource:      true,
		RequireAccountantPackageSource: true,
		RequireValidatedPricing:        true,
		RequireCurrency:                true,
		RequireVATNotice:               true,
		RequirePlanComparison:          true,
		RequireFeatureSummary:          true,
		RequireEntitlementReference:    true,
		RequireCTA:                     true,
		RequireLegalReview:             true,
		RequireFounderApproval:         true,
		RequireChangeLog:               true,
		RequireAuditTrail:              true,
		RequirePublicCopyGuard:         true,
		RequireProductionPublishBlock:  true,
		RequireRealCustomerSignupBlock: true,
		RequireCheckoutBlock:           true,
		RequirePaymentCollectionBlock:  true,
		AllowWebTestsDeferred:          true,
		Sections: []PricingPageSection{
			section("pricing_landing_page", DomainPricingOverview, "Pricing Landing Page"),
			section("plan_comparison_table", DomainPlanComparison, "Plan Comparison Table"),
			section("vat_notice_panel", DomainVATNotice, "VAT / KDV Notice Panel"),
			section("free_plan_public_copy", DomainPublicCopy, "Free Plan Public Copy"),
			section("starter_plan_public_copy", DomainPublicCopy, "Starter Plan Public Copy"),
			section("pro_plan_public_copy", DomainPublicCopy, "Pro Plan Public Copy"),
			section("enterprise_plan_public_copy", DomainCTA, "Enterprise Plan Public Copy"),
			section("accountant_package_public_copy", DomainAccountant, "Accountant Package Public Copy"),
			section("launch_guard_panel", DomainLaunchGuard, "Launch Guard Panel"),
			deferred("public_developer_web_tests_deferred_marker", DomainWebTestsNext, "Public / Developer Web Testleri Deferred Marker"),
		},
	}
}

func section(key string, domain PageDomain, title string) PricingPageSection {
	return PricingPageSection{
		Key:                             key,
		Domain:                          domain,
		Title:                           title,
		Owner:                           "commercial_web_ops",
		Status:                          StatusReady,
		Required:                        true,
		HasEvidence:                     true,
		HasCounterBasedAudit:            true,
		RequiredFailCount:               0,
		OptionalWarnCount:               0,
		ProductionPagePublished:         false,
		RealCustomerSignupEnabled:       false,
		CheckoutEnabled:                 false,
		PaymentCollectionEnabled:        false,
		PublicPricingVisible:            false,
		RequiresPricingTableSource:      true,
		RequiresAccountantPackageSource: true,
		RequiresValidatedPricing:        true,
		RequiresCurrency:                true,
		RequiresVATNotice:               true,
		RequiresPlanComparison:          true,
		RequiresFeatureSummary:          true,
		RequiresEntitlementReference:    true,
		RequiresCTA:                     true,
		RequiresLegalReview:             true,
		RequiresFounderApproval:         true,
		RequiresChangeLog:               true,
		RequiresAuditTrail:              true,
		RequiresPublicCopyGuard:         true,
		BlocksProductionPublish:         true,
		BlocksRealCustomerSignup:        true,
		BlocksCheckout:                  true,
		BlocksPaymentCollection:         true,
		DeferredToWebTests:              false,
	}
}

func deferred(key string, domain PageDomain, title string) PricingPageSection {
	s := section(key, domain, title)
	s.Status = StatusPendingNext
	s.DeferredToWebTests = true
	s.DeferredReason = "Public / developer web testleri 279 — FAZ 5-19.6 içinde açılacak"
	return s
}
