package jobsqueue

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type completeRowMock struct {
	values []any
	err    error
}

func (r *completeRowMock) Scan(dest ...any) error {
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
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type completeQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *completeQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestCompleteSQLStoreCompleteJob_Success(t *testing.T) {
	db := &completeQueryRowProviderMock{
		row: &completeRowMock{
			values: []any{
				"job-1",
				"succeeded",
				1,
				"tamamlandi",
				"",
				map[string]any{"sent_count": 10},
				true,
			},
		},
	}

	store := NewCompleteSQLStore(db)

	result, err := store.CompleteJob(context.Background(), CompleteJobCommand{
		TenantID:       "tenant-a",
		JobID:          "job-1",
		WorkerID:       "worker-01",
		Status:         "succeeded",
		AttemptNo:      1,
		CompletionNote: "tamamlandi",
		OutputPayload:  map[string]any{"sent_count": 10},
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.JobID != "job-1" {
		t.Fatalf("beklenen job_id job-1, alinan: %s", result.JobID)
	}

	if result.Status != "succeeded" {
		t.Fatalf("beklenen status succeeded, alinan: %s", result.Status)
	}

	if result.AttemptNo != 1 {
		t.Fatalf("beklenen attempt_no 1, alinan: %d", result.AttemptNo)
	}

	if !result.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !strings.Contains(db.lastQuery, "runtime.jobs") {
		t.Fatalf("jobs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lease_expires_at = NULL") {
		t.Fatalf("lease release query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "attempt_no") {
		t.Fatalf("attempt_no query icinde olmaliydi")
	}

	if len(db.lastArgs) != 8 {
		t.Fatalf("beklenen 8 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestCompleteSQLStoreCompleteJob_FailedSuccess(t *testing.T) {
	db := &completeQueryRowProviderMock{
		row: &completeRowMock{
			values: []any{
				"job-2",
				"failed",
				2,
				"provider timeout",
				"EMAIL_TIMEOUT",
				map[string]any{},
				true,
			},
		},
	}

	store := NewCompleteSQLStore(db)

	result, err := store.CompleteJob(context.Background(), CompleteJobCommand{
		TenantID:       "tenant-a",
		JobID:          "job-2",
		WorkerID:       "worker-02",
		Status:         "failed",
		AttemptNo:      2,
		CompletionNote: "provider timeout",
		ErrorCode:      "EMAIL_TIMEOUT",
		OutputPayload:  map[string]any{},
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ErrorCode != "EMAIL_TIMEOUT" {
		t.Fatalf("beklenen error_code EMAIL_TIMEOUT, alinan: %s", result.ErrorCode)
	}
}

func TestCompleteSQLStoreCompleteJob_NoDB(t *testing.T) {
	store := NewCompleteSQLStore(nil)

	_, err := store.CompleteJob(context.Background(), CompleteJobCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestCompleteSQLStoreCompleteJob_ScanError(t *testing.T) {
	db := &completeQueryRowProviderMock{
		row: &completeRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewCompleteSQLStore(db)

	_, err := store.CompleteJob(context.Background(), CompleteJobCommand{
		TenantID:       "tenant-a",
		JobID:          "job-1",
		WorkerID:       "worker-01",
		Status:         "cancelled",
		AttemptNo:      1,
		CompletionNote: "iptal edildi",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
