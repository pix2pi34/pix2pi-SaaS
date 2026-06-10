package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type progressRowMock struct {
	values []any
	err    error
}

func (r *progressRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *int:
			*d = r.values[i].(int)
		case *time.Time:
			*d = r.values[i].(time.Time)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type progressQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *progressQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestUpdateProgressSQLStoreUpdateJobProgress_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 25, 10, 2, 0, 0, time.UTC)

	db := &progressQueryRowProviderMock{
		row: &progressRowMock{
			values: []any{
				"job-1",
				"processing",
				60,
				1,
				"ikinci batch tamamlandi",
				leaseExpiresAt,
			},
		},
	}

	store := NewUpdateProgressSQLStore(db)

	result, err := store.UpdateJobProgress(context.Background(), UpdateJobProgressCommand{
		TenantID:           "tenant-a",
		JobID:              "job-1",
		WorkerID:           "worker-01",
		Status:             "processing",
		ProgressPercent:    60,
		Message:            "ikinci batch tamamlandi",
		AttemptNo:          1,
		LeaseExtendSeconds: 120,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.JobID != "job-1" {
		t.Fatalf("beklenen job_id job-1, alinan: %s", result.JobID)
	}

	if result.Status != "processing" {
		t.Fatalf("beklenen status processing, alinan: %s", result.Status)
	}

	if result.ProgressPercent != 60 {
		t.Fatalf("beklenen progress 60, alinan: %d", result.ProgressPercent)
	}

	if result.AttemptNo != 1 {
		t.Fatalf("beklenen attempt_no 1, alinan: %d", result.AttemptNo)
	}

	if result.LeaseExpiresAt == nil || !result.LeaseExpiresAt.Equal(leaseExpiresAt) {
		t.Fatalf("beklenen lease_expires_at korunmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.jobs") {
		t.Fatalf("jobs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lease_expires_at") {
		t.Fatalf("lease_expires_at query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "attempt_no") {
		t.Fatalf("attempt_no query icinde olmaliydi")
	}

	if len(db.lastArgs) != 8 {
		t.Fatalf("beklenen 8 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestUpdateProgressSQLStoreUpdateJobProgress_NoDB(t *testing.T) {
	store := NewUpdateProgressSQLStore(nil)

	_, err := store.UpdateJobProgress(context.Background(), UpdateJobProgressCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestUpdateProgressSQLStoreUpdateJobProgress_ScanError(t *testing.T) {
	db := &progressQueryRowProviderMock{
		row: &progressRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewUpdateProgressSQLStore(db)

	_, err := store.UpdateJobProgress(context.Background(), UpdateJobProgressCommand{
		TenantID:           "tenant-a",
		JobID:              "job-1",
		WorkerID:           "worker-01",
		Status:             "processing",
		ProgressPercent:    50,
		Message:            "heartbeat",
		AttemptNo:          1,
		LeaseExtendSeconds: 60,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
