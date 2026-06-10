package logo

import (
	"strings"
	"testing"
)

func TestLogoFileGenerationDryRunReadiness(t *testing.T) {
	contract := NewLogoFileGenerationContract()

	if err := contract.Validate(); err != nil {
		t.Fatalf("Logo file generation dry-run contract must validate: %v", err)
	}

	if contract.Step != StepFAZ78L5 {
		t.Fatalf("step mismatch: got %s", contract.Step)
	}

	if contract.FileGenerationMode != LogoFileGenerationMode {
		t.Fatalf("file generation mode mismatch: got %s", contract.FileGenerationMode)
	}

	t.Log("7-8L IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.5 IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.5.1 file generation dry-run readiness IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.5.2 export mapping dependency validation IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFileGenerationKeepsRealIntegrationsClosed(t *testing.T) {
	contract := NewLogoFileGenerationContract()

	if !contract.RealIntegrationsClosed() {
		t.Fatal("real provider API, file delivery, and ERP write must remain closed")
	}

	for _, operation := range contract.Operations {
		if !operation.DryRunFileGenerationAllowed {
			t.Fatalf("operation %s must allow dry-run file generation", operation.Name)
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

	t.Log("7-8L.5.3 dry-run file generation allowed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.5.4 real Logo provider API closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.5.5 real Logo file delivery closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.5.6 real ERP write closed IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoGenerateDryRunImportPackage(t *testing.T) {
	contract := NewLogoFileGenerationContract()
	input := NewLogoSampleDryRunExportInput()

	pkg, err := contract.GenerateDryRunImportPackage(input)
	if err != nil {
		t.Fatalf("dry-run import package must be generated: %v", err)
	}

	if err := pkg.Validate(); err != nil {
		t.Fatalf("generated package must validate: %v", err)
	}

	if !strings.Contains(pkg.GeneratedFile.Content, "HEADER|tenant_7|") {
		t.Fatal("generated content must include HEADER line")
	}
	if !strings.Contains(pkg.GeneratedFile.Content, "LINE|120|") {
		t.Fatal("generated content must include LINE rows")
	}
	if !strings.Contains(pkg.GeneratedFile.Content, "PARTY|") {
		t.Fatal("generated content must include PARTY row")
	}
	if !strings.Contains(pkg.GeneratedFile.Content, "TAX|") {
		t.Fatal("generated content must include TAX row")
	}
	if !strings.Contains(pkg.GeneratedFile.Content, "INVOICE|") {
		t.Fatal("generated content must include INVOICE row")
	}
	if !strings.Contains(pkg.GeneratedFile.Content, "MANIFEST|DRY_RUN_ONLY|NO_REAL_DELIVERY|NO_ERP_WRITE") {
		t.Fatal("generated content must include MANIFEST guard")
	}
	if pkg.GeneratedFile.ChecksumSHA256 == "" {
		t.Fatal("checksum must exist")
	}
	if pkg.GeneratedFile.DeliveryAllowed {
		t.Fatal("delivery must remain disabled")
	}

	t.Log("7-8L.5.7 dry-run export input IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.5.8 dry-run file content generation IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.5.9 checksum calculation IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.5.10 dry-run import package manifest IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.5.11 no real delivery package guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFileGenerationRejectsMissingTenant(t *testing.T) {
	contract := NewLogoFileGenerationContract()
	input := NewLogoSampleDryRunExportInput()
	input.Header.TenantID = ""

	if _, err := contract.GenerateDryRunImportPackage(input); err == nil {
		t.Fatal("expected validation error when tenant_id is missing")
	}

	t.Log("7-8L.5.12 missing tenant rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFileGenerationRejectsMissingJournalLines(t *testing.T) {
	contract := NewLogoFileGenerationContract()
	input := NewLogoSampleDryRunExportInput()
	input.Lines = nil

	if _, err := contract.GenerateDryRunImportPackage(input); err == nil {
		t.Fatal("expected validation error when journal lines are missing")
	}

	t.Log("7-8L.5.13 missing journal lines rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFileGenerationRejectsRealDeliveryOperation(t *testing.T) {
	contract := NewLogoFileGenerationContract()
	contract.Operations[0].RealFileDeliveryAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real file delivery is allowed")
	}

	t.Log("7-8L.5.14 real file delivery guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFileGenerationRejectsExternalOperation(t *testing.T) {
	contract := NewLogoFileGenerationContract()
	contract.Operations[0].ExternalCallAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when external call is allowed")
	}

	t.Log("7-8L.5.15 external call guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoFileGenerationRejectsERPWriteOperation(t *testing.T) {
	contract := NewLogoFileGenerationContract()
	contract.Operations[0].ERPWriteAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when ERP write is allowed")
	}

	t.Log("7-8L.5.16 ERP write guard IMPLEMENTED_OR_PRESENT / OK ✅")
}
