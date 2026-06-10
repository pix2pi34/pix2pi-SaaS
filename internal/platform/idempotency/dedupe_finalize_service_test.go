package idempotency

import (
	"context"
	"errors"
	"testing"
	"time"
)

type finalizeDedupeStoreMock struct {
	lastCmd FinalizeDedupeRecordCommand
	result  FinalizeDedupeRecordResult
	err     error
	called  bool
}

func (m *finalizeDedupeStoreMock) FinalizeRecord(_ context.Context, cmd FinalizeDedupeRecordCommand) (FinalizeDedupeRecordResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestFinalizeDedupeRecordRequestValidate_Success(t *testing.T) {
	req := FinalizeDedupeRecordRequest{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		ValueRef:    "batch-123",
		FinalStatus: "completed",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestFinalizeDedupeRecordRequestValidate_InvalidValueRef(t *testing.T) {
	req := FinalizeDedupeRecordRequest{
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		ValueRef:    "batch 123",
		FinalStatus: "completed",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestFinalizeDedupeRecordRequestValidate_InvalidFinalStatus(t *testing.T) {
	req := FinalizeDedupeRecordRequest{
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		ValueRef:    "batch-123",
		FinalStatus: "reserved",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestFinalizeDedupeRecordRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := FinalizeDedupeRecordRequest{
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		ValueRef:    "batch-123",
		FinalStatus: "completed",
		RequestedBy: "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestFinalizeDedupeRecordUsecaseFinalize_Success(t *testing.T) {
	store := &finalizeDedupeStoreMock{
		result: FinalizeDedupeRecordResult{
			RecordID:    "ded-1",
			ValueRef:    "batch-123",
			FinalStatus: "completed",
		},
	}

	usecase := NewFinalizeDedupeRecordUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 19, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Finalize(context.Background(), FinalizeDedupeRecordRequest{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		ValueRef:    "batch-123",
		FinalStatus: "completed",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ValueRef != "batch-123" {
		t.Fatalf("beklenen value_ref batch-123, alinan: %s", store.lastCmd.ValueRef)
	}

	if resp.RecordID != "ded-1" {
		t.Fatalf("beklenen record_id ded-1, alinan: %s", resp.RecordID)
	}

	if resp.FinalStatus != "completed" {
		t.Fatalf("beklenen final_status completed, alinan: %s", resp.FinalStatus)
	}

	if !resp.BoundAt.Equal(time.Date(2026, 4, 25, 19, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen bound_at sabit zaman")
	}
}

func TestFinalizeDedupeRecordUsecaseFinalize_FailedSuccess(t *testing.T) {
	store := &finalizeDedupeStoreMock{
		result: FinalizeDedupeRecordResult{
			RecordID:    "ded-2",
			ValueRef:    "error-500",
			FinalStatus: "failed",
		},
	}

	usecase := NewFinalizeDedupeRecordUsecase(store)

	resp, err := usecase.Finalize(context.Background(), FinalizeDedupeRecordRequest{
		ScopeKey:    "stock.sync",
		RecordKey:   "record-002",
		PayloadHash: "hash-002",
		ValueRef:    "error-500",
		FinalStatus: "failed",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.FinalStatus != "failed" {
		t.Fatalf("beklenen final_status failed, alinan: %s", resp.FinalStatus)
	}
}

func TestFinalizeDedupeRecordUsecaseFinalize_ValidationError(t *testing.T) {
	store := &finalizeDedupeStoreMock{}
	usecase := NewFinalizeDedupeRecordUsecase(store)

	_, err := usecase.Finalize(context.Background(), FinalizeDedupeRecordRequest{
		ScopeKey:    "",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		ValueRef:    "batch-123",
		FinalStatus: "completed",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestFinalizeDedupeRecordUsecaseFinalize_StoreError(t *testing.T) {
	store := &finalizeDedupeStoreMock{
		err: errors.New("finalize dedupe failed"),
	}
	usecase := NewFinalizeDedupeRecordUsecase(store)

	_, err := usecase.Finalize(context.Background(), FinalizeDedupeRecordRequest{
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		ValueRef:    "batch-123",
		FinalStatus: "completed",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestFinalizeDedupeRecordResponseValidate_InvalidBoundAt(t *testing.T) {
	resp := FinalizeDedupeRecordResponse{
		RecordID:    "ded-1",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		ValueRef:    "batch-123",
		FinalStatus: "completed",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
