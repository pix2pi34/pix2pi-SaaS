package internalfinancedashboard

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

type PanelStatus string

const (
	StatusReady       PanelStatus = "READY"
	StatusPendingNext PanelStatus = "PENDING_NEXT"
	StatusBlocked     PanelStatus = "BLOCKED"
)

type DashboardDomain string

const (
	DomainRevenue       DashboardDomain = "REVENUE"
	DomainCollection    DashboardDomain = "COLLECTION"
	DomainBilling       DashboardDomain = "BILLING"
	DomainRisk          DashboardDomain = "RISK"
	DomainCashflow      DashboardDomain = "CASHFLOW"
	DomainOpsAlert      DashboardDomain = "OPS_ALERT"
	DomainAuditEvidence DashboardDomain = "AUDIT_EVIDENCE"
	DomainNextPriority  DashboardDomain = "NEXT_PRIORITY"
)

type DashboardPanel struct {
	Key                             string
	Domain                          DashboardDomain
	Title                           string
	Owner                           string
	Status                          PanelStatus
	Required                        bool
	HasEvidence                     bool
	HasCounterBasedAudit            bool
	RequiredFailCount               int
	OptionalWarnCount               int
	ProductionDashboardEnabled      bool
	RealCustomerFinanceEnabled      bool
	ExternalFinanceExportEnabled    bool
	AutoExecutiveEmailEnabled       bool
	RequiresTenantID                bool
	RequiresPeriodWindow            bool
	RequiresMRRARRSource            bool
	RequiresChurnExpansionSource    bool
	RequiresCollectionSuccessSource bool
	RequiresBillingSource           bool
	RequiresCashflowProjection      bool
	RequiresRiskSignal              bool
	RequiresAlertThreshold          bool
	RequiresDataFreshness           bool
	RequiresAuditTrail              bool
	RequiresPrivacyGuard            bool
	RequiresExportPolicy            bool
	RequiresOwnerBreakdown          bool
	RequiresDecisionNote            bool
	BlocksProductionDashboard       bool
	BlocksRealCustomerFinance       bool
	BlocksExternalFinanceExport     bool
	BlocksAutoExecutiveEmail        bool
	DeferredToPricingTable          bool
	DeferredReason                  string
}

type DashboardInput struct {
	Phase                             string
	Target                            string
	InternalFinanceDashboardReady     bool
	ProductionDashboardEnabled        bool
	RealCustomerFinanceEnabled        bool
	ExternalFinanceExportEnabled      bool
	AutoExecutiveEmailEnabled         bool
	RequiredPanelKeys                 []string
	RequiredDomains                   []DashboardDomain
	Panels                            []DashboardPanel
	RequireEvidence                   bool
	RequireCounterBasedAudit          bool
	RequireNoRequiredFail             bool
	RequireNoOptionalWarn             bool
	RequireTenantID                   bool
	RequirePeriodWindow               bool
	RequireMRRARRSource               bool
	RequireChurnExpansionSource       bool
	RequireCollectionSuccessSource    bool
	RequireBillingSource              bool
	RequireCashflowProjection         bool
	RequireRiskSignal                 bool
	RequireAlertThreshold             bool
	RequireDataFreshness              bool
	RequireAuditTrail                 bool
	RequirePrivacyGuard               bool
	RequireExportPolicy               bool
	RequireOwnerBreakdown             bool
	RequireDecisionNote               bool
	RequireProductionDashboardBlock   bool
	RequireRealCustomerFinanceBlock   bool
	RequireExternalFinanceExportBlock bool
	RequireAutoExecutiveEmailBlock    bool
	AllowPricingTableDeferred         bool
}

type Finding struct {
	Severity string
	Code     string
	Message  string
}

type DashboardResult struct {
	Status                        string
	InternalFinanceDashboardReady bool
	ProductionDashboardEnabled    bool
	RealCustomerFinanceEnabled    bool
	ExternalFinanceExportEnabled  bool
	AutoExecutiveEmailEnabled     bool
	RequiredFailCount             int
	OptionalWarnCount             int
	PassCount                     int
	Findings                      []Finding
}

