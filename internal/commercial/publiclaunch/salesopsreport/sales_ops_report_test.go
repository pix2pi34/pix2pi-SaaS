package salesopsreport

import "testing"

func TestSalesOpsReportPassesInternalReadiness(t *testing.T) {
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

	if !result.InternalSalesOpsReportReady {
		t.Fatal("internal sales ops report readiness must be true")
	}

	if result.ProductionReportEnabled {
		t.Fatal("production report must remain disabled")
	}

	if result.RealCustomerReportEnabled {
		t.Fatal("real customer report must remain disabled")
	}

	if result.ExternalBIExportEnabled {
		t.Fatal("external BI export must remain disabled")
	}

	if result.AutoExecutiveEmailEnabled {
		t.Fatal("auto executive email must remain disabled")
	}

	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestSalesOpsReportBlocksProductionReport(t *testing.T) {
	input := validReportInput()
	input.ProductionReportEnabled = true

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

func TestSalesOpsReportRequiresPipelineMetrics(t *testing.T) {
	input := validReportInput()
	input.Sections[0].RequiresPipelineMetrics = false

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

func TestSalesOpsReportRequiresDeferredReason(t *testing.T) {
	input := validReportInput()

	for idx := range input.Sections {
		if input.Sections[idx].DeferredToMRRARRReport {
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
	input := ReportInput{RequiredSectionKeys: []string{"quote_sales_summary", "crm_pipeline_summary"}}
	keys := RequiredSectionKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "crm_pipeline_summary" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validReportInput() ReportInput {
	return ReportInput{
		Phase:                       "FAZ_5_18_6_4",
		Target:                      "FAZ_5_R_SALES_OPS_REPORT",
		InternalSalesOpsReportReady: true,
		ProductionReportEnabled:     false,
		RealCustomerReportEnabled:   false,
		ExternalBIExportEnabled:     false,
		AutoExecutiveEmailEnabled:   false,
		RequiredSectionKeys: []string{
			"crm_pipeline_summary",
			"quote_sales_summary",
			"conversion_funnel_summary",
			"activity_sla_summary",
			"forecast_pipeline_summary",
			"lost_reason_summary",
			"owner_performance_summary",
			"audit_evidence_summary",
			"mrr_arr_report_deferred_marker",
		},
		RequiredDomains: []ReportDomain{
			DomainCRMStage,
			DomainQuoteSales,
			DomainConversion,
			DomainActivity,
			DomainForecast,
			DomainAuditEvidence,
			DomainNextPriority,
		},
		RequireEvidence:                true,
		RequireCounterBasedAudit:       true,
		RequireNoRequiredFail:          true,
		RequireNoOptionalWarn:          true,
		RequireTenantID:                true,
		RequireDateWindow:              true,
		RequireCRMStageSource:          true,
		RequireQuoteSalesSource:        true,
		RequirePipelineMetrics:         true,
		RequireConversionMetrics:       true,
		RequireActivityMetrics:         true,
		RequireForecastMetrics:         true,
		RequireLostReasonBreakdown:     true,
		RequireOwnerBreakdown:          true,
		RequireAuditTrail:              true,
		RequireDataFreshness:           true,
		RequireExportPolicy:            true,
		RequirePrivacyGuard:            true,
		RequireProductionReportBlock:   true,
		RequireRealCustomerReportBlock: true,
		RequireExternalBIExportBlock:   true,
		RequireAutoExecutiveEmailBlock: true,
		AllowMRRARRReportDeferred:      true,
		Sections: []ReportSection{
			section("crm_pipeline_summary", DomainCRMStage, "CRM Pipeline Summary"),
			section("quote_sales_summary", DomainQuoteSales, "Quote Sales Summary"),
			section("conversion_funnel_summary", DomainConversion, "Conversion Funnel Summary"),
			section("activity_sla_summary", DomainActivity, "Activity SLA Summary"),
			section("forecast_pipeline_summary", DomainForecast, "Forecast Pipeline Summary"),
			section("lost_reason_summary", DomainConversion, "Lost Reason Summary"),
			section("owner_performance_summary", DomainActivity, "Owner Performance Summary"),
			section("audit_evidence_summary", DomainAuditEvidence, "Audit Evidence Summary"),
			deferred("mrr_arr_report_deferred_marker", DomainNextPriority, "MRR / ARR Report Deferred Marker"),
		},
	}
}

func section(key string, domain ReportDomain, title string) ReportSection {
	return ReportSection{
		Key:                         key,
		Domain:                      domain,
		Title:                       title,
		Owner:                       "commercial_ops",
		Status:                      StatusReady,
		Required:                    true,
		HasEvidence:                 true,
		HasCounterBasedAudit:        true,
		RequiredFailCount:           0,
		OptionalWarnCount:           0,
		ProductionReportEnabled:     false,
		RealCustomerReportEnabled:   false,
		ExternalBIExportEnabled:     false,
		AutoExecutiveEmailEnabled:   false,
		RequiresTenantID:            true,
		RequiresDateWindow:          true,
		RequiresCRMStageSource:      true,
		RequiresQuoteSalesSource:    true,
		RequiresPipelineMetrics:     true,
		RequiresConversionMetrics:   true,
		RequiresActivityMetrics:     true,
		RequiresForecastMetrics:     true,
		RequiresLostReasonBreakdown: true,
		RequiresOwnerBreakdown:      true,
		RequiresAuditTrail:          true,
		RequiresDataFreshness:       true,
		RequiresExportPolicy:        true,
		RequiresPrivacyGuard:        true,
		BlocksProductionReport:      true,
		BlocksRealCustomerReport:    true,
		BlocksExternalBIExport:      true,
		BlocksAutoExecutiveEmail:    true,
		DeferredToMRRARRReport:      false,
	}
}

func deferred(key string, domain ReportDomain, title string) ReportSection {
	s := section(key, domain, title)
	s.Status = StatusPendingNext
	s.DeferredToMRRARRReport = true
	s.DeferredReason = "MRR / ARR raporu 268 — FAZ 5-18.7.1 içinde açılacak"
	return s
}
