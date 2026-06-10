package quotesalesflow

import "testing"

func TestQuoteSalesFlowPassesInternalReadiness(t *testing.T) {
	input := validFlowInput()

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if report.Status != "PASS" {
		t.Fatalf("expected PASS got %s findings=%v", report.Status, report.Findings)
	}

	if report.RequiredFailCount != 0 {
		t.Fatalf("expected zero required fails got %d", report.RequiredFailCount)
	}

	if !report.InternalQuoteSalesFlowReady {
		t.Fatal("internal quote sales flow readiness must be true")
	}

	if report.ProductionSalesEnabled {
		t.Fatal("production sales must remain disabled")
	}

	if report.RealCustomerSalesOpen {
		t.Fatal("real customer sales must remain closed")
	}

	if report.AutoQuoteSendEnabled {
		t.Fatal("auto quote send must remain disabled")
	}

	if report.AutoContractActivationEnabled {
		t.Fatal("auto contract activation must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestQuoteSalesFlowBlocksProductionSales(t *testing.T) {
	input := validFlowInput()
	input.ProductionSalesEnabled = true

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if report.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", report.Status)
	}

	if report.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestQuoteSalesFlowRequiresPricingSnapshot(t *testing.T) {
	input := validFlowInput()
	input.Steps[0].RequiresPricingSnapshot = false

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if report.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", report.Status)
	}

	if report.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestQuoteSalesFlowRequiresDeferredReason(t *testing.T) {
	input := validFlowInput()

	for idx := range input.Steps {
		if input.Steps[idx].DeferredToSalesOpsReport {
			input.Steps[idx].DeferredReason = ""
		}
	}

	report, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if report.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", report.Status)
	}

	if report.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestRequiredStepKeysSorted(t *testing.T) {
	input := FlowInput{RequiredStepKeys: []string{"proposal_draft_create", "quote_request_intake"}}
	keys := RequiredStepKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "proposal_draft_create" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validFlowInput() FlowInput {
	return FlowInput{
		Phase:                         "FAZ_5_18_6_3",
		Target:                        "FAZ_5_R_QUOTE_SALES_FLOW",
		InternalQuoteSalesFlowReady:   true,
		ProductionSalesEnabled:        false,
		RealCustomerSalesOpen:         false,
		AutoQuoteSendEnabled:          false,
		AutoContractActivationEnabled: false,
		RequiredStepKeys: []string{
			"quote_request_intake",
			"crm_stage_verify",
			"customer_profile_validate",
			"pricing_snapshot_attach",
			"discount_approval_queue",
			"proposal_draft_create",
			"commercial_terms_review",
			"quote_approval_record",
			"sales_won_handoff",
			"sales_ops_report_deferred_marker",
		},
		RequiredEvents: []SalesEvent{
			EventQuoteRequestReceived,
			EventCRMStageVerified,
			EventCustomerProfileValidated,
			EventPricingSnapshotAttached,
			EventDiscountApprovalQueued,
			EventProposalDraftCreated,
			EventCommercialTermsReviewed,
			EventQuoteApprovalRecorded,
			EventSalesWonHandoffReady,
			EventSalesOpsReportDeferred,
		},
		RequireEvidence:                    true,
		RequireCounterBasedAudit:           true,
		RequireNoRequiredFail:              true,
		RequireNoOptionalWarn:              true,
		RequireTenantID:                    true,
		RequireLeadID:                      true,
		RequireQuoteID:                     true,
		RequireCRMStage:                    true,
		RequireCustomerProfile:             true,
		RequirePricingSnapshot:             true,
		RequirePlanSnapshot:                true,
		RequireDiscountApproval:            true,
		RequireCommercialTerms:             true,
		RequireOwnerApproval:               true,
		RequireAuditTrail:                  true,
		RequireConsentCheck:                true,
		RequireKVKKNotice:                  true,
		RequireValidityWindow:              true,
		RequireRollbackPath:                true,
		RequireOnboardingHandoff:           true,
		RequireProductionSalesBlock:        true,
		RequireRealCustomerSalesBlock:      true,
		RequireAutoQuoteSendBlock:          true,
		RequireAutoContractActivationBlock: true,
		AllowSalesOpsReportDeferred:        true,
		Steps: []SalesStep{
			step("quote_request_intake", EventQuoteRequestReceived, "Quote Request Intake"),
			step("crm_stage_verify", EventCRMStageVerified, "CRM Stage Verify"),
			step("customer_profile_validate", EventCustomerProfileValidated, "Customer Profile Validate"),
			step("pricing_snapshot_attach", EventPricingSnapshotAttached, "Pricing Snapshot Attach"),
			step("discount_approval_queue", EventDiscountApprovalQueued, "Discount Approval Queue"),
			step("proposal_draft_create", EventProposalDraftCreated, "Proposal Draft Create"),
			step("commercial_terms_review", EventCommercialTermsReviewed, "Commercial Terms Review"),
			step("quote_approval_record", EventQuoteApprovalRecorded, "Quote Approval Record"),
			step("sales_won_handoff", EventSalesWonHandoffReady, "Sales Won Handoff"),
			deferred("sales_ops_report_deferred_marker", EventSalesOpsReportDeferred, "Sales Ops Report Deferred Marker"),
		},
	}
}

func step(key string, event SalesEvent, title string) SalesStep {
	return SalesStep{
		Key:                           key,
		Event:                         event,
		Title:                         title,
		Owner:                         "commercial_ops",
		Status:                        StatusReady,
		Required:                      true,
		HasEvidence:                   true,
		HasCounterBasedAudit:          true,
		RequiredFailCount:             0,
		OptionalWarnCount:             0,
		ProductionSalesEnabled:        false,
		RealCustomerSalesOpen:         false,
		AutoQuoteSendEnabled:          false,
		AutoContractActivationEnabled: false,
		RequiresTenantID:              true,
		RequiresLeadID:                true,
		RequiresQuoteID:               true,
		RequiresCRMStage:              true,
		RequiresCustomerProfile:       true,
		RequiresPricingSnapshot:       true,
		RequiresPlanSnapshot:          true,
		RequiresDiscountApproval:      true,
		RequiresCommercialTerms:       true,
		RequiresOwnerApproval:         true,
		RequiresAuditTrail:            true,
		RequiresConsentCheck:          true,
		RequiresKVKKNotice:            true,
		RequiresValidityWindow:        true,
		RequiresRollbackPath:          true,
		RequiresOnboardingHandoff:     true,
		BlocksProductionSales:         true,
		BlocksRealCustomerSales:       true,
		BlocksAutoQuoteSend:           true,
		BlocksAutoContractActivation:  true,
		DeferredToSalesOpsReport:      false,
	}
}

func deferred(key string, event SalesEvent, title string) SalesStep {
	s := step(key, event, title)
	s.Status = StatusPendingNext
	s.DeferredToSalesOpsReport = true
	s.DeferredReason = "Sales ops raporu 267 — FAZ 5-18.6.4 içinde açılacak"
	return s
}
