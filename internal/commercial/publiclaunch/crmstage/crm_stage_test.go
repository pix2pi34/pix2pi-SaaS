package crmstage

import "testing"

func TestCRMStageManagementPassesInternalReadiness(t *testing.T) {
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

	if !report.InternalCRMStageReady {
		t.Fatal("internal CRM stage readiness must be true")
	}

	if report.ProductionCRMEnabled {
		t.Fatal("production CRM must remain disabled")
	}

	if report.RealCustomerCRMOpen {
		t.Fatal("real customer CRM must remain closed")
	}

	if report.AutoSalesActionEnabled {
		t.Fatal("auto sales action must remain disabled")
	}

	if report.ExternalCRMProviderEnabled {
		t.Fatal("external CRM provider must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestCRMStageManagementBlocksProductionCRM(t *testing.T) {
	input := validFlowInput()
	input.ProductionCRMEnabled = true

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

func TestCRMStageManagementRequiresConsentCheck(t *testing.T) {
	input := validFlowInput()
	input.Transitions[0].RequiresConsentCheck = false

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

func TestCRMStageManagementRequiresDeferredReason(t *testing.T) {
	input := validFlowInput()

	for idx := range input.Transitions {
		if input.Transitions[idx].DeferredToSalesFlow {
			input.Transitions[idx].DeferredReason = ""
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

func TestRequiredTransitionKeysSorted(t *testing.T) {
	input := FlowInput{RequiredTransitionKeys: []string{"qualified_to_demo", "lead_to_discovery"}}
	keys := RequiredTransitionKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "lead_to_discovery" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validFlowInput() FlowInput {
	return FlowInput{
		Phase:                      "FAZ_5_18_6_2",
		Target:                     "FAZ_5_R_CRM_STAGE_MANAGEMENT",
		InternalCRMStageReady:      true,
		ProductionCRMEnabled:       false,
		RealCustomerCRMOpen:        false,
		AutoSalesActionEnabled:     false,
		ExternalCRMProviderEnabled: false,
		RequiredTransitionKeys: []string{
			"lead_to_discovery",
			"discovery_to_qualified",
			"qualified_to_demo",
			"demo_to_proposal_requested",
			"proposal_requested_to_proposal_sent",
			"proposal_sent_to_won",
			"proposal_sent_to_lost",
			"won_to_onboarding_handoff",
			"quote_sales_flow_deferred_marker",
		},
		RequiredStages: []Stage{
			StageLeadIntake,
			StageDiscovery,
			StageQualified,
			StageDemoScheduled,
			StageProposalRequested,
			StageProposalSent,
			StageWon,
			StageLost,
			StageOnboardingHandoff,
		},
		RequireEvidence:                 true,
		RequireCounterBasedAudit:        true,
		RequireNoRequiredFail:           true,
		RequireNoOptionalWarn:           true,
		RequireTenantID:                 true,
		RequireLeadID:                   true,
		RequireStageReason:              true,
		RequireOwnerAssignment:          true,
		RequireAuditTrail:               true,
		RequireConsentCheck:             true,
		RequireKVKKNotice:               true,
		RequireNextAction:               true,
		RequireSLA:                      true,
		RequireRollbackPath:             true,
		RequireDuplicateGuard:           true,
		RequireManualReview:             true,
		RequireProductionCRMBlock:       true,
		RequireRealCustomerCRMBlock:     true,
		RequireAutoSalesActionBlock:     true,
		RequireExternalCRMProviderBlock: true,
		AllowSalesFlowDeferred:          true,
		Transitions: []StageTransition{
			transition("lead_to_discovery", StageLeadIntake, StageDiscovery, "lead captured"),
			transition("discovery_to_qualified", StageDiscovery, StageQualified, "business fit confirmed"),
			transition("qualified_to_demo", StageQualified, StageDemoScheduled, "demo requested"),
			transition("demo_to_proposal_requested", StageDemoScheduled, StageProposalRequested, "proposal requested"),
			transition("proposal_requested_to_proposal_sent", StageProposalRequested, StageProposalSent, "commercial proposal prepared"),
			transition("proposal_sent_to_won", StageProposalSent, StageWon, "commercial approval received"),
			transition("proposal_sent_to_lost", StageProposalSent, StageLost, "lost reason recorded"),
			transition("won_to_onboarding_handoff", StageWon, StageOnboardingHandoff, "tenant lifecycle handoff"),
			deferred("quote_sales_flow_deferred_marker", StageProposalRequested, StageProposalSent, "Teklif / satış akışı 266 — FAZ 5-18.6.3 içinde açılacak"),
		},
	}
}

func transition(key string, from Stage, to Stage, trigger string) StageTransition {
	return StageTransition{
		Key:                        key,
		From:                       from,
		To:                         to,
		Trigger:                    trigger,
		Owner:                      "commercial_ops",
		Status:                     StatusReady,
		Required:                   true,
		HasEvidence:                true,
		HasCounterBasedAudit:       true,
		RequiredFailCount:          0,
		OptionalWarnCount:          0,
		ProductionCRMEnabled:       false,
		RealCustomerCRMOpen:        false,
		AutoSalesActionEnabled:     false,
		ExternalCRMProviderEnabled: false,
		RequiresTenantID:           true,
		RequiresLeadID:             true,
		RequiresStageReason:        true,
		RequiresOwnerAssignment:    true,
		RequiresAuditTrail:         true,
		RequiresConsentCheck:       true,
		RequiresKVKKNotice:         true,
		RequiresNextAction:         true,
		RequiresSLA:                true,
		RequiresRollbackPath:       true,
		RequiresDuplicateGuard:     true,
		RequiresManualReview:       true,
		BlocksProductionCRM:        true,
		BlocksRealCustomerCRM:      true,
		BlocksAutoSalesAction:      true,
		BlocksExternalCRMProvider:  true,
		DeferredToSalesFlow:        false,
	}
}

func deferred(key string, from Stage, to Stage, reason string) StageTransition {
	t := transition(key, from, to, "sales flow deferred")
	t.Status = StatusPendingNext
	t.DeferredToSalesFlow = true
	t.DeferredReason = reason
	return t
}
