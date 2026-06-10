package paymentadapter

import (
	"errors"
	"testing"
	"time"
)

func TestPaymentFailureRetryRuntimeRequiresDependencies(t *testing.T) {
	service, webhook, repo := failureRetrySandboxComponents(t)

	if _, err := NewPaymentFailureRetryRuntime(nil, repo, webhook, DefaultPaymentRetryPolicy()); err == nil {
		t.Fatal("missing service must fail")
	}
	if _, err := NewPaymentFailureRetryRuntime(service, nil, webhook, DefaultPaymentRetryPolicy()); err == nil {
		t.Fatal("missing repository must fail")
	}
	if _, err := NewPaymentFailureRetryRuntime(service, repo, nil, DefaultPaymentRetryPolicy()); err == nil {
		t.Fatal("missing webhook runtime must fail")
	}
}

func TestPaymentFailureRetryAuthorizeIdempotencyReplay(t *testing.T) {
	runtime, _, _ := failureRetryRuntime(t)

	first, err := runtime.AuthorizeWithReplay(failureRetryPaymentRequest())
	if err != nil {
		t.Fatalf("expected first authorize success, got %v", err)
	}
	if first.Replay {
		t.Fatal("first authorize must not be replay")
	}

	second, err := runtime.AuthorizeWithReplay(failureRetryPaymentRequest())
	if err != nil {
		t.Fatalf("expected replay authorize success, got %v", err)
	}
	if !second.Replay {
		t.Fatal("second authorize with same idempotency key must be replay")
	}
	if second.Attempt.AttemptID != first.Attempt.AttemptID {
		t.Fatalf("expected replay attempt id %s, got %s", first.Attempt.AttemptID, second.Attempt.AttemptID)
	}
}

func TestPaymentFailureRetryDeniedAuthorizePersistsFailedAttempt(t *testing.T) {
	runtime, repo := failureRetryProductionDeniedRuntime(t)

	result, err := runtime.AuthorizeWithReplay(failureRetryPaymentRequest())
	if err != nil {
		t.Fatalf("denied authorize should persist failed attempt without runtime error, got %v", err)
	}

	if result.Attempt.Status != AttemptStatusFailed {
		t.Fatalf("expected FAILED attempt, got %s", result.Attempt.Status)
	}
	if result.Attempt.FailureCode != ErrorProductionGateClosed {
		t.Fatalf("expected production gate closed, got %s", result.Attempt.FailureCode)
	}

	found, exists, err := repo.FindByAttemptID("tenant_7", "attempt_failure_retry_001")
	if err != nil {
		t.Fatalf("expected repository lookup success, got %v", err)
	}
	if !exists {
		t.Fatal("failed attempt must be persisted")
	}
	if found.Status != AttemptStatusFailed {
		t.Fatalf("expected persisted FAILED, got %s", found.Status)
	}
}

func TestPaymentFailureRetryDecisionModel(t *testing.T) {
	runtime, _, _ := failureRetryRuntime(t)

	allowed := runtime.EvaluateRetry(ErrorProviderTransactionRequired, 1)
	if allowed.Status != RetryDecisionAllowed {
		t.Fatalf("expected retry allowed, got %s", allowed.Status)
	}
	if !allowed.Retryable {
		t.Fatal("expected retryable decision")
	}

	nonRetryable := runtime.EvaluateRetry(ErrorProductionGateClosed, 1)
	if nonRetryable.Status != RetryDecisionNonRetryable {
		t.Fatalf("expected non-retryable decision, got %s", nonRetryable.Status)
	}
	if nonRetryable.Retryable {
		t.Fatal("production gate closed must not be retryable")
	}

	limitReached := runtime.EvaluateRetry(ErrorProviderTransactionRequired, 3)
	if limitReached.Status != RetryDecisionDenied {
		t.Fatalf("expected retry denied after limit, got %s", limitReached.Status)
	}
}

