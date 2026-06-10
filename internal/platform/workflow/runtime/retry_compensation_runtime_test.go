package workflowruntime

import "testing"

func failedWorkflowInstanceForCompensation(t *testing.T) WorkflowInstance {
	t.Helper()

	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())

	instance, err := NewWorkflowInstance("tenant_7", "wf_retry_1", "stock_sync")
	if err != nil {
		t.Fatalf("new instance failed: %v", err)
	}

	sequence := []WorkflowTransitionRequest{
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_retry_1",
			FromState:  WorkflowStateDraft,
			ToState:    WorkflowStateReady,
			StepID:     "prepare",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_retry_1",
			FromState:  WorkflowStateReady,
			ToState:    WorkflowStateRunning,
			StepID:     "run",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_retry_1",
			FromState:  WorkflowStateRunning,
			ToState:    WorkflowStateFailed,
			StepID:     "sync_failed",
		},
	}

	for _, req := range sequence {
		instance, _, err = machine.Transition(instance, req)
		if err != nil {
			t.Fatalf("transition failed: %v", err)
		}
	}

	if instance.CurrentState != WorkflowStateFailed {
		t.Fatalf("expected FAILED, got %s", instance.CurrentState)
	}

	return instance
}

func TestWorkflowRetryRuntimeSchedulesRetryWithExponentialBackoff(t *testing.T) {
	runtime := NewWorkflowRetryCompensationRuntime(DefaultWorkflowRetryCompensationRuntimeConfig())

	attempt, decision, err := runtime.DecideFailedStep(WorkflowRetryDecisionRequest{
		TenantID:       "tenant_7",
		WorkflowID:     "wf_retry_1",
		StepID:         "sync_stock",
		CurrentAttempt: 0,
		Policy: WorkflowRetryRuntimePolicy{
			MaxAttempts:     3,
			BackoffStrategy: WorkflowRetryBackoffExponential,
			BackoffSeconds:  30,
		},
		LastErrorCode:    "TEMPORARY_PROVIDER_ERROR",
		LastErrorMessage: "provider timeout",
	})
	if err != nil {
		t.Fatalf("retry decision failed: %v", err)
	}

	if !decision.Allowed {
		t.Fatalf("expected allow decision, got reason=%s", decision.Reason)
	}
	if decision.Action != WorkflowRetryActionRetry {
		t.Fatalf("expected RETRY action, got %s", decision.Action)
	}
	if decision.Reason != WorkflowRetryReasonRetryScheduled {
		t.Fatalf("expected retry scheduled reason, got %s", decision.Reason)
	}
	if attempt.Status != WorkflowRetryAttemptStatusScheduled {
		t.Fatalf("expected SCHEDULED, got %s", attempt.Status)
	}
	if attempt.AttemptNumber != 1 {
		t.Fatalf("expected attempt 1, got %d", attempt.AttemptNumber)
	}
	if attempt.NextRetryAt == "" {
		t.Fatal("expected next retry timestamp")
	}
}

func TestWorkflowRetryRuntimeExhaustionRequiresCompensation(t *testing.T) {
	runtime := NewWorkflowRetryCompensationRuntime(DefaultWorkflowRetryCompensationRuntimeConfig())

	attempt, decision, err := runtime.DecideFailedStep(WorkflowRetryDecisionRequest{
		TenantID:       "tenant_7",
		WorkflowID:     "wf_retry_1",
		StepID:         "sync_stock",
		CurrentAttempt: 3,
		Policy: WorkflowRetryRuntimePolicy{
			MaxAttempts:     3,
			BackoffStrategy: WorkflowRetryBackoffFixed,
			BackoffSeconds:  10,
		},
	})
	if err != nil {
		t.Fatalf("retry exhaustion decision failed: %v", err)
	}

	if !decision.Allowed {
		t.Fatalf("expected allow decision, got reason=%s", decision.Reason)
	}
	if decision.Action != WorkflowRetryActionCompensate {
		t.Fatalf("expected COMPENSATE action, got %s", decision.Action)
	}
	if decision.Reason != WorkflowRetryReasonCompensationRequired {
		t.Fatalf("expected compensation required, got %s", decision.Reason)
	}
	if attempt.Status != WorkflowRetryAttemptStatusExhausted {
		t.Fatalf("expected EXHAUSTED attempt, got %s", attempt.Status)
	}
}

func TestWorkflowRetryRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewWorkflowRetryCompensationRuntime(DefaultWorkflowRetryCompensationRuntimeConfig())

	_, decision, err := runtime.DecideFailedStep(WorkflowRetryDecisionRequest{
		WorkflowID: "wf_retry_1",
		StepID:     "sync_stock",
		Policy: WorkflowRetryRuntimePolicy{
			MaxAttempts:     3,
			BackoffStrategy: WorkflowRetryBackoffFixed,
			BackoffSeconds:  10,
		},
	})

	if err != ErrWorkflowRetryMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != WorkflowRetryReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestCalculateRetryBackoffSeconds(t *testing.T) {
	fixed := CalculateRetryBackoffSeconds(WorkflowRetryRuntimePolicy{
		MaxAttempts:     3,
		BackoffStrategy: WorkflowRetryBackoffFixed,
		BackoffSeconds:  10,
	}, 3)
	if fixed != 10 {
		t.Fatalf("expected fixed 10, got %d", fixed)
	}

	linear := CalculateRetryBackoffSeconds(WorkflowRetryRuntimePolicy{
		MaxAttempts:     3,
		BackoffStrategy: WorkflowRetryBackoffLinear,
		BackoffSeconds:  10,
	}, 3)
	if linear != 30 {
		t.Fatalf("expected linear 30, got %d", linear)
	}

	exponential := CalculateRetryBackoffSeconds(WorkflowRetryRuntimePolicy{
		MaxAttempts:     3,
		BackoffStrategy: WorkflowRetryBackoffExponential,
		BackoffSeconds:  10,
	}, 3)
	if exponential != 40 {
		t.Fatalf("expected exponential 40, got %d", exponential)
	}
}

