package paymentadapter

import (
	"errors"
	"strings"
	"testing"
	"time"
)

func TestSimulationProviderImplementsPaymentProviderAdapter(t *testing.T) {
	adapter := mustSimulationProvider(t, []string{"AUTHORIZE"}, ModeSimulation)
	var _ PaymentProviderAdapter = adapter
}

func TestSimulationProviderRejectsProductionMode(t *testing.T) {
	_, err := NewSimulationPaymentProviderAdapter(simulationProviderTestConfig([]string{"AUTHORIZE"}, ModeProduction), "whsec_sim")
	if err == nil {
		t.Fatal("production mode must be rejected")
	}
	if !errors.Is(err, ErrSimulationProviderInvalidConfig) {
		t.Fatalf("expected invalid config error, got %v", err)
	}
}

func TestSimulationProviderRejectsRealPaymentEnabled(t *testing.T) {
	cfg := simulationProviderTestConfig([]string{"AUTHORIZE"}, ModeSandbox)
	cfg.RealPaymentEnabled = true

	_, err := NewSimulationPaymentProviderAdapter(cfg, "whsec_sim")
	if err == nil {
		t.Fatal("real payment enabled must be rejected")
	}
	if !errors.Is(err, ErrSimulationProviderInvalidConfig) {
		t.Fatalf("expected invalid config error, got %v", err)
	}
}

func TestSimulationProviderAuthorizeProducesProviderTransaction(t *testing.T) {
	adapter := mustSimulationProvider(t, []string{"AUTHORIZE"}, ModeSandbox)

	result, err := adapter.Authorize(simulationRequestContext(), "attempt_sim_001", Money{AmountMinor: 90000, Currency: "TRY"})
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}
	if !result.Approved {
		t.Fatalf("expected approved authorize, got %s", result.Message)
	}
	if result.Status != AttemptStatusAuthorized {
		t.Fatalf("expected AUTHORIZED, got %s", result.Status)
	}
	if !strings.Contains(result.ProviderTransactionID, "sim_tenant_7_attempt_sim_001_authorize") {
		t.Fatalf("unexpected provider transaction id: %s", result.ProviderTransactionID)
	}
}

func TestSimulationProviderCaptureRefundVoid(t *testing.T) {
	adapter := mustSimulationProvider(t, []string{"AUTHORIZE", "CAPTURE", "REFUND", "VOID"}, ModeSandbox)
	ctx := simulationRequestContext()

	authorized, err := adapter.Authorize(ctx, "attempt_sim_002", Money{AmountMinor: 90000, Currency: "TRY"})
	if err != nil {
		t.Fatalf("expected authorize success, got %v", err)
	}

	captured, err := adapter.Capture(ctx, authorized.ProviderTransactionID, Money{AmountMinor: 90000, Currency: "TRY"})
	if err != nil {
		t.Fatalf("expected capture success, got %v", err)
	}
	if captured.Status != AttemptStatusCaptured {
		t.Fatalf("expected CAPTURED, got %s", captured.Status)
	}

	refunded, err := adapter.Refund(ctx, authorized.ProviderTransactionID, Money{AmountMinor: 90000, Currency: "TRY"})
	if err != nil {
		t.Fatalf("expected refund success, got %v", err)
	}
	if refunded.Status != AttemptStatusRefunded {
		t.Fatalf("expected REFUNDED, got %s", refunded.Status)
	}

	voided, err := adapter.Void(ctx, authorized.ProviderTransactionID)
	if err != nil {
		t.Fatalf("expected void success, got %v", err)
	}
	if voided.Status != AttemptStatusVoided {
		t.Fatalf("expected VOIDED, got %s", voided.Status)
	}
}

