package workflow

import (
	"context"
	"errors"
	"testing"
	"time"
)

type workflowStateMachineStoreMock struct {
	lastCmd ApplyWorkflowTransitionCommand
	result  ApplyWorkflowTransitionResult
	err     error
	called  bool
}

func (m *workflowStateMachineStoreMock) ApplyTransition(_ context.Context, cmd ApplyWorkflowTransitionCommand) (ApplyWorkflowTransitionResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestApplyWorkflowTransitionRequestValidate_Success(t *testing.T) {
	req := ApplyWorkflowTransitionRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "draft",
		Action:        "submit",
		RequestedBy:   "worker-01",
		ContextVars:   map[string]any{"amount": 1500},
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestApplyWorkflowTransitionRequestValidate_InvalidCurrentState(t *testing.T) {
	req := ApplyWorkflowTransitionRequest{
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "running",
		Action:        "submit",
		RequestedBy:   "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyWorkflowTransitionRequestValidate_InvalidAction(t *testing.T) {
	req := ApplyWorkflowTransitionRequest{
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "draft",
		Action:        "resume",
		RequestedBy:   "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyWorkflowTransitionRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := ApplyWorkflowTransitionRequest{
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "draft",
		Action:        "submit",
		RequestedBy:   "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyWorkflowTransitionUsecaseApply_Success(t *testing.T) {
	store := &workflowStateMachineStoreMock{
		result: ApplyWorkflowTransitionResult{
			WorkflowRunID:     "wf-run-001",
			DefinitionKey:     "purchase_approval",
			PreviousState:     "draft",
			Action:            "submit",
			NextState:         "pending",
			TransitionAllowed: true,
			ContextVars:       map[string]any{"amount": 1500},
		},
	}

	usecase := NewApplyWorkflowTransitionUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 23, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
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

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.WorkflowRunID != "wf-run-001" {
		t.Fatalf("beklenen workflow_run_id wf-run-001, alinan: %s", store.lastCmd.WorkflowRunID)
	}

	if !resp.TransitionAllowed {
		t.Fatalf("beklenen transition_allowed true")
	}

	if resp.NextState != "pending" {
		t.Fatalf("beklenen next_state pending, alinan: %s", resp.NextState)
	}

	if !resp.TransitionedAt.Equal(time.Date(2026, 4, 25, 23, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen transitioned_at sabit zaman")
	}
}

func TestApplyWorkflowTransitionUsecaseApply_FallbackSuccess(t *testing.T) {
	store := &workflowStateMachineStoreMock{
		result: ApplyWorkflowTransitionResult{},
	}

	usecase := NewApplyWorkflowTransitionUsecase(store)

	resp, err := usecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
		WorkflowRunID: "wf-run-002",
		DefinitionKey: "purchase_approval",
		CurrentState:  "waiting_approval",
		Action:        "approve",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !resp.TransitionAllowed {
		t.Fatalf("beklenen fallback transition_allowed true")
	}

	if resp.NextState != "approved" {
		t.Fatalf("beklenen next_state approved, alinan: %s", resp.NextState)
	}
}

func TestApplyWorkflowTransitionUsecaseApply_ValidationError(t *testing.T) {
	store := &workflowStateMachineStoreMock{}
	usecase := NewApplyWorkflowTransitionUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "draft",
		Action:        "resume",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestApplyWorkflowTransitionUsecaseApply_StoreError(t *testing.T) {
	store := &workflowStateMachineStoreMock{
		err: errors.New("apply workflow transition failed"),
	}
	usecase := NewApplyWorkflowTransitionUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyWorkflowTransitionRequest{
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		CurrentState:  "draft",
		Action:        "submit",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestApplyWorkflowTransitionResponseValidate_InvalidTransitionedAt(t *testing.T) {
	resp := ApplyWorkflowTransitionResponse{
		WorkflowRunID:     "wf-run-001",
		DefinitionKey:     "purchase_approval",
		PreviousState:     "draft",
		Action:            "submit",
		NextState:         "pending",
		TransitionAllowed: true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
