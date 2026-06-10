package salesopsreport

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type ReportStatus string

const (
	StatusReady       ReportStatus = "READY"
	StatusPendingNext ReportStatus = "PENDING_NEXT"
	StatusBlocked     ReportStatus = "BLOCKED"
)

type ReportDomain string

const (
	DomainCRMStage      ReportDomain = "CRM_STAGE"
	DomainQuoteSales    ReportDomain = "QUOTE_SALES"
	DomainConversion    ReportDomain = "CONVERSION"
	DomainActivity      ReportDomain = "ACTIVITY"
	DomainForecast      ReportDomain = "FORECAST"
	DomainAuditEvidence ReportDomain = "AUDIT_EVIDENCE"
	DomainNextPriority  ReportDomain = "NEXT_PRIORITY"
)

type ReportSection struct {
	Key                         string
	Domain                      ReportDomain
	Title                       string
	Owner                       string
	Status                      ReportStatus
	Required                    bool
	HasEvidence                 bool
	HasCounterBasedAudit        bool
	RequiredFailCount           int
	OptionalWarnCount           int
	ProductionReportEnabled     bool
	RealCustomerReportEnabled   bool
	ExternalBIExportEnabled     bool
	AutoExecutiveEmailEnabled   bool
	RequiresTenantID            bool
	RequiresDateWindow          bool
	RequiresCRMStageSource      bool
	RequiresQuoteSalesSource    bool
	RequiresPipelineMetrics     bool
	RequiresConversionMetrics   bool
	RequiresActivityMetrics     bool
	RequiresForecastMetrics     bool
	RequiresLostReasonBreakdown bool
	RequiresOwnerBreakdown      bool
	RequiresAuditTrail          bool
	RequiresDataFreshness       bool
	RequiresExportPolicy        bool
	RequiresPrivacyGuard        bool
	BlocksProductionReport      bool
	BlocksRealCustomerReport    bool
	BlocksExternalBIExport      bool
	BlocksAutoExecutiveEmail    bool
	DeferredToMRRARRReport      bool
	DeferredReason              string
}