func TestSimulationProviderCaptureRequiresProviderTransaction(t *testing.T) {
	adapter := mustSimulationProvider(t, []string{"CAPTURE"}, ModeSandbox)

	result, err := adapter.Capture(simulationRequestContext(), "", Money{AmountMinor: 90000, Currency: "TRY"})
	if err != nil {
		t.Fatalf("denied capture should return result without runtime error, got %v", err)
	}
	if result.Approved {
		t.Fatal("capture without provider transaction id must be denied")
	}
	if result.Decision.ErrorCode != ErrorProviderTransactionRequired {
		t.Fatalf("expected provider transaction required, got %s", result.Decision.ErrorCode)
	}
}

func TestSimulationProviderDeniesMissingTenantThroughContract(t *testing.T) {
	adapter := mustSimulationProvider(t, []string{"AUTHORIZE"}, ModeSandbox)
	ctx := simulationRequestContext()
	ctx.TenantID = ""

	result, err := adapter.Authorize(ctx, "attempt_sim_003", Money{AmountMinor: 90000, Currency: "TRY"})
	if err != nil {
		t.Fatalf("contract denial should return result without runtime error, got %v", err)
	}
	if result.Approved {
		t.Fatal("missing tenant must be denied")
	}
	if result.Decision.ErrorCode != ErrorTenantRequired {
		t.Fatalf("expected tenant required, got %s", result.Decision.ErrorCode)
	}
}

func TestSimulationProviderBuildWebhookDeliveryProducesSignedPayload(t *testing.T) {
	adapter := mustSimulationProvider(t, []string{"AUTHORIZE", "WEBHOOK_VERIFY"}, ModeSandbox)
	fixedNow := time.Unix(1893456000, 0).UTC()
	adapter.now = func() time.Time { return fixedNow }

	delivery, err := adapter.BuildWebhookDelivery(simulationRequestContext(), "attempt_sim_004", "sim_txn_004", "payment.authorized")
	if err != nil {
		t.Fatalf("expected webhook delivery, got %v", err)
	}

	if delivery.ProviderCode != "pix2pi_simulation" {
		t.Fatalf("unexpected provider code: %s", delivery.ProviderCode)
	}
	if !strings.Contains(string(delivery.RawPayload), `"event_type":"payment.authorized"`) {
		t.Fatalf("expected event type in payload, got %s", string(delivery.RawPayload))
	}
	if !strings.Contains(delivery.SignatureHeader, "t=1893456000,v1=") {
		t.Fatalf("unexpected signature header: %s", delivery.SignatureHeader)
	}

	parts, err := parsePaymentWebhookSignatureHeader(delivery.SignatureHeader)
	if err != nil {
		t.Fatalf("expected signature header parse success, got %v", err)
	}
	if !verifyPaymentWebhookSignature([]byte("whsec_sim"), parts.Timestamp, delivery.RawPayload, parts.Signature) {
		t.Fatal("expected generated webhook signature to be valid")
	}
}

func mustSimulationProvider(t *testing.T, operations []string, mode ProviderMode) *SimulationPaymentProviderAdapter {
	t.Helper()

	adapter, err := NewSimulationPaymentProviderAdapter(simulationProviderTestConfig(operations, mode), "whsec_sim")
	if err != nil {
		t.Fatalf("expected simulation provider, got %v", err)
	}

	return adapter
}

func simulationProviderTestConfig(operations []string, mode ProviderMode) ProviderConfig {
	return ProviderConfig{
		ProviderName:       "Pix2pi Simulation Provider",
		ProviderCode:       "pix2pi_simulation",
		Mode:               string(mode),
		RealPaymentEnabled: false,
		AllowedOperations:  operations,
		SettlementCurrency: "TRY",
		WebhookRequired:    true,
		AuditEnabled:       true,
	}
}

func simulationRequestContext() RequestContext {
	return RequestContext{
		TenantID:       "tenant_7",
		SubscriptionID: "sub_sim_001",
		PlanCode:       "pro",
		CorrelationID:  "corr_sim_001",
		RequestID:      "req_sim_001",
		IdempotencyKey: "idem_sim_001",
	}
}
