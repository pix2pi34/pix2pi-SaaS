package churnexpansionreport

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

type MotionDomain string

const (
	DomainRevenueBase   MotionDomain = "REVENUE_BASE"
	DomainChurn         MotionDomain = "CHURN"
	DomainExpansion     MotionDomain = "EXPANSION"
	DomainContraction   MotionDomain = "CONTRACTION"
	DomainRetention     MotionDomain = "RETENTION"
	DomainReason        MotionDomain = "REASON_BREAKDOWN"
	DomainAuditEvidence MotionDomain = "AUDIT_EVIDENCE"
	DomainNextPriority  MotionDomain = "NEXT_PRIORITY"
)

type MotionSection struct {
	Key                               string
	Domain                            MotionDomain
	Title                             string
	Owner                             string
	Status                            SectionStatus
	Required                          bool
	HasEvidence                       bool
	HasCounterBasedAudit              bool
	RequiredFailCount                 int
	OptionalWarnCount                 int
	ProductionMotionReportEnabled     bool
	RealCustomerMotionEnabled         bool
	ExternalFinanceExportEnabled      bool
	AutoExecutiveEmailEnabled         bool
	RequiresTenantID                  bool
	RequiresPeriodWindow              bool
	RequiresStartingMRRBase           bool
	RequiresEndingMRRBase             bool
	RequiresChurnMetric               bool
	RequiresExpansionMetric           bool
	RequiresContractionMetric         bool
	RequiresNRRFormula                bool
	RequiresGRRFormula                bool
	RequiresReasonBreakdown           bool
	RequiresSubscriptionSource        bool
	RequiresBillingSource             bool
	RequiresPlanChangeSource          bool
	RequiresCancellationSource        bool
	RequiresCollectionRiskSignal      bool
	RequiresDataFreshness             bool
	RequiresAuditTrail                bool
	RequiresPrivacyGuard              bool
	RequiresExportPolicy              bool
	BlocksProductionMotionReport      bool
	BlocksRealCustomerMotion          bool
	BlocksExternalFinanceExport       bool
	BlocksAutoExecutiveEmail          bool
	DeferredToCollectionSuccessReport bool
	DeferredReason                    string
}

