package zirve

import (
	"strings"
	"testing"
	"time"
)

func validZirveImportDeliveryExportPackage(t *testing.T) ZirveExportPackage {
	t.Helper()

	builder := NewZirveExportPackageBuilder(NewZirveProviderIdentity(time.Time{}))
	pkg, err := builder.BuildDryRunExportPackage(validZirveDryRunExportPackageRequest())
	if err != nil {
		t.Fatalf("failed to build dry-run export package for import delivery test: %v", err)
	}

	return pkg
}

func validZirveImportDeliveryRequest(t *testing.T) ZirveImportDeliveryRequest {
	t.Helper()

	pkg := validZirveImportDeliveryExportPackage(t)

	return ZirveImportDeliveryRequest{
		TenantID:      "tenant_7",
		ExportRunID:   "zirve-export-run-001",
		DeliveryRunID: "zirve-delivery-run-001",
		CorrelationID: "corr-zirve-001",
		RequestedBy:   "ops-admin",
		Package:       pkg,
		Channel:       ZirveDeliveryChannelLocalPackage,
		DryRun:        true,
		RequestedAt:   time.Date(2026, 5, 3, 14, 0, 0, 0, time.UTC),
	}
}

func TestZirveImportDeliveryBuildsDryRunContract(t *testing.T) {
	builder := NewZirveImportDeliveryContractBuilder(NewZirveProviderIdentity(time.Time{}))

	contract, err := builder.BuildDryRunImportDeliveryContract(validZirveImportDeliveryRequest(t))
	if err != nil {
		t.Fatalf("expected import delivery contract to build, got error: %v", err)
	}

	if contract.ProviderID != "zirve" {
		t.Fatalf("unexpected provider id: %s", contract.ProviderID)
	}
	if contract.ModuleCode != "FAZ_7_8Z_3" {
		t.Fatalf("unexpected module code: %s", contract.ModuleCode)
	}
	if contract.ContractMode != "IMPORT_PACKAGE_DELIVERY_CONTRACT_DRY_RUN_ONLY" {
		t.Fatalf("unexpected contract mode: %s", contract.ContractMode)
	}
	if contract.ContractStatus != "READY_DRY_RUN_ONLY" {
		t.Fatalf("unexpected contract status: %s", contract.ContractStatus)
	}
	if contract.DeliveryChannel != ZirveDeliveryChannelLocalPackage {
		t.Fatalf("unexpected delivery channel: %s", contract.DeliveryChannel)
	}
	if contract.PackageArtifactCount != 4 {
		t.Fatalf("expected 4 package artifacts from 7-8Z.2 package, got %d", contract.PackageArtifactCount)
	}
	if len(contract.Artifacts) != 3 {
		t.Fatalf("expected 3 delivery contract artifacts, got %d", len(contract.Artifacts))
	}
	if len(contract.PackageFingerprintSHA256) != 64 {
		t.Fatalf("expected package fingerprint sha256 to be 64 chars, got %s", contract.PackageFingerprintSHA256)
	}
}

func TestZirveImportDeliveryKeepsRealBoundariesClosed(t *testing.T) {
	builder := NewZirveImportDeliveryContractBuilder(NewZirveProviderIdentity(time.Time{}))

	contract, err := builder.BuildDryRunImportDeliveryContract(validZirveImportDeliveryRequest(t))
	if err != nil {
		t.Fatalf("expected import delivery contract to build, got error: %v", err)
	}

	if contract.RealProviderAPIAllowed {
		t.Fatal("real provider API must remain closed")
	}
	if contract.RealFileDeliveryAllowed {
		t.Fatal("real file delivery must remain closed")
	}
	if contract.RealDeliveryChannelAllowed {
		t.Fatal("real delivery channel must remain closed")
	}
	if contract.RealERPWriteAllowed {
		t.Fatal("real ERP write must remain closed")
	}
	if contract.RealOperatorProviderActionAllowed {
		t.Fatal("real operator provider action must remain closed")
	}
	if contract.DryRunDeliveryPolicy != "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE" {
		t.Fatalf("unexpected dry-run delivery policy: %s", contract.DryRunDeliveryPolicy)
	}
}

func TestZirveImportDeliveryRejectsProviderLiveChannel(t *testing.T) {
	builder := NewZirveImportDeliveryContractBuilder(NewZirveProviderIdentity(time.Time{}))
	request := validZirveImportDeliveryRequest(t)
	request.Channel = ZirveDeliveryChannelProviderLiveModule

	_, err := builder.BuildDryRunImportDeliveryContract(request)
	if err == nil {
		t.Fatal("expected provider live delivery channel to be rejected")
	}
	if !strings.Contains(err.Error(), "LOCAL_PACKAGE_PLACEHOLDER") {
		t.Fatalf("expected local package placeholder error, got: %v", err)
	}
}

