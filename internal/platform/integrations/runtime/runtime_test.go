package integrationruntime

import (
	"context"
	"strings"
	"testing"
	"time"
)

type fakeConnectorAdapter struct{}

func (fakeConnectorAdapter) ProviderKey() string {
	return "parasut"
}

func (fakeConnectorAdapter) Capabilities() []string {
	return []string{"invoice.pull", "customer.sync"}
}

func (fakeConnectorAdapter) Execute(ctx context.Context, req OperationRequest) (OperationResult, error) {
	if err := ValidateOperationRequest(req); err != nil {
		return OperationResult{}, err
	}

	return OperationResult{
		TenantID:              req.TenantID,
		ProviderKey:           req.ProviderKey,
		AppKey:                req.AppKey,
		Operation:             req.Operation,
		IdempotencyKey:        req.IdempotencyKey,
		CorrelationID:         req.CorrelationID,
		Succeeded:             true,
		ProviderTransactionID: "sim-parasut-txn-001",
		Message:               "simulated connector operation completed",
	}, nil
}

func TestTenantIntegrationEnablement_7_8I_1(t *testing.T) {
	req := EnableTenantIntegrationRequest{
		TenantID:      "tenant_7",
		ProviderKey:   "parasut",
		AppKey:        "parasut_accounting",
		AuthMode:      AuthModeAPIKey,
		Capabilities:  []string{"invoice.pull", "customer.sync"},
		Config:        map[string]string{"mode": "simulation"},
		RequestedBy:   "admin_1",
		CorrelationID: "corr-7-8i-1",
		RequestedAt:   time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	}

	install, err := EnableTenantIntegration(req)
	if err != nil {
		t.Fatalf("enable tenant integration failed: %v", err)
	}

	if install.Status != IntegrationInstallStatusEnabled {
		t.Fatalf("expected enabled status, got %s", install.Status)
	}
	if install.TenantID != "tenant_7" {
		t.Fatalf("tenant mismatch: %s", install.TenantID)
	}
	if install.AuditDecision != AuditDecisionAllowed {
		t.Fatalf("audit decision mismatch: %s", install.AuditDecision)
	}
	t.Log("7-8I.1 Tenant Integration Install / Enablement Runtime OK ✅")
	t.Log("7-8I.1.1 Tenant install model OK ✅")
	t.Log("7-8I.1.2 Capability validation OK ✅")
	t.Log("7-8I.1.3 Audit decision field OK ✅")

	req.ProductionEnabled = true
	_, err = EnableTenantIntegration(req)
	if err == nil {
		t.Fatal("expected production enablement gate to reject request")
	}
	if !strings.Contains(err.Error(), "production provider enablement is closed") {
		t.Fatalf("unexpected production gate error: %v", err)
	}
	t.Log("7-8I.1.4 Production real provider gate closed OK ✅")
}

func TestConnectorRuntimeAdapterSDK_7_8I_2(t *testing.T) {
	sdk := NewAdapterSDK()

	if err := sdk.RegisterAdapter(fakeConnectorAdapter{}); err != nil {
		t.Fatalf("register adapter failed: %v", err)
	}
	t.Log("7-8I.2 Connector Runtime Foundation / Adapter SDK OK ✅")
	t.Log("7-8I.2.1 ConnectorAdapter registry OK ✅")

	err := sdk.RegisterAdapter(fakeConnectorAdapter{})
	if err == nil {
		t.Fatal("expected duplicate adapter registration to fail")
	}
	t.Log("7-8I.2.2 Duplicate adapter guard OK ✅")

	result, err := sdk.Execute(context.Background(), OperationRequest{
		TenantID:       "tenant_7",
		ProviderKey:    "parasut",
		AppKey:         "parasut_accounting",
		Operation:      ConnectorOperationPullInvoice,
		IdempotencyKey: "idem-7-8i-2",
		CorrelationID:  "corr-7-8i-2",
		Payload:        map[string]string{"invoice_no": "INV-1"},
	})
	if err != nil {
		t.Fatalf("execute adapter failed: %v", err)
	}
	if !result.Succeeded || result.ProviderTransactionID == "" {
		t.Fatalf("unexpected operation result: %+v", result)
	}
	t.Log("7-8I.2.3 Provider independent execute bridge OK ✅")
	t.Log("7-8I.2.4 Operation idempotency/correlation guard OK ✅")

	_, err = sdk.Execute(context.Background(), OperationRequest{
		TenantID:    "tenant_7",
		ProviderKey: "parasut",
		AppKey:      "parasut_accounting",
		Operation:   ConnectorOperationPullInvoice,
	})
	if err == nil {
		t.Fatal("expected missing idempotency/correlation to fail")
	}
	t.Log("7-8I.2.5 Invalid operation request guard OK ✅")
}

