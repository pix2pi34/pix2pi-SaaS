package mrrarrreport

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

type RevenueDomain string

const (
	DomainSubscriptionBase RevenueDomain = "SUBSCRIPTION_BASE"
	DomainMRR              RevenueDomain = "MRR"
	DomainARR              RevenueDomain = "ARR"
	DomainExpansion        RevenueDomain = "EXPANSION"
	DomainContraction      RevenueDomain = "CONTRACTION"
	DomainCollection       RevenueDomain = "COLLECTION"
	DomainAuditEvidence    RevenueDomain = "AUDIT_EVIDENCE"
	DomainNextPriority     RevenueDomain = "NEXT_PRIORITY"
)

type RevenueSection struct {
	Key                            string
	Domain                         RevenueDomain
	Title                          string
	Owner                          string
	Status                         SectionStatus
	Required                       bool
	HasEvidence                    bool
	HasCounterBasedAudit           bool
	RequiredFailCount              int
	OptionalWarnCount              int
	ProductionRevenueReportEnabled bool
	RealCustomerRevenueEnabled     bool
	ExternalFinanceExportEnabled   bool
	AutoInvestorEmailEnabled       bool
	RequiresTenantID               bool
	RequiresPeriodWindow           bool
	RequiresSubscriptionSource     bool
	RequiresBillingSource          bool
	RequiresPlanSnapshot           bool
	RequiresCurrencyPolicy         bool
	RequiresMRRFormula             bool
	RequiresARRFormula             bool
	RequiresExpansionMetric        bool
	RequiresContractionMetric      bool
	RequiresCollectionStatus       bool
	RequiresTaxExclusionPolicy     bool
	RequiresDataFreshness          bool
	RequiresAuditTrail             bool
	RequiresPrivacyGuard           bool
	RequiresExportPolicy           bool
	BlocksProductionRevenueReport  bool
	BlocksRealCustomerRevenue      bool
	BlocksExternalFinanceExport    bool
	BlocksAutoInvestorEmail        bool
	DeferredToChurnExpansionReport bool
	DeferredReason                 string
}

