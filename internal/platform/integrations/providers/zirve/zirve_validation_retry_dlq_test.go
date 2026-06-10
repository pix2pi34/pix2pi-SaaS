package zirve

import (
	"strings"
	"testing"
	"time"
)

func validZirveValidationRetryDLQDeliveryContract(t *testing.T) ZirveImportDeliveryContract {
	t.Helper()

	builder := NewZirveImportDeliveryContractBuilder(NewZirveProviderIdentity(time.Time{}))
	contract, err := builder.BuildDryRunImportDeliveryContract(validZirveImportDeliveryRequest(t))
	if err != nil {
		t.Fatalf("failed to build dry-run import delivery contract for validation test: %v", err)
	}

	return contract
}

func validZirveValidationRetryDLQRequest(t *testing.T) ZirveValidationRetryDLQRequest {
	t.Helper()

	contract := validZirveValidationRetryDLQDeliveryContract(t)

	return ZirveValidationRetryDLQRequest{
		TenantID:             "tenant_7",
		ExportRunID:          "zirve-export-run-001",
		DeliveryRunID:        "zirve-delivery-run-001",
		ValidationRunID:      "zirve-validation-run-001",
		CorrelationID:        "corr-zirve-001",
		RequestedBy:          "ops-admin",
		DeliveryContract:     contract,
		ObservedErrorCode:    ZirveErrNone,
		ObservedErrorMessage: "",
		Attempt:              1,
		MaxAttempts:          3,
		DryRun:               true,
		RequestedAt:          time.Date(2026, 5, 3, 15, 0, 0, 0, time.UTC),
	}
}

func TestZirveValidationRetryDLQPassDecision(t *testing.T) {
	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))

	decision, err := runtime.BuildDryRunValidationRetryDLQDecision(validZirveValidationRetryDLQRequest(t))
	if err != nil {
		t.Fatalf("expected validation decision to build, got error: %v", err)
	}

	if decision.ProviderID != "zirve" {
		t.Fatalf("unexpected provider id: %s", decision.ProviderID)
	}
	if decision.ModuleCode != "FAZ_7_8Z_4" {
		t.Fatalf("unexpected module code: %s", decision.ModuleCode)
	}
	if decision.Mode != "VALIDATION_RETRY_DLQ_DRY_RUN_ONLY" {
		t.Fatalf("unexpected mode: %s", decision.Mode)
	}
	if decision.Outcome != ZirveValidationOutcomePass {
		t.Fatalf("expected PASS outcome, got %s", decision.Outcome)
	}
	if len(decision.Issues) != 0 {
		t.Fatalf("expected no issues for pass decision, got %+v", decision.Issues)
	}
}

func TestZirveValidationRetryDLQRetryableTemporaryFailure(t *testing.T) {
	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveValidationRetryDLQRequest(t)
	request.ObservedErrorCode = ZirveErrProviderTemporary
	request.ObservedErrorMessage = "temporary provider failure"
	request.Attempt = 1
	request.MaxAttempts = 3

	decision, err := runtime.BuildDryRunValidationRetryDLQDecision(request)
	if err != nil {
		t.Fatalf("expected retryable validation decision, got error: %v", err)
	}

	if decision.Outcome != ZirveValidationOutcomeRetry {
		t.Fatalf("expected RETRY outcome, got %s", decision.Outcome)
	}
	if !decision.Retryable {
		t.Fatal("temporary provider failure must be retryable before max attempt")
	}
	if decision.SendToDLQ {
		t.Fatal("temporary provider failure must not go to DLQ before max attempt")
	}
}

func TestZirveValidationRetryDLQMaxAttemptGoesToDLQ(t *testing.T) {
	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveValidationRetryDLQRequest(t)
	request.ObservedErrorCode = ZirveErrProviderRateLimit
	request.ObservedErrorMessage = "rate limit"
	request.Attempt = 3
	request.MaxAttempts = 3

	decision, err := runtime.BuildDryRunValidationRetryDLQDecision(request)
	if err != nil {
		t.Fatalf("expected max attempt validation decision, got error: %v", err)
	}

	if decision.Outcome != ZirveValidationOutcomeDLQ {
		t.Fatalf("expected DLQ outcome after max attempt, got %s", decision.Outcome)
	}
	if !decision.SendToDLQ {
		t.Fatal("max attempt retryable failure must go to DLQ")
	}
}

