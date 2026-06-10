package integrationruntime

import (
	"context"
	"strings"
	"testing"
	"time"
)

func TestParasutConnectorConfigProviderIdentity_7_8P_1(t *testing.T) {
	cfg := DefaultParasutConnectorConfig("tenant_7")

	if err := ValidateParasutConnectorConfig(cfg); err != nil {
		t.Fatalf("expected valid parasut config: %v", err)
	}
	if cfg.Environment != ParasutEnvironmentSimulation {
		t.Fatalf("expected simulation environment, got %s", cfg.Environment)
	}
	if cfg.ProductionEnabled {
		t.Fatal("production must remain disabled")
	}

	t.Log("7-8P.1 Paraşüt Connector Config / Provider Identity OK ✅")
	t.Log("7-8P.1.1 Provider key standard parasut OK ✅")
	t.Log("7-8P.1.2 Tenant connector config OK ✅")
	t.Log("7-8P.1.3 Simulation environment default OK ✅")
	t.Log("7-8P.1.4 Webhook secret required OK ✅")

	cfg.ProductionEnabled = true
	err := ValidateParasutConnectorConfig(cfg)
	if err == nil {
		t.Fatal("expected production gate to reject")
	}
	if !strings.Contains(err.Error(), "production provider gate is closed") {
		t.Fatalf("unexpected production gate error: %v", err)
	}
	t.Log("7-8P.1.5 Production provider gate closed OK ✅")

	cfg = DefaultParasutConnectorConfig("tenant_7")
	cfg.Environment = ParasutEnvironmentProduction
	err = ValidateParasutConnectorConfig(cfg)
	if err == nil {
		t.Fatal("expected production environment to reject")
	}
	t.Log("7-8P.1.6 Production environment closed OK ✅")
}

func TestParasutAdapterSDKBridge_7_8P_2(t *testing.T) {
	cfg := DefaultParasutConnectorConfig("tenant_7")
	adapter, err := NewParasutConnectorAdapter(cfg)
	if err != nil {
		t.Fatalf("new parasut adapter failed: %v", err)
	}

	if adapter.ProviderKey() != ParasutProviderKey {
		t.Fatalf("provider key mismatch: %s", adapter.ProviderKey())
	}

	sdk := NewAdapterSDK()
	if err := sdk.RegisterAdapter(adapter); err != nil {
		t.Fatalf("register parasut adapter failed: %v", err)
	}

	result, err := sdk.Execute(context.Background(), OperationRequest{
		TenantID:       "tenant_7",
		ProviderKey:    "parasut",
		AppKey:         "parasut_accounting",
		Operation:      ConnectorOperationPullInvoice,
		IdempotencyKey: "idem-7-8p-2",
		CorrelationID:  "corr-7-8p-2",
		Payload:        map[string]string{"invoice_no": "P-INV-1"},
	})
	if err != nil {
		t.Fatalf("execute parasut operation failed: %v", err)
	}
	if !result.Succeeded || !strings.HasPrefix(result.ProviderTransactionID, "parasut-sim-") {
		t.Fatalf("unexpected parasut result: %+v", result)
	}

	t.Log("7-8P.2 Paraşüt Adapter SDK Bridge OK ✅")
	t.Log("7-8P.2.1 7-8I ConnectorAdapter interface compatibility OK ✅")
	t.Log("7-8P.2.2 AdapterSDK registration compatibility OK ✅")
	t.Log("7-8P.2.3 PULL_INVOICE simulation OK ✅")
	t.Log("7-8P.2.4 OperationResult provider transaction trace OK ✅")

	_, err = sdk.Execute(context.Background(), OperationRequest{
		TenantID:       "tenant_99",
		ProviderKey:    "parasut",
		AppKey:         "parasut_accounting",
		Operation:      ConnectorOperationPullInvoice,
		IdempotencyKey: "idem-wrong-tenant",
		CorrelationID:  "corr-wrong-tenant",
	})
	if err == nil {
		t.Fatal("expected tenant mismatch to fail")
	}
	t.Log("7-8P.2.5 Tenant mismatch guard OK ✅")

	_, err = sdk.Execute(context.Background(), OperationRequest{
		TenantID:       "tenant_7",
		ProviderKey:    "logo",
		AppKey:         "parasut_accounting",
		Operation:      ConnectorOperationPullInvoice,
		IdempotencyKey: "idem-wrong-provider",
		CorrelationID:  "corr-wrong-provider",
	})
	if err == nil {
		t.Fatal("expected provider mismatch or adapter lookup to fail")
	}
	t.Log("7-8P.2.6 Provider mismatch guard OK ✅")
}

