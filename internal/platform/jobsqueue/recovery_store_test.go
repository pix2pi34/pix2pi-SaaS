package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type recoveryRowMock struct {
	values []any
	err    error
}

func (r *recoveryRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *int:
			*d = r.values[i].(int)
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type recoveryQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *recoveryQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestRecoverSQLStoreRecoverJob_RetrySuccess(t *testing.T) {
	db := &recoveryQueryRowProviderMock{
		row: &recoveryRowMock{
			values: []any{"job-1", "queued", "notifications-email", 0, true},
		},
	}

	store := NewRecoverSQLStore(db)

	result, err := store.RecoverJob(context.Background(), RecoverJobCommand{
		TenantID:       "tenant-a",
		JobID:          "job-1",
		ActionType:     "retry",
		RequestedBy:    "worker-01",
		Reason:         "transient error temizlendi",
		ResetAttempts:  true,
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

	if result.AttemptNo != 0 {
		t.Fatalf("beklenen attempt_no 0, alinan: %d", result.AttemptNo)
	}

	if !result.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !strings.Contains(db.lastQuery, "runtime.jobs") {
		t.Fatalf("jobs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "target_queue") {
		t.Fatalf("target_queue cte query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lease_expires_at = NULL") {
		t.Fatalf("lease release query icinde olmaliydi")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestRecoverSQLStoreRecoverJob_RequeueSuccess(t *testing.T) {
	db := &recoveryQueryRowProviderMock{
		row: &recoveryRowMock{
			values: []any{"job-2", "queued", "priority-critical", 3, true},
		},
	}

	store := NewRecoverSQLStore(db)

	result, err := store.RecoverJob(context.Background(), RecoverJobCommand{
		TenantID:       "tenant-a",
		JobID:          "job-2",
		ActionType:     "requeue",
		RequestedBy:    "worker-02",
		TargetQueueKey: "priority-critical",
		Reason:         "daha yuksek kuyruğa tasi",
		ResetAttempts:  false,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.QueueKey != "priority-critical" {
		t.Fatalf("beklenen queue_key priority-critical, alinan: %s", result.QueueKey)
	}
}

func TestRecoverSQLStoreRecoverJob_DeadLetterSuccess(t *testing.T) {
	db := &recoveryQueryRowProviderMock{
		row: &recoveryRowMock{
			values: []any{"job-3", "dead_letter", "notifications-email", 5, true},
		},
	}

	store := NewRecoverSQLStore(db)

	result, err := store.RecoverJob(context.Background(), RecoverJobCommand{
		TenantID:      "tenant-a",
		JobID:         "job-3",
		ActionType:    "dead_letter",
		RequestedBy:   "worker-03",
		Reason:        "kalici hata",
		ResetAttempts: false,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Status != "dead_letter" {
		t.Fatalf("beklenen status dead_letter, alinan: %s", result.Status)
	}
}

func TestRecoverSQLStoreRecoverJob_NoDB(t *testing.T) {
	store := NewRecoverSQLStore(nil)

	_, err := store.RecoverJob(context.Background(), RecoverJobCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestRecoverSQLStoreRecoverJob_ScanError(t *testing.T) {
	db := &recoveryQueryRowProviderMock{
		row: &recoveryRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewRecoverSQLStore(db)

	_, err := store.RecoverJob(context.Background(), RecoverJobCommand{
		TenantID:      "tenant-a",
		JobID:         "job-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "yeniden dene",
		ResetAttempts: true,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
