package logo

import "testing"

func TestLogoLiveContractReadiness(t *testing.T) {
	contract := NewLogoLiveContract()

	if err := contract.Validate(); err != nil {
		t.Fatalf("Logo live contract must validate: %v", err)
	}

	if contract.Step != StepFAZ78L2 {
		t.Fatalf("step mismatch: got %s", contract.Step)
	}

	if contract.ContractMode != LogoLiveContractMode {
		t.Fatalf("contract mode mismatch: got %s", contract.ContractMode)
	}

	t.Log("7-8L IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.2 IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.2.1 live contract readiness IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.2.2 foundation dependency validation IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoLiveContractKeepsRealIntegrationsClosed(t *testing.T) {
	contract := NewLogoLiveContract()

	if !contract.RealIntegrationsClosed() {
		t.Fatal("real Logo provider API, file delivery, and ERP write must remain closed")
	}

	for _, operation := range contract.Operations {
		if operation.ExternalCallAllowed {
			t.Fatalf("operation %s must not allow external calls", operation.Name)
		}
		if operation.FileDeliveryAllowed {
			t.Fatalf("operation %s must not allow file delivery", operation.Name)
		}
		if operation.ERPWriteAllowed {
			t.Fatalf("operation %s must not allow ERP writes", operation.Name)
		}
	}

	t.Log("7-8L.2.3 real Logo provider API closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.2.4 real Logo file delivery closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.2.5 real ERP write closed IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoAPIContractDeclaredButRealCallsDisabled(t *testing.T) {
	contract := NewLogoLiveContract()

	if err := contract.APIContract.Validate(); err != nil {
		t.Fatalf("API contract must validate: %v", err)
	}

	if !contract.APIContract.Declared {
		t.Fatal("API contract must be declared")
	}

	if contract.APIContract.RealCallAllowed {
		t.Fatal("real API calls must remain disabled")
	}

	if len(contract.APIContract.Endpoints) < 3 {
		t.Fatalf("expected at least 3 declared API endpoint contracts, got %d", len(contract.APIContract.Endpoints))
	}

	t.Log("7-8L.2.6 API contract declared IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.2.7 real API call disabled IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.2.8 API endpoint placeholders IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFileContractDeclaredButRealDeliveryDisabled(t *testing.T) {
	contract := NewLogoLiveContract()

	if err := contract.FileContract.Validate(); err != nil {
		t.Fatalf("file contract must validate: %v", err)
	}

	if !contract.FileContract.Declared {
		t.Fatal("file contract must be declared")
	}

	if contract.FileContract.RealFileDeliveryAllowed {
		t.Fatal("real file delivery must remain disabled")
	}

	if len(contract.FileContract.Formats) < 2 {
		t.Fatalf("expected at least 2 file formats, got %d", len(contract.FileContract.Formats))
	}

	if len(contract.FileContract.DeliveryChannels) < 3 {
		t.Fatalf("expected at least 3 delivery channels, got %d", len(contract.FileContract.DeliveryChannels))
	}

	t.Log("7-8L.2.9 file contract declared IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.2.10 real file delivery disabled IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.2.11 import package placeholders IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoLiveContractRejectsOpenProviderAPI(t *testing.T) {
	contract := NewLogoLiveContract()
	contract.RealProviderAPIStatus = "OPEN"

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real provider API is open")
	}

	t.Log("7-8L.2.12 open real provider API rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoLiveContractRejectsRealFileDelivery(t *testing.T) {
	contract := NewLogoLiveContract()
	contract.FileContract.RealFileDeliveryAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real file delivery is allowed")
	}

	t.Log("7-8L.2.13 real file delivery rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoLiveContractRejectsExternalOperation(t *testing.T) {
	contract := NewLogoLiveContract()
	contract.Operations[0].ExternalCallAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when external call is allowed")
	}

	t.Log("7-8L.2.14 external call guard IMPLEMENTED_OR_PRESENT / OK ✅")
}