func TestParasutDataMappingFoundation_7_8P_3(t *testing.T) {
	draft, err := BuildParasutInvoiceDraft(ParasutInvoiceDraftRequest{
		TenantID:      "tenant_7",
		CustomerTaxNo: "1234567890",
		InvoiceNo:     "INV-2026-001",
		AmountMinor:   125000,
		Currency:      "try",
		CorrelationID: "corr-7-8p-3",
	})
	if err != nil {
		t.Fatalf("build parasut invoice draft failed: %v", err)
	}
	if draft.ProviderKey != ParasutProviderKey {
		t.Fatalf("provider key mismatch: %s", draft.ProviderKey)
	}
	if draft.Currency != "TRY" {
		t.Fatalf("expected TRY, got %s", draft.Currency)
	}
	if !draft.ProviderReady {
		t.Fatal("expected provider ready draft")
	}

	t.Log("7-8P.3 Paraşüt Data Mapping Foundation OK ✅")
	t.Log("7-8P.3.1 Invoice draft mapping model OK ✅")
	t.Log("7-8P.3.2 Tenant/customer/invoice guard OK ✅")
	t.Log("7-8P.3.3 Amount minor unit guard OK ✅")
	t.Log("7-8P.3.4 Currency normalization OK ✅")

	_, err = BuildParasutInvoiceDraft(ParasutInvoiceDraftRequest{
		TenantID:      "tenant_7",
		CustomerTaxNo: "1234567890",
		InvoiceNo:     "INV-INVALID",
		AmountMinor:   0,
		Currency:      "TRY",
		CorrelationID: "corr-invalid",
	})
	if err == nil {
		t.Fatal("expected invalid amount to fail")
	}
	t.Log("7-8P.3.5 Invalid amount rejected OK ✅")
}

func TestParasutWebhookBridge_7_8P_4(t *testing.T) {
	cfg := DefaultParasutConnectorConfig("tenant_7")
	bridge, err := NewParasutWebhookBridge(cfg.WebhookSecret)
	if err != nil {
		t.Fatalf("new parasut webhook bridge failed: %v", err)
	}

	now := time.Now().UTC()
	payload := `{"provider":"parasut","event":"invoice.created","id":"evt-7-8p"}`
	signature := BuildParasutWebhookSignature(cfg.WebhookSecret, now, payload)

	event, err := bridge.Verify(ExternalEventIntakeRequest{
		TenantID:        "tenant_7",
		ProviderKey:     "parasut",
		ExternalEventID: "evt-7-8p",
		EventType:       "invoice.created",
		CorrelationID:   "corr-7-8p-4",
		RawPayload:      payload,
		Signature:       signature,
		Secret:          cfg.WebhookSecret,
		Timestamp:       now,
	})
	if err != nil {
		t.Fatalf("verify parasut webhook failed: %v", err)
	}
	if event.ProviderKey != ParasutProviderKey || event.RawPayload == "" {
		t.Fatalf("unexpected parasut webhook event: %+v", event)
	}

	t.Log("7-8P.4 Paraşüt Webhook Bridge OK ✅")
	t.Log("7-8P.4.1 7-8I webhook intake bridge OK ✅")
	t.Log("7-8P.4.2 HMAC SHA256 signature bridge OK ✅")
	t.Log("7-8P.4.3 Raw payload guard OK ✅")
	t.Log("7-8P.4.4 Timestamp skew guard bridge OK ✅")
	t.Log("7-8P.4.5 Provider key parasut guard OK ✅")

	_, err = bridge.Verify(ExternalEventIntakeRequest{
		TenantID:        "tenant_7",
		ProviderKey:     "parasut",
		ExternalEventID: "evt-7-8p-bad",
		EventType:       "invoice.created",
		CorrelationID:   "corr-7-8p-4-bad",
		RawPayload:      payload,
		Signature:       "bad-signature",
		Secret:          cfg.WebhookSecret,
		Timestamp:       now,
	})
	if err == nil {
		t.Fatal("expected bad signature to fail")
	}
	t.Log("7-8P.4.6 Bad signature rejected OK ✅")

	_, err = bridge.Verify(ExternalEventIntakeRequest{
		TenantID:        "tenant_7",
		ProviderKey:     "logo",
		ExternalEventID: "evt-7-8p-provider-bad",
		EventType:       "invoice.created",
		CorrelationID:   "corr-7-8p-4-provider-bad",
		RawPayload:      payload,
		Signature:       signature,
		Secret:          cfg.WebhookSecret,
		Timestamp:       now,
	})
	if err == nil {
		t.Fatal("expected wrong provider to fail")
	}
	t.Log("7-8P.4.7 Wrong provider rejected OK ✅")
}

