package collectionsuccessreport

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

type CollectionDomain string

const (
	DomainBillingBase   CollectionDomain = "BILLING_BASE"
	DomainCollection    CollectionDomain = "COLLECTION_SUCCESS"
	DomainFailedPayment CollectionDomain = "FAILED_PAYMENT"
	DomainRecovery      CollectionDomain = "RECOVERY"
	DomainAging         CollectionDomain = "AGING"
	DomainRisk          CollectionDomain = "RISK"
	DomainAuditEvidence CollectionDomain = "AUDIT_EVIDENCE"
	DomainNextPriority  CollectionDomain = "NEXT_PRIORITY"
)

type CollectionSection struct {
	Key                                string
	Domain                             CollectionDomain
	Title                              string
	Owner                              string
	Status                             SectionStatus
	Required                           bool
	HasEvidence                        bool
	HasCounterBasedAudit               bool
	RequiredFailCount                  int
	OptionalWarnCount                  int
	ProductionCollectionReportEnabled  bool
	RealCustomerCollectionEnabled      bool
	ExternalFinanceExportEnabled       bool
	AutoDunningEnabled                 bool
	RequiresTenantID                   bool
	RequiresPeriodWindow               bool
	RequiresInvoiceSource              bool
	RequiresBillingSource              bool
	RequiresPaymentAttemptSource       bool
	RequiresSuccessRateFormula         bool
	RequiresFailedPaymentMetric        bool
	RequiresRecoveryMetric             bool
	RequiresAgingBucket                bool
	RequiresCollectionRiskSignal       bool
	RequiresTaxPolicy                  bool
	RequiresDataFreshness              bool
	RequiresAuditTrail                 bool
	RequiresPrivacyGuard               bool
	RequiresExportPolicy               bool
	BlocksProductionCollectionReport   bool
	BlocksRealCustomerCollection       bool
	BlocksExternalFinanceExport        bool
	BlocksAutoDunning                  bool
	DeferredToInternalFinanceDashboard bool
	DeferredReason                     string
}

