package accountantpackage

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type PackageStatus string

const (
	StatusReady       PackageStatus = "READY"
	StatusPendingNext PackageStatus = "PENDING_NEXT"
	StatusBlocked     PackageStatus = "BLOCKED"
)

type AccountantSegment string

const (
	SegmentAccountantStarter    AccountantSegment = "ACCOUNTANT_STARTER"
	SegmentAccountantPro        AccountantSegment = "ACCOUNTANT_PRO"
	SegmentAccountantEnterprise AccountantSegment = "ACCOUNTANT_ENTERPRISE"
	SegmentValidationNext       AccountantSegment = "VALIDATION_NEXT"
)

type AccountantPackage struct {
	Key                               string
	Segment                           AccountantSegment
	Title                             string
	Owner                             string
	Status                            PackageStatus
	Required                          bool
	HasEvidence                       bool
	HasCounterBasedAudit              bool
	RequiredFailCount                 int
	OptionalWarnCount                 int
	ProductionPackagePublished        bool
	RealCustomerBillingEnabled        bool
	PaymentCollectionEnabled          bool
	AccountantPortalCommercialEnabled bool
	RequiresPackageCode               bool
	RequiresCurrency                  bool
	RequiresMonthlyBaseFee            bool
	RequiresPerCompanyFee             bool
	RequiresVATPolicy                 bool
	RequiresCompanyLimit              bool
	RequiresAccountantUserLimit       bool
	RequiresExportRights              bool
	RequiresPortalEntitlement         bool
	RequiresCompanyAssignmentPolicy   bool
	RequiresMonthlyRevalidation       bool
	RequiresBillingPolicy             bool
	RequiresKVKKScope                 bool
	RequiresDataAccessPolicy          bool
	RequiresLegalReview               bool
	RequiresFounderApproval           bool
	RequiresChangeLog                 bool
	RequiresPublicCopyGuard           bool
	BlocksProductionPublish           bool
	BlocksRealCustomerBilling         bool
	BlocksPaymentCollection           bool
	BlocksAccountantPortalCommercial  bool
	DeferredToPricingValidation       bool
	DeferredReason                    string
}

