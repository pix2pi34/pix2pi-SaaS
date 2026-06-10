package notifications

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type notificationProgressRowMock struct {
	values []any
	err    error
}

func (r *notificationProgressRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *int:
			*d = r.values[i].(int)
		case *time.Time:
			*d = r.values[i].(time.Time)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type notificationProgressQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *notificationProgressQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestUpdateNotificationDeliverySQLStoreUpdateNotificationDelivery_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 25, 21, 2, 0, 0, time.UTC)

	db := &notificationProgressQueryRowProviderMock{
		row: &notificationProgressRowMock{
			values: []any{
				"notif-id-1",
				"sending",
				1,
				"provider-msg-1",
				"smtp-250",
				"",
				leaseExpiresAt,
			},
		},
	}

	store := NewUpdateNotificationDeliverySQLStore(db)

	result, err := store.UpdateNotificationDelivery(context.Background(), UpdateNotificationDeliveryCommand{
		TenantID:           "tenant-a",
		NotificationID:     "notif-id-1",
		WorkerID:           "worker-01",
		Status:             "sending",
		AttemptNo:          1,
		DeliveryRef:        "provider-msg-1",
		ProviderCode:       "smtp-250",
		ErrorCode:          "",
		LeaseExtendSeconds: 120,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.NotificationID != "notif-id-1" {
		t.Fatalf("beklenen notification_id notif-id-1, alinan: %s", result.NotificationID)
	}

	if result.Status != "sending" {
		t.Fatalf("beklenen status sending, alinan: %s", result.Status)
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

	if result.LeaseExpiresAt == nil || !result.LeaseExpiresAt.Equal(leaseExpiresAt) {
		t.Fatalf("beklenen lease_expires_at korunmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.notifications") {
		t.Fatalf("notifications query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lease_expires_at") {
		t.Fatalf("lease_expires_at query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "coalesce(n.attempt_no, 0) = $5") {
		t.Fatalf("attempt kontrolu query icinde olmaliydi")
	}

	if len(db.lastArgs) != 9 {
		t.Fatalf("beklenen 9 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestUpdateNotificationDeliverySQLStoreUpdateNotificationDelivery_SentSuccess(t *testing.T) {
	zeroLease := time.Time{}

	db := &notificationProgressQueryRowProviderMock{
		row: &notificationProgressRowMock{
			values: []any{
				"notif-id-2",
				"sent",
				1,
				"provider-msg-2",
				"smtp-250",
				"",
				zeroLease,
			},
		},
	}

	store := NewUpdateNotificationDeliverySQLStore(db)

	result, err := store.UpdateNotificationDelivery(context.Background(), UpdateNotificationDeliveryCommand{
		NotificationID:     "notif-id-2",
		WorkerID:           "worker-01",
		Status:             "sent",
		AttemptNo:          1,
		DeliveryRef:        "provider-msg-2",
		ProviderCode:       "smtp-250",
		LeaseExtendSeconds: 0,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Status != "sent" {
		t.Fatalf("beklenen status sent, alinan: %s", result.Status)
	}

	if result.LeaseExpiresAt != nil {
		t.Fatalf("sent durumunda lease_expires_at nil olmaliydi")
	}
}

func TestUpdateNotificationDeliverySQLStoreUpdateNotificationDelivery_NoDB(t *testing.T) {
	store := NewUpdateNotificationDeliverySQLStore(nil)

	_, err := store.UpdateNotificationDelivery(context.Background(), UpdateNotificationDeliveryCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestUpdateNotificationDeliverySQLStoreUpdateNotificationDelivery_ScanError(t *testing.T) {
	db := &notificationProgressQueryRowProviderMock{
		row: &notificationProgressRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewUpdateNotificationDeliverySQLStore(db)

	_, err := store.UpdateNotificationDelivery(context.Background(), UpdateNotificationDeliveryCommand{
		TenantID:           "tenant-a",
		NotificationID:     "notif-id-1",
		WorkerID:           "worker-01",
		Status:             "failed",
		AttemptNo:          1,
		ErrorCode:          "SMTP_TIMEOUT",
		LeaseExtendSeconds: 0,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
