package commercialchecklist

import "testing"

func TestCommercialChecklistPassesInternalReadiness(t *testing.T) {
	input := validChecklistInput()

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

	if !report.InternalCommercialChecklistReady {
		t.Fatal("internal commercial checklist readiness must be true")
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

func TestCommercialChecklistBlocksProductionPublicLaunch(t *testing.T) {
	input := validChecklistInput()
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

	if report.ProductionPublicLaunchAllowed {
		t.Fatal("production public launch must be blocked")
	}
}

func TestCommercialChecklistRequiresEvidence(t *testing.T) {
	input := validChecklistInput()
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

func TestCommercialChecklistAllowsDeferredNextPriorityWithReason(t *testing.T) {
	input := validChecklistInput()

	found := false
	for _, item := range input.Items {
		if item.DeferredToNextPriority && item.DeferredReason != "" {
			found = true
		}
	}

	if !found {
		t.Fatal("expected at least one deferred next priority item")
	}
}

func TestRequiredItemKeysSorted(t *testing.T) {
	input := ChecklistInput{RequiredItemKeys: []string{"support_ops_block", "compliance_document_control"}}
	keys := RequiredItemKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "compliance_document_control" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validChecklistInput() ChecklistInput {
	return ChecklistInput{
		Phase:                            "FAZ_5_18_8_1",
		Target:                           "FAZ_5_R_COMMERCIAL_CHECKLIST",
		InternalCommercialChecklistReady: true,
		ProductionPublicLaunchAllowed:    false,
		RealCustomerCommercialOpsOpen:    false,
		RequiredItemKeys: []string{
			"compliance_document_control",
			"log_retention_policy",
			"support_sla_levels",
			"support_channel_structure",
			"customer_communication_templates",
			"support_escalation_matrix",
			"incident_classification",
			"support_ops_test_suite",
			"billing_lifecycle_next_priority_marker",
			"pricing_public_surface_next_priority_marker",
		},
		RequiredDomains: []ChecklistDomain{
			DomainCompliance,
			DomainSupport,
			DomainCommercial,
			DomainLaunchGate,
			DomainDeferred,
		},
		RequireEvidence:                true,
		RequireCounterBasedAudit:       true,
		RequireNoRequiredFail:          true,
		RequireInternalReady:           true,
		AllowDeferredNextPriorityItems: true,
		Items: []ChecklistItem{
			ready("compliance_document_control", DomainCompliance, "Compliance Document Control"),
			ready("log_retention_policy", DomainCompliance, "Log Retention / İmha Politikası"),
			ready("support_sla_levels", DomainSupport, "SLA Seviyeleri"),
			ready("support_channel_structure", DomainSupport, "Destek Kanal Yapısı"),
			ready("customer_communication_templates", DomainSupport, "Müşteri İletişim Şablonları"),
			ready("support_escalation_matrix", DomainSupport, "Escalation Matrisi"),
			ready("incident_classification", DomainSupport, "Incident Sınıflandırma"),
			ready("support_ops_test_suite", DomainSupport, "Support Ops Testleri"),
			deferred("billing_lifecycle_next_priority_marker", DomainDeferred, "Billing / Tenant Lifecycle Next Priority", "257-264 arası Priority 2 içinde kapanacak"),
			deferred("pricing_public_surface_next_priority_marker", DomainDeferred, "Pricing / Public Surface Next Priority", "272-279 arası Priority 3/4 içinde kapanacak"),
			ready("commercial_launch_gate", DomainLaunchGate, "Commercial Launch Gate"),
			ready("commercial_ops_control", DomainCommercial, "Commercial Ops Control"),
		},
	}
}

func ready(key string, domain ChecklistDomain, title string) ChecklistItem {
	return ChecklistItem{
		Key:                       key,
		Domain:                    domain,
		Title:                     title,
		Owner:                     "commercial_ops",
		Status:                    StatusReady,
		Required:                  true,
		BlocksLaunch:              true,
		RequiresEvidence:          true,
		HasEvidence:               true,
		RequiresCounterBasedAudit: true,
		HasCounterBasedAudit:      true,
		RequiresNoRequiredFail:    true,
		RequiredFailCount:         0,
		OptionalWarnCount:         0,
		ProductionEnabled:         false,
		InternalReady:             true,
		DeferredToNextPriority:    false,
	}
}

func deferred(key string, domain ChecklistDomain, title string, reason string) ChecklistItem {
	return ChecklistItem{
		Key:                       key,
		Domain:                    domain,
		Title:                     title,
		Owner:                     "commercial_ops",
		Status:                    StatusPendingNext,
		Required:                  true,
		BlocksLaunch:              true,
		RequiresEvidence:          true,
		HasEvidence:               true,
		RequiresCounterBasedAudit: true,
		HasCounterBasedAudit:      true,
		RequiresNoRequiredFail:    true,
		RequiredFailCount:         0,
		OptionalWarnCount:         0,
		ProductionEnabled:         false,
		InternalReady:             false,
		DeferredToNextPriority:    true,
		DeferredReason:            reason,
	}
}