type ReportInput struct {
	Phase                                  string
	Target                                 string
	InternalCollectionSuccessReportReady   bool
	ProductionCollectionReportEnabled      bool
	RealCustomerCollectionEnabled          bool
	ExternalFinanceExportEnabled           bool
	AutoDunningEnabled                     bool
	RequiredSectionKeys                    []string
	RequiredDomains                        []CollectionDomain
	Sections                               []CollectionSection
	RequireEvidence                        bool
	RequireCounterBasedAudit               bool
	RequireNoRequiredFail                  bool
	RequireNoOptionalWarn                  bool
	RequireTenantID                        bool
	RequirePeriodWindow                    bool
	RequireInvoiceSource                   bool
	RequireBillingSource                   bool
	RequirePaymentAttemptSource            bool
	RequireSuccessRateFormula              bool
	RequireFailedPaymentMetric             bool
	RequireRecoveryMetric                  bool
	RequireAgingBucket                     bool
	RequireCollectionRiskSignal            bool
	RequireTaxPolicy                       bool
	RequireDataFreshness                   bool
	RequireAuditTrail                      bool
	RequirePrivacyGuard                    bool
	RequireExportPolicy                    bool
	RequireProductionCollectionReportBlock bool
	RequireRealCustomerCollectionBlock     bool
	RequireExternalFinanceExportBlock      bool
	RequireAutoDunningBlock                bool
	AllowInternalFinanceDashboardDeferred  bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ReportResult struct {
	Status                               string
	InternalCollectionSuccessReportReady bool
	ProductionCollectionReportEnabled    bool
	RealCustomerCollectionEnabled        bool
	ExternalFinanceExportEnabled         bool
	AutoDunningEnabled                   bool
	RequiredFailCount                    int
	OptionalWarnCount                    int
	PassCount                            int
	Findings                             []Finding
}

func Evaluate(input ReportInput) (ReportResult, error) {
	result := ReportResult{
		Status:                               "PASS",
		InternalCollectionSuccessReportReady: false,
		ProductionCollectionReportEnabled:    false,
		RealCustomerCollectionEnabled:        false,
		ExternalFinanceExportEnabled:         false,
		AutoDunningEnabled:                   false,
		Findings:                             []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionCollectionReportEnabled {
		addFail(&result, "PRODUCTION_COLLECTION_REPORT_BLOCKED", "bu fazda production tahsilat raporu açılamaz")
	}

	if input.RealCustomerCollectionEnabled {
		addFail(&result, "REAL_CUSTOMER_COLLECTION_BLOCKED", "bu fazda gerçek müşteri tahsilat raporu açılamaz")
	}

	if input.ExternalFinanceExportEnabled {
		addFail(&result, "EXTERNAL_FINANCE_EXPORT_BLOCKED", "bu fazda external finance export açılamaz")
	}

	if input.AutoDunningEnabled {
		addFail(&result, "AUTO_DUNNING_BLOCKED", "bu fazda otomatik dunning/takip aksiyonu açılamaz")
	}

	sectionByKey := map[string]CollectionSection{}
	domainCoverage := map[CollectionDomain]bool{}

	for _, section := range input.Sections {
		key := strings.TrimSpace(section.Key)
		if key == "" {
			addFail(&result, "COLLECTION_SECTION_KEY_MISSING", "collection section key boş olamaz")
			continue
		}

		if _, exists := sectionByKey[key]; exists {
			addFail(&result, "COLLECTION_SECTION_DUPLICATE", fmt.Sprintf("collection section duplicate: %s", key))
			continue
		}

		sectionByKey[key] = section
		domainCoverage[section.Domain] = true

		if section.Required && section.Status != StatusReady {
			if section.DeferredToInternalFinanceDashboard && input.AllowInternalFinanceDashboardDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_SECTION_NOT_READY", fmt.Sprintf("required collection section READY değil: %s", key))
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
		checkBool(&result, input.RequireInvoiceSource, section.Required, section.RequiresInvoiceSource, "INVOICE_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireBillingSource, section.Required, section.RequiresBillingSource, "BILLING_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequirePaymentAttemptSource, section.Required, section.RequiresPaymentAttemptSource, "PAYMENT_ATTEMPT_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireSuccessRateFormula, section.Required, section.RequiresSuccessRateFormula, "SUCCESS_RATE_FORMULA_REQUIRED", key)
		checkBool(&result, input.RequireFailedPaymentMetric, section.Required, section.RequiresFailedPaymentMetric, "FAILED_PAYMENT_METRIC_REQUIRED", key)
		checkBool(&result, input.RequireRecoveryMetric, section.Required, section.RequiresRecoveryMetric, "RECOVERY_METRIC_REQUIRED", key)
		checkBool(&result, input.RequireAgingBucket, section.Required, section.RequiresAgingBucket, "AGING_BUCKET_REQUIRED", key)
		checkBool(&result, input.RequireCollectionRiskSignal, section.Required, section.RequiresCollectionRiskSignal, "COLLECTION_RISK_SIGNAL_REQUIRED", key)
		checkBool(&result, input.RequireTaxPolicy, section.Required, section.RequiresTaxPolicy, "TAX_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireDataFreshness, section.Required, section.RequiresDataFreshness, "DATA_FRESHNESS_REQUIRED", key)
		checkBool(&result, input.RequireAuditTrail, section.Required, section.RequiresAuditTrail, "AUDIT_TRAIL_REQUIRED", key)
		checkBool(&result, input.RequirePrivacyGuard, section.Required, section.RequiresPrivacyGuard, "PRIVACY_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireExportPolicy, section.Required, section.RequiresExportPolicy, "EXPORT_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireProductionCollectionReportBlock, section.Required, section.BlocksProductionCollectionReport, "PRODUCTION_COLLECTION_REPORT_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealCustomerCollectionBlock, section.Required, section.BlocksRealCustomerCollection, "REAL_CUSTOMER_COLLECTION_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireExternalFinanceExportBlock, section.Required, section.BlocksExternalFinanceExport, "EXTERNAL_FINANCE_EXPORT_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireAutoDunningBlock, section.Required, section.BlocksAutoDunning, "AUTO_DUNNING_BLOCK_REQUIRED", key)

		if section.ProductionCollectionReportEnabled {
			addFail(&result, "SECTION_PRODUCTION_COLLECTION_REPORT_ENABLED_BLOCKED", fmt.Sprintf("production collection report enabled açık olamaz: %s", key))
		}

		if section.RealCustomerCollectionEnabled {
			addFail(&result, "SECTION_REAL_CUSTOMER_COLLECTION_ENABLED_BLOCKED", fmt.Sprintf("real customer collection enabled açık olamaz: %s", key))
		}

		if section.ExternalFinanceExportEnabled {
			addFail(&result, "SECTION_EXTERNAL_FINANCE_EXPORT_ENABLED_BLOCKED", fmt.Sprintf("external finance export açık olamaz: %s", key))
		}

		if section.AutoDunningEnabled {
			addFail(&result, "SECTION_AUTO_DUNNING_ENABLED_BLOCKED", fmt.Sprintf("auto dunning açık olamaz: %s", key))
		}

		if section.DeferredToInternalFinanceDashboard && strings.TrimSpace(section.DeferredReason) == "" {
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
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("collection success report domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalCollectionSuccessReportReady = input.InternalCollectionSuccessReportReady
	result.ProductionCollectionReportEnabled = false
	result.RealCustomerCollectionEnabled = false
	result.ExternalFinanceExportEnabled = false
	result.AutoDunningEnabled = false
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
		return errors.New("collection success report failed")
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