func Evaluate(input DashboardInput) (DashboardResult, error) {
	result := DashboardResult{
		Status:                        "PASS",
		InternalFinanceDashboardReady: false,
		ProductionDashboardEnabled:    false,
		RealCustomerFinanceEnabled:    false,
		ExternalFinanceExportEnabled:  false,
		AutoExecutiveEmailEnabled:     false,
		Findings:                      []Finding{},
	}

	if strings.TrimSpace(input.Phase) == "" {
		addFail(&result, "PHASE_MISSING", "phase boş olamaz")
	}

	if strings.TrimSpace(input.Target) == "" {
		addFail(&result, "TARGET_MISSING", "target boş olamaz")
	}

	if input.ProductionDashboardEnabled {
		addFail(&result, "PRODUCTION_DASHBOARD_BLOCKED", "bu fazda production finance dashboard açılamaz")
	}

	if input.RealCustomerFinanceEnabled {
		addFail(&result, "REAL_CUSTOMER_FINANCE_BLOCKED", "bu fazda gerçek müşteri finans dashboard açılamaz")
	}

	if input.ExternalFinanceExportEnabled {
		addFail(&result, "EXTERNAL_FINANCE_EXPORT_BLOCKED", "bu fazda external finance export açılamaz")
	}

	if input.AutoExecutiveEmailEnabled {
		addFail(&result, "AUTO_EXECUTIVE_EMAIL_BLOCKED", "bu fazda otomatik yönetici e-postası açılamaz")
	}

	panelByKey := map[string]DashboardPanel{}
	domainCoverage := map[DashboardDomain]bool{}

	for _, panel := range input.Panels {
		key := strings.TrimSpace(panel.Key)
		if key == "" {
			addFail(&result, "DASHBOARD_PANEL_KEY_MISSING", "dashboard panel key boş olamaz")
			continue
		}

		if _, exists := panelByKey[key]; exists {
			addFail(&result, "DASHBOARD_PANEL_DUPLICATE", fmt.Sprintf("dashboard panel duplicate: %s", key))
			continue
		}

		panelByKey[key] = panel
		domainCoverage[panel.Domain] = true

		if panel.Required && panel.Status != StatusReady {
			if panel.DeferredToPricingTable && input.AllowPricingTableDeferred {
				result.PassCount++
			} else {
				addFail(&result, "REQUIRED_PANEL_NOT_READY", fmt.Sprintf("required dashboard panel READY değil: %s", key))
			}
		} else if panel.Required {
			result.PassCount++
		}

		checkBool(&result, input.RequireEvidence, panel.Required, panel.HasEvidence, "EVIDENCE_REQUIRED", key)
		checkBool(&result, input.RequireCounterBasedAudit, panel.Required, panel.HasCounterBasedAudit, "COUNTER_BASED_AUDIT_REQUIRED", key)
		checkZero(&result, input.RequireNoRequiredFail, panel.Required, panel.RequiredFailCount, "REQUIRED_FAIL_MUST_BE_ZERO", key)
		checkZero(&result, input.RequireNoOptionalWarn, panel.Required, panel.OptionalWarnCount, "OPTIONAL_WARN_MUST_BE_ZERO", key)
		checkBool(&result, input.RequireTenantID, panel.Required, panel.RequiresTenantID, "TENANT_ID_REQUIRED", key)
		checkBool(&result, input.RequirePeriodWindow, panel.Required, panel.RequiresPeriodWindow, "PERIOD_WINDOW_REQUIRED", key)
		checkBool(&result, input.RequireMRRARRSource, panel.Required, panel.RequiresMRRARRSource, "MRR_ARR_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireChurnExpansionSource, panel.Required, panel.RequiresChurnExpansionSource, "CHURN_EXPANSION_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireCollectionSuccessSource, panel.Required, panel.RequiresCollectionSuccessSource, "COLLECTION_SUCCESS_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireBillingSource, panel.Required, panel.RequiresBillingSource, "BILLING_SOURCE_REQUIRED", key)
		checkBool(&result, input.RequireCashflowProjection, panel.Required, panel.RequiresCashflowProjection, "CASHFLOW_PROJECTION_REQUIRED", key)
		checkBool(&result, input.RequireRiskSignal, panel.Required, panel.RequiresRiskSignal, "RISK_SIGNAL_REQUIRED", key)
		checkBool(&result, input.RequireAlertThreshold, panel.Required, panel.RequiresAlertThreshold, "ALERT_THRESHOLD_REQUIRED", key)
		checkBool(&result, input.RequireDataFreshness, panel.Required, panel.RequiresDataFreshness, "DATA_FRESHNESS_REQUIRED", key)
		checkBool(&result, input.RequireAuditTrail, panel.Required, panel.RequiresAuditTrail, "AUDIT_TRAIL_REQUIRED", key)
		checkBool(&result, input.RequirePrivacyGuard, panel.Required, panel.RequiresPrivacyGuard, "PRIVACY_GUARD_REQUIRED", key)
		checkBool(&result, input.RequireExportPolicy, panel.Required, panel.RequiresExportPolicy, "EXPORT_POLICY_REQUIRED", key)
		checkBool(&result, input.RequireOwnerBreakdown, panel.Required, panel.RequiresOwnerBreakdown, "OWNER_BREAKDOWN_REQUIRED", key)
		checkBool(&result, input.RequireDecisionNote, panel.Required, panel.RequiresDecisionNote, "DECISION_NOTE_REQUIRED", key)
		checkBool(&result, input.RequireProductionDashboardBlock, panel.Required, panel.BlocksProductionDashboard, "PRODUCTION_DASHBOARD_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireRealCustomerFinanceBlock, panel.Required, panel.BlocksRealCustomerFinance, "REAL_CUSTOMER_FINANCE_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireExternalFinanceExportBlock, panel.Required, panel.BlocksExternalFinanceExport, "EXTERNAL_FINANCE_EXPORT_BLOCK_REQUIRED", key)
		checkBool(&result, input.RequireAutoExecutiveEmailBlock, panel.Required, panel.BlocksAutoExecutiveEmail, "AUTO_EXECUTIVE_EMAIL_BLOCK_REQUIRED", key)

		if panel.ProductionDashboardEnabled {
			addFail(&result, "PANEL_PRODUCTION_DASHBOARD_ENABLED_BLOCKED", fmt.Sprintf("production dashboard enabled açık olamaz: %s", key))
		}

		if panel.RealCustomerFinanceEnabled {
			addFail(&result, "PANEL_REAL_CUSTOMER_FINANCE_ENABLED_BLOCKED", fmt.Sprintf("real customer finance enabled açık olamaz: %s", key))
		}

		if panel.ExternalFinanceExportEnabled {
			addFail(&result, "PANEL_EXTERNAL_FINANCE_EXPORT_ENABLED_BLOCKED", fmt.Sprintf("external finance export açık olamaz: %s", key))
		}

		if panel.AutoExecutiveEmailEnabled {
			addFail(&result, "PANEL_AUTO_EXECUTIVE_EMAIL_ENABLED_BLOCKED", fmt.Sprintf("auto executive email açık olamaz: %s", key))
		}

		if panel.DeferredToPricingTable && strings.TrimSpace(panel.DeferredReason) == "" {
			addFail(&result, "DEFERRED_REASON_REQUIRED", fmt.Sprintf("deferred reason eksik: %s", key))
		}
	}

	for _, requiredKey := range input.RequiredPanelKeys {
		requiredKey = strings.TrimSpace(requiredKey)
		if requiredKey == "" {
			continue
		}

		panel, exists := panelByKey[requiredKey]
		if !exists {
			addFail(&result, "REQUIRED_PANEL_NOT_REGISTERED", fmt.Sprintf("required listesinde olup dashboard içinde yok: %s", requiredKey))
			continue
		}

		if !panel.Required {
			addFail(&result, "REQUIRED_PANEL_FLAG_FALSE", fmt.Sprintf("required listesinde ama panel required=false: %s", requiredKey))
			continue
		}

		result.PassCount++
	}

	for _, domain := range input.RequiredDomains {
		if !domainCoverage[domain] {
			addFail(&result, "REQUIRED_DOMAIN_MISSING", fmt.Sprintf("internal finance dashboard domain eksik: %s", domain))
			continue
		}
		result.PassCount++
	}

	if result.RequiredFailCount > 0 {
		result.Status = "FAIL"
		return result, nil
	}

	result.Status = "PASS"
	result.InternalFinanceDashboardReady = input.InternalFinanceDashboardReady
	result.ProductionDashboardEnabled = false
	result.RealCustomerFinanceEnabled = false
	result.ExternalFinanceExportEnabled = false
	result.AutoExecutiveEmailEnabled = false
	return result, nil
}

func RequiredPanelKeys(input DashboardInput) []string {
	keys := make([]string, 0, len(input.RequiredPanelKeys))
	keys = append(keys, input.RequiredPanelKeys...)
	sort.Strings(keys)
	return keys
}

func MustPass(result DashboardResult) error {
	if result.RequiredFailCount > 0 || result.Status != "PASS" {
		return errors.New("internal finance dashboard failed")
	}
	return nil
}

func checkBool(result *DashboardResult, required bool, panelRequired bool, actual bool, code string, key string) {
	if required && panelRequired && !actual {
		addFail(result, code, fmt.Sprintf("%s eksik: %s", code, key))
	} else if panelRequired {
		result.PassCount++
	}
}

func checkZero(result *DashboardResult, required bool, panelRequired bool, actual int, code string, key string) {
	if required && panelRequired && actual != 0 {
		addFail(result, code, fmt.Sprintf("%s sıfır değil: %s", code, key))
	} else if panelRequired {
		result.PassCount++
	}
}

func addFail(result *DashboardResult, code, message string) {
	result.RequiredFailCount++
	result.Findings = append(result.Findings, Finding{
		Severity: "REQUIRED_FAIL",
		Code:     code,
		Message:  message,
	})
}
