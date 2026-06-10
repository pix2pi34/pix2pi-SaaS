package opsruntime

import (
	"strings"
	"testing"
)

func TestEmailDeliveryRuntimeDispatchesEmail(t *testing.T) {
	runtime := NewEmailDeliveryRuntime(DefaultEmailDeliveryRuntimeConfig())

	record, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID:       "tenant_7",
		NotificationID: "notification_1",
		To:             []string{"USER@example.com", "user@example.com"},
		Subject:        "Pix2pi Alert",
		Body:           "Service is healthy",
		TemplateID:     "template_health",
		IdempotencyKey: "email_1",
		RequestedBy:    "system",
		CorrelationID:  "corr-email-1",
		Metadata:       map[string]string{"source": "mission_control"},
	})
	if err != nil {
		t.Fatalf("dispatch email failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected email dispatch allowed, got reason=%s", decision.Reason)
	}
	if record.DeliveryID == "" {
		t.Fatal("expected delivery id")
	}
	if record.Provider != EmailDeliveryProviderSimulation {
		t.Fatalf("expected SIMULATION provider, got %s", record.Provider)
	}
	if record.State != EmailDeliveryStateDelivered {
		t.Fatalf("expected DELIVERED dry-run state, got %s", record.State)
	}
	if len(record.To) != 1 {
		t.Fatalf("expected deduplicated recipient count 1, got %d", len(record.To))
	}
	if record.To[0] != "user@example.com" {
		t.Fatalf("expected normalized recipient user@example.com, got %s", record.To[0])
	}
	if record.BodyHash == "" {
		t.Fatal("expected body hash")
	}
	if record.Metadata["source"] != "mission_control" {
		t.Fatalf("expected metadata source mission_control, got %s", record.Metadata["source"])
	}
}

func TestEmailDeliveryRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewEmailDeliveryRuntime(DefaultEmailDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		To:      []string{"user@example.com"},
		Subject: "Subject",
		Body:    "Body",
	})
	if err != ErrEmailDeliveryMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != EmailDeliveryReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestEmailDeliveryRuntimeRejectsMissingRecipient(t *testing.T) {
	runtime := NewEmailDeliveryRuntime(DefaultEmailDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID: "tenant_7",
		Subject:  "Subject",
		Body:     "Body",
	})
	if err != ErrEmailDeliveryMissingRecipient {
		t.Fatalf("expected missing recipient error, got %v", err)
	}
	if decision.Reason != EmailDeliveryReasonMissingRecipient {
		t.Fatalf("expected missing recipient reason, got %s", decision.Reason)
	}
}

func TestEmailDeliveryRuntimeRejectsInvalidRecipient(t *testing.T) {
	runtime := NewEmailDeliveryRuntime(DefaultEmailDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID: "tenant_7",
		To:       []string{"not-an-email"},
		Subject:  "Subject",
		Body:     "Body",
	})
	if err != ErrEmailDeliveryInvalidRecipient {
		t.Fatalf("expected invalid recipient error, got %v", err)
	}
	if decision.Reason != EmailDeliveryReasonInvalidRecipient {
		t.Fatalf("expected invalid recipient reason, got %s", decision.Reason)
	}
}

func TestEmailDeliveryRuntimeRejectsTooManyRecipients(t *testing.T) {
	config := DefaultEmailDeliveryRuntimeConfig()
	config.MaxRecipients = 1
	runtime := NewEmailDeliveryRuntime(config)

	_, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID: "tenant_7",
		To:       []string{"a@example.com", "b@example.com"},
		Subject:  "Subject",
		Body:     "Body",
	})
	if err != ErrEmailDeliveryTooManyRecipients {
		t.Fatalf("expected too many recipients error, got %v", err)
	}
	if decision.Reason != EmailDeliveryReasonTooManyRecipients {
		t.Fatalf("expected too many recipients reason, got %s", decision.Reason)
	}
}

func TestEmailDeliveryRuntimeRejectsMissingSubject(t *testing.T) {
	runtime := NewEmailDeliveryRuntime(DefaultEmailDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID: "tenant_7",
		To:       []string{"user@example.com"},
		Body:     "Body",
	})
	if err != ErrEmailDeliveryMissingSubject {
		t.Fatalf("expected missing subject error, got %v", err)
	}
	if decision.Reason != EmailDeliveryReasonMissingSubject {
		t.Fatalf("expected missing subject reason, got %s", decision.Reason)
	}
}

func TestEmailDeliveryRuntimeRejectsMissingBody(t *testing.T) {
	runtime := NewEmailDeliveryRuntime(DefaultEmailDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID: "tenant_7",
		To:       []string{"user@example.com"},
		Subject:  "Subject",
	})
	if err != ErrEmailDeliveryMissingBody {
		t.Fatalf("expected missing body error, got %v", err)
	}
	if decision.Reason != EmailDeliveryReasonMissingBody {
		t.Fatalf("expected missing body reason, got %s", decision.Reason)
	}
}

func TestEmailDeliveryRuntimeRejectsInvalidProvider(t *testing.T) {
	runtime := NewEmailDeliveryRuntime(DefaultEmailDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID: "tenant_7",
		Provider: "SENDGRID",
		To:       []string{"user@example.com"},
		Subject:  "Subject",
		Body:     "Body",
	})
	if err != ErrEmailDeliveryInvalidProvider {
		t.Fatalf("expected invalid provider error, got %v", err)
	}
	if decision.Reason != EmailDeliveryReasonInvalidProvider {
		t.Fatalf("expected invalid provider reason, got %s", decision.Reason)
	}
}

