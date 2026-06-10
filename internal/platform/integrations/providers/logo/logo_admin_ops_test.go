package logo

import "testing"

func buildLogoAdminOpsReviewItem(t *testing.T) LogoManualReviewItem {
	t.Helper()

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

	validationContract := NewLogoValidationRetryDLQContract()
	decision := validationContract.Decide(LogoErrorUnknownProvider, 0)

	item, err := NewLogoManualReviewItemFromDecision(envelope, decision, "ops-system")
	if err != nil {
		t.Fatalf("manual review item must be created from decision: %v", err)
	}

	return item
}

func TestLogoAdminOpsContractReadiness(t *testing.T) {
	contract := NewLogoAdminOpsContract()

	if err := contract.Validate(); err != nil {
		t.Fatalf("Logo admin ops contract must validate: %v", err)
	}

	if contract.Step != StepFAZ78L8 {
		t.Fatalf("step mismatch: got %s", contract.Step)
	}

	if contract.AdminOpsMode != LogoAdminOpsMode {
		t.Fatalf("admin ops mode mismatch: got %s", contract.AdminOpsMode)
	}

	t.Log("7-8L IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8 IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.1 admin ops contract readiness IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.2 validation retry-DLQ dependency validation IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoAdminOpsKeepsRealIntegrationsClosed(t *testing.T) {
	contract := NewLogoAdminOpsContract()

	if !contract.RealIntegrationsClosed() {
		t.Fatal("real provider API, file delivery, and ERP write must remain closed")
	}

	for _, operation := range contract.Operations {
		if !operation.DryRunAdminOpsAllowed {
			t.Fatalf("operation %s must allow dry-run admin ops", operation.Name)
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

	t.Log("7-8L.8.3 dry-run admin ops allowed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.4 real Logo provider API closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.5 real Logo file delivery closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.6 real ERP write closed IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoManualReviewItemCreation(t *testing.T) {
	item := buildLogoAdminOpsReviewItem(t)

	if err := item.Validate(); err != nil {
		t.Fatalf("manual review item must validate: %v", err)
	}

	if item.Status != LogoManualReviewStatusOpen {
		t.Fatalf("expected OPEN status, got %s", item.Status)
	}

	if item.Reason != LogoManualReviewReasonUnknownProviderError {
		t.Fatalf("expected unknown provider reason, got %s", item.Reason)
	}

	t.Log("7-8L.8.7 manual review item model IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.8 manual review OPEN status IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.9 ops audit fields IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoManualReviewTenantSafeListAndRead(t *testing.T) {
	runtime := NewLogoAdminOpsRuntime()
	item := buildLogoAdminOpsReviewItem(t)

	created, err := runtime.CreateManualReviewItem(item)
	if err != nil {
		t.Fatalf("manual review item must be created: %v", err)
	}

	items, err := runtime.ListManualReviews(created.TenantID)
	if err != nil {
		t.Fatalf("tenant-safe list must work: %v", err)
	}

	if len(items) != 1 {
		t.Fatalf("expected 1 item, got %d", len(items))
	}

	read, err := runtime.ReadManualReview(created.TenantID, created.ReviewID)
	if err != nil {
		t.Fatalf("tenant-safe read must work: %v", err)
	}

	if read.ReviewID != created.ReviewID {
		t.Fatal("read item mismatch")
	}

	t.Log("7-8L.8.10 manual review queue create IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.11 tenant-safe review list IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.12 tenant-safe review read IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoManualReviewAssignAndResolve(t *testing.T) {
	runtime := NewLogoAdminOpsRuntime()
	item := buildLogoAdminOpsReviewItem(t)

	created, err := runtime.CreateManualReviewItem(item)
	if err != nil {
		t.Fatalf("manual review item must be created: %v", err)
	}

	assigned, err := runtime.AssignManualReview(created.TenantID, created.ReviewID, "ops-user-1")
	if err != nil {
		t.Fatalf("manual review item must be assigned: %v", err)
	}

	if assigned.Status != LogoManualReviewStatusAssigned {
		t.Fatalf("expected ASSIGNED status, got %s", assigned.Status)
	}

	resolved, err := runtime.ResolveManualReview(created.TenantID, created.ReviewID, "ops-user-1", "dry-run review resolved")
	if err != nil {
		t.Fatalf("manual review item must be resolved: %v", err)
	}

	if resolved.Status != LogoManualReviewStatusResolved {
		t.Fatalf("expected RESOLVED status, got %s", resolved.Status)
	}

	t.Log("7-8L.8.13 assign manual review action IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.14 resolve manual review action IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.15 review state transition IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoManualReviewReject(t *testing.T) {
	runtime := NewLogoAdminOpsRuntime()
	item := buildLogoAdminOpsReviewItem(t)

	created, err := runtime.CreateManualReviewItem(item)
	if err != nil {
		t.Fatalf("manual review item must be created: %v", err)
	}

	rejected, err := runtime.RejectManualReview(created.TenantID, created.ReviewID, "ops-user-1", "dry-run review rejected")
	if err != nil {
		t.Fatalf("manual review item must be rejected: %v", err)
	}

	if rejected.Status != LogoManualReviewStatusRejected {
		t.Fatalf("expected REJECTED status, got %s", rejected.Status)
	}

	t.Log("7-8L.8.16 reject manual review action IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.8.17 REJECTED review status IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoManualReviewCrossTenantReadRejected(t *testing.T) {
	runtime := NewLogoAdminOpsRuntime()
	item := buildLogoAdminOpsReviewItem(t)

	created, err := runtime.CreateManualReviewItem(item)
	if err != nil {
		t.Fatalf("manual review item must be created: %v", err)
	}

	if _, err := runtime.ReadManualReview("tenant_99", created.ReviewID); err == nil {
		t.Fatal("expected cross-tenant read rejection")
	}

	t.Log("7-8L.8.18 cross-tenant review read rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoManualReviewInvalidTransitionRejected(t *testing.T) {
	runtime := NewLogoAdminOpsRuntime()
	item := buildLogoAdminOpsReviewItem(t)

	created, err := runtime.CreateManualReviewItem(item)
	if err != nil {
		t.Fatalf("manual review item must be created: %v", err)
	}

	if _, err := runtime.ResolveManualReview(created.TenantID, created.ReviewID, "ops-user-1", "invalid direct resolve"); err == nil {
		t.Fatal("expected direct resolve without assignment to fail")
	}

	t.Log("7-8L.8.19 invalid review transition rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoAdminOpsRejectsExternalOperation(t *testing.T) {
	contract := NewLogoAdminOpsContract()
	contract.Operations[0].ExternalCallAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when external call is allowed")
	}

	t.Log("7-8L.8.20 external call guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoAdminOpsRejectsRealFileDeliveryOperation(t *testing.T) {
	contract := NewLogoAdminOpsContract()
	contract.Operations[0].RealFileDeliveryAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real file delivery is allowed")
	}

	t.Log("7-8L.8.21 real file delivery guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoAdminOpsRejectsERPWriteOperation(t *testing.T) {
	contract := NewLogoAdminOpsContract()
	contract.Operations[0].ERPWriteAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when ERP write is allowed")
	}

	t.Log("7-8L.8.22 ERP write guard IMPLEMENTED_OR_PRESENT / OK ✅")
}
