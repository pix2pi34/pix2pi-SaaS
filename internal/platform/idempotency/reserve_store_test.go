package idempotency

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type reserveRowMock struct {
	values []any
	err    error
}

func (r *reserveRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *time.Time:
			*d = r.values[i].(time.Time)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type reserveQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *reserveQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestReserveIdempotencySQLStoreReserveOrCheckKey_ReservedSuccess(t *testing.T) {
	expiresAt := time.Date(2026, 4, 25, 16, 5, 0, 0, time.UTC)

	db := &reserveQueryRowProviderMock{
		row: &reserveRowMock{
			values: []any{"res-1", "reserved", "", expiresAt},
		},
	}

	store := NewReserveIdempotencySQLStore(db)

	result, err := store.ReserveOrCheckKey(context.Background(), ReserveIdempotencyKeyCommand{
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

	if result.ReservationID != "res-1" {
		t.Fatalf("beklenen reservation_id res-1, alinan: %s", result.ReservationID)
	}

	if result.Status != "reserved" {
		t.Fatalf("beklenen status reserved, alinan: %s", result.Status)
	}

	if result.ExpiresAt == nil || !result.ExpiresAt.Equal(expiresAt) {
		t.Fatalf("beklenen expires_at korunmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.idempotency_keys") {
		t.Fatalf("idempotency_keys query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "existing_key") {
		t.Fatalf("existing_key cte query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "inserted_key") {
		t.Fatalf("inserted_key cte query icinde olmaliydi")
	}

	if len(db.lastArgs) != 6 {
		t.Fatalf("beklenen 6 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestReserveIdempotencySQLStoreReserveOrCheckKey_ExistingSuccess(t *testing.T) {
	expiresAt := time.Date(2026, 4, 25, 16, 10, 0, 0, time.UTC)

	db := &reserveQueryRowProviderMock{
		row: &reserveRowMock{
			values: []any{"res-2", "existing", "payment-123", expiresAt},
		},
	}

	store := NewReserveIdempotencySQLStore(db)

	result, err := store.ReserveOrCheckKey(context.Background(), ReserveIdempotencyKeyCommand{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-002",
		RequestHash:    "hash-002",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Status != "existing" {
		t.Fatalf("beklenen status existing, alinan: %s", result.Status)
	}

	if result.ExistingResultRef != "payment-123" {
		t.Fatalf("beklenen existing_result_ref payment-123, alinan: %s", result.ExistingResultRef)
	}
}

func TestReserveIdempotencySQLStoreReserveOrCheckKey_ConflictSuccess(t *testing.T) {
	expiresAt := time.Date(2026, 4, 25, 16, 15, 0, 0, time.UTC)

	db := &reserveQueryRowProviderMock{
		row: &reserveRowMock{
			values: []any{"res-3", "conflict", "", expiresAt},
		},
	}

	store := NewReserveIdempotencySQLStore(db)

	result, err := store.ReserveOrCheckKey(context.Background(), ReserveIdempotencyKeyCommand{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-003",
		RequestHash:    "hash-different",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Status != "conflict" {
		t.Fatalf("beklenen status conflict, alinan: %s", result.Status)
	}
}

func TestReserveIdempotencySQLStoreReserveOrCheckKey_NoDB(t *testing.T) {
	store := NewReserveIdempotencySQLStore(nil)

	_, err := store.ReserveOrCheckKey(context.Background(), ReserveIdempotencyKeyCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestReserveIdempotencySQLStoreReserveOrCheckKey_ScanError(t *testing.T) {
	db := &reserveQueryRowProviderMock{
		row: &reserveRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewReserveIdempotencySQLStore(db)

	_, err := store.ReserveOrCheckKey(context.Background(), ReserveIdempotencyKeyCommand{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
