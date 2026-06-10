package zirve

import (
	"strings"
	"testing"
	"time"
)

func TestZirveFinalClosureReportValidates(t *testing.T) {
	report := NewZirveFinalClosureReport(time.Date(2026, 5, 3, 18, 0, 0, 0, time.UTC))

	if err := report.Validate(); err != nil {
		t.Fatalf("expected final closure report to validate, got error: %v", err)
	}

	if report.ProviderID != "zirve" {
		t.Fatalf("unexpected provider id: %s", report.ProviderID)
	}
	if report.ModuleCode != "FAZ_7_8Z_7" {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.ConnectorModuleFinalSealStatus != "SEALED" {
		t.Fatalf("unexpected seal status: %s", report.ConnectorModuleFinalSealStatus)
	}
	if report.DryRunModuleFinalStatus != "SEALED" {
		t.Fatalf("unexpected dry-run status: %s", report.DryRunModuleFinalStatus)
	}
	if report.RequiredModuleCount != 6 {
		t.Fatalf("expected 6 required modules, got %d", report.RequiredModuleCount)
	}
}

func TestZirveFinalClosureRequiresAllModules(t *testing.T) {
	report := NewZirveFinalClosureReport(time.Time{})

	expected := map[string]bool{
		"FAZ_7_8Z":   false,
		"FAZ_7_8Z_2": false,
		"FAZ_7_8Z_3": false,
		"FAZ_7_8Z_4": false,
		"FAZ_7_8Z_5": false,
		"FAZ_7_8Z_6": false,
	}

	for _, module := range report.RequiredModules {
		expected[module.ModuleCode] = true
		if module.FinalStatus != "PASS" {
			t.Fatalf("module %s must be PASS, got %s", module.StepCode, module.FinalStatus)
		}
		if module.RuntimeFile == "" || module.TestFile == "" || module.ConfigFile == "" || module.DocFile == "" || module.EvidenceFile == "" {
			t.Fatalf("module %s evidence paths must be complete: %+v", module.StepCode, module)
		}
	}

	for moduleCode, seen := range expected {
		if !seen {
			t.Fatalf("required module not present in final closure evidence: %s", moduleCode)
		}
	}
}

func TestZirveFinalClosureKeepsRealBoundariesClosed(t *testing.T) {
	report := NewZirveFinalClosureReport(time.Time{})

	if report.RealProviderAPIAllowed {
		t.Fatal("real provider API must remain closed")
	}
	if report.RealFileDeliveryAllowed {
		t.Fatal("real file delivery must remain closed")
	}
	if report.RealDeliveryChannelAllowed {
		t.Fatal("real delivery channel must remain closed")
	}
	if report.RealERPWriteAllowed {
		t.Fatal("real ERP write must remain closed")
	}
	if report.RealOperatorProviderActionAllowed {
		t.Fatal("real operator provider action must remain closed")
	}
	if report.ProviderLiveModuleStatus != "NOT_STARTED" {
		t.Fatalf("provider live module must remain NOT_STARTED, got %s", report.ProviderLiveModuleStatus)
	}
}

func TestZirveFinalClosureProviderLiveHandoffReadyButLiveNotStarted(t *testing.T) {
	report := NewZirveFinalClosureReport(time.Time{})

	if !report.CanStartRealProviderLiveModule() {
		t.Fatal("provider live handoff should be ready while real operations remain closed")
	}
	if report.ProviderLiveHandoffGate != "READY_FOR_PROVIDER_LIVE_MODULE" {
		t.Fatalf("unexpected provider live handoff gate: %s", report.ProviderLiveHandoffGate)
	}
	if report.ProviderLiveModuleStatus != "NOT_STARTED" {
		t.Fatalf("provider live module must not start in final closure, got %s", report.ProviderLiveModuleStatus)
	}
}

func TestZirveFinalClosureRejectsMissingEvidence(t *testing.T) {
	report := NewZirveFinalClosureReport(time.Time{})
	report.RequiredModules[0].EvidenceFile = ""

	err := report.Validate()
	if err == nil {
		t.Fatal("expected missing evidence file to be rejected")
	}
	if !strings.Contains(err.Error(), "audit evidence file is required") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestZirveFinalClosureRejectsMissingModule(t *testing.T) {
	report := NewZirveFinalClosureReport(time.Time{})
	report.RequiredModules = report.RequiredModules[:5]
	report.RequiredModuleCount = len(report.RequiredModules)

	err := report.Validate()
	if err == nil {
		t.Fatal("expected missing module to be rejected")
	}
	if !strings.Contains(err.Error(), "exactly 6 completed dry-run modules") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestZirveFinalClosureDecisionModel(t *testing.T) {
	report := NewZirveFinalClosureReport(time.Time{})

	sealDecision := report.DecideFinalClosureOperation("DRY_RUN_FINAL_CLOSURE_SEAL")
	if !sealDecision.Allowed {
		t.Fatalf("expected dry-run final closure seal to be allowed: %+v", sealDecision)
	}

	handoffDecision := report.DecideFinalClosureOperation("DRY_RUN_PROVIDER_LIVE_HANDOFF_GATE_PREPARE")
	if !handoffDecision.Allowed {
		t.Fatalf("expected dry-run provider live handoff preparation to be allowed: %+v", handoffDecision)
	}

	realDecision := report.DecideFinalClosureOperation("REAL_ZIRVE_PROVIDER_API_START")
	if realDecision.Allowed {
		t.Fatalf("real provider operation must remain denied: %+v", realDecision)
	}
	if realDecision.RequiredGate != "READY_FOR_PROVIDER_LIVE_MODULE" {
		t.Fatalf("unexpected required gate: %s", realDecision.RequiredGate)
	}
}
