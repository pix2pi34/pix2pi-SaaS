package opsruntime

import (
	"strings"
	"testing"
)

func TestSMSPushDeliveryRuntimeDispatchesSMS(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	record, decision, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:       "tenant_7",
		NotificationID: "notification_sms_1",
		PhoneNumbers:   []string{"+90 555 111 2233", "+905551112233"},
		Message:        "Pix2pi SMS alert",
		TemplateID:     "sms_alert",
		IdempotencyKey: "sms_1",
		RequestedBy:    "system",
		CorrelationID:  "corr-sms-1",
		Metadata:       map[string]string{"source": "mission_control"},
	})
	if err != nil {
		t.Fatalf("dispatch sms failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected sms dispatch allowed, got reason=%s", decision.Reason)
	}
	if record.DeliveryID == "" {
		t.Fatal("expected delivery id")
	}
	if record.Channel != SMSPushDeliveryChannelSMS {
		t.Fatalf("expected SMS channel, got %s", record.Channel)
	}
	if record.Provider != SMSPushDeliveryProviderSimulation {
		t.Fatalf("expected SIMULATION provider, got %s", record.Provider)
	}
	if record.State != SMSPushDeliveryStateDelivered {
		t.Fatalf("expected DELIVERED dry-run state, got %s", record.State)
	}
	if len(record.PhoneNumbers) != 1 {
		t.Fatalf("expected deduplicated phone count 1, got %d", len(record.PhoneNumbers))
	}
	if record.PhoneNumbers[0] != "+905551112233" {
		t.Fatalf("expected normalized phone +905551112233, got %s", record.PhoneNumbers[0])
	}
	if record.MessageHash == "" {
		t.Fatal("expected message hash")
	}
	if record.Metadata["source"] != "mission_control" {
		t.Fatalf("expected metadata source mission_control, got %s", record.Metadata["source"])
	}
}

func TestSMSPushDeliveryRuntimeDispatchesPush(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	record, decision, err := runtime.DispatchPush(SMSPushDeliveryRequest{
		TenantID:       "tenant_7",
		NotificationID: "notification_push_1",
		DeviceTokens:   []string{"device-token-123", "device-token-123"},
		Title:          "Pix2pi",
		Message:        "Push alert",
		IdempotencyKey: "push_1",
	})
	if err != nil {
		t.Fatalf("dispatch push failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected push dispatch allowed, got reason=%s", decision.Reason)
	}
	if record.Channel != SMSPushDeliveryChannelPush {
		t.Fatalf("expected PUSH channel, got %s", record.Channel)
	}
	if len(record.DeviceTokens) != 1 {
		t.Fatalf("expected deduplicated token count 1, got %d", len(record.DeviceTokens))
	}
}

func TestSMSPushDeliveryRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		PhoneNumbers: []string{"+905551112233"},
		Message:      "hello",
	})
	if err != ErrSMSPushDeliveryMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != SMSPushDeliveryReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestSMSPushDeliveryRuntimeRejectsInvalidChannel(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	_, decision, err := runtime.Dispatch(SMSPushDeliveryRequest{
		TenantID:     "tenant_7",
		Channel:      "FAX",
		PhoneNumbers: []string{"+905551112233"},
		Message:      "hello",
	})
	if err != ErrSMSPushDeliveryInvalidChannel {
		t.Fatalf("expected invalid channel error, got %v", err)
	}
	if decision.Reason != SMSPushDeliveryReasonInvalidChannel {
		t.Fatalf("expected invalid channel reason, got %s", decision.Reason)
	}
}

func TestSMSPushDeliveryRuntimeRejectsInvalidProvider(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:     "tenant_7",
		Provider:     "WHATSAPP",
		PhoneNumbers: []string{"+905551112233"},
		Message:      "hello",
	})
	if err != ErrSMSPushDeliveryInvalidProvider {
		t.Fatalf("expected invalid provider error, got %v", err)
	}
	if decision.Reason != SMSPushDeliveryReasonInvalidProvider {
		t.Fatalf("expected invalid provider reason, got %s", decision.Reason)
	}
}

