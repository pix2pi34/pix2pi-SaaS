package idempotency

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type dedupeFinalizeRowMock struct {
	values []any
	err    error
}

func (r *dedupeFinalizeRowMock) Scan(dest ...any) error {
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

type dedupeFinalizeQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *dedupeFinalizeQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestFinalizeDedupeRecordSQLStoreFinalizeRecord_CompletedSuccess(t *testing.T) {
	db := &dedupeFinalizeQueryRowProviderMock{
		row: &dedupeFinalizeRowMock{
			values: []any{"ded-1", "batch-123", "completed"},
		},
	}

	store := NewFinalizeDedupeRecordSQLStore(db)

	result, err := store.FinalizeRecord(context.Background(), FinalizeDedupeRecordCommand{
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

	if result.RecordID != "ded-1" {
		t.Fatalf("beklenen record_id ded-1, alinan: %s", result.RecordID)
	}

	if result.ValueRef != "batch-123" {
		t.Fatalf("beklenen value_ref batch-123, alinan: %s", result.ValueRef)
	}

	if result.FinalStatus != "completed" {
		t.Fatalf("beklenen final_status completed, alinan: %s", result.FinalStatus)
	}

	if !strings.Contains(db.lastQuery, "runtime.dedupe_records") {
		t.Fatalf("dedupe_records query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "value_ref = $5") {
		t.Fatalf("value_ref update query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "status = $6") {
		t.Fatalf("status update query icinde olmaliydi")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestFinalizeDedupeRecordSQLStoreFinalizeRecord_FailedSuccess(t *testing.T) {
	db := &dedupeFinalizeQueryRowProviderMock{
		row: &dedupeFinalizeRowMock{
			values: []any{"ded-2", "error-500", "failed"},
		},
	}

	store := NewFinalizeDedupeRecordSQLStore(db)

	result, err := store.FinalizeRecord(context.Background(), FinalizeDedupeRecordCommand{
		TenantID:    "tenant-a",
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

	if result.FinalStatus != "failed" {
		t.Fatalf("beklenen final_status failed, alinan: %s", result.FinalStatus)
	}
}

func TestFinalizeDedupeRecordSQLStoreFinalizeRecord_NoDB(t *testing.T) {
	store := NewFinalizeDedupeRecordSQLStore(nil)

	_, err := store.FinalizeRecord(context.Background(), FinalizeDedupeRecordCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestFinalizeDedupeRecordSQLStoreFinalizeRecord_ScanError(t *testing.T) {
	db := &dedupeFinalizeQueryRowProviderMock{
		row: &dedupeFinalizeRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewFinalizeDedupeRecordSQLStore(db)

	_, err := store.FinalizeRecord(context.Background(), FinalizeDedupeRecordCommand{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		ValueRef:    "batch-123",
		FinalStatus: "completed",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
