package idempotency

import (
	"context"
	"errors"
	"testing"
	"time"
)

type reserveDedupeStoreMock struct {
	lastCmd ReserveDedupeRecordCommand
	result  ReserveDedupeRecordResult
	err     error
	called  bool
}

func (m *reserveDedupeStoreMock) ReserveOrCheckRecord(_ context.Context, cmd ReserveDedupeRecordCommand) (ReserveDedupeRecordResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestReserveDedupeRecordRequestValidate_Success(t *testing.T) {
	req := ReserveDedupeRecordRequest{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestReserveDedupeRecordRequestValidate_InvalidRecordKey(t *testing.T) {
	req := ReserveDedupeRecordRequest{
		ScopeKey:    "stock.sync",
		RecordKey:   "record 001",
		PayloadHash: "hash-001",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestReserveDedupeRecordRequestValidate_InvalidTTL(t *testing.T) {
	req := ReserveDedupeRecordRequest{
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		TTLSeconds:  10,
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestReserveDedupeRecordRequestValidate_InvalidPayloadHash(t *testing.T) {
	req := ReserveDedupeRecordRequest{
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash 001",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestReserveDedupeRecordUsecaseReserveOrCheck_Success(t *testing.T) {
	expiresAt := time.Date(2026, 4, 25, 18, 5, 0, 0, time.UTC)

	store := &reserveDedupeStoreMock{
		result: ReserveDedupeRecordResult{
			RecordID:  "ded-1",
			Status:    "reserved",
			ExpiresAt: &expiresAt,
		},
	}

	usecase := NewReserveDedupeRecordUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 18, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.ReserveOrCheck(context.Background(), ReserveDedupeRecordRequest{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ScopeKey != "stock.sync" {
		t.Fatalf("beklenen scope_key stock.sync, alinan: %s", store.lastCmd.ScopeKey)
	}

	if resp.RecordID != "ded-1" {
		t.Fatalf("beklenen record_id ded-1, alinan: %s", resp.RecordID)
	}

	if resp.Status != "reserved" {
		t.Fatalf("beklenen status reserved, alinan: %s", resp.Status)
	}

	if !resp.ExpiresAt.Equal(expiresAt) {
		t.Fatalf("beklenen expires_at korunmaliydi")
	}

	if !resp.ReservedAt.Equal(time.Date(2026, 4, 25, 18, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen reserved_at sabit zaman")
	}
}

func TestReserveDedupeRecordUsecaseReserveOrCheck_ExistingSuccess(t *testing.T) {
	expiresAt := time.Date(2026, 4, 25, 18, 10, 0, 0, time.UTC)

	store := &reserveDedupeStoreMock{
		result: ReserveDedupeRecordResult{
			RecordID:         "ded-2",
			Status:           "existing",
			ExistingValueRef: "sync-batch-123",
			ExpiresAt:        &expiresAt,
		},
	}

	usecase := NewReserveDedupeRecordUsecase(store)

	resp, err := usecase.ReserveOrCheck(context.Background(), ReserveDedupeRecordRequest{
		ScopeKey:    "stock.sync",
		RecordKey:   "record-002",
		PayloadHash: "hash-002",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Status != "existing" {
		t.Fatalf("beklenen status existing, alinan: %s", resp.Status)
	}

	if resp.ExistingValueRef != "sync-batch-123" {
		t.Fatalf("beklenen existing_value_ref sync-batch-123, alinan: %s", resp.ExistingValueRef)
	}
}

func TestReserveDedupeRecordUsecaseReserveOrCheck_ValidationError(t *testing.T) {
	store := &reserveDedupeStoreMock{}
	usecase := NewReserveDedupeRecordUsecase(store)

	_, err := usecase.ReserveOrCheck(context.Background(), ReserveDedupeRecordRequest{
		ScopeKey:    "",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestReserveDedupeRecordUsecaseReserveOrCheck_StoreError(t *testing.T) {
	store := &reserveDedupeStoreMock{
		err: errors.New("reserve dedupe failed"),
	}
	usecase := NewReserveDedupeRecordUsecase(store)

	_, err := usecase.ReserveOrCheck(context.Background(), ReserveDedupeRecordRequest{
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestReserveDedupeRecordResponseValidate_InvalidReservedAt(t *testing.T) {
	resp := ReserveDedupeRecordResponse{
		RecordID:    "ded-1",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		Status:      "reserved",
		ExpiresAt:   time.Date(2026, 4, 25, 18, 5, 0, 0, time.UTC),
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
