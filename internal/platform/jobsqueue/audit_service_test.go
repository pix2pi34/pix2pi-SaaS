package jobsqueue

import (
	"context"
	"errors"
	"testing"
	"time"
)

type jobAuditStoreMock struct {
	lastCmd RecordJobAuditEventCommand
	result  RecordJobAuditEventResult
	err     error
	called  bool
}

func (m *jobAuditStoreMock) RecordJobAuditEvent(_ context.Context, cmd RecordJobAuditEventCommand) (RecordJobAuditEventResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestRecordJobAuditEventRequestValidate_Success(t *testing.T) {
	req := RecordJobAuditEventRequest{
		TenantID:  "tenant-a",
		JobID:     "job-1",
		EventType: "claimed",
		ActorRef:  "worker-01",
		Status:    "processing",
		AttemptNo: 1,
		Message:   "worker job claim etti",
		Metadata:  map[string]any{"lease_seconds": 60},
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestRecordJobAuditEventRequestValidate_InvalidEventType(t *testing.T) {
	req := RecordJobAuditEventRequest{
		JobID:     "job-1",
		EventType: "resumed",
		ActorRef:  "worker-01",
		Status:    "processing",
		AttemptNo: 1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRecordJobAuditEventRequestValidate_InvalidStatus(t *testing.T) {
	req := RecordJobAuditEventRequest{
		JobID:     "job-1",
		EventType: "claimed",
		ActorRef:  "worker-01",
		Status:    "active",
		AttemptNo: 1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestRecordJobAuditEventRequestValidate_InvalidAttemptNo(t *testing.T) {
	req := RecordJobAuditEventRequest{
		JobID:     "job-1",
		EventType: "claimed",
		ActorRef:  "worker-01",
		Status:    "processing",
		AttemptNo: -1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestJobAuditUsecaseRecord_Success(t *testing.T) {
	store := &jobAuditStoreMock{
		result: RecordJobAuditEventResult{
			AuditID: "audit-1",
		},
	}

	usecase := NewJobAuditUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 13, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Record(context.Background(), RecordJobAuditEventRequest{
		TenantID:  "tenant-a",
		JobID:     "job-1",
		EventType: "claimed",
		ActorRef:  "worker-01",
		Status:    "processing",
		AttemptNo: 1,
		Message:   "worker job claim etti",
		Metadata:  map[string]any{"lease_seconds": 60},
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

	if resp.AuditID != "audit-1" {
		t.Fatalf("beklenen audit_id audit-1, alinan: %s", resp.AuditID)
	}

	if !resp.OccurredAt.Equal(time.Date(2026, 4, 25, 13, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen occurred_at sabit zaman")
	}
}

func TestJobAuditUsecaseRecord_ValidationError(t *testing.T) {
	store := &jobAuditStoreMock{}
	usecase := NewJobAuditUsecase(store)

	_, err := usecase.Record(context.Background(), RecordJobAuditEventRequest{
		JobID:     "",
		EventType: "claimed",
		ActorRef:  "worker-01",
		Status:    "processing",
		AttemptNo: 1,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestJobAuditUsecaseRecord_StoreError(t *testing.T) {
	store := &jobAuditStoreMock{
		err: errors.New("audit insert failed"),
	}
	usecase := NewJobAuditUsecase(store)

	_, err := usecase.Record(context.Background(), RecordJobAuditEventRequest{
		JobID:     "job-1",
		EventType: "claimed",
		ActorRef:  "worker-01",
		Status:    "processing",
		AttemptNo: 1,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestRecordJobAuditEventResponseValidate_InvalidOccurredAt(t *testing.T) {
	resp := RecordJobAuditEventResponse{
		AuditID:   "audit-1",
		JobID:     "job-1",
		EventType: "claimed",
		ActorRef:  "worker-01",
		Status:    "processing",
		AttemptNo: 1,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
