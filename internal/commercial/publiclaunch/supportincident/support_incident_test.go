package supportincident

import "testing"

func TestIncidentClassificationPassesInternalReadiness(t *testing.T) {
	input := validClassificationInput()

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

	if !report.InternalClassificationReady {
		t.Fatal("internal classification readiness must be true")
	}

	if report.ProductionAutoClassificationEnabled {
		t.Fatal("production auto classification must remain disabled")
	}

	if report.CustomerNotificationEnabled {
		t.Fatal("customer notification must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestIncidentClassificationBlocksProductionAutoClassification(t *testing.T) {
	input := validClassificationInput()
	input.ProductionAutoClassificationEnabled = true

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

	if report.ProductionAutoClassificationEnabled {
		t.Fatal("production auto classification must be blocked")
	}
}

func TestIncidentClassificationRequiresSecurityOwnerMapping(t *testing.T) {
	input := validClassificationInput()

	for idx := range input.Rules {
		if input.Rules[idx].Category == CategorySecurity {
			input.Rules[idx].RequiresSecurityReview = false
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

func TestIncidentClassificationRequiresSeverityCoverage(t *testing.T) {
	input := validClassificationInput()

	for idx := range input.Rules {
		if input.Rules[idx].Severity == SeverityP3 {
			input.Rules[idx].Severity = SeverityP2
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
	input := ClassificationInput{RequiredRuleKeys: []string{"incident_support_ops_p3", "incident_availability_p0"}}
	keys := RequiredRuleKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "incident_availability_p0" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validClassificationInput() ClassificationInput {
	return ClassificationInput{
		Phase:                               "FAZ_5_18_4_3",
		Target:                              "FAZ_5_R_SUPPORT_INCIDENT_CLASSIFICATION",
		InternalClassificationReady:         true,
		ProductionAutoClassificationEnabled: false,
		CustomerNotificationEnabled:         false,
		RequiredRuleKeys: []string{
			"incident_availability_p0",
			"incident_performance_p2",
			"incident_security_p0",
			"incident_kvkk_p1",
			"incident_billing_p1",
			"incident_data_integrity_p0",
			"incident_support_ops_p3",
		},
		RequiredCategories: []IncidentCategory{
			CategoryAvailability,
			CategoryPerformance,
			CategorySecurity,
			CategoryKVKK,
			CategoryBilling,
			CategoryDataIntegrity,
			CategorySupportOps,
		},
		RequireTenantID:            true,
		RequireTicketID:            true,
		RequireCorrelationID:       true,
		RequireAuditTrail:          true,
		RequireRootCause:           true,
		RequireCustomerImpact:      true,
		RequireManualReview:        true,
		RequireAutoCloseBlock:      true,
		RequireSLAKey:              true,
		RequireEscalationKey:       true,
		RequireCustomerTemplate:    true,
		RequireSpecialOwnerMapping: true,
		Rules: []IncidentRule{
			rule("incident_availability_p0", CategoryAvailability, SeverityP0, "sla_p0_critical", "p0_incident_to_engineering", "template_incident_update", true, false, false, true, true),
			rule("incident_performance_p2", CategoryPerformance, SeverityP2, "sla_p2_normal", "unresolved_ticket_to_ops", "template_incident_update", true, false, false, false, true),
			rule("incident_security_p0", CategorySecurity, SeverityP0, "sla_p0_critical", "security_report_to_compliance", "template_security_report_ack", true, true, false, true, false),
			rule("incident_kvkk_p1", CategoryKVKK, SeverityP1, "sla_p1_high", "kvkk_request_to_compliance", "template_kvkk_request_ack", false, false, true, false, false),
			rule("incident_billing_p1", CategoryBilling, SeverityP1, "sla_p1_high", "billing_dispute_to_business", "template_billing_issue_ack", false, false, false, false, false),
			rule("incident_data_integrity_p0", CategoryDataIntegrity, SeverityP0, "sla_p0_critical", "p0_incident_to_engineering", "template_incident_update", true, false, false, true, true),
			rule("incident_support_ops_p3", CategorySupportOps, SeverityP3, "sla_p3_low", "unresolved_ticket_to_ops", "template_ticket_ack", true, false, false, false, true),
		},
	}
}

func rule(
	key string,
	category IncidentCategory,
	severity Severity,
	sla string,
	escalation string,
	template string,
	supportOwner bool,
	securityReview bool,
	kvkkReview bool,
	engineeringOwner bool,
	customerImpact bool,
) IncidentRule {
	return IncidentRule{
		Key:                           key,
		Category:                      category,
		Severity:                      severity,
		Title:                         key,
		Owner:                         "support_ops",
		Status:                        StatusReady,
		Required:                      true,
		DefaultSLAKey:                 sla,
		DefaultEscalationKey:          escalation,
		DefaultCustomerTemplateKey:    template,
		RequiresTenantID:              true,
		RequiresTicketID:              true,
		RequiresCorrelationID:         true,
		RequiresAuditTrail:            true,
		RequiresRootCause:             true,
		RequiresCustomerImpact:        customerImpact || severity == SeverityP0 || severity == SeverityP1,
		RequiresSecurityReview:        securityReview,
		RequiresKVKKReview:            kvkkReview,
		RequiresBillingOwner:          category == CategoryBilling,
		RequiresEngineeringOwner:      engineeringOwner,
		RequiresSupportOwner:          supportOwner,
		ManualReviewAllowed:           true,
		BlocksAutoClose:               true,
		InternalOnly:                  true,
		ProductionAutoClassifyEnabled: false,
	}
}
