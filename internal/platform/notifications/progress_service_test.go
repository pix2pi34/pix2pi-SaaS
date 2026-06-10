package notifications

import (
	"context"
	"errors"
	"testing"
	"time"
)

type updateNotificationDeliveryStoreMock struct {
	lastCmd UpdateNotificationDeliveryCommand
	result  UpdateNotificationDeliveryResult
	err     error
	called  bool
}

func (m *updateNotificationDeliveryStoreMock) UpdateNotificationDelivery(_ context.Context, cmd UpdateNotificationDeliveryCommand) (UpdateNotificationDeliveryResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestUpdateNotificationDeliveryRequestValidate_Success(t *testing.T) {
	req := UpdateNotificationDeliveryRequest{
		TenantID:           "tenant-a",
		NotificationID:     "notif-id-1",
		WorkerID:           "worker-01",
		Status:             "sending",
		AttemptNo:          1,
		DeliveryRef:        "provider-msg-1",
		ProviderCode:       "smtp-250",
		LeaseExtendSeconds: 120,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestUpdateNotificationDeliveryRequestValidate_InvalidWorkerID(t *testing.T) {
	req := UpdateNotificationDeliveryRequest{
		NotificationID:     "notif-id-1",
		WorkerID:           "worker 01",
		Status:             "sending",
		AttemptNo:          1,
		LeaseExtendSeconds: 120,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestUpdateNotificationDeliveryRequestValidate_InvalidStatus(t *testing.T) {
	req := UpdateNotificationDeliveryRequest{
		NotificationID:     "notif-id-1",
		WorkerID:           "worker-01",
		Status:             "queued",
		AttemptNo:          1,
		LeaseExtendSeconds: 120,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestUpdateNotificationDeliveryRequestValidate_FailedRequiresErrorCode(t *testing.T) {
	req := UpdateNotificationDeliveryRequest{
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "failed",
		AttemptNo:      1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestUpdateNotificationDeliveryUsecaseUpdate_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 25, 21, 2, 0, 0, time.UTC)

	store := &updateNotificationDeliveryStoreMock{
		result: UpdateNotificationDeliveryResult{
			NotificationID: "notif-id-1",
			Status:         "sending",
			AttemptNo:      1,
			DeliveryRef:    "provider-msg-1",
			ProviderCode:   "smtp-250",
			LeaseExpiresAt: &leaseExpiresAt,
		},
	}

	usecase := NewUpdateNotificationDeliveryUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 21, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Update(context.Background(), UpdateNotificationDeliveryRequest{
		TenantID:           "tenant-a",
		NotificationID:     "notif-id-1",
		WorkerID:           "worker-01",
		Status:             "sending",
		AttemptNo:          1,
		DeliveryRef:        "provider-msg-1",
		ProviderCode:       "smtp-250",
		LeaseExtendSeconds: 120,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.NotificationID != "notif-id-1" {
		t.Fatalf("beklenen notification_id notif-id-1, alinan: %s", store.lastCmd.NotificationID)
	}

	if resp.NotificationID != "notif-id-1" {
		t.Fatalf("beklenen response notification_id notif-id-1, alinan: %s", resp.NotificationID)
	}

	if resp.Status != "sending" {
		t.Fatalf("beklenen status sending, alinan: %s", resp.Status)
	}

	if resp.LeaseExpiresAt == nil || !resp.LeaseExpiresAt.Equal(leaseExpiresAt) {
		t.Fatalf("beklenen lease_expires_at korunmaliydi")
	}

	if !resp.UpdatedAt.Equal(time.Date(2026, 4, 25, 21, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen updated_at sabit zaman")
	}
}

func TestUpdateNotificationDeliveryUsecaseUpdate_SentWithoutLease(t *testing.T) {
	store := &updateNotificationDeliveryStoreMock{
		result: UpdateNotificationDeliveryResult{
			NotificationID: "notif-id-2",
			Status:         "sent",
			AttemptNo:      1,
			DeliveryRef:    "provider-msg-2",
			ProviderCode:   "smtp-250",
			LeaseExpiresAt: nil,
		},
	}

	usecase := NewUpdateNotificationDeliveryUsecase(store)

	resp, err := usecase.Update(context.Background(), UpdateNotificationDeliveryRequest{
		NotificationID: "notif-id-2",
		WorkerID:       "worker-01",
		Status:         "sent",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-2",
		ProviderCode:   "smtp-250",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.LeaseExpiresAt != nil {
		t.Fatalf("sent durumunda lease_expires_at nil olmaliydi")
	}
}

func TestUpdateNotificationDeliveryUsecaseUpdate_ValidationError(t *testing.T) {
	store := &updateNotificationDeliveryStoreMock{}
	usecase := NewUpdateNotificationDeliveryUsecase(store)

	_, err := usecase.Update(context.Background(), UpdateNotificationDeliveryRequest{
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "failed",
		AttemptNo:      1,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestUpdateNotificationDeliveryUsecaseUpdate_StoreError(t *testing.T) {
	store := &updateNotificationDeliveryStoreMock{
		err: errors.New("update notification delivery failed"),
	}
	usecase := NewUpdateNotificationDeliveryUsecase(store)

	_, err := usecase.Update(context.Background(), UpdateNotificationDeliveryRequest{
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "sent",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-1",
		ProviderCode:   "smtp-250",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestUpdateNotificationDeliveryResponseValidate_InvalidUpdatedAt(t *testing.T) {
	resp := UpdateNotificationDeliveryResponse{
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "sent",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-1",
		ProviderCode:   "smtp-250",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
