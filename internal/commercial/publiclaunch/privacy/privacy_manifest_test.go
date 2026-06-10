package privacy

import "testing"

func draftManifest() PrivacyManifest {
	return PrivacyManifest{
		Phase:                         "FAZ 5-R",
		StepNo:                        243,
		StepCode:                      "FAZ_5_18_3_2",
		Slug:                          "faz_5_18_3_2_kvkk_gizlilik_metinleri",
		Module:                        "commercial_public_launch_privacy",
		TitleTR:                       "KVKK / gizlilik metinleri",
		SetVersion:                    "0.1.0-draft",
		Status:                        DocumentDraft,
		PublicPublishAllowed:          false,
		PublicCoreProductAllowed:      true,
		DataMonetizationPublicAllowed: false,
		LegalApprovalRequired:         true,
		KvkkApprovalRequired:          true,
		ProductionReady:               false,
		SeparationRules: SeparationRules{
			PrivacyNoticeSeparateFromExplicitConsent:                      true,
			CookiePolicySeparate:                                          true,
			CommercialElectronicMessageConsentSeparate:                    true,
			DataSupportedPlanContractTermsSeparateFromPersonalDataConsent: true,
		},
		ApprovalGates: map[string]ApprovalGate{
			"hukukcu_onayi":        {Status: ApprovalPending, RequiredForPublicLaunch: true},
			"kvkk_danismani_onayi": {Status: ApprovalPending, RequiredForPublicLaunch: true},
			"founder_go_no_go":     {Status: ApprovalPending, RequiredForPublicLaunch: true},
		},
		RuntimeContract: RuntimeContract{
			ConsentRegistryRequired:               true,
			ConsentVersioningRequired:             true,
			ConsentRevocationRequired:             true,
			TenantScopedConsentRequired:           true,
			UserScopedConsentRequired:             true,
			EvidenceHashRequired:                  true,
			FeatureGateIntegrationRequired:        true,
			DataPipelineGuardRequired:             true,
			CommercialMessageConsentGuardRequired: true,
			CookiePreferenceGuardRequired:         true,
		},
		PrivacyDocuments: []PrivacyDocument{
			doc("privacy_notice"),
			doc("privacy_policy"),
			doc("explicit_consent"),
			doc("cookie_policy"),
			doc("commercial_electronic_message_consent"),
			doc("data_processing_inventory"),
			doc("privacy_preference_matrix"),
			doc("consent_registry_runtime_contract"),
		},
		RequiredConsentScopes: []ConsentScope{
			ScopeDataSupportedPlanTerms,
			ScopePersonalDataCommercialRecommendation,
			ScopeSponsoredOfferPersonalization,
			ScopeAnonymizedAggregatedInsight,
			ScopeAIDecisionSupport,
			ScopeCommercialElectronicMessage,
			ScopeNonEssentialCookies,
		},
	}
}

func doc(slug string) PrivacyDocument {
	return PrivacyDocument{
		Slug:                 slug,
		TitleTR:              slug,
		File:                 "privacy/faz5r/public_launch/" + slug + ".tr.md",
		Status:               DocumentDraft,
		Version:              "0.1.0-draft",
		PublicPublishAllowed: false,
		RequiredApprovals:    []string{"kvkk_danismani_onayi"},
	}
}

func TestDraftManifestIsStructurallyValid(t *testing.T) {
	manifest := draftManifest()
	if issues := manifest.Validate(); len(issues) != 0 {
		t.Fatalf("expected no validation issues, got %#v", issues)
	}
}

func TestCoreProductAllowedButDataMonetizationClosed(t *testing.T) {
	manifest := draftManifest()

	if !manifest.CanRunCoreProduct() {
		t.Fatal("core product should remain allowed")
	}

	if manifest.CanRunDataMonetization() {
		t.Fatal("data monetization must remain closed")
	}
}

func TestPrivacyDocsCannotPublishInDraft(t *testing.T) {
	manifest := draftManifest()

	if manifest.CanPublishPrivacyDocs() {
		t.Fatal("draft privacy docs must not be publishable")
	}
}

func TestRequiredConsentScopesAreMandatory(t *testing.T) {
	manifest := draftManifest()
	manifest.RequiredConsentScopes = manifest.RequiredConsentScopes[:len(manifest.RequiredConsentScopes)-1]

	issues := manifest.Validate()
	if len(issues) == 0 {
		t.Fatal("expected missing required consent scope")
	}
}

func TestPrivacyNoticeMustBeSeparateFromExplicitConsent(t *testing.T) {
	manifest := draftManifest()
	manifest.SeparationRules.PrivacyNoticeSeparateFromExplicitConsent = false

	issues := manifest.Validate()
	if len(issues) == 0 {
		t.Fatal("expected separation rule issue")
	}
}
