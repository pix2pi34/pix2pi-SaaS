package idempotency

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type finalizeRowMock struct {
	values []any
	err    error
}

func (r *finalizeRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type finalizeQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *finalizeQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestFinalizeIdempotencySQLStoreFinalizeKey_CompletedSuccess(t *testing.T) {
	db := &finalizeQueryRowProviderMock{
		row: &finalizeRowMock{
			values: []any{"res-1", "payment-123", "completed"},
		},
	}

	store := NewFinalizeIdempotencySQLStore(db)

	result, err := store.FinalizeKey(context.Background(), FinalizeIdempotencyKeyCommand{
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

	if result.ReservationID != "res-1" {
		t.Fatalf("beklenen reservation_id res-1, alinan: %s", result.ReservationID)
	}

	if result.ResultRef != "payment-123" {
		t.Fatalf("beklenen result_ref payment-123, alinan: %s", result.ResultRef)
	}

	if result.FinalStatus != "completed" {
		t.Fatalf("beklenen final_status completed, alinan: %s", result.FinalStatus)
	}

	if !strings.Contains(db.lastQuery, "runtime.idempotency_keys") {
		t.Fatalf("idempotency_keys query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "result_ref = $5") {
		t.Fatalf("result_ref update query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "status = $6") {
		t.Fatalf("status update query icinde olmaliydi")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestFinalizeIdempotencySQLStoreFinalizeKey_FailedSuccess(t *testing.T) {
	db := &finalizeQueryRowProviderMock{
		row: &finalizeRowMock{
			values: []any{"res-2", "error-500", "failed"},
		},
	}

	store := NewFinalizeIdempotencySQLStore(db)

	result, err := store.FinalizeKey(context.Background(), FinalizeIdempotencyKeyCommand{
		TenantID:       "tenant-a",
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

	if result.FinalStatus != "failed" {
		t.Fatalf("beklenen final_status failed, alinan: %s", result.FinalStatus)
	}
}

func TestFinalizeIdempotencySQLStoreFinalizeKey_NoDB(t *testing.T) {
	store := NewFinalizeIdempotencySQLStore(nil)

	_, err := store.FinalizeKey(context.Background(), FinalizeIdempotencyKeyCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestFinalizeIdempotencySQLStoreFinalizeKey_ScanError(t *testing.T) {
	db := &finalizeQueryRowProviderMock{
		row: &finalizeRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewFinalizeIdempotencySQLStore(db)

	_, err := store.FinalizeKey(context.Background(), FinalizeIdempotencyKeyCommand{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		ResultRef:      "payment-123",
		FinalStatus:    "completed",
		RequestedBy:    "api-gateway",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
