package workflow

import (
	"context"
	"errors"
	"testing"
	"time"
)

type workflowStepClaimStoreMock struct {
	lastCmd ClaimWorkflowStepCommand
	result  ClaimWorkflowStepResult
	err     error
	called  bool
}

func (m *workflowStepClaimStoreMock) ClaimStep(_ context.Context, cmd ClaimWorkflowStepCommand) (ClaimWorkflowStepResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestClaimWorkflowStepRequestValidate_Success(t *testing.T) {
	req := ClaimWorkflowStepRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		WorkerID:      "worker-01",
		LeaseSeconds:  60,
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestClaimWorkflowStepRequestValidate_InvalidStepKey(t *testing.T) {
	req := ClaimWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval step 1",
		WorkerID:      "worker-01",
		LeaseSeconds:  60,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestClaimWorkflowStepRequestValidate_InvalidWorkerID(t *testing.T) {
	req := ClaimWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		WorkerID:      "worker 01",
		LeaseSeconds:  60,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestClaimWorkflowStepRequestValidate_InvalidLeaseSeconds(t *testing.T) {
	req := ClaimWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		WorkerID:      "worker-01",
		LeaseSeconds:  1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestClaimWorkflowStepUsecaseClaim_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 25, 23, 31, 0, 0, time.UTC)

	store := &workflowStepClaimStoreMock{
		result: ClaimWorkflowStepResult{
			Claimed:        true,
			WorkflowRunID:  "wf-run-001",
			StepKey:        "approval-step-1",
			StepType:       "approval",
			Status:         "in_progress",
			AttemptNo:      1,
			LeaseExpiresAt: &leaseExpiresAt,
		},
	}

	usecase := NewClaimWorkflowStepUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 23, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		WorkerID:      "worker-01",
		LeaseSeconds:  60,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.StepKey != "approval-step-1" {
		t.Fatalf("beklenen step_key approval-step-1, alinan: %s", store.lastCmd.StepKey)
	}

	if !resp.Claimed {
		t.Fatalf("beklenen claimed true")
	}

	if resp.StepType != "approval" {
		t.Fatalf("beklenen step_type approval, alinan: %s", resp.StepType)
	}

	if resp.LeaseExpiresAt == nil || !resp.LeaseExpiresAt.Equal(leaseExpiresAt) {
		t.Fatalf("beklenen lease_expires_at korunmaliydi")
	}

	if !resp.ClaimedAt.Equal(time.Date(2026, 4, 25, 23, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen claimed_at sabit zaman")
	}
}

func TestClaimWorkflowStepUsecaseClaim_NoStepFound(t *testing.T) {
	store := &workflowStepClaimStoreMock{
		result: ClaimWorkflowStepResult{
			Claimed: false,
		},
	}

	usecase := NewClaimWorkflowStepUsecase(store)

	resp, err := usecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		WorkerID:      "worker-01",
		LeaseSeconds:  60,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Claimed {
		t.Fatalf("beklenen claimed false")
	}

	if resp.StepKey != "" {
		t.Fatalf("beklenen bos step_key")
	}
}

func TestClaimWorkflowStepUsecaseClaim_ValidationError(t *testing.T) {
	store := &workflowStepClaimStoreMock{}
	usecase := NewClaimWorkflowStepUsecase(store)

	_, err := usecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval step 1",
		WorkerID:      "worker-01",
		LeaseSeconds:  60,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestClaimWorkflowStepUsecaseClaim_StoreError(t *testing.T) {
	store := &workflowStepClaimStoreMock{
		err: errors.New("claim workflow step failed"),
	}
	usecase := NewClaimWorkflowStepUsecase(store)

	_, err := usecase.Claim(context.Background(), ClaimWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		WorkerID:      "worker-01",
		LeaseSeconds:  60,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestClaimWorkflowStepResponseValidate_InvalidClaimedAt(t *testing.T) {
	resp := ClaimWorkflowStepResponse{
		Claimed: false,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
