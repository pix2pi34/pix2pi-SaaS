package notifications

import (
	"context"
	"errors"
	"testing"
	"time"
)

type recoverNotificationStoreMock struct {
	lastCmd RecoverNotificationCommand
	result  RecoverNotificationResult
	err     error
	called  bool
}

func (m *recoverNotificationStoreMock) RecoverNotification(_ context.Context, cmd RecoverNotificationCommand) (RecoverNotificationResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestRecoverNotificationRequestValidate_Success(t *testing.T) {
	req := RecoverNotificationRequest{
		TenantID:      "tenant-a",
		NotificationID: "notif-id-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "gecici hata temizlendi",
		ResetAttempts: true,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestRecoverNotificationRequestValidate_InvalidActionType(t *testing.T) {
	req := RecoverNotificationRequest{
		NotificationID: "notif-id-1",
		ActionType:    "resume",
		RequestedBy:   "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRecoverNotificationRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := RecoverNotificationRequest{
		NotificationID: "notif-id-1",
		ActionType:    "retry",
		RequestedBy:   "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRecoverNotificationRequestValidate_RequeueRequiresTargetChannel(t *testing.T) {
	req := RecoverNotificationRequest{
		NotificationID: "notif-id-1",
		ActionType:    "requeue",
		RequestedBy:   "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRecoverNotificationUsecaseRecover_RetrySuccess(t *testing.T) {
	store := &recoverNotificationStoreMock{
		result: RecoverNotificationResult{
			NotificationID: "notif-id-1",
			Status:         "queued",
			Channel:        "email",
			AttemptNo:      0,
			LeaseReleased:  true,
		},
	}

	usecase := NewRecoverNotificationUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Recover(context.Background(), RecoverNotificationRequest{
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

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ActionType != "retry" {
		t.Fatalf("beklenen action_type retry, alinan: %s", store.lastCmd.ActionType)
	}

	if resp.Status != "queued" {
		t.Fatalf("beklenen status queued, alinan: %s", resp.Status)
	}

	if !resp.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !resp.RequestedAt.Equal(time.Date(2026, 4, 25, 22, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen requested_at sabit zaman")
	}
}

func TestRecoverNotificationUsecaseRecover_DeadLetterSuccess(t *testing.T) {
	store := &recoverNotificationStoreMock{
		result: RecoverNotificationResult{
			NotificationID: "notif-id-2",
			Status:         "dead_letter",
			Channel:        "sms",
			AttemptNo:      3,
			LeaseReleased:  true,
		},
	}

	usecase := NewRecoverNotificationUsecase(store)

	resp, err := usecase.Recover(context.Background(), RecoverNotificationRequest{
		NotificationID: "notif-id-2",
		ActionType:    "dead_letter",
		RequestedBy:   "worker-02",
		Reason:        "kalici hata",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Status != "dead_letter" {
		t.Fatalf("beklenen status dead_letter, alinan: %s", resp.Status)
	}
}

func TestRecoverNotificationUsecaseRecover_ValidationError(t *testing.T) {
	store := &recoverNotificationStoreMock{}
	usecase := NewRecoverNotificationUsecase(store)

	_, err := usecase.Recover(context.Background(), RecoverNotificationRequest{
		NotificationID: "",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestRecoverNotificationUsecaseRecover_StoreError(t *testing.T) {
	store := &recoverNotificationStoreMock{
		err: errors.New("recover notification failed"),
	}
	usecase := NewRecoverNotificationUsecase(store)

	_, err := usecase.Recover(context.Background(), RecoverNotificationRequest{
		NotificationID: "notif-id-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestRecoverNotificationResponseValidate_InvalidRequestedAt(t *testing.T) {
	resp := RecoverNotificationResponse{
		NotificationID: "notif-id-1",
		ActionType:    "retry",
		Status:        "queued",
		LeaseReleased: true,
		RequestedBy:   "worker-01",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
