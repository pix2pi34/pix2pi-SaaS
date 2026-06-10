package workflow

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type workflowStepCompleteRowMock struct {
	values []any
	err    error
}

func (r *workflowStepCompleteRowMock) Scan(dest ...any) error {
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

type workflowStepCompleteQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *workflowStepCompleteQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestCompleteWorkflowStepSQLStoreCompleteStep_Success(t *testing.T) {
	db := &workflowStepCompleteQueryRowProviderMock{
		row: &workflowStepCompleteRowMock{
			values: []any{
				"wf-run-001",
				"service-step-1",
				"completed",
				1,
				"output-001",
				"",
				"basariyla tamamlandi",
				true,
			},
		},
	}

	store := NewCompleteWorkflowStepSQLStore(db)

	result, err := store.CompleteStep(context.Background(), CompleteWorkflowStepCommand{
		TenantID:       "tenant-a",
		WorkflowRunID:  "wf-run-001",
		StepKey:        "service-step-1",
		WorkerID:       "worker-01",
		Status:         "completed",
		AttemptNo:      1,
		OutputRef:      "output-001",
		ErrorCode:      "",
		CompletionNote: "basariyla tamamlandi",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.WorkflowRunID != "wf-run-001" {
		t.Fatalf("beklenen workflow_run_id wf-run-001, alinan: %s", result.WorkflowRunID)
	}

	if result.StepKey != "service-step-1" {
		t.Fatalf("beklenen step_key service-step-1, alinan: %s", result.StepKey)
	}

	if result.Status != "completed" {
		t.Fatalf("beklenen status completed, alinan: %s", result.Status)
	}

	if result.AttemptNo != 1 {
		t.Fatalf("beklenen attempt_no 1, alinan: %d", result.AttemptNo)
	}

	if result.OutputRef != "output-001" {
		t.Fatalf("beklenen output_ref output-001, alinan: %s", result.OutputRef)
	}

	if result.CompletionNote != "basariyla tamamlandi" {
		t.Fatalf("beklenen completion_note basariyla tamamlandi, alinan: %s", result.CompletionNote)
	}

	if !result.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_steps") {
		t.Fatalf("workflow_steps query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lease_expires_at = NULL") {
		t.Fatalf("lease release query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "coalesce(ws.attempt_no, 0) = $6") {
		t.Fatalf("attempt kontrolu query icinde olmaliydi")
	}

	if len(db.lastArgs) != 9 {
		t.Fatalf("beklenen 9 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestCompleteWorkflowStepSQLStoreCompleteStep_FailedSuccess(t *testing.T) {
	db := &workflowStepCompleteQueryRowProviderMock{
		row: &workflowStepCompleteRowMock{
			values: []any{
				"wf-run-002",
				"service-step-2",
				"failed",
				2,
				"",
				"TIMEOUT",
				"servis timeout verdi",
				true,
			},
		},
	}

	store := NewCompleteWorkflowStepSQLStore(db)

	result, err := store.CompleteStep(context.Background(), CompleteWorkflowStepCommand{
		WorkflowRunID:  "wf-run-002",
		StepKey:        "service-step-2",
		WorkerID:       "worker-02",
		Status:         "failed",
		AttemptNo:      2,
		OutputRef:      "",
		ErrorCode:      "TIMEOUT",
		CompletionNote: "servis timeout verdi",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ErrorCode != "TIMEOUT" {
		t.Fatalf("beklenen error_code TIMEOUT, alinan: %s", result.ErrorCode)
	}
}

func TestCompleteWorkflowStepSQLStoreCompleteStep_NoDB(t *testing.T) {
	store := NewCompleteWorkflowStepSQLStore(nil)

	_, err := store.CompleteStep(context.Background(), CompleteWorkflowStepCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestCompleteWorkflowStepSQLStoreCompleteStep_ScanError(t *testing.T) {
	db := &workflowStepCompleteQueryRowProviderMock{
		row: &workflowStepCompleteRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewCompleteWorkflowStepSQLStore(db)

	_, err := store.CompleteStep(context.Background(), CompleteWorkflowStepCommand{
		TenantID:       "tenant-a",
		WorkflowRunID:  "wf-run-001",
		StepKey:        "service-step-1",
		WorkerID:       "worker-01",
		Status:         "completed",
		AttemptNo:      1,
		OutputRef:      "output-001",
		CompletionNote: "basariyla tamamlandi",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
