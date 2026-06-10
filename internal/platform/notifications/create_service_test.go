package notifications

import (
	"context"
	"errors"
	"testing"
	"time"
)

type createNotificationStoreMock struct {
	lastCmd CreateNotificationCommand
	result  CreateNotificationResult
	err     error
	called  bool
}

func (m *createNotificationStoreMock) CreateNotification(_ context.Context, cmd CreateNotificationCommand) (CreateNotificationResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestCreateNotificationRequestValidate_Success(t *testing.T) {
	scheduledAt := time.Date(2026, 4, 25, 20, 30, 0, 0, time.UTC)

	req := CreateNotificationRequest{
		TenantID:        "tenant-a",
		Channel:         "email",
		NotificationKey: "notif-001",
		RecipientRef:    "user_1@example.com",
		Subject:         "Hos geldiniz",
		MessageBody:     "Merhaba",
		TemplateRef:     "welcome_email",
		Priority:        "high",
		DedupKey:        "welcome-user-1",
		ScheduledAt:     &scheduledAt,
		RequestedBy:     "api-gateway",
		Metadata:        map[string]any{"locale": "tr"},
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestCreateNotificationRequestValidate_InvalidChannel(t *testing.T) {
	req := CreateNotificationRequest{
		Channel:         "fax",
		NotificationKey: "notif-001",
		RecipientRef:    "user_1@example.com",
		MessageBody:     "Merhaba",
		Priority:        "normal",
		RequestedBy:     "api-gateway",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCreateNotificationRequestValidate_InvalidRecipientRef(t *testing.T) {
	req := CreateNotificationRequest{
		Channel:         "email",
		NotificationKey: "notif-001",
		RecipientRef:    "user 1@example.com",
		MessageBody:     "Merhaba",
		Priority:        "normal",
		RequestedBy:     "api-gateway",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCreateNotificationRequestValidate_MissingContent(t *testing.T) {
	req := CreateNotificationRequest{
		Channel:         "email",
		NotificationKey: "notif-001",
		RecipientRef:    "user_1@example.com",
		Priority:        "normal",
		RequestedBy:     "api-gateway",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCreateNotificationUsecaseCreate_Success(t *testing.T) {
	store := &createNotificationStoreMock{
		result: CreateNotificationResult{
			NotificationID: "notif-id-1",
			Status:         "queued",
			DedupMatched:   false,
		},
	}

	usecase := NewCreateNotificationUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 20, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Create(context.Background(), CreateNotificationRequest{
		TenantID:        "tenant-a",
		Channel:         "email",
		NotificationKey: "notif-001",
		RecipientRef:    "user_1@example.com",
		MessageBody:     "Merhaba",
		Priority:        "high",
		RequestedBy:     "api-gateway",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.Channel != "email" {
		t.Fatalf("beklenen channel email, alinan: %s", store.lastCmd.Channel)
	}

	if resp.NotificationID != "notif-id-1" {
		t.Fatalf("beklenen notification_id notif-id-1, alinan: %s", resp.NotificationID)
	}

	if resp.Status != "queued" {
		t.Fatalf("beklenen status queued, alinan: %s", resp.Status)
	}

	if !resp.EnqueuedAt.Equal(time.Date(2026, 4, 25, 20, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen enqueued_at sabit zaman")
	}
}

func TestCreateNotificationUsecaseCreate_ScheduledDefaultsStatus(t *testing.T) {
	store := &createNotificationStoreMock{
		result: CreateNotificationResult{},
	}

	usecase := NewCreateNotificationUsecase(store)

	scheduledAt := time.Date(2026, 4, 25, 21, 0, 0, 0, time.UTC)
	resp, err := usecase.Create(context.Background(), CreateNotificationRequest{
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

	if resp.Status != "scheduled" {
		t.Fatalf("beklenen status scheduled, alinan: %s", resp.Status)
	}

	if resp.ScheduledAt == nil || !resp.ScheduledAt.Equal(scheduledAt) {
		t.Fatalf("beklenen scheduled_at korunmaliydi")
	}
}

func TestCreateNotificationUsecaseCreate_ValidationError(t *testing.T) {
	store := &createNotificationStoreMock{}
	usecase := NewCreateNotificationUsecase(store)

	_, err := usecase.Create(context.Background(), CreateNotificationRequest{
		Channel:         "email",
		NotificationKey: "notif-001",
		RecipientRef:    "bad recipient",
		MessageBody:     "Merhaba",
		Priority:        "high",
		RequestedBy:     "api-gateway",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestCreateNotificationUsecaseCreate_StoreError(t *testing.T) {
	store := &createNotificationStoreMock{
		err: errors.New("create notification failed"),
	}
	usecase := NewCreateNotificationUsecase(store)

	_, err := usecase.Create(context.Background(), CreateNotificationRequest{
		Channel:         "email",
		NotificationKey: "notif-001",
		RecipientRef:    "user_1@example.com",
		MessageBody:     "Merhaba",
		Priority:        "high",
		RequestedBy:     "api-gateway",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestCreateNotificationResponseValidate_InvalidEnqueuedAt(t *testing.T) {
	resp := CreateNotificationResponse{
		NotificationID:  "notif-id-1",
		Channel:         "email",
		NotificationKey: "notif-001",
		RecipientRef:    "user_1@example.com",
		Priority:        "high",
		Status:          "queued",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
