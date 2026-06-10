package supportopstests

import "testing"

func TestSupportOpsTestSuitePassesInternalReadiness(t *testing.T) {
	input := validSuiteInput()

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

	if !report.InternalSupportOpsTestsReady {
		t.Fatal("internal support ops tests readiness must be true")
	}

	if report.ProductionSupportOpsEnabled {
		t.Fatal("production support ops must remain disabled")
	}

	if report.RealCustomerNotificationEnabled {
		t.Fatal("real customer notification must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestSupportOpsTestSuiteBlocksProductionSupportOps(t *testing.T) {
	input := validSuiteInput()
	input.ProductionSupportOpsEnabled = true

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

	if report.ProductionSupportOpsEnabled {
		t.Fatal("production support ops must be blocked")
	}
}

func TestSupportOpsTestSuiteRequiresNegativePath(t *testing.T) {
	input := validSuiteInput()
	input.Cases[0].HasNegativePath = false

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

func TestSupportOpsTestSuiteRequiresEndToEndAssertions(t *testing.T) {
	input := validSuiteInput()

	for idx := range input.Cases {
		if input.Cases[idx].Domain == DomainEndToEnd {
			input.Cases[idx].HasIncidentAssertion = false
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

func TestRequiredCaseKeysSorted(t *testing.T) {
	input := TestSuiteInput{RequiredCaseKeys: []string{"support_negative_guard_test", "support_sla_contract_test"}}
	keys := RequiredCaseKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "support_negative_guard_test" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validSuiteInput() TestSuiteInput {
	return TestSuiteInput{
		Phase:                           "FAZ_5_18_4_6",
		Target:                          "FAZ_5_R_SUPPORT_OPS_TEST_SUITE",
		InternalSupportOpsTestsReady:    true,
		ProductionSupportOpsEnabled:     false,
		RealCustomerNotificationEnabled: false,
		RequiredCaseKeys: []string{
			"support_sla_contract_test",
			"support_channel_intake_test",
			"support_template_contract_test",
			"support_escalation_matrix_test",
			"support_incident_classification_test",
			"support_end_to_end_readiness_test",
			"support_negative_guard_test",
		},
		RequiredDomains: []TestDomain{
			DomainSLA,
			DomainChannel,
			DomainTemplate,
			DomainEscalation,
			DomainIncident,
			DomainEndToEnd,
			DomainNegativeGuard,
		},
		RequirePositivePath:                  true,
		RequireNegativePath:                  true,
		RequireTenantIsolationCheck:          true,
		RequireCorrelationIDCheck:            true,
		RequireAuditEvidenceCheck:            true,
		RequireCounterBasedResult:            true,
		RequirePublicSupportBlock:            true,
		RequireRealCustomerNotificationBlock: true,
		RequireProductionAutoActionBlock:     true,
		Cases: []SupportOpsTestCase{
			testCase("support_sla_contract_test", DomainSLA),
			testCase("support_channel_intake_test", DomainChannel),
			testCase("support_template_contract_test", DomainTemplate),
			testCase("support_escalation_matrix_test", DomainEscalation),
			testCase("support_incident_classification_test", DomainIncident),
			testCase("support_end_to_end_readiness_test", DomainEndToEnd),
			testCase("support_negative_guard_test", DomainNegativeGuard),
		},
	}
}

func testCase(key string, domain TestDomain) SupportOpsTestCase {
	tc := SupportOpsTestCase{
		Key:                            key,
		Domain:                         domain,
		Title:                          key,
		Owner:                          "support_ops",
		Status:                         StatusReady,
		Required:                       true,
		HasPositivePath:                true,
		HasNegativePath:                true,
		HasTenantIsolationCheck:        true,
		HasCorrelationIDCheck:          true,
		HasAuditEvidenceCheck:          true,
		HasCounterBasedResult:          true,
		BlocksPublicSupport:            true,
		BlocksRealCustomerNotification: true,
		BlocksProductionAutoAction:     true,
		ExpectedRequiredFail:           0,
		ExpectedOptionalWarn:           0,
	}

	switch domain {
	case DomainSLA:
		tc.HasSLAAssertion = true
	case DomainChannel:
		tc.HasChannelAssertion = true
	case DomainTemplate:
		tc.HasTemplateAssertion = true
	case DomainEscalation:
		tc.HasEscalationAssertion = true
	case DomainIncident:
		tc.HasIncidentAssertion = true
	case DomainEndToEnd:
		tc.HasSLAAssertion = true
		tc.HasChannelAssertion = true
		tc.HasTemplateAssertion = true
		tc.HasEscalationAssertion = true
		tc.HasIncidentAssertion = true
	case DomainNegativeGuard:
		tc.HasNegativePath = true
	}

	return tc
}
