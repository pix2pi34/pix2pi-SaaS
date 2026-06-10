package jobsqueue

import (
	"context"
	"errors"
	"testing"
	"time"
)

type claimJobStoreMock struct {
	lastCmd ClaimJobCommand
	result  ClaimJobResult
	err     error
	called  bool
}

func (m *claimJobStoreMock) ClaimNextJob(_ context.Context, cmd ClaimJobCommand) (ClaimJobResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestClaimJobRequestValidate_Success(t *testing.T) {
	req := ClaimJobRequest{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestClaimJobRequestValidate_InvalidQueueKey(t *testing.T) {
	req := ClaimJobRequest{
		QueueKey:     "Notifications Email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestClaimJobRequestValidate_InvalidWorkerID(t *testing.T) {
	req := ClaimJobRequest{
		QueueKey:     "notifications-email",
		WorkerID:     "worker 01",
		LeaseSeconds: 60,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestClaimJobRequestValidate_InvalidLeaseSeconds(t *testing.T) {
	req := ClaimJobRequest{
		QueueKey:     "notifications-email",
		WorkerID:     "worker-01",
		LeaseSeconds: 1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestClaimJobUsecaseClaim_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 25, 9, 1, 0, 0, time.UTC)

	store := &claimJobStoreMock{
		result: ClaimJobResult{
			Claimed:        true,
			JobID:          "job-1",
			QueueKey:       "notifications-email",
			JobKey:         "job-email-001",
			JobType:        "email.send",
			Priority:       "high",
			Status:         "processing",
			AttemptNo:      1,
			Payload:        map[string]any{"template": "welcome"},
			LeaseExpiresAt: &leaseExpiresAt,
		},
	}

	usecase := NewClaimJobUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 9, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Claim(context.Background(), ClaimJobRequest{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.QueueKey != "notifications-email" {
		t.Fatalf("beklenen queue_key notifications-email, alinan: %s", store.lastCmd.QueueKey)
	}

	if !resp.Claimed {
		t.Fatalf("beklenen claimed true")
	}

	if resp.JobID != "job-1" {
		t.Fatalf("beklenen job_id job-1, alinan: %s", resp.JobID)
	}

	if resp.WorkerID != "worker-01" {
		t.Fatalf("beklenen worker_id worker-01, alinan: %s", resp.WorkerID)
	}

	if resp.LeaseExpiresAt == nil || !resp.LeaseExpiresAt.Equal(leaseExpiresAt) {
		t.Fatalf("beklenen lease_expires_at korunmaliydi")
	}

	if !resp.ClaimedAt.Equal(time.Date(2026, 4, 25, 9, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen claimed_at sabit zaman")
	}
}

func TestClaimJobUsecaseClaim_NoJobFound(t *testing.T) {
	store := &claimJobStoreMock{
		result: ClaimJobResult{
			Claimed: false,
		},
	}

	usecase := NewClaimJobUsecase(store)
	resp, err := usecase.Claim(context.Background(), ClaimJobRequest{
		QueueKey:     "notifications-email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Claimed {
		t.Fatalf("beklenen claimed false")
	}

	if resp.JobID != "" {
		t.Fatalf("beklenen bos job_id")
	}
}

func TestClaimJobUsecaseClaim_ValidationError(t *testing.T) {
	store := &claimJobStoreMock{}
	usecase := NewClaimJobUsecase(store)

	_, err := usecase.Claim(context.Background(), ClaimJobRequest{
		QueueKey:     "bad queue",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestClaimJobUsecaseClaim_StoreError(t *testing.T) {
	store := &claimJobStoreMock{
		err: errors.New("claim failed"),
	}
	usecase := NewClaimJobUsecase(store)

	_, err := usecase.Claim(context.Background(), ClaimJobRequest{
		QueueKey:     "notifications-email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestClaimJobResponseValidate_InvalidClaimedAt(t *testing.T) {
	resp := ClaimJobResponse{
		Claimed: false,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
