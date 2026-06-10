package pricingvalidation

import "testing"

func TestPricingValidationPassesInternalReadiness(t *testing.T) {
	input := validValidationInput()

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

	if !result.InternalPricingValidationReady {
		t.Fatal("internal pricing validation readiness must be true")
	}

	if result.ProductionPricingPublished {
		t.Fatal("production pricing must remain unpublished")
	}

	if result.RealCustomerBillingEnabled {
		t.Fatal("real customer billing must remain disabled")
	}

	if result.PaymentCollectionEnabled {
		t.Fatal("payment collection must remain disabled")
	}

	if result.PublicCheckoutEnabled {
		t.Fatal("public checkout must remain disabled")
	}

	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestPricingValidationBlocksProductionPublish(t *testing.T) {
	input := validValidationInput()
	input.ProductionPricingPublished = true

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

func TestPricingValidationRequiresBillingGateClosed(t *testing.T) {
	input := validValidationInput()
	input.Controls[0].RequiresBillingGateClosed = false

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

func TestPricingValidationRequiresDeferredReason(t *testing.T) {
	input := validValidationInput()

	for idx := range input.Controls {
		if input.Controls[idx].DeferredToDeveloperDocsPortal {
			input.Controls[idx].DeferredReason = ""
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

func TestRequiredControlKeysSorted(t *testing.T) {
	input := ValidationInput{RequiredControlKeys: []string{"vat_policy_validation", "pricing_table_integrity"}}
	keys := RequiredControlKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "pricing_table_integrity" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validValidationInput() ValidationInput {
	return ValidationInput{
		Phase:                          "FAZ_5_18_1_5",
		Target:                         "FAZ_5_R_PRICING_VALIDATION",
		InternalPricingValidationReady: true,
		ProductionPricingPublished:     false,
		RealCustomerBillingEnabled:     false,
		PaymentCollectionEnabled:       false,
		PublicCheckoutEnabled:          false,
		RequiredControlKeys: []string{
			"pricing_table_integrity",
			"accountant_package_integrity",
			"vat_policy_validation",
			"annual_monthly_price_validation",
			"entitlement_consistency_validation",
			"billing_gate_validation",
			"payment_gate_validation",
			"public_copy_approval_validation",
			"developer_docs_portal_deferred_marker",
		},
		RequiredDomains: []ValidationDomain{
			DomainPricingTable,
			DomainAccountantPackage,
			DomainVATPolicy,
			DomainBillingGate,
			DomainPaymentGate,
			DomainPublicCopy,
			DomainApproval,
			DomainDeveloperDocsNext,
		},
		RequireEvidence:                  true,
		RequireCounterBasedAudit:         true,
		RequireNoRequiredFail:            true,
		RequireNoOptionalWarn:            true,
		RequirePricingTableSource:        true,
		RequireAccountantPackageSource:   true,
		RequirePlanCodeConsistency:       true,
		RequireCurrencyConsistency:       true,
		RequireVATPolicyConsistency:      true,
		RequireAnnualMonthlyConsistency:  true,
		RequireEntitlementConsistency:    true,
		RequireBillingGateClosed:         true,
		RequirePaymentGateClosed:         true,
		RequirePublicCopyGuard:           true,
		RequireLegalReview:               true,
		RequireFounderApproval:           true,
		RequireChangeLog:                 true,
		RequireAuditTrail:                true,
		RequireProductionPublishBlock:    true,
		RequireRealCustomerBillingBlock:  true,
		RequirePaymentCollectionBlock:    true,
		RequirePublicCheckoutBlock:       true,
		AllowDeveloperDocsPortalDeferred: true,
		Controls: []ValidationControl{
			control("pricing_table_integrity", DomainPricingTable, "Pricing Table Integrity"),
			control("accountant_package_integrity", DomainAccountantPackage, "Accountant Package Integrity"),
			control("vat_policy_validation", DomainVATPolicy, "VAT Policy Validation"),
			control("annual_monthly_price_validation", DomainPricingTable, "Annual Monthly Price Validation"),
			control("entitlement_consistency_validation", DomainApproval, "Entitlement Consistency Validation"),
			control("billing_gate_validation", DomainBillingGate, "Billing Gate Validation"),
			control("payment_gate_validation", DomainPaymentGate, "Payment Gate Validation"),
			control("public_copy_approval_validation", DomainPublicCopy, "Public Copy Approval Validation"),
			deferred("developer_docs_portal_deferred_marker", DomainDeveloperDocsNext, "Developer Docs Portal Deferred Marker"),
		},
	}
}

func control(key string, domain ValidationDomain, title string) ValidationControl {
	return ValidationControl{
		Key:                              key,
		Domain:                           domain,
		Title:                            title,
		Owner:                            "commercial_finance_ops",
		Status:                           StatusReady,
		Required:                         true,
		HasEvidence:                      true,
		HasCounterBasedAudit:             true,
		RequiredFailCount:                0,
		OptionalWarnCount:                0,
		ProductionPricingPublished:       false,
		RealCustomerBillingEnabled:       false,
		PaymentCollectionEnabled:         false,
		PublicCheckoutEnabled:            false,
		RequiresPricingTableSource:       true,
		RequiresAccountantPackageSource:  true,
		RequiresPlanCodeConsistency:      true,
		RequiresCurrencyConsistency:      true,
		RequiresVATPolicyConsistency:     true,
		RequiresAnnualMonthlyConsistency: true,
		RequiresEntitlementConsistency:   true,
		RequiresBillingGateClosed:        true,
		RequiresPaymentGateClosed:        true,
		RequiresPublicCopyGuard:          true,
		RequiresLegalReview:              true,
		RequiresFounderApproval:          true,
		RequiresChangeLog:                true,
		RequiresAuditTrail:               true,
		BlocksProductionPublish:          true,
		BlocksRealCustomerBilling:        true,
		BlocksPaymentCollection:          true,
		BlocksPublicCheckout:             true,
		DeferredToDeveloperDocsPortal:    false,
	}
}

func deferred(key string, domain ValidationDomain, title string) ValidationControl {
	c := control(key, domain, title)
	c.Status = StatusPendingNext
	c.DeferredToDeveloperDocsPortal = true
	c.DeferredReason = "Developer docs portalı 275 — FAZ 5-19.3 içinde açılacak"
	return c
}
