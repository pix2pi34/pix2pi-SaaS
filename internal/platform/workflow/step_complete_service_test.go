package workflow

import (
	"context"
	"errors"
	"testing"
	"time"
)

type workflowStepCompletionStoreMock struct {
	lastCmd CompleteWorkflowStepCommand
	result  CompleteWorkflowStepResult
	err     error
	called  bool
}

func (m *workflowStepCompletionStoreMock) CompleteStep(_ context.Context, cmd CompleteWorkflowStepCommand) (CompleteWorkflowStepResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestCompleteWorkflowStepRequestValidate_Success(t *testing.T) {
	req := CompleteWorkflowStepRequest{
		TenantID:       "tenant-a",
		WorkflowRunID:  "wf-run-001",
		StepKey:        "service-step-1",
		WorkerID:       "worker-01",
		Status:         "completed",
		AttemptNo:      1,
		OutputRef:      "output-001",
		CompletionNote: "basariyla tamamlandi",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestCompleteWorkflowStepRequestValidate_InvalidStatus(t *testing.T) {
	req := CompleteWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		WorkerID:      "worker-01",
		Status:        "sending",
		AttemptNo:     1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCompleteWorkflowStepRequestValidate_InvalidWorkerID(t *testing.T) {
	req := CompleteWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		WorkerID:      "worker 01",
		Status:        "completed",
		AttemptNo:     1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCompleteWorkflowStepRequestValidate_FailedRequiresErrorCode(t *testing.T) {
	req := CompleteWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		WorkerID:      "worker-01",
		Status:        "failed",
		AttemptNo:     1,
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestCompleteWorkflowStepUsecaseComplete_Success(t *testing.T) {
	store := &workflowStepCompletionStoreMock{
		result: CompleteWorkflowStepResult{
			WorkflowRunID:  "wf-run-001",
			StepKey:        "service-step-1",
			Status:         "completed",
			AttemptNo:      1,
			OutputRef:      "output-001",
			CompletionNote: "basariyla tamamlandi",
			LeaseReleased:  true,
		},
	}

	usecase := NewCompleteWorkflowStepUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 0, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Complete(context.Background(), CompleteWorkflowStepRequest{
		TenantID:       "tenant-a",
		WorkflowRunID:  "wf-run-001",
		StepKey:        "service-step-1",
		WorkerID:       "worker-01",
		Status:         "completed",
		AttemptNo:      1,
		OutputRef:      "output-001",
		CompletionNote: "basariyla tamamlandi",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.StepKey != "service-step-1" {
		t.Fatalf("beklenen step_key service-step-1, alinan: %s", store.lastCmd.StepKey)
	}

	if resp.Status != "completed" {
		t.Fatalf("beklenen status completed, alinan: %s", resp.Status)
	}

	if resp.OutputRef != "output-001" {
		t.Fatalf("beklenen output_ref output-001, alinan: %s", resp.OutputRef)
	}

	if !resp.LeaseReleased {
		t.Fatalf("beklenen lease_released true")
	}

	if !resp.CompletedAt.Equal(time.Date(2026, 4, 26, 0, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen completed_at sabit zaman")
	}
}

func TestCompleteWorkflowStepUsecaseComplete_FailedSuccess(t *testing.T) {
	store := &workflowStepCompletionStoreMock{
		result: CompleteWorkflowStepResult{
			WorkflowRunID:  "wf-run-002",
			StepKey:        "service-step-2",
			Status:         "failed",
			AttemptNo:      2,
			ErrorCode:      "TIMEOUT",
			CompletionNote: "servis timeout verdi",
			LeaseReleased:  true,
		},
	}

	usecase := NewCompleteWorkflowStepUsecase(store)

	resp, err := usecase.Complete(context.Background(), CompleteWorkflowStepRequest{
		WorkflowRunID:  "wf-run-002",
		StepKey:        "service-step-2",
		WorkerID:       "worker-02",
		Status:         "failed",
		AttemptNo:      2,
		ErrorCode:      "TIMEOUT",
		CompletionNote: "servis timeout verdi",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.ErrorCode != "TIMEOUT" {
		t.Fatalf("beklenen error_code TIMEOUT, alinan: %s", resp.ErrorCode)
	}
}

func TestCompleteWorkflowStepUsecaseComplete_ValidationError(t *testing.T) {
	store := &workflowStepCompletionStoreMock{}
	usecase := NewCompleteWorkflowStepUsecase(store)

	_, err := usecase.Complete(context.Background(), CompleteWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		WorkerID:      "worker-01",
		Status:        "failed",
		AttemptNo:     1,
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestCompleteWorkflowStepUsecaseComplete_StoreError(t *testing.T) {
	store := &workflowStepCompletionStoreMock{
		err: errors.New("complete workflow step failed"),
	}
	usecase := NewCompleteWorkflowStepUsecase(store)

	_, err := usecase.Complete(context.Background(), CompleteWorkflowStepRequest{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		WorkerID:      "worker-01",
		Status:        "completed",
		AttemptNo:     1,
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestCompleteWorkflowStepResponseValidate_InvalidCompletedAt(t *testing.T) {
	resp := CompleteWorkflowStepResponse{
		WorkflowRunID: "wf-run-001",
		StepKey:       "service-step-1",
		WorkerID:      "worker-01",
		Status:        "completed",
		AttemptNo:     1,
		LeaseReleased: true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