func TestZirveValidationRetryDLQManualReviewForSchemaMismatch(t *testing.T) {
	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveValidationRetryDLQRequest(t)
	request.ObservedErrorCode = ZirveErrSchemaMismatch
	request.ObservedErrorMessage = "schema mismatch"

	decision, err := runtime.BuildDryRunValidationRetryDLQDecision(request)
	if err != nil {
		t.Fatalf("expected manual review validation decision, got error: %v", err)
	}

	if decision.Outcome != ZirveValidationOutcomeManualReview {
		t.Fatalf("expected MANUAL_REVIEW outcome, got %s", decision.Outcome)
	}
	if !decision.ManualReview {
		t.Fatal("schema mismatch must route to manual review")
	}
	if decision.Retryable {
		t.Fatal("schema mismatch must not be retryable")
	}
}

func TestZirveValidationRetryDLQDenyRealDeliveryAttempt(t *testing.T) {
	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveValidationRetryDLQRequest(t)
	request.ObservedErrorCode = ZirveErrRealDeliveryAttempted
	request.ObservedErrorMessage = "real external delivery attempted in dry-run phase"

	decision, err := runtime.BuildDryRunValidationRetryDLQDecision(request)
	if err != nil {
		t.Fatalf("expected deny decision, got error: %v", err)
	}

	if decision.Outcome != ZirveValidationOutcomeDeny {
		t.Fatalf("expected DENY outcome, got %s", decision.Outcome)
	}
	if !decision.SendToDLQ {
		t.Fatal("real delivery attempt must be DLQ-visible")
	}
	if !decision.ManualReview {
		t.Fatal("real delivery attempt must be manual-review visible")
	}
	if decision.RequiredAction != "deny_real_operation_and_escalate" {
		t.Fatalf("unexpected required action: %s", decision.RequiredAction)
	}
}

func TestZirveValidationRetryDLQKeepsRealBoundariesClosed(t *testing.T) {
	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))

	decision, err := runtime.BuildDryRunValidationRetryDLQDecision(validZirveValidationRetryDLQRequest(t))
	if err != nil {
		t.Fatalf("expected validation decision, got error: %v", err)
	}

	if decision.RealProviderAPIAllowed {
		t.Fatal("real provider API must remain closed")
	}
	if decision.RealFileDeliveryAllowed {
		t.Fatal("real file delivery must remain closed")
	}
	if decision.RealDeliveryChannelAllowed {
		t.Fatal("real delivery channel must remain closed")
	}
	if decision.RealERPWriteAllowed {
		t.Fatal("real ERP write must remain closed")
	}
	if decision.RealOperatorProviderActionAllowed {
		t.Fatal("real operator provider action must remain closed")
	}
}

func TestZirveValidationRetryDLQRejectsNonDryRun(t *testing.T) {
	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveValidationRetryDLQRequest(t)
	request.DryRun = false

	_, err := runtime.BuildDryRunValidationRetryDLQDecision(request)
	if err == nil {
		t.Fatal("expected non-dry-run validation request to be rejected")
	}
	if !strings.Contains(err.Error(), "dry-run only") {
		t.Fatalf("expected dry-run only error, got: %v", err)
	}
}

func TestZirveValidationRetryDLQRejectsInvalidContract(t *testing.T) {
	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))

	realFileDeliveryOpen := validZirveValidationRetryDLQRequest(t)
	realFileDeliveryOpen.DeliveryContract.RealFileDeliveryAllowed = true
	if _, err := runtime.BuildDryRunValidationRetryDLQDecision(realFileDeliveryOpen); err == nil {
		t.Fatal("expected contract with real file delivery allowed to be rejected")
	}

	wrongTenant := validZirveValidationRetryDLQRequest(t)
	wrongTenant.TenantID = "tenant_99"
	if _, err := runtime.BuildDryRunValidationRetryDLQDecision(wrongTenant); err == nil {
		t.Fatal("expected tenant mismatch to be rejected")
	}

	missingFingerprint := validZirveValidationRetryDLQRequest(t)
	missingFingerprint.DeliveryContract.PackageFingerprintSHA256 = ""
	if _, err := runtime.BuildDryRunValidationRetryDLQDecision(missingFingerprint); err == nil {
		t.Fatal("expected missing package fingerprint to be rejected")
	}
}

func TestZirveValidationRetryDLQRejectsAttemptGreaterThanMax(t *testing.T) {
	runtime := NewZirveValidationRetryDLQRuntime(NewZirveProviderIdentity(time.Time{}))
	request := validZirveValidationRetryDLQRequest(t)
	request.Attempt = 4
	request.MaxAttempts = 3

	_, err := runtime.BuildDryRunValidationRetryDLQDecision(request)
	if err == nil {
		t.Fatal("expected attempt greater than max attempts to be rejected")
	}
	if !strings.Contains(err.Error(), "attempt cannot be greater than max attempts") {
		t.Fatalf("unexpected error: %v", err)
	}
}
