package workflow

import (
	"context"
	"errors"
	"testing"
	"time"
)

type workflowRecoveryStoreMock struct {
	lastCmd ApplyWorkflowRecoveryCommand
	result  ApplyWorkflowRecoveryResult
	err     error
	called  bool
}

func (m *workflowRecoveryStoreMock) ApplyRecovery(_ context.Context, cmd ApplyWorkflowRecoveryCommand) (ApplyWorkflowRecoveryResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestApplyWorkflowRecoveryRequestValidate_Success(t *testing.T) {
	req := ApplyWorkflowRecoveryRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
		Reason:        "gecici hata temizlendi",
		ResetAttempts: true,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestApplyWorkflowRecoveryRequestValidate_InvalidActionType(t *testing.T) {
	req := ApplyWorkflowRecoveryRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		ActionType:    "resume",
		RequestedBy:   "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyWorkflowRecoveryRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := ApplyWorkflowRecoveryRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		ActionType:    "retry",
		RequestedBy:   "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyWorkflowRecoveryRequestValidate_CompensateRequiresCompensationRef(t *testing.T) {
	req := ApplyWorkflowRecoveryRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		ActionType:    "compensate",
		RequestedBy:   "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyWorkflowRecoveryUsecaseApply_RetrySuccess(t *testing.T) {
	store := &workflowRecoveryStoreMock{
		result: ApplyWorkflowRecoveryResult{
			WorkflowRunID: "wf-run-001",
			StepKey:       "service-step-1",
			ActionType:    "retry",
			StepStatus:    "pending",
			WorkflowState: "pending",
			AttemptNo:     0,
			LeaseReleased: true,
		},
	}

	usecase := NewApplyWorkflowRecoveryUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 1, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Apply(context.Background(), ApplyWorkflowRecoveryRequest{
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

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ActionType != "retry" {
		t.Fatalf("beklenen action_type retry, alinan: %s", store.lastCmd.ActionType)
	}

	if resp.StepStatus != "pending" {
		t.Fatalf("beklenen step_status pending, alinan: %s", resp.StepStatus)
	}

	if resp.WorkflowState != "pending" {
		t.Fatalf("beklenen workflow_state pending, alinan: %s", resp.WorkflowState)
	}

	if !resp.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !resp.RequestedAt.Equal(time.Date(2026, 4, 26, 1, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen requested_at sabit zaman")
	}
}

func TestApplyWorkflowRecoveryUsecaseApply_CompensateFallbackSuccess(t *testing.T) {
	store := &workflowRecoveryStoreMock{
		result: ApplyWorkflowRecoveryResult{},
	}

	usecase := NewApplyWorkflowRecoveryUsecase(store)

	resp, err := usecase.Apply(context.Background(), ApplyWorkflowRecoveryRequest{
		WorkflowRunID:   "wf-run-002",
		StepKey:         "service-step-2",
		ActionType:      "compensate",
		RequestedBy:     "worker-02",
		Reason:          "rollback gerekli",
		CompensationRef: "comp-001",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.StepStatus != "compensating" {
		t.Fatalf("beklenen step_status compensating, alinan: %s", resp.StepStatus)
	}

	if resp.WorkflowState != "failed" {
		t.Fatalf("beklenen workflow_state failed, alinan: %s", resp.WorkflowState)
	}

	if resp.CompensationRef != "comp-001" {
		t.Fatalf("beklenen compensation_ref comp-001, alinan: %s", resp.CompensationRef)
	}
}

func TestApplyWorkflowRecoveryUsecaseApply_ValidationError(t *testing.T) {
	store := &workflowRecoveryStoreMock{}
	usecase := NewApplyWorkflowRecoveryUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyWorkflowRecoveryRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		ActionType:    "resume",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestApplyWorkflowRecoveryUsecaseApply_StoreError(t *testing.T) {
	store := &workflowRecoveryStoreMock{
		err: errors.New("apply workflow recovery failed"),
	}
	usecase := NewApplyWorkflowRecoveryUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyWorkflowRecoveryRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		ActionType:    "retry",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestApplyWorkflowRecoveryResponseValidate_InvalidRequestedAt(t *testing.T) {
	resp := ApplyWorkflowRecoveryResponse{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		ActionType:    "retry",
		StepStatus:    "pending",
		WorkflowState: "pending",
		LeaseReleased: true,
		RequestedBy:   "worker-01",
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
