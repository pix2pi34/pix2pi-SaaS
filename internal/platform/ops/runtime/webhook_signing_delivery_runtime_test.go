package opsruntime

import (
	"strings"
	"testing"
)

func TestWebhookSigningDeliveryRuntimeDispatchesWebhook(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	record, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:       "tenant_7",
		WebhookID:      "webhook_1",
		URL:            "https://example.com/webhook",
		EventType:      "order.created",
		Payload:        `{"order_id":"ord_1"}`,
		Secret:         "secret_1",
		IdempotencyKey: "webhook_delivery_1",
		RequestedBy:    "system",
		CorrelationID:  "corr-webhook-1",
		Headers:        map[string]string{"X-Custom": "yes"},
		Metadata:       map[string]string{"source": "notification_runtime"},
	})
	if err != nil {
		t.Fatalf("dispatch webhook failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected webhook allowed, got reason=%s", decision.Reason)
	}
	if record.DeliveryID == "" {
		t.Fatal("expected delivery id")
	}
	if record.Provider != WebhookDeliveryProviderSimulation {
		t.Fatalf("expected SIMULATION provider, got %s", record.Provider)
	}
	if record.Method != WebhookDeliveryMethodPOST {
		t.Fatalf("expected POST method, got %s", record.Method)
	}
	if record.State != WebhookDeliveryStateDelivered {
		t.Fatalf("expected DELIVERED dry-run state, got %s", record.State)
	}
	if record.Signature == "" {
		t.Fatal("expected signature")
	}
	if !strings.HasPrefix(record.SignatureHeader, "sha256=") {
		t.Fatalf("expected sha256 signature header, got %s", record.SignatureHeader)
	}
	if record.Headers["X-Pix2pi-Signature"] != record.SignatureHeader {
		t.Fatal("expected signature header bridge")
	}
	if record.Metadata["source"] != "notification_runtime" {
		t.Fatalf("expected metadata source notification_runtime, got %s", record.Metadata["source"])
	}
}

func TestWebhookSigningDeliveryRuntimeVerifiesSignature(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	payload := `{"ok":true}`
	secret := "secret_1"
	header := BuildWebhookSignatureHeader(BuildWebhookSignature(secret, payload))

	decision, err := runtime.VerifySignature(secret, payload, header)
	if err != nil {
		t.Fatalf("verify signature failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected signature allowed, got reason=%s", decision.Reason)
	}
}

func TestWebhookSigningDeliveryRuntimeRejectsSignatureMismatch(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	decision, err := runtime.VerifySignature("secret_1", `{"ok":true}`, "sha256=bad")
	if err != ErrWebhookDeliverySignatureMismatch {
		t.Fatalf("expected signature mismatch error, got %v", err)
	}
	if decision.Reason != WebhookDeliveryReasonSignatureMismatch {
		t.Fatalf("expected signature mismatch reason, got %s", decision.Reason)
	}
}

func TestWebhookSigningDeliveryRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		URL:       "https://example.com/webhook",
		EventType: "order.created",
		Payload:   "{}",
		Secret:    "secret",
	})
	if err != ErrWebhookDeliveryMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != WebhookDeliveryReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestWebhookSigningDeliveryRuntimeRejectsMissingURL(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:  "tenant_7",
		EventType: "order.created",
		Payload:   "{}",
		Secret:    "secret",
	})
	if err != ErrWebhookDeliveryMissingURL {
		t.Fatalf("expected missing url error, got %v", err)
	}
	if decision.Reason != WebhookDeliveryReasonMissingURL {
		t.Fatalf("expected missing url reason, got %s", decision.Reason)
	}
}

func TestWebhookSigningDeliveryRuntimeRejectsInvalidURL(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:  "tenant_7",
		URL:       "ftp://example.com/webhook",
		EventType: "order.created",
		Payload:   "{}",
		Secret:    "secret",
	})
	if err != ErrWebhookDeliveryInvalidURL {
		t.Fatalf("expected invalid url error, got %v", err)
	}
	if decision.Reason != WebhookDeliveryReasonInvalidURL {
		t.Fatalf("expected invalid url reason, got %s", decision.Reason)
	}
}

