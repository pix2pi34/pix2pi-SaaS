package webhooks

import (
	"context"
	"errors"
	"testing"
	"time"
)

type webhookDeliveryStoreMock struct {
	lastCmd DeliverWebhookCommand
	result  DeliverWebhookResult
	err     error
	called  bool
}

func (m *webhookDeliveryStoreMock) DeliverWebhook(_ context.Context, cmd DeliverWebhookCommand) (DeliverWebhookResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestDeliverWebhookRequestValidate_Success(t *testing.T) {
	req := DeliverWebhookRequest{
		TenantID:       "tenant-a",
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "https://example.com/webhook",
		SecretRef:      "secret-001",
		Payload:        map[string]any{"invoice_id": "inv-001"},
		RequestedBy:    "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestDeliverWebhookRequestValidate_InvalidTargetURL(t *testing.T) {
	req := DeliverWebhookRequest{
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "example.com/webhook",
		SecretRef:      "secret-001",
		Payload:        map[string]any{"invoice_id": "inv-001"},
		RequestedBy:    "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestDeliverWebhookRequestValidate_EmptyPayload(t *testing.T) {
	req := DeliverWebhookRequest{
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "https://example.com/webhook",
		SecretRef:      "secret-001",
		Payload:        map[string]any{},
		RequestedBy:    "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestDeliverWebhookRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := DeliverWebhookRequest{
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "https://example.com/webhook",
		SecretRef:      "secret-001",
		Payload:        map[string]any{"invoice_id": "inv-001"},
		RequestedBy:    "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestDeliverWebhookUsecaseDeliver_Success(t *testing.T) {
	store := &webhookDeliveryStoreMock{
		result: DeliverWebhookResult{
			WebhookID:      "webhook-001",
			SubscriptionID: "sub-001",
			EventID:        "event-001",
			EventType:      "invoice.created",
			TargetURL:      "https://example.com/webhook",
			Status:         "sending",
			AttemptNo:      1,
			DeliveryRef:    "delivery-001",
		},
	}

	usecase := NewDeliverWebhookUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 7, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Deliver(context.Background(), DeliverWebhookRequest{
		TenantID:       "tenant-a",
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "https://example.com/webhook",
		SecretRef:      "secret-001",
		Payload:        map[string]any{"invoice_id": "inv-001"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.Signature == "" {
		t.Fatalf("signature bos olmamaliydi")
	}

	if store.lastCmd.SignedPayload == "" {
		t.Fatalf("signed_payload bos olmamaliydi")
	}

	if resp.Status != "sending" {
		t.Fatalf("beklenen status sending, alinan: %s", resp.Status)
	}

	if resp.Signature == "" {
		t.Fatalf("response signature bos olmamaliydi")
	}

	if resp.AttemptNo != 1 {
		t.Fatalf("beklenen attempt_no 1, alinan: %d", resp.AttemptNo)
	}

	if !resp.SignedAt.Equal(time.Date(2026, 4, 26, 7, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen signed_at sabit zaman")
	}
}

func TestDeliverWebhookUsecaseDeliver_ValidationError(t *testing.T) {
	store := &webhookDeliveryStoreMock{}
	usecase := NewDeliverWebhookUsecase(store)

	_, err := usecase.Deliver(context.Background(), DeliverWebhookRequest{
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "example.com/webhook",
		SecretRef:      "secret-001",
		Payload:        map[string]any{"invoice_id": "inv-001"},
		RequestedBy:    "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestDeliverWebhookUsecaseDeliver_StoreError(t *testing.T) {
	store := &webhookDeliveryStoreMock{
		err: errors.New("deliver webhook failed"),
	}
	usecase := NewDeliverWebhookUsecase(store)

	_, err := usecase.Deliver(context.Background(), DeliverWebhookRequest{
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "https://example.com/webhook",
		SecretRef:      "secret-001",
		Payload:        map[string]any{"invoice_id": "inv-001"},
		RequestedBy:    "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestDeliverWebhookResponseValidate_InvalidSignedAt(t *testing.T) {
	resp := DeliverWebhookResponse{
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "https://example.com/webhook",
		Signature:      "sha256-abc123",
		Status:         "sending",
		AttemptNo:      1,
		RequestedBy:    "worker-01",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
