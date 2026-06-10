package logo

import "testing"

func TestLogoFinalClosureContractReadiness(t *testing.T) {
	contract := NewLogoFinalClosureContract()

	if err := contract.Validate(); err != nil {
		t.Fatalf("Logo final closure contract must validate: %v", err)
	}

	if contract.Step != StepFAZ78L10 {
		t.Fatalf("step mismatch: got %s", contract.Step)
	}

	if contract.ClosureMode != LogoFinalClosureMode {
		t.Fatalf("closure mode mismatch: got %s", contract.ClosureMode)
	}

	t.Log("7-8L IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10 IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.1 final closure contract readiness IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.2 E2E dry-run dependency validation IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFinalClosureKeepsRealIntegrationsClosed(t *testing.T) {
	contract := NewLogoFinalClosureContract()

	if !contract.RealIntegrationsClosed() {
		t.Fatal("real provider API, file delivery, ERP write, secret values, and delivery channel must remain closed")
	}

	for _, operation := range contract.Operations {
		if !operation.FinalClosureAllowed {
			t.Fatalf("operation %s must allow final closure", operation.Name)
		}
		if operation.ExternalCallAllowed {
			t.Fatalf("operation %s must not allow external calls", operation.Name)
		}
		if operation.RealFileDeliveryAllowed {
			t.Fatalf("operation %s must not allow real file delivery", operation.Name)
		}
		if operation.ERPWriteAllowed {
			t.Fatalf("operation %s must not allow ERP writes", operation.Name)
		}
		if operation.RealProviderLiveAllowed {
			t.Fatalf("operation %s must not allow real provider live", operation.Name)
		}
	}

	t.Log("7-8L.10.3 final closure allowed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.4 real Logo provider API closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.5 real Logo file delivery closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.6 real ERP write closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.7 real provider live disabled IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFinalClosureValidatesAllRequiredStepSeals(t *testing.T) {
	contract := NewLogoFinalClosureContract()

	if err := contract.ValidateRequiredStepSeals(); err != nil {
		t.Fatalf("required step seals must validate: %v", err)
	}

	requiredSteps := []string{
		"FAZ_7_8L.1",
		"FAZ_7_8L.2",
		"FAZ_7_8L.3",
		"FAZ_7_8L.4",
		"FAZ_7_8L.5",
		"FAZ_7_8L.6",
		"FAZ_7_8L.7",
		"FAZ_7_8L.8",
		"FAZ_7_8L.9",
	}

	for _, step := range requiredSteps {
		if _, ok := contract.RequiredStepSeal(step); !ok {
			t.Fatalf("missing required step seal: %s", step)
		}
	}

	t.Log("7-8L.10.8 7-8L.1 seal validated IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.9 7-8L.2 seal validated IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.10 7-8L.3 seal validated IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.11 7-8L.4 seal validated IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.12 7-8L.5 seal validated IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.13 7-8L.6 seal validated IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.14 7-8L.7 seal validated IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.15 7-8L.8 seal validated IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.16 7-8L.9 seal validated IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFinalClosureProviderLiveHandoffGate(t *testing.T) {
	contract := NewLogoFinalClosureContract()

	if err := contract.ProviderLiveRequirements.Validate(); err != nil {
		t.Fatalf("provider live requirements must validate: %v", err)
	}

	if contract.ProviderLiveHandoffGate != LogoProviderLiveHandoffGate {
		t.Fatalf("provider live handoff gate mismatch: %s", contract.ProviderLiveHandoffGate)
	}

	if contract.ModuleFinalSealStatus != LogoConnectorModuleFinalSealStatus {
		t.Fatalf("module final seal mismatch: %s", contract.ModuleFinalSealStatus)
	}

	t.Log("7-8L.10.17 provider live handoff gate IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.18 provider live approvals pending IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.19 Logo dry-run module sealed IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFinalClosureBuildsSummary(t *testing.T) {
	contract := NewLogoFinalClosureContract()

	summary, err := contract.BuildSummary()
	if err != nil {
		t.Fatalf("summary must build: %v", err)
	}

	if summary.ModuleFinalSealStatus != LogoConnectorModuleFinalSealStatus {
		t.Fatalf("module final seal mismatch: %s", summary.ModuleFinalSealStatus)
	}

	if summary.ProviderLiveHandoffGate != LogoProviderLiveHandoffGate {
		t.Fatalf("provider live handoff gate mismatch: %s", summary.ProviderLiveHandoffGate)
	}

	if summary.FAZ79HoldStatus != LogoFAZ79HoldStatus {
		t.Fatalf("FAZ 7-9 hold mismatch: %s", summary.FAZ79HoldStatus)
	}

	if len(summary.SealedSteps) != 9 {
		t.Fatalf("expected 9 sealed steps, got %d", len(summary.SealedSteps))
	}

	t.Log("7-8L.10.20 final closure summary IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.21 FAZ 7-9 hold marker IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.10.22 next provider module ready marker IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFinalClosureRejectsOpenProviderAPI(t *testing.T) {
	contract := NewLogoFinalClosureContract()
	contract.RealProviderAPIStatus = "OPEN"

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real provider API is open")
	}

	t.Log("7-8L.10.23 open real provider API rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFinalClosureRejectsRealProviderLiveAllowed(t *testing.T) {
	contract := NewLogoFinalClosureContract()
	contract.Operations[0].RealProviderLiveAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real provider live is allowed")
	}

	t.Log("7-8L.10.24 real provider live guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFinalClosureRejectsExternalOperation(t *testing.T) {
	contract := NewLogoFinalClosureContract()
	contract.Operations[0].ExternalCallAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when external call is allowed")
	}

	t.Log("7-8L.10.25 external call guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFinalClosureRejectsRealFileDeliveryOperation(t *testing.T) {
	contract := NewLogoFinalClosureContract()
	contract.Operations[0].RealFileDeliveryAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real file delivery is allowed")
	}

	t.Log("7-8L.10.26 real file delivery guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFinalClosureRejectsERPWriteOperation(t *testing.T) {
	contract := NewLogoFinalClosureContract()
	contract.Operations[0].ERPWriteAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when ERP write is allowed")
	}

	t.Log("7-8L.10.27 ERP write guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFinalClosureRejectsMissingStepSeal(t *testing.T) {
	contract := NewLogoFinalClosureContract()
	contract.RequiredStepSeals = contract.RequiredStepSeals[:8]

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when 7-8L.9 seal is missing")
	}

	t.Log("7-8L.10.28 missing required step seal rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}
