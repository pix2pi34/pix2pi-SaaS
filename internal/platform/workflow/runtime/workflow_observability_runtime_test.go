package workflowruntime

import "testing"

func TestWorkflowObservabilityRuntimeRecordsStateTransitions(t *testing.T) {
	runtime := NewWorkflowObservabilityRuntime(DefaultWorkflowObservabilityRuntimeConfig())

	snapshot, decision, err := runtime.RecordTransition(WorkflowTransitionEvent{
		TenantID:   "tenant_7",
		WorkflowID: "wf_obs_1",
		FromState:  WorkflowStateDraft,
		ToState:    WorkflowStateReady,
		StepID:     "prepare",
	})
	if err != nil {
		t.Fatalf("record transition failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected allowed decision, got reason=%s", decision.Reason)
	}

	key := WorkflowStateDraft + "->" + WorkflowStateReady
	if snapshot.StateTransitionCounters[key] != 1 {
		t.Fatalf("expected transition counter 1, got %d", snapshot.StateTransitionCounters[key])
	}
	if snapshot.TotalTransitions != 1 {
		t.Fatalf("expected total transitions 1, got %d", snapshot.TotalTransitions)
	}
}

func TestWorkflowObservabilityRuntimeRecordsFailedWorkflowCounter(t *testing.T) {
	runtime := NewWorkflowObservabilityRuntime(DefaultWorkflowObservabilityRuntimeConfig())

	snapshot, _, err := runtime.RecordTransition(WorkflowTransitionEvent{
		TenantID:   "tenant_7",
		WorkflowID: "wf_obs_1",
		FromState:  WorkflowStateRunning,
		ToState:    WorkflowStateFailed,
		StepID:     "sync_failed",
	})
	if err != nil {
		t.Fatalf("record failed transition failed: %v", err)
	}

	if snapshot.FailedWorkflowCounters[WorkflowStateFailed] != 1 {
		t.Fatalf("expected failed workflow counter 1, got %d", snapshot.FailedWorkflowCounters[WorkflowStateFailed])
	}
}

func TestWorkflowObservabilityRuntimeRecordsApprovalCounters(t *testing.T) {
	runtime := NewWorkflowObservabilityRuntime(DefaultWorkflowObservabilityRuntimeConfig())

	snapshot, decision, err := runtime.RecordApproval(ManualApprovalRequest{
		TenantID:   "tenant_7",
		ApprovalID: "appr_1",
		WorkflowID: "wf_obs_2",
		StepID:     "manager_approval",
		Status:     ApprovalRequestStatusApproved,
	})
	if err != nil {
		t.Fatalf("record approval failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected allowed decision, got reason=%s", decision.Reason)
	}
	if snapshot.ApprovalCounters[ApprovalRequestStatusApproved] != 1 {
		t.Fatalf("expected approved counter 1, got %d", snapshot.ApprovalCounters[ApprovalRequestStatusApproved])
	}
	if snapshot.TotalApprovals != 1 {
		t.Fatalf("expected total approvals 1, got %d", snapshot.TotalApprovals)
	}
}

func TestWorkflowObservabilityRuntimeRecordsRetryCounters(t *testing.T) {
	runtime := NewWorkflowObservabilityRuntime(DefaultWorkflowObservabilityRuntimeConfig())

	snapshot, decision, err := runtime.RecordRetryDecision(WorkflowRetryDecision{
		TenantID:   "tenant_7",
		WorkflowID: "wf_obs_3",
		StepID:     "sync_stock",
		Action:     WorkflowRetryActionRetry,
		Reason:     WorkflowRetryReasonRetryScheduled,
	})
	if err != nil {
		t.Fatalf("record retry decision failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected allowed decision, got reason=%s", decision.Reason)
	}
	if snapshot.RetryCounters[WorkflowRetryActionRetry] != 1 {
		t.Fatalf("expected retry counter 1, got %d", snapshot.RetryCounters[WorkflowRetryActionRetry])
	}
	if snapshot.TotalRetryDecisions != 1 {
		t.Fatalf("expected total retry decisions 1, got %d", snapshot.TotalRetryDecisions)
	}
}

