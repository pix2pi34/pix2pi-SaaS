package pricingvalidation

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type ControlStatus string

const (
	StatusReady       ControlStatus = "READY"
	StatusPendingNext ControlStatus = "PENDING_NEXT"
	StatusBlocked     ControlStatus = "BLOCKED"
)

type ValidationDomain string

const (
	DomainPricingTable      ValidationDomain = "PRICING_TABLE"
	DomainAccountantPackage ValidationDomain = "ACCOUNTANT_PACKAGE"
	DomainVATPolicy         ValidationDomain = "VAT_POLICY"
	DomainBillingGate       ValidationDomain = "BILLING_GATE"
	DomainPaymentGate       ValidationDomain = "PAYMENT_GATE"
	DomainPublicCopy        ValidationDomain = "PUBLIC_COPY"
	DomainApproval          ValidationDomain = "APPROVAL"
	DomainDeveloperDocsNext ValidationDomain = "DEVELOPER_DOCS_NEXT"
)

type ValidationControl struct {
	Key                              string
	Domain                           ValidationDomain
	Title                            string
	Owner                            string
	Status                           ControlStatus
	Required                         bool
	HasEvidence                      bool
	HasCounterBasedAudit             bool
	RequiredFailCount                int
	OptionalWarnCount                int
	ProductionPricingPublished       bool
	RealCustomerBillingEnabled       bool
	PaymentCollectionEnabled         bool
	PublicCheckoutEnabled            bool
	RequiresPricingTableSource       bool
	RequiresAccountantPackageSource  bool
	RequiresPlanCodeConsistency      bool
	RequiresCurrencyConsistency      bool
	RequiresVATPolicyConsistency     bool
	RequiresAnnualMonthlyConsistency bool
	RequiresEntitlementConsistency   bool
	RequiresBillingGateClosed        bool
	RequiresPaymentGateClosed        bool
	RequiresPublicCopyGuard          bool
	RequiresLegalReview              bool
	RequiresFounderApproval          bool
	RequiresChangeLog                bool
	RequiresAuditTrail               bool
	BlocksProductionPublish          bool
	BlocksRealCustomerBilling        bool
	BlocksPaymentCollection          bool
	BlocksPublicCheckout             bool
	DeferredToDeveloperDocsPortal    bool
	DeferredReason                   string
}

