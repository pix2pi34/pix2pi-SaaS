package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type claimRowMock struct {
	values []any
	err    error
}

func (r *claimRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *int:
			*d = r.values[i].(int)
		case *map[string]any:
			*d = r.values[i].(map[string]any)
		case *time.Time:
			*d = r.values[i].(time.Time)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type claimQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *claimQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestClaimSQLStoreClaimNextJob_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 25, 9, 1, 0, 0, time.UTC)

	db := &claimQueryRowProviderMock{
		row: &claimRowMock{
			values: []any{
				"job-1",
				"notifications-email",
				"job-email-001",
				"email.send",
				"high",
				"processing",
				1,
				map[string]any{"template": "welcome"},
				leaseExpiresAt,
			},
		},
	}

	store := NewClaimSQLStore(db)

	result, err := store.ClaimNextJob(context.Background(), ClaimJobCommand{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !result.Claimed {
		t.Fatalf("beklenen claimed true")
	}

	if result.JobID != "job-1" {
		t.Fatalf("beklenen job_id job-1, alinan: %s", result.JobID)
	}

	if result.AttemptNo != 1 {
		t.Fatalf("beklenen attempt_no 1, alinan: %d", result.AttemptNo)
	}

	if result.LeaseExpiresAt == nil || !result.LeaseExpiresAt.Equal(leaseExpiresAt) {
		t.Fatalf("beklenen lease_expires_at korunmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.job_queues") {
		t.Fatalf("job_queues query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.jobs") {
		t.Fatalf("jobs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "candidate_job") {
		t.Fatalf("candidate_job cte query icinde olmaliydi")
	}

	if len(db.lastArgs) != 4 {
		t.Fatalf("beklenen 4 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestClaimSQLStoreClaimNextJob_NoDB(t *testing.T) {
	store := NewClaimSQLStore(nil)

	_, err := store.ClaimNextJob(context.Background(), ClaimJobCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestClaimSQLStoreClaimNextJob_ScanError(t *testing.T) {
	db := &claimQueryRowProviderMock{
		row: &claimRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewClaimSQLStore(db)

	_, err := store.ClaimNextJob(context.Background(), ClaimJobCommand{
		TenantID:     "tenant-a",
		QueueKey:     "notifications-email",
		WorkerID:     "worker-01",
		LeaseSeconds: 60,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
