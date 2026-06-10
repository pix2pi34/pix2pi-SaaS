package accountantpackage

import "testing"

func TestAccountantPackagePassesInternalReadiness(t *testing.T) {
	input := validPackageInput()

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

	if !result.InternalAccountantPackageReady {
		t.Fatal("internal accountant package readiness must be true")
	}

	if result.ProductionPackagePublished {
		t.Fatal("production package must remain unpublished")
	}

	if result.RealCustomerBillingEnabled {
		t.Fatal("real customer billing must remain disabled")
	}

	if result.PaymentCollectionEnabled {
		t.Fatal("payment collection must remain disabled")
	}

	if result.AccountantPortalCommercialEnabled {
		t.Fatal("accountant portal commercial must remain disabled")
	}

	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestAccountantPackageBlocksProductionPublish(t *testing.T) {
	input := validPackageInput()
	input.ProductionPackagePublished = true

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

func TestAccountantPackageRequiresDataAccessPolicy(t *testing.T) {
	input := validPackageInput()
	input.Packages[0].RequiresDataAccessPolicy = false

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

func TestAccountantPackageRequiresDeferredReason(t *testing.T) {
	input := validPackageInput()

	for idx := range input.Packages {
		if input.Packages[idx].DeferredToPricingValidation {
			input.Packages[idx].DeferredReason = ""
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

func TestRequiredPackageKeysSorted(t *testing.T) {
	input := PackageInput{RequiredPackageKeys: []string{"accountant_pro_package", "accountant_starter_package"}}
	keys := RequiredPackageKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "accountant_pro_package" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validPackageInput() PackageInput {
	return PackageInput{
		Phase:                             "FAZ_5_18_1_4",
		Target:                            "FAZ_5_R_ACCOUNTANT_SPECIAL_PACKAGES",
		InternalAccountantPackageReady:    true,
		ProductionPackagePublished:        false,
		RealCustomerBillingEnabled:        false,
		PaymentCollectionEnabled:          false,
		AccountantPortalCommercialEnabled: false,
		RequiredPackageKeys: []string{
			"accountant_starter_package",
			"accountant_pro_package",
			"accountant_enterprise_package",
			"pricing_validation_deferred_marker",
		},
		RequiredSegments: []AccountantSegment{
			SegmentAccountantStarter,
			SegmentAccountantPro,
			SegmentAccountantEnterprise,
			SegmentValidationNext,
		},
		RequireEvidence:                        true,
		RequireCounterBasedAudit:               true,
		RequireNoRequiredFail:                  true,
		RequireNoOptionalWarn:                  true,
		RequirePackageCode:                     true,
		RequireCurrency:                        true,
		RequireMonthlyBaseFee:                  true,
		RequirePerCompanyFee:                   true,
		RequireVATPolicy:                       true,
		RequireCompanyLimit:                    true,
		RequireAccountantUserLimit:             true,
		RequireExportRights:                    true,
		RequirePortalEntitlement:               true,
		RequireCompanyAssignmentPolicy:         true,
		RequireMonthlyRevalidation:             true,
		RequireBillingPolicy:                   true,
		RequireKVKKScope:                       true,
		RequireDataAccessPolicy:                true,
		RequireLegalReview:                     true,
		RequireFounderApproval:                 true,
		RequireChangeLog:                       true,
		RequirePublicCopyGuard:                 true,
		RequireProductionPublishBlock:          true,
		RequireRealCustomerBillingBlock:        true,
		RequirePaymentCollectionBlock:          true,
		RequireAccountantPortalCommercialBlock: true,
		AllowPricingValidationDeferred:         true,
		Packages: []AccountantPackage{
			pkg("accountant_starter_package", SegmentAccountantStarter, "Accountant Starter Package"),
			pkg("accountant_pro_package", SegmentAccountantPro, "Accountant Pro Package"),
			pkg("accountant_enterprise_package", SegmentAccountantEnterprise, "Accountant Enterprise Package"),
			deferred("pricing_validation_deferred_marker", SegmentValidationNext, "Fiyatlama Doğrulama Deferred Marker"),
		},
	}
}

func pkg(key string, segment AccountantSegment, title string) AccountantPackage {
	return AccountantPackage{
		Key:                               key,
		Segment:                           segment,
		Title:                             title,
		Owner:                             "commercial_finance_ops",
		Status:                            StatusReady,
		Required:                          true,
		HasEvidence:                       true,
		HasCounterBasedAudit:              true,
		RequiredFailCount:                 0,
		OptionalWarnCount:                 0,
		ProductionPackagePublished:        false,
		RealCustomerBillingEnabled:        false,
		PaymentCollectionEnabled:          false,
		AccountantPortalCommercialEnabled: false,
		RequiresPackageCode:               true,
		RequiresCurrency:                  true,
		RequiresMonthlyBaseFee:            true,
		RequiresPerCompanyFee:             true,
		RequiresVATPolicy:                 true,
		RequiresCompanyLimit:              true,
		RequiresAccountantUserLimit:       true,
		RequiresExportRights:              true,
		RequiresPortalEntitlement:         true,
		RequiresCompanyAssignmentPolicy:   true,
		RequiresMonthlyRevalidation:       true,
		RequiresBillingPolicy:             true,
		RequiresKVKKScope:                 true,
		RequiresDataAccessPolicy:          true,
		RequiresLegalReview:               true,
		RequiresFounderApproval:           true,
		RequiresChangeLog:                 true,
		RequiresPublicCopyGuard:           true,
		BlocksProductionPublish:           true,
		BlocksRealCustomerBilling:         true,
		BlocksPaymentCollection:           true,
		BlocksAccountantPortalCommercial:  true,
		DeferredToPricingValidation:       false,
	}
}

func deferred(key string, segment AccountantSegment, title string) AccountantPackage {
	p := pkg(key, segment, title)
	p.Status = StatusPendingNext
	p.DeferredToPricingValidation = true
	p.DeferredReason = "Fiyatlama doğrulama 274 — FAZ 5-18.1.5 içinde açılacak"
	return p
}
