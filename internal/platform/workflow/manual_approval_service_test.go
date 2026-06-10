package workflow

import (
	"context"
	"errors"
	"testing"
	"time"
)

type manualApprovalStoreMock struct {
	lastCmd ApplyManualApprovalCommand
	result  ApplyManualApprovalResult
	err     error
	called  bool
}

func (m *manualApprovalStoreMock) ApplyApprovalDecision(_ context.Context, cmd ApplyManualApprovalCommand) (ApplyManualApprovalResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestApplyManualApprovalRequestValidate_Success(t *testing.T) {
	req := ApplyManualApprovalRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		ApprovalID:    "approval-001",
		ApproverRef:   "user-approver-1",
		Decision:      "approve",
		Comment:       "uygun bulundu",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestApplyManualApprovalRequestValidate_InvalidApprovalID(t *testing.T) {
	req := ApplyManualApprovalRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		ApprovalID:    "approval 001",
		ApproverRef:   "user-approver-1",
		Decision:      "approve",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyManualApprovalRequestValidate_InvalidApproverRef(t *testing.T) {
	req := ApplyManualApprovalRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		ApprovalID:    "approval-001",
		ApproverRef:   "user approver 1",
		Decision:      "approve",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyManualApprovalRequestValidate_InvalidDecision(t *testing.T) {
	req := ApplyManualApprovalRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		ApprovalID:    "approval-001",
		ApproverRef:   "user-approver-1",
		Decision:      "hold",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestApplyManualApprovalUsecaseApply_ApproveSuccess(t *testing.T) {
	store := &manualApprovalStoreMock{
		result: ApplyManualApprovalResult{
			WorkflowRunID:     "wf-run-001",
			StepKey:           "approval-step-1",
			ApprovalID:        "approval-001",
			ApproverRef:       "user-approver-1",
			Decision:          "approve",
			ApprovalStatus:    "approved",
			WorkflowNextState: "approved",
			Comment:           "uygun bulundu",
			Completed:         true,
		},
	}

	usecase := NewApplyManualApprovalUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Apply(context.Background(), ApplyManualApprovalRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		ApprovalID:    "approval-001",
		ApproverRef:   "user-approver-1",
		Decision:      "approve",
		Comment:       "uygun bulundu",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.ApprovalID != "approval-001" {
		t.Fatalf("beklenen approval_id approval-001, alinan: %s", store.lastCmd.ApprovalID)
	}

	if resp.ApprovalStatus != "approved" {
		t.Fatalf("beklenen approval_status approved, alinan: %s", resp.ApprovalStatus)
	}

	if resp.WorkflowNextState != "approved" {
		t.Fatalf("beklenen workflow_next_state approved, alinan: %s", resp.WorkflowNextState)
	}

	if !resp.DecidedAt.Equal(time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen decided_at sabit zaman")
	}
}

func TestApplyManualApprovalUsecaseApply_RejectFallbackSuccess(t *testing.T) {
	store := &manualApprovalStoreMock{
		result: ApplyManualApprovalResult{},
	}

	usecase := NewApplyManualApprovalUsecase(store)

	resp, err := usecase.Apply(context.Background(), ApplyManualApprovalRequest{
		WorkflowRunID: "wf-run-002",
		StepKey:       "approval-step-2",
		ApprovalID:    "approval-002",
		ApproverRef:   "user-approver-2",
		Decision:      "reject",
		Comment:       "eksik bilgi",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.ApprovalStatus != "rejected" {
		t.Fatalf("beklenen approval_status rejected, alinan: %s", resp.ApprovalStatus)
	}

	if resp.WorkflowNextState != "rejected" {
		t.Fatalf("beklenen workflow_next_state rejected, alinan: %s", resp.WorkflowNextState)
	}
}

func TestApplyManualApprovalUsecaseApply_ValidationError(t *testing.T) {
	store := &manualApprovalStoreMock{}
	usecase := NewApplyManualApprovalUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyManualApprovalRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		ApprovalID:    "approval-001",
		ApproverRef:   "user-approver-1",
		Decision:      "hold",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestApplyManualApprovalUsecaseApply_StoreError(t *testing.T) {
	store := &manualApprovalStoreMock{
		err: errors.New("apply manual approval failed"),
	}
	usecase := NewApplyManualApprovalUsecase(store)

	_, err := usecase.Apply(context.Background(), ApplyManualApprovalRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "approval-step-1",
		ApprovalID:    "approval-001",
		ApproverRef:   "user-approver-1",
		Decision:      "approve",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestApplyManualApprovalResponseValidate_InvalidDecidedAt(t *testing.T) {
	resp := ApplyManualApprovalResponse{
		WorkflowRunID:     "wf-run-001",
		StepKey:           "approval-step-1",
		ApprovalID:        "approval-001",
		ApproverRef:       "user-approver-1",
		Decision:          "approve",
		ApprovalStatus:    "approved",
		WorkflowNextState: "approved",
		Completed:         true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
