package workflow

import (
	"context"
	"errors"
	"testing"
	"time"
)

type workflowDefinitionLoaderStoreMock struct {
	lastCmd LoadWorkflowDefinitionCommand
	result  LoadWorkflowDefinitionResult
	err     error
	called  bool
}

func (m *workflowDefinitionLoaderStoreMock) LoadDefinition(_ context.Context, cmd LoadWorkflowDefinitionCommand) (LoadWorkflowDefinitionResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestLoadWorkflowDefinitionRequestValidate_Success(t *testing.T) {
	req := LoadWorkflowDefinitionRequest{
		TenantID:      "tenant-a",
		DefinitionKey: "purchase_approval",
		RequestedBy:   "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestLoadWorkflowDefinitionRequestValidate_InvalidDefinitionKey(t *testing.T) {
	req := LoadWorkflowDefinitionRequest{
		DefinitionKey: "purchase approval",
		RequestedBy:   "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestLoadWorkflowDefinitionRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := LoadWorkflowDefinitionRequest{
		DefinitionKey: "purchase_approval",
		RequestedBy:   "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestWorkflowDefinitionStepValidate_InvalidStepType(t *testing.T) {
	step := WorkflowDefinitionStep{
		StepKey:  "approval-step-1",
		StepType: "human",
	}

	if err := step.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestLoadWorkflowDefinitionUsecaseLoad_Success(t *testing.T) {
	store := &workflowDefinitionLoaderStoreMock{
		result: LoadWorkflowDefinitionResult{
			DefinitionKey: "purchase_approval",
			Version:       3,
			InitialState:  "draft",
			Loaded:        true,
			Steps: []WorkflowDefinitionStep{
				{
					StepKey:                "submit-step",
					StepType:               "task",
					NextOnSuccess:          "approval-step-1",
					RequiresManualApproval: false,
				},
				{
					StepKey:                "approval-step-1",
					StepType:               "approval",
					NextOnSuccess:          "complete-step",
					NextOnFailure:          "reject-step",
					RequiresManualApproval: true,
				},
			},
		},
	}

	usecase := NewLoadWorkflowDefinitionUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 1, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Load(context.Background(), LoadWorkflowDefinitionRequest{
		TenantID:      "tenant-a",
		DefinitionKey: "purchase_approval",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.DefinitionKey != "purchase_approval" {
		t.Fatalf("beklenen definition_key purchase_approval, alinan: %s", store.lastCmd.DefinitionKey)
	}

	if !resp.Loaded {
		t.Fatalf("beklenen loaded true")
	}

	if resp.Version != 3 {
		t.Fatalf("beklenen version 3, alinan: %d", resp.Version)
	}

	if len(resp.Steps) != 2 {
		t.Fatalf("beklenen 2 step, alinan: %d", len(resp.Steps))
	}

	if !resp.LoadedAt.Equal(time.Date(2026, 4, 26, 1, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen loaded_at sabit zaman")
	}
}

func TestLoadWorkflowDefinitionUsecaseLoad_NotFoundSuccess(t *testing.T) {
	store := &workflowDefinitionLoaderStoreMock{
		result: LoadWorkflowDefinitionResult{
			DefinitionKey: "purchase_approval",
			Loaded:        false,
		},
	}

	usecase := NewLoadWorkflowDefinitionUsecase(store)

	resp, err := usecase.Load(context.Background(), LoadWorkflowDefinitionRequest{
		DefinitionKey: "purchase_approval",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Loaded {
		t.Fatalf("beklenen loaded false")
	}
}

func TestLoadWorkflowDefinitionUsecaseLoad_ValidationError(t *testing.T) {
	store := &workflowDefinitionLoaderStoreMock{}
	usecase := NewLoadWorkflowDefinitionUsecase(store)

	_, err := usecase.Load(context.Background(), LoadWorkflowDefinitionRequest{
		DefinitionKey: "purchase approval",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestLoadWorkflowDefinitionUsecaseLoad_StoreError(t *testing.T) {
	store := &workflowDefinitionLoaderStoreMock{
		err: errors.New("load workflow definition failed"),
	}
	usecase := NewLoadWorkflowDefinitionUsecase(store)

	_, err := usecase.Load(context.Background(), LoadWorkflowDefinitionRequest{
		DefinitionKey: "purchase_approval",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestLoadWorkflowDefinitionResponseValidate_InvalidLoadedAt(t *testing.T) {
	resp := LoadWorkflowDefinitionResponse{
		DefinitionKey: "purchase_approval",
		Loaded:        false,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
