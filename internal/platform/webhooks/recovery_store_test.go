package webhooks

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"testing"
	"time"
)

type webhookRecoveryRowMock struct {
	values []any
	err    error
}

func (r *webhookRecoveryRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *int:
			*d = r.values[i].(int)
		case *bool:
			*d = r.values[i].(bool)
		case *sql.NullTime:
			switch v := r.values[i].(type) {
			case sql.NullTime:
				*d = v
			case time.Time:
				*d = sql.NullTime{Time: v, Valid: true}
			case nil:
				*d = sql.NullTime{Valid: false}
			default:
				return errors.New("sql.NullTime tipi desteklenmiyor")
			}
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type webhookRecoveryQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *webhookRecoveryQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestApplyWebhookRecoverySQLStoreApplyRecovery_RetrySuccess(t *testing.T) {
	db := &webhookRecoveryQueryRowProviderMock{
		row: &webhookRecoveryRowMock{
			values: []any{
				"webhook-001",
				"event-001-delivery-1",
				"retry",
				"pending",
				0,
				nil,
				true,
			},
		},
	}

	store := NewApplyWebhookRecoverySQLStore(db)

	result, err := store.ApplyRecovery(context.Background(), ApplyWebhookRecoveryCommand{
		TenantID:      "tenant-a",
		WebhookID:     "webhook-001",
		DeliveryRef:   "event-001-delivery-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "gecici hata temizlendi",
		ResetAttempts: true,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.WebhookID != "webhook-001" {
		t.Fatalf("beklenen webhook_id webhook-001, alinan: %s", result.WebhookID)
	}

	if result.DeliveryRef != "event-001-delivery-1" {
		t.Fatalf("beklenen delivery_ref event-001-delivery-1, alinan: %s", result.DeliveryRef)
	}

	if result.ActionType != "retry" {
		t.Fatalf("beklenen action_type retry, alinan: %s", result.ActionType)
	}

	if result.Status != "pending" {
		t.Fatalf("beklenen status pending, alinan: %s", result.Status)
	}

	if result.AttemptNo != 0 {
		t.Fatalf("beklenen attempt_no 0, alinan: %d", result.AttemptNo)
	}

	if result.NextAttemptAt != nil {
		t.Fatalf("retry icin next_attempt_at bos olmaliydi")
	}

	if !result.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !strings.Contains(db.lastQuery, "runtime.webhook_deliveries") {
		t.Fatalf("webhook_deliveries query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lease_expires_at = NULL") {
		t.Fatalf("lease release query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "WHEN $4 = 'dead_letter' THEN 'dead_letter'") {
		t.Fatalf("dead_letter status case query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "WHEN $4 = 'requeue' THEN $8") {
		t.Fatalf("requeue next_attempt_at case query icinde olmaliydi")
	}

	if len(db.lastArgs) != 8 {
		t.Fatalf("beklenen 8 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestApplyWebhookRecoverySQLStoreApplyRecovery_RequeueSuccess(t *testing.T) {
	nextAttemptAt := time.Date(2026, 4, 26, 8, 5, 0, 0, time.UTC)

	db := &webhookRecoveryQueryRowProviderMock{
		row: &webhookRecoveryRowMock{
			values: []any{
				"webhook-002",
				"event-002-delivery-1",
				"requeue",
				"pending",
				2,
				nextAttemptAt,
				true,
			},
		},
	}

	store := NewApplyWebhookRecoverySQLStore(db)

	result, err := store.ApplyRecovery(context.Background(), ApplyWebhookRecoveryCommand{
		WebhookID:     "webhook-002",
		DeliveryRef:   "event-002-delivery-1",
		ActionType:    "requeue",
		RequestedBy:   "worker-02",
		Reason:        "backoff sonrasi tekrar kuyruga al",
		ResetAttempts: false,
		NextAttemptAt: &nextAttemptAt,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Status != "pending" {
		t.Fatalf("beklenen status pending, alinan: %s", result.Status)
	}

	if result.NextAttemptAt == nil || !result.NextAttemptAt.Equal(nextAttemptAt) {
		t.Fatalf("beklenen next_attempt_at korunmaliydi")
	}
}

func TestApplyWebhookRecoverySQLStoreApplyRecovery_DeadLetterSuccess(t *testing.T) {
	db := &webhookRecoveryQueryRowProviderMock{
		row: &webhookRecoveryRowMock{
			values: []any{
				"webhook-003",
				"event-003-delivery-1",
				"dead_letter",
				"dead_letter",
				5,
				nil,
				true,
			},
		},
	}

	store := NewApplyWebhookRecoverySQLStore(db)

	result, err := store.ApplyRecovery(context.Background(), ApplyWebhookRecoveryCommand{
		WebhookID:   "webhook-003",
		DeliveryRef: "event-003-delivery-1",
		ActionType:  "dead_letter",
		RequestedBy: "worker-03",
		Reason:      "kalici hata",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Status != "dead_letter" {
		t.Fatalf("beklenen status dead_letter, alinan: %s", result.Status)
	}

	if result.AttemptNo != 5 {
		t.Fatalf("beklenen attempt_no 5, alinan: %d", result.AttemptNo)
	}
}

func TestApplyWebhookRecoverySQLStoreApplyRecovery_NoDB(t *testing.T) {
	store := NewApplyWebhookRecoverySQLStore(nil)

	_, err := store.ApplyRecovery(context.Background(), ApplyWebhookRecoveryCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestApplyWebhookRecoverySQLStoreApplyRecovery_ScanError(t *testing.T) {
	db := &webhookRecoveryQueryRowProviderMock{
		row: &webhookRecoveryRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewApplyWebhookRecoverySQLStore(db)

	_, err := store.ApplyRecovery(context.Background(), ApplyWebhookRecoveryCommand{
		TenantID:      "tenant-a",
		WebhookID:     "webhook-001",
		DeliveryRef:   "event-001-delivery-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "yeniden dene",
		ResetAttempts: true,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
