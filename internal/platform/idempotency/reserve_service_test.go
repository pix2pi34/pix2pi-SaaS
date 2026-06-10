package idempotency

import (
	"context"
	"errors"
	"testing"
	"time"
)

type reserveIdempotencyStoreMock struct {
	lastCmd ReserveIdempotencyKeyCommand
	result  ReserveIdempotencyKeyResult
	err     error
	called  bool
}

func (m *reserveIdempotencyStoreMock) ReserveOrCheckKey(_ context.Context, cmd ReserveIdempotencyKeyCommand) (ReserveIdempotencyKeyResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestReserveIdempotencyKeyRequestValidate_Success(t *testing.T) {
	req := ReserveIdempotencyKeyRequest{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestReserveIdempotencyKeyRequestValidate_InvalidScopeKey(t *testing.T) {
	req := ReserveIdempotencyKeyRequest{
		ScopeKey:       "Payment Create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestReserveIdempotencyKeyRequestValidate_InvalidTTL(t *testing.T) {
	req := ReserveIdempotencyKeyRequest{
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		TTLSeconds:     10,
		RequestedBy:    "api-gateway",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestReserveIdempotencyKeyRequestValidate_InvalidRequestHash(t *testing.T) {
	req := ReserveIdempotencyKeyRequest{
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash 001",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestReserveIdempotencyKeyUsecaseReserveOrCheck_Success(t *testing.T) {
	expiresAt := time.Date(2026, 4, 25, 16, 5, 0, 0, time.UTC)

	store := &reserveIdempotencyStoreMock{
		result: ReserveIdempotencyKeyResult{
			ReservationID: "res-1",
			Status:        "reserved",
			ExpiresAt:     &expiresAt,
		},
	}

	usecase := NewReserveIdempotencyKeyUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 16, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.ReserveOrCheck(context.Background(), ReserveIdempotencyKeyRequest{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ScopeKey != "payment.create" {
		t.Fatalf("beklenen scope_key payment.create, alinan: %s", store.lastCmd.ScopeKey)
	}

	if resp.ReservationID != "res-1" {
		t.Fatalf("beklenen reservation_id res-1, alinan: %s", resp.ReservationID)
	}

	if resp.Status != "reserved" {
		t.Fatalf("beklenen status reserved, alinan: %s", resp.Status)
	}

	if !resp.ExpiresAt.Equal(expiresAt) {
		t.Fatalf("beklenen expires_at korunmaliydi")
	}

	if !resp.ReservedAt.Equal(time.Date(2026, 4, 25, 16, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen reserved_at sabit zaman")
	}
}

func TestReserveIdempotencyKeyUsecaseReserveOrCheck_ExistingSuccess(t *testing.T) {
	expiresAt := time.Date(2026, 4, 25, 16, 10, 0, 0, time.UTC)

	store := &reserveIdempotencyStoreMock{
		result: ReserveIdempotencyKeyResult{
			ReservationID:     "res-2",
			Status:            "existing",
			ExistingResultRef: "payment-123",
			ExpiresAt:         &expiresAt,
		},
	}

	usecase := NewReserveIdempotencyKeyUsecase(store)

	resp, err := usecase.ReserveOrCheck(context.Background(), ReserveIdempotencyKeyRequest{
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-002",
		RequestHash:    "hash-002",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Status != "existing" {
		t.Fatalf("beklenen status existing, alinan: %s", resp.Status)
	}

	if resp.ExistingResultRef != "payment-123" {
		t.Fatalf("beklenen existing_result_ref payment-123, alinan: %s", resp.ExistingResultRef)
	}
}

func TestReserveIdempotencyKeyUsecaseReserveOrCheck_ValidationError(t *testing.T) {
	store := &reserveIdempotencyStoreMock{}
	usecase := NewReserveIdempotencyKeyUsecase(store)

	_, err := usecase.ReserveOrCheck(context.Background(), ReserveIdempotencyKeyRequest{
		ScopeKey:       "",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestReserveIdempotencyKeyUsecaseReserveOrCheck_StoreError(t *testing.T) {
	store := &reserveIdempotencyStoreMock{
		err: errors.New("reserve failed"),
	}
	usecase := NewReserveIdempotencyKeyUsecase(store)

	_, err := usecase.ReserveOrCheck(context.Background(), ReserveIdempotencyKeyRequest{
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestReserveIdempotencyKeyResponseValidate_InvalidReservedAt(t *testing.T) {
	resp := ReserveIdempotencyKeyResponse{
		ReservationID:  "res-1",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		Status:         "reserved",
		ExpiresAt:      time.Date(2026, 4, 25, 16, 5, 0, 0, time.UTC),
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