func TestWorkflowCompensationRuntimeLifecycle(t *testing.T) {
	runtime := NewWorkflowRetryCompensationRuntime(DefaultWorkflowRetryCompensationRuntimeConfig())

	record, decision, err := runtime.RequestCompensation(WorkflowCompensationRequest{
		TenantID:           "tenant_7",
		WorkflowID:         "wf_retry_1",
		FailedStepID:       "sync_stock",
		CompensationStepID: "rollback_stock",
		Reason:             "retry exhausted",
	})
	if err != nil {
		t.Fatalf("request compensation failed: %v", err)
	}

	if !decision.Allowed {
		t.Fatalf("expected allow compensation, got reason=%s", decision.Reason)
	}
	if record.CompensationID == "" {
		t.Fatal("expected compensation id")
	}
	if record.Status != WorkflowCompensationStatusRequested {
		t.Fatalf("expected REQUESTED, got %s", record.Status)
	}

	record, _, err = runtime.StartCompensation("tenant_7", record.CompensationID)
	if err != nil {
		t.Fatalf("start compensation failed: %v", err)
	}
	if record.Status != WorkflowCompensationStatusRunning {
		t.Fatalf("expected RUNNING, got %s", record.Status)
	}

	record, _, err = runtime.CompleteCompensation("tenant_7", record.CompensationID)
	if err != nil {
		t.Fatalf("complete compensation failed: %v", err)
	}
	if record.Status != WorkflowCompensationStatusCompleted {
		t.Fatalf("expected COMPLETED, got %s", record.Status)
	}
	if record.CompletedAt == "" {
		t.Fatal("expected completed timestamp")
	}
}

func TestWorkflowCompensationRuntimeRejectsCrossTenantAccess(t *testing.T) {
	runtime := NewWorkflowRetryCompensationRuntime(DefaultWorkflowRetryCompensationRuntimeConfig())

	record, _, err := runtime.RequestCompensation(WorkflowCompensationRequest{
		TenantID:           "tenant_7",
		WorkflowID:         "wf_retry_1",
		FailedStepID:       "sync_stock",
		CompensationStepID: "rollback_stock",
	})
	if err != nil {
		t.Fatalf("request compensation failed: %v", err)
	}

	_, decision, err := runtime.StartCompensation("tenant_8", record.CompensationID)
	if err != ErrWorkflowCompensationCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != WorkflowCompensationReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestWorkflowCompensationRuntimeBridgeToStateMachine(t *testing.T) {
	runtime := NewWorkflowRetryCompensationRuntime(DefaultWorkflowRetryCompensationRuntimeConfig())
	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())

	instance := failedWorkflowInstanceForCompensation(t)

	record, _, err := runtime.RequestCompensation(WorkflowCompensationRequest{
		TenantID:           "tenant_7",
		WorkflowID:         instance.WorkflowID,
		FailedStepID:       "sync_failed",
		CompensationStepID: "rollback_stock",
		Reason:             "retry exhausted",
	})
	if err != nil {
		t.Fatalf("request compensation failed: %v", err)
	}

	record, _, err = runtime.StartCompensation("tenant_7", record.CompensationID)
	if err != nil {
		t.Fatalf("start compensation failed: %v", err)
	}

	instance, transition, err := runtime.ApplyCompensationStartToWorkflow(machine, instance, record, "workflow-worker")
	if err != nil {
		t.Fatalf("apply compensation start failed: %v", err)
	}
	if !transition.Allowed {
		t.Fatalf("expected transition allowed, got reason=%s", transition.Reason)
	}
	if instance.CurrentState != WorkflowStateCompensating {
		t.Fatalf("expected COMPENSATING, got %s", instance.CurrentState)
	}

	record, _, err = runtime.CompleteCompensation("tenant_7", record.CompensationID)
	if err != nil {
		t.Fatalf("complete compensation failed: %v", err)
	}

	instance, transition, err = runtime.ApplyCompensationCompleteToWorkflow(machine, instance, record, "workflow-worker")
	if err != nil {
		t.Fatalf("apply compensation complete failed: %v", err)
	}
	if !transition.Allowed {
		t.Fatalf("expected transition allowed, got reason=%s", transition.Reason)
	}
	if instance.CurrentState != WorkflowStateCompensated {
		t.Fatalf("expected COMPENSATED, got %s", instance.CurrentState)
	}
}
