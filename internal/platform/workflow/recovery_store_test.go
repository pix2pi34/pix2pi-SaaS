package workflow

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type workflowRecoveryRowMock struct {
	values []any
	err    error
}

func (r *workflowRecoveryRowMock) Scan(dest ...any) error {
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

type workflowRecoveryQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *workflowRecoveryQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestApplyWorkflowRecoverySQLStoreApplyRecovery_RetrySuccess(t *testing.T) {
	db := &workflowRecoveryQueryRowProviderMock{
		row: &workflowRecoveryRowMock{
			values: []any{
				"wf-run-001",
				"service-step-1",
				"retry",
				"pending",
				"pending",
				0,
				"",
				true,
			},
		},
	}

	store := NewApplyWorkflowRecoverySQLStore(db)

	result, err := store.ApplyRecovery(context.Background(), ApplyWorkflowRecoveryCommand{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "gecici hata temizlendi",
		ResetAttempts: true,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.WorkflowRunID != "wf-run-001" {
		t.Fatalf("beklenen workflow_run_id wf-run-001, alinan: %s", result.WorkflowRunID)
	}

	if result.StepStatus != "pending" {
		t.Fatalf("beklenen step_status pending, alinan: %s", result.StepStatus)
	}

	if result.WorkflowState != "pending" {
		t.Fatalf("beklenen workflow_state pending, alinan: %s", result.WorkflowState)
	}

	if result.AttemptNo != 0 {
		t.Fatalf("beklenen attempt_no 0, alinan: %d", result.AttemptNo)
	}

	if !result.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_steps") {
		t.Fatalf("workflow_steps query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_runs") {
		t.Fatalf("workflow_runs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "lease_expires_at = NULL") {
		t.Fatalf("lease release query icinde olmaliydi")
	}

	if len(db.lastArgs) != 8 {
		t.Fatalf("beklenen 8 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestApplyWorkflowRecoverySQLStoreApplyRecovery_CompensateSuccess(t *testing.T) {
	db := &workflowRecoveryQueryRowProviderMock{
		row: &workflowRecoveryRowMock{
			values: []any{
				"wf-run-002",
				"service-step-2",
				"compensate",
				"compensating",
				"failed",
				2,
				"comp-001",
				true,
			},
		},
	}

	store := NewApplyWorkflowRecoverySQLStore(db)

	result, err := store.ApplyRecovery(context.Background(), ApplyWorkflowRecoveryCommand{
		WorkflowRunID:   "wf-run-002",
		StepKey:         "service-step-2",
		ActionType:      "compensate",
		RequestedBy:     "worker-02",
		Reason:          "rollback gerekli",
		ResetAttempts:   false,
		CompensationRef: "comp-001",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.StepStatus != "compensating" {
		t.Fatalf("beklenen step_status compensating, alinan: %s", result.StepStatus)
	}

	if result.WorkflowState != "failed" {
		t.Fatalf("beklenen workflow_state failed, alinan: %s", result.WorkflowState)
	}

	if result.CompensationRef != "comp-001" {
		t.Fatalf("beklenen compensation_ref comp-001, alinan: %s", result.CompensationRef)
	}
}

func TestApplyWorkflowRecoverySQLStoreApplyRecovery_NoDB(t *testing.T) {
	store := NewApplyWorkflowRecoverySQLStore(nil)

	_, err := store.ApplyRecovery(context.Background(), ApplyWorkflowRecoveryCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestApplyWorkflowRecoverySQLStoreApplyRecovery_ScanError(t *testing.T) {
	db := &workflowRecoveryQueryRowProviderMock{
		row: &workflowRecoveryRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewApplyWorkflowRecoverySQLStore(db)

	_, err := store.ApplyRecovery(context.Background(), ApplyWorkflowRecoveryCommand{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "yeniden dene",
		ResetAttempts: true,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