func TestWebhookSigningDeliveryRuntimeRejectsInvalidProvider(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:  "tenant_7",
		Provider:  "RABBIT",
		URL:       "https://example.com/webhook",
		EventType: "order.created",
		Payload:   "{}",
		Secret:    "secret",
	})
	if err != ErrWebhookDeliveryInvalidProvider {
		t.Fatalf("expected invalid provider error, got %v", err)
	}
	if decision.Reason != WebhookDeliveryReasonInvalidProvider {
		t.Fatalf("expected invalid provider reason, got %s", decision.Reason)
	}
}

func TestWebhookSigningDeliveryRuntimeRejectsInvalidMethod(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:  "tenant_7",
		Method:    "DELETE",
		URL:       "https://example.com/webhook",
		EventType: "order.created",
		Payload:   "{}",
		Secret:    "secret",
	})
	if err != ErrWebhookDeliveryInvalidMethod {
		t.Fatalf("expected invalid method error, got %v", err)
	}
	if decision.Reason != WebhookDeliveryReasonInvalidMethod {
		t.Fatalf("expected invalid method reason, got %s", decision.Reason)
	}
}

func TestWebhookSigningDeliveryRuntimeRejectsMissingEventType(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID: "tenant_7",
		URL:      "https://example.com/webhook",
		Payload:  "{}",
		Secret:   "secret",
	})
	if err != ErrWebhookDeliveryMissingEventType {
		t.Fatalf("expected missing event type error, got %v", err)
	}
	if decision.Reason != WebhookDeliveryReasonMissingEventType {
		t.Fatalf("expected missing event type reason, got %s", decision.Reason)
	}
}

func TestWebhookSigningDeliveryRuntimeRejectsMissingPayload(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:  "tenant_7",
		URL:       "https://example.com/webhook",
		EventType: "order.created",
		Secret:    "secret",
	})
	if err != ErrWebhookDeliveryMissingPayload {
		t.Fatalf("expected missing payload error, got %v", err)
	}
	if decision.Reason != WebhookDeliveryReasonMissingPayload {
		t.Fatalf("expected missing payload reason, got %s", decision.Reason)
	}
}

func TestWebhookSigningDeliveryRuntimeRejectsMissingSecret(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:  "tenant_7",
		URL:       "https://example.com/webhook",
		EventType: "order.created",
		Payload:   "{}",
	})
	if err != ErrWebhookDeliveryMissingSecret {
		t.Fatalf("expected missing secret error, got %v", err)
	}
	if decision.Reason != WebhookDeliveryReasonMissingSecret {
		t.Fatalf("expected missing secret reason, got %s", decision.Reason)
	}
}

func TestWebhookSigningDeliveryRuntimeRejectsDuplicateIdempotency(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	first, _, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:       "tenant_7",
		URL:            "https://example.com/webhook",
		EventType:      "order.created",
		Payload:        "{}",
		Secret:         "secret",
		IdempotencyKey: "webhook_1",
	})
	if err != nil {
		t.Fatalf("first webhook dispatch failed: %v", err)
	}

	_, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:       "tenant_7",
		URL:            "https://example.com/webhook",
		EventType:      "order.created",
		Payload:        "{}",
		Secret:         "secret",
		IdempotencyKey: "webhook_1",
	})
	if err != ErrWebhookDeliveryDuplicateIdempotency {
		t.Fatalf("expected duplicate idempotency error, got %v", err)
	}
	if decision.Reason != WebhookDeliveryReasonDuplicateIdempotency {
		t.Fatalf("expected duplicate idempotency reason, got %s", decision.Reason)
	}
	if decision.DeliveryID != first.DeliveryID {
		t.Fatalf("expected duplicate delivery id %s, got %s", first.DeliveryID, decision.DeliveryID)
	}
}

