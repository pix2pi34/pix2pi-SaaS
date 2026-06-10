package privacy

type ApprovalStatus string
type DocumentStatus string
type ConsentScope string

const (
	ApprovalPending  ApprovalStatus = "PENDING"
	ApprovalApproved ApprovalStatus = "APPROVED"
	ApprovalRejected ApprovalStatus = "REJECTED"

	DocumentDraft     DocumentStatus = "DRAFT"
	DocumentApproved  DocumentStatus = "APPROVED"
	DocumentPublished DocumentStatus = "PUBLISHED"

	ScopeDataSupportedPlanTerms               ConsentScope = "DATA_SUPPORTED_PLAN_TERMS"
	ScopePersonalDataCommercialRecommendation ConsentScope = "PERSONAL_DATA_COMMERCIAL_RECOMMENDATION"
	ScopeSponsoredOfferPersonalization        ConsentScope = "SPONSORED_OFFER_PERSONALIZATION"
	ScopeAnonymizedAggregatedInsight          ConsentScope = "ANONYMIZED_AGGREGATED_INSIGHT"
	ScopeAIDecisionSupport                    ConsentScope = "AI_DECISION_SUPPORT"
	ScopeCommercialElectronicMessage          ConsentScope = "COMMERCIAL_ELECTRONIC_MESSAGE"
	ScopeNonEssentialCookies                  ConsentScope = "NON_ESSENTIAL_COOKIES"
)

type ApprovalGate struct {
	Status                  ApprovalStatus `json:"status"`
	RequiredForPublicLaunch bool           `json:"required_for_public_launch"`
}

type SeparationRules struct {
	PrivacyNoticeSeparateFromExplicitConsent                      bool `json:"privacy_notice_separate_from_explicit_consent"`
	CookiePolicySeparate                                          bool `json:"cookie_policy_separate"`
	CommercialElectronicMessageConsentSeparate                    bool `json:"commercial_electronic_message_consent_separate"`
	DataSupportedPlanContractTermsSeparateFromPersonalDataConsent bool `json:"data_supported_plan_contract_terms_separate_from_personal_data_consent"`
}

type RuntimeContract struct {
	ConsentRegistryRequired               bool `json:"consent_registry_required"`
	ConsentVersioningRequired             bool `json:"consent_versioning_required"`
	ConsentRevocationRequired             bool `json:"consent_revocation_required"`
	TenantScopedConsentRequired           bool `json:"tenant_scoped_consent_required"`
	UserScopedConsentRequired             bool `json:"user_scoped_consent_required"`
	EvidenceHashRequired                  bool `json:"evidence_hash_required"`
	FeatureGateIntegrationRequired        bool `json:"feature_gate_integration_required"`
	DataPipelineGuardRequired             bool `json:"data_pipeline_guard_required"`
	CommercialMessageConsentGuardRequired bool `json:"commercial_message_consent_guard_required"`
	CookiePreferenceGuardRequired         bool `json:"cookie_preference_guard_required"`
}

type PrivacyDocument struct {
	Slug                 string         `json:"slug"`
	TitleTR              string         `json:"title_tr"`
	File                 string         `json:"file"`
	Status               DocumentStatus `json:"status"`
	Version              string         `json:"version"`
	PublicPublishAllowed bool           `json:"public_publish_allowed"`
	RequiredApprovals    []string       `json:"required_approvals"`
}

type PrivacyManifest struct {
	Phase                         string                  `json:"phase"`
	StepNo                        int                     `json:"step_no"`
	StepCode                      string                  `json:"step_code"`
	Slug                          string                  `json:"slug"`
	Module                        string                  `json:"module"`
	TitleTR                       string                  `json:"title_tr"`
	SetVersion                    string                  `json:"set_version"`
	Status                        DocumentStatus          `json:"status"`
	PublicPublishAllowed          bool                    `json:"public_publish_allowed"`
	PublicCoreProductAllowed      bool                    `json:"public_core_product_allowed"`
	DataMonetizationPublicAllowed bool                    `json:"data_monetization_public_allowed"`
	LegalApprovalRequired         bool                    `json:"legal_approval_required"`
	KvkkApprovalRequired          bool                    `json:"kvkk_approval_required"`
	ProductionReady               bool                    `json:"production_ready"`
	SeparationRules               SeparationRules         `json:"separation_rules"`
	ApprovalGates                 map[string]ApprovalGate `json:"approval_gates"`
	RuntimeContract               RuntimeContract         `json:"runtime_contract"`
	PrivacyDocuments              []PrivacyDocument       `json:"privacy_documents"`
	RequiredConsentScopes         []ConsentScope          `json:"required_consent_scopes"`
}