type ReportInput struct {
	Phase                               string
	Target                              string
	InternalMRRARRReportReady           bool
	ProductionRevenueReportEnabled      bool
	RealCustomerRevenueEnabled          bool
	ExternalFinanceExportEnabled        bool
	AutoInvestorEmailEnabled            bool
	RequiredSectionKeys                 []string
	RequiredDomains                     []RevenueDomain
	Sections                            []RevenueSection
	RequireEvidence                     bool
	RequireCounterBasedAudit            bool
	RequireNoRequiredFail               bool
	RequireNoOptionalWarn               bool
	RequireTenantID                     bool
	RequirePeriodWindow                 bool
	RequireSubscriptionSource           bool
	RequireBillingSource                bool
	RequirePlanSnapshot                 bool
	RequireCurrencyPolicy               bool
	RequireMRRFormula                   bool
	RequireARRFormula                   bool
	RequireExpansionMetric              bool
	RequireContractionMetric            bool
	RequireCollectionStatus             bool
	RequireTaxExclusionPolicy           bool
	RequireDataFreshness                bool
	RequireAuditTrail                   bool
	RequirePrivacyGuard                 bool
	RequireExportPolicy                 bool
	RequireProductionRevenueReportBlock bool
	RequireRealCustomerRevenueBlock     bool
	RequireExternalFinanceExportBlock   bool
	RequireAutoInvestorEmailBlock       bool
	AllowChurnExpansionDeferred         bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ReportResult struct {
	Status                         string
	InternalMRRARRReportReady      bool
	ProductionRevenueReportEnabled bool
	RealCustomerRevenueEnabled     bool
	ExternalFinanceExportEnabled   bool
	AutoInvestorEmailEnabled       bool
	RequiredFailCount              int
	OptionalWarnCount              int
	PassCount                      int
	Findings                       []Finding
}

func Evaluate(input ReportInput) (ReportResult, error) {
	result := ReportResult{
		Status:                         "PASS",
		InternalMRRARRReportReady:      false,
		ProductionRevenueReportEnabled: false,
		RealCustomerRevenueEnabled:     false,
		ExternalFinanceExportEnabled:   false,
		AutoInvestorEmailEnabled:       false,
		Findings:                       []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionRevenueReportEnabled {
		addFail(&result, "PRODUCTION_REVENUE_REPORT_BLOCKED", "bu fazda production MRR/ARR raporu açılamaz")
	}

	if input.RealCustomerRevenueEnabled {
		addFail(&result, "REAL_CUSTOMER_REVENUE_BLOCKED", "bu fazda gerçek müşteri revenue raporu açılamaz")
	}

	if input.ExternalFinanceExportEnabled {
		addFail(&result, "EXTERNAL_FINANCE_EXPORT_BLOCKED", "bu fazda external finance export açılamaz")
	}

	if input.AutoInvestorEmailEnabled {
		addFail(&result, "AUTO_INVESTOR_EMAIL_BLOCKED", "bu fazda otomatik yatırımcı e-postası açılamaz")
	}

	sectionByKey := map[string]RevenueSection{}
	domainCoverage := map[RevenueDomain]bool{}

	for _, section := range input.Sections {
		key := strings.TrimSpace(section.Key)
		if key == "" {
			addFail(&result, "REVENUE_SECTION_KEY_MISSING", "revenue section key boş olamaz")
			continue
		}

		if _, exists := sectionByKey[key]; exists {
			addFail(&result, "REVENUE_SECTION_DUPLICATE", fmt.Sprintf("revenue section duplicate: %s", key))
			continue
		}

		sectionByKey[key] = section
		domainCoverage[section.Domain] = true

		if section.Required && section.Status != StatusReady {
			if section.DeferredToChurnExpansionReport && input.AllowChurnExpansionDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_SECTION_NOT_READY", fmt.Sprintf("required revenue section READY değil: %s", key))
			}
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireEvidence && section.Required && !section.HasEvidence {
			addFail(&result, "EVIDENCE_REQUIRED", fmt.Sprintf("evidence eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireCounterBasedAudit && section.Required && !section.HasCounterBasedAudit {
			addFail(&result, "COUNTER_BASED_AUDIT_REQUIRED", fmt.Sprintf("counter based audit eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireNoRequiredFail && section.Required && section.RequiredFailCount != 0 {
			addFail(&result, "REQUIRED_FAIL_MUST_BE_ZERO", fmt.Sprintf("required fail sıfır değil: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireNoOptionalWarn && section.Required && section.OptionalWarnCount != 0 {
			addFail(&result, "OPTIONAL_WARN_MUST_BE_ZERO", fmt.Sprintf("optional warn sıfır değil: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireTenantID && section.Required && !section.RequiresTenantID {
			addFail(&result, "TENANT_ID_REQUIRED", fmt.Sprintf("tenant_id eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequirePeriodWindow && section.Required && !section.RequiresPeriodWindow {
			addFail(&result, "PERIOD_WINDOW_REQUIRED", fmt.Sprintf("period window eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireSubscriptionSource && section.Required && !section.RequiresSubscriptionSource {
			addFail(&result, "SUBSCRIPTION_SOURCE_REQUIRED", fmt.Sprintf("subscription source eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireBillingSource && section.Required && !section.RequiresBillingSource {
			addFail(&result, "BILLING_SOURCE_REQUIRED", fmt.Sprintf("billing source eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequirePlanSnapshot && section.Required && !section.RequiresPlanSnapshot {
			addFail(&result, "PLAN_SNAPSHOT_REQUIRED", fmt.Sprintf("plan snapshot eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireCurrencyPolicy && section.Required && !section.RequiresCurrencyPolicy {
			addFail(&result, "CURRENCY_POLICY_REQUIRED", fmt.Sprintf("currency policy eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireMRRFormula && section.Required && !section.RequiresMRRFormula {
			addFail(&result, "MRR_FORMULA_REQUIRED", fmt.Sprintf("MRR formula eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireARRFormula && section.Required && !section.RequiresARRFormula {
			addFail(&result, "ARR_FORMULA_REQUIRED", fmt.Sprintf("ARR formula eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireExpansionMetric && section.Required && !section.RequiresExpansionMetric {
			addFail(&result, "EXPANSION_METRIC_REQUIRED", fmt.Sprintf("expansion metric eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireContractionMetric && section.Required && !section.RequiresContractionMetric {
			addFail(&result, "CONTRACTION_METRIC_REQUIRED", fmt.Sprintf("contraction metric eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireCollectionStatus && section.Required && !section.RequiresCollectionStatus {
			addFail(&result, "COLLECTION_STATUS_REQUIRED", fmt.Sprintf("collection status eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireTaxExclusionPolicy && section.Required && !section.RequiresTaxExclusionPolicy {
			addFail(&result, "TAX_EXCLUSION_POLICY_REQUIRED", fmt.Sprintf("tax exclusion policy eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireDataFreshness && section.Required && !section.RequiresDataFreshness {
			addFail(&result, "DATA_FRESHNESS_REQUIRED", fmt.Sprintf("data freshness eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireAuditTrail && section.Required && !section.RequiresAuditTrail {
			addFail(&result, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequirePrivacyGuard && section.Required && !section.RequiresPrivacyGuard {
			addFail(&result, "PRIVACY_GUARD_REQUIRED", fmt.Sprintf("privacy guard eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireExportPolicy && section.Required && !section.RequiresExportPolicy {
			addFail(&result, "EXPORT_POLICY_REQUIRED", fmt.Sprintf("export policy eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireProductionRevenueReportBlock && section.Required && !section.BlocksProductionRevenueReport {
			addFail(&result, "PRODUCTION_REVENUE_REPORT_BLOCK_REQUIRED", fmt.Sprintf("production revenue report block eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireRealCustomerRevenueBlock && section.Required && !section.BlocksRealCustomerRevenue {
			addFail(&result, "REAL_CUSTOMER_REVENUE_BLOCK_REQUIRED", fmt.Sprintf("real customer revenue block eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireExternalFinanceExportBlock && section.Required && !section.BlocksExternalFinanceExport {
			addFail(&result, "EXTERNAL_FINANCE_EXPORT_BLOCK_REQUIRED", fmt.Sprintf("external finance export block eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireAutoInvestorEmailBlock && section.Required && !section.BlocksAutoInvestorEmail {
			addFail(&result, "AUTO_INVESTOR_EMAIL_BLOCK_REQUIRED", fmt.Sprintf("auto investor email block eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if section.ProductionRevenueReportEnabled {
			addFail(&result, "SECTION_PRODUCTION_REVENUE_REPORT_ENABLED_BLOCKED", fmt.Sprintf("production revenue report enabled açık olamaz: %s", key))
		}

		if section.RealCustomerRevenueEnabled {
			addFail(&result, "SECTION_REAL_CUSTOMER_REVENUE_ENABLED_BLOCKED", fmt.Sprintf("real customer revenue enabled açık olamaz: %s", key))
		}

		if section.ExternalFinanceExportEnabled {
			addFail(&result, "SECTION_EXTERNAL_FINANCE_EXPORT_ENABLED_BLOCKED", fmt.Sprintf("external finance export açık olamaz: %s", key))
		}

		if section.AutoInvestorEmailEnabled {
			addFail(&result, "SECTION_AUTO_INVESTOR_EMAIL_ENABLED_BLOCKED", fmt.Sprintf("auto investor email açık olamaz: %s", key))
		}

		if section.DeferredToChurnExpansionReport && strings.TrimSpace(section.DeferredReason) == "" {
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
			addFail(&result, "REQUIRED_SECTION_NOT_REGISTERED", fmt.Sprintf("required listesinde olup report içinde yok: %s", requiredKey))
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
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("MRR/ARR report domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalMRRARRReportReady = input.InternalMRRARRReportReady
	result.ProductionRevenueReportEnabled = false
	result.RealCustomerRevenueEnabled = false
	result.ExternalFinanceExportEnabled = false
	result.AutoInvestorEmailEnabled = false
	return result, nil
}

func RequiredSectionKeys(input ReportInput) []string {
	keys := make([]string, 0, len(input.RequiredSectionKeys))
	keys = append(keys, input.RequiredSectionKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result ReportResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("mrr arr report failed")
	}
	return nil
}

func addFail(result *ReportResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
