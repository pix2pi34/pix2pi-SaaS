package workflow

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type workflowStateMachineRowMock struct {
	values []any
	err    error
}

func (r *workflowStateMachineRowMock) Scan(dest ...any) error {
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

type workflowStateMachineQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *workflowStateMachineQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestApplyWorkflowTransitionSQLStoreApplyTransition_Success(t *testing.T) {
	db := &workflowStateMachineQueryRowProviderMock{
		row: &workflowStateMachineRowMock{
			values: []any{
				"wf-run-001",
				"purchase_approval",
				"draft",
				"submit",
				"pending",
				true,
				"",
			},
		},
	}

	store := NewApplyWorkflowTransitionSQLStore(db)

	result, err := store.ApplyTransition(context.Background(), ApplyWorkflowTransitionCommand{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "draft",
		Action:        "submit",
		RequestedBy:   "worker-01",
		ContextVars:   map[string]any{"amount": 1500},
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.WorkflowRunID != "wf-run-001" {
		t.Fatalf("beklenen workflow_run_id wf-run-001, alinan: %s", result.WorkflowRunID)
	}

	if result.NextState != "pending" {
		t.Fatalf("beklenen next_state pending, alinan: %s", result.NextState)
	}

	if !result.TransitionAllowed {
		t.Fatalf("beklenen transition_allowed true")
	}

	if !strings.Contains(db.lastQuery, "runtime.workflow_runs") {
		t.Fatalf("workflow_runs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "transition_rules") {
		t.Fatalf("transition_rules cte query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "current_state = tr.next_state") {
		t.Fatalf("state update query icinde olmaliydi")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestApplyWorkflowTransitionSQLStoreApplyTransition_NotAllowed(t *testing.T) {
	db := &workflowStateMachineQueryRowProviderMock{
		row: &workflowStateMachineRowMock{
			values: []any{
				"wf-run-002",
				"purchase_approval",
				"draft",
				"approve",
				"",
				false,
				"transition not allowed",
			},
		},
	}

	store := NewApplyWorkflowTransitionSQLStore(db)

	result, err := store.ApplyTransition(context.Background(), ApplyWorkflowTransitionCommand{
		WorkflowRunID: "wf-run-002",
		DefinitionKey: "purchase_approval",
		CurrentState:  "draft",
		Action:        "approve",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.TransitionAllowed {
		t.Fatalf("beklenen transition_allowed false")
	}

	if result.Reason != "transition not allowed" {
		t.Fatalf("beklenen reason transition not allowed, alinan: %s", result.Reason)
	}
}

func TestApplyWorkflowTransitionSQLStoreApplyTransition_NoDB(t *testing.T) {
	store := NewApplyWorkflowTransitionSQLStore(nil)

	_, err := store.ApplyTransition(context.Background(), ApplyWorkflowTransitionCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestApplyWorkflowTransitionSQLStoreApplyTransition_ScanError(t *testing.T) {
	db := &workflowStateMachineQueryRowProviderMock{
		row: &workflowStateMachineRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewApplyWorkflowTransitionSQLStore(db)

	_, err := store.ApplyTransition(context.Background(), ApplyWorkflowTransitionCommand{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "draft",
		Action:        "submit",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