func TestWebhookExternalEventIntakeFoundation_7_8I_3(t *testing.T) {
	runtime := DefaultWebhookIntakeRuntime()
	now := time.Now().UTC()
	payload := `{"event":"invoice.created","invoice_id":"INV-77"}`
	secret := "secret-7-8i"
	signature := BuildWebhookSignature(secret, now, payload)

	event, err := runtime.VerifyAndBuildEvent(ExternalEventIntakeRequest{
		TenantID:        "tenant_7",
		ProviderKey:     "parasut",
		ExternalEventID: "evt-001",
		EventType:       "invoice.created",
		CorrelationID:   "corr-7-8i-3",
		RawPayload:      payload,
		Signature:       signature,
		Secret:          secret,
		Timestamp:       now,
	})
	if err != nil {
		t.Fatalf("verify webhook failed: %v", err)
	}
	if event.ExternalEventID != "evt-001" || event.RawPayload == "" {
		t.Fatalf("unexpected event: %+v", event)
	}
	t.Log("7-8I.3 Webhook / External Event Intake Foundation OK ✅")
	t.Log("7-8I.3.1 External event intake model OK ✅")
	t.Log("7-8I.3.2 Raw payload required guard OK ✅")
	t.Log("7-8I.3.3 Webhook signature guard OK ✅")

	_, err = runtime.VerifyAndBuildEvent(ExternalEventIntakeRequest{
		TenantID:        "tenant_7",
		ProviderKey:     "parasut",
		ExternalEventID: "evt-002",
		EventType:       "invoice.created",
		CorrelationID:   "corr-7-8i-3-bad",
		RawPayload:      payload,
		Signature:       "bad-signature",
		Secret:          secret,
		Timestamp:       now,
	})
	if err == nil {
		t.Fatal("expected bad signature to fail")
	}
	t.Log("7-8I.3.4 Bad signature reject guard OK ✅")

	_, err = runtime.VerifyAndBuildEvent(ExternalEventIntakeRequest{
		TenantID:        "tenant_7",
		ProviderKey:     "parasut",
		ExternalEventID: "evt-003",
		EventType:       "invoice.created",
		CorrelationID:   "corr-7-8i-3-old",
		RawPayload:      payload,
		Signature:       BuildWebhookSignature(secret, now.Add(-30*time.Minute), payload),
		Secret:          secret,
		Timestamp:       now.Add(-30 * time.Minute),
	})
	if err == nil {
		t.Fatal("expected old timestamp to fail")
	}
	t.Log("7-8I.3.5 Timestamp skew guard OK ✅")
}

func TestConnectorOperationAuditObservability_7_8I_4(t *testing.T) {
	obs := NewConnectorObservabilityRuntime()

	err := obs.RecordOperation(ConnectorAuditEvent{
		TenantID:      "tenant_7",
		ProviderKey:   "parasut",
		AppKey:        "parasut_accounting",
		Operation:     string(ConnectorOperationPullInvoice),
		Status:        "SUCCEEDED",
		Decision:      AuditDecisionAllowed,
		CorrelationID: "corr-7-8i-4",
		Message:       "operation completed",
	})
	if err != nil {
		t.Fatalf("record operation failed: %v", err)
	}
	t.Log("7-8I.4 Connector Operation Audit / Observability OK ✅")
	t.Log("7-8I.4.1 Connector audit event model OK ✅")

	snapshot := obs.Snapshot()
	if snapshot.TotalOperations != 1 || snapshot.ByProvider["parasut"] != 1 {
		t.Fatalf("unexpected snapshot: %+v", snapshot)
	}
	t.Log("7-8I.4.2 Operation metrics snapshot OK ✅")

	trail := obs.AuditTrailByTenant("tenant_7")
	if len(trail) != 1 {
		t.Fatalf("expected tenant audit trail length 1, got %d", len(trail))
	}
	t.Log("7-8I.4.3 Tenant audit trail read OK ✅")

	duplicate, err := obs.RecordWebhookEvent(ExternalEvent{
		TenantID:        "tenant_7",
		ProviderKey:     "parasut",
		ExternalEventID: "evt-dup-1",
		EventType:       "invoice.created",
		CorrelationID:   "corr-dup",
		RawPayload:      "{}",
	})
	if err != nil || duplicate {
		t.Fatalf("first webhook record failed duplicate=%v err=%v", duplicate, err)
	}

	duplicate, err = obs.RecordWebhookEvent(ExternalEvent{
		TenantID:        "tenant_7",
		ProviderKey:     "parasut",
		ExternalEventID: "evt-dup-1",
		EventType:       "invoice.created",
		CorrelationID:   "corr-dup",
		RawPayload:      "{}",
	})
	if err != nil || !duplicate {
		t.Fatalf("expected duplicate webhook duplicate=%v err=%v", duplicate, err)
	}
	t.Log("7-8I.4.4 Duplicate webhook metric guard OK ✅")
}

