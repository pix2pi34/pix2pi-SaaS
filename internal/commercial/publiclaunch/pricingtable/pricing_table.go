package pricingtable

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type RowStatus string

const (
	StatusReady       RowStatus = "READY"
	StatusPendingNext RowStatus = "PENDING_NEXT"
	StatusBlocked     RowStatus = "BLOCKED"
)

type PriceSegment string

const (
	SegmentFree           PriceSegment = "FREE"
	SegmentStarter        PriceSegment = "STARTER"
	SegmentPro            PriceSegment = "PRO"
	SegmentEnterprise     PriceSegment = "ENTERPRISE"
	SegmentAccountantNext PriceSegment = "ACCOUNTANT_NEXT"
)

type PricingRow struct {
	Key                          string
	Segment                      PriceSegment
	Title                        string
	Owner                        string
	Status                       RowStatus
	Required                     bool
	HasEvidence                  bool
	HasCounterBasedAudit         bool
	RequiredFailCount            int
	OptionalWarnCount            int
	ProductionPricingPublished   bool
	RealCustomerBillingEnabled   bool
	PaymentCollectionEnabled     bool
	PublicCheckoutEnabled        bool
	RequiresPlanCode             bool
	RequiresCurrency             bool
	RequiresMonthlyPrice         bool
	RequiresAnnualPrice          bool
	RequiresVATPolicy            bool
	RequiresUserLimit            bool
	RequiresTenantLimit          bool
	RequiresFeatureSummary       bool
	RequiresEntitlementReference bool
	RequiresBillingPolicy        bool
	RequiresLegalReview          bool
	RequiresFounderApproval      bool
	RequiresChangeLog            bool
	RequiresPublicCopyGuard      bool
	BlocksProductionPublish      bool
	BlocksRealCustomerBilling    bool
	BlocksPaymentCollection      bool
	BlocksPublicCheckout         bool
	DeferredToAccountantPackage  bool
	DeferredReason               string
}

