package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type enqueueRowMock struct {
	values []any
	err    error
}

func (r *enqueueRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type enqueueQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *enqueueQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestEnqueueSQLStoreEnqueueJob_Success(t *testing.T) {
	db := &enqueueQueryRowProviderMock{
		row: &enqueueRowMock{
			values: []any{"job-1", "queued", false},
		},
	}

	store := NewEnqueueSQLStore(db)

	result, err := store.EnqueueJob(context.Background(), EnqueueJobCommand{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-email-001",
		JobType:     "email.send",
		Priority:    "high",
		DedupKey:    "email-user-1",
		Payload:     map[string]any{"template": "welcome"},
		RequestedBy: "system-api",
		MaxAttempts: 5,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.JobID != "job-1" {
		t.Fatalf("beklenen job_id job-1, alinan: %s", result.JobID)
	}

	if result.Status != "queued" {
		t.Fatalf("beklenen status queued, alinan: %s", result.Status)
	}

	if result.DedupMatched {
		t.Fatalf("beklenen dedup false")
	}

	if !strings.Contains(db.lastQuery, "runtime.job_queues") {
		t.Fatalf("job_queues query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.jobs") {
		t.Fatalf("jobs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "dedup_match") {
		t.Fatalf("dedup_match cte query icinde olmaliydi")
	}

	if len(db.lastArgs) != 10 {
		t.Fatalf("beklenen 10 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestEnqueueSQLStoreEnqueueJob_DedupMatched(t *testing.T) {
	db := &enqueueQueryRowProviderMock{
		row: &enqueueRowMock{
			values: []any{"job-existing-1", "queued", true},
		},
	}

	store := NewEnqueueSQLStore(db)

	result, err := store.EnqueueJob(context.Background(), EnqueueJobCommand{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-email-002",
		JobType:     "email.send",
		Priority:    "normal",
		DedupKey:    "email-user-1",
		Payload:     map[string]any{"template": "welcome"},
		RequestedBy: "system-api",
		MaxAttempts: 3,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !result.DedupMatched {
		t.Fatalf("beklenen dedup true")
	}

	if result.JobID != "job-existing-1" {
		t.Fatalf("beklenen mevcut job id job-existing-1, alinan: %s", result.JobID)
	}
}

func TestEnqueueSQLStoreEnqueueJob_NoDB(t *testing.T) {
	store := NewEnqueueSQLStore(nil)

	_, err := store.EnqueueJob(context.Background(), EnqueueJobCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestEnqueueSQLStoreEnqueueJob_ScanError(t *testing.T) {
	db := &enqueueQueryRowProviderMock{
		row: &enqueueRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewEnqueueSQLStore(db)

	_, err := store.EnqueueJob(context.Background(), EnqueueJobCommand{
		TenantID:    "tenant-a",
		QueueKey:    "notifications-email",
		JobKey:      "job-email-001",
		JobType:     "email.send",
		Priority:    "high",
		RequestedBy: "system-api",
		MaxAttempts: 5,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