type ReportInput struct {
	Phase                          string
	Target                         string
	InternalSalesOpsReportReady    bool
	ProductionReportEnabled        bool
	RealCustomerReportEnabled      bool
	ExternalBIExportEnabled        bool
	AutoExecutiveEmailEnabled      bool
	RequiredSectionKeys            []string
	RequiredDomains                []ReportDomain
	Sections                       []ReportSection
	RequireEvidence                bool
	RequireCounterBasedAudit       bool
	RequireNoRequiredFail          bool
	RequireNoOptionalWarn          bool
	RequireTenantID                bool
	RequireDateWindow              bool
	RequireCRMStageSource          bool
	RequireQuoteSalesSource        bool
	RequirePipelineMetrics         bool
	RequireConversionMetrics       bool
	RequireActivityMetrics         bool
	RequireForecastMetrics         bool
	RequireLostReasonBreakdown     bool
	RequireOwnerBreakdown          bool
	RequireAuditTrail              bool
	RequireDataFreshness           bool
	RequireExportPolicy            bool
	RequirePrivacyGuard            bool
	RequireProductionReportBlock   bool
	RequireRealCustomerReportBlock bool
	RequireExternalBIExportBlock   bool
	RequireAutoExecutiveEmailBlock bool
	AllowMRRARRReportDeferred      bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type ReportResult struct {
	Status                      string
	InternalSalesOpsReportReady bool
	ProductionReportEnabled     bool
	RealCustomerReportEnabled   bool
	ExternalBIExportEnabled     bool
	AutoExecutiveEmailEnabled   bool
	RequiredFailCount           int
	OptionalWarnCount           int
	PassCount                   int
	Findings                    []Finding
}

func Evaluate(input ReportInput) (ReportResult, error) {
	result := ReportResult{
		Status:                      "PASS",
		InternalSalesOpsReportReady: false,
		ProductionReportEnabled:     false,
		RealCustomerReportEnabled:   false,
		ExternalBIExportEnabled:     false,
		AutoExecutiveEmailEnabled:   false,
		Findings:                    []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionReportEnabled {
		addFail(&result, "PRODUCTION_REPORT_BLOCKED", "bu fazda production sales ops raporu açılamaz")
	}

	if input.RealCustomerReportEnabled {
		addFail(&result, "REAL_CUSTOMER_REPORT_BLOCKED", "bu fazda gerçek müşteri sales ops raporu açılamaz")
	}

	if input.ExternalBIExportEnabled {
		addFail(&result, "EXTERNAL_BI_EXPORT_BLOCKED", "bu fazda external BI export açılamaz")
	}

	if input.AutoExecutiveEmailEnabled {
		addFail(&result, "AUTO_EXECUTIVE_EMAIL_BLOCKED", "bu fazda otomatik yönetici e-postası açılamaz")
	}

	sectionByKey := map[string]ReportSection{}
	domainCoverage := map[ReportDomain]bool{}

	for _, section := range input.Sections {
		key := strings.TrimSpace(section.Key)
		if key == "" {
			addFail(&result, "REPORT_SECTION_KEY_MISSING", "report section key boş olamaz")
			continue
		}

		if _, exists := sectionByKey[key]; exists {
			addFail(&result, "REPORT_SECTION_DUPLICATE", fmt.Sprintf("report section duplicate: %s", key))
			continue
		}

		sectionByKey[key] = section
		domainCoverage[section.Domain] = true

		if section.Required && section.Status != StatusReady {
			if section.DeferredToMRRARRReport && input.AllowMRRARRReportDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_SECTION_NOT_READY", fmt.Sprintf("required sales ops report section READY değil: %s", key))
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

		if input.RequireDateWindow && section.Required && !section.RequiresDateWindow {
			addFail(&result, "DATE_WINDOW_REQUIRED", fmt.Sprintf("date window eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireCRMStageSource && section.Required && !section.RequiresCRMStageSource {
			addFail(&result, "CRM_STAGE_SOURCE_REQUIRED", fmt.Sprintf("CRM stage source eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireQuoteSalesSource && section.Required && !section.RequiresQuoteSalesSource {
			addFail(&result, "QUOTE_SALES_SOURCE_REQUIRED", fmt.Sprintf("quote sales source eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequirePipelineMetrics && section.Required && !section.RequiresPipelineMetrics {
			addFail(&result, "PIPELINE_METRICS_REQUIRED", fmt.Sprintf("pipeline metrics eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireConversionMetrics && section.Required && !section.RequiresConversionMetrics {
			addFail(&result, "CONVERSION_METRICS_REQUIRED", fmt.Sprintf("conversion metrics eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireActivityMetrics && section.Required && !section.RequiresActivityMetrics {
			addFail(&result, "ACTIVITY_METRICS_REQUIRED", fmt.Sprintf("activity metrics eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireForecastMetrics && section.Required && !section.RequiresForecastMetrics {
			addFail(&result, "FORECAST_METRICS_REQUIRED", fmt.Sprintf("forecast metrics eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireLostReasonBreakdown && section.Required && !section.RequiresLostReasonBreakdown {
			addFail(&result, "LOST_REASON_BREAKDOWN_REQUIRED", fmt.Sprintf("lost reason breakdown eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireOwnerBreakdown && section.Required && !section.RequiresOwnerBreakdown {
			addFail(&result, "OWNER_BREAKDOWN_REQUIRED", fmt.Sprintf("owner breakdown eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireAuditTrail && section.Required && !section.RequiresAuditTrail {
			addFail(&result, "AUDIT_TRAIL_REQUIRED", fmt.Sprintf("audit trail eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireDataFreshness && section.Required && !section.RequiresDataFreshness {
			addFail(&result, "DATA_FRESHNESS_REQUIRED", fmt.Sprintf("data freshness eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireExportPolicy && section.Required && !section.RequiresExportPolicy {
			addFail(&result, "EXPORT_POLICY_REQUIRED", fmt.Sprintf("export policy eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequirePrivacyGuard && section.Required && !section.RequiresPrivacyGuard {
			addFail(&result, "PRIVACY_GUARD_REQUIRED", fmt.Sprintf("privacy guard eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireProductionReportBlock && section.Required && !section.BlocksProductionReport {
			addFail(&result, "PRODUCTION_REPORT_BLOCK_REQUIRED", fmt.Sprintf("production report block eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireRealCustomerReportBlock && section.Required && !section.BlocksRealCustomerReport {
			addFail(&result, "REAL_CUSTOMER_REPORT_BLOCK_REQUIRED", fmt.Sprintf("real customer report block eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireExternalBIExportBlock && section.Required && !section.BlocksExternalBIExport {
			addFail(&result, "EXTERNAL_BI_EXPORT_BLOCK_REQUIRED", fmt.Sprintf("external BI export block eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if input.RequireAutoExecutiveEmailBlock && section.Required && !section.BlocksAutoExecutiveEmail {
			addFail(&result, "AUTO_EXECUTIVE_EMAIL_BLOCK_REQUIRED", fmt.Sprintf("auto executive email block eksik: %s", key))
		} else if section.Required {
			result.PassCount++
		}

		if section.ProductionReportEnabled {
			addFail(&result, "SECTION_PRODUCTION_REPORT_ENABLED_BLOCKED", fmt.Sprintf("production report enabled açık olamaz: %s", key))
		}

		if section.RealCustomerReportEnabled {
			addFail(&result, "SECTION_REAL_CUSTOMER_REPORT_ENABLED_BLOCKED", fmt.Sprintf("real customer report enabled açık olamaz: %s", key))
		}

		if section.ExternalBIExportEnabled {
			addFail(&result, "SECTION_EXTERNAL_BI_EXPORT_ENABLED_BLOCKED", fmt.Sprintf("external BI export açık olamaz: %s", key))
		}

		if section.AutoExecutiveEmailEnabled {
			addFail(&result, "SECTION_AUTO_EXECUTIVE_EMAIL_ENABLED_BLOCKED", fmt.Sprintf("auto executive email açık olamaz: %s", key))
		}

		if section.DeferredToMRRARRReport && strings.TrimSpace(section.DeferredReason) == "" {
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
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("sales ops report domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalSalesOpsReportReady = input.InternalSalesOpsReportReady
	result.ProductionReportEnabled = false
	result.RealCustomerReportEnabled = false
	result.ExternalBIExportEnabled = false
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
		return errors.New("sales ops report failed")
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