func TestPaymentFailureRetryDuplicateWebhookDoesNotAppendSecondEvent(t *testing.T) {
	runtime, provider, _ := failureRetryRuntime(t)

	authorized, err := runtime.AuthorizeWithReplay(failureRetryPaymentRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	delivery, err := provider.BuildWebhookDelivery(RequestContext{
		TenantID:       "tenant_7",
		CorrelationID:  "corr_failure_retry_001",
		RequestID:      "req_failure_retry_001",
		IdempotencyKey: "idem_failure_retry_001",
	}, authorized.Attempt.AttemptID, authorized.Attempt.ProviderTransactionID, "payment.authorized")
	if err != nil {
		t.Fatalf("expected webhook delivery, got %v", err)
	}

	req := PaymentWebhookIntakeRequest{
		TenantID:        "tenant_7",
		AttemptID:       authorized.Attempt.AttemptID,
		ProviderCode:    delivery.ProviderCode,
		CorrelationID:   "corr_failure_retry_001",
		RequestID:       "req_failure_retry_001",
		SignatureHeader: delivery.SignatureHeader,
		RawPayload:      delivery.RawPayload,
		ReceivedAt:      delivery.OccurredAt,
	}

	first, err := runtime.VerifyWebhookOnce("webhook_event_001", req)
	if err != nil {
		t.Fatalf("expected first webhook verify success, got %v", err)
	}
	if first.Duplicate {
		t.Fatal("first webhook must not be duplicate")
	}
	if first.EventCount != 3 {
		t.Fatalf("expected 3 events after first webhook, got %d", first.EventCount)
	}

	second, err := runtime.VerifyWebhookOnce("webhook_event_001", req)
	if err != nil {
		t.Fatalf("expected duplicate webhook ignore success, got %v", err)
	}
	if !second.Duplicate {
		t.Fatal("second webhook with same dedupe key must be duplicate")
	}
	if second.EventCount != first.EventCount {
		t.Fatalf("duplicate webhook must not append event: first=%d second=%d", first.EventCount, second.EventCount)
	}
}

func TestPaymentFailureRetryRejectsMissingWebhookDedupeKey(t *testing.T) {
	runtime, _, _ := failureRetryRuntime(t)

	_, err := runtime.VerifyWebhookOnce("", PaymentWebhookIntakeRequest{
		TenantID:  "tenant_7",
		AttemptID: "attempt_failure_retry_001",
	})
	if err == nil {
		t.Fatal("missing webhook dedupe key must fail")
	}
	if !errors.Is(err, ErrPaymentFailureRetryInvalidRequest) {
		t.Fatalf("expected invalid request error, got %v", err)
	}
}

func failureRetryRuntime(t *testing.T) (*PaymentFailureRetryRuntime, *SimulationPaymentProviderAdapter, *InMemoryPaymentAttemptRepository) {
	t.Helper()

	service, webhook, repo, provider := failureRetrySandboxComponentsWithProvider(t)
	runtime, err := NewPaymentFailureRetryRuntime(service, repo, webhook, DefaultPaymentRetryPolicy())
	if err != nil {
		t.Fatalf("expected failure retry runtime, got %v", err)
	}

	return runtime, provider, repo
}

func failureRetrySandboxComponents(t *testing.T) (*PaymentService, *PaymentWebhookIntakeRuntime, *InMemoryPaymentAttemptRepository) {
	t.Helper()

	service, webhook, repo, _ := failureRetrySandboxComponentsWithProvider(t)
	return service, webhook, repo
}

func failureRetrySandboxComponentsWithProvider(t *testing.T) (*PaymentService, *PaymentWebhookIntakeRuntime, *InMemoryPaymentAttemptRepository, *SimulationPaymentProviderAdapter) {
	t.Helper()

	cfg := ProviderConfig{
		ProviderName:       "Pix2pi Simulation Provider",
		ProviderCode:       "pix2pi_simulation",
		Mode:               string(ModeSandbox),
		RealPaymentEnabled: false,
		AllowedOperations:  []string{"AUTHORIZE", "WEBHOOK_VERIFY"},
		SettlementCurrency: "TRY",
		WebhookRequired:    true,
		AuditEnabled:       true,
	}

	provider, err := NewSimulationPaymentProviderAdapter(cfg, "whsec_failure_retry")
	if err != nil {
		t.Fatalf("expected simulation provider, got %v", err)
	}

	matrix, err := NewProviderCapabilityMatrix(cfg)
	if err != nil {
		t.Fatalf("expected capability matrix, got %v", err)
	}

	repo := NewInMemoryPaymentAttemptRepository()

	service, err := NewPaymentService(provider, matrix, repo)
	if err != nil {
		t.Fatalf("expected payment service, got %v", err)
	}

	webhook, err := NewPaymentWebhookIntakeRuntime(service, provider.Code(), "whsec_failure_retry")
	if err != nil {
		t.Fatalf("expected webhook runtime, got %v", err)
	}

	fixedNow := time.Unix(1893456000, 0).UTC()
	provider.now = func() time.Time { return fixedNow }
	webhook.now = func() time.Time { return fixedNow }

	return service, webhook, repo, provider
}

func failureRetryProductionDeniedRuntime(t *testing.T) (*PaymentFailureRetryRuntime, *InMemoryPaymentAttemptRepository) {
	t.Helper()

	cfg := ProviderConfig{
		ProviderName:       "Production Provider",
		ProviderCode:       "pix2pi_simulation",
		Mode:               string(ModeProduction),
		RealPaymentEnabled: false,
		AllowedOperations:  []string{"AUTHORIZE", "WEBHOOK_VERIFY"},
		SettlementCurrency: "TRY",
		WebhookRequired:    true,
		AuditEnabled:       true,
	}

	provider, err := NewProviderAdapter(cfg)
	if err != nil {
		t.Fatalf("expected provider adapter, got %v", err)
	}

	matrix, err := NewProviderCapabilityMatrix(cfg)
	if err != nil {
		t.Fatalf("expected capability matrix, got %v", err)
	}

	repo := NewInMemoryPaymentAttemptRepository()

	service, err := NewPaymentService(provider, matrix, repo)
	if err != nil {
		t.Fatalf("expected payment service, got %v", err)
	}

	webhook, err := NewPaymentWebhookIntakeRuntime(service, provider.Code(), "whsec_failure_retry")
	if err != nil {
		t.Fatalf("expected webhook runtime, got %v", err)
	}

	runtime, err := NewPaymentFailureRetryRuntime(service, repo, webhook, DefaultPaymentRetryPolicy())
	if err != nil {
		t.Fatalf("expected failure retry runtime, got %v", err)
	}

	return runtime, repo
}

func failureRetryPaymentRequest() PaymentOperationRequest {
	return PaymentOperationRequest{
		AttemptID:      "attempt_failure_retry_001",
		TenantID:       "tenant_7",
		InvoiceID:      "invoice_failure_retry_001",
		SubscriptionID: "sub_failure_retry_001",
		CorrelationID:  "corr_failure_retry_001",
		RequestID:      "req_failure_retry_001",
		IdempotencyKey: "idem_failure_retry_001",
		Money:          Money{AmountMinor: 135000, Currency: "TRY"},
	}
}
