package workflowruntime

import "testing"

func TestWorkflowStateMachineHappyPath(t *testing.T) {
	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())

	instance, err := NewWorkflowInstance("tenant_7", "wf_1", "purchase_approval")
	if err != nil {
		t.Fatalf("new instance failed: %v", err)
	}

	steps := []WorkflowTransitionRequest{
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_1",
			FromState:  WorkflowStateDraft,
			ToState:    WorkflowStateReady,
			StepID:     "step_prepare",
			ActorRef:   "system",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_1",
			FromState:  WorkflowStateReady,
			ToState:    WorkflowStateRunning,
			StepID:     "step_start",
			ActorRef:   "system",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_1",
			FromState:  WorkflowStateRunning,
			ToState:    WorkflowStateWaitingApproval,
			StepID:     "step_approval",
			ActorRef:   "system",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_1",
			FromState:  WorkflowStateWaitingApproval,
			ToState:    WorkflowStateRunning,
			StepID:     "step_after_approval",
			ActorRef:   "manager_1",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_1",
			FromState:  WorkflowStateRunning,
			ToState:    WorkflowStateCompleted,
			StepID:     "step_done",
			ActorRef:   "system",
		},
	}

	for _, req := range steps {
		var decision WorkflowTransitionDecision
		instance, decision, err = machine.Transition(instance, req)
		if err != nil {
			t.Fatalf("transition %s -> %s failed: %v", req.FromState, req.ToState, err)
		}
		if !decision.Allowed {
			t.Fatalf("expected allowed decision for %s -> %s", req.FromState, req.ToState)
		}
	}

	if instance.CurrentState != WorkflowStateCompleted {
		t.Fatalf("expected COMPLETED, got %s", instance.CurrentState)
	}
	if !machine.IsTerminal(instance.CurrentState) {
		t.Fatal("expected completed to be terminal")
	}
	if len(instance.AuditEvents) != len(steps) {
		t.Fatalf("expected %d audit events, got %d", len(steps), len(instance.AuditEvents))
	}
}

func TestWorkflowStateMachineRejectsCrossTenant(t *testing.T) {
	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())

	instance, err := NewWorkflowInstance("tenant_7", "wf_1", "purchase_approval")
	if err != nil {
		t.Fatalf("new instance failed: %v", err)
	}

	_, decision, err := machine.Transition(instance, WorkflowTransitionRequest{
		TenantID:   "tenant_8",
		WorkflowID: "wf_1",
		FromState:  WorkflowStateDraft,
		ToState:    WorkflowStateReady,
	})

	if err != ErrWorkflowCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != WorkflowReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestWorkflowStateMachineRejectsInvalidTransition(t *testing.T) {
	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())

	instance, err := NewWorkflowInstance("tenant_7", "wf_1", "purchase_approval")
	if err != nil {
		t.Fatalf("new instance failed: %v", err)
	}

	_, decision, err := machine.Transition(instance, WorkflowTransitionRequest{
		TenantID:   "tenant_7",
		WorkflowID: "wf_1",
		FromState:  WorkflowStateDraft,
		ToState:    WorkflowStateCompleted,
	})

	if err != ErrWorkflowInvalidTransition {
		t.Fatalf("expected invalid transition error, got %v", err)
	}
	if decision.Reason != WorkflowReasonInvalidTransition {
		t.Fatalf("expected invalid transition reason, got %s", decision.Reason)
	}
}

func TestWorkflowStateMachineRejectsTerminalTransition(t *testing.T) {
	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())

	instance, err := NewWorkflowInstance("tenant_7", "wf_1", "purchase_approval")
	if err != nil {
		t.Fatalf("new instance failed: %v", err)
	}

	instance.CurrentState = WorkflowStateCompleted

	_, decision, err := machine.Transition(instance, WorkflowTransitionRequest{
		TenantID:   "tenant_7",
		WorkflowID: "wf_1",
		FromState:  WorkflowStateCompleted,
		ToState:    WorkflowStateRunning,
	})

	if err != ErrWorkflowTerminalState {
		t.Fatalf("expected terminal state error, got %v", err)
	}
	if decision.Reason != WorkflowReasonTerminalState {
		t.Fatalf("expected terminal state reason, got %s", decision.Reason)
	}
}

func TestWorkflowStateMachineFailedCompensationPath(t *testing.T) {
	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())

	instance, err := NewWorkflowInstance("tenant_7", "wf_2", "stock_sync")
	if err != nil {
		t.Fatalf("new instance failed: %v", err)
	}

	sequence := []WorkflowTransitionRequest{
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_2",
			FromState:  WorkflowStateDraft,
			ToState:    WorkflowStateReady,
			StepID:     "step_ready",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_2",
			FromState:  WorkflowStateReady,
			ToState:    WorkflowStateRunning,
			StepID:     "step_run",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_2",
			FromState:  WorkflowStateRunning,
			ToState:    WorkflowStateFailed,
			StepID:     "step_failed",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_2",
			FromState:  WorkflowStateFailed,
			ToState:    WorkflowStateCompensating,
			StepID:     "step_compensating",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_2",
			FromState:  WorkflowStateCompensating,
			ToState:    WorkflowStateCompensated,
			StepID:     "step_compensated",
		},
	}

	for _, req := range sequence {
		var decision WorkflowTransitionDecision
		instance, decision, err = machine.Transition(instance, req)
		if err != nil {
			t.Fatalf("transition %s -> %s failed: %v", req.FromState, req.ToState, err)
		}
		if !decision.Allowed {
			t.Fatalf("expected allowed decision for %s -> %s", req.FromState, req.ToState)
		}
	}

	if instance.CurrentState != WorkflowStateCompensated {
		t.Fatalf("expected COMPENSATED, got %s", instance.CurrentState)
	}
	if !machine.IsTerminal(instance.CurrentState) {
		t.Fatal("expected compensated to be terminal")
	}
}

func TestWorkflowStateMachineRejectsStateMismatch(t *testing.T) {
	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())

	instance, err := NewWorkflowInstance("tenant_7", "wf_3", "demo")
	if err != nil {
		t.Fatalf("new instance failed: %v", err)
	}

	_, decision, err := machine.Transition(instance, WorkflowTransitionRequest{
		TenantID:   "tenant_7",
		WorkflowID: "wf_3",
		FromState:  WorkflowStateRunning,
		ToState:    WorkflowStateCompleted,
	})

	if err != ErrWorkflowStateMismatch {
		t.Fatalf("expected state mismatch error, got %v", err)
	}
	if decision.Reason != WorkflowReasonStateMismatch {
		t.Fatalf("expected state mismatch reason, got %s", decision.Reason)
	}
}
