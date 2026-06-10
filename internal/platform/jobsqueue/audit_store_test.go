package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type auditRowMock struct {
	values []any
	err    error
}

func (r *auditRowMock) Scan(dest ...any) error {
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

type auditQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *auditQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestJobAuditSQLStoreRecordJobAuditEvent_Success(t *testing.T) {
	db := &auditQueryRowProviderMock{
		row: &auditRowMock{
			values: []any{"audit-1"},
		},
	}

	store := NewJobAuditSQLStore(db)

	result, err := store.RecordJobAuditEvent(context.Background(), RecordJobAuditEventCommand{
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

	if result.AuditID != "audit-1" {
		t.Fatalf("beklenen audit_id audit-1, alinan: %s", result.AuditID)
	}

	if !strings.Contains(db.lastQuery, "runtime.jobs") {
		t.Fatalf("jobs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.job_attempts") {
		t.Fatalf("job_attempts query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "inserted_audit") {
		t.Fatalf("inserted_audit cte query icinde olmaliydi")
	}

	if len(db.lastArgs) != 8 {
		t.Fatalf("beklenen 8 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestJobAuditSQLStoreRecordJobAuditEvent_NoDB(t *testing.T) {
	store := NewJobAuditSQLStore(nil)

	_, err := store.RecordJobAuditEvent(context.Background(), RecordJobAuditEventCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestJobAuditSQLStoreRecordJobAuditEvent_ScanError(t *testing.T) {
	db := &auditQueryRowProviderMock{
		row: &auditRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewJobAuditSQLStore(db)

	_, err := store.RecordJobAuditEvent(context.Background(), RecordJobAuditEventCommand{
		TenantID:  "tenant-a",
		JobID:     "job-1",
		EventType: "claimed",
		ActorRef:  "worker-01",
		Status:    "processing",
		AttemptNo: 1,
		Message:   "worker job claim etti",
		Metadata:  map[string]any{"lease_seconds": 60},
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
