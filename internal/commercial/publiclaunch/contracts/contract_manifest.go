package contracts

type ApprovalStatus string
type ContractStatus string
type PlanMode string

const (
	ApprovalPending  ApprovalStatus = "PENDING"
	ApprovalApproved ApprovalStatus = "APPROVED"
	ApprovalRejected ApprovalStatus = "REJECTED"

	ContractDraft     ContractStatus = "DRAFT"
	ContractApproved  ContractStatus = "APPROVED"
	ContractPublished ContractStatus = "PUBLISHED"

	PlanDataSupported     PlanMode = "DATA_SUPPORTED"
	PlanRestrictedPaid    PlanMode = "RESTRICTED_PAID"
	PlanEnterprisePrivacy PlanMode = "ENTERPRISE_PRIVACY"
)

type ApprovalGate struct {
	Status                  ApprovalStatus `json:"status"`
	RequiredForPublicLaunch bool           `json:"required_for_public_launch"`
}

type BusinessTerms struct {
	SystemName                            string `json:"system_name"`
	DataSupportedPlanEnabledAfterApproval bool   `json:"data_supported_plan_enabled_after_approval"`
	RestrictedPaidPlanSupported           bool   `json:"restricted_paid_plan_supported"`
	ModuleBasedPricingSupported           bool   `json:"module_based_pricing_supported"`
	EnterprisePrivacyPlanSupported        bool   `json:"enterprise_privacy_plan_supported"`
	CommercialBenefitProgramSupported     bool   `json:"commercial_benefit_program_supported"`
	ProcurementRecommendationSupported    bool   `json:"procurement_recommendation_supported"`
	PooledPurchasingSupported             bool   `json:"pooled_purchasing_supported"`
	SponsoredOfferSupported               bool   `json:"sponsored_offer_supported"`
	AnonymousAggregatedInsightSupported   bool   `json:"anonymous_aggregated_insight_supported"`
	Pix2piSupplierResellerRoleSupported   bool   `json:"pix2pi_supplier_reseller_role_supported"`
}

type RuntimeGateContract struct {
	ConsentRegistryRequired                bool `json:"consent_registry_required"`
	CommercialPreferenceRegistryRequired   bool `json:"commercial_preference_registry_required"`
	EntitlementRuntimeRequired             bool `json:"entitlement_runtime_required"`
	PlanPricingEngineRequired              bool `json:"plan_pricing_engine_required"`
	FeatureGateMiddlewareRequired          bool `json:"feature_gate_middleware_required"`
	DataPipelineGuardRequired              bool `json:"data_pipeline_guard_required"`
	SponsoredOfferGuardRequired            bool `json:"sponsored_offer_guard_required"`
	ProcurementRecommendationGuardRequired bool `json:"procurement_recommendation_guard_required"`
}

type PricingPolicy struct {
	Pix2piCanSetMonthlyYearlyPeriodicPrices            bool `json:"pix2pi_can_set_monthly_yearly_periodic_prices"`
	FirstYearDiscountOrFreeDoesNotCreatePermanentRight bool `json:"first_year_discount_or_free_does_not_create_permanent_right"`
	RenewalPricesCanChange                             bool `json:"renewal_prices_can_change"`
	ModuleBasedPricingCanApplyWhenDataModelDeclined    bool `json:"module_based_pricing_can_apply_when_data_model_declined"`
	CustomerMayCancelBeforeRenewalIfNewPriceDeclined   bool `json:"customer_may_cancel_before_renewal_if_new_price_declined"`
}

type PlanModeContract struct {
	Description                                  string `json:"description"`
	CoreProductAllowed                           bool   `json:"core_product_allowed"`
	CommercialBenefitProgramAllowedAfterApproval bool   `json:"commercial_benefit_program_allowed_after_approval"`
	PricePolicy                                  string `json:"price_policy"`
}

type ContractDocument struct {
	Slug              string         `json:"slug"`
	PublicNameTR      string         `json:"public_name_tr"`
	File              string         `json:"file"`
	Status            ContractStatus `json:"status"`
	Version           string         `json:"version"`
	RequiredApprovals []string       `json:"required_approvals"`
}

