package supportreadiness

import "testing"

func TestSupportReadinessPassesInternalReadiness(t *testing.T) {
	input := validReadinessInput()

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

	if !report.InternalSupportReadinessReady {
		t.Fatal("internal support readiness must be true")
	}

	if report.ProductionSupportEnabled {
		t.Fatal("production support must remain disabled")
	}

	if report.RealCustomerSupportOpen {
		t.Fatal("real customer support must remain closed")
	}

	if report.PublicSupportEnabled {
		t.Fatal("public support must remain disabled")
	}

	if report.CustomerNotificationEnabled {
		t.Fatal("customer notification must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestSupportReadinessBlocksProductionSupport(t *testing.T) {
	input := validReadinessInput()
	input.ProductionSupportEnabled = true

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

func TestSupportReadinessRequiresEscalationBinding(t *testing.T) {
	input := validReadinessInput()
	input.Items[0].RequiresEscalationBinding = false

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

func TestRequiredItemKeysSorted(t *testing.T) {
	input := ReadinessInput{RequiredItemKeys: []string{"support_ops_tests_ready", "support_sla_ready"}}
	keys := RequiredItemKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "support_ops_tests_ready" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validReadinessInput() ReadinessInput {
	return ReadinessInput{
		Phase:                         "FAZ_5_18_8_3",
		Target:                        "FAZ_5_R_SUPPORT_READINESS",
		InternalSupportReadinessReady: true,
		ProductionSupportEnabled:      false,
		RealCustomerSupportOpen:       false,
		PublicSupportEnabled:          false,
		CustomerNotificationEnabled:   false,
		RequiredItemKeys: []string{
			"support_sla_ready",
			"support_channel_ready",
			"support_templates_ready",
			"support_escalation_ready",
			"support_incident_ready",
			"support_ops_tests_ready",
			"commercial_legal_alignment_ready",
			"support_launch_gate_ready",
		},
		RequiredDomains: []ReadinessDomain{
			DomainSLA,
			DomainChannel,
			DomainTemplate,
			DomainEscalation,
			DomainIncident,
			DomainOpsTest,
			DomainCommercialLegal,
			DomainLaunchGate,
		},
		RequireInternalReady:                 true,
		RequireEvidence:                      true,
		RequireCounterBasedAudit:             true,
		RequireNoRequiredFail:                true,
		RequireNoOptionalWarn:                true,
		RequireTenantID:                      true,
		RequireCorrelationID:                 true,
		RequireAuditTrail:                    true,
		RequireSLAContract:                   true,
		RequireEscalationBinding:             true,
		RequireIncidentClassification:        true,
		RequireCommunicationTemplate:         true,
		RequireProductionSupportBlock:        true,
		RequireRealCustomerNotificationBlock: true,
		Items: []SupportReadinessItem{
			item("support_sla_ready", DomainSLA, "Support SLA Ready"),
			item("support_channel_ready", DomainChannel, "Support Channel Ready"),
			item("support_templates_ready", DomainTemplate, "Support Templates Ready"),
			item("support_escalation_ready", DomainEscalation, "Support Escalation Ready"),
			item("support_incident_ready", DomainIncident, "Support Incident Ready"),
			item("support_ops_tests_ready", DomainOpsTest, "Support Ops Tests Ready"),
			item("commercial_legal_alignment_ready", DomainCommercialLegal, "Commercial Legal Alignment Ready"),
			item("support_launch_gate_ready", DomainLaunchGate, "Support Launch Gate Ready"),
		},
	}
}

func item(key string, domain ReadinessDomain, title string) SupportReadinessItem {
	return SupportReadinessItem{
		Key:                            key,
		Domain:                         domain,
		Title:                          title,
		Owner:                          "support_ops",
		Status:                         StatusReady,
		Required:                       true,
		InternalReady:                  true,
		HasEvidence:                    true,
		HasCounterBasedAudit:           true,
		RequiredFailCount:              0,
		OptionalWarnCount:              0,
		ProductionEnabled:              false,
		RealCustomerSupportOpen:        false,
		PublicSupportEnabled:           false,
		CustomerNotificationEnabled:    false,
		RequiresTenantID:               true,
		RequiresCorrelationID:          true,
		RequiresAuditTrail:             true,
		RequiresSLAContract:            true,
		RequiresEscalationBinding:      true,
		RequiresIncidentClassification: true,
		RequiresCommunicationTemplate:  true,
		BlocksProductionSupport:        true,
		BlocksRealCustomerNotification: true,
	}
}