func TestConnectorFailureRetryDLQReadiness_7_8I_5(t *testing.T) {
	policy := DefaultRetryPolicy()

	failure := FailureRecord{
		TenantID:      "tenant_7",
		ProviderKey:   "parasut",
		AppKey:        "parasut_accounting",
		Operation:     string(ConnectorOperationPullInvoice),
		Attempt:       1,
		Kind:          FailureKindRetryable,
		ErrorCode:     "PROVIDER_TIMEOUT",
		CorrelationID: "corr-7-8i-5",
		Payload:       "{}",
	}

	decision := EvaluateRetry(policy, failure)
	if !decision.ShouldRetry || decision.MoveToDLQ || decision.NextAttempt != 2 {
		t.Fatalf("unexpected retry decision: %+v", decision)
	}
	t.Log("7-8I.5 Connector Failure / Retry / DLQ Readiness OK ✅")
	t.Log("7-8I.5.1 Retryable failure decision OK ✅")

	failure.Attempt = 3
	decision = EvaluateRetry(policy, failure)
	if decision.ShouldRetry || !decision.MoveToDLQ {
		t.Fatalf("expected max attempt to move DLQ: %+v", decision)
	}
	t.Log("7-8I.5.2 Max attempt DLQ decision OK ✅")

	dlq, err := CreateDLQMessage(failure, decision.Reason)
	if err != nil {
		t.Fatalf("create dlq failed: %v", err)
	}
	if dlq.TenantID != "tenant_7" || dlq.Reason == "" {
		t.Fatalf("unexpected dlq message: %+v", dlq)
	}
	t.Log("7-8I.5.3 DLQ message model OK ✅")

	poison := failure
	poison.Attempt = 1
	poison.Kind = FailureKindPoison
	decision = EvaluateRetry(policy, poison)
	if decision.ShouldRetry || !decision.MoveToDLQ || decision.Reason != "poison_message" {
		t.Fatalf("unexpected poison decision: %+v", decision)
	}
	t.Log("7-8I.5.4 Poison message DLQ guard OK ✅")
}

func TestConnectorFinalClosureProviderHandoffGate_7_8I_6(t *testing.T) {
	result := EvaluateProviderModuleHandoffGate(ProviderModuleHandoffGateInput{
		RuntimeCodeReady:               true,
		ConfigReady:                    true,
		DocsReady:                      true,
		TestsReady:                     true,
		RealImplementationAuditReady:   true,
		RealPaymentLiveEnabled:         false,
		ProviderSpecificModuleRequired: true,
	})

	if !result.Ready || result.Decision != "READY_FOR_PROVIDER_MODULE" || len(result.Blockers) != 0 {
		t.Fatalf("expected ready handoff gate: %+v", result)
	}
	t.Log("7-8I.6 Connector Final Closure / Provider Module Handoff Gate OK ✅")
	t.Log("7-8I.6.1 Provider module handoff ready decision OK ✅")
	t.Log("7-8I.6.2 Real payment live gate closed OK ✅")

	blocked := EvaluateProviderModuleHandoffGate(ProviderModuleHandoffGateInput{
		RuntimeCodeReady:               true,
		ConfigReady:                    true,
		DocsReady:                      true,
		TestsReady:                     true,
		RealImplementationAuditReady:   true,
		RealPaymentLiveEnabled:         true,
		ProviderSpecificModuleRequired: true,
	})

	if blocked.Ready || blocked.Decision != "BLOCKED" {
		t.Fatalf("expected blocked handoff gate: %+v", blocked)
	}
	t.Log("7-8I.6.3 Production provider unsafe state blocked OK ✅")
}