type ReportInput struct {
	Phase                              string
	Target                             string
	InternalChurnExpansionReportReady  bool
	ProductionMotionReportEnabled      bool
	RealCustomerMotionEnabled          bool
	ExternalFinanceExportEnabled       bool
	AutoExecutiveEmailEnabled          bool
	RequiredSectionKeys                []string
	RequiredDomains                    []MotionDomain
	Sections                           []MotionSection
	RequireEvidence                    bool
	RequireCounterBasedAudit           bool
	RequireNoRequiredFail              bool
	RequireNoOptionalWarn              bool
	RequireTenantID                    bool
	RequirePeriodWindow                bool
	RequireStartingMRRBase             bool
	RequireEndingMRRBase               bool
	RequireChurnMetric                 bool
	RequireExpansionMetric             bool
	RequireContractionMetric           bool
	RequireNRRFormula                  bool
	RequireGRRFormula                  bool
	RequireReasonBreakdown             bool
	RequireSubscriptionSource          bool
	RequireBillingSource               bool
	RequirePlanChangeSource            bool
	RequireCancellationSource          bool
	RequireCollectionRiskSignal        bool
	RequireDataFreshness               bool
	RequireAuditTrail                  bool
	RequirePrivacyGuard                bool
	RequireExportPolicy                bool
	RequireProductionMotionReportBlock bool
	RequireRealCustomerMotionBlock     bool
	RequireExternalFinanceExportBlock  bool
	RequireAutoExecutiveEmailBlock     bool
	AllowCollectionSuccessDeferred     bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ReportResult struct {
	Status                            string
	InternalChurnExpansionReportReady bool
	ProductionMotionReportEnabled     bool
	RealCustomerMotionEnabled         bool
	ExternalFinanceExportEnabled      bool
	AutoExecutiveEmailEnabled         bool
	RequiredFailCount                 int
	OptionalWarnCount                 int
	PassCount                         int
	Findings                          []Finding
}

func Evaluate(input ReportInput) (ReportResult, error) {
	result := ReportResult{
		Status:                            "PASS",
		InternalChurnExpansionReportReady: false,
		ProductionMotionReportEnabled:     false,
		RealCustomerMotionEnabled:         false,
		ExternalFinanceExportEnabled:      false,
		AutoExecutiveEmailEnabled:         false,
		Findings:                          []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionMotionReportEnabled {
		addFail(&result, "PRODUCTION_MOTION_REPORT_BLOCKED", "bu fazda production churn/expansion raporu açılamaz")
	}

	if input.RealCustomerMotionEnabled {
		addFail(&result, "REAL_CUSTOMER_MOTION_BLOCKED", "bu fazda gerçek müşteri churn/expansion raporu açılamaz")
	}

	if input.ExternalFinanceExportEnabled {
		addFail(&result, "EXTERNAL_FINANCE_EXPORT_BLOCKED", "bu fazda external finance export açılamaz")
	}

	if input.AutoExecutiveEmailEnabled {
		addFail(&result, "AUTO_EXECUTIVE_EMAIL_BLOCKED", "bu fazda otomatik yönetici e-postası açılamaz")
	}

	sectionByKey := map[string]MotionSection{}
	domainCoverage := map[MotionDomain]bool{}

	for _, section := range input.Sections {
		key := strings.TrimSpace(section.Key)
		if key == "" {
			addFail(&result, "MOTION_SECTION_KEY_MISSING", "motion section key boş olamaz")
			continue
		}

		if _, exists := sectionByKey[key]; exists {
			addFail(&result, "MOTION_SECTION_DUPLICATE", fmt.Sprintf("motion section duplicate: %s", key))
			continue
		}

		sectionByKey[key] = section
		domainCoverage[section.Domain] = true

		if section.Required && section.Status != StatusReady {
			if section.DeferredToCollectionSuccessReport && input.AllowCollectionSuccessDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_SECTION_NOT_READY", fmt.Sprintf("required motion section READY değil: %s", key))
			}
		} else if section.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence, section.Required, section.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit, section.Required, section.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, section.Required, section.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, section.Required, section.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequireTenantID, section.Required, section.RequiresTenantID, "TENANT_ID_REQUIRED", key)
		checkBool(&result, input.RequirePeriodWindow, section.Required, section.RequiresPeriodWindow, "PERIOD_WINDOW_REQUIRED", key)
		checkBool(&result, input.RequireStartingMRRBase, section.Required, section.RequiresStartingMRRBase, "STARTING_MRR_BASE_REQUIRED", key)
		checkBool(&result, input.RequireEndingMRRBase, section.Required, section.RequiresEndingMRRBase, "ENDING_MRR_BASE_REQUIRED", key)
		checkBool(&result, input.RequireChurnMetric, section.Required, section.RequiresChurnMetric, "CHURN_METRIC_REQUIRED", key)
		checkBool(&result, input.RequireExpansionMetric, section.Required, section.RequiresExpansionMetric, "EXPANSION_METRIC_REQUIRED", key)
		checkBool(&result, input.RequireContractionMetric, section.Required, section.RequiresContractionMetric, "CONTRACTION_METRIC_REQUIRED", key)
		checkBool(&result, input.RequireNRRFormula, section.Required, section.RequiresNRRFormula, "NRR_FORMULA_REQUIRED", key)
		checkBool(&result, input.RequireGRRFormula, section.Required, section.RequiresGRRFormula, "GRR_FORMULA_REQUIRED", key)
		checkBool(&result, input.RequireReasonBreakdown, section.Required, section.RequiresReasonBreakdown, "REASON_BREAKDOWN_REQUIRED", key)
		checkBool(&result, input.RequireSubscriptionSource, section.Required, section.RequiresSubscriptionSource, "SUBSCRIPTION_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireBillingSource, section.Required, section.RequiresBillingSource, "BILLING_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequirePlanChangeSource, section.Required, section.RequiresPlanChangeSource, "PLAN_CHANGE_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireCancellationSource, section.Required, section.RequiresCancellationSource, "CANCELLATION_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireCollectionRiskSignal, section.Required, section.RequiresCollectionRiskSignal, "COLLECTION_RISK_SIGNAL_REQUIRED", key)
		checkBool(&result, input.RequireDataFreshness, section.Required, section.RequiresDataFreshness, "DATA_FRESHNESS_REQUIRED", key)
		checkBool(&result, input.RequireAuditTrail, section.Required, section.RequiresAuditTrail, "AUDIT_TRAIL_REQUIRED", key)
		checkBool(&result, input.RequirePrivacyGuard, section.Required, section.RequiresPrivacyGuard, "PRIVACY_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireExportPolicy, section.Required, section.RequiresExportPolicy, "EXPORT_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireProductionMotionReportBlock, section.Required, section.BlocksProductionMotionReport, "PRODUCTION_MOTION_REPORT_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealCustomerMotionBlock, section.Required, section.BlocksRealCustomerMotion, "REAL_CUSTOMER_MOTION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireExternalFinanceExportBlock, section.Required, section.BlocksExternalFinanceExport, "EXTERNAL_FINANCE_EXPORT_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireAutoExecutiveEmailBlock, section.Required, section.BlocksAutoExecutiveEmail, "AUTO_EXECUTIVE_EMAIL_BLOCK_REQUIRED", key)

		if section.ProductionMotionReportEnabled {
			addFail(&result, "SECTION_PRODUCTION_MOTION_REPORT_ENABLED_BLOCKED", fmt.Sprintf("production motion report enabled açık olamaz: %s", key))
		}

		if section.RealCustomerMotionEnabled {
			addFail(&result, "SECTION_REAL_CUSTOMER_MOTION_ENABLED_BLOCKED", fmt.Sprintf("real customer motion enabled açık olamaz: %s", key))
		}

		if section.ExternalFinanceExportEnabled {
			addFail(&result, "SECTION_EXTERNAL_FINANCE_EXPORT_ENABLED_BLOCKED", fmt.Sprintf("external finance export açık olamaz: %s", key))
		}

		if section.AutoExecutiveEmailEnabled {
			addFail(&result, "SECTION_AUTO_EXECUTIVE_EMAIL_ENABLED_BLOCKED", fmt.Sprintf("auto executive email açık olamaz: %s", key))
		}

		if section.DeferredToCollectionSuccessReport && strings.TrimSpace(section.DeferredReason) == "" {
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
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("churn/expansion report domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalChurnExpansionReportReady = input.InternalChurnExpansionReportReady
	result.ProductionMotionReportEnabled = false
	result.RealCustomerMotionEnabled = false
	result.ExternalFinanceExportEnabled = false
	result.AutoExecutiveEmailEnabled = false
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
		return errors.New("churn expansion report failed")
	}
	return nil
}

func checkBool(result *ReportResult, required bool, sectionRequired bool, actual bool, code string, key string) {
	if required && sectionRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if sectionRequired {
		result.PassCount++
	}
}

func checkZero(result *ReportResult, required bool, sectionRequired bool, actual int, code string, key string) {
	if required && sectionRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if sectionRequired {
		result.PassCount++
	}
}

func addFail(result *ReportResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
