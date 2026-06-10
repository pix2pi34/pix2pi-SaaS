package mrrarrreport

import "testing"

func TestMRRARRReportPassesInternalReadiness(t *testing.T) {
	input := validReportInput()

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

	if !result.InternalMRRARRReportReady {
		t.Fatal("internal MRR/ARR report readiness must be true")
	}

	if result.ProductionRevenueReportEnabled {
		t.Fatal("production revenue report must remain disabled")
	}

	if result.RealCustomerRevenueEnabled {
		t.Fatal("real customer revenue must remain disabled")
	}

	if result.ExternalFinanceExportEnabled {
		t.Fatal("external finance export must remain disabled")
	}

	if result.AutoInvestorEmailEnabled {
		t.Fatal("auto investor email must remain disabled")
	}

	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestMRRARRReportBlocksProductionRevenueReport(t *testing.T) {
	input := validReportInput()
	input.ProductionRevenueReportEnabled = true

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

func TestMRRARRReportRequiresARRFormula(t *testing.T) {
	input := validReportInput()
	input.Sections[0].RequiresARRFormula = false

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

func TestMRRARRReportRequiresDeferredReason(t *testing.T) {
	input := validReportInput()

	for idx := range input.Sections {
		if input.Sections[idx].DeferredToChurnExpansionReport {
			input.Sections[idx].DeferredReason = ""
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

func TestRequiredSectionKeysSorted(t *testing.T) {
	input := ReportInput{RequiredSectionKeys: []string{"arr_summary", "mrr_summary"}}
	keys := RequiredSectionKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "arr_summary" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validReportInput() ReportInput {
	return ReportInput{
		Phase:                          "FAZ_5_18_7_1",
		Target:                         "FAZ_5_R_MRR_ARR_REPORT",
		InternalMRRARRReportReady:      true,
		ProductionRevenueReportEnabled: false,
		RealCustomerRevenueEnabled:     false,
		ExternalFinanceExportEnabled:   false,
		AutoInvestorEmailEnabled:       false,
		RequiredSectionKeys: []string{
			"subscription_base_snapshot",
			"mrr_summary",
			"arr_summary",
			"new_mrr_summary",
			"expansion_mrr_summary",
			"contraction_mrr_summary",
			"collection_status_summary",
			"audit_evidence_summary",
			"churn_expansion_deferred_marker",
		},
		RequiredDomains: []RevenueDomain{
			DomainSubscriptionBase,
			DomainMRR,
			DomainARR,
			DomainExpansion,
			DomainContraction,
			DomainCollection,
			DomainAuditEvidence,
			DomainNextPriority,
		},
		RequireEvidence:                     true,
		RequireCounterBasedAudit:            true,
		RequireNoRequiredFail:               true,
		RequireNoOptionalWarn:               true,
		RequireTenantID:                     true,
		RequirePeriodWindow:                 true,
		RequireSubscriptionSource:           true,
		RequireBillingSource:                true,
		RequirePlanSnapshot:                 true,
		RequireCurrencyPolicy:               true,
		RequireMRRFormula:                   true,
		RequireARRFormula:                   true,
		RequireExpansionMetric:              true,
		RequireContractionMetric:            true,
		RequireCollectionStatus:             true,
		RequireTaxExclusionPolicy:           true,
		RequireDataFreshness:                true,
		RequireAuditTrail:                   true,
		RequirePrivacyGuard:                 true,
		RequireExportPolicy:                 true,
		RequireProductionRevenueReportBlock: true,
		RequireRealCustomerRevenueBlock:     true,
		RequireExternalFinanceExportBlock:   true,
		RequireAutoInvestorEmailBlock:       true,
		AllowChurnExpansionDeferred:         true,
		Sections: []RevenueSection{
			section("subscription_base_snapshot", DomainSubscriptionBase, "Subscription Base Snapshot"),
			section("mrr_summary", DomainMRR, "MRR Summary"),
			section("arr_summary", DomainARR, "ARR Summary"),
			section("new_mrr_summary", DomainMRR, "New MRR Summary"),
			section("expansion_mrr_summary", DomainExpansion, "Expansion MRR Summary"),
			section("contraction_mrr_summary", DomainContraction, "Contraction MRR Summary"),
			section("collection_status_summary", DomainCollection, "Collection Status Summary"),
			section("audit_evidence_summary", DomainAuditEvidence, "Audit Evidence Summary"),
			deferred("churn_expansion_deferred_marker", DomainNextPriority, "Churn / Expansion Deferred Marker"),
		},
	}
}

func section(key string, domain RevenueDomain, title string) RevenueSection {
	return RevenueSection{
		Key:                            key,
		Domain:                         domain,
		Title:                          title,
		Owner:                          "commercial_finance_ops",
		Status:                         StatusReady,
		Required:                       true,
		HasEvidence:                    true,
		HasCounterBasedAudit:           true,
		RequiredFailCount:              0,
		OptionalWarnCount:              0,
		ProductionRevenueReportEnabled: false,
		RealCustomerRevenueEnabled:     false,
		ExternalFinanceExportEnabled:   false,
		AutoInvestorEmailEnabled:       false,
		RequiresTenantID:               true,
		RequiresPeriodWindow:           true,
		RequiresSubscriptionSource:     true,
		RequiresBillingSource:          true,
		RequiresPlanSnapshot:           true,
		RequiresCurrencyPolicy:         true,
		RequiresMRRFormula:             true,
		RequiresARRFormula:             true,
		RequiresExpansionMetric:        true,
		RequiresContractionMetric:      true,
		RequiresCollectionStatus:       true,
		RequiresTaxExclusionPolicy:     true,
		RequiresDataFreshness:          true,
		RequiresAuditTrail:             true,
		RequiresPrivacyGuard:           true,
		RequiresExportPolicy:           true,
		BlocksProductionRevenueReport:  true,
		BlocksRealCustomerRevenue:      true,
		BlocksExternalFinanceExport:    true,
		BlocksAutoInvestorEmail:        true,
		DeferredToChurnExpansionReport: false,
	}
}

func deferred(key string, domain RevenueDomain, title string) RevenueSection {
	s := section(key, domain, title)
	s.Status = StatusPendingNext
	s.DeferredToChurnExpansionReport = true
	s.DeferredReason = "Churn / expansion raporu 269 — FAZ 5-18.7.2 içinde açılacak"
	return s
}
