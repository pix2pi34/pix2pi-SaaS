package errorretry

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		Mode:                        RuntimeModeSimulation,
		RealPaymentGateOpen:         false,
		ProductionApproved:          false,
		MaxRetryCount:               3,
		BaseRetryDelaySec:           60,
		MaxRetryDelaySec:            600,
		DLQEnabled:                  true,
		ManualReviewEnabled:         true,
		ReversalReasonRequired:      true,
		IdempotencyRequired:         true,
		ProviderPayloadHashRequired: true,
		AllowedChannels: []PaymentChannel{
			PaymentChannelPOS,
			PaymentChannelVirtualPOS,
			PaymentChannelBankCollection,
			PaymentChannelBankTransfer,
			PaymentChannelMarketplace,
		},
		AllowedProviderCodes: []string{
			"SIM_BANK_POS",
			"SIM_BANK",
			"SIM_MARKETPLACE",
		},
		RetryableErrorCodes: []string{
			"PROVIDER_TIMEOUT",
			"PROVIDER_RATE_LIMITED",
			"BANK_TEMPORARY_UNAVAILABLE",
		},
		FatalErrorCodes: []string{
			"INVALID_CARD",
			"INSUFFICIENT_FUNDS",
			"INVALID_IBAN",
			"INVALID_AMOUNT",
		},
		ManualReviewCodes: []string{
			"CHARGEBACK_RISK",
			"BANK_RECONCILIATION_CONFLICT",
		},
	}
}

func validErrorEvent() PaymentErrorEvent {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return PaymentErrorEvent{
		TenantID:              "tenant-001",
		CorrelationID:         "corr-001",
		RequestID:             "req-001",
		IdempotencyKey:        "idem-001",
		PaymentTransactionID:  "pay-001",
		TransactionNo:         "PAY-001",
		Channel:               PaymentChannelPOS,
		ProviderCode:          "SIM_BANK_POS",
		ProviderTransactionID: "provider-pay-001",
		Operation:             OperationAuthorize,
		ProviderErrorCode:     "PROVIDER_TIMEOUT",
		ProviderErrorText:     "timeout",
		ProviderPayloadHash:   "sha256:payload",
		AmountKurus:           100000,
		CurrencyCode:          "TRY",
		RetryCount:            0,
		OccurredAt:            now,
		ReceivedAt:            now.Add(time.Second),
	}
}

func validReversalRequest() ReversalRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return ReversalRequest{
		TenantID:              "tenant-001",
		CorrelationID:         "corr-001",
		RequestID:             "req-001",
		IdempotencyKey:        "idem-rev-001",
		PaymentTransactionID:  "pay-001",
		TransactionNo:         "PAY-001",
		Channel:               PaymentChannelPOS,
		ProviderCode:          "SIM_BANK_POS",
		ProviderTransactionID: "provider-pay-001",
		OriginalOperation:     OperationSale,
		AmountKurus:           100000,
		CurrencyCode:          "TRY",
		ReversalReasonCode:    "OPERATOR_REVERSAL",
		ReversalReasonText:    "Operator iptali",
		RequestedBy:           "user-001",
		RequestedAt:           now,
	}
}

func TestRuntimeRejectsProductionWithoutApproval(t *testing.T) {
	cfg := validConfig()
	cfg.Mode = RuntimeModeProduction
	cfg.RealPaymentGateOpen = false
	cfg.ProductionApproved = false

	if _, err := NewPaymentErrorRetryReversalRuntime(cfg); err == nil {
		t.Fatal("expected production real payment gate to be closed")
	}
}

func TestHandleProviderErrorSchedulesRetry(t *testing.T) {
	runtime, err := NewPaymentErrorRetryReversalRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	decision, err := runtime.HandleProviderError(validErrorEvent())
	if err != nil {
		t.Fatalf("handle provider error failed: %v", err)
	}

	if decision.DecisionStatus != DecisionRetryScheduled {
		t.Fatalf("expected retry scheduled, got %s", decision.DecisionStatus)
	}
	if decision.NextRetryCount != 1 {
		t.Fatalf("expected next retry 1, got %d", decision.NextRetryCount)
	}
	if decision.RetryAfter.IsZero() {
		t.Fatal("expected retry_after")
	}
}

func TestHandleProviderErrorMovesToDLQWhenRetryExhausted(t *testing.T) {
	runtime, err := NewPaymentErrorRetryReversalRuntime(validConfig())
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
	runtime, err := NewPaymentErrorRetryReversalRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validErrorEvent()
	event.ProviderErrorCode = "INSUFFICIENT_FUNDS"

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
	runtime, err := NewPaymentErrorRetryReversalRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validErrorEvent()
	event.ProviderErrorCode = "BANK_RECONCILIATION_CONFLICT"

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
	runtime, err := NewPaymentErrorRetryReversalRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	event := validErrorEvent()
	event.ProviderErrorCode = "DUPLICATE_PROVIDER_TRANSACTION"

	decision, err := runtime.HandleProviderError(event)
	if err != nil {
		t.Fatalf("handle provider error failed: %v", err)
	}

	if decision.DecisionStatus != DecisionDuplicate {
		t.Fatalf("expected duplicate ignored, got %s", decision.DecisionStatus)
	}
}

func TestPrepareReversalRequiresReasonCode(t *testing.T) {
	runtime, err := NewPaymentErrorRetryReversalRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validReversalRequest()
	req.ReversalReasonCode = ""

	decision, err := runtime.PrepareReversal(req)
	if err == nil {
		t.Fatal("expected reversal reason error")
	}
	if decision.DecisionStatus != ReversalDecisionRejected {
		t.Fatalf("expected reversal rejected, got %s", decision.DecisionStatus)
	}
	if decision.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", decision.ErrorCode)
	}
}

func TestPrepareAndRegisterReversalAccepted(t *testing.T) {
	runtime, err := NewPaymentErrorRetryReversalRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	queued, err := runtime.PrepareReversal(validReversalRequest())
	if err != nil {
		t.Fatalf("prepare reversal failed: %v", err)
	}
	if queued.DecisionStatus != ReversalDecisionQueued {
		t.Fatalf("expected reversal queued, got %s", queued.DecisionStatus)
	}
	if queued.ReversalID == "" {
		t.Fatal("expected reversal id")
	}

	accepted, err := runtime.RegisterReversalAccepted(validReversalRequest())
	if err != nil {
		t.Fatalf("register reversal accepted failed: %v", err)
	}
	if accepted.DecisionStatus != ReversalDecisionAccepted {
		t.Fatalf("expected reversal accepted, got %s", accepted.DecisionStatus)
	}
	if accepted.ReversalID == "" {
		t.Fatal("expected accepted reversal id")
	}
}