func TestEmailDeliveryRuntimeRejectsDuplicateIdempotency(t *testing.T) {
	runtime := NewEmailDeliveryRuntime(DefaultEmailDeliveryRuntimeConfig())

	first, _, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID:       "tenant_7",
		To:             []string{"user@example.com"},
		Subject:        "Subject",
		Body:           "Body",
		IdempotencyKey: "email_1",
	})
	if err != nil {
		t.Fatalf("first email dispatch failed: %v", err)
	}

	_, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID:       "tenant_7",
		To:             []string{"user@example.com"},
		Subject:        "Subject",
		Body:           "Body",
		IdempotencyKey: "email_1",
	})
	if err != ErrEmailDeliveryDuplicateIdempotency {
		t.Fatalf("expected duplicate idempotency error, got %v", err)
	}
	if decision.Reason != EmailDeliveryReasonDuplicateIdempotency {
		t.Fatalf("expected duplicate idempotency reason, got %s", decision.Reason)
	}
	if decision.DeliveryID != first.DeliveryID {
		t.Fatalf("expected duplicate decision delivery id %s, got %s", first.DeliveryID, decision.DeliveryID)
	}
}

func TestEmailDeliveryRuntimeIdempotencyIsTenantScoped(t *testing.T) {
	runtime := NewEmailDeliveryRuntime(DefaultEmailDeliveryRuntimeConfig())

	_, _, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID:       "tenant_7",
		To:             []string{"user@example.com"},
		Subject:        "Subject",
		Body:           "Body",
		IdempotencyKey: "email_shared",
	})
	if err != nil {
		t.Fatalf("tenant_7 email dispatch failed: %v", err)
	}

	record, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID:       "tenant_8",
		To:             []string{"user@example.com"},
		Subject:        "Subject",
		Body:           "Body",
		IdempotencyKey: "email_shared",
	})
	if err != nil {
		t.Fatalf("tenant_8 same idempotency should be allowed, got %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected tenant_8 email allowed, got reason=%s", decision.Reason)
	}
	if record.TenantID != "tenant_8" {
		t.Fatalf("expected tenant_8 delivery, got %s", record.TenantID)
	}
}

func TestEmailDeliveryRuntimeTenantSafeAccess(t *testing.T) {
	runtime := NewEmailDeliveryRuntime(DefaultEmailDeliveryRuntimeConfig())

	record, _, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID: "tenant_7",
		To:       []string{"user@example.com"},
		Subject:  "Subject",
		Body:     "Body",
	})
	if err != nil {
		t.Fatalf("dispatch email failed: %v", err)
	}

	got, err := runtime.GetDelivery("tenant_7", record.DeliveryID)
	if err != nil {
		t.Fatalf("get delivery failed: %v", err)
	}
	if got.DeliveryID != record.DeliveryID {
		t.Fatalf("expected delivery id %s, got %s", record.DeliveryID, got.DeliveryID)
	}

	_, err = runtime.GetDelivery("tenant_8", record.DeliveryID)
	if err != ErrEmailDeliveryCrossTenant {
		t.Fatalf("expected cross tenant get delivery error, got %v", err)
	}

	tenantDeliveries, err := runtime.ListTenantDeliveries("tenant_7")
	if err != nil {
		t.Fatalf("list tenant deliveries failed: %v", err)
	}
	if len(tenantDeliveries) != 1 {
		t.Fatalf("expected tenant delivery count 1, got %d", len(tenantDeliveries))
	}

	recipientDeliveries, err := runtime.ListRecipientDeliveries("tenant_7", "USER@example.com")
	if err != nil {
		t.Fatalf("list recipient deliveries failed: %v", err)
	}
	if len(recipientDeliveries) != 1 {
		t.Fatalf("expected recipient delivery count 1, got %d", len(recipientDeliveries))
	}

	tenant8Deliveries, err := runtime.ListTenantDeliveries("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 deliveries failed: %v", err)
	}
	if len(tenant8Deliveries) != 0 {
		t.Fatalf("expected tenant_8 delivery count 0, got %d", len(tenant8Deliveries))
	}
}

func TestEmailDeliveryRuntimeQueuedWhenNotDryRunOnly(t *testing.T) {
	config := DefaultEmailDeliveryRuntimeConfig()
	config.DryRunOnly = false
	runtime := NewEmailDeliveryRuntime(config)

	record, decision, err := runtime.DispatchEmail(EmailDeliveryRequest{
		TenantID: "tenant_7",
		Provider: EmailDeliveryProviderSMTP,
		To:       []string{"user@example.com"},
		Subject:  "Subject",
		Body:     "Body",
	})
	if err != nil {
		t.Fatalf("dispatch email failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected email dispatch allowed, got reason=%s", decision.Reason)
	}
	if record.State != EmailDeliveryStateQueued {
		t.Fatalf("expected QUEUED state when not dry run, got %s", record.State)
	}
}

func TestEmailDeliveryRuntimeIDGenerator(t *testing.T) {
	deliveryID := NewEmailDeliveryID()
	if !strings.HasPrefix(deliveryID, "email_delivery_") {
		t.Fatalf("unexpected delivery id %s", deliveryID)
	}
}
