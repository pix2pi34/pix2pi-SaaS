package paymentadapter

import (
	"errors"
	"strings"
	"testing"
	"time"
)

func TestPaymentSandboxE2ERuntimeRequiresDependencies(t *testing.T) {
	service, provider, webhook, repo := sandboxE2EComponents(t)

	if _, err := NewPaymentSandboxE2ERuntime(nil, provider, webhook, repo); err == nil {
		t.Fatal("missing service must fail")
	}
	if _, err := NewPaymentSandboxE2ERuntime(service, nil, webhook, repo); err == nil {
		t.Fatal("missing provider must fail")
	}
	if _, err := NewPaymentSandboxE2ERuntime(service, provider, nil, repo); err == nil {
		t.Fatal("missing webhook runtime must fail")
	}
	if _, err := NewPaymentSandboxE2ERuntime(service, provider, webhook, nil); err == nil {
		t.Fatal("missing repository must fail")
	}
}

func TestPaymentSandboxE2EAuthorizeWebhookRoundtrip(t *testing.T) {
	runtime, _, _, repo := sandboxE2ERuntime(t)

	result, err := runtime.AuthorizeWebhookRoundtrip(PaymentSandboxE2ERoundtripRequest{
		PaymentRequest: sandboxE2EPaymentRequest(),
		EventType:      "payment.authorized",
	})
	if err != nil {
		t.Fatalf("expected sandbox e2e roundtrip success, got %v", err)
	}

	if result.AuthorizeResult.Attempt.Status != AttemptStatusAuthorized {
		t.Fatalf("expected authorize status AUTHORIZED, got %s", result.AuthorizeResult.Attempt.Status)
	}
	if !result.WebhookResult.Verified {
		t.Fatal("expected webhook result verified")
	}
	if result.FinalAttempt.Status != AttemptStatusAuthorized {
		t.Fatalf("webhook roundtrip must keep AUTHORIZED status, got %s", result.FinalAttempt.Status)
	}
	if result.EventCountBefore != 2 {
		t.Fatalf("expected creation + authorize before webhook, got %d", result.EventCountBefore)
	}
	if result.EventCountAfter != 3 {
		t.Fatalf("expected creation + authorize + webhook after roundtrip, got %d", result.EventCountAfter)
	}
	if result.FinalAttempt.ProviderTransactionID != result.AuthorizeResult.Attempt.ProviderTransactionID {
		t.Fatal("provider transaction id continuity failed")
	}
	if !strings.Contains(string(result.WebhookDelivery.RawPayload), `"event_type":"payment.authorized"`) {
		t.Fatalf("expected webhook payload event type, got %s", string(result.WebhookDelivery.RawPayload))
	}

	found, exists, err := repo.FindByAttemptID("tenant_7", "attempt_e2e_001")
	if err != nil {
		t.Fatalf("expected repository find success, got %v", err)
	}
	if !exists {
		t.Fatal("final attempt must exist in repository")
	}
	if len(found.Events) != 3 {
		t.Fatalf("expected persisted 3 events, got %d", len(found.Events))
	}
}

func TestPaymentSandboxE2ERejectsMissingEventType(t *testing.T) {
	runtime, _, _, _ := sandboxE2ERuntime(t)

	_, err := runtime.AuthorizeWebhookRoundtrip(PaymentSandboxE2ERoundtripRequest{
		PaymentRequest: sandboxE2EPaymentRequest(),
		EventType:      "",
	})
	if err == nil {
		t.Fatal("missing event type must fail")
	}
	if !errors.Is(err, ErrPaymentSandboxE2EInvalidRequest) {
		t.Fatalf("expected invalid request error, got %v", err)
	}
}

func TestPaymentSandboxE2ERejectsMissingTenant(t *testing.T) {
	runtime, _, _, _ := sandboxE2ERuntime(t)
	req := sandboxE2EPaymentRequest()
	req.TenantID = ""

	_, err := runtime.AuthorizeWebhookRoundtrip(PaymentSandboxE2ERoundtripRequest{
		PaymentRequest: req,
		EventType:      "payment.authorized",
	})
	if err == nil {
		t.Fatal("missing tenant must fail")
	}
	if !errors.Is(err, ErrPaymentSandboxE2EInvalidRequest) {
		t.Fatalf("expected invalid request error, got %v", err)
	}
}

func TestPaymentSandboxE2EWebhookSignatureRoundtripIsValid(t *testing.T) {
	runtime, _, _, _ := sandboxE2ERuntime(t)

	result, err := runtime.AuthorizeWebhookRoundtrip(PaymentSandboxE2ERoundtripRequest{
		PaymentRequest: sandboxE2EPaymentRequest(),
		EventType:      "payment.authorized",
	})
	if err != nil {
		t.Fatalf("expected sandbox e2e roundtrip success, got %v", err)
	}

	parts, err := parsePaymentWebhookSignatureHeader(result.WebhookDelivery.SignatureHeader)
	if err != nil {
		t.Fatalf("expected signature header parse success, got %v", err)
	}

	if !verifyPaymentWebhookSignature([]byte("whsec_e2e"), parts.Timestamp, result.WebhookDelivery.RawPayload, parts.Signature) {
		t.Fatal("expected webhook delivery signature to verify")
	}
}

func sandboxE2ERuntime(t *testing.T) (*PaymentSandboxE2ERuntime, *PaymentService, *SimulationPaymentProviderAdapter, *InMemoryPaymentAttemptRepository) {
	t.Helper()

	service, provider, webhook, repo := sandboxE2EComponents(t)
	runtime, err := NewPaymentSandboxE2ERuntime(service, provider, webhook, repo)
	if err != nil {
		t.Fatalf("expected sandbox e2e runtime, got %v", err)
	}

	return runtime, service, provider, repo
}

func sandboxE2EComponents(t *testing.T) (*PaymentService, *SimulationPaymentProviderAdapter, *PaymentWebhookIntakeRuntime, *InMemoryPaymentAttemptRepository) {
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

	provider, err := NewSimulationPaymentProviderAdapter(cfg, "whsec_e2e")
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

	webhook, err := NewPaymentWebhookIntakeRuntime(service, provider.Code(), "whsec_e2e")
	if err != nil {
		t.Fatalf("expected webhook runtime, got %v", err)
	}

	fixedNow := time.Unix(1893456000, 0).UTC()
	provider.now = func() time.Time { return fixedNow }
	webhook.now = func() time.Time { return fixedNow }

	return service, provider, webhook, repo
}

func sandboxE2EPaymentRequest() PaymentOperationRequest {
	return PaymentOperationRequest{
		AttemptID:      "attempt_e2e_001",
		TenantID:       "tenant_7",
		InvoiceID:      "invoice_e2e_001",
		SubscriptionID: "sub_e2e_001",
		CorrelationID:  "corr_e2e_001",
		RequestID:      "req_e2e_001",
		IdempotencyKey: "idem_e2e_001",
		Money:          Money{AmountMinor: 120000, Currency: "TRY"},
	}
}
