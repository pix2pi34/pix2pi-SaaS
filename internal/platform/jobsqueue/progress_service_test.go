package jobsqueue

import (
	"context"
	"errors"
	"testing"
	"time"
)

type updateJobProgressStoreMock struct {
	lastCmd UpdateJobProgressCommand
	result  UpdateJobProgressResult
	err     error
	called  bool
}

func (m *updateJobProgressStoreMock) UpdateJobProgress(_ context.Context, cmd UpdateJobProgressCommand) (UpdateJobProgressResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestUpdateJobProgressRequestValidate_Success(t *testing.T) {
	req := UpdateJobProgressRequest{
		TenantID:           "tenant-a",
		JobID:              "job-1",
		WorkerID:           "worker-01",
		Status:             "processing",
		ProgressPercent:    45,
		Message:            "ilk batch tamamlandi",
		AttemptNo:          1,
		LeaseExtendSeconds: 120,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestUpdateJobProgressRequestValidate_InvalidWorkerID(t *testing.T) {
	req := UpdateJobProgressRequest{
		JobID:              "job-1",
		WorkerID:           "worker 01",
		Status:             "processing",
		ProgressPercent:    45,
		AttemptNo:          1,
		LeaseExtendSeconds: 120,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestUpdateJobProgressRequestValidate_InvalidStatus(t *testing.T) {
	req := UpdateJobProgressRequest{
		JobID:              "job-1",
		WorkerID:           "worker-01",
		Status:             "queued",
		ProgressPercent:    45,
		AttemptNo:          1,
		LeaseExtendSeconds: 120,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestUpdateJobProgressRequestValidate_InvalidProgressPercent(t *testing.T) {
	req := UpdateJobProgressRequest{
		JobID:              "job-1",
		WorkerID:           "worker-01",
		Status:             "processing",
		ProgressPercent:    101,
		AttemptNo:          1,
		LeaseExtendSeconds: 120,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestUpdateJobProgressUsecaseUpdate_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 25, 10, 2, 0, 0, time.UTC)

	store := &updateJobProgressStoreMock{
		result: UpdateJobProgressResult{
			JobID:           "job-1",
			Status:          "processing",
			ProgressPercent: 60,
			AttemptNo:       1,
			Message:         "ikinci batch tamamlandi",
			LeaseExpiresAt:  &leaseExpiresAt,
		},
	}

	usecase := NewUpdateJobProgressUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 10, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Update(context.Background(), UpdateJobProgressRequest{
		TenantID:           "tenant-a",
		JobID:              "job-1",
		WorkerID:           "worker-01",
		Status:             "processing",
		ProgressPercent:    60,
		Message:            "ikinci batch tamamlandi",
		AttemptNo:          1,
		LeaseExtendSeconds: 120,
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

	if resp.ProgressPercent != 60 {
		t.Fatalf("beklenen progress 60, alinan: %d", resp.ProgressPercent)
	}

	if resp.LeaseExpiresAt == nil || !resp.LeaseExpiresAt.Equal(leaseExpiresAt) {
		t.Fatalf("beklenen lease_expires_at korunmaliydi")
	}

	if !resp.UpdatedAt.Equal(time.Date(2026, 4, 25, 10, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen updated_at sabit zaman")
	}
}

func TestUpdateJobProgressUsecaseUpdate_SucceededWithoutLease(t *testing.T) {
	store := &updateJobProgressStoreMock{
		result: UpdateJobProgressResult{
			JobID:           "job-1",
			Status:          "succeeded",
			ProgressPercent: 100,
			AttemptNo:       1,
			Message:         "tamamlandi",
			LeaseExpiresAt:  nil,
		},
	}

	usecase := NewUpdateJobProgressUsecase(store)

	resp, err := usecase.Update(context.Background(), UpdateJobProgressRequest{
		JobID:           "job-1",
		WorkerID:        "worker-01",
		Status:          "succeeded",
		ProgressPercent: 100,
		Message:         "tamamlandi",
		AttemptNo:       1,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.LeaseExpiresAt != nil {
		t.Fatalf("succeeded durumunda lease_expires_at nil olmaliydi")
	}
}

func TestUpdateJobProgressUsecaseUpdate_ValidationError(t *testing.T) {
	store := &updateJobProgressStoreMock{}
	usecase := NewUpdateJobProgressUsecase(store)

	_, err := usecase.Update(context.Background(), UpdateJobProgressRequest{
		JobID:           "",
		WorkerID:        "worker-01",
		Status:          "processing",
		ProgressPercent: 50,
		AttemptNo:       1,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestUpdateJobProgressUsecaseUpdate_StoreError(t *testing.T) {
	store := &updateJobProgressStoreMock{
		err: errors.New("progress update failed"),
	}
	usecase := NewUpdateJobProgressUsecase(store)

	_, err := usecase.Update(context.Background(), UpdateJobProgressRequest{
		JobID:           "job-1",
		WorkerID:        "worker-01",
		Status:          "processing",
		ProgressPercent: 50,
		AttemptNo:       1,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestUpdateJobProgressResponseValidate_InvalidUpdatedAt(t *testing.T) {
	resp := UpdateJobProgressResponse{
		JobID:           "job-1",
		WorkerID:        "worker-01",
		Status:          "succeeded",
		ProgressPercent: 100,
		AttemptNo:       1,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
