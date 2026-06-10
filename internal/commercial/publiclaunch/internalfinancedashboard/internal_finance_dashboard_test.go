package internalfinancedashboard

import "testing"

func TestInternalFinanceDashboardPassesInternalReadiness(t *testing.T) {
	input := validDashboardInput()

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if result.Status != "PASS" {
		t.Fatalf("expected PASS got %s findings=%v", result.Status, result.Findings)
	}

	if result.RequiredFailCount != 0 {
		t.Fatalf("expected zero required fails got %d", result.RequiredFailCount)
	}

	if !result.InternalFinanceDashboardReady {
		t.Fatal("internal finance dashboard readiness must be true")
	}

	if result.ProductionDashboardEnabled {
		t.Fatal("production dashboard must remain disabled")
	}

	if result.RealCustomerFinanceEnabled {
		t.Fatal("real customer finance must remain disabled")
	}

	if result.ExternalFinanceExportEnabled {
		t.Fatal("external finance export must remain disabled")
	}

	if result.AutoExecutiveEmailEnabled {
		t.Fatal("auto executive email must remain disabled")
	}

	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestInternalFinanceDashboardBlocksProductionDashboard(t *testing.T) {
	input := validDashboardInput()
	input.ProductionDashboardEnabled = true

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if result.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", result.Status)
	}

	if result.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestInternalFinanceDashboardRequiresMRRARRSource(t *testing.T) {
	input := validDashboardInput()
	input.Panels[0].RequiresMRRARRSource = false

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if result.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", result.Status)
	}

	if result.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestInternalFinanceDashboardRequiresDeferredReason(t *testing.T) {
	input := validDashboardInput()

	for idx := range input.Panels {
		if input.Panels[idx].DeferredToPricingTable {
			input.Panels[idx].DeferredReason = ""
		}
	}

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if result.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", result.Status)
	}

	if result.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestRequiredPanelKeysSorted(t *testing.T) {
	input := DashboardInput{RequiredPanelKeys: []string{"mrr_arr_panel", "cashflow_projection_panel"}}
	keys := RequiredPanelKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "cashflow_projection_panel" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validDashboardInput() DashboardInput {
	return DashboardInput{
		Phase:                         "FAZ_5_18_7_4",
		Target:                        "FAZ_5_R_INTERNAL_FINANCE_DASHBOARD",
		InternalFinanceDashboardReady: true,
		ProductionDashboardEnabled:    false,
		RealCustomerFinanceEnabled:    false,
		ExternalFinanceExportEnabled:  false,
		AutoExecutiveEmailEnabled:     false,
		RequiredPanelKeys: []string{
			"executive_finance_summary",
			"mrr_arr_panel",
			"churn_expansion_panel",
			"collection_success_panel",
			"billing_risk_panel",
			"cashflow_projection_panel",
			"finance_ops_alert_panel",
			"audit_evidence_panel",
			"pricing_table_deferred_marker",
		},
		RequiredDomains: []DashboardDomain{
			DomainRevenue,
			DomainCollection,
			DomainBilling,
			DomainRisk,
			DomainCashflow,
			DomainOpsAlert,
			DomainAuditEvidence,
			DomainNextPriority,
		},
		RequireEvidence:                   true,
		RequireCounterBasedAudit:          true,
		RequireNoRequiredFail:             true,
		RequireNoOptionalWarn:             true,
		RequireTenantID:                   true,
		RequirePeriodWindow:               true,
		RequireMRRARRSource:               true,
		RequireChurnExpansionSource:       true,
		RequireCollectionSuccessSource:    true,
		RequireBillingSource:              true,
		RequireCashflowProjection:         true,
		RequireRiskSignal:                 true,
		RequireAlertThreshold:             true,
		RequireDataFreshness:              true,
		RequireAuditTrail:                 true,
		RequirePrivacyGuard:               true,
		RequireExportPolicy:               true,
		RequireOwnerBreakdown:             true,
		RequireDecisionNote:               true,
		RequireProductionDashboardBlock:   true,
		RequireRealCustomerFinanceBlock:   true,
		RequireExternalFinanceExportBlock: true,
		RequireAutoExecutiveEmailBlock:    true,
		AllowPricingTableDeferred:         true,
		Panels: []DashboardPanel{
			panel("executive_finance_summary", DomainRevenue, "Executive Finance Summary"),
			panel("mrr_arr_panel", DomainRevenue, "MRR / ARR Panel"),
			panel("churn_expansion_panel", DomainRisk, "Churn / Expansion Panel"),
			panel("collection_success_panel", DomainCollection, "Collection Success Panel"),
			panel("billing_risk_panel", DomainBilling, "Billing Risk Panel"),
			panel("cashflow_projection_panel", DomainCashflow, "Cashflow Projection Panel"),
			panel("finance_ops_alert_panel", DomainOpsAlert, "Finance Ops Alert Panel"),
			panel("audit_evidence_panel", DomainAuditEvidence, "Audit Evidence Panel"),
			deferred("pricing_table_deferred_marker", DomainNextPriority, "Pricing Table Deferred Marker"),
		},
	}
}

func panel(key string, domain DashboardDomain, title string) DashboardPanel {
	return DashboardPanel{
		Key:                             key,
		Domain:                          domain,
		Title:                           title,
		Owner:                           "commercial_finance_ops",
		Status:                          StatusReady,
		Required:                        true,
		HasEvidence:                     true,
		HasCounterBasedAudit:            true,
		RequiredFailCount:               0,
		OptionalWarnCount:               0,
		ProductionDashboardEnabled:      false,
		RealCustomerFinanceEnabled:      false,
		ExternalFinanceExportEnabled:    false,
		AutoExecutiveEmailEnabled:       false,
		RequiresTenantID:                true,
		RequiresPeriodWindow:            true,
		RequiresMRRARRSource:            true,
		RequiresChurnExpansionSource:    true,
		RequiresCollectionSuccessSource: true,
		RequiresBillingSource:           true,
		RequiresCashflowProjection:      true,
		RequiresRiskSignal:              true,
		RequiresAlertThreshold:          true,
		RequiresDataFreshness:           true,
		RequiresAuditTrail:              true,
		RequiresPrivacyGuard:            true,
		RequiresExportPolicy:            true,
		RequiresOwnerBreakdown:          true,
		RequiresDecisionNote:            true,
		BlocksProductionDashboard:       true,
		BlocksRealCustomerFinance:       true,
		BlocksExternalFinanceExport:     true,
		BlocksAutoExecutiveEmail:        true,
		DeferredToPricingTable:          false,
	}
}

func deferred(key string, domain DashboardDomain, title string) DashboardPanel {
	p := panel(key, domain, title)
	p.Status = StatusPendingNext
	p.DeferredToPricingTable = true
	p.DeferredReason = "Fiyat tablosu 272 — FAZ 5-18.1.2 içinde açılacak"
	return p
}
