package errorretry

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		MaxRetryCount:        3,
		BaseRetryDelaySec:    60,
		MaxRetryDelaySec:     600,
		DLQEnabled:           true,
		ManualReviewEnabled:  true,
		CancelReasonRequired: true,
		AllowedDocumentTypes: []DocumentType{
			DocumentTypeEFatura,
			DocumentTypeEArsiv,
			DocumentTypeEAdisyon,
		},
		AllowedProviderCodes: []string{
			"SIM_GIB_EFATURA",
			"SIM_GIB_EARSIV",
			"SIM_GIB_EADISYON",
		},
		RetryableErrorCodes: []string{
			"PROVIDER_TIMEOUT",
			"PROVIDER_RATE_LIMITED",
			"PROVIDER_TEMPORARY_UNAVAILABLE",
		},
		FatalErrorCodes: []string{
			"INVALID_TAX_IDENTITY",
			"INVALID_UBL",
			"DOCUMENT_SCHEMA_INVALID",
		},
		ManualReviewCodes: []string{
			"PROVIDER_STATE_CONFLICT",
			"LEGAL_STATUS_UNKNOWN",
		},
	}
}

func validErrorEvent() ErrorEvent {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return ErrorEvent{
		TenantID:            "tenant-001",
		CorrelationID:       "corr-001",
		RequestID:           "req-001",
		IdempotencyKey:      "idem-001",
		DocumentID:          "doc-001",
		DocumentNo:          "EF2026000000001",
		DocumentType:        DocumentTypeEFatura,
		ProviderCode:        "SIM_GIB_EFATURA",
		ProviderDocumentID:  "provider-doc-001",
		Operation:           OperationSend,
		ProviderErrorCode:   "PROVIDER_TIMEOUT",
		ProviderErrorText:   "timeout",
		ProviderPayloadHash: "sha256:payload",
		RetryCount:          0,
		OccurredAt:          now,
		ReceivedAt:          now.Add(time.Second),
	}
}

func validCancelRequest() CancelRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return CancelRequest{
		TenantID:           "tenant-001",
		CorrelationID:      "corr-001",
		RequestID:          "req-001",
		IdempotencyKey:     "idem-cancel-001",
		DocumentID:         "doc-001",
		DocumentNo:         "EF2026000000001",
		DocumentType:       DocumentTypeEFatura,
		ProviderCode:       "SIM_GIB_EFATURA",
		ProviderDocumentID: "provider-doc-001",
		CancelReasonCode:   "CUSTOMER_REQUEST",
		CancelReasonText:   "Musteri talebi",
		RequestedBy:        "user-001",
		RequestedAt:        now,
	}
}

func TestHandleProviderErrorSchedulesRetry(t *testing.T) {
	runtime, err := NewErrorCancelRetryRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validErrorEvent()
	decision, err := runtime.HandleProviderError(event)
	if err != nil {
		t.Fatalf("handle provider error failed: %v", err)
	}

	if decision.DecisionStatus != DecisionRetryScheduled {
		t.Fatalf("expected retry scheduled, got %s", decision.DecisionStatus)
	}
	if decision.NextRetryCount != 1 {
		t.Fatalf("expected next retry count 1, got %d", decision.NextRetryCount)
	}
	if decision.RetryAfter.IsZero() {
		t.Fatal("expected retry_after")
	}
}

func TestHandleProviderErrorMovesToDLQWhenRetryExhausted(t *testing.T) {
	runtime, err := NewErrorCancelRetryRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validErrorEvent()
	event.RetryCount = 3

	decision, err := runtime.HandleProviderError(event)
	if err != nil {
		t.Fatalf("handle provider error failed: %v", err)
	}

	if decision.DecisionStatus != DecisionDLQ {
		t.Fatalf("expected DLQ, got %s", decision.DecisionStatus)
	}
	if !decision.DLQRequired {
		t.Fatal("expected DLQ required")
	}
}

func TestHandleProviderErrorDetectsNonRetryable(t *testing.T) {
	runtime, err := NewErrorCancelRetryRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validErrorEvent()
	event.ProviderErrorCode = "INVALID_UBL"

	decision, err := runtime.HandleProviderError(event)
	if err != nil {
		t.Fatalf("handle provider error failed: %v", err)
	}

	if decision.DecisionStatus != DecisionNoRetry {
		t.Fatalf("expected no retry, got %s", decision.DecisionStatus)
	}
	if decision.ErrorClass != ErrorClassNonRetryable {
		t.Fatalf("expected non retryable, got %s", decision.ErrorClass)
	}
}

func TestHandleProviderErrorDetectsManualReview(t *testing.T) {
	runtime, err := NewErrorCancelRetryRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validErrorEvent()
	event.ProviderErrorCode = "LEGAL_STATUS_UNKNOWN"

	decision, err := runtime.HandleProviderError(event)
	if err != nil {
		t.Fatalf("handle provider error failed: %v", err)
	}

	if decision.DecisionStatus != DecisionManualReview {
		t.Fatalf("expected manual review, got %s", decision.DecisionStatus)
	}
	if !decision.ManualReviewRequired {
		t.Fatal("expected manual review required")
	}
}

func TestHandleProviderErrorIgnoresDuplicate(t *testing.T) {
	runtime, err := NewErrorCancelRetryRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validErrorEvent()
	event.ProviderErrorCode = "DUPLICATE_IDEMPOTENCY_KEY"

	decision, err := runtime.HandleProviderError(event)
	if err != nil {
		t.Fatalf("handle provider error failed: %v", err)
	}

	if decision.DecisionStatus != DecisionDuplicate {
		t.Fatalf("expected duplicate ignored, got %s", decision.DecisionStatus)
	}
}

func TestPrepareCancelRequiresReasonCode(t *testing.T) {
	runtime, err := NewErrorCancelRetryRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validCancelRequest()
	req.CancelReasonCode = ""

	decision, err := runtime.PrepareCancel(req)
	if err == nil {
		t.Fatal("expected cancel reason error")
	}
	if decision.DecisionStatus != CancelDecisionRejected {
		t.Fatalf("expected cancel rejected, got %s", decision.DecisionStatus)
	}
	if decision.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", decision.ErrorCode)
	}
}

func TestPrepareAndRegisterCancelAccepted(t *testing.T) {
	runtime, err := NewErrorCancelRetryRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	queued, err := runtime.PrepareCancel(validCancelRequest())
	if err != nil {
		t.Fatalf("prepare cancel failed: %v", err)
	}
	if queued.DecisionStatus != CancelDecisionQueued {
		t.Fatalf("expected cancel queued, got %s", queued.DecisionStatus)
	}

	accepted, err := runtime.RegisterCancelAccepted(validCancelRequest())
	if err != nil {
		t.Fatalf("register cancel accepted failed: %v", err)
	}
	if accepted.DecisionStatus != CancelDecisionAccepted {
		t.Fatalf("expected cancel accepted, got %s", accepted.DecisionStatus)
	}
	if accepted.ProviderCancelID == "" {
		t.Fatal("expected provider cancel id")
	}
}
