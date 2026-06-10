package workflow

import (
	"context"
	"errors"
	"testing"
	"time"
)

type workflowObservabilityStoreMock struct {
	lastCmd LoadWorkflowObservabilityCommand
	result  LoadWorkflowObservabilityResult
	err     error
	called  bool
}

func (m *workflowObservabilityStoreMock) LoadObservability(_ context.Context, cmd LoadWorkflowObservabilityCommand) (LoadWorkflowObservabilityResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestLoadWorkflowObservabilityRequestValidate_Success(t *testing.T) {
	req := LoadWorkflowObservabilityRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		RequestedBy:   "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestLoadWorkflowObservabilityRequestValidate_InvalidWorkflowRunID(t *testing.T) {
	req := LoadWorkflowObservabilityRequest{
		WorkflowRunID: "wf run 001",
		RequestedBy:   "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestLoadWorkflowObservabilityRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := LoadWorkflowObservabilityRequest{
		WorkflowRunID: "wf-run-001",
		RequestedBy:   "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestWorkflowObservabilitySummaryValidate_InvalidTotalSteps(t *testing.T) {
	summary := WorkflowObservabilitySummary{
		TotalSteps: -1,
	}

	if err := summary.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestLoadWorkflowObservabilityUsecaseLoad_Success(t *testing.T) {
	leaseExpiresAt := time.Date(2026, 4, 26, 2, 5, 0, 0, time.UTC)

	store := &workflowObservabilityStoreMock{
		result: LoadWorkflowObservabilityResult{
			WorkflowRunID: "wf-run-001",
			DefinitionKey: "purchase_approval",
			WorkflowState: "in_progress",
			Summary: WorkflowObservabilitySummary{
				TotalSteps:        3,
				PendingSteps:      1,
				InProgressSteps:   1,
				CompletedSteps:    1,
				FailedSteps:       0,
				PendingApprovals:  1,
				ActiveLeaseCount:  1,
				ExpiredLeaseCount: 0,
			},
			Steps: []WorkflowStepObservation{
				{
					StepKey:        "submit-step",
					StepType:       "task",
					Status:         "completed",
					AttemptNo:      1,
					WorkerID:       "worker-01",
					LeaseExpiresAt: nil,
					LastErrorCode:  "",
				},
				{
					StepKey:        "approval-step-1",
					StepType:       "approval",
					Status:         "in_progress",
					AttemptNo:      1,
					WorkerID:       "worker-02",
					LeaseExpiresAt: &leaseExpiresAt,
					LastErrorCode:  "",
				},
			},
		},
	}

	usecase := NewLoadWorkflowObservabilityUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 2, 0, 0, 0, time.UTC)
	}

	resp, err := usecase.Load(context.Background(), LoadWorkflowObservabilityRequest{
		TenantID:      "tenant-a",
		WorkflowRunID: "wf-run-001",
		RequestedBy:   "worker-01",
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

	if resp.HealthStatus != "degraded" {
		t.Fatalf("beklenen health_status degraded, alinan: %s", resp.HealthStatus)
	}

	if len(resp.Steps) != 2 {
		t.Fatalf("beklenen 2 step, alinan: %d", len(resp.Steps))
	}

	if !resp.ObservedAt.Equal(time.Date(2026, 4, 26, 2, 0, 0, 0, time.UTC)) {
		t.Fatalf("beklenen observed_at sabit zaman")
	}
}

func TestLoadWorkflowObservabilityUsecaseLoad_FailedHealth(t *testing.T) {
	store := &workflowObservabilityStoreMock{
		result: LoadWorkflowObservabilityResult{
			WorkflowRunID: "wf-run-002",
			DefinitionKey: "purchase_approval",
			WorkflowState: "failed",
			Summary: WorkflowObservabilitySummary{
				TotalSteps:        2,
				PendingSteps:      0,
				InProgressSteps:   0,
				CompletedSteps:    1,
				FailedSteps:       1,
				PendingApprovals:  0,
				ActiveLeaseCount:  0,
				ExpiredLeaseCount: 0,
			},
		},
	}

	usecase := NewLoadWorkflowObservabilityUsecase(store)

	resp, err := usecase.Load(context.Background(), LoadWorkflowObservabilityRequest{
		WorkflowRunID: "wf-run-002",
		RequestedBy:   "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.HealthStatus != "failed" {
		t.Fatalf("beklenen health_status failed, alinan: %s", resp.HealthStatus)
	}
}

func TestLoadWorkflowObservabilityUsecaseLoad_ValidationError(t *testing.T) {
	store := &workflowObservabilityStoreMock{}
	usecase := NewLoadWorkflowObservabilityUsecase(store)

	_, err := usecase.Load(context.Background(), LoadWorkflowObservabilityRequest{
		WorkflowRunID: "wf run 001",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestLoadWorkflowObservabilityUsecaseLoad_StoreError(t *testing.T) {
	store := &workflowObservabilityStoreMock{
		err: errors.New("load workflow observability failed"),
	}
	usecase := NewLoadWorkflowObservabilityUsecase(store)

	_, err := usecase.Load(context.Background(), LoadWorkflowObservabilityRequest{
		WorkflowRunID: "wf-run-001",
		RequestedBy:   "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestLoadWorkflowObservabilityResponseValidate_InvalidObservedAt(t *testing.T) {
	resp := LoadWorkflowObservabilityResponse{
		WorkflowRunID: "wf-run-001",
		DefinitionKey: "purchase_approval",
		WorkflowState: "draft",
		HealthStatus:  "healthy",
		Summary: WorkflowObservabilitySummary{
			TotalSteps:        1,
			PendingSteps:      1,
			InProgressSteps:   0,
			CompletedSteps:    0,
			FailedSteps:       0,
			PendingApprovals:  0,
			ActiveLeaseCount:  0,
			ExpiredLeaseCount: 0,
		},
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
