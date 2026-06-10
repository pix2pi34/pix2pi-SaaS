package pricingpages

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type SectionStatus string

const (
	StatusReady       SectionStatus = "READY"
	StatusPendingNext SectionStatus = "PENDING_NEXT"
	StatusBlocked     SectionStatus = "BLOCKED"
)

type PageDomain string

const (
	DomainPricingOverview PageDomain = "PRICING_OVERVIEW"
	DomainPlanComparison  PageDomain = "PLAN_COMPARISON"
	DomainPublicCopy      PageDomain = "PUBLIC_COPY"
	DomainVATNotice       PageDomain = "VAT_NOTICE"
	DomainCTA             PageDomain = "CTA"
	DomainAccountant      PageDomain = "ACCOUNTANT_PACKAGE"
	DomainLaunchGuard     PageDomain = "LAUNCH_GUARD"
	DomainWebTestsNext    PageDomain = "WEB_TESTS_NEXT"
)

type PricingPageSection struct {
	Key                             string
	Domain                          PageDomain
	Title                           string
	Owner                           string
	Status                          SectionStatus
	Required                        bool
	HasEvidence                     bool
	HasCounterBasedAudit            bool
	RequiredFailCount               int
	OptionalWarnCount               int
	ProductionPagePublished         bool
	RealCustomerSignupEnabled       bool
	CheckoutEnabled                 bool
	PaymentCollectionEnabled        bool
	PublicPricingVisible            bool
	RequiresPricingTableSource      bool
	RequiresAccountantPackageSource bool
	RequiresValidatedPricing        bool
	RequiresCurrency                bool
	RequiresVATNotice               bool
	RequiresPlanComparison          bool
	RequiresFeatureSummary          bool
	RequiresEntitlementReference    bool
	RequiresCTA                     bool
	RequiresLegalReview             bool
	RequiresFounderApproval         bool
	RequiresChangeLog               bool
	RequiresAuditTrail              bool
	RequiresPublicCopyGuard         bool
	BlocksProductionPublish         bool
	BlocksRealCustomerSignup        bool
	BlocksCheckout                  bool
	BlocksPaymentCollection         bool
	DeferredToWebTests              bool
	DeferredReason                  string
}

