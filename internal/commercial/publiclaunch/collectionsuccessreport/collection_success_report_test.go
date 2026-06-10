package collectionsuccessreport

import "testing"

func TestCollectionSuccessReportPassesInternalReadiness(t *testing.T) {
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

	if !result.InternalCollectionSuccessReportReady {
		t.Fatal("internal collection success report readiness must be true")
	}

	if result.ProductionCollectionReportEnabled {
		t.Fatal("production collection report must remain disabled")
	}

	if result.RealCustomerCollectionEnabled {
		t.Fatal("real customer collection must remain disabled")
	}

	if result.ExternalFinanceExportEnabled {
		t.Fatal("external finance export must remain disabled")
	}

	if result.AutoDunningEnabled {
		t.Fatal("auto dunning must remain disabled")
	}

	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestCollectionSuccessReportBlocksProductionCollectionReport(t *testing.T) {
	input := validReportInput()
	input.ProductionCollectionReportEnabled = true

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

func TestCollectionSuccessReportRequiresSuccessRateFormula(t *testing.T) {
	input := validReportInput()
	input.Sections[0].RequiresSuccessRateFormula = false

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

func TestCollectionSuccessReportRequiresDeferredReason(t *testing.T) {
	input := validReportInput()

	for idx := range input.Sections {
		if input.Sections[idx].DeferredToInternalFinanceDashboard {
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
	input := ReportInput{RequiredSectionKeys: []string{"recovery_summary", "collection_success_summary"}}
	keys := RequiredSectionKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "collection_success_summary" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validReportInput() ReportInput {
	return ReportInput{
		Phase:                                "FAZ_5_18_7_3",
		Target:                               "FAZ_5_R_COLLECTION_SUCCESS_REPORT",
		InternalCollectionSuccessReportReady: true,
		ProductionCollectionReportEnabled:    false,
		RealCustomerCollectionEnabled:        false,
		ExternalFinanceExportEnabled:         false,
		AutoDunningEnabled:                   false,
		RequiredSectionKeys: []string{
			"billing_base_snapshot",
			"invoice_collection_summary",
			"collection_success_summary",
			"failed_payment_summary",
			"recovery_summary",
			"aging_bucket_summary",
			"collection_risk_summary",
			"audit_evidence_summary",
			"internal_finance_dashboard_deferred_marker",
		},
		RequiredDomains: []CollectionDomain{
			DomainBillingBase,
			DomainCollection,
			DomainFailedPayment,
			DomainRecovery,
			DomainAging,
			DomainRisk,
			DomainAuditEvidence,
			DomainNextPriority,
		},
		RequireEvidence:                        true,
		RequireCounterBasedAudit:               true,
		RequireNoRequiredFail:                  true,
		RequireNoOptionalWarn:                  true,
		RequireTenantID:                        true,
		RequirePeriodWindow:                    true,
		RequireInvoiceSource:                   true,
		RequireBillingSource:                   true,
		RequirePaymentAttemptSource:            true,
		RequireSuccessRateFormula:              true,
		RequireFailedPaymentMetric:             true,
		RequireRecoveryMetric:                  true,
		RequireAgingBucket:                     true,
		RequireCollectionRiskSignal:            true,
		RequireTaxPolicy:                       true,
		RequireDataFreshness:                   true,
		RequireAuditTrail:                      true,
		RequirePrivacyGuard:                    true,
		RequireExportPolicy:                    true,
		RequireProductionCollectionReportBlock: true,
		RequireRealCustomerCollectionBlock:     true,
		RequireExternalFinanceExportBlock:      true,
		RequireAutoDunningBlock:                true,
		AllowInternalFinanceDashboardDeferred:  true,
		Sections: []CollectionSection{
			section("billing_base_snapshot", DomainBillingBase, "Billing Base Snapshot"),
			section("invoice_collection_summary", DomainCollection, "Invoice Collection Summary"),
			section("collection_success_summary", DomainCollection, "Collection Success Summary"),
			section("failed_payment_summary", DomainFailedPayment, "Failed Payment Summary"),
			section("recovery_summary", DomainRecovery, "Recovery Summary"),
			section("aging_bucket_summary", DomainAging, "Aging Bucket Summary"),
			section("collection_risk_summary", DomainRisk, "Collection Risk Summary"),
			section("audit_evidence_summary", DomainAuditEvidence, "Audit Evidence Summary"),
			deferred("internal_finance_dashboard_deferred_marker", DomainNextPriority, "Internal Finance Dashboard Deferred Marker"),
		},
	}
}

func section(key string, domain CollectionDomain, title string) CollectionSection {
	return CollectionSection{
		Key:                                key,
		Domain:                             domain,
		Title:                              title,
		Owner:                              "commercial_finance_ops",
		Status:                             StatusReady,
		Required:                           true,
		HasEvidence:                        true,
		HasCounterBasedAudit:               true,
		RequiredFailCount:                  0,
		OptionalWarnCount:                  0,
		ProductionCollectionReportEnabled:  false,
		RealCustomerCollectionEnabled:      false,
		ExternalFinanceExportEnabled:       false,
		AutoDunningEnabled:                 false,
		RequiresTenantID:                   true,
		RequiresPeriodWindow:               true,
		RequiresInvoiceSource:              true,
		RequiresBillingSource:              true,
		RequiresPaymentAttemptSource:       true,
		RequiresSuccessRateFormula:         true,
		RequiresFailedPaymentMetric:        true,
		RequiresRecoveryMetric:             true,
		RequiresAgingBucket:                true,
		RequiresCollectionRiskSignal:       true,
		RequiresTaxPolicy:                  true,
		RequiresDataFreshness:              true,
		RequiresAuditTrail:                 true,
		RequiresPrivacyGuard:               true,
		RequiresExportPolicy:               true,
		BlocksProductionCollectionReport:   true,
		BlocksRealCustomerCollection:       true,
		BlocksExternalFinanceExport:        true,
		BlocksAutoDunning:                  true,
		DeferredToInternalFinanceDashboard: false,
	}
}

func deferred(key string, domain CollectionDomain, title string) CollectionSection {
	s := section(key, domain, title)
	s.Status = StatusPendingNext
	s.DeferredToInternalFinanceDashboard = true
	s.DeferredReason = "İç finans dashboard 271 — FAZ 5-18.7.4 içinde açılacak"
	return s
}
