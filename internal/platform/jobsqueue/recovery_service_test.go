package jobsqueue

import (
	"context"
	"errors"
	"testing"
	"time"
)

type recoverJobStoreMock struct {
	lastCmd RecoverJobCommand
	result  RecoverJobResult
	err     error
	called  bool
}

func (m *recoverJobStoreMock) RecoverJob(_ context.Context, cmd RecoverJobCommand) (RecoverJobResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestRecoverJobRequestValidate_Success(t *testing.T) {
	req := RecoverJobRequest{
		TenantID:      "tenant-a",
		JobID:         "job-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "transient error temizlendi",
		ResetAttempts: true,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestRecoverJobRequestValidate_InvalidActionType(t *testing.T) {
	req := RecoverJobRequest{
		JobID:       "job-1",
		ActionType:  "resume",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRecoverJobRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := RecoverJobRequest{
		JobID:       "job-1",
		ActionType:  "retry",
		RequestedBy: "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRecoverJobRequestValidate_RequeueRequiresTargetQueue(t *testing.T) {
	req := RecoverJobRequest{
		JobID:       "job-1",
		ActionType:  "requeue",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRecoverJobUsecaseRecover_RetrySuccess(t *testing.T) {
	store := &recoverJobStoreMock{
		result: RecoverJobResult{
			JobID:         "job-1",
			Status:        "queued",
			QueueKey:      "notifications-email",
			AttemptNo:     0,
			LeaseReleased: true,
		},
	}

	usecase := NewRecoverJobUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 12, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Recover(context.Background(), RecoverJobRequest{
		TenantID:      "tenant-a",
		JobID:         "job-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "transient error temizlendi",
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

	if !resp.RequestedAt.Equal(time.Date(2026, 4, 25, 12, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen requested_at sabit zaman")
	}
}

func TestRecoverJobUsecaseRecover_DeadLetterSuccess(t *testing.T) {
	store := &recoverJobStoreMock{
		result: RecoverJobResult{
			JobID:         "job-2",
			Status:        "dead_letter",
			QueueKey:      "notifications-email",
			AttemptNo:     3,
			LeaseReleased: true,
		},
	}

	usecase := NewRecoverJobUsecase(store)

	resp, err := usecase.Recover(context.Background(), RecoverJobRequest{
		JobID:       "job-2",
		ActionType:  "dead_letter",
		RequestedBy: "worker-02",
		Reason:      "kalici hata",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Status != "dead_letter" {
		t.Fatalf("beklenen status dead_letter, alinan: %s", resp.Status)
	}
}

func TestRecoverJobUsecaseRecover_ValidationError(t *testing.T) {
	store := &recoverJobStoreMock{}
	usecase := NewRecoverJobUsecase(store)

	_, err := usecase.Recover(context.Background(), RecoverJobRequest{
		JobID:       "",
		ActionType:  "retry",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestRecoverJobUsecaseRecover_StoreError(t *testing.T) {
	store := &recoverJobStoreMock{
		err: errors.New("recover failed"),
	}
	usecase := NewRecoverJobUsecase(store)

	_, err := usecase.Recover(context.Background(), RecoverJobRequest{
		JobID:       "job-1",
		ActionType:  "retry",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestRecoverJobResponseValidate_InvalidRequestedAt(t *testing.T) {
	resp := RecoverJobResponse{
		JobID:         "job-1",
		ActionType:    "retry",
		Status:        "queued",
		LeaseReleased: true,
		RequestedBy:   "worker-01",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