func TestSMSPushDeliveryRuntimeRejectsMissingSMSRecipient(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID: "tenant_7",
		Message:  "hello",
	})
	if err != ErrSMSPushDeliveryMissingRecipient {
		t.Fatalf("expected missing recipient error, got %v", err)
	}
	if decision.Reason != SMSPushDeliveryReasonMissingRecipient {
		t.Fatalf("expected missing recipient reason, got %s", decision.Reason)
	}
}

func TestSMSPushDeliveryRuntimeRejectsInvalidPhone(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:     "tenant_7",
		PhoneNumbers: []string{"05551112233"},
		Message:      "hello",
	})
	if err != ErrSMSPushDeliveryInvalidPhone {
		t.Fatalf("expected invalid phone error, got %v", err)
	}
	if decision.Reason != SMSPushDeliveryReasonInvalidPhone {
		t.Fatalf("expected invalid phone reason, got %s", decision.Reason)
	}
}

func TestSMSPushDeliveryRuntimeRejectsInvalidDeviceToken(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchPush(SMSPushDeliveryRequest{
		TenantID:     "tenant_7",
		DeviceTokens: []string{"short"},
		Message:      "hello",
	})
	if err != ErrSMSPushDeliveryInvalidDeviceToken {
		t.Fatalf("expected invalid device token error, got %v", err)
	}
	if decision.Reason != SMSPushDeliveryReasonInvalidDeviceToken {
		t.Fatalf("expected invalid token reason, got %s", decision.Reason)
	}
}

func TestSMSPushDeliveryRuntimeRejectsTooManyRecipients(t *testing.T) {
	config := DefaultSMSPushDeliveryRuntimeConfig()
	config.MaxRecipients = 1
	runtime := NewSMSPushDeliveryRuntime(config)

	_, decision, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:     "tenant_7",
		PhoneNumbers: []string{"+905551112233", "+905551112234"},
		Message:      "hello",
	})
	if err != ErrSMSPushDeliveryTooManyRecipients {
		t.Fatalf("expected too many recipients error, got %v", err)
	}
	if decision.Reason != SMSPushDeliveryReasonTooManyRecipients {
		t.Fatalf("expected too many recipients reason, got %s", decision.Reason)
	}
}

func TestSMSPushDeliveryRuntimeRejectsMissingMessage(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	_, decision, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:     "tenant_7",
		PhoneNumbers: []string{"+905551112233"},
	})
	if err != ErrSMSPushDeliveryMissingMessage {
		t.Fatalf("expected missing message error, got %v", err)
	}
	if decision.Reason != SMSPushDeliveryReasonMissingMessage {
		t.Fatalf("expected missing message reason, got %s", decision.Reason)
	}
}

func TestSMSPushDeliveryRuntimeRejectsDuplicateIdempotency(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	first, _, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:       "tenant_7",
		PhoneNumbers:   []string{"+905551112233"},
		Message:        "hello",
		IdempotencyKey: "sms_1",
	})
	if err != nil {
		t.Fatalf("first sms dispatch failed: %v", err)
	}

	_, decision, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:       "tenant_7",
		PhoneNumbers:   []string{"+905551112233"},
		Message:        "hello",
		IdempotencyKey: "sms_1",
	})
	if err != ErrSMSPushDeliveryDuplicateIdempotency {
		t.Fatalf("expected duplicate idempotency error, got %v", err)
	}
	if decision.Reason != SMSPushDeliveryReasonDuplicateIdempotency {
		t.Fatalf("expected duplicate idempotency reason, got %s", decision.Reason)
	}
	if decision.DeliveryID != first.DeliveryID {
		t.Fatalf("expected duplicate delivery id %s, got %s", first.DeliveryID, decision.DeliveryID)
	}
}

