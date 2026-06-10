package idempotency

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type dedupeReserveRowMock struct {
	values []any
	err    error
}

func (r *dedupeReserveRowMock) Scan(dest ...any) error {
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

type dedupeReserveQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *dedupeReserveQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestReserveDedupeRecordSQLStoreReserveOrCheckRecord_ReservedSuccess(t *testing.T) {
	expiresAt := time.Date(2026, 4, 25, 18, 5, 0, 0, time.UTC)

	db := &dedupeReserveQueryRowProviderMock{
		row: &dedupeReserveRowMock{
			values: []any{"ded-1", "reserved", "", expiresAt},
		},
	}

	store := NewReserveDedupeRecordSQLStore(db)

	result, err := store.ReserveOrCheckRecord(context.Background(), ReserveDedupeRecordCommand{
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

	if result.RecordID != "ded-1" {
		t.Fatalf("beklenen record_id ded-1, alinan: %s", result.RecordID)
	}

	if result.Status != "reserved" {
		t.Fatalf("beklenen status reserved, alinan: %s", result.Status)
	}

	if result.ExpiresAt == nil || !result.ExpiresAt.Equal(expiresAt) {
		t.Fatalf("beklenen expires_at korunmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.dedupe_records") {
		t.Fatalf("dedupe_records query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "existing_record") {
		t.Fatalf("existing_record cte query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "inserted_record") {
		t.Fatalf("inserted_record cte query icinde olmaliydi")
	}

	if len(db.lastArgs) != 6 {
		t.Fatalf("beklenen 6 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestReserveDedupeRecordSQLStoreReserveOrCheckRecord_ExistingSuccess(t *testing.T) {
	expiresAt := time.Date(2026, 4, 25, 18, 10, 0, 0, time.UTC)

	db := &dedupeReserveQueryRowProviderMock{
		row: &dedupeReserveRowMock{
			values: []any{"ded-2", "existing", "sync-batch-123", expiresAt},
		},
	}

	store := NewReserveDedupeRecordSQLStore(db)

	result, err := store.ReserveOrCheckRecord(context.Background(), ReserveDedupeRecordCommand{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-002",
		PayloadHash: "hash-002",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Status != "existing" {
		t.Fatalf("beklenen status existing, alinan: %s", result.Status)
	}

	if result.ExistingValueRef != "sync-batch-123" {
		t.Fatalf("beklenen existing_value_ref sync-batch-123, alinan: %s", result.ExistingValueRef)
	}
}

func TestReserveDedupeRecordSQLStoreReserveOrCheckRecord_ConflictSuccess(t *testing.T) {
	expiresAt := time.Date(2026, 4, 25, 18, 15, 0, 0, time.UTC)

	db := &dedupeReserveQueryRowProviderMock{
		row: &dedupeReserveRowMock{
			values: []any{"ded-3", "conflict", "", expiresAt},
		},
	}

	store := NewReserveDedupeRecordSQLStore(db)

	result, err := store.ReserveOrCheckRecord(context.Background(), ReserveDedupeRecordCommand{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-003",
		PayloadHash: "hash-different",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Status != "conflict" {
		t.Fatalf("beklenen status conflict, alinan: %s", result.Status)
	}
}

func TestReserveDedupeRecordSQLStoreReserveOrCheckRecord_NoDB(t *testing.T) {
	store := NewReserveDedupeRecordSQLStore(nil)

	_, err := store.ReserveOrCheckRecord(context.Background(), ReserveDedupeRecordCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestReserveDedupeRecordSQLStoreReserveOrCheckRecord_ScanError(t *testing.T) {
	db := &dedupeReserveQueryRowProviderMock{
		row: &dedupeReserveRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewReserveDedupeRecordSQLStore(db)

	_, err := store.ReserveOrCheckRecord(context.Background(), ReserveDedupeRecordCommand{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