type ContractSetManifest struct {
	Phase                                 string                        `json:"phase"`
	StepNo                                int                           `json:"step_no"`
	StepCode                              string                        `json:"step_code"`
	Slug                                  string                        `json:"slug"`
	Module                                string                        `json:"module"`
	TitleTR                               string                        `json:"title_tr"`
	SetVersion                            string                        `json:"set_version"`
	Status                                ContractStatus                `json:"status"`
	PublicPublishAllowed                  bool                          `json:"public_publish_allowed"`
	PublicCoreProductAllowed              bool                          `json:"public_core_product_allowed"`
	PublicContractDraftAllowed            bool                          `json:"public_contract_draft_allowed"`
	DataMonetizationPublicAllowed         bool                          `json:"data_monetization_public_allowed"`
	LegalKVKKApprovalRequiredForDataModel bool                          `json:"legal_kvkk_approval_required_for_data_model"`
	LegalApprovalRequired                 bool                          `json:"legal_approval_required"`
	KvkkApprovalRequired                  bool                          `json:"kvkk_approval_required"`
	ProductionReady                       bool                          `json:"production_ready"`
	BusinessTerms                         BusinessTerms                 `json:"business_terms"`
	RuntimeGateContract                   RuntimeGateContract           `json:"runtime_gate_contract"`
	ApprovalGates                         map[string]ApprovalGate       `json:"approval_gates"`
	PlanModes                             map[PlanMode]PlanModeContract `json:"plan_modes"`
	PricingPolicy                         PricingPolicy                 `json:"pricing_policy"`
	RequiredDocuments                     []ContractDocument            `json:"required_documents"`
}

type ValidationIssue struct {
	Field   string
	Code    string
	Message string
}

