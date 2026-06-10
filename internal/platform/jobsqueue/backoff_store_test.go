package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type backoffRowMock struct {
	values []any
	err    error
}

func (r *backoffRowMock) Scan(dest ...any) error {
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
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type backoffQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *backoffQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestBackoffSQLStoreScheduleJobRetry_Success(t *testing.T) {
	retryAt := time.Date(2026, 4, 25, 14, 5, 0, 0, time.UTC)

	db := &backoffQueryRowProviderMock{
		row: &backoffRowMock{
			values: []any{
				"job-1",
				"scheduled",
				2,
				300,
				retryAt,
				true,
			},
		},
	}

	store := NewBackoffSQLStore(db)

	result, err := store.ScheduleJobRetry(context.Background(), ScheduleJobBackoffCommand{
		TenantID:            "tenant-a",
		JobID:               "job-1",
		AttemptNo:           2,
		PlannedDelaySeconds: 300,
		RetryAt:             retryAt,
		LastErrorCode:       "EMAIL_TIMEOUT",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.JobID != "job-1" {
		t.Fatalf("beklenen job_id job-1, alinan: %s", result.JobID)
	}

	if result.Status != "scheduled" {
		t.Fatalf("beklenen status scheduled, alinan: %s", result.Status)
	}

	if result.AttemptNo != 2 {
		t.Fatalf("beklenen attempt_no 2, alinan: %d", result.AttemptNo)
	}

	if result.PlannedDelaySeconds != 300 {
		t.Fatalf("beklenen planned_delay_seconds 300, alinan: %d", result.PlannedDelaySeconds)
	}

	if !result.RetryAt.Equal(retryAt) {
		t.Fatalf("beklenen retry_at korunmaliydi")
	}

	if !result.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !strings.Contains(db.lastQuery, "runtime.jobs") {
		t.Fatalf("jobs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "scheduled_at = $4") {
		t.Fatalf("scheduled_at update query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lease_expires_at = NULL") {
		t.Fatalf("lease release query icinde olmaliydi")
	}

	if len(db.lastArgs) != 5 {
		t.Fatalf("beklenen 5 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestBackoffSQLStoreScheduleJobRetry_NoDB(t *testing.T) {
	store := NewBackoffSQLStore(nil)

	_, err := store.ScheduleJobRetry(context.Background(), ScheduleJobBackoffCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestBackoffSQLStoreScheduleJobRetry_ScanError(t *testing.T) {
	retryAt := time.Date(2026, 4, 25, 14, 5, 0, 0, time.UTC)

	db := &backoffQueryRowProviderMock{
		row: &backoffRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewBackoffSQLStore(db)

	_, err := store.ScheduleJobRetry(context.Background(), ScheduleJobBackoffCommand{
		TenantID:            "tenant-a",
		JobID:               "job-1",
		AttemptNo:           2,
		PlannedDelaySeconds: 300,
		RetryAt:             retryAt,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