type PageInput struct {
	Phase                          string
	Target                         string
	InternalPricingPagesReady      bool
	StaticHTMLReady                bool
	ProductionPagePublished        bool
	RealCustomerSignupEnabled      bool
	CheckoutEnabled                bool
	PaymentCollectionEnabled       bool
	PublicPricingVisible           bool
	RequiredSectionKeys            []string
	RequiredDomains                []PageDomain
	Sections                       []PricingPageSection
	RequireEvidence                bool
	RequireCounterBasedAudit       bool
	RequireNoRequiredFail          bool
	RequireNoOptionalWarn          bool
	RequirePricingTableSource      bool
	RequireAccountantPackageSource bool
	RequireValidatedPricing        bool
	RequireCurrency                bool
	RequireVATNotice               bool
	RequirePlanComparison          bool
	RequireFeatureSummary          bool
	RequireEntitlementReference    bool
	RequireCTA                     bool
	RequireLegalReview             bool
	RequireFounderApproval         bool
	RequireChangeLog               bool
	RequireAuditTrail              bool
	RequirePublicCopyGuard         bool
	RequireProductionPublishBlock  bool
	RequireRealCustomerSignupBlock bool
	RequireCheckoutBlock           bool
	RequirePaymentCollectionBlock  bool
	AllowWebTestsDeferred          bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type PageResult struct {
	Status                    string
	InternalPricingPagesReady bool
	StaticHTMLReady           bool
	ProductionPagePublished   bool
	RealCustomerSignupEnabled bool
	CheckoutEnabled           bool
	PaymentCollectionEnabled  bool
	PublicPricingVisible      bool
	RequiredFailCount         int
	OptionalWarnCount         int
	PassCount                 int
	Findings                  []Finding
}

func Evaluate(input PageInput) (PageResult, error) {
	result := PageResult{
		Status:                    "PASS",
		InternalPricingPagesReady: false,
		StaticHTMLReady:           false,
		ProductionPagePublished:   false,
		RealCustomerSignupEnabled: false,
		CheckoutEnabled:           false,
		PaymentCollectionEnabled:  false,
		PublicPricingVisible:      false,
		Findings:                  []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}
	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}
	if input.ProductionPagePublished {
		addFail(&result, "PRODUCTION_PAGE_PUBLISH_BLOCKED", "bu fazda production fiyatlama sayfası yayını açılamaz")
	}
	if input.RealCustomerSignupEnabled {
		addFail(&result, "REAL_CUSTOMER_SIGNUP_BLOCKED", "bu fazda gerçek müşteri kayıt akışı açılamaz")
	}
	if input.CheckoutEnabled {
		addFail(&result, "CHECKOUT_BLOCKED", "bu fazda checkout açılamaz")
	}
	if input.PaymentCollectionEnabled {
		addFail(&result, "PAYMENT_COLLECTION_BLOCKED", "bu fazda gerçek ödeme/tahsilat açılamaz")
	}
	if input.PublicPricingVisible {
		addFail(&result, "PUBLIC_PRICING_VISIBLE_BLOCKED", "bu fazda public pricing görünürlüğü açılamaz")
	}

	sectionByKey := map[string]PricingPageSection{}
	domainCoverage := map[PageDomain]bool{}

	for _, section := range input.Sections {
		key := strings.TrimSpace(section.Key)
		if key == "" {
			addFail(&result, "PRICING_PAGE_SECTION_KEY_MISSING", "pricing page section key boş olamaz")
			continue
		}
		if _, exists := sectionByKey[key]; exists {
			addFail(&result, "PRICING_PAGE_SECTION_DUPLICATE", fmt.Sprintf("pricing page section duplicate: %s", key))
			continue
		}

		sectionByKey[key] = section
		domainCoverage[section.Domain] = true

		if section.Required && section.Status != StatusReady {
			if section.DeferredToWebTests && input.AllowWebTestsDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_SECTION_NOT_READY", fmt.Sprintf("required pricing page section READY değil: %s", key))
			}
		} else if section.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence, section.Required, section.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit, section.Required, section.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, section.Required, section.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, section.Required, section.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequirePricingTableSource, section.Required, section.RequiresPricingTableSource, "PRICING_TABLE_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireAccountantPackageSource, section.Required, section.RequiresAccountantPackageSource, "ACCOUNTANT_PACKAGE_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireValidatedPricing, section.Required, section.RequiresValidatedPricing, "VALIDATED_PRICING_REQUIRED", key)
		checkBool(&result, input.RequireCurrency, section.Required, section.RequiresCurrency, "CURRENCY_REQUIRED", key)
		checkBool(&result, input.RequireVATNotice, section.Required, section.RequiresVATNotice, "VAT_NOTICE_REQUIRED", key)
		checkBool(&result, input.RequirePlanComparison, section.Required, section.RequiresPlanComparison, "PLAN_COMPARISON_REQUIRED", key)
		checkBool(&result, input.RequireFeatureSummary, section.Required, section.RequiresFeatureSummary, "FEATURE_SUMMARY_REQUIRED", key)
		checkBool(&result, input.RequireEntitlementReference, section.Required, section.RequiresEntitlementReference, "ENTITLEMENT_REFERENCE_REQUIRED", key)
		checkBool(&result, input.RequireCTA, section.Required, section.RequiresCTA, "CTA_REQUIRED", key)
		checkBool(&result, input.RequireLegalReview, section.Required, section.RequiresLegalReview, "LEGAL_REVIEW_REQUIRED", key)
		checkBool(&result, input.RequireFounderApproval, section.Required, section.RequiresFounderApproval, "FOUNDER_APPROVAL_REQUIRED", key)
		checkBool(&result, input.RequireChangeLog, section.Required, section.RequiresChangeLog, "CHANGE_LOG_REQUIRED", key)
		checkBool(&result, input.RequireAuditTrail, section.Required, section.RequiresAuditTrail, "AUDIT_TRAIL_REQUIRED", key)
		checkBool(&result, input.RequirePublicCopyGuard, section.Required, section.RequiresPublicCopyGuard, "PUBLIC_COPY_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireProductionPublishBlock, section.Required, section.BlocksProductionPublish, "PRODUCTION_PUBLISH_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealCustomerSignupBlock, section.Required, section.BlocksRealCustomerSignup, "REAL_CUSTOMER_SIGNUP_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireCheckoutBlock, section.Required, section.BlocksCheckout, "CHECKOUT_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequirePaymentCollectionBlock, section.Required, section.BlocksPaymentCollection, "PAYMENT_COLLECTION_BLOCK_REQUIRED", key)

		if section.ProductionPagePublished {
			addFail(&result, "SECTION_PRODUCTION_PAGE_PUBLISHED_BLOCKED", fmt.Sprintf("production page published açık olamaz: %s", key))
		}
		if section.RealCustomerSignupEnabled {
			addFail(&result, "SECTION_REAL_CUSTOMER_SIGNUP_BLOCKED", fmt.Sprintf("real customer signup açık olamaz: %s", key))
		}
		if section.CheckoutEnabled {
			addFail(&result, "SECTION_CHECKOUT_BLOCKED", fmt.Sprintf("checkout açık olamaz: %s", key))
		}
		if section.PaymentCollectionEnabled {
			addFail(&result, "SECTION_PAYMENT_COLLECTION_BLOCKED", fmt.Sprintf("payment collection açık olamaz: %s", key))
		}
		if section.PublicPricingVisible {
			addFail(&result, "SECTION_PUBLIC_PRICING_VISIBLE_BLOCKED", fmt.Sprintf("public pricing visible açık olamaz: %s", key))
		}
		if section.DeferredToWebTests && strings.TrimSpace(section.DeferredReason) == "" {
			addFail(&result, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredSectionKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}
		section, exists := sectionByKey[requiredKey]
		if !exists {
			addFail(&result, "REQUIRED_SECTION_NOT_REGISTERED", fmt.Sprintf("required listesinde olup pricing pages içinde yok: %s", requiredKey))
			continue
		}
		if !section.Required {
			addFail(&result, "REQUIRED_SECTION_FLAG_FALSE", fmt.Sprintf("required listesinde ama section required=false: %s", requiredKey))
			continue
		}
		result.PassCount++
	}

	for _, domain := range input.RequiredDomains {
		if !domainCoverage[domain] {
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("pricing pages domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalPricingPagesReady = input.InternalPricingPagesReady
	result.StaticHTMLReady = input.StaticHTMLReady
	result.ProductionPagePublished = false
	result.RealCustomerSignupEnabled = false
	result.CheckoutEnabled = false
	result.PaymentCollectionEnabled = false
	result.PublicPricingVisible = false
	return result, nil
}

func RequiredSectionKeys(input PageInput) []string {
	keys := make([]string, 0, len(input.RequiredSectionKeys))
	keys = append(keys, input.RequiredSectionKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result PageResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("pricing pages failed")
	}
	return nil
}

func checkBool(result *PageResult, required bool, sectionRequired bool, actual bool, code string, key string) {
	if required && sectionRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if sectionRequired {
		result.PassCount++
	}
}

func checkZero(result *PageResult, required bool, sectionRequired bool, actual int, code string, key string) {
	if required && sectionRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if sectionRequired {
		result.PassCount++
	}
}

func addFail(result *PageResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
