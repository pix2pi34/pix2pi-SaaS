package zirve

import (
	"strings"
	"testing"
	"time"
)

func validZirveDryRunExportPackageRequest() ZirveExportPackageRequest {
	return ZirveExportPackageRequest{
		TenantID:      "tenant_7",
		ExportRunID:   "zirve-export-run-001",
		CorrelationID: "corr-zirve-001",
		RequestedBy:   "ops-admin",
		Direction:     DirectionPix2piToZirve,
		DeliveryMode:  DeliveryModeFilePackageDryRun,
		DryRun:        true,
		RequestedAt:   time.Date(2026, 5, 3, 13, 0, 0, 0, time.UTC),
		Objects: []ZirveExportObject{
			{
				ObjectKey:   "invoice-001",
				ObjectType:  ZirveObjectInvoice,
				Operation:   ZirveExportUpsert,
				PayloadHash: "sha256-invoice-001",
			},
			{
				ObjectKey:   "customer-001",
				ObjectType:  ZirveObjectCustomer,
				Operation:   ZirveExportUpsert,
				PayloadHash: "sha256-customer-001",
			},
		},
	}
}

func TestZirveFileGenerationBuildsDryRunPackage(t *testing.T) {
	builder := NewZirveExportPackageBuilder(NewZirveProviderIdentity(time.Time{}))

	pkg, err := builder.BuildDryRunExportPackage(validZirveDryRunExportPackageRequest())
	if err != nil {
		t.Fatalf("expected dry-run package to build, got error: %v", err)
	}

	if pkg.ProviderID != "zirve" {
		t.Fatalf("unexpected provider id: %s", pkg.ProviderID)
	}
	if pkg.ModuleCode != "FAZ_7_8Z_2" {
		t.Fatalf("unexpected module code: %s", pkg.ModuleCode)
	}
	if pkg.FileGenerationMode != "EXPORT_PACKAGE_BUILDER_DRY_RUN_ONLY" {
		t.Fatalf("unexpected file generation mode: %s", pkg.FileGenerationMode)
	}
	if pkg.TargetSystem != "ZIRVE_ACCOUNTING_IMPORT_DRY_RUN" {
		t.Fatalf("unexpected target system: %s", pkg.TargetSystem)
	}
	if !pkg.DryRun {
		t.Fatal("package must be dry-run")
	}
	if len(pkg.Artifacts) != 4 {
		t.Fatalf("expected 4 dry-run artifacts, got %d", len(pkg.Artifacts))
	}
}

func TestZirveFileGenerationKeepsRealBoundariesClosed(t *testing.T) {
	builder := NewZirveExportPackageBuilder(NewZirveProviderIdentity(time.Time{}))

	pkg, err := builder.BuildDryRunExportPackage(validZirveDryRunExportPackageRequest())
	if err != nil {
		t.Fatalf("expected dry-run package to build, got error: %v", err)
	}

	if pkg.RealFileDeliveryAllowed {
		t.Fatal("real file delivery must remain closed")
	}
	if pkg.RealDeliveryChannelAllowed {
		t.Fatal("real delivery channel must remain closed")
	}
	if pkg.RealERPWriteAllowed {
		t.Fatal("real ERP write must remain closed")
	}
	if pkg.RealOperatorProviderActionAllowed {
		t.Fatal("real operator provider action must remain closed")
	}
	if pkg.DryRunDeliveryPolicy != "NO_EXTERNAL_DELIVERY_IN_THIS_PHASE" {
		t.Fatalf("unexpected dry-run delivery policy: %s", pkg.DryRunDeliveryPolicy)
	}
}

