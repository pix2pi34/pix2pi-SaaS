package notifications

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type completeNotificationRowMock struct {
	values []any
	err    error
}

func (r *completeNotificationRowMock) Scan(dest ...any) error {
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
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type completeNotificationQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *completeNotificationQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestCompleteNotificationDeliverySQLStoreCompleteNotificationDelivery_SentSuccess(t *testing.T) {
	db := &completeNotificationQueryRowProviderMock{
		row: &completeNotificationRowMock{
			values: []any{
				"notif-id-1",
				"sent",
				1,
				"provider-msg-1",
				"smtp-250",
				"",
				"teslim edildi",
				true,
			},
		},
	}

	store := NewCompleteNotificationDeliverySQLStore(db)

	result, err := store.CompleteNotificationDelivery(context.Background(), CompleteNotificationDeliveryCommand{
		TenantID:       "tenant-a",
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "sent",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-1",
		ProviderCode:   "smtp-250",
		ErrorCode:      "",
		CompletionNote: "teslim edildi",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.NotificationID != "notif-id-1" {
		t.Fatalf("beklenen notification_id notif-id-1, alinan: %s", result.NotificationID)
	}

	if result.Status != "sent" {
		t.Fatalf("beklenen status sent, alinan: %s", result.Status)
	}

	if result.AttemptNo != 1 {
		t.Fatalf("beklenen attempt_no 1, alinan: %d", result.AttemptNo)
	}

	if result.DeliveryRef != "provider-msg-1" {
		t.Fatalf("beklenen delivery_ref provider-msg-1, alinan: %s", result.DeliveryRef)
	}

	if result.ProviderCode != "smtp-250" {
		t.Fatalf("beklenen provider_code smtp-250, alinan: %s", result.ProviderCode)
	}

	if result.CompletionNote != "teslim edildi" {
		t.Fatalf("beklenen completion_note teslim edildi, alinan: %s", result.CompletionNote)
	}

	if !result.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !strings.Contains(db.lastQuery, "runtime.notifications") {
		t.Fatalf("notifications query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lease_expires_at = NULL") {
		t.Fatalf("lease release query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "coalesce(n.attempt_no, 0) = $5") {
		t.Fatalf("attempt kontrolu query icinde olmaliydi")
	}

	if len(db.lastArgs) != 9 {
		t.Fatalf("beklenen 9 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestCompleteNotificationDeliverySQLStoreCompleteNotificationDelivery_FailedSuccess(t *testing.T) {
	db := &completeNotificationQueryRowProviderMock{
		row: &completeNotificationRowMock{
			values: []any{
				"notif-id-2",
				"failed",
				2,
				"provider-msg-2",
				"smtp-421",
				"SMTP_TIMEOUT",
				"provider timeout",
				true,
			},
		},
	}

	store := NewCompleteNotificationDeliverySQLStore(db)

	result, err := store.CompleteNotificationDelivery(context.Background(), CompleteNotificationDeliveryCommand{
		NotificationID: "notif-id-2",
		WorkerID:       "worker-01",
		Status:         "failed",
		AttemptNo:      2,
		DeliveryRef:    "provider-msg-2",
		ProviderCode:   "smtp-421",
		ErrorCode:      "SMTP_TIMEOUT",
		CompletionNote: "provider timeout",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ErrorCode != "SMTP_TIMEOUT" {
		t.Fatalf("beklenen error_code SMTP_TIMEOUT, alinan: %s", result.ErrorCode)
	}
}

func TestCompleteNotificationDeliverySQLStoreCompleteNotificationDelivery_NoDB(t *testing.T) {
	store := NewCompleteNotificationDeliverySQLStore(nil)

	_, err := store.CompleteNotificationDelivery(context.Background(), CompleteNotificationDeliveryCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestCompleteNotificationDeliverySQLStoreCompleteNotificationDelivery_ScanError(t *testing.T) {
	db := &completeNotificationQueryRowProviderMock{
		row: &completeNotificationRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewCompleteNotificationDeliverySQLStore(db)

	_, err := store.CompleteNotificationDelivery(context.Background(), CompleteNotificationDeliveryCommand{
		TenantID:       "tenant-a",
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "sent",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-1",
		ProviderCode:   "smtp-250",
		CompletionNote: "teslim edildi",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