type TableInput struct {
	Phase                           string
	Target                          string
	InternalPricingTableReady       bool
	ProductionPricingPublished      bool
	RealCustomerBillingEnabled      bool
	PaymentCollectionEnabled        bool
	PublicCheckoutEnabled           bool
	RequiredRowKeys                 []string
	RequiredSegments                []PriceSegment
	Rows                            []PricingRow
	RequireEvidence                 bool
	RequireCounterBasedAudit        bool
	RequireNoRequiredFail           bool
	RequireNoOptionalWarn           bool
	RequirePlanCode                 bool
	RequireCurrency                 bool
	RequireMonthlyPrice             bool
	RequireAnnualPrice              bool
	RequireVATPolicy                bool
	RequireUserLimit                bool
	RequireTenantLimit              bool
	RequireFeatureSummary           bool
	RequireEntitlementReference     bool
	RequireBillingPolicy            bool
	RequireLegalReview              bool
	RequireFounderApproval          bool
	RequireChangeLog                bool
	RequirePublicCopyGuard          bool
	RequireProductionPublishBlock   bool
	RequireRealCustomerBillingBlock bool
	RequirePaymentCollectionBlock   bool
	RequirePublicCheckoutBlock      bool
	AllowAccountantPackageDeferred  bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type TableResult struct {
	Status                     string
	InternalPricingTableReady  bool
	ProductionPricingPublished bool
	RealCustomerBillingEnabled bool
	PaymentCollectionEnabled   bool
	PublicCheckoutEnabled      bool
	RequiredFailCount          int
	OptionalWarnCount          int
	PassCount                  int
	Findings                   []Finding
}

func Evaluate(input TableInput) (TableResult, error) {
	result := TableResult{
		Status:                     "PASS",
		InternalPricingTableReady:  false,
		ProductionPricingPublished: false,
		RealCustomerBillingEnabled: false,
		PaymentCollectionEnabled:   false,
		PublicCheckoutEnabled:      false,
		Findings:                   []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionPricingPublished {
		addFail(&result, "PRODUCTION_PRICING_PUBLISH_BLOCKED", "bu fazda production fiyat yayını açılamaz")
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

	rowByKey := map[string]PricingRow{}
	segmentCoverage := map[PriceSegment]bool{}

	for _, row := range input.Rows {
		key := strings.TrimSpace(row.Key)
		if key == "" {
			addFail(&result, "PRICING_ROW_KEY_MISSING", "pricing row key boş olamaz")
			continue
		}

		if _, exists := rowByKey[key]; exists {
			addFail(&result, "PRICING_ROW_DUPLICATE", fmt.Sprintf("pricing row duplicate: %s", key))
			continue
		}

		rowByKey[key] = row
		segmentCoverage[row.Segment] = true

		if row.Required && row.Status != StatusReady {
			if row.DeferredToAccountantPackage && input.AllowAccountantPackageDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_ROW_NOT_READY", fmt.Sprintf("required pricing row READY değil: %s", key))
			}
		} else if row.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence, row.Required, row.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit, row.Required, row.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, row.Required, row.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, row.Required, row.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequirePlanCode, row.Required, row.RequiresPlanCode, "PLAN_CODE_REQUIRED", key)
		checkBool(&result, input.RequireCurrency, row.Required, row.RequiresCurrency, "CURRENCY_REQUIRED", key)
		checkBool(&result, input.RequireMonthlyPrice, row.Required, row.RequiresMonthlyPrice, "MONTHLY_PRICE_REQUIRED", key)
		checkBool(&result, input.RequireAnnualPrice, row.Required, row.RequiresAnnualPrice, "ANNUAL_PRICE_REQUIRED", key)
		checkBool(&result, input.RequireVATPolicy, row.Required, row.RequiresVATPolicy, "VAT_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireUserLimit, row.Required, row.RequiresUserLimit, "USER_LIMIT_REQUIRED", key)
		checkBool(&result, input.RequireTenantLimit, row.Required, row.RequiresTenantLimit, "TENANT_LIMIT_REQUIRED", key)
		checkBool(&result, input.RequireFeatureSummary, row.Required, row.RequiresFeatureSummary, "FEATURE_SUMMARY_REQUIRED", key)
		checkBool(&result, input.RequireEntitlementReference, row.Required, row.RequiresEntitlementReference, "ENTITLEMENT_REFERENCE_REQUIRED", key)
		checkBool(&result, input.RequireBillingPolicy, row.Required, row.RequiresBillingPolicy, "BILLING_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireLegalReview, row.Required, row.RequiresLegalReview, "LEGAL_REVIEW_REQUIRED", key)
		checkBool(&result, input.RequireFounderApproval, row.Required, row.RequiresFounderApproval, "FOUNDER_APPROVAL_REQUIRED", key)
		checkBool(&result, input.RequireChangeLog, row.Required, row.RequiresChangeLog, "CHANGE_LOG_REQUIRED", key)
		checkBool(&result, input.RequirePublicCopyGuard, row.Required, row.RequiresPublicCopyGuard, "PUBLIC_COPY_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireProductionPublishBlock, row.Required, row.BlocksProductionPublish, "PRODUCTION_PUBLISH_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealCustomerBillingBlock, row.Required, row.BlocksRealCustomerBilling, "REAL_CUSTOMER_BILLING_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequirePaymentCollectionBlock, row.Required, row.BlocksPaymentCollection, "PAYMENT_COLLECTION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequirePublicCheckoutBlock, row.Required, row.BlocksPublicCheckout, "PUBLIC_CHECKOUT_BLOCK_REQUIRED", key)

		if row.ProductionPricingPublished {
			addFail(&result, "ROW_PRODUCTION_PRICING_PUBLISHED_BLOCKED", fmt.Sprintf("production pricing published açık olamaz: %s", key))
		}

		if row.RealCustomerBillingEnabled {
			addFail(&result, "ROW_REAL_CUSTOMER_BILLING_ENABLED_BLOCKED", fmt.Sprintf("real customer billing açık olamaz: %s", key))
		}

		if row.PaymentCollectionEnabled {
			addFail(&result, "ROW_PAYMENT_COLLECTION_ENABLED_BLOCKED", fmt.Sprintf("payment collection açık olamaz: %s", key))
		}

		if row.PublicCheckoutEnabled {
			addFail(&result, "ROW_PUBLIC_CHECKOUT_ENABLED_BLOCKED", fmt.Sprintf("public checkout açık olamaz: %s", key))
		}

		if row.DeferredToAccountantPackage && strings.TrimSpace(row.DeferredReason) == "" {
			addFail(&result, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredRowKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		row, exists := rowByKey[requiredKey]
		if !exists {
			addFail(&result, "REQUIRED_ROW_NOT_REGISTERED", fmt.Sprintf("required listesinde olup pricing table içinde yok: %s", requiredKey))
			continue
		}

		if !row.Required {
			addFail(&result, "REQUIRED_ROW_FLAG_FALSE", fmt.Sprintf("required listesinde ama row required=false: %s", requiredKey))
			continue
		}

		result.PassCount++
	}

	for _, segment := range input.RequiredSegments {
		if !segmentCoverage[segment] {
			addFail(&result, "REQUIRED_SEGMENT_MISSING", fmt.Sprintf("pricing segment eksik: %s", segment))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalPricingTableReady = input.InternalPricingTableReady
	result.ProductionPricingPublished = false
	result.RealCustomerBillingEnabled = false
	result.PaymentCollectionEnabled = false
	result.PublicCheckoutEnabled = false
	return result, nil
}

func RequiredRowKeys(input TableInput) []string {
	keys := make([]string, 0, len(input.RequiredRowKeys))
	keys = append(keys, input.RequiredRowKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result TableResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("pricing table failed")
	}
	return nil
}

func checkBool(result *TableResult, required bool, rowRequired bool, actual bool, code string, key string) {
	if required && rowRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if rowRequired {
		result.PassCount++
	}
}

func checkZero(result *TableResult, required bool, rowRequired bool, actual int, code string, key string) {
	if required && rowRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if rowRequired {
		result.PassCount++
	}
}

func addFail(result *TableResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
