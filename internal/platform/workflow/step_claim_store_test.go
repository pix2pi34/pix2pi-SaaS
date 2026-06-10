package workflow

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

type workflowStepClaimRowMock struct {
	values []any
	err    error
}

func (r *workflowStepClaimRowMock) Scan(dest ...any) error {
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

type workflowStepClaimQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *workflowStepClaimQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestClaimWorkflowStepSQLStoreClaimStep_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 25, 23, 31, 0, 0, time.UTC)

	db := &workflowStepClaimQueryRowProviderMock{
		row: &workflowStepClaimRowMock{
			values: []any{
				"wf-run-001",
				"approval-step-1",
				"approval",
				"in_progress",
				1,
				leaseExpiresAt,
			},
		},
	}

	store := NewClaimWorkflowStepSQLStore(db)

	result, err := store.ClaimStep(context.Background(), ClaimWorkflowStepCommand{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		WorkerID:      "worker-01",
		LeaseSeconds:  60,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !result.Claimed {
		t.Fatalf("beklenen claimed true")
	}

	if result.WorkflowRunID != "wf-run-001" {
		t.Fatalf("beklenen workflow_run_id wf-run-001, alinan: %s", result.WorkflowRunID)
	}

	if result.StepKey != "approval-step-1" {
		t.Fatalf("beklenen step_key approval-step-1, alinan: %s", result.StepKey)
	}

	if result.StepType != "approval" {
		t.Fatalf("beklenen step_type approval, alinan: %s", result.StepType)
	}

	if result.Status != "in_progress" {
		t.Fatalf("beklenen status in_progress, alinan: %s", result.Status)
	}

	if result.AttemptNo != 1 {
		t.Fatalf("beklenen attempt_no 1, alinan: %d", result.AttemptNo)
	}

	if result.LeaseExpiresAt == nil || !result.LeaseExpiresAt.Equal(leaseExpiresAt) {
		t.Fatalf("beklenen lease_expires_at korunmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_steps") {
		t.Fatalf("workflow_steps query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "status = 'in_progress'") {
		t.Fatalf("status update query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "attempt_no = coalesce(ws.attempt_no, 0) + 1") {
		t.Fatalf("attempt artisi query icinde olmaliydi")
	}

	if len(db.lastArgs) != 5 {
		t.Fatalf("beklenen 5 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestClaimWorkflowStepSQLStoreClaimStep_NoDB(t *testing.T) {
	store := NewClaimWorkflowStepSQLStore(nil)

	_, err := store.ClaimStep(context.Background(), ClaimWorkflowStepCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestClaimWorkflowStepSQLStoreClaimStep_ScanError(t *testing.T) {
	db := &workflowStepClaimQueryRowProviderMock{
		row: &workflowStepClaimRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewClaimWorkflowStepSQLStore(db)

	_, err := store.ClaimStep(context.Background(), ClaimWorkflowStepCommand{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		WorkerID:      "worker-01",
		LeaseSeconds:  60,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