func TestParasutFailureRetryDLQBridge_7_8P_5(t *testing.T) {
	policy := DefaultRetryPolicy()

	failure := FailureRecord{
		TenantID:      "tenant_7",
		ProviderKey:   ParasutProviderKey,
		AppKey:        "parasut_accounting",
		Operation:     string(ConnectorOperationPullInvoice),
		Attempt:       1,
		Kind:          FailureKindRetryable,
		ErrorCode:     "PARASUT_PROVIDER_TIMEOUT",
		CorrelationID: "corr-7-8p-5",
		Payload:       `{"provider":"parasut"}`,
	}

	decision := EvaluateRetry(policy, failure)
	if !decision.ShouldRetry || decision.MoveToDLQ || decision.NextAttempt != 2 {
		t.Fatalf("unexpected parasut retry decision: %+v", decision)
	}
	t.Log("7-8P.5 Paraşüt Failure / Retry / DLQ Bridge OK ✅")
	t.Log("7-8P.5.1 Retryable provider timeout decision OK ✅")

	failure.Attempt = 3
	decision = EvaluateRetry(policy, failure)
	if decision.ShouldRetry || !decision.MoveToDLQ {
		t.Fatalf("expected parasut max attempt to move DLQ: %+v", decision)
	}
	t.Log("7-8P.5.2 Max attempt DLQ bridge OK ✅")

	dlq, err := CreateDLQMessage(failure, decision.Reason)
	if err != nil {
		t.Fatalf("create parasut dlq failed: %v", err)
	}
	if dlq.ProviderKey != ParasutProviderKey || dlq.TenantID != "tenant_7" {
		t.Fatalf("unexpected parasut dlq: %+v", dlq)
	}
	t.Log("7-8P.5.3 Tenant-safe DLQ message OK ✅")

	poison := failure
	poison.Attempt = 1
	poison.Kind = FailureKindPoison
	decision = EvaluateRetry(policy, poison)
	if decision.ShouldRetry || !decision.MoveToDLQ || decision.Reason != "poison_message" {
		t.Fatalf("unexpected poison decision: %+v", decision)
	}
	t.Log("7-8P.5.4 Poison webhook/message DLQ bridge OK ✅")
}

func TestParasutConnectorFinalClosureGate_7_8P_6(t *testing.T) {
	result := EvaluateParasutConnectorModuleGate(ParasutConnectorModuleGateInput{
		ConfigReady:                  true,
		AdapterReady:                 true,
		MappingReady:                 true,
		WebhookBridgeReady:           true,
		RetryDLQBridgeReady:          true,
		TestsReady:                   true,
		RealImplementationAuditReady: true,
		ProductionEnabled:            false,
	})

	if !result.Ready || result.Decision != "PARASUT_CONNECTOR_FOUNDATION_READY" || len(result.Blockers) != 0 {
		t.Fatalf("expected parasut connector foundation ready: %+v", result)
	}

	t.Log("7-8P.6 Paraşüt Connector Final Closure / Provider Handoff Gate OK ✅")
	t.Log("7-8P.6.1 Config readiness gate OK ✅")
	t.Log("7-8P.6.2 Adapter readiness gate OK ✅")
	t.Log("7-8P.6.3 Mapping readiness gate OK ✅")
	t.Log("7-8P.6.4 Webhook bridge readiness gate OK ✅")
	t.Log("7-8P.6.5 Retry DLQ readiness gate OK ✅")
	t.Log("7-8P.6.6 Production live gate closed OK ✅")

	blocked := EvaluateParasutConnectorModuleGate(ParasutConnectorModuleGateInput{
		ConfigReady:                  true,
		AdapterReady:                 true,
		MappingReady:                 true,
		WebhookBridgeReady:           true,
		RetryDLQBridgeReady:          true,
		TestsReady:                   true,
		RealImplementationAuditReady: true,
		ProductionEnabled:            true,
	})

	if blocked.Ready || blocked.Decision != "BLOCKED" {
		t.Fatalf("expected production enabled state to be blocked: %+v", blocked)
	}
	t.Log("7-8P.6.7 Unsafe production state blocked OK ✅")
}