func TestZirveFileGenerationRejectsRealDeliveryMode(t *testing.T) {
	builder := NewZirveExportPackageBuilder(NewZirveProviderIdentity(time.Time{}))
	request := validZirveDryRunExportPackageRequest()
	request.DeliveryMode = DeliveryModeProviderLiveOnly

	_, err := builder.BuildDryRunExportPackage(request)
	if err == nil {
		t.Fatal("expected provider live delivery mode to be rejected")
	}
	if !strings.Contains(err.Error(), "FILE_PACKAGE_DRY_RUN") {
		t.Fatalf("expected dry-run delivery mode error, got: %v", err)
	}
}

func TestZirveFileGenerationRejectsNonDryRun(t *testing.T) {
	builder := NewZirveExportPackageBuilder(NewZirveProviderIdentity(time.Time{}))
	request := validZirveDryRunExportPackageRequest()
	request.DryRun = false

	_, err := builder.BuildDryRunExportPackage(request)
	if err == nil {
		t.Fatal("expected non-dry-run request to be rejected")
	}
	if !strings.Contains(err.Error(), "dry-run only") {
		t.Fatalf("expected dry-run only error, got: %v", err)
	}
}

func TestZirveFileGenerationRequiresTenantCorrelationAndObjects(t *testing.T) {
	builder := NewZirveExportPackageBuilder(NewZirveProviderIdentity(time.Time{}))

	missingTenant := validZirveDryRunExportPackageRequest()
	missingTenant.TenantID = ""
	if _, err := builder.BuildDryRunExportPackage(missingTenant); err == nil {
		t.Fatal("expected missing tenant id to be rejected")
	}

	missingCorrelation := validZirveDryRunExportPackageRequest()
	missingCorrelation.CorrelationID = ""
	if _, err := builder.BuildDryRunExportPackage(missingCorrelation); err == nil {
		t.Fatal("expected missing correlation id to be rejected")
	}

	missingObjects := validZirveDryRunExportPackageRequest()
	missingObjects.Objects = nil
	if _, err := builder.BuildDryRunExportPackage(missingObjects); err == nil {
		t.Fatal("expected missing objects to be rejected")
	}
}

func TestZirveFileGenerationArtifactsAreAuditable(t *testing.T) {
	builder := NewZirveExportPackageBuilder(NewZirveProviderIdentity(time.Time{}))

	pkg, err := builder.BuildDryRunExportPackage(validZirveDryRunExportPackageRequest())
	if err != nil {
		t.Fatalf("expected dry-run package to build, got error: %v", err)
	}

	artifactByPath := map[string]ZirveExportPackageArtifact{}
	for _, artifact := range pkg.Artifacts {
		if artifact.RelativePath == "" {
			t.Fatal("artifact relative path is required")
		}
		if artifact.MimeType == "" {
			t.Fatal("artifact mime type is required")
		}
		if artifact.SizeBytes <= 0 {
			t.Fatalf("artifact size must be positive: %+v", artifact)
		}
		if len(artifact.SHA256) != 64 {
			t.Fatalf("artifact sha256 must be 64 hex chars: %+v", artifact)
		}
		artifactByPath[artifact.RelativePath] = artifact
	}

	manifest := artifactByPath[ZirveArtifactManifest]
	if !strings.Contains(manifest.Content, `"real_file_delivery": false`) {
		t.Fatal("manifest must state real file delivery is false")
	}
	if !strings.Contains(manifest.Content, `"real_erp_write": false`) {
		t.Fatal("manifest must state real ERP write is false")
	}

	objects := artifactByPath[ZirveArtifactObjectsNDJSON]
	if !strings.Contains(objects.Content, `"tenant_id":"tenant_7"`) {
		t.Fatal("objects artifact must include tenant id")
	}
	if !strings.Contains(objects.Content, `"dry_run":true`) {
		t.Fatal("objects artifact must mark dry-run")
	}

	audit := artifactByPath[ZirveArtifactAuditJSON]
	if !strings.Contains(audit.Content, `"operation_code": "DRY_RUN_EXPORT_PACKAGE_BUILD"`) {
		t.Fatal("audit artifact must include operation code")
	}
}
