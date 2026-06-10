package notifications

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type createNotificationRowMock struct {
	values []any
	err    error
}

func (r *createNotificationRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case **time.Time:
			if r.values[i] == nil {
				*d = nil
			} else {
				t := r.values[i].(time.Time)
				*d = &t
			}
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type createNotificationQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *createNotificationQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestCreateNotificationSQLStoreCreateNotification_Success(t *testing.T) {
	db := &createNotificationQueryRowProviderMock{
		row: &createNotificationRowMock{
			values: []any{"notif-id-1", "queued", nil, false},
		},
	}

	store := NewCreateNotificationSQLStore(db)

	result, err := store.CreateNotification(context.Background(), CreateNotificationCommand{
		TenantID:        "tenant-a",
		Channel:         "email",
		NotificationKey: "notif-001",
		RecipientRef:    "user_1@example.com",
		Subject:         "Hos geldiniz",
		MessageBody:     "Merhaba",
		Priority:        "high",
		DedupKey:        "welcome-user-1",
		RequestedBy:     "api-gateway",
		Metadata:        map[string]any{"locale": "tr"},
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

	if result.DedupMatched {
		t.Fatalf("beklenen dedup false")
	}

	if !strings.Contains(db.lastQuery, "runtime.notifications") {
		t.Fatalf("notifications query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "dedup_match") {
		t.Fatalf("dedup_match cte query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "inserted_notification") {
		t.Fatalf("inserted_notification cte query icinde olmaliydi")
	}

	if len(db.lastArgs) != 12 {
		t.Fatalf("beklenen 12 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestCreateNotificationSQLStoreCreateNotification_ScheduledSuccess(t *testing.T) {
	scheduledAt := time.Date(2026, 4, 25, 21, 0, 0, 0, time.UTC)

	db := &createNotificationQueryRowProviderMock{
		row: &createNotificationRowMock{
			values: []any{"notif-id-2", "scheduled", scheduledAt, false},
		},
	}

	store := NewCreateNotificationSQLStore(db)

	result, err := store.CreateNotification(context.Background(), CreateNotificationCommand{
		Channel:         "sms",
		NotificationKey: "notif-002",
		RecipientRef:    "905551112233",
		MessageBody:     "Kodunuz hazir",
		Priority:        "normal",
		ScheduledAt:     &scheduledAt,
		RequestedBy:     "api-gateway",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Status != "scheduled" {
		t.Fatalf("beklenen status scheduled, alinan: %s", result.Status)
	}

	if result.ScheduledAt == nil || !result.ScheduledAt.Equal(scheduledAt) {
		t.Fatalf("beklenen scheduled_at korunmaliydi")
	}
}

func TestCreateNotificationSQLStoreCreateNotification_DedupMatched(t *testing.T) {
	db := &createNotificationQueryRowProviderMock{
		row: &createNotificationRowMock{
			values: []any{"notif-existing-1", "queued", nil, true},
		},
	}

	store := NewCreateNotificationSQLStore(db)

	result, err := store.CreateNotification(context.Background(), CreateNotificationCommand{
		TenantID:        "tenant-a",
		Channel:         "email",
		NotificationKey: "notif-003",
		RecipientRef:    "user_1@example.com",
		MessageBody:     "Merhaba tekrar",
		Priority:        "normal",
		DedupKey:        "welcome-user-1",
		RequestedBy:     "api-gateway",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !result.DedupMatched {
		t.Fatalf("beklenen dedup true")
	}

	if result.NotificationID != "notif-existing-1" {
		t.Fatalf("beklenen mevcut notification id notif-existing-1, alinan: %s", result.NotificationID)
	}
}

func TestCreateNotificationSQLStoreCreateNotification_NoDB(t *testing.T) {
	store := NewCreateNotificationSQLStore(nil)

	_, err := store.CreateNotification(context.Background(), CreateNotificationCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestCreateNotificationSQLStoreCreateNotification_ScanError(t *testing.T) {
	db := &createNotificationQueryRowProviderMock{
		row: &createNotificationRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewCreateNotificationSQLStore(db)

	_, err := store.CreateNotification(context.Background(), CreateNotificationCommand{
		Channel:         "email",
		NotificationKey: "notif-001",
		RecipientRef:    "user_1@example.com",
		MessageBody:     "Merhaba",
		Priority:        "high",
		RequestedBy:     "api-gateway",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
