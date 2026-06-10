package idempotency

import (
	"context"
	"errors"
	"testing"
	"time"
)

type finalizeIdempotencyStoreMock struct {
	lastCmd FinalizeIdempotencyKeyCommand
	result  FinalizeIdempotencyKeyResult
	err     error
	called  bool
}

func (m *finalizeIdempotencyStoreMock) FinalizeKey(_ context.Context, cmd FinalizeIdempotencyKeyCommand) (FinalizeIdempotencyKeyResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestFinalizeIdempotencyKeyRequestValidate_Success(t *testing.T) {
	req := FinalizeIdempotencyKeyRequest{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		ResultRef:      "payment-123",
		FinalStatus:    "completed",
		RequestedBy:    "api-gateway",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestFinalizeIdempotencyKeyRequestValidate_InvalidResultRef(t *testing.T) {
	req := FinalizeIdempotencyKeyRequest{
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		ResultRef:      "payment 123",
		FinalStatus:    "completed",
		RequestedBy:    "api-gateway",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestFinalizeIdempotencyKeyRequestValidate_InvalidFinalStatus(t *testing.T) {
	req := FinalizeIdempotencyKeyRequest{
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		ResultRef:      "payment-123",
		FinalStatus:    "reserved",
		RequestedBy:    "api-gateway",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestFinalizeIdempotencyKeyRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := FinalizeIdempotencyKeyRequest{
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		ResultRef:      "payment-123",
		FinalStatus:    "completed",
		RequestedBy:    "api gateway",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestFinalizeIdempotencyKeyUsecaseFinalize_Success(t *testing.T) {
	store := &finalizeIdempotencyStoreMock{
		result: FinalizeIdempotencyKeyResult{
			ReservationID: "res-1",
			ResultRef:     "payment-123",
			FinalStatus:   "completed",
		},
	}

	usecase := NewFinalizeIdempotencyKeyUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 17, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Finalize(context.Background(), FinalizeIdempotencyKeyRequest{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		ResultRef:      "payment-123",
		FinalStatus:    "completed",
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ResultRef != "payment-123" {
		t.Fatalf("beklenen result_ref payment-123, alinan: %s", store.lastCmd.ResultRef)
	}

	if resp.ReservationID != "res-1" {
		t.Fatalf("beklenen reservation_id res-1, alinan: %s", resp.ReservationID)
	}

	if resp.FinalStatus != "completed" {
		t.Fatalf("beklenen final_status completed, alinan: %s", resp.FinalStatus)
	}

	if !resp.BoundAt.Equal(time.Date(2026, 4, 25, 17, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen bound_at sabit zaman")
	}
}

func TestFinalizeIdempotencyKeyUsecaseFinalize_FailedSuccess(t *testing.T) {
	store := &finalizeIdempotencyStoreMock{
		result: FinalizeIdempotencyKeyResult{
			ReservationID: "res-2",
			ResultRef:     "error-500",
			FinalStatus:   "failed",
		},
	}

	usecase := NewFinalizeIdempotencyKeyUsecase(store)

	resp, err := usecase.Finalize(context.Background(), FinalizeIdempotencyKeyRequest{
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-002",
		RequestHash:    "hash-002",
		ResultRef:      "error-500",
		FinalStatus:    "failed",
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.FinalStatus != "failed" {
		t.Fatalf("beklenen final_status failed, alinan: %s", resp.FinalStatus)
	}
}

func TestFinalizeIdempotencyKeyUsecaseFinalize_ValidationError(t *testing.T) {
	store := &finalizeIdempotencyStoreMock{}
	usecase := NewFinalizeIdempotencyKeyUsecase(store)

	_, err := usecase.Finalize(context.Background(), FinalizeIdempotencyKeyRequest{
		ScopeKey:       "",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		ResultRef:      "payment-123",
		FinalStatus:    "completed",
		RequestedBy:    "api-gateway",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestFinalizeIdempotencyKeyUsecaseFinalize_StoreError(t *testing.T) {
	store := &finalizeIdempotencyStoreMock{
		err: errors.New("finalize failed"),
	}
	usecase := NewFinalizeIdempotencyKeyUsecase(store)

	_, err := usecase.Finalize(context.Background(), FinalizeIdempotencyKeyRequest{
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		ResultRef:      "payment-123",
		FinalStatus:    "completed",
		RequestedBy:    "api-gateway",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestFinalizeIdempotencyKeyResponseValidate_InvalidBoundAt(t *testing.T) {
	resp := FinalizeIdempotencyKeyResponse{
		ReservationID:  "res-1",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		ResultRef:      "payment-123",
		FinalStatus:    "completed",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
