package notifications

import (
	"context"
	"errors"
	"testing"
	"time"
)

type completeNotificationDeliveryStoreMock struct {
	lastCmd CompleteNotificationDeliveryCommand
	result  CompleteNotificationDeliveryResult
	err     error
	called  bool
}

func (m *completeNotificationDeliveryStoreMock) CompleteNotificationDelivery(_ context.Context, cmd CompleteNotificationDeliveryCommand) (CompleteNotificationDeliveryResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestCompleteNotificationDeliveryRequestValidate_Success(t *testing.T) {
	req := CompleteNotificationDeliveryRequest{
		TenantID:       "tenant-a",
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "sent",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-1",
		ProviderCode:   "smtp-250",
		CompletionNote: "teslim edildi",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestCompleteNotificationDeliveryRequestValidate_InvalidWorkerID(t *testing.T) {
	req := CompleteNotificationDeliveryRequest{
		NotificationID: "notif-id-1",
		WorkerID:       "worker 01",
		Status:         "sent",
		AttemptNo:      1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCompleteNotificationDeliveryRequestValidate_InvalidStatus(t *testing.T) {
	req := CompleteNotificationDeliveryRequest{
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "sending",
		AttemptNo:      1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCompleteNotificationDeliveryRequestValidate_FailedRequiresErrorCode(t *testing.T) {
	req := CompleteNotificationDeliveryRequest{
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "failed",
		AttemptNo:      1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCompleteNotificationDeliveryUsecaseComplete_SentSuccess(t *testing.T) {
	store := &completeNotificationDeliveryStoreMock{
		result: CompleteNotificationDeliveryResult{
			NotificationID: "notif-id-1",
			Status:         "sent",
			AttemptNo:      1,
			DeliveryRef:    "provider-msg-1",
			ProviderCode:   "smtp-250",
			CompletionNote: "teslim edildi",
			LeaseReleased:  true,
		},
	}

	usecase := NewCompleteNotificationDeliveryUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 21, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Complete(context.Background(), CompleteNotificationDeliveryRequest{
		TenantID:       "tenant-a",
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "sent",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-1",
		ProviderCode:   "smtp-250",
		CompletionNote: "teslim edildi",
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

	if resp.Status != "sent" {
		t.Fatalf("beklenen status sent, alinan: %s", resp.Status)
	}

	if !resp.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !resp.CompletedAt.Equal(time.Date(2026, 4, 25, 21, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen completed_at sabit zaman")
	}
}

func TestCompleteNotificationDeliveryUsecaseComplete_FailedSuccess(t *testing.T) {
	store := &completeNotificationDeliveryStoreMock{
		result: CompleteNotificationDeliveryResult{
			NotificationID: "notif-id-2",
			Status:         "failed",
			AttemptNo:      2,
			DeliveryRef:    "provider-msg-2",
			ProviderCode:   "smtp-421",
			ErrorCode:      "SMTP_TIMEOUT",
			CompletionNote: "provider timeout",
			LeaseReleased:  true,
		},
	}

	usecase := NewCompleteNotificationDeliveryUsecase(store)

	resp, err := usecase.Complete(context.Background(), CompleteNotificationDeliveryRequest{
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

	if resp.ErrorCode != "SMTP_TIMEOUT" {
		t.Fatalf("beklenen error_code SMTP_TIMEOUT, alinan: %s", resp.ErrorCode)
	}
}

func TestCompleteNotificationDeliveryUsecaseComplete_ValidationError(t *testing.T) {
	store := &completeNotificationDeliveryStoreMock{}
	usecase := NewCompleteNotificationDeliveryUsecase(store)

	_, err := usecase.Complete(context.Background(), CompleteNotificationDeliveryRequest{
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

func TestCompleteNotificationDeliveryUsecaseComplete_StoreError(t *testing.T) {
	store := &completeNotificationDeliveryStoreMock{
		err: errors.New("complete notification failed"),
	}
	usecase := NewCompleteNotificationDeliveryUsecase(store)

	_, err := usecase.Complete(context.Background(), CompleteNotificationDeliveryRequest{
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "sent",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-1",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestCompleteNotificationDeliveryResponseValidate_InvalidCompletedAt(t *testing.T) {
	resp := CompleteNotificationDeliveryResponse{
		NotificationID: "notif-id-1",
		WorkerID:       "worker-01",
		Status:         "sent",
		AttemptNo:      1,
		DeliveryRef:    "provider-msg-1",
		ProviderCode:   "smtp-250",
		LeaseReleased:  true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
