package commercialclosure

import "testing"

func TestCommercialClosurePassesInternalReadiness(t *testing.T) {
	input := validClosureInput()

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

	if !report.InternalCommercialClosureReady {
		t.Fatal("internal commercial closure readiness must be true")
	}

	if !report.Priority1CommercialBlockComplete {
		t.Fatal("priority 1 commercial block must be complete")
	}

	if report.ProductionPublicLaunchAllowed {
		t.Fatal("production public launch must remain blocked")
	}

	if report.RealCustomerCommercialOpsOpen {
		t.Fatal("real customer commercial ops must remain closed")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestCommercialClosureBlocksProductionPublicLaunch(t *testing.T) {
	input := validClosureInput()
	input.ProductionPublicLaunchAllowed = true

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

func TestCommercialClosureRequiresEvidence(t *testing.T) {
	input := validClosureInput()
	input.Items[0].HasEvidence = false

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

func TestCommercialClosureAllowsDeferredNextPriorityWithReason(t *testing.T) {
	input := validClosureInput()

	found := false
	for _, item := range input.Items {
		if item.DeferredToNextPriority && item.DeferredReason != "" {
			found = true
		}
	}

	if !found {
		t.Fatal("expected deferred next priority marker")
	}
}

func TestRequiredItemKeysSorted(t *testing.T) {
	input := ClosureInput{RequiredItemKeys: []string{"support_readiness_complete", "compliance_block_complete"}}
	keys := RequiredItemKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "compliance_block_complete" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validClosureInput() ClosureInput {
	return ClosureInput{
		Phase:                            "FAZ_5_18_8_4",
		Target:                           "FAZ_5_R_COMMERCIAL_CLOSURE_REPORT",
		InternalCommercialClosureReady:   true,
		Priority1CommercialBlockComplete: true,
		ProductionPublicLaunchAllowed:    false,
		RealCustomerCommercialOpsOpen:    false,
		RequiredItemKeys: []string{
			"compliance_block_complete",
			"support_ops_block_complete",
			"commercial_checklist_complete",
			"legal_checklist_complete",
			"support_readiness_complete",
			"priority_1_closure_gate",
			"production_launch_block",
			"priority_2_ready_marker",
		},
		RequiredDomains: []ClosureDomain{
			DomainCompliance,
			DomainSupportOps,
			DomainCommercial,
			DomainLegal,
			DomainClosure,
			DomainNextPriority,
		},
		RequireInternalReady:           true,
		RequireEvidence:                true,
		RequireCounterBasedAudit:       true,
		RequireNoRequiredFail:          true,
		RequireNoOptionalWarn:          true,
		RequireProductionLaunchBlock:   true,
		AllowDeferredNextPriorityItems: true,
		Items: []ClosureItem{
			ready("compliance_block_complete", DomainCompliance, "Compliance Block Complete"),
			ready("support_ops_block_complete", DomainSupportOps, "Support Ops Block Complete"),
			ready("commercial_checklist_complete", DomainCommercial, "Commercial Checklist Complete"),
			ready("legal_checklist_complete", DomainLegal, "Legal Checklist Complete"),
			ready("support_readiness_complete", DomainSupportOps, "Support Readiness Complete"),
			ready("priority_1_closure_gate", DomainClosure, "Priority 1 Closure Gate"),
			ready("production_launch_block", DomainClosure, "Production Launch Block"),
			deferred("priority_2_ready_marker", DomainNextPriority, "Priority 2 Ready Marker", "Sıradaki iş 257 — FAZ 5-18.2.3 Tahsilat / başarısız ödeme akışı"),
		},
	}
}

func ready(key string, domain ClosureDomain, title string) ClosureItem {
	return ClosureItem{
		Key:                    key,
		Domain:                 domain,
		Title:                  title,
		Owner:                  "commercial_ops",
		Status:                 StatusReady,
		Required:               true,
		InternalReady:          true,
		HasEvidence:            true,
		HasCounterBasedAudit:   true,
		RequiredFailCount:      0,
		OptionalWarnCount:      0,
		ProductionEnabled:      false,
		RealCustomerOpsOpen:    false,
		BlocksProductionLaunch: true,
		DeferredToNextPriority: false,
	}
}

func deferred(key string, domain ClosureDomain, title string, reason string) ClosureItem {
	return ClosureItem{
		Key:                    key,
		Domain:                 domain,
		Title:                  title,
		Owner:                  "commercial_ops",
		Status:                 StatusPendingNext,
		Required:               true,
		InternalReady:          false,
		HasEvidence:            true,
		HasCounterBasedAudit:   true,
		RequiredFailCount:      0,
		OptionalWarnCount:      0,
		ProductionEnabled:      false,
		RealCustomerOpsOpen:    false,
		BlocksProductionLaunch: true,
		DeferredToNextPriority: true,
		DeferredReason:         reason,
	}
}