type ValidationInput struct {
	Phase                            string
	Target                           string
	InternalPricingValidationReady   bool
	ProductionPricingPublished       bool
	RealCustomerBillingEnabled       bool
	PaymentCollectionEnabled         bool
	PublicCheckoutEnabled            bool
	RequiredControlKeys              []string
	RequiredDomains                  []ValidationDomain
	Controls                         []ValidationControl
	RequireEvidence                  bool
	RequireCounterBasedAudit         bool
	RequireNoRequiredFail            bool
	RequireNoOptionalWarn            bool
	RequirePricingTableSource        bool
	RequireAccountantPackageSource   bool
	RequirePlanCodeConsistency       bool
	RequireCurrencyConsistency       bool
	RequireVATPolicyConsistency      bool
	RequireAnnualMonthlyConsistency  bool
	RequireEntitlementConsistency    bool
	RequireBillingGateClosed         bool
	RequirePaymentGateClosed         bool
	RequirePublicCopyGuard           bool
	RequireLegalReview               bool
	RequireFounderApproval           bool
	RequireChangeLog                 bool
	RequireAuditTrail                bool
	RequireProductionPublishBlock    bool
	RequireRealCustomerBillingBlock  bool
	RequirePaymentCollectionBlock    bool
	RequirePublicCheckoutBlock       bool
	AllowDeveloperDocsPortalDeferred bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ValidationResult struct {
	Status                         string
	InternalPricingValidationReady bool
	ProductionPricingPublished     bool
	RealCustomerBillingEnabled     bool
	PaymentCollectionEnabled       bool
	PublicCheckoutEnabled          bool
	RequiredFailCount              int
	OptionalWarnCount              int
	PassCount                      int
	Findings                       []Finding
}

func Evaluate(input ValidationInput) (ValidationResult, error) {
	result := ValidationResult{
		Status:                         "PASS",
		InternalPricingValidationReady: false,
		ProductionPricingPublished:     false,
		RealCustomerBillingEnabled:     false,
		PaymentCollectionEnabled:       false,
		PublicCheckoutEnabled:          false,
		Findings:                       []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}
	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}
	if input.ProductionPricingPublished {
		addFail(&result, "PRODUCTION_PRICING_PUBLISH_BLOCKED", "bu fazda production pricing publish açılamaz")
	}
	if input.RealCustomerBillingEnabled {
		addFail(&result, "REAL_CUSTOMER_BILLING_BLOCKED", "bu fazda gerçek müşteri billing açılamaz")
	}
	if input.PaymentCollectionEnabled {
		addFail(&result, "PAYMENT_COLLECTION_BLOCKED", "bu fazda gerçek tahsilat açılamaz")
	}
	if input.PublicCheckoutEnabled {
		addFail(&result, "PUBLIC_CHECKOUT_BLOCKED", "bu fazda public checkout açılamaz")
	}

	controlByKey := map[string]ValidationControl{}
	domainCoverage := map[ValidationDomain]bool{}

	for _, control := range input.Controls {
		key := strings.TrimSpace(control.Key)
		if key == "" {
			addFail(&result, "VALIDATION_CONTROL_KEY_MISSING", "validation control key boş olamaz")
			continue
		}
		if _, exists := controlByKey[key]; exists {
			addFail(&result, "VALIDATION_CONTROL_DUPLICATE", fmt.Sprintf("validation control duplicate: %s", key))
			continue
		}

		controlByKey[key] = control
		domainCoverage[control.Domain] = true

		if control.Required && control.Status != StatusReady {
			if control.DeferredToDeveloperDocsPortal && input.AllowDeveloperDocsPortalDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_CONTROL_NOT_READY", fmt.Sprintf("required validation control READY değil: %s", key))
			}
		} else if control.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence, control.Required, control.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit, control.Required, control.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, control.Required, control.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, control.Required, control.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequirePricingTableSource, control.Required, control.RequiresPricingTableSource, "PRICING_TABLE_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireAccountantPackageSource, control.Required, control.RequiresAccountantPackageSource, "ACCOUNTANT_PACKAGE_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequirePlanCodeConsistency, control.Required, control.RequiresPlanCodeConsistency, "PLAN_CODE_CONSISTENCY_REQUIRED", key)
		checkBool(&result, input.RequireCurrencyConsistency, control.Required, control.RequiresCurrencyConsistency, "CURRENCY_CONSISTENCY_REQUIRED", key)
		checkBool(&result, input.RequireVATPolicyConsistency, control.Required, control.RequiresVATPolicyConsistency, "VAT_POLICY_CONSISTENCY_REQUIRED", key)
		checkBool(&result, input.RequireAnnualMonthlyConsistency, control.Required, control.RequiresAnnualMonthlyConsistency, "ANNUAL_MONTHLY_CONSISTENCY_REQUIRED", key)
		checkBool(&result, input.RequireEntitlementConsistency, control.Required, control.RequiresEntitlementConsistency, "ENTITLEMENT_CONSISTENCY_REQUIRED", key)
		checkBool(&result, input.RequireBillingGateClosed, control.Required, control.RequiresBillingGateClosed, "BILLING_GATE_CLOSED_REQUIRED", key)
		checkBool(&result, input.RequirePaymentGateClosed, control.Required, control.RequiresPaymentGateClosed, "PAYMENT_GATE_CLOSED_REQUIRED", key)
		checkBool(&result, input.RequirePublicCopyGuard, control.Required, control.RequiresPublicCopyGuard, "PUBLIC_COPY_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireLegalReview, control.Required, control.RequiresLegalReview, "LEGAL_REVIEW_REQUIRED", key)
		checkBool(&result, input.RequireFounderApproval, control.Required, control.RequiresFounderApproval, "FOUNDER_APPROVAL_REQUIRED", key)
		checkBool(&result, input.RequireChangeLog, control.Required, control.RequiresChangeLog, "CHANGE_LOG_REQUIRED", key)
		checkBool(&result, input.RequireAuditTrail, control.Required, control.RequiresAuditTrail, "AUDIT_TRAIL_REQUIRED", key)
		checkBool(&result, input.RequireProductionPublishBlock, control.Required, control.BlocksProductionPublish, "PRODUCTION_PUBLISH_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealCustomerBillingBlock, control.Required, control.BlocksRealCustomerBilling, "REAL_CUSTOMER_BILLING_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequirePaymentCollectionBlock, control.Required, control.BlocksPaymentCollection, "PAYMENT_COLLECTION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequirePublicCheckoutBlock, control.Required, control.BlocksPublicCheckout, "PUBLIC_CHECKOUT_BLOCK_REQUIRED", key)

		if control.ProductionPricingPublished {
			addFail(&result, "CONTROL_PRODUCTION_PRICING_PUBLISHED_BLOCKED", fmt.Sprintf("production pricing published açık olamaz: %s", key))
		}
		if control.RealCustomerBillingEnabled {
			addFail(&result, "CONTROL_REAL_CUSTOMER_BILLING_ENABLED_BLOCKED", fmt.Sprintf("real customer billing açık olamaz: %s", key))
		}
		if control.PaymentCollectionEnabled {
			addFail(&result, "CONTROL_PAYMENT_COLLECTION_ENABLED_BLOCKED", fmt.Sprintf("payment collection açık olamaz: %s", key))
		}
		if control.PublicCheckoutEnabled {
			addFail(&result, "CONTROL_PUBLIC_CHECKOUT_ENABLED_BLOCKED", fmt.Sprintf("public checkout açık olamaz: %s", key))
		}
		if control.DeferredToDeveloperDocsPortal && strings.TrimSpace(control.DeferredReason) == "" {
			addFail(&result, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredControlKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}
		control, exists := controlByKey[requiredKey]
		if !exists {
			addFail(&result, "REQUIRED_CONTROL_NOT_REGISTERED", fmt.Sprintf("required listesinde olup validation içinde yok: %s", requiredKey))
			continue
		}
		if !control.Required {
			addFail(&result, "REQUIRED_CONTROL_FLAG_FALSE", fmt.Sprintf("required listesinde ama control required=false: %s", requiredKey))
			continue
		}
		result.PassCount++
	}

	for _, domain := range input.RequiredDomains {
		if !domainCoverage[domain] {
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("pricing validation domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalPricingValidationReady = input.InternalPricingValidationReady
	result.ProductionPricingPublished = false
	result.RealCustomerBillingEnabled = false
	result.PaymentCollectionEnabled = false
	result.PublicCheckoutEnabled = false
	return result, nil
}

func RequiredControlKeys(input ValidationInput) []string {
	keys := make([]string, 0, len(input.RequiredControlKeys))
	keys = append(keys, input.RequiredControlKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result ValidationResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("pricing validation failed")
	}
	return nil
}

func checkBool(result *ValidationResult, required bool, controlRequired bool, actual bool, code string, key string) {
	if required && controlRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if controlRequired {
		result.PassCount++
	}
}

func checkZero(result *ValidationResult, required bool, controlRequired bool, actual int, code string, key string) {
	if required && controlRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if controlRequired {
		result.PassCount++
	}
}

func addFail(result *ValidationResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