func (m ContractSetManifest) Validate() []ValidationIssue {
	var issues []ValidationIssue

	add := func(field, code, message string) {
		issues = append(issues, ValidationIssue{Field: field, Code: code, Message: message})
	}

	if m.StepNo != 242 {
		add("step_no", "invalid_step_no", "contract set manifest must belong to step 242")
	}

	if m.StepCode != "FAZ_5_18_3_1" {
		add("step_code", "invalid_step_code", "contract set manifest must belong to FAZ_5_18_3_1")
	}

	if m.BusinessTerms.SystemName != "Pix2pi Ticaret Operasyon Sistemi" {
		add("business_terms.system_name", "invalid_system_name", "system name must be Pix2pi Ticaret Operasyon Sistemi")
	}

	if !m.PublicCoreProductAllowed {
		add("public_core_product_allowed", "core_product_must_be_allowed", "core product can be allowed separately from data monetization")
	}

	if m.PublicContractDraftAllowed {
		add("public_contract_draft_allowed", "draft_contract_must_not_be_public", "draft contracts must not be connected to production approval flow")
	}

	if m.DataMonetizationPublicAllowed {
		add("data_monetization_public_allowed", "data_monetization_requires_approval", "data monetization must remain closed while legal/KVKK approvals are pending")
	}

	if !m.LegalKVKKApprovalRequiredForDataModel {
		add("legal_kvkk_approval_required_for_data_model", "approval_gate_required", "data monetization must require legal and KVKK approval")
	}

	if !m.LegalApprovalRequired {
		add("legal_approval_required", "legal_approval_must_be_required", "legal approval must be required before public launch")
	}

	if !m.KvkkApprovalRequired {
		add("kvkk_approval_required", "kvkk_approval_must_be_required", "KVKK approval must be required before public launch")
	}

	if !m.BusinessTerms.RestrictedPaidPlanSupported {
		add("business_terms.restricted_paid_plan_supported", "restricted_paid_plan_required", "restricted paid plan must exist when data supported plan is declined")
	}

	if !m.BusinessTerms.ModuleBasedPricingSupported {
		add("business_terms.module_based_pricing_supported", "module_pricing_required", "module based pricing must be supported")
	}

	if !m.BusinessTerms.CommercialBenefitProgramSupported {
		add("business_terms.commercial_benefit_program_supported", "commercial_benefit_program_required", "commercial benefit program must be supported")
	}

	if !m.PricingPolicy.RenewalPricesCanChange {
		add("pricing_policy.renewal_prices_can_change", "renewal_price_policy_required", "renewal price changes must be contractually declared")
	}

	requiredGates := []string{"hukukcu_onayi", "kvkk_danismani_onayi", "ticari_operasyon_onayi", "founder_go_no_go"}
	for _, gate := range requiredGates {
		approval, ok := m.ApprovalGates[gate]
		if !ok {
			add("approval_gates."+gate, "missing_approval_gate", "required approval gate is missing")
			continue
		}
		if approval.Status != ApprovalPending && approval.Status != ApprovalApproved && approval.Status != ApprovalRejected {
			add("approval_gates."+gate, "invalid_approval_status", "approval status is invalid")
		}
		if !approval.RequiredForPublicLaunch {
			add("approval_gates."+gate, "gate_must_be_required", "approval gate must be required for public launch")
		}
	}

	requiredPlanModes := []PlanMode{PlanDataSupported, PlanRestrictedPaid, PlanEnterprisePrivacy}
	for _, mode := range requiredPlanModes {
		plan, ok := m.PlanModes[mode]
		if !ok {
			add("plan_modes."+string(mode), "missing_plan_mode", "required plan mode is missing")
			continue
		}
		if !plan.CoreProductAllowed {
			add("plan_modes."+string(mode), "core_product_should_be_allowed", "core product should remain available by plan")
		}
	}

	requiredDocuments := map[string]bool{
		"abonelik_hizmet_sozlesmesi":          true,
		"kullanim_sartlari":                   true,
		"gizlilik_politikasi":                 true,
		"kvkk_aydinlatma_metni":               true,
		"acik_riza_metni":                     true,
		"cerez_politikasi":                    true,
		"veri_isleme_ek_protokolu":            true,
		"sla_destek_politikasi":               true,
		"iptal_iade_politikasi":               true,
		"muhasebeci_portali_ek_sartlari":      true,
		"paket_fiyat_entitlement_ek_sartlari": true,
		"ticari_fayda_programi_ek_sartlari":   true,
	}

	seen := map[string]bool{}
	for _, doc := range m.RequiredDocuments {
		if doc.Slug == "" {
			add("required_documents", "missing_document_slug", "document slug is required")
		}
		if doc.File == "" {
			add("required_documents", "missing_document_file", "document file path is required")
		}
		if doc.Version == "" {
			add("required_documents", "missing_document_version", "document version is required")
		}
		if doc.Status == "" {
			add("required_documents", "missing_document_status", "document status is required")
		}
		if len(doc.RequiredApprovals) == 0 {
			add("required_documents", "missing_document_approvals", "document must declare required approvals")
		}
		seen[doc.Slug] = true
	}

	for slug := range requiredDocuments {
		if !seen[slug] {
			add("required_documents."+slug, "missing_required_document", "required contract document is missing")
		}
	}

	if m.PublicPublishAllowed || m.ProductionReady {
		for gate, approval := range m.ApprovalGates {
			if approval.RequiredForPublicLaunch && approval.Status != ApprovalApproved {
				add("approval_gates."+gate, "approval_required_before_publish", "required approval gate must be approved before public publish")
			}
		}
	}

	return issues
}

func (m ContractSetManifest) ReadyForPublicPublish() bool {
	if !m.PublicPublishAllowed || m.PublicContractDraftAllowed || m.DataMonetizationPublicAllowed {
		return false
	}
	return len(m.Validate()) == 0
}

func (m ContractSetManifest) CoreProductCanBeUsed() bool {
	return m.PublicCoreProductAllowed
}

func (m ContractSetManifest) DataMonetizationCanGoPublic() bool {
	if !m.DataMonetizationPublicAllowed {
		return false
	}
	return m.ReadyForPublicPublish()
}
