package notifications

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type deliveryRowMock struct {
	values []any
	err    error
}

func (r *deliveryRowMock) Scan(dest ...any) error {
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

type deliveryQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *deliveryQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestClaimNotificationDeliverySQLStoreClaimNotificationForDelivery_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 25, 20, 31, 0, 0, time.UTC)

	db := &deliveryQueryRowProviderMock{
		row: &deliveryRowMock{
			values: []any{
				"notif-id-1",
				"email",
				"notif-001",
				"user_1@example.com",
				"Hos geldiniz",
				"Merhaba",
				"",
				"high",
				"sending",
				1,
				leaseExpiresAt,
			},
		},
	}

	store := NewClaimNotificationDeliverySQLStore(db)

	result, err := store.ClaimNotificationForDelivery(context.Background(), ClaimNotificationDeliveryCommand{
		TenantID:     "tenant-a",
		Channel:      "email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !result.Claimed {
		t.Fatalf("beklenen claimed true")
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

	if result.LeaseExpiresAt == nil || !result.LeaseExpiresAt.Equal(leaseExpiresAt) {
		t.Fatalf("beklenen lease_expires_at korunmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.notifications") {
		t.Fatalf("notifications query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "candidate_notification") {
		t.Fatalf("candidate_notification cte query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lease_expires_at") {
		t.Fatalf("lease_expires_at query icinde olmaliydi")
	}

	if len(db.lastArgs) != 4 {
		t.Fatalf("beklenen 4 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestClaimNotificationDeliverySQLStoreClaimNotificationForDelivery_NoDB(t *testing.T) {
	store := NewClaimNotificationDeliverySQLStore(nil)

	_, err := store.ClaimNotificationForDelivery(context.Background(), ClaimNotificationDeliveryCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestClaimNotificationDeliverySQLStoreClaimNotificationForDelivery_ScanError(t *testing.T) {
	db := &deliveryQueryRowProviderMock{
		row: &deliveryRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewClaimNotificationDeliverySQLStore(db)

	_, err := store.ClaimNotificationForDelivery(context.Background(), ClaimNotificationDeliveryCommand{
		TenantID:     "tenant-a",
		Channel:      "email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
