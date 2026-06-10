package zirve

import (
	"strings"
	"testing"
	"time"
)

func validZirveE2EDryRunRequest() ZirveE2EDryRunRequest {
	return ZirveE2EDryRunRequest{
		TenantID:             "tenant_7",
		ExportRunID:          "zirve-e2e-export-001",
		DeliveryRunID:        "zirve-e2e-delivery-001",
		ValidationRunID:      "zirve-e2e-validation-001",
		ReviewID:             "zirve-e2e-review-001",
		CorrelationID:        "corr-zirve-e2e-001",
		RequestedBy:          "ops-admin",
		ObservedErrorCode:    ZirveErrSchemaMismatch,
		ObservedErrorMessage: "schema mismatch requires review",
		Attempt:              1,
		MaxAttempts:          3,
		DryRun:               true,
		RequestedAt:          time.Date(2026, 5, 3, 17, 0, 0, 0, time.UTC),
		Objects: []ZirveExportObject{
			{
				ObjectKey:   "customer-e2e-001",
				ObjectType:  ZirveObjectCustomer,
				Operation:   ZirveExportUpsert,
				PayloadHash: "sha256-customer-e2e-001",
			},
			{
				ObjectKey:   "invoice-e2e-001",
				ObjectType:  ZirveObjectInvoice,
				Operation:   ZirveExportUpsert,
				PayloadHash: "sha256-invoice-e2e-001",
			},
		},
	}
}

func TestZirveE2EDryRunManualReviewFlow(t *testing.T) {
	runtime := NewZirveE2EDryRunRuntime(NewZirveProviderIdentity(time.Time{}))

	result, err := runtime.RunDryRunFlow(validZirveE2EDryRunRequest())
	if err != nil {
		t.Fatalf("expected E2E dry-run flow to pass, got error: %v", err)
	}

	if result.ProviderID != "zirve" {
		t.Fatalf("unexpected provider id: %s", result.ProviderID)
	}
	if result.ModuleCode != "FAZ_7_8Z_6" {
		t.Fatalf("unexpected module code: %s", result.ModuleCode)
	}
	if result.Mode != "E2E_DRY_RUN_FLOW_ONLY" {
		t.Fatalf("unexpected mode: %s", result.Mode)
	}
	if result.Status != "READY_DRY_RUN_ONLY" {
		t.Fatalf("unexpected status: %s", result.Status)
	}
	if result.ExportPackage.ModuleCode != ZirveFileGenerationModuleCode {
		t.Fatalf("expected file generation module code, got %s", result.ExportPackage.ModuleCode)
	}
	if result.ImportDeliveryContract.ModuleCode != ZirveImportDeliveryModuleCode {
		t.Fatalf("expected import delivery module code, got %s", result.ImportDeliveryContract.ModuleCode)
	}
	if result.ValidationDecision.ModuleCode != ZirveValidationRetryDLQModuleCode {
		t.Fatalf("expected validation module code, got %s", result.ValidationDecision.ModuleCode)
	}
	if !result.ManualReviewOpened {
		t.Fatal("schema mismatch E2E flow must open manual review")
	}
	if result.ManualReviewItem.ModuleCode != ZirveAdminOpsModuleCode {
		t.Fatalf("expected admin ops module code, got %s", result.ManualReviewItem.ModuleCode)
	}
	if result.FinalOutcome != ZirveValidationOutcomeManualReview {
		t.Fatalf("expected MANUAL_REVIEW final outcome, got %s", result.FinalOutcome)
	}
	if len(result.Steps) != 6 {
		t.Fatalf("expected 6 E2E steps, got %d", len(result.Steps))
	}
}

func TestZirveE2EDryRunPassFlowSkipsManualReview(t *testing.T) {
	runtime := NewZirveE2EDryRunRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveE2EDryRunRequest()
	request.ObservedErrorCode = ZirveErrNone
	request.ObservedErrorMessage = ""
	request.ReviewID = "zirve-e2e-review-pass-001"

	result, err := runtime.RunDryRunFlow(request)
	if err != nil {
		t.Fatalf("expected PASS E2E flow to pass, got error: %v", err)
	}

	if result.FinalOutcome != ZirveValidationOutcomePass {
		t.Fatalf("expected PASS final outcome, got %s", result.FinalOutcome)
	}
	if result.ManualReviewOpened {
		t.Fatal("PASS flow must not open manual review")
	}

	lastAdminStepFound := false
	for _, step := range result.Steps {
		if step.StepCode == "7-8Z.6.5" {
			lastAdminStepFound = true
			if step.Status != ZirveE2EStepSkipped {
				t.Fatalf("expected admin step to be SKIPPED for PASS flow, got %s", step.Status)
			}
		}
	}
	if !lastAdminStepFound {
		t.Fatal("expected admin step evidence in PASS flow")
	}
}

