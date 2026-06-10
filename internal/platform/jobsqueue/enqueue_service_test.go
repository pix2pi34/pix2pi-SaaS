package jobsqueue

import (
	"context"
	"errors"
	"testing"
	"time"
)

type enqueueJobStoreMock struct {
	lastCmd EnqueueJobCommand
	result  EnqueueJobResult
	err     error
	called  bool
}

func (m *enqueueJobStoreMock) EnqueueJob(_ context.Context, cmd EnqueueJobCommand) (EnqueueJobResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestEnqueueJobRequestValidate_Success(t *testing.T) {
	scheduledAt := time.Date(2026, 4, 25, 9, 0, 0, 0, time.UTC)

	req := EnqueueJobRequest{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-email-001",
		JobType:     "email.send",
		Priority:    "high",
		DedupKey:    "email-user-1",
		Payload:     map[string]any{"template": "welcome"},
		ScheduledAt: &scheduledAt,
		RequestedBy: "system-api",
		MaxAttempts: 5,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestEnqueueJobRequestValidate_InvalidQueueKey(t *testing.T) {
	req := EnqueueJobRequest{
		QueueKey:    "Notifications Email",
		JobKey:      "job-email-001",
		JobType:     "email.send",
		Priority:    "high",
		RequestedBy: "system-api",
		MaxAttempts: 5,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEnqueueJobRequestValidate_InvalidPriority(t *testing.T) {
	req := EnqueueJobRequest{
		QueueKey:    "notifications-email",
		JobKey:      "job-email-001",
		JobType:     "email.send",
		Priority:    "urgent",
		RequestedBy: "system-api",
		MaxAttempts: 5,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEnqueueJobRequestValidate_InvalidMaxAttempts(t *testing.T) {
	req := EnqueueJobRequest{
		QueueKey:    "notifications-email",
		JobKey:      "job-email-001",
		JobType:     "email.send",
		Priority:    "high",
		RequestedBy: "system-api",
		MaxAttempts: 0,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestEnqueueJobUsecaseEnqueue_Success(t *testing.T) {
	store := &enqueueJobStoreMock{
		result: EnqueueJobResult{
			JobID:        "job-1",
			Status:       "queued",
			DedupMatched: false,
		},
	}

	usecase := NewEnqueueJobUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 8, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Enqueue(context.Background(), EnqueueJobRequest{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-email-001",
		JobType:     "email.send",
		Priority:    "high",
		Payload:     map[string]any{"template": "welcome"},
		RequestedBy: "system-api",
		MaxAttempts: 5,
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

	if resp.JobID != "job-1" {
		t.Fatalf("beklenen job_id job-1, alinan: %s", resp.JobID)
	}

	if resp.Status != "queued" {
		t.Fatalf("beklenen status queued, alinan: %s", resp.Status)
	}

	if !resp.EnqueuedAt.Equal(time.Date(2026, 4, 25, 8, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen enqueued_at sabit zaman")
	}
}

func TestEnqueueJobUsecaseEnqueue_ScheduledDefaultsStatus(t *testing.T) {
	store := &enqueueJobStoreMock{
		result: EnqueueJobResult{},
	}

	usecase := NewEnqueueJobUsecase(store)

	scheduledAt := time.Date(2026, 4, 25, 10, 0, 0, 0, time.UTC)
	resp, err := usecase.Enqueue(context.Background(), EnqueueJobRequest{
		QueueKey:    "notifications-email",
		JobKey:      "job-email-002",
		JobType:     "email.send",
		Priority:    "normal",
		ScheduledAt: &scheduledAt,
		RequestedBy: "system-api",
		MaxAttempts: 3,
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

func TestEnqueueJobUsecaseEnqueue_ValidationError(t *testing.T) {
	store := &enqueueJobStoreMock{}
	usecase := NewEnqueueJobUsecase(store)

	_, err := usecase.Enqueue(context.Background(), EnqueueJobRequest{
		QueueKey:    "bad queue",
		JobKey:      "job-email-001",
		JobType:     "email.send",
		Priority:    "high",
		RequestedBy: "system-api",
		MaxAttempts: 5,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestEnqueueJobUsecaseEnqueue_StoreError(t *testing.T) {
	store := &enqueueJobStoreMock{
		err: errors.New("enqueue failed"),
	}
	usecase := NewEnqueueJobUsecase(store)

	_, err := usecase.Enqueue(context.Background(), EnqueueJobRequest{
		QueueKey:    "notifications-email",
		JobKey:      "job-email-001",
		JobType:     "email.send",
		Priority:    "high",
		RequestedBy: "system-api",
		MaxAttempts: 5,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestEnqueueJobResponseValidate_InvalidEnqueuedAt(t *testing.T) {
	resp := EnqueueJobResponse{
		JobID:    "job-1",
		QueueKey: "notifications-email",
		JobKey:   "job-email-001",
		JobType:  "email.send",
		Priority: "high",
		Status:   "queued",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
