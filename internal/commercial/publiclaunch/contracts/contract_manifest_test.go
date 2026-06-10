package contracts

import "testing"

func draftManifest() ContractSetManifest {
	return ContractSetManifest{
		Phase:                                 "FAZ 5-R",
		StepNo:                                242,
		StepCode:                              "FAZ_5_18_3_1",
		Slug:                                  "faz_5_18_3_1_sozlesme_seti",
		Module:                                "commercial_public_launch",
		TitleTR:                               "Sözleşme seti",
		SetVersion:                            "0.2.0-draft-fix",
		Status:                                ContractDraft,
		PublicPublishAllowed:                  false,
		PublicCoreProductAllowed:              true,
		PublicContractDraftAllowed:            false,
		DataMonetizationPublicAllowed:         false,
		LegalKVKKApprovalRequiredForDataModel: true,
		LegalApprovalRequired:                 true,
		KvkkApprovalRequired:                  true,
		ProductionReady:                       false,
		BusinessTerms: BusinessTerms{
			SystemName:                            "Pix2pi Ticaret Operasyon Sistemi",
			DataSupportedPlanEnabledAfterApproval: true,
			RestrictedPaidPlanSupported:           true,
			ModuleBasedPricingSupported:           true,
			EnterprisePrivacyPlanSupported:        true,
			CommercialBenefitProgramSupported:     true,
			ProcurementRecommendationSupported:    true,
			PooledPurchasingSupported:             true,
			SponsoredOfferSupported:               true,
			AnonymousAggregatedInsightSupported:   true,
			Pix2piSupplierResellerRoleSupported:   true,
		},
		RuntimeGateContract: RuntimeGateContract{
			ConsentRegistryRequired:                true,
			CommercialPreferenceRegistryRequired:   true,
			EntitlementRuntimeRequired:             true,
			PlanPricingEngineRequired:              true,
			FeatureGateMiddlewareRequired:          true,
			DataPipelineGuardRequired:              true,
			SponsoredOfferGuardRequired:            true,
			ProcurementRecommendationGuardRequired: true,
		},
		ApprovalGates: map[string]ApprovalGate{
			"hukukcu_onayi":          {Status: ApprovalPending, RequiredForPublicLaunch: true},
			"kvkk_danismani_onayi":   {Status: ApprovalPending, RequiredForPublicLaunch: true},
			"ticari_operasyon_onayi": {Status: ApprovalPending, RequiredForPublicLaunch: true},
			"founder_go_no_go":       {Status: ApprovalPending, RequiredForPublicLaunch: true},
		},
		PlanModes: map[PlanMode]PlanModeContract{
			PlanDataSupported:     {Description: "data", CoreProductAllowed: true, CommercialBenefitProgramAllowedAfterApproval: true, PricePolicy: "free_or_discounted_or_advantaged"},
			PlanRestrictedPaid:    {Description: "restricted", CoreProductAllowed: true, CommercialBenefitProgramAllowedAfterApproval: false, PricePolicy: "module_based_paid"},
			PlanEnterprisePrivacy: {Description: "enterprise", CoreProductAllowed: true, CommercialBenefitProgramAllowedAfterApproval: false, PricePolicy: "custom_quote"},
		},
		PricingPolicy: PricingPolicy{
			Pix2piCanSetMonthlyYearlyPeriodicPrices:            true,
			FirstYearDiscountOrFreeDoesNotCreatePermanentRight: true,
			RenewalPricesCanChange:                             true,
			ModuleBasedPricingCanApplyWhenDataModelDeclined:    true,
			CustomerMayCancelBeforeRenewalIfNewPriceDeclined:   true,
		},
		RequiredDocuments: []ContractDocument{
			doc("abonelik_hizmet_sozlesmesi"),
			doc("kullanim_sartlari"),
			doc("gizlilik_politikasi"),
			doc("kvkk_aydinlatma_metni"),
			doc("acik_riza_metni"),
			doc("cerez_politikasi"),
			doc("veri_isleme_ek_protokolu"),
			doc("sla_destek_politikasi"),
			doc("iptal_iade_politikasi"),
			doc("muhasebeci_portali_ek_sartlari"),
			doc("paket_fiyat_entitlement_ek_sartlari"),
			doc("ticari_fayda_programi_ek_sartlari"),
		},
	}
}

func doc(slug string) ContractDocument {
	return ContractDocument{
		Slug:              slug,
		PublicNameTR:      slug,
		File:              "contracts/faz5r/public_launch/" + slug + ".tr.md",
		Status:            ContractDraft,
		Version:           "0.2.0-draft-fix",
		RequiredApprovals: []string{"hukukcu_onayi"},
	}
}

func TestDraftContractSetIsStructurallyValid(t *testing.T) {
	manifest := draftManifest()

	if issues := manifest.Validate(); len(issues) != 0 {
		t.Fatalf("expected draft manifest to be structurally valid, got issues: %#v", issues)
	}
}

func TestCoreProductCanBeUsedWhileDataMonetizationIsClosed(t *testing.T) {
	manifest := draftManifest()

	if !manifest.CoreProductCanBeUsed() {
		t.Fatal("core product should be allowed separately")
	}

	if manifest.DataMonetizationCanGoPublic() {
		t.Fatal("data monetization must remain closed in draft/pending state")
	}
}

func TestDraftContractSetIsNotPublicPublishable(t *testing.T) {
	manifest := draftManifest()

	if manifest.ReadyForPublicPublish() {
		t.Fatal("draft manifest must not be ready for public publish")
	}
}

func TestRequiredContractDocumentsAreMandatory(t *testing.T) {
	manifest := draftManifest()
	manifest.RequiredDocuments = manifest.RequiredDocuments[:len(manifest.RequiredDocuments)-1]

	issues := manifest.Validate()
	if len(issues) == 0 {
		t.Fatal("expected missing required document issue")
	}

	found := false
	for _, issue := range issues {
		if issue.Code == "missing_required_document" {
			found = true
			break
		}
	}

	if !found {
		t.Fatalf("expected missing_required_document issue, got: %#v", issues)
	}
}

func TestRestrictedPaidPlanIsMandatory(t *testing.T) {
	manifest := draftManifest()
	delete(manifest.PlanModes, PlanRestrictedPaid)

	issues := manifest.Validate()
	if len(issues) == 0 {
		t.Fatal("expected missing restricted paid plan issue")
	}
}

func TestDataMonetizationCannotOpenWithoutApprovalGate(t *testing.T) {
	manifest := draftManifest()
	manifest.DataMonetizationPublicAllowed = true

	if manifest.DataMonetizationCanGoPublic() {
		t.Fatal("data monetization must not go public without approval and public publish")
	}
}
