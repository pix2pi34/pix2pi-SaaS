package tenantdataexport

import "testing"

func TestTenantDataExportFlowPassesInternalReadiness(t *testing.T) {
	input := validFlowInput()

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

	if !report.InternalDataExportFlowReady {
		t.Fatal("internal data export flow readiness must be true")
	}

	if report.ProductionExportEnabled {
		t.Fatal("production export must remain disabled")
	}

	if report.RealCustomerExportEnabled {
		t.Fatal("real customer export must remain disabled")
	}

	if report.DataDeletionEnabled {
		t.Fatal("data deletion must remain disabled")
	}

	if report.AutoTransferEnabled {
		t.Fatal("auto transfer must remain disabled")
	}

	if err := MustPass(report); err != nil {
		t.Fatal(err)
	}
}

func TestTenantDataExportFlowBlocksProductionExport(t *testing.T) {
	input := validFlowInput()
	input.ProductionExportEnabled = true

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

func TestTenantDataExportFlowRequiresChecksumManifest(t *testing.T) {
	input := validFlowInput()
	input.Steps[0].RequiresChecksumManifest = false

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

func TestTenantDataExportFlowRequiresDeferredReason(t *testing.T) {
	input := validFlowInput()

	for idx := range input.Steps {
		if input.Steps[idx].DeferredToProductionApproval || input.Steps[idx].DeferredToTenantShutdown {
			input.Steps[idx].DeferredReason = ""
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

func TestRequiredStepKeysSorted(t *testing.T) {
	input := FlowInput{RequiredStepKeys: []string{"owner_verification", "export_request_intake"}}
	keys := RequiredStepKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}

	if keys[0] != "export_request_intake" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validFlowInput() FlowInput {
	return FlowInput{
		Phase:                       "FAZ_5_18_5_5",
		Target:                      "FAZ_5_R_TENANT_DATA_EXPORT_HANDOVER_FLOW",
		InternalDataExportFlowReady: true,
		ProductionExportEnabled:     false,
		RealCustomerExportEnabled:   false,
		DataDeletionEnabled:         false,
		AutoTransferEnabled:         false,
		RequiredStepKeys: []string{
			"export_request_intake",
			"owner_verification",
			"legal_hold_check",
			"data_scope_selection",
			"kvkk_masking_policy",
			"export_bundle_prepare",
			"checksum_manifest_create",
			"secure_download_package",
			"handover_acceptance_record",
			"data_deletion_deferred_marker",
		},
		RequiredEvents: []ExportEvent{
			EventExportRequestReceived,
			EventOwnerVerified,
			EventLegalHoldChecked,
			EventDataScopeSelected,
			EventKVKKMaskingApplied,
			EventExportBundlePrepared,
			EventChecksumManifestCreated,
			EventSecureDownloadReady,
			EventHandoverAcceptanceRecorded,
			EventDeletionDeferred,
		},
		RequireInternalReady:            true,
		RequireEvidence:                 true,
		RequireCounterBasedAudit:        true,
		RequireNoRequiredFail:           true,
		RequireNoOptionalWarn:           true,
		RequireTenantID:                 true,
		RequireExportRequestID:          true,
		RequireOwnerApproval:            true,
		RequireLegalHoldCheck:           true,
		RequireDataScope:                true,
		RequireKVKKMasking:              true,
		RequireDataClassification:       true,
		RequireFormatPolicy:             true,
		RequireChecksumManifest:         true,
		RequireEncryption:               true,
		RequireSecureDownload:           true,
		RequireAuditTrail:               true,
		RequireRetentionPolicy:          true,
		RequireHandoverAcceptance:       true,
		RequireSupportHandoff:           true,
		RequireProductionExportBlock:    true,
		RequireRealCustomerExportBlock:  true,
		RequireDataDeletionBlock:        true,
		RequireAutoTransferBlock:        true,
		AllowProductionApprovalDeferred: true,
		AllowTenantShutdownDeferred:     true,
		Steps: []ExportStep{
			step("export_request_intake", EventExportRequestReceived, "Export Request Intake"),
			step("owner_verification", EventOwnerVerified, "Owner Verification"),
			step("legal_hold_check", EventLegalHoldChecked, "Legal Hold Check"),
			step("data_scope_selection", EventDataScopeSelected, "Data Scope Selection"),
			step("kvkk_masking_policy", EventKVKKMaskingApplied, "KVKK Masking Policy"),
			step("export_bundle_prepare", EventExportBundlePrepared, "Export Bundle Prepare"),
			step("checksum_manifest_create", EventChecksumManifestCreated, "Checksum Manifest Create"),
			step("secure_download_package", EventSecureDownloadReady, "Secure Download Package"),
			step("handover_acceptance_record", EventHandoverAcceptanceRecorded, "Handover Acceptance Record"),
			deferred("data_deletion_deferred_marker", EventDeletionDeferred, "Data Deletion Deferred Marker"),
		},
	}
}

func step(key string, event ExportEvent, title string) ExportStep {
	return ExportStep{
		Key:                          key,
		Event:                        event,
		Title:                        title,
		Owner:                        "tenant_lifecycle_ops",
		Status:                       StatusReady,
		Required:                     true,
		InternalReady:                true,
		HasEvidence:                  true,
		HasCounterBasedAudit:         true,
		RequiredFailCount:            0,
		OptionalWarnCount:            0,
		ProductionExportEnabled:      false,
		RealCustomerExportEnabled:    false,
		DataDeletionEnabled:          false,
		AutoTransferEnabled:          false,
		RequiresTenantID:             true,
		RequiresExportRequestID:      true,
		RequiresOwnerApproval:        true,
		RequiresLegalHoldCheck:       true,
		RequiresDataScope:            true,
		RequiresKVKKMasking:          true,
		RequiresDataClassification:   true,
		RequiresFormatPolicy:         true,
		RequiresChecksumManifest:     true,
		RequiresEncryption:           true,
		RequiresSecureDownload:       true,
		RequiresAuditTrail:           true,
		RequiresRetentionPolicy:      true,
		RequiresHandoverAcceptance:   true,
		RequiresSupportHandoff:       true,
		BlocksProductionExport:       true,
		BlocksRealCustomerExport:     true,
		BlocksDataDeletion:           true,
		BlocksAutoTransfer:           true,
		DeferredToProductionApproval: false,
		DeferredToTenantShutdown:     false,
	}
}

func deferred(key string, event ExportEvent, title string) ExportStep {
	s := step(key, event, title)
	s.Status = StatusPendingNext
	s.InternalReady = false
	s.DeferredToProductionApproval = true
	s.DeferredToTenantShutdown = true
	s.DeferredReason = "Gerçek veri silme/devir kapanışı production approval ve tenant kapatma final gate sonrası açılacak"
	return s
}
