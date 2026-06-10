package paymentadapter

import (
	"errors"
	"testing"
)

func TestPaymentServiceConstructorRequiresDependencies(t *testing.T) {
	provider, matrix := testPaymentProviderAndMatrix(t, []string{"AUTHORIZE"}, ModeSandbox, false)
	repo := NewInMemoryPaymentAttemptRepository()

	if _, err := NewPaymentService(nil, matrix, repo); err == nil {
		t.Fatal("missing provider must fail")
	}

	if _, err := NewPaymentService(provider, matrix, nil); err == nil {
		t.Fatal("missing repository must fail")
	}

	mismatchedMatrix := matrix
	mismatchedMatrix.ProviderCode = "another_provider"
	if _, err := NewPaymentService(provider, mismatchedMatrix, repo); err == nil {
		t.Fatal("provider code mismatch must fail")
	}
}

func TestPaymentServiceAuthorizeCreatesAndPersistsAttempt(t *testing.T) {
	service, repo := testPaymentService(t, []string{"AUTHORIZE"}, ModeSandbox, false)

	result, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got error: %v", err)
	}

	if result.Replay {
		t.Fatal("first authorize must not be replay")
	}
	if result.Attempt.Status != AttemptStatusAuthorized {
		t.Fatalf("expected AUTHORIZED, got %s", result.Attempt.Status)
	}
	if result.Attempt.ProviderTransactionID != "sim_provider_txn_attempt_service_001" {
		t.Fatalf("expected simulated provider transaction id, got %s", result.Attempt.ProviderTransactionID)
	}

	found, exists, err := repo.FindByAttemptID("tenant_7", "attempt_service_001")
	if err != nil {
		t.Fatalf("expected repository find success, got %v", err)
	}
	if !exists {
		t.Fatal("authorized attempt must be persisted")
	}
	if found.Status != AttemptStatusAuthorized {
		t.Fatalf("expected persisted AUTHORIZED, got %s", found.Status)
	}
}

func TestPaymentServiceAuthorizeIdempotencyReplayReturnsExistingAttempt(t *testing.T) {
	service, _ := testPaymentService(t, []string{"AUTHORIZE"}, ModeSandbox, false)

	first, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected first authorize success, got %v", err)
	}

	second, err := service.Authorize(testAuthorizeRequest())
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

func TestPaymentServiceAuthorizeDeniedDecisionIsPersistedAsFailed(t *testing.T) {
	service, repo := testPaymentService(t, []string{"AUTHORIZE"}, ModeProduction, false)

	result, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("denied contract decision should persist failed attempt without service error, got %v", err)
	}

	if result.Attempt.Status != AttemptStatusFailed {
		t.Fatalf("expected FAILED, got %s", result.Attempt.Status)
	}
	if result.Attempt.FailureCode != ErrorProductionGateClosed {
		t.Fatalf("expected production gate failure, got %s", result.Attempt.FailureCode)
	}

	found, exists, err := repo.FindByAttemptID("tenant_7", "attempt_service_001")
	if err != nil {
		t.Fatalf("expected failed attempt lookup success, got %v", err)
	}
	if !exists {
		t.Fatal("failed attempt must be persisted for audit")
	}
	if found.Status != AttemptStatusFailed {
		t.Fatalf("expected persisted FAILED, got %s", found.Status)
	}
}

func TestPaymentServiceCaptureUpdatesPersistedAttempt(t *testing.T) {
	service, repo := testPaymentService(t, []string{"AUTHORIZE", "CAPTURE"}, ModeSandbox, false)

	authorized, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	captureReq := testAuthorizeRequest()
	captureReq.ProviderTransactionID = authorized.Attempt.ProviderTransactionID

	captured, err := service.Capture(captureReq)
	if err != nil {
		t.Fatalf("expected capture success, got %v", err)
	}

	if captured.Attempt.Status != AttemptStatusCaptured {
		t.Fatalf("expected CAPTURED, got %s", captured.Attempt.Status)
	}

	found, exists, err := repo.FindByAttemptID("tenant_7", "attempt_service_001")
	if err != nil {
		t.Fatalf("expected repository find success, got %v", err)
	}
	if !exists {
		t.Fatal("captured attempt must exist")
	}
	if found.Status != AttemptStatusCaptured {
		t.Fatalf("expected persisted CAPTURED, got %s", found.Status)
	}
}

func TestPaymentServiceCaptureRejectsProviderTransactionMismatch(t *testing.T) {
	service, _ := testPaymentService(t, []string{"AUTHORIZE", "CAPTURE"}, ModeSandbox, false)

	if _, err := service.Authorize(testAuthorizeRequest()); err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	captureReq := testAuthorizeRequest()
	captureReq.ProviderTransactionID = "wrong_provider_txn"

	_, err := service.Capture(captureReq)
	if err == nil {
		t.Fatal("provider transaction mismatch must fail")
	}
	if !errors.Is(err, ErrProviderTransactionMismatch) {
		t.Fatalf("expected provider transaction mismatch, got %v", err)
	}
}

