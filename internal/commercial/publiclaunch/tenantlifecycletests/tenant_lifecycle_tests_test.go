package tenantlifecycletests

import "testing"

func TestTenantLifecycleSuitePassesInternalReadiness(t *testing.T) {
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

	if !report.InternalLifecycleTestsReady {
		t.Fatal("internal lifecycle tests readiness must be true")
	}

	if report.ProductionLifecycleLiveEnabled {
		t.Fatal("production lifecycle live must remain disabled")
	}

	if report.RealCustomerOpsOpen {
		t.Fatal("real customer ops must remain closed")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestTenantLifecycleSuiteBlocksProductionLive(t *testing.T) {
	input := validSuiteInput()
	input.ProductionLifecycleLiveEnabled = true

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

func TestTenantLifecycleSuiteRequiresCrossFlowCoverage(t *testing.T) {
	input := validSuiteInput()
	input.TestCases[0].RequiresCrossFlowCoverage = false

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

func TestTenantLifecycleSuiteRequiresDeferredReason(t *testing.T) {
	input := validSuiteInput()

	for idx := range input.TestCases {
		if input.TestCases[idx].DeferredToCRMStageFlow {
			input.TestCases[idx].DeferredReason = ""
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

func TestRequiredTestKeysSorted(t *testing.T) {
	input := SuiteInput{RequiredTestKeys: []string{"tenant_freeze_contract_test", "tenant_shutdown_contract_test"}}
	keys := RequiredTestKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "tenant_freeze_contract_test" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validSuiteInput() SuiteInput {
	return SuiteInput{
		Phase:                          "FAZ_5_18_5_6",
		Target:                         "FAZ_5_R_TENANT_LIFECYCLE_TEST_SUITE",
		InternalLifecycleTestsReady:    true,
		ProductionLifecycleLiveEnabled: false,
		RealCustomerOpsOpen:            false,
		RequiredTestKeys: []string{
			"tenant_shutdown_contract_test",
			"tenant_data_export_contract_test",
			"tenant_plan_change_contract_test",
			"tenant_freeze_contract_test",
			"cross_flow_billing_guard_test",
			"cross_flow_audit_evidence_test",
			"crm_stage_deferred_marker",
		},
		RequiredDomains: []LifecycleDomain{
			DomainTenantShutdown,
			DomainDataExport,
			DomainPlanChange,
			DomainTenantFreeze,
			DomainCrossFlow,
			DomainNextPriority,
		},
		RequireEvidence:            true,
		RequireCounterBasedAudit:   true,
		RequireNoRequiredFail:      true,
		RequireNoOptionalWarn:      true,
		RequireTenantID:            true,
		RequireAuditTrail:          true,
		RequireRollbackCoverage:    true,
		RequireConfigFixture:       true,
		RequireRuntimePackage:      true,
		RequireEvidenceFile:        true,
		RequireCrossFlowCoverage:   true,
		RequireProductionLiveBlock: true,
		AllowCRMStageDeferred:      true,
		TestCases: []LifecycleTestCase{
			testCase("tenant_shutdown_contract_test", DomainTenantShutdown, "Tenant Shutdown Contract Test", []string{
				"docs/faz5r/FAZ_5_18_5_4_TENANT_KAPATMA.md",
				"configs/faz5r/tenant_shutdown_flow.public_launch.v1.json",
				"internal/commercial/publiclaunch/tenantshutdown",
				"docs/faz5r/evidence/FAZ_5_18_5_4_TENANT_KAPATMA_REAL_IMPLEMENTATION_AUDIT.md",
			}),
			testCase("tenant_data_export_contract_test", DomainDataExport, "Tenant Data Export Contract Test", []string{
				"docs/faz5r/FAZ_5_18_5_5_VERI_EXPORT_DEVIR_AKISI.md",
				"configs/faz5r/tenant_data_export_handover_flow.public_launch.v1.json",
				"internal/commercial/publiclaunch/tenantdataexport",
				"docs/faz5r/evidence/FAZ_5_18_5_5_VERI_EXPORT_DEVIR_AKISI_REAL_IMPLEMENTATION_AUDIT.md",
			}),
			testCase("tenant_plan_change_contract_test", DomainPlanChange, "Tenant Plan Change Contract Test", []string{
				"docs/faz5r/FAZ_5_18_5_2_TENANT_YUKSELTME_DUSURME.md",
				"configs/faz5r/tenant_plan_change_flow.public_launch.v1.json",
				"internal/commercial/publiclaunch/tenantplanchange",
				"docs/faz5r/evidence/FAZ_5_18_5_2_TENANT_YUKSELTME_DUSURME_REAL_IMPLEMENTATION_AUDIT.md",
			}),
			testCase("tenant_freeze_contract_test", DomainTenantFreeze, "Tenant Freeze Contract Test", []string{
				"docs/faz5r/FAZ_5_18_5_3_TENANT_DONDURMA.md",
				"configs/faz5r/tenant_freeze_flow.public_launch.v1.json",
				"internal/commercial/publiclaunch/tenantfreeze",
				"docs/faz5r/evidence/FAZ_5_18_5_3_TENANT_DONDURMA_REAL_IMPLEMENTATION_AUDIT.md",
			}),
			testCase("cross_flow_billing_guard_test", DomainCrossFlow, "Cross Flow Billing Guard Test", []string{
				"FAZ_5_18_2_2_FATURALAMA_AKISI",
				"FAZ_5_18_2_3_TAHSILAT_BASARISIZ_ODEME_AKISI",
				"FAZ_5_18_2_5_IADE_IPTAL_TICARI_AKISI",
			}),
			testCase("cross_flow_audit_evidence_test", DomainCrossFlow, "Cross Flow Audit Evidence Test", []string{
				"REQUIRED_FAIL=0",
				"OPTIONAL_WARN=0",
				"COUNTER_BASED_AUDIT",
			}),
			deferred("crm_stage_deferred_marker", DomainNextPriority, "CRM Stage Deferred Marker", []string{
				"FAZ_5_18_6_2_CRM_STAGE_YONETIMI",
			}),
		},
	}
}

func testCase(key string, domain LifecycleDomain, title string, artifacts []string) LifecycleTestCase {
	return LifecycleTestCase{
		Key:                       key,
		Domain:                    domain,
		Title:                     title,
		Owner:                     "tenant_lifecycle_ops",
		Status:                    StatusReady,
		Required:                  true,
		HasEvidence:               true,
		HasCounterBasedAudit:      true,
		RequiredFailCount:         0,
		OptionalWarnCount:         0,
		ProductionLiveEnabled:     false,
		RealCustomerOpsEnabled:    false,
		RequiresTenantID:          true,
		RequiresAuditTrail:        true,
		RequiresRollbackCoverage:  true,
		RequiresConfigFixture:     true,
		RequiresRuntimePackage:    true,
		RequiresEvidenceFile:      true,
		RequiresCrossFlowCoverage: true,
		BlocksProductionLive:      true,
		CoveredArtifacts:          artifacts,
		DeferredToCRMStageFlow:    false,
	}
}

func deferred(key string, domain LifecycleDomain, title string, artifacts []string) LifecycleTestCase {
	t := testCase(key, domain, title, artifacts)
	t.Status = StatusPendingNext
	t.DeferredToCRMStageFlow = true
	t.DeferredReason = "Sıradaki iş 265 — FAZ 5-18.6.2 CRM stage yönetimi içinde açılacak"
	return t
}