func TestZirveImportDeliveryRejectsNonDryRun(t *testing.T) {
	builder := NewZirveImportDeliveryContractBuilder(NewZirveProviderIdentity(time.Time{}))
	request := validZirveImportDeliveryRequest(t)
	request.DryRun = false

	_, err := builder.BuildDryRunImportDeliveryContract(request)
	if err == nil {
		t.Fatal("expected non-dry-run request to be rejected")
	}
	if !strings.Contains(err.Error(), "dry-run only") {
		t.Fatalf("expected dry-run only error, got: %v", err)
	}
}

func TestZirveImportDeliveryRejectsTenantMismatch(t *testing.T) {
	builder := NewZirveImportDeliveryContractBuilder(NewZirveProviderIdentity(time.Time{}))
	request := validZirveImportDeliveryRequest(t)
	request.TenantID = "tenant_99"

	_, err := builder.BuildDryRunImportDeliveryContract(request)
	if err == nil {
		t.Fatal("expected tenant mismatch to be rejected")
	}
	if !strings.Contains(err.Error(), "tenant id must match") {
		t.Fatalf("expected tenant mismatch error, got: %v", err)
	}
}

func TestZirveImportDeliveryRejectsInvalidPackage(t *testing.T) {
	builder := NewZirveImportDeliveryContractBuilder(NewZirveProviderIdentity(time.Time{}))

	missingArtifacts := validZirveImportDeliveryRequest(t)
	missingArtifacts.Package.Artifacts = nil
	if _, err := builder.BuildDryRunImportDeliveryContract(missingArtifacts); err == nil {
		t.Fatal("expected missing package artifacts to be rejected")
	}

	realDeliveryOpen := validZirveImportDeliveryRequest(t)
	realDeliveryOpen.Package.RealFileDeliveryAllowed = true
	if _, err := builder.BuildDryRunImportDeliveryContract(realDeliveryOpen); err == nil {
		t.Fatal("expected package with real file delivery allowed to be rejected")
	}

	wrongModule := validZirveImportDeliveryRequest(t)
	wrongModule.Package.ModuleCode = "WRONG_MODULE"
	if _, err := builder.BuildDryRunImportDeliveryContract(wrongModule); err == nil {
		t.Fatal("expected wrong package module code to be rejected")
	}
}

func TestZirveImportDeliveryArtifactsAreAuditable(t *testing.T) {
	builder := NewZirveImportDeliveryContractBuilder(NewZirveProviderIdentity(time.Time{}))

	contract, err := builder.BuildDryRunImportDeliveryContract(validZirveImportDeliveryRequest(t))
	if err != nil {
		t.Fatalf("expected import delivery contract to build, got error: %v", err)
	}

	artifactByPath := map[string]ZirveExportPackageArtifact{}
	for _, artifact := range contract.Artifacts {
		if artifact.RelativePath == "" {
			t.Fatal("delivery artifact relative path is required")
		}
		if artifact.MimeType != "application/json" {
			t.Fatalf("delivery artifact mime type must be application/json: %+v", artifact)
		}
		if artifact.SizeBytes <= 0 {
			t.Fatalf("delivery artifact size must be positive: %+v", artifact)
		}
		if len(artifact.SHA256) != 64 {
			t.Fatalf("delivery artifact sha256 must be 64 chars: %+v", artifact)
		}
		artifactByPath[artifact.RelativePath] = artifact
	}

	manifest := artifactByPath[ZirveDeliveryArtifactManifest]
	if !strings.Contains(manifest.Content, `"real_file_delivery": false`) {
		t.Fatal("delivery manifest must state real file delivery is false")
	}
	if !strings.Contains(manifest.Content, `"real_delivery_channel": false`) {
		t.Fatal("delivery manifest must state real delivery channel is false")
	}
	if !strings.Contains(manifest.Content, `"real_erp_write": false`) {
		t.Fatal("delivery manifest must state real ERP write is false")
	}

	handoff := artifactByPath[ZirveDeliveryArtifactHandoff]
	if !strings.Contains(handoff.Content, `"provider_live_module_status": "NOT_STARTED"`) {
		t.Fatal("handoff artifact must state provider live module not started")
	}

	audit := artifactByPath[ZirveDeliveryArtifactAuditDecision]
	if !strings.Contains(audit.Content, `"operation_code": "DRY_RUN_IMPORT_DELIVERY_CONTRACT"`) {
		t.Fatal("audit artifact must include operation code")
	}
	if !strings.Contains(audit.Content, `"external_delivery_attempted": false`) {
		t.Fatal("audit artifact must state external delivery was not attempted")
	}
}