func TestPaymentServiceRefundUpdatesCapturedAttempt(t *testing.T) {
	service, _ := testPaymentService(t, []string{"AUTHORIZE", "CAPTURE", "REFUND"}, ModeSandbox, false)

	authorized, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	captureReq := testAuthorizeRequest()
	captureReq.ProviderTransactionID = authorized.Attempt.ProviderTransactionID

	captured, err := service.Capture(captureReq)
	if err != nil {
		t.Fatalf("expected capture success, got %v", err)
	}

	refundReq := testAuthorizeRequest()
	refundReq.ProviderTransactionID = captured.Attempt.ProviderTransactionID

	refunded, err := service.Refund(refundReq)
	if err != nil {
		t.Fatalf("expected refund success, got %v", err)
	}
	if refunded.Attempt.Status != AttemptStatusRefunded {
		t.Fatalf("expected REFUNDED, got %s", refunded.Attempt.Status)
	}
}

func TestPaymentServiceVoidUpdatesAuthorizedAttempt(t *testing.T) {
	service, _ := testPaymentService(t, []string{"AUTHORIZE", "VOID"}, ModeSandbox, false)

	authorized, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	voidReq := testAuthorizeRequest()
	voidReq.Money = Money{}
	voidReq.ProviderTransactionID = authorized.Attempt.ProviderTransactionID

	voided, err := service.Void(voidReq)
	if err != nil {
		t.Fatalf("expected void success, got %v", err)
	}
	if voided.Attempt.Status != AttemptStatusVoided {
		t.Fatalf("expected VOIDED, got %s", voided.Attempt.Status)
	}
}

func TestPaymentServiceVerifyWebhookAddsAuditEventWithoutChangingStatus(t *testing.T) {
	service, _ := testPaymentService(t, []string{"AUTHORIZE", "WEBHOOK_VERIFY"}, ModeSandbox, false)

	authorized, err := service.Authorize(testAuthorizeRequest())
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	webhookReq := testAuthorizeRequest()
	webhookReq.ProviderTransactionID = authorized.Attempt.ProviderTransactionID
	webhookReq.Money = Money{}
	webhookReq.IdempotencyKey = ""
	webhookReq.WebhookSignature = "sig_test"
	webhookReq.RawWebhookPayload = []byte(`{"event":"payment.authorized"}`)

	result, err := service.VerifyWebhook(webhookReq)
	if err != nil {
		t.Fatalf("expected webhook verify success, got %v", err)
	}

	if result.Attempt.Status != AttemptStatusAuthorized {
		t.Fatalf("webhook verify must not change status, got %s", result.Attempt.Status)
	}
	if len(result.Attempt.Events) != 3 {
		t.Fatalf("expected creation + authorize + webhook events, got %d", len(result.Attempt.Events))
	}
}

func testPaymentService(t *testing.T, operations []string, mode ProviderMode, realPaymentEnabled bool) (*PaymentService, *InMemoryPaymentAttemptRepository) {
	t.Helper()

	provider, matrix := testPaymentProviderAndMatrix(t, operations, mode, realPaymentEnabled)
	repo := NewInMemoryPaymentAttemptRepository()

	service, err := NewPaymentService(provider, matrix, repo)
	if err != nil {
		t.Fatalf("expected payment service, got error: %v", err)
	}

	return service, repo
}

func testPaymentProviderAndMatrix(t *testing.T, operations []string, mode ProviderMode, realPaymentEnabled bool) (PaymentProviderAdapter, ProviderCapabilityMatrix) {
	t.Helper()

	cfg := ProviderConfig{
		ProviderName:       "Pix2pi Simulation Provider",
		ProviderCode:       "pix2pi_simulation",
		Mode:               string(mode),
		RealPaymentEnabled: realPaymentEnabled,
		AllowedOperations:  operations,
		SettlementCurrency: "TRY",
		WebhookRequired:    true,
		AuditEnabled:       true,
	}

	provider, err := NewProviderAdapter(cfg)
	if err != nil {
		t.Fatalf("expected provider adapter, got error: %v", err)
	}

	matrix, err := NewProviderCapabilityMatrix(cfg)
	if err != nil {
		t.Fatalf("expected provider capability matrix, got error: %v", err)
	}

	return provider, matrix
}

func testAuthorizeRequest() PaymentOperationRequest {
	return PaymentOperationRequest{
		AttemptID:      "attempt_service_001",
		TenantID:       "tenant_7",
		InvoiceID:      "invoice_service_001",
		SubscriptionID: "sub_service_001",
		CorrelationID:  "corr_service_001",
		RequestID:      "req_service_001",
		IdempotencyKey: "idem_service_001",
		Money:          Money{AmountMinor: 65000, Currency: "TRY"},
	}
}
