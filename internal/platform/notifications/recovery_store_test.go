package notifications

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type notificationRecoveryRowMock struct {
	values []any
	err    error
}

func (r *notificationRecoveryRowMock) Scan(dest ...any) error {
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

type notificationRecoveryQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *notificationRecoveryQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestRecoverNotificationSQLStoreRecoverNotification_RetrySuccess(t *testing.T) {
	db := &notificationRecoveryQueryRowProviderMock{
		row: &notificationRecoveryRowMock{
			values: []any{"notif-id-1", "queued", "email", 0, true},
		},
	}

	store := NewRecoverNotificationSQLStore(db)

	result, err := store.RecoverNotification(context.Background(), RecoverNotificationCommand{
		TenantID:      "tenant-a",
		NotificationID: "notif-id-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "gecici hata temizlendi",
		ResetAttempts: true,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.NotificationID != "notif-id-1" {
		t.Fatalf("beklenen notification_id notif-id-1, alinan: %s", result.NotificationID)
	}

	if result.Status != "queued" {
		t.Fatalf("beklenen status queued, alinan: %s", result.Status)
	}

	if result.AttemptNo != 0 {
		t.Fatalf("beklenen attempt_no 0, alinan: %d", result.AttemptNo)
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

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestRecoverNotificationSQLStoreRecoverNotification_RequeueSuccess(t *testing.T) {
	db := &notificationRecoveryQueryRowProviderMock{
		row: &notificationRecoveryRowMock{
			values: []any{"notif-id-2", "queued", "sms", 2, true},
		},
	}

	store := NewRecoverNotificationSQLStore(db)

	result, err := store.RecoverNotification(context.Background(), RecoverNotificationCommand{
		TenantID:      "tenant-a",
		NotificationID: "notif-id-2",
		ActionType:    "requeue",
		RequestedBy:   "worker-02",
		TargetChannel: "sms",
		Reason:        "sms kanalina tasindi",
		ResetAttempts: false,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Channel != "sms" {
		t.Fatalf("beklenen channel sms, alinan: %s", result.Channel)
	}
}

func TestRecoverNotificationSQLStoreRecoverNotification_DeadLetterSuccess(t *testing.T) {
	db := &notificationRecoveryQueryRowProviderMock{
		row: &notificationRecoveryRowMock{
			values: []any{"notif-id-3", "dead_letter", "email", 3, true},
		},
	}

	store := NewRecoverNotificationSQLStore(db)

	result, err := store.RecoverNotification(context.Background(), RecoverNotificationCommand{
		TenantID:      "tenant-a",
		NotificationID: "notif-id-3",
		ActionType:    "dead_letter",
		RequestedBy:   "worker-03",
		Reason:        "kalici hata",
		ResetAttempts: false,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Status != "dead_letter" {
		t.Fatalf("beklenen status dead_letter, alinan: %s", result.Status)
	}
}

func TestRecoverNotificationSQLStoreRecoverNotification_NoDB(t *testing.T) {
	store := NewRecoverNotificationSQLStore(nil)

	_, err := store.RecoverNotification(context.Background(), RecoverNotificationCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestRecoverNotificationSQLStoreRecoverNotification_ScanError(t *testing.T) {
	db := &notificationRecoveryQueryRowProviderMock{
		row: &notificationRecoveryRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewRecoverNotificationSQLStore(db)

	_, err := store.RecoverNotification(context.Background(), RecoverNotificationCommand{
		TenantID:      "tenant-a",
		NotificationID: "notif-id-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "yeniden dene",
		ResetAttempts: true,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