func TestZirveE2EDryRunDLQFlowOpensManualReview(t *testing.T) {
	runtime := NewZirveE2EDryRunRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveE2EDryRunRequest()
	request.ObservedErrorCode = ZirveErrProviderRateLimit
	request.ObservedErrorMessage = "rate limit exhausted"
	request.Attempt = 3
	request.MaxAttempts = 3
	request.ReviewID = "zirve-e2e-review-dlq-001"

	result, err := runtime.RunDryRunFlow(request)
	if err != nil {
		t.Fatalf("expected DLQ E2E flow to pass, got error: %v", err)
	}

	if result.FinalOutcome != ZirveValidationOutcomeDLQ {
		t.Fatalf("expected DLQ final outcome, got %s", result.FinalOutcome)
	}
	if !result.ManualReviewOpened {
		t.Fatal("DLQ flow must open manual review")
	}
	if result.ManualReviewItem.Priority != ZirveManualReviewPriorityHigh {
		t.Fatalf("expected HIGH priority for DLQ review, got %s", result.ManualReviewItem.Priority)
	}
}

func TestZirveE2EDryRunDenyFlowOpensCriticalManualReview(t *testing.T) {
	runtime := NewZirveE2EDryRunRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveE2EDryRunRequest()
	request.ObservedErrorCode = ZirveErrRealDeliveryAttempted
	request.ObservedErrorMessage = "real delivery attempted"
	request.ReviewID = "zirve-e2e-review-deny-001"

	result, err := runtime.RunDryRunFlow(request)
	if err != nil {
		t.Fatalf("expected DENY E2E flow to pass, got error: %v", err)
	}

	if result.FinalOutcome != ZirveValidationOutcomeDeny {
		t.Fatalf("expected DENY final outcome, got %s", result.FinalOutcome)
	}
	if !result.ManualReviewOpened {
		t.Fatal("DENY flow must open manual review")
	}
	if result.ManualReviewItem.Priority != ZirveManualReviewPriorityCritical {
		t.Fatalf("expected CRITICAL priority for DENY review, got %s", result.ManualReviewItem.Priority)
	}
}

func TestZirveE2EDryRunKeepsRealBoundariesClosed(t *testing.T) {
	runtime := NewZirveE2EDryRunRuntime(NewZirveProviderIdentity(time.Time{}))

	result, err := runtime.RunDryRunFlow(validZirveE2EDryRunRequest())
	if err != nil {
		t.Fatalf("expected E2E dry-run flow to pass, got error: %v", err)
	}

	if result.RealProviderAPIAllowed {
		t.Fatal("real provider API must remain closed")
	}
	if result.RealFileDeliveryAllowed {
		t.Fatal("real file delivery must remain closed")
	}
	if result.RealDeliveryChannelAllowed {
		t.Fatal("real delivery channel must remain closed")
	}
	if result.RealERPWriteAllowed {
		t.Fatal("real ERP write must remain closed")
	}
	if result.RealOperatorProviderActionAllowed {
		t.Fatal("real operator provider action must remain closed")
	}
	if result.ExportPackage.RealFileDeliveryAllowed {
		t.Fatal("export package real file delivery must remain closed")
	}
	if result.ImportDeliveryContract.RealDeliveryChannelAllowed {
		t.Fatal("import delivery real delivery channel must remain closed")
	}
	if result.ValidationDecision.RealERPWriteAllowed {
		t.Fatal("validation decision real ERP write must remain closed")
	}
	if result.ManualReviewItem.RealOperatorProviderActionAllowed {
		t.Fatal("manual review real operator provider action must remain closed")
	}
}

func TestZirveE2EDryRunRejectsNonDryRun(t *testing.T) {
	runtime := NewZirveE2EDryRunRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveE2EDryRunRequest()
	request.DryRun = false

	_, err := runtime.RunDryRunFlow(request)
	if err == nil {
		t.Fatal("expected non-dry-run E2E request to be rejected")
	}
	if !strings.Contains(err.Error(), "dry-run only") {
		t.Fatalf("expected dry-run only error, got: %v", err)
	}
}

func TestZirveE2EDryRunRequiresObjects(t *testing.T) {
	runtime := NewZirveE2EDryRunRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveE2EDryRunRequest()
	request.Objects = nil

	_, err := runtime.RunDryRunFlow(request)
	if err == nil {
		t.Fatal("expected missing objects to be rejected")
	}
	if !strings.Contains(err.Error(), "at least one export object") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestZirveE2EDryRunRejectsAttemptGreaterThanMax(t *testing.T) {
	runtime := NewZirveE2EDryRunRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveE2EDryRunRequest()
	request.Attempt = 4
	request.MaxAttempts = 3

	_, err := runtime.RunDryRunFlow(request)
	if err == nil {
		t.Fatal("expected attempt greater than max to be rejected")
	}
	if !strings.Contains(err.Error(), "attempt cannot be greater than max attempts") {
		t.Fatalf("unexpected error: %v", err)
	}
}
