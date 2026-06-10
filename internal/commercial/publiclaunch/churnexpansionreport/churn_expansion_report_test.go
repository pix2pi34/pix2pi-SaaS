package churnexpansionreport

import "testing"

func TestChurnExpansionReportPassesInternalReadiness(t *testing.T) {
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

	if !result.InternalChurnExpansionReportReady {
		t.Fatal("internal churn/expansion report readiness must be true")
	}

	if result.ProductionMotionReportEnabled {
		t.Fatal("production motion report must remain disabled")
	}

	if result.RealCustomerMotionEnabled {
		t.Fatal("real customer motion must remain disabled")
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

func TestChurnExpansionReportBlocksProductionMotionReport(t *testing.T) {
	input := validReportInput()
	input.ProductionMotionReportEnabled = true

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

func TestChurnExpansionReportRequiresNRRFormula(t *testing.T) {
	input := validReportInput()
	input.Sections[0].RequiresNRRFormula = false

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

func TestChurnExpansionReportRequiresDeferredReason(t *testing.T) {
	input := validReportInput()

	for idx := range input.Sections {
		if input.Sections[idx].DeferredToCollectionSuccessReport {
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
	input := ReportInput{RequiredSectionKeys: []string{"nrr_summary", "churned_mrr_summary"}}
	keys := RequiredSectionKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "churned_mrr_summary" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validReportInput() ReportInput {
	return ReportInput{
		Phase:                             "FAZ_5_18_7_2",
		Target:                            "FAZ_5_R_CHURN_EXPANSION_REPORT",
		InternalChurnExpansionReportReady: true,
		ProductionMotionReportEnabled:     false,
		RealCustomerMotionEnabled:         false,
		ExternalFinanceExportEnabled:      false,
		AutoExecutiveEmailEnabled:         false,
		RequiredSectionKeys: []string{
			"starting_mrr_base",
			"churned_tenant_summary",
			"churned_mrr_summary",
			"expansion_tenant_summary",
			"expansion_mrr_summary",
			"contraction_mrr_summary",
			"nrr_summary",
			"grr_summary",
			"churn_reason_breakdown",
			"audit_evidence_summary",
			"collection_success_deferred_marker",
		},
		RequiredDomains: []MotionDomain{
			DomainRevenueBase,
			DomainChurn,
			DomainExpansion,
			DomainContraction,
			DomainRetention,
			DomainReason,
			DomainAuditEvidence,
			DomainNextPriority,
		},
		RequireEvidence:                    true,
		RequireCounterBasedAudit:           true,
		RequireNoRequiredFail:              true,
		RequireNoOptionalWarn:              true,
		RequireTenantID:                    true,
		RequirePeriodWindow:                true,
		RequireStartingMRRBase:             true,
		RequireEndingMRRBase:               true,
		RequireChurnMetric:                 true,
		RequireExpansionMetric:             true,
		RequireContractionMetric:           true,
		RequireNRRFormula:                  true,
		RequireGRRFormula:                  true,
		RequireReasonBreakdown:             true,
		RequireSubscriptionSource:          true,
		RequireBillingSource:               true,
		RequirePlanChangeSource:            true,
		RequireCancellationSource:          true,
		RequireCollectionRiskSignal:        true,
		RequireDataFreshness:               true,
		RequireAuditTrail:                  true,
		RequirePrivacyGuard:                true,
		RequireExportPolicy:                true,
		RequireProductionMotionReportBlock: true,
		RequireRealCustomerMotionBlock:     true,
		RequireExternalFinanceExportBlock:  true,
		RequireAutoExecutiveEmailBlock:     true,
		AllowCollectionSuccessDeferred:     true,
		Sections: []MotionSection{
			section("starting_mrr_base", DomainRevenueBase, "Starting MRR Base"),
			section("churned_tenant_summary", DomainChurn, "Churned Tenant Summary"),
			section("churned_mrr_summary", DomainChurn, "Churned MRR Summary"),
			section("expansion_tenant_summary", DomainExpansion, "Expansion Tenant Summary"),
			section("expansion_mrr_summary", DomainExpansion, "Expansion MRR Summary"),
			section("contraction_mrr_summary", DomainContraction, "Contraction MRR Summary"),
			section("nrr_summary", DomainRetention, "NRR Summary"),
			section("grr_summary", DomainRetention, "GRR Summary"),
			section("churn_reason_breakdown", DomainReason, "Churn Reason Breakdown"),
			section("audit_evidence_summary", DomainAuditEvidence, "Audit Evidence Summary"),
			deferred("collection_success_deferred_marker", DomainNextPriority, "Tahsilat Başarı Raporu Deferred Marker"),
		},
	}
}

func section(key string, domain MotionDomain, title string) MotionSection {
	return MotionSection{
		Key:                               key,
		Domain:                            domain,
		Title:                             title,
		Owner:                             "commercial_finance_ops",
		Status:                            StatusReady,
		Required:                          true,
		HasEvidence:                       true,
		HasCounterBasedAudit:              true,
		RequiredFailCount:                 0,
		OptionalWarnCount:                 0,
		ProductionMotionReportEnabled:     false,
		RealCustomerMotionEnabled:         false,
		ExternalFinanceExportEnabled:      false,
		AutoExecutiveEmailEnabled:         false,
		RequiresTenantID:                  true,
		RequiresPeriodWindow:              true,
		RequiresStartingMRRBase:           true,
		RequiresEndingMRRBase:             true,
		RequiresChurnMetric:               true,
		RequiresExpansionMetric:           true,
		RequiresContractionMetric:         true,
		RequiresNRRFormula:                true,
		RequiresGRRFormula:                true,
		RequiresReasonBreakdown:           true,
		RequiresSubscriptionSource:        true,
		RequiresBillingSource:             true,
		RequiresPlanChangeSource:          true,
		RequiresCancellationSource:        true,
		RequiresCollectionRiskSignal:      true,
		RequiresDataFreshness:             true,
		RequiresAuditTrail:                true,
		RequiresPrivacyGuard:              true,
		RequiresExportPolicy:              true,
		BlocksProductionMotionReport:      true,
		BlocksRealCustomerMotion:          true,
		BlocksExternalFinanceExport:       true,
		BlocksAutoExecutiveEmail:          true,
		DeferredToCollectionSuccessReport: false,
	}
}

func deferred(key string, domain MotionDomain, title string) MotionSection {
	s := section(key, domain, title)
	s.Status = StatusPendingNext
	s.DeferredToCollectionSuccessReport = true
	s.DeferredReason = "Tahsilat başarı raporu 270 — FAZ 5-18.7.3 içinde açılacak"
	return s
}
