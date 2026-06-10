package webhooks

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type webhookDeliveryRowMock struct {
	values []any
	err    error
}

func (r *webhookDeliveryRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *int:
			*d = r.values[i].(int)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type webhookDeliveryQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *webhookDeliveryQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestDeliverWebhookSQLStoreDeliverWebhook_Success(t *testing.T) {
	db := &webhookDeliveryQueryRowProviderMock{
		row: &webhookDeliveryRowMock{
			values: []any{
				"webhook-001",
				"sub-001",
				"event-001",
				"invoice.created",
				"https://example.com/webhook",
				"sha256-abc123",
				"sending",
				1,
				"event-001-delivery-1",
			},
		},
	}

	store := NewDeliverWebhookSQLStore(db)

	result, err := store.DeliverWebhook(context.Background(), DeliverWebhookCommand{
		TenantID:       "tenant-a",
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "https://example.com/webhook",
		SecretRef:      "secret-001",
		Signature:      "sha256-abc123",
		SignedPayload:  `{"invoice_id":"inv-001"}`,
		Payload:        map[string]any{"invoice_id": "inv-001"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.WebhookID != "webhook-001" {
		t.Fatalf("beklenen webhook_id webhook-001, alinan: %s", result.WebhookID)
	}

	if result.SubscriptionID != "sub-001" {
		t.Fatalf("beklenen subscription_id sub-001, alinan: %s", result.SubscriptionID)
	}

	if result.EventID != "event-001" {
		t.Fatalf("beklenen event_id event-001, alinan: %s", result.EventID)
	}

	if result.EventType != "invoice.created" {
		t.Fatalf("beklenen event_type invoice.created, alinan: %s", result.EventType)
	}

	if result.TargetURL != "https://example.com/webhook" {
		t.Fatalf("beklenen target_url https://example.com/webhook, alinan: %s", result.TargetURL)
	}

	if result.Signature != "sha256-abc123" {
		t.Fatalf("beklenen signature sha256-abc123, alinan: %s", result.Signature)
	}

	if result.Status != "sending" {
		t.Fatalf("beklenen status sending, alinan: %s", result.Status)
	}

	if result.AttemptNo != 1 {
		t.Fatalf("beklenen attempt_no 1, alinan: %d", result.AttemptNo)
	}

	if result.DeliveryRef != "event-001-delivery-1" {
		t.Fatalf("beklenen delivery_ref event-001-delivery-1, alinan: %s", result.DeliveryRef)
	}

	if !strings.Contains(db.lastQuery, "runtime.webhook_deliveries") {
		t.Fatalf("webhook_deliveries query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "signature") {
		t.Fatalf("signature query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "signed_payload") {
		t.Fatalf("signed_payload query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "'sending'") {
		t.Fatalf("sending status query icinde olmaliydi")
	}

	if len(db.lastArgs) != 11 {
		t.Fatalf("beklenen 11 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestDeliverWebhookSQLStoreDeliverWebhook_NoDB(t *testing.T) {
	store := NewDeliverWebhookSQLStore(nil)

	_, err := store.DeliverWebhook(context.Background(), DeliverWebhookCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestDeliverWebhookSQLStoreDeliverWebhook_ScanError(t *testing.T) {
	db := &webhookDeliveryQueryRowProviderMock{
		row: &webhookDeliveryRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewDeliverWebhookSQLStore(db)

	_, err := store.DeliverWebhook(context.Background(), DeliverWebhookCommand{
		TenantID:       "tenant-a",
		WebhookID:      "webhook-001",
		SubscriptionID: "sub-001",
		EventID:        "event-001",
		EventType:      "invoice.created",
		TargetURL:      "https://example.com/webhook",
		SecretRef:      "secret-001",
		Signature:      "sha256-abc123",
		SignedPayload:  `{"invoice_id":"inv-001"}`,
		Payload:        map[string]any{"invoice_id": "inv-001"},
		RequestedBy:    "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
