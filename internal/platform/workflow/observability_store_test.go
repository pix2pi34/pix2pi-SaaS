package workflow

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type workflowObservabilityRowMock struct {
	values []any
	err    error
}

func (r *workflowObservabilityRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *int:
			*d = r.values[i].(int)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type workflowObservabilityQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *workflowObservabilityQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestLoadWorkflowObservabilitySQLStoreLoadObservability_Success(t *testing.T) {
	db := &workflowObservabilityQueryRowProviderMock{
		row: &workflowObservabilityRowMock{
			values: []any{
				"wf-run-001",
				"purchase_approval",
				"in_progress",
				3,
				1,
				1,
				1,
				0,
				1,
				1,
				0,
				`[
					{
						"step_key":"submit-step",
						"step_type":"task",
						"status":"completed",
						"attempt_no":1,
						"worker_id":"worker-01",
						"lease_expires_at":null,
						"last_error_code":""
					},
					{
						"step_key":"approval-step-1",
						"step_type":"approval",
						"status":"in_progress",
						"attempt_no":1,
						"worker_id":"worker-02",
						"lease_expires_at":"2026-04-26T02:05:00Z",
						"last_error_code":""
					}
				]`,
			},
		},
	}

	store := NewLoadWorkflowObservabilitySQLStore(db)

	result, err := store.LoadObservability(context.Background(), LoadWorkflowObservabilityCommand{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.WorkflowRunID != "wf-run-001" {
		t.Fatalf("beklenen workflow_run_id wf-run-001, alinan: %s", result.WorkflowRunID)
	}

	if result.DefinitionKey != "purchase_approval" {
		t.Fatalf("beklenen definition_key purchase_approval, alinan: %s", result.DefinitionKey)
	}

	if result.WorkflowState != "in_progress" {
		t.Fatalf("beklenen workflow_state in_progress, alinan: %s", result.WorkflowState)
	}

	if result.Summary.TotalSteps != 3 {
		t.Fatalf("beklenen total_steps 3, alinan: %d", result.Summary.TotalSteps)
	}

	if result.Summary.PendingApprovals != 1 {
		t.Fatalf("beklenen pending_approvals 1, alinan: %d", result.Summary.PendingApprovals)
	}

	if len(result.Steps) != 2 {
		t.Fatalf("beklenen 2 step, alinan: %d", len(result.Steps))
	}

	if result.Steps[1].StepType != "approval" {
		t.Fatalf("beklenen ikinci step approval, alinan: %s", result.Steps[1].StepType)
	}

	if result.Steps[1].LeaseExpiresAt == nil {
		t.Fatalf("beklenen ikinci step lease_expires_at dolu olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_runs") {
		t.Fatalf("workflow_runs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_steps") {
		t.Fatalf("workflow_steps query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_approvals") {
		t.Fatalf("workflow_approvals query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "step_summary") {
		t.Fatalf("step_summary cte query icinde olmaliydi")
	}

	if len(db.lastArgs) != 2 {
		t.Fatalf("beklenen 2 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestLoadWorkflowObservabilitySQLStoreLoadObservability_EmptyStepsJSONSuccess(t *testing.T) {
	db := &workflowObservabilityQueryRowProviderMock{
		row: &workflowObservabilityRowMock{
			values: []any{
				"wf-run-002",
				"simple_flow",
				"draft",
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				"[]",
			},
		},
	}

	store := NewLoadWorkflowObservabilitySQLStore(db)

	result, err := store.LoadObservability(context.Background(), LoadWorkflowObservabilityCommand{
		WorkflowRunID: "wf-run-002",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if len(result.Steps) != 0 {
		t.Fatalf("beklenen 0 step, alinan: %d", len(result.Steps))
	}
}

func TestLoadWorkflowObservabilitySQLStoreLoadObservability_InvalidJSON(t *testing.T) {
	db := &workflowObservabilityQueryRowProviderMock{
		row: &workflowObservabilityRowMock{
			values: []any{
				"wf-run-003",
				"broken_flow",
				"failed",
				1,
				0,
				0,
				0,
				1,
				0,
				0,
				0,
				"{invalid-json}",
			},
		},
	}

	store := NewLoadWorkflowObservabilitySQLStore(db)

	_, err := store.LoadObservability(context.Background(), LoadWorkflowObservabilityCommand{
		WorkflowRunID: "wf-run-003",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen json parse hatasi")
	}
}

func TestLoadWorkflowObservabilitySQLStoreLoadObservability_NoDB(t *testing.T) {
	store := NewLoadWorkflowObservabilitySQLStore(nil)

	_, err := store.LoadObservability(context.Background(), LoadWorkflowObservabilityCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestLoadWorkflowObservabilitySQLStoreLoadObservability_ScanError(t *testing.T) {
	db := &workflowObservabilityQueryRowProviderMock{
		row: &workflowObservabilityRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewLoadWorkflowObservabilitySQLStore(db)

	_, err := store.LoadObservability(context.Background(), LoadWorkflowObservabilityCommand{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
