package supportsla

import "testing"

func TestSupportSLALevelsPassInternalReadiness(t *testing.T) {
	input := validSLAInput()

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
	if !report.InternalSLAReady {
		t.Fatal("internal SLA readiness must be true")
	}
	if report.ProductionSLAPublished {
		t.Fatal("production SLA publication must remain blocked")
	}
	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestSupportSLALevelsBlockProductionPublication(t *testing.T) {
	input := validSLAInput()
	input.ProductionSLAPublished = true

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
	if report.ProductionSLAPublished {
		t.Fatal("production SLA publication must be blocked")
	}
}

func TestSupportSLALevelsRejectInvalidPriorityOrder(t *testing.T) {
	input := validSLAInput()
	input.Levels[0].ResponseSLAHours = 99

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

func TestRequiredPrioritiesSorted(t *testing.T) {
	input := SLAInput{RequiredPriorities: []Priority{PriorityP3, PriorityP0, PriorityP2, PriorityP1}}
	priorities := RequiredPriorities(input)

	if len(priorities) != 4 {
		t.Fatalf("expected 4 priorities got %d", len(priorities))
	}
	if priorities[0] != PriorityP0 {
		t.Fatalf("expected P0 first got %v", priorities)
	}
	if priorities[3] != PriorityP3 {
		t.Fatalf("expected P3 last got %v", priorities)
	}
}

func validSLAInput() SLAInput {
	return SLAInput{
		Phase:                  "FAZ_5_18_4_1",
		Target:                 "FAZ_5_R_SUPPORT_OPS_READINESS",
		InternalSLAReady:       true,
		ProductionSLAPublished: false,
		RequiredPriorities: []Priority{
			PriorityP0,
			PriorityP1,
			PriorityP2,
			PriorityP3,
		},
		RequireTenantScope:    true,
		RequireOpsOwner:       true,
		RequireBusinessOwner:  true,
		RequireEscalationRule: true,
		RequireBreachPolicy:   true,
		RequireUpdateInterval: true,
		Levels: []SLALevel{
			{
				Key:                 "sla_p0_critical",
				Priority:            PriorityP0,
				Title:               "P0 Critical SLA",
				Status:              StatusReady,
				Required:            true,
				ResponseSLAHours:    1,
				ResolutionSLAHours:  4,
				EscalationSLAHours:  1,
				UpdateIntervalHours: 1,
				TenantScoped:        true,
				HasOpsOwner:         true,
				HasBusinessOwner:    true,
				HasEscalationRule:   true,
				HasBreachPolicy:     true,
				PublicVisible:       false,
			},
			{
				Key:                 "sla_p1_high",
				Priority:            PriorityP1,
				Title:               "P1 High SLA",
				Status:              StatusReady,
				Required:            true,
				ResponseSLAHours:    4,
				ResolutionSLAHours:  24,
				EscalationSLAHours:  4,
				UpdateIntervalHours: 4,
				TenantScoped:        true,
				HasOpsOwner:         true,
				HasBusinessOwner:    true,
				HasEscalationRule:   true,
				HasBreachPolicy:     true,
				PublicVisible:       false,
			},
			{
				Key:                 "sla_p2_normal",
				Priority:            PriorityP2,
				Title:               "P2 Normal SLA",
				Status:              StatusReady,
				Required:            true,
				ResponseSLAHours:    24,
				ResolutionSLAHours:  72,
				EscalationSLAHours:  24,
				UpdateIntervalHours: 24,
				TenantScoped:        true,
				HasOpsOwner:         true,
				HasBusinessOwner:    true,
				HasEscalationRule:   true,
				HasBreachPolicy:     true,
				PublicVisible:       false,
			},
			{
				Key:                 "sla_p3_low",
				Priority:            PriorityP3,
				Title:               "P3 Low SLA",
				Status:              StatusReady,
				Required:            true,
				ResponseSLAHours:    48,
				ResolutionSLAHours:  168,
				EscalationSLAHours:  48,
				UpdateIntervalHours: 48,
				TenantScoped:        true,
				HasOpsOwner:         true,
				HasBusinessOwner:    true,
				HasEscalationRule:   true,
				HasBreachPolicy:     true,
				PublicVisible:       false,
			},
		},
	}
}
