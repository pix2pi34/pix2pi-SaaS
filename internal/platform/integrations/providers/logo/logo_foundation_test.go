package logo

import "testing"

func TestLogoProviderIdentityFoundation(t *testing.T) {
	identity := NewProviderIdentity()

	if err := identity.Validate(); err != nil {
		t.Fatalf("Logo provider identity must validate: %v", err)
	}

	if identity.ProviderCode != ProviderCode {
		t.Fatalf("provider code mismatch: got %s", identity.ProviderCode)
	}

	if identity.ConnectorCode != ConnectorCode {
		t.Fatalf("connector code mismatch: got %s", identity.ConnectorCode)
	}

	t.Log("7-8L IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.1 IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.1.1 provider identity IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.1.2 connector identity IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.1.3 provider directory standard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoRealIntegrationsRemainClosed(t *testing.T) {
	identity := NewProviderIdentity()

	if !identity.RealIntegrationsClosed() {
		t.Fatal("real Logo provider API, real file delivery, and real ERP write must remain closed")
	}

	for _, operation := range identity.Operations {
		if operation.ExternalCallAllowed {
			t.Fatalf("operation %s must not allow external calls", operation.Name)
		}
		if operation.ERPWriteAllowed {
			t.Fatalf("operation %s must not allow ERP writes", operation.Name)
		}
	}

	t.Log("7-8L.1.4 dry-run mode IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.1.5 real Logo provider API closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.1.6 real Logo file delivery closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.1.7 real ERP write closed IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoCapabilitiesAndOperations(t *testing.T) {
	identity := NewProviderIdentity()

	requiredCapabilities := []Capability{
		CapabilityExportMappingContract,
		CapabilityFileGenerationDryRun,
		CapabilityImportPackagePreparation,
		CapabilityValidationErrorMapping,
		CapabilityRetryDLQReadiness,
		CapabilityAdminOpsManualReview,
		CapabilityE2EDryRunFlow,
		CapabilityProviderLiveHandoffGate,
	}

	for _, capability := range requiredCapabilities {
		if !identity.HasCapability(capability) {
			t.Fatalf("missing capability: %s", capability)
		}
	}

	requiredOperations := []OperationName{
		OperationBuildExportModel,
		OperationGenerateLogoDryRunFile,
		OperationPrepareImportPackage,
		OperationValidateImportPackage,
		OperationMapLogoError,
		OperationCreateManualReviewItem,
		OperationRunE2EDryRun,
		OperationPrepareProviderLiveGate,
	}

	for _, operationName := range requiredOperations {
		operation, ok := identity.Operation(operationName)
		if !ok {
			t.Fatalf("missing operation: %s", operationName)
		}
		if operation.Mode != OperationModeDryRunOnly {
			t.Fatalf("operation %s must be dry-run only", operationName)
		}
	}

	if got := len(identity.DryRunOperationNames()); got != len(requiredOperations) {
		t.Fatalf("dry-run operation count mismatch: got %d want %d", got, len(requiredOperations))
	}

	t.Log("7-8L.1.8 capability set IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.1.9 dry-run operation set IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoProviderIdentityRejectsOpenRealProviderAPI(t *testing.T) {
	identity := NewProviderIdentity()
	identity.RealProviderAPIStatus = "OPEN"

	if err := identity.Validate(); err == nil {
		t.Fatal("expected validation error when real provider API is open")
	}

	t.Log("7-8L.1.10 open real provider API rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoProviderIdentityRejectsExternalOperation(t *testing.T) {
	identity := NewProviderIdentity()
	identity.Operations[0].ExternalCallAllowed = true

	if err := identity.Validate(); err == nil {
		t.Fatal("expected validation error when dry-run operation allows external call")
	}

	t.Log("7-8L.1.11 external call guard IMPLEMENTED_OR_PRESENT / OK ✅")
}