type PackageInput struct {
	Phase                                  string
	Target                                 string
	InternalAccountantPackageReady         bool
	ProductionPackagePublished             bool
	RealCustomerBillingEnabled             bool
	PaymentCollectionEnabled               bool
	AccountantPortalCommercialEnabled      bool
	RequiredPackageKeys                    []string
	RequiredSegments                       []AccountantSegment
	Packages                               []AccountantPackage
	RequireEvidence                        bool
	RequireCounterBasedAudit               bool
	RequireNoRequiredFail                  bool
	RequireNoOptionalWarn                  bool
	RequirePackageCode                     bool
	RequireCurrency                        bool
	RequireMonthlyBaseFee                  bool
	RequirePerCompanyFee                   bool
	RequireVATPolicy                       bool
	RequireCompanyLimit                    bool
	RequireAccountantUserLimit             bool
	RequireExportRights                    bool
	RequirePortalEntitlement               bool
	RequireCompanyAssignmentPolicy         bool
	RequireMonthlyRevalidation             bool
	RequireBillingPolicy                   bool
	RequireKVKKScope                       bool
	RequireDataAccessPolicy                bool
	RequireLegalReview                     bool
	RequireFounderApproval                 bool
	RequireChangeLog                       bool
	RequirePublicCopyGuard                 bool
	RequireProductionPublishBlock          bool
	RequireRealCustomerBillingBlock        bool
	RequirePaymentCollectionBlock          bool
	RequireAccountantPortalCommercialBlock bool
	AllowPricingValidationDeferred         bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type PackageResult struct {
	Status                            string
	InternalAccountantPackageReady    bool
	ProductionPackagePublished        bool
	RealCustomerBillingEnabled        bool
	PaymentCollectionEnabled          bool
	AccountantPortalCommercialEnabled bool
	RequiredFailCount                 int
	OptionalWarnCount                 int
	PassCount                         int
	Findings                          []Finding
}

func Evaluate(input PackageInput) (PackageResult, error) {
	result := PackageResult{
		Status:                            "PASS",
		InternalAccountantPackageReady:    false,
		ProductionPackagePublished:        false,
		RealCustomerBillingEnabled:        false,
		PaymentCollectionEnabled:          false,
		AccountantPortalCommercialEnabled: false,
		Findings:                          []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}
	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}
	if input.ProductionPackagePublished {
		addFail(&result, "PRODUCTION_PACKAGE_PUBLISH_BLOCKED", "bu fazda production muhasebeci paket yayını açılamaz")
	}
	if input.RealCustomerBillingEnabled {
		addFail(&result, "REAL_CUSTOMER_BILLING_BLOCKED", "bu fazda gerçek müşteri billing açılamaz")
	}
	if input.PaymentCollectionEnabled {
		addFail(&result, "PAYMENT_COLLECTION_BLOCKED", "bu fazda gerçek tahsilat açılamaz")
	}
	if input.AccountantPortalCommercialEnabled {
		addFail(&result, "ACCOUNTANT_PORTAL_COMMERCIAL_BLOCKED", "bu fazda muhasebeci portal ticari aktivasyon açılamaz")
	}

	packageByKey := map[string]AccountantPackage{}
	segmentCoverage := map[AccountantSegment]bool{}

	for _, pkg := range input.Packages {
		key := strings.TrimSpace(pkg.Key)
		if key == "" {
			addFail(&result, "ACCOUNTANT_PACKAGE_KEY_MISSING", "accountant package key boş olamaz")
			continue
		}
		if _, exists := packageByKey[key]; exists {
			addFail(&result, "ACCOUNTANT_PACKAGE_DUPLICATE", fmt.Sprintf("accountant package duplicate: %s", key))
			continue
		}

		packageByKey[key] = pkg
		segmentCoverage[pkg.Segment] = true

		if pkg.Required && pkg.Status != StatusReady {
			if pkg.DeferredToPricingValidation && input.AllowPricingValidationDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_PACKAGE_NOT_READY", fmt.Sprintf("required accountant package READY değil: %s", key))
			}
		} else if pkg.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence, pkg.Required, pkg.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit, pkg.Required, pkg.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, pkg.Required, pkg.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, pkg.Required, pkg.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequirePackageCode, pkg.Required, pkg.RequiresPackageCode, "PACKAGE_CODE_REQUIRED", key)
		checkBool(&result, input.RequireCurrency, pkg.Required, pkg.RequiresCurrency, "CURRENCY_REQUIRED", key)
		checkBool(&result, input.RequireMonthlyBaseFee, pkg.Required, pkg.RequiresMonthlyBaseFee, "MONTHLY_BASE_FEE_REQUIRED", key)
		checkBool(&result, input.RequirePerCompanyFee, pkg.Required, pkg.RequiresPerCompanyFee, "PER_COMPANY_FEE_REQUIRED", key)
		checkBool(&result, input.RequireVATPolicy, pkg.Required, pkg.RequiresVATPolicy, "VAT_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireCompanyLimit, pkg.Required, pkg.RequiresCompanyLimit, "COMPANY_LIMIT_REQUIRED", key)
		checkBool(&result, input.RequireAccountantUserLimit, pkg.Required, pkg.RequiresAccountantUserLimit, "ACCOUNTANT_USER_LIMIT_REQUIRED", key)
		checkBool(&result, input.RequireExportRights, pkg.Required, pkg.RequiresExportRights, "EXPORT_RIGHTS_REQUIRED", key)
		checkBool(&result, input.RequirePortalEntitlement, pkg.Required, pkg.RequiresPortalEntitlement, "PORTAL_ENTITLEMENT_REQUIRED", key)
		checkBool(&result, input.RequireCompanyAssignmentPolicy, pkg.Required, pkg.RequiresCompanyAssignmentPolicy, "COMPANY_ASSIGNMENT_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireMonthlyRevalidation, pkg.Required, pkg.RequiresMonthlyRevalidation, "MONTHLY_REVALIDATION_REQUIRED", key)
		checkBool(&result, input.RequireBillingPolicy, pkg.Required, pkg.RequiresBillingPolicy, "BILLING_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireKVKKScope, pkg.Required, pkg.RequiresKVKKScope, "KVKK_SCOPE_REQUIRED", key)
		checkBool(&result, input.RequireDataAccessPolicy, pkg.Required, pkg.RequiresDataAccessPolicy, "DATA_ACCESS_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireLegalReview, pkg.Required, pkg.RequiresLegalReview, "LEGAL_REVIEW_REQUIRED", key)
		checkBool(&result, input.RequireFounderApproval, pkg.Required, pkg.RequiresFounderApproval, "FOUNDER_APPROVAL_REQUIRED", key)
		checkBool(&result, input.RequireChangeLog, pkg.Required, pkg.RequiresChangeLog, "CHANGE_LOG_REQUIRED", key)
		checkBool(&result, input.RequirePublicCopyGuard, pkg.Required, pkg.RequiresPublicCopyGuard, "PUBLIC_COPY_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireProductionPublishBlock, pkg.Required, pkg.BlocksProductionPublish, "PRODUCTION_PUBLISH_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealCustomerBillingBlock, pkg.Required, pkg.BlocksRealCustomerBilling, "REAL_CUSTOMER_BILLING_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequirePaymentCollectionBlock, pkg.Required, pkg.BlocksPaymentCollection, "PAYMENT_COLLECTION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireAccountantPortalCommercialBlock, pkg.Required, pkg.BlocksAccountantPortalCommercial, "ACCOUNTANT_PORTAL_COMMERCIAL_BLOCK_REQUIRED", key)

		if pkg.ProductionPackagePublished {
			addFail(&result, "PACKAGE_PRODUCTION_PUBLISHED_BLOCKED", fmt.Sprintf("production package published açık olamaz: %s", key))
		}
		if pkg.RealCustomerBillingEnabled {
			addFail(&result, "PACKAGE_REAL_CUSTOMER_BILLING_BLOCKED", fmt.Sprintf("real customer billing açık olamaz: %s", key))
		}
		if pkg.PaymentCollectionEnabled {
			addFail(&result, "PACKAGE_PAYMENT_COLLECTION_BLOCKED", fmt.Sprintf("payment collection açık olamaz: %s", key))
		}
		if pkg.AccountantPortalCommercialEnabled {
			addFail(&result, "PACKAGE_ACCOUNTANT_PORTAL_COMMERCIAL_BLOCKED", fmt.Sprintf("accountant portal commercial açık olamaz: %s", key))
		}
		if pkg.DeferredToPricingValidation && strings.TrimSpace(pkg.DeferredReason) == "" {
			addFail(&result, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredPackageKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}
		pkg, exists := packageByKey[requiredKey]
		if !exists {
			addFail(&result, "REQUIRED_PACKAGE_NOT_REGISTERED", fmt.Sprintf("required listesinde olup package içinde yok: %s", requiredKey))
			continue
		}
		if !pkg.Required {
			addFail(&result, "REQUIRED_PACKAGE_FLAG_FALSE", fmt.Sprintf("required listesinde ama package required=false: %s", requiredKey))
			continue
		}
		result.PassCount++
	}

	for _, segment := range input.RequiredSegments {
		if !segmentCoverage[segment] {
			addFail(&result, "REQUIRED_SEGMENT_MISSING", fmt.Sprintf("accountant package segment eksik: %s", segment))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalAccountantPackageReady = input.InternalAccountantPackageReady
	result.ProductionPackagePublished = false
	result.RealCustomerBillingEnabled = false
	result.PaymentCollectionEnabled = false
	result.AccountantPortalCommercialEnabled = false
	return result, nil
}

func RequiredPackageKeys(input PackageInput) []string {
	keys := make([]string, 0, len(input.RequiredPackageKeys))
	keys = append(keys, input.RequiredPackageKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result PackageResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("accountant package failed")
	}
	return nil
}

func checkBool(result *PackageResult, required bool, packageRequired bool, actual bool, code string, key string) {
	if required && packageRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if packageRequired {
		result.PassCount++
	}
}

func checkZero(result *PackageResult, required bool, packageRequired bool, actual int, code string, key string) {
	if required && packageRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if packageRequired {
		result.PassCount++
	}
}

func addFail(result *PackageResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