func TestWorkflowObservabilityRuntimeRecordsCompensationCounters(t *testing.T) {
	runtime := NewWorkflowObservabilityRuntime(DefaultWorkflowObservabilityRuntimeConfig())

	snapshot, decision, err := runtime.RecordCompensation(WorkflowCompensationRecord{
		TenantID:       "tenant_7",
		WorkflowID:     "wf_obs_4",
		CompensationID: "comp_1",
		Status:         WorkflowCompensationStatusCompleted,
	})
	if err != nil {
		t.Fatalf("record compensation failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected allowed decision, got reason=%s", decision.Reason)
	}
	if snapshot.CompensationCounters[WorkflowCompensationStatusCompleted] != 1 {
		t.Fatalf("expected completed compensation counter 1, got %d", snapshot.CompensationCounters[WorkflowCompensationStatusCompleted])
	}
	if snapshot.TotalCompensations != 1 {
		t.Fatalf("expected total compensations 1, got %d", snapshot.TotalCompensations)
	}
}

func TestWorkflowObservabilityRuntimeTenantSafeSnapshots(t *testing.T) {
	runtime := NewWorkflowObservabilityRuntime(DefaultWorkflowObservabilityRuntimeConfig())

	_, _, err := runtime.RecordTransition(WorkflowTransitionEvent{
		TenantID:   "tenant_a",
		WorkflowID: "wf_a",
		FromState:  WorkflowStateDraft,
		ToState:    WorkflowStateReady,
	})
	if err != nil {
		t.Fatalf("record tenant_a failed: %v", err)
	}

	_, _, err = runtime.RecordTransition(WorkflowTransitionEvent{
		TenantID:   "tenant_b",
		WorkflowID: "wf_b",
		FromState:  WorkflowStateDraft,
		ToState:    WorkflowStateReady,
	})
	if err != nil {
		t.Fatalf("record tenant_b failed: %v", err)
	}

	snapshotA, err := runtime.Snapshot("tenant_a")
	if err != nil {
		t.Fatalf("snapshot tenant_a failed: %v", err)
	}
	snapshotB, err := runtime.Snapshot("tenant_b")
	if err != nil {
		t.Fatalf("snapshot tenant_b failed: %v", err)
	}

	if snapshotA.TenantID != "tenant_a" {
		t.Fatalf("expected tenant_a snapshot, got %s", snapshotA.TenantID)
	}
	if snapshotB.TenantID != "tenant_b" {
		t.Fatalf("expected tenant_b snapshot, got %s", snapshotB.TenantID)
	}
	if snapshotA.TotalTransitions != 1 {
		t.Fatalf("expected tenant_a total transition 1, got %d", snapshotA.TotalTransitions)
	}
	if snapshotB.TotalTransitions != 1 {
		t.Fatalf("expected tenant_b total transition 1, got %d", snapshotB.TotalTransitions)
	}
	if runtime.TenantCount() != 2 {
		t.Fatalf("expected tenant count 2, got %d", runtime.TenantCount())
	}
}

func TestWorkflowObservabilityRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewWorkflowObservabilityRuntime(DefaultWorkflowObservabilityRuntimeConfig())

	_, decision, err := runtime.RecordTransition(WorkflowTransitionEvent{
		WorkflowID: "wf_missing_tenant",
		FromState:  WorkflowStateDraft,
		ToState:    WorkflowStateReady,
	})
	if err != ErrWorkflowObservabilityMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != WorkflowObservabilityReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}

	_, err = runtime.Snapshot("")
	if err != ErrWorkflowObservabilityMissingTenant {
		t.Fatalf("expected missing tenant snapshot error, got %v", err)
	}
}

func TestWorkflowObservabilityRuntimeReturnsEmptySnapshotForNewTenant(t *testing.T) {
	runtime := NewWorkflowObservabilityRuntime(DefaultWorkflowObservabilityRuntimeConfig())

	snapshot, err := runtime.Snapshot("tenant_empty")
	if err != nil {
		t.Fatalf("snapshot failed: %v", err)
	}

	if snapshot.TenantID != "tenant_empty" {
		t.Fatalf("expected tenant_empty, got %s", snapshot.TenantID)
	}
	if snapshot.TotalTransitions != 0 {
		t.Fatalf("expected zero transitions, got %d", snapshot.TotalTransitions)
	}
	if len(snapshot.StateTransitionCounters) != 0 {
		t.Fatalf("expected empty transition counters")
	}
}