type ValidationIssue struct {
	Field   string
	Code    string
	Message string
}

func (m PrivacyManifest) Validate() []ValidationIssue {
	var issues []ValidationIssue

	add := func(field, code, message string) {
		issues = append(issues, ValidationIssue{Field: field, Code: code, Message: message})
	}

	if m.StepNo != 243 {
		add("step_no", "invalid_step_no", "privacy manifest must belong to step 243")
	}

	if m.StepCode != "FAZ_5_18_3_2" {
		add("step_code", "invalid_step_code", "privacy manifest must belong to FAZ_5_18_3_2")
	}

	if m.PublicPublishAllowed {
		add("public_publish_allowed", "draft_privacy_must_not_be_public", "draft privacy docs must not be public before approvals")
	}

	if !m.PublicCoreProductAllowed {
		add("public_core_product_allowed", "core_product_should_remain_allowed", "core product can be allowed separately")
	}

	if m.DataMonetizationPublicAllowed {
		add("data_monetization_public_allowed", "data_monetization_requires_approval", "data monetization must remain closed in draft")
	}

	if !m.LegalApprovalRequired {
		add("legal_approval_required", "legal_approval_required", "legal approval must be required")
	}

	if !m.KvkkApprovalRequired {
		add("kvkk_approval_required", "kvkk_approval_required", "KVKK approval must be required")
	}

	if !m.SeparationRules.PrivacyNoticeSeparateFromExplicitConsent {
		add("separation_rules.privacy_notice", "privacy_notice_must_be_separate", "privacy notice must be separate from explicit consent")
	}

	if !m.SeparationRules.CommercialElectronicMessageConsentSeparate {
		add("separation_rules.commercial_message", "commercial_message_consent_must_be_separate", "commercial electronic message consent must be separate")
	}

	if !m.RuntimeContract.ConsentRegistryRequired ||
		!m.RuntimeContract.ConsentVersioningRequired ||
		!m.RuntimeContract.ConsentRevocationRequired ||
		!m.RuntimeContract.FeatureGateIntegrationRequired {
		add("runtime_contract", "runtime_contract_incomplete", "consent runtime contract is incomplete")
	}

	requiredDocs := map[string]bool{
		"privacy_notice":                        true,
		"privacy_policy":                        true,
		"explicit_consent":                      true,
		"cookie_policy":                         true,
		"commercial_electronic_message_consent": true,
		"data_processing_inventory":             true,
		"privacy_preference_matrix":             true,
		"consent_registry_runtime_contract":     true,
	}

	seenDocs := map[string]bool{}
	for _, doc := range m.PrivacyDocuments {
		seenDocs[doc.Slug] = true
		if doc.Status != DocumentDraft {
			add("privacy_documents."+doc.Slug, "document_must_be_draft", "document must be draft at this stage")
		}
		if doc.PublicPublishAllowed {
			add("privacy_documents."+doc.Slug, "document_public_not_allowed", "document public publish must be false")
		}
		if doc.Version == "" {
			add("privacy_documents."+doc.Slug, "missing_version", "document version is required")
		}
		if len(doc.RequiredApprovals) == 0 {
			add("privacy_documents."+doc.Slug, "missing_required_approvals", "required approvals must be declared")
		}
	}

	for slug := range requiredDocs {
		if !seenDocs[slug] {
			add("privacy_documents."+slug, "missing_required_document", "required privacy document is missing")
		}
	}

	requiredScopes := map[ConsentScope]bool{
		ScopeDataSupportedPlanTerms:               true,
		ScopePersonalDataCommercialRecommendation: true,
		ScopeSponsoredOfferPersonalization:        true,
		ScopeAnonymizedAggregatedInsight:          true,
		ScopeAIDecisionSupport:                    true,
		ScopeCommercialElectronicMessage:          true,
		ScopeNonEssentialCookies:                  true,
	}

	seenScopes := map[ConsentScope]bool{}
	for _, scope := range m.RequiredConsentScopes {
		seenScopes[scope] = true
	}

	for scope := range requiredScopes {
		if !seenScopes[scope] {
			add("required_consent_scopes."+string(scope), "missing_required_scope", "required consent scope is missing")
		}
	}

	return issues
}

func (m PrivacyManifest) CanPublishPrivacyDocs() bool {
	return m.PublicPublishAllowed && len(m.Validate()) == 0
}

func (m PrivacyManifest) CanRunCoreProduct() bool {
	return m.PublicCoreProductAllowed
}

func (m PrivacyManifest) CanRunDataMonetization() bool {
	return m.DataMonetizationPublicAllowed && m.CanPublishPrivacyDocs()
}
