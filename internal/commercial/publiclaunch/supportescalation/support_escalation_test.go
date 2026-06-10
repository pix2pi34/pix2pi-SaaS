package supportescalation

import "testing"

func TestEscalationMatrixPassesInternalReadiness(t *testing.T) {
	input := validMatrixInput()

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

	if !report.InternalMatrixReady {
		t.Fatal("internal matrix readiness must be true")
	}

	if report.ProductionAutoEscalationEnabled {
		t.Fatal("production auto escalation must remain disabled")
	}

	if report.CustomerNotificationEnabled {
		t.Fatal("customer notification must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestEscalationMatrixBlocksProductionAutoEscalation(t *testing.T) {
	input := validMatrixInput()
	input.ProductionAutoEscalationEnabled = true

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

	if report.ProductionAutoEscalationEnabled {
		t.Fatal("production auto escalation must be blocked")
	}
}

func TestEscalationMatrixRejectsInvalidTransition(t *testing.T) {
	input := validMatrixInput()
	input.Rules[0].FromLevel = LevelL3Engineering
	input.Rules[0].ToLevel = LevelL2Ops

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

func TestEscalationMatrixRequiresLegalOwnerForCompliance(t *testing.T) {
	input := validMatrixInput()

	for idx := range input.Rules {
		if input.Rules[idx].ToLevel == LevelL4Compliance {
			input.Rules[idx].RequiresLegalKVKKSecurityOwner = false
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

func TestRequiredRuleKeysSorted(t *testing.T) {
	input := MatrixInput{RequiredRuleKeys: []string{"security_report_to_compliance", "billing_dispute_to_business"}}
	keys := RequiredRuleKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "billing_dispute_to_business" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validMatrixInput() MatrixInput {
	return MatrixInput{
		Phase:                           "FAZ_5_18_4_4",
		Target:                          "FAZ_5_R_SUPPORT_ESCALATION_MATRIX",
		InternalMatrixReady:             true,
		ProductionAutoEscalationEnabled: false,
		CustomerNotificationEnabled:     false,
		RequiredRuleKeys: []string{
			"sla_breach_to_ops",
			"p0_incident_to_engineering",
			"kvkk_request_to_compliance",
			"security_report_to_compliance",
			"billing_dispute_to_business",
			"unresolved_ticket_to_ops",
		},
		RequiredTriggers: []TriggerType{
			TriggerSLABreach,
			TriggerP0Incident,
			TriggerKVKKRequest,
			TriggerSecurityReport,
			TriggerBillingDispute,
			TriggerUnresolvedTicket,
		},
		RequireTenantID:                  true,
		RequireTicketID:                  true,
		RequireCorrelationID:             true,
		RequireSLAKey:                    true,
		RequireAuditTrail:                true,
		RequireCustomerTemplateForNotify: true,
		RequireOwnerMapping:              true,
		RequireSilentFailureBlock:        true,
		RequireManualReview:              true,
		Rules: []EscalationRule{
			rule("sla_breach_to_ops", TriggerSLABreach, PriorityP1, LevelL1Support, LevelL2Ops, "support_ops", 4, true, true, true, false, false, false),
			rule("p0_incident_to_engineering", TriggerP0Incident, PriorityP0, LevelL2Ops, LevelL3Engineering, "engineering_oncall", 1, true, true, true, true, false, false),
			rule("kvkk_request_to_compliance", TriggerKVKKRequest, PriorityP1, LevelL1Support, LevelL4Compliance, "kvkk_owner", 4, true, true, false, false, false, true),
			rule("security_report_to_compliance", TriggerSecurityReport, PriorityP0, LevelL1Support, LevelL4Compliance, "security_owner", 1, true, true, false, true, false, true),
			rule("billing_dispute_to_business", TriggerBillingDispute, PriorityP1, LevelL1Support, LevelL5Executive, "commercial_owner", 24, true, true, false, false, true, false),
			rule("unresolved_ticket_to_ops", TriggerUnresolvedTicket, PriorityP2, LevelL1Support, LevelL2Ops, "support_ops", 48, false, true, true, false, false, false),
		},
	}
}

func rule(
	key string,
	trigger TriggerType,
	priority Priority,
	from EscalationLevel,
	to EscalationLevel,
	owner string,
	maxAge int,
	notify bool,
	auto bool,
	ops bool,
	engineering bool,
	business bool,
	compliance bool,
) EscalationRule {
	return EscalationRule{
		Key:                            key,
		Trigger:                        trigger,
		Priority:                       priority,
		FromLevel:                      from,
		ToLevel:                        to,
		Owner:                          owner,
		Status:                         StatusReady,
		Required:                       true,
		MaxAgeHours:                    maxAge,
		NotifyCustomer:                 notify,
		AutoEscalate:                   auto,
		ManualReviewAllowed:            true,
		RequiresTenantID:               true,
		RequiresTicketID:               true,
		RequiresCorrelationID:          true,
		RequiresSLAKey:                 true,
		RequiresAuditTrail:             true,
		RequiresCustomerTemplate:       notify,
		RequiresOpsOwner:               ops,
		RequiresBusinessOwner:          business,
		RequiresEngineeringOwner:       engineering,
		RequiresLegalKVKKSecurityOwner: compliance,
		BlocksSilentFailure:            true,
	}
}
