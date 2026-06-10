package webhooks

import (
	"context"
	"errors"
	"testing"
	"time"
)

type webhookRecoveryStoreMock struct {
	lastCmd ApplyWebhookRecoveryCommand
	result  ApplyWebhookRecoveryResult
	err     error
	called  bool
}

func (m *webhookRecoveryStoreMock) ApplyRecovery(_ context.Context, cmd ApplyWebhookRecoveryCommand) (ApplyWebhookRecoveryResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestApplyWebhookRecoveryRequestValidate_Success(t *testing.T) {
	req := ApplyWebhookRecoveryRequest{
		TenantID:      "tenant-a",
		WebhookID:     "webhook-001",
		DeliveryRef:   "event-001-delivery-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "gecici hata temizlendi",
		ResetAttempts: true,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestApplyWebhookRecoveryRequestValidate_InvalidActionType(t *testing.T) {
	req := ApplyWebhookRecoveryRequest{
		WebhookID:   "webhook-001",
		DeliveryRef: "event-001-delivery-1",
		ActionType:  "resume",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyWebhookRecoveryRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := ApplyWebhookRecoveryRequest{
		WebhookID:   "webhook-001",
		DeliveryRef: "event-001-delivery-1",
		ActionType:  "retry",
		RequestedBy: "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyWebhookRecoveryRequestValidate_RequeueRequiresNextAttemptAt(t *testing.T) {
	req := ApplyWebhookRecoveryRequest{
		WebhookID:   "webhook-001",
		DeliveryRef: "event-001-delivery-1",
		ActionType:  "requeue",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyWebhookRecoveryUsecaseApply_RetrySuccess(t *testing.T) {
	store := &webhookRecoveryStoreMock{
		result: ApplyWebhookRecoveryResult{
			WebhookID:      "webhook-001",
			DeliveryRef:    "event-001-delivery-1",
			ActionType:     "retry",
			Status:         "pending",
			AttemptNo:      0,
			LeaseReleased:  true,
		},
	}

	usecase := NewApplyWebhookRecoveryUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 8, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Apply(context.Background(), ApplyWebhookRecoveryRequest{
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

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ActionType != "retry" {
		t.Fatalf("beklenen action_type retry, alinan: %s", store.lastCmd.ActionType)
	}

	if resp.Status != "pending" {
		t.Fatalf("beklenen status pending, alinan: %s", resp.Status)
	}

	if resp.AttemptNo != 0 {
		t.Fatalf("beklenen attempt_no 0, alinan: %d", resp.AttemptNo)
	}

	if !resp.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !resp.RequestedAt.Equal(time.Date(2026, 4, 26, 8, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen requested_at sabit zaman")
	}
}

func TestApplyWebhookRecoveryUsecaseApply_RequeueFallbackSuccess(t *testing.T) {
	nextAttemptAt := time.Date(2026, 4, 26, 8, 5, 0, 0, time.UTC)

	store := &webhookRecoveryStoreMock{
		result: ApplyWebhookRecoveryResult{},
	}

	usecase := NewApplyWebhookRecoveryUsecase(store)

	resp, err := usecase.Apply(context.Background(), ApplyWebhookRecoveryRequest{
		WebhookID:     "webhook-002",
		DeliveryRef:   "event-002-delivery-1",
		ActionType:    "requeue",
		RequestedBy:   "worker-02",
		Reason:        "backoff sonrasi tekrar kuyruga al",
		NextAttemptAt: &nextAttemptAt,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Status != "pending" {
		t.Fatalf("beklenen status pending, alinan: %s", resp.Status)
	}

	if resp.NextAttemptAt == nil || !resp.NextAttemptAt.Equal(nextAttemptAt) {
		t.Fatalf("beklenen next_attempt_at korunmaliydi")
	}
}

func TestApplyWebhookRecoveryUsecaseApply_DeadLetterSuccess(t *testing.T) {
	store := &webhookRecoveryStoreMock{
		result: ApplyWebhookRecoveryResult{
			WebhookID:      "webhook-003",
			DeliveryRef:    "event-003-delivery-1",
			ActionType:     "dead_letter",
			Status:         "dead_letter",
			AttemptNo:      5,
			LeaseReleased:  true,
		},
	}

	usecase := NewApplyWebhookRecoveryUsecase(store)

	resp, err := usecase.Apply(context.Background(), ApplyWebhookRecoveryRequest{
		WebhookID:   "webhook-003",
		DeliveryRef: "event-003-delivery-1",
		ActionType:  "dead_letter",
		RequestedBy: "worker-03",
		Reason:      "kalici hata",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Status != "dead_letter" {
		t.Fatalf("beklenen status dead_letter, alinan: %s", resp.Status)
	}
}

func TestApplyWebhookRecoveryUsecaseApply_ValidationError(t *testing.T) {
	store := &webhookRecoveryStoreMock{}
	usecase := NewApplyWebhookRecoveryUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyWebhookRecoveryRequest{
		WebhookID:   "webhook-001",
		DeliveryRef: "event-001-delivery-1",
		ActionType:  "resume",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestApplyWebhookRecoveryUsecaseApply_StoreError(t *testing.T) {
	store := &webhookRecoveryStoreMock{
		err: errors.New("apply webhook recovery failed"),
	}
	usecase := NewApplyWebhookRecoveryUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyWebhookRecoveryRequest{
		WebhookID:   "webhook-001",
		DeliveryRef: "event-001-delivery-1",
		ActionType:  "retry",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestApplyWebhookRecoveryResponseValidate_InvalidRequestedAt(t *testing.T) {
	resp := ApplyWebhookRecoveryResponse{
		WebhookID:      "webhook-001",
		DeliveryRef:    "event-001-delivery-1",
		ActionType:     "retry",
		Status:         "pending",
		AttemptNo:      0,
		LeaseReleased:  true,
		RequestedBy:    "worker-01",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