func TestWebhookSigningDeliveryRuntimeIdempotencyIsTenantScoped(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	_, _, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:       "tenant_7",
		URL:            "https://example.com/webhook",
		EventType:      "order.created",
		Payload:        "{}",
		Secret:         "secret",
		IdempotencyKey: "shared",
	})
	if err != nil {
		t.Fatalf("tenant_7 webhook dispatch failed: %v", err)
	}

	record, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:       "tenant_8",
		URL:            "https://example.com/webhook",
		EventType:      "order.created",
		Payload:        "{}",
		Secret:         "secret",
		IdempotencyKey: "shared",
	})
	if err != nil {
		t.Fatalf("tenant_8 same idempotency should be allowed, got %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected tenant_8 webhook allowed, got reason=%s", decision.Reason)
	}
	if record.TenantID != "tenant_8" {
		t.Fatalf("expected tenant_8 delivery, got %s", record.TenantID)
	}
}

func TestWebhookSigningDeliveryRuntimeTenantSafeAccess(t *testing.T) {
	runtime := NewWebhookSigningDeliveryRuntime(DefaultWebhookSigningDeliveryRuntimeConfig())

	record, _, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:  "tenant_7",
		URL:       "https://example.com/webhook",
		EventType: "order.created",
		Payload:   "{}",
		Secret:    "secret",
	})
	if err != nil {
		t.Fatalf("dispatch webhook failed: %v", err)
	}

	got, err := runtime.GetDelivery("tenant_7", record.DeliveryID)
	if err != nil {
		t.Fatalf("get delivery failed: %v", err)
	}
	if got.DeliveryID != record.DeliveryID {
		t.Fatalf("expected delivery id %s, got %s", record.DeliveryID, got.DeliveryID)
	}

	_, err = runtime.GetDelivery("tenant_8", record.DeliveryID)
	if err != ErrWebhookDeliveryCrossTenant {
		t.Fatalf("expected cross tenant delivery error, got %v", err)
	}

	tenantDeliveries, err := runtime.ListTenantDeliveries("tenant_7")
	if err != nil {
		t.Fatalf("list tenant deliveries failed: %v", err)
	}
	if len(tenantDeliveries) != 1 {
		t.Fatalf("expected tenant delivery count 1, got %d", len(tenantDeliveries))
	}

	eventDeliveries, err := runtime.ListTenantEventDeliveries("tenant_7", "order.created")
	if err != nil {
		t.Fatalf("list event deliveries failed: %v", err)
	}
	if len(eventDeliveries) != 1 {
		t.Fatalf("expected event delivery count 1, got %d", len(eventDeliveries))
	}

	tenant8Deliveries, err := runtime.ListTenantDeliveries("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 deliveries failed: %v", err)
	}
	if len(tenant8Deliveries) != 0 {
		t.Fatalf("expected tenant_8 delivery count 0, got %d", len(tenant8Deliveries))
	}
}

func TestWebhookSigningDeliveryRuntimeQueuedWhenNotDryRunOnly(t *testing.T) {
	config := DefaultWebhookSigningDeliveryRuntimeConfig()
	config.DryRunOnly = false
	runtime := NewWebhookSigningDeliveryRuntime(config)

	record, decision, err := runtime.DispatchWebhook(WebhookDeliveryRequest{
		TenantID:  "tenant_7",
		Provider:  WebhookDeliveryProviderHTTP,
		Method:    WebhookDeliveryMethodPUT,
		URL:       "https://example.com/webhook",
		EventType: "order.updated",
		Payload:   "{}",
		Secret:    "secret",
	})
	if err != nil {
		t.Fatalf("dispatch webhook failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected webhook allowed, got reason=%s", decision.Reason)
	}
	if record.State != WebhookDeliveryStateQueued {
		t.Fatalf("expected QUEUED when not dry-run, got %s", record.State)
	}
}

func TestWebhookSigningDeliveryRuntimeIDGenerator(t *testing.T) {
	deliveryID := NewWebhookDeliveryID()
	if !strings.HasPrefix(deliveryID, "webhook_delivery_") {
		t.Fatalf("unexpected delivery id %s", deliveryID)
	}
}
