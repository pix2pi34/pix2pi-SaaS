package paymentadapter

import "testing"

func TestNewProviderAdapterSimulationConfig(t *testing.T) {
	cfg := ProviderConfig{
		ProviderName:       "Pix2pi Simulation Provider",
		ProviderCode:       "pix2pi_simulation",
		Mode:               "SIMULATION",
		RealPaymentEnabled: false,
		AllowedOperations:  []string{"AUTHORIZE", "CAPTURE", "REFUND", "VOID", "WEBHOOK_VERIFY"},
		SettlementCurrency: "TRY",
		WebhookRequired:    true,
		AuditEnabled:       true,
	}

	adapter, err := NewProviderAdapter(cfg)
	if err != nil {
		t.Fatalf("expected adapter, got error: %v", err)
	}
	if adapter.Code() != "pix2pi_simulation" {
		t.Fatalf("unexpected provider code: %s", adapter.Code())
	}
	if adapter.Mode() != ModeSimulation {
		t.Fatalf("unexpected provider mode: %s", adapter.Mode())
	}
}

func TestAdapterAllowsSandboxAuthorizeWithTenantAndIdempotency(t *testing.T) {
	adapter := mustAdapter(t, ProviderConfig{
		ProviderName:       "Sandbox Provider",
		ProviderCode:       "sandbox_provider",
		Mode:               "SANDBOX",
		RealPaymentEnabled: false,
		AllowedOperations:  []string{"AUTHORIZE"},
		SettlementCurrency: "TRY",
		WebhookRequired:    true,
		AuditEnabled:       true,
	})

	decision := adapter.Evaluate(validContext(), OperationAuthorize, Money{AmountMinor: 15000, Currency: "TRY"})
	if !decision.Allowed {
		t.Fatalf("expected allowed decision, got reason: %s", decision.Reason)
	}
	if decision.RealPayment {
		t.Fatal("sandbox decision must not be real payment")
	}
	if !decision.AuditRequired {
		t.Fatal("audit must be required")
	}
}

func TestAdapterDeniesProductionWhenRealPaymentGateClosed(t *testing.T) {
	adapter := mustAdapter(t, ProviderConfig{
		ProviderName:       "Production Provider",
		ProviderCode:       "production_provider",
		Mode:               "PRODUCTION",
		RealPaymentEnabled: false,
		AllowedOperations:  []string{"AUTHORIZE"},
		SettlementCurrency: "TRY",
		WebhookRequired:    true,
		AuditEnabled:       true,
	})

	decision := adapter.Evaluate(validContext(), OperationAuthorize, Money{AmountMinor: 15000, Currency: "TRY"})
	if decision.Allowed {
		t.Fatal("production payment must be denied while real payment gate is closed")
	}
	if decision.Reason != "production real payment gate is closed" {
		t.Fatalf("unexpected denial reason: %s", decision.Reason)
	}
}

func TestAdapterDeniesMissingTenant(t *testing.T) {
	adapter := mustAdapter(t, ProviderConfig{
		ProviderName:       "Sandbox Provider",
		ProviderCode:       "sandbox_provider",
		Mode:               "SANDBOX",
		RealPaymentEnabled: false,
		AllowedOperations:  []string{"AUTHORIZE"},
		SettlementCurrency: "TRY",
		WebhookRequired:    true,
		AuditEnabled:       true,
	})

	ctx := validContext()
	ctx.TenantID = ""
	decision := adapter.Evaluate(ctx, OperationAuthorize, Money{AmountMinor: 15000, Currency: "TRY"})
	if decision.Allowed {
		t.Fatal("missing tenant must be denied")
	}
	if decision.Reason != "tenant context is required" {
		t.Fatalf("unexpected reason: %s", decision.Reason)
	}
}

func TestAdapterDeniesUnsupportedOperation(t *testing.T) {
	adapter := mustAdapter(t, ProviderConfig{
		ProviderName:       "Sandbox Provider",
		ProviderCode:       "sandbox_provider",
		Mode:               "SANDBOX",
		RealPaymentEnabled: false,
		AllowedOperations:  []string{"AUTHORIZE"},
		SettlementCurrency: "TRY",
		WebhookRequired:    true,
		AuditEnabled:       true,
	})

	decision := adapter.Evaluate(validContext(), OperationRefund, Money{AmountMinor: 15000, Currency: "TRY"})
	if decision.Allowed {
		t.Fatal("unsupported operation must be denied")
	}
	if decision.Reason != "operation is not allowed for provider" {
		t.Fatalf("unexpected reason: %s", decision.Reason)
	}
}

func TestLoadProviderConfigFromJSON(t *testing.T) {
	raw := []byte(`{
		"provider_name": "Pix2pi Simulation Provider",
		"provider_code": "pix2pi_simulation",
		"mode": "SIMULATION",
		"real_payment_enabled": false,
		"allowed_operations": ["AUTHORIZE", "CAPTURE", "REFUND", "VOID", "WEBHOOK_VERIFY"],
		"settlement_currency": "TRY",
		"webhook_required": true,
		"audit_enabled": true
	}`)

	cfg, err := LoadProviderConfig(raw)
	if err != nil {
		t.Fatalf("expected config to load, got error: %v", err)
	}
	if cfg.ProviderCode != "pix2pi_simulation" {
		t.Fatalf("unexpected provider code: %s", cfg.ProviderCode)
	}
	if _, err := NewProviderAdapter(cfg); err != nil {
		t.Fatalf("expected loaded config to create adapter, got error: %v", err)
	}
}

func validContext() RequestContext {
	return RequestContext{
		TenantID:       "tenant_7",
		SubscriptionID: "sub_demo_001",
		PlanCode:       "pro",
		CorrelationID:  "corr_7_5p_001",
		RequestID:      "req_7_5p_001",
		IdempotencyKey: "idem_7_5p_001",
	}
}

func mustAdapter(t *testing.T, cfg ProviderConfig) *ProviderAdapter {
	t.Helper()
	adapter, err := NewProviderAdapter(cfg)
	if err != nil {
		t.Fatalf("expected adapter, got error: %v", err)
	}
	return adapter
}