func TestSMSPushDeliveryRuntimeIdempotencyIsTenantAndChannelScoped(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	_, _, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:       "tenant_7",
		PhoneNumbers:   []string{"+905551112233"},
		Message:        "hello",
		IdempotencyKey: "shared",
	})
	if err != nil {
		t.Fatalf("tenant_7 sms dispatch failed: %v", err)
	}

	pushRecord, pushDecision, err := runtime.DispatchPush(SMSPushDeliveryRequest{
		TenantID:       "tenant_7",
		DeviceTokens:   []string{"device-token-123"},
		Message:        "hello",
		IdempotencyKey: "shared",
	})
	if err != nil {
		t.Fatalf("same tenant push same idempotency should be allowed by channel scope, got %v", err)
	}
	if !pushDecision.Allowed {
		t.Fatalf("expected push allowed, got reason=%s", pushDecision.Reason)
	}
	if pushRecord.Channel != SMSPushDeliveryChannelPush {
		t.Fatalf("expected push channel, got %s", pushRecord.Channel)
	}

	tenant8Record, tenant8Decision, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:       "tenant_8",
		PhoneNumbers:   []string{"+905551112233"},
		Message:        "hello",
		IdempotencyKey: "shared",
	})
	if err != nil {
		t.Fatalf("tenant_8 sms same idempotency should be allowed, got %v", err)
	}
	if !tenant8Decision.Allowed {
		t.Fatalf("expected tenant_8 sms allowed, got reason=%s", tenant8Decision.Reason)
	}
	if tenant8Record.TenantID != "tenant_8" {
		t.Fatalf("expected tenant_8 record, got %s", tenant8Record.TenantID)
	}
}

func TestSMSPushDeliveryRuntimeTenantSafeAccess(t *testing.T) {
	runtime := NewSMSPushDeliveryRuntime(DefaultSMSPushDeliveryRuntimeConfig())

	record, _, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:     "tenant_7",
		PhoneNumbers: []string{"+905551112233"},
		Message:      "hello",
	})
	if err != nil {
		t.Fatalf("dispatch sms failed: %v", err)
	}

	got, err := runtime.GetDelivery("tenant_7", record.DeliveryID)
	if err != nil {
		t.Fatalf("get delivery failed: %v", err)
	}
	if got.DeliveryID != record.DeliveryID {
		t.Fatalf("expected delivery id %s, got %s", record.DeliveryID, got.DeliveryID)
	}

	_, err = runtime.GetDelivery("tenant_8", record.DeliveryID)
	if err != ErrSMSPushDeliveryCrossTenant {
		t.Fatalf("expected cross tenant delivery error, got %v", err)
	}

	tenantDeliveries, err := runtime.ListTenantDeliveries("tenant_7")
	if err != nil {
		t.Fatalf("list tenant deliveries failed: %v", err)
	}
	if len(tenantDeliveries) != 1 {
		t.Fatalf("expected tenant delivery count 1, got %d", len(tenantDeliveries))
	}

	channelDeliveries, err := runtime.ListTenantChannelDeliveries("tenant_7", SMSPushDeliveryChannelSMS)
	if err != nil {
		t.Fatalf("list tenant channel deliveries failed: %v", err)
	}
	if len(channelDeliveries) != 1 {
		t.Fatalf("expected tenant channel delivery count 1, got %d", len(channelDeliveries))
	}

	tenant8Deliveries, err := runtime.ListTenantDeliveries("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 deliveries failed: %v", err)
	}
	if len(tenant8Deliveries) != 0 {
		t.Fatalf("expected tenant_8 delivery count 0, got %d", len(tenant8Deliveries))
	}
}

func TestSMSPushDeliveryRuntimeQueuedWhenNotDryRunOnly(t *testing.T) {
	config := DefaultSMSPushDeliveryRuntimeConfig()
	config.DryRunOnly = false
	runtime := NewSMSPushDeliveryRuntime(config)

	record, decision, err := runtime.DispatchSMS(SMSPushDeliveryRequest{
		TenantID:     "tenant_7",
		Provider:     SMSPushDeliveryProviderSMSGateway,
		PhoneNumbers: []string{"+905551112233"},
		Message:      "hello",
	})
	if err != nil {
		t.Fatalf("dispatch sms failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected sms dispatch allowed, got reason=%s", decision.Reason)
	}
	if record.State != SMSPushDeliveryStateQueued {
		t.Fatalf("expected QUEUED state when not dry run, got %s", record.State)
	}
}

func TestSMSPushDeliveryRuntimeIDGenerator(t *testing.T) {
	deliveryID := NewSMSPushDeliveryID()
	if !strings.HasPrefix(deliveryID, "sms_push_delivery_") {
		t.Fatalf("unexpected delivery id %s", deliveryID)
	}
}
