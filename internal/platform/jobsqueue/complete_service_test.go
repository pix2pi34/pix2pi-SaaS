package jobsqueue

import (
	"context"
	"errors"
	"testing"
	"time"
)

type completeJobStoreMock struct {
	lastCmd CompleteJobCommand
	result  CompleteJobResult
	err     error
	called  bool
}

func (m *completeJobStoreMock) CompleteJob(_ context.Context, cmd CompleteJobCommand) (CompleteJobResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestCompleteJobRequestValidate_Success(t *testing.T) {
	req := CompleteJobRequest{
		TenantID:       "tenant-a",
		JobID:          "job-1",
		WorkerID:       "worker-01",
		Status:         "succeeded",
		AttemptNo:      1,
		CompletionNote: "tamamlandi",
		OutputPayload:  map[string]any{"sent_count": 10},
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestCompleteJobRequestValidate_InvalidWorkerID(t *testing.T) {
	req := CompleteJobRequest{
		JobID:     "job-1",
		WorkerID:  "worker 01",
		Status:    "succeeded",
		AttemptNo: 1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCompleteJobRequestValidate_InvalidStatus(t *testing.T) {
	req := CompleteJobRequest{
		JobID:     "job-1",
		WorkerID:  "worker-01",
		Status:    "processing",
		AttemptNo: 1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCompleteJobRequestValidate_FailedRequiresErrorCode(t *testing.T) {
	req := CompleteJobRequest{
		JobID:     "job-1",
		WorkerID:  "worker-01",
		Status:    "failed",
		AttemptNo: 1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCompleteJobUsecaseComplete_Success(t *testing.T) {
	store := &completeJobStoreMock{
		result: CompleteJobResult{
			JobID:          "job-1",
			Status:         "succeeded",
			AttemptNo:      1,
			CompletionNote: "tamamlandi",
			OutputPayload:  map[string]any{"sent_count": 10},
			LeaseReleased:  true,
		},
	}

	usecase := NewCompleteJobUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 11, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Complete(context.Background(), CompleteJobRequest{
		TenantID:       "tenant-a",
		JobID:          "job-1",
		WorkerID:       "worker-01",
		Status:         "succeeded",
		AttemptNo:      1,
		CompletionNote: "tamamlandi",
		OutputPayload:  map[string]any{"sent_count": 10},
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.JobID != "job-1" {
		t.Fatalf("beklenen job_id job-1, alinan: %s", store.lastCmd.JobID)
	}

	if resp.JobID != "job-1" {
		t.Fatalf("beklenen response job_id job-1, alinan: %s", resp.JobID)
	}

	if resp.Status != "succeeded" {
		t.Fatalf("beklenen status succeeded, alinan: %s", resp.Status)
	}

	if !resp.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !resp.FinishedAt.Equal(time.Date(2026, 4, 25, 11, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen finished_at sabit zaman")
	}
}

func TestCompleteJobUsecaseComplete_FailedSuccess(t *testing.T) {
	store := &completeJobStoreMock{
		result: CompleteJobResult{
			JobID:          "job-2",
			Status:         "failed",
			AttemptNo:      2,
			CompletionNote: "provider timeout",
			ErrorCode:      "EMAIL_TIMEOUT",
			LeaseReleased:  true,
		},
	}

	usecase := NewCompleteJobUsecase(store)

	resp, err := usecase.Complete(context.Background(), CompleteJobRequest{
		JobID:          "job-2",
		WorkerID:       "worker-02",
		Status:         "failed",
		AttemptNo:      2,
		CompletionNote: "provider timeout",
		ErrorCode:      "EMAIL_TIMEOUT",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.ErrorCode != "EMAIL_TIMEOUT" {
		t.Fatalf("beklenen error_code EMAIL_TIMEOUT, alinan: %s", resp.ErrorCode)
	}
}

func TestCompleteJobUsecaseComplete_ValidationError(t *testing.T) {
	store := &completeJobStoreMock{}
	usecase := NewCompleteJobUsecase(store)

	_, err := usecase.Complete(context.Background(), CompleteJobRequest{
		JobID:     "",
		WorkerID:  "worker-01",
		Status:    "succeeded",
		AttemptNo: 1,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestCompleteJobUsecaseComplete_StoreError(t *testing.T) {
	store := &completeJobStoreMock{
		err: errors.New("complete failed"),
	}
	usecase := NewCompleteJobUsecase(store)

	_, err := usecase.Complete(context.Background(), CompleteJobRequest{
		JobID:     "job-1",
		WorkerID:  "worker-01",
		Status:    "cancelled",
		AttemptNo: 1,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestCompleteJobResponseValidate_InvalidFinishedAt(t *testing.T) {
	resp := CompleteJobResponse{
		JobID:         "job-1",
		WorkerID:      "worker-01",
		Status:        "succeeded",
		AttemptNo:     1,
		LeaseReleased: true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
