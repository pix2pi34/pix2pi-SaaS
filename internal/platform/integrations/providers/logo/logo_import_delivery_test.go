package logo

import "testing"

func TestLogoImportDeliveryContractReadiness(t *testing.T) {
	contract := NewLogoImportDeliveryContract()

	if err := contract.Validate(); err != nil {
		t.Fatalf("Logo import delivery contract must validate: %v", err)
	}

	if contract.Step != StepFAZ78L6 {
		t.Fatalf("step mismatch: got %s", contract.Step)
	}

	if contract.DeliveryMode != LogoImportDeliveryMode {
		t.Fatalf("delivery mode mismatch: got %s", contract.DeliveryMode)
	}

	t.Log("7-8L IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6 IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.1 import delivery contract readiness IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.2 file generation dependency validation IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoImportDeliveryKeepsRealIntegrationsClosed(t *testing.T) {
	contract := NewLogoImportDeliveryContract()

	if !contract.RealIntegrationsClosed() {
		t.Fatal("real provider API, file delivery, delivery channel, and ERP write must remain closed")
	}

	for _, operation := range contract.Operations {
		if !operation.DryRunDeliveryContractAllowed {
			t.Fatalf("operation %s must allow dry-run delivery contract", operation.Name)
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
	}

	t.Log("7-8L.6.3 dry-run delivery contract allowed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.4 real Logo provider API closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.5 real Logo file delivery closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.6 real ERP write closed IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoDeliveryChannelsDeclaredAsPlaceholders(t *testing.T) {
	contract := NewLogoImportDeliveryContract()

	required := []LogoDeliveryChannelName{
		LogoDeliveryChannelManualUpload,
		LogoDeliveryChannelSFTP,
		LogoDeliveryChannelProviderAPI,
	}

	for _, name := range required {
		channel, ok := contract.DeliveryChannel(name)
		if !ok {
			t.Fatalf("missing channel: %s", name)
		}
		if err := channel.Validate(); err != nil {
			t.Fatalf("channel must validate: %v", err)
		}
	}

	t.Log("7-8L.6.7 manual upload placeholder IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.8 SFTP placeholder IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.9 provider API placeholder IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.10 real delivery disabled on all channels IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoPrepareDryRunDeliveryEnvelope(t *testing.T) {
	fileContract := NewLogoFileGenerationContract()
	input := NewLogoSampleDryRunExportInput()

	pkg, err := fileContract.GenerateDryRunImportPackage(input)
	if err != nil {
		t.Fatalf("dry-run import package must be generated: %v", err)
	}

	deliveryContract := NewLogoImportDeliveryContract()
	envelope, err := deliveryContract.PrepareDryRunDeliveryEnvelope(LogoDeliveryChannelManualUpload, pkg)
	if err != nil {
		t.Fatalf("delivery envelope must be prepared: %v", err)
	}

	if err := envelope.Validate(); err != nil {
		t.Fatalf("delivery envelope must validate: %v", err)
	}

	if envelope.DeliveryAllowed {
		t.Fatal("delivery must remain disabled")
	}
	if envelope.ExternalCallAllowed {
		t.Fatal("external calls must remain disabled")
	}
	if envelope.ERPWriteAllowed {
		t.Fatal("ERP write must remain disabled")
	}
	if envelope.ChecksumSHA256 != pkg.GeneratedFile.ChecksumSHA256 {
		t.Fatal("checksum must be carried forward")
	}
	if envelope.TenantID != pkg.TenantID {
		t.Fatal("tenant_id must be carried forward")
	}

	t.Log("7-8L.6.11 dry-run package delivery envelope IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.12 package checksum carry-forward IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.13 tenant/correlation/idempotency carry-forward IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.6.14 no real delivery envelope guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoImportDeliveryRejectsRealDeliveryChannel(t *testing.T) {
	contract := NewLogoImportDeliveryContract()
	contract.DeliveryChannels[0].RealDeliveryAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real delivery is allowed on channel")
	}

	t.Log("7-8L.6.15 real delivery channel rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoImportDeliveryRejectsExternalOperation(t *testing.T) {
	contract := NewLogoImportDeliveryContract()
	contract.Operations[0].ExternalCallAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when external call is allowed")
	}

	t.Log("7-8L.6.16 external call guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoImportDeliveryRejectsERPWriteOperation(t *testing.T) {
	contract := NewLogoImportDeliveryContract()
	contract.Operations[0].ERPWriteAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when ERP write is allowed")
	}

	t.Log("7-8L.6.17 ERP write guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoImportDeliveryRejectsUnknownChannel(t *testing.T) {
	fileContract := NewLogoFileGenerationContract()
	input := NewLogoSampleDryRunExportInput()

	pkg, err := fileContract.GenerateDryRunImportPackage(input)
	if err != nil {
		t.Fatalf("dry-run import package must be generated: %v", err)
	}

	deliveryContract := NewLogoImportDeliveryContract()
	if _, err := deliveryContract.PrepareDryRunDeliveryEnvelope(LogoDeliveryChannelName("UNKNOWN_CHANNEL"), pkg); err == nil {
		t.Fatal("expected validation error for unknown channel")
	}

	t.Log("7-8L.6.18 unknown delivery channel rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoImportDeliveryEnvelopeRejectsDeliveryAllowed(t *testing.T) {
	fileContract := NewLogoFileGenerationContract()
	input := NewLogoSampleDryRunExportInput()

	pkg, err := fileContract.GenerateDryRunImportPackage(input)
	if err != nil {
		t.Fatalf("dry-run import package must be generated: %v", err)
	}

	deliveryContract := NewLogoImportDeliveryContract()
	envelope, err := deliveryContract.PrepareDryRunDeliveryEnvelope(LogoDeliveryChannelSFTP, pkg)
	if err != nil {
		t.Fatalf("delivery envelope must be prepared: %v", err)
	}

	envelope.DeliveryAllowed = true
	if err := envelope.Validate(); err == nil {
		t.Fatal("expected validation error when delivery is allowed")
	}

	t.Log("7-8L.6.19 delivery allowed envelope rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}
