package pricingtable

import "testing"

func TestPricingTablePassesInternalReadiness(t *testing.T) {
	input := validTableInput()

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

	if !result.InternalPricingTableReady {
		t.Fatal("internal pricing table readiness must be true")
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

func TestPricingTableBlocksProductionPublish(t *testing.T) {
	input := validTableInput()
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

func TestPricingTableRequiresVATPolicy(t *testing.T) {
	input := validTableInput()
	input.Rows[0].RequiresVATPolicy = false

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

func TestPricingTableRequiresDeferredReason(t *testing.T) {
	input := validTableInput()

	for idx := range input.Rows {
		if input.Rows[idx].DeferredToAccountantPackage {
			input.Rows[idx].DeferredReason = ""
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

func TestRequiredRowKeysSorted(t *testing.T) {
	input := TableInput{RequiredRowKeys: []string{"pro_plan_row", "free_plan_row"}}
	keys := RequiredRowKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "free_plan_row" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validTableInput() TableInput {
	return TableInput{
		Phase:                      "FAZ_5_18_1_2",
		Target:                     "FAZ_5_R_PRICING_TABLE",
		InternalPricingTableReady:  true,
		ProductionPricingPublished: false,
		RealCustomerBillingEnabled: false,
		PaymentCollectionEnabled:   false,
		PublicCheckoutEnabled:      false,
		RequiredRowKeys: []string{
			"free_plan_row",
			"starter_plan_row",
			"pro_plan_row",
			"enterprise_plan_row",
			"accountant_package_deferred_marker",
		},
		RequiredSegments: []PriceSegment{
			SegmentFree,
			SegmentStarter,
			SegmentPro,
			SegmentEnterprise,
			SegmentAccountantNext,
		},
		RequireEvidence:                 true,
		RequireCounterBasedAudit:        true,
		RequireNoRequiredFail:           true,
		RequireNoOptionalWarn:           true,
		RequirePlanCode:                 true,
		RequireCurrency:                 true,
		RequireMonthlyPrice:             true,
		RequireAnnualPrice:              true,
		RequireVATPolicy:                true,
		RequireUserLimit:                true,
		RequireTenantLimit:              true,
		RequireFeatureSummary:           true,
		RequireEntitlementReference:     true,
		RequireBillingPolicy:            true,
		RequireLegalReview:              true,
		RequireFounderApproval:          true,
		RequireChangeLog:                true,
		RequirePublicCopyGuard:          true,
		RequireProductionPublishBlock:   true,
		RequireRealCustomerBillingBlock: true,
		RequirePaymentCollectionBlock:   true,
		RequirePublicCheckoutBlock:      true,
		AllowAccountantPackageDeferred:  true,
		Rows: []PricingRow{
			row("free_plan_row", SegmentFree, "Free Plan Row"),
			row("starter_plan_row", SegmentStarter, "Starter Plan Row"),
			row("pro_plan_row", SegmentPro, "Pro Plan Row"),
			row("enterprise_plan_row", SegmentEnterprise, "Enterprise Plan Row"),
			deferred("accountant_package_deferred_marker", SegmentAccountantNext, "Muhasebeci Özel Paketleri Deferred Marker"),
		},
	}
}

func row(key string, segment PriceSegment, title string) PricingRow {
	return PricingRow{
		Key:                          key,
		Segment:                      segment,
		Title:                        title,
		Owner:                        "commercial_finance_ops",
		Status:                       StatusReady,
		Required:                     true,
		HasEvidence:                  true,
		HasCounterBasedAudit:         true,
		RequiredFailCount:            0,
		OptionalWarnCount:            0,
		ProductionPricingPublished:   false,
		RealCustomerBillingEnabled:   false,
		PaymentCollectionEnabled:     false,
		PublicCheckoutEnabled:        false,
		RequiresPlanCode:             true,
		RequiresCurrency:             true,
		RequiresMonthlyPrice:         true,
		RequiresAnnualPrice:          true,
		RequiresVATPolicy:            true,
		RequiresUserLimit:            true,
		RequiresTenantLimit:          true,
		RequiresFeatureSummary:       true,
		RequiresEntitlementReference: true,
		RequiresBillingPolicy:        true,
		RequiresLegalReview:          true,
		RequiresFounderApproval:      true,
		RequiresChangeLog:            true,
		RequiresPublicCopyGuard:      true,
		BlocksProductionPublish:      true,
		BlocksRealCustomerBilling:    true,
		BlocksPaymentCollection:      true,
		BlocksPublicCheckout:         true,
		DeferredToAccountantPackage:  false,
	}
}

func deferred(key string, segment PriceSegment, title string) PricingRow {
	r := row(key, segment, title)
	r.Status = StatusPendingNext
	r.DeferredToAccountantPackage = true
	r.DeferredReason = "Muhasebeci özel paketleri 273 — FAZ 5-18.1.4 içinde açılacak"
	return r
}
