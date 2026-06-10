package workflowruntime

import (
	"testing"
)

func workflowWaitingApprovalInstance(t *testing.T) WorkflowInstance {
	t.Helper()

	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())

	instance, err := NewWorkflowInstance("tenant_7", "wf_approval_1", "purchase_approval")
	if err != nil {
		t.Fatalf("new instance failed: %v", err)
	}

	sequence := []WorkflowTransitionRequest{
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_approval_1",
			FromState:  WorkflowStateDraft,
			ToState:    WorkflowStateReady,
			StepID:     "prepare",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_approval_1",
			FromState:  WorkflowStateReady,
			ToState:    WorkflowStateRunning,
			StepID:     "start",
		},
		{
			TenantID:   "tenant_7",
			WorkflowID: "wf_approval_1",
			FromState:  WorkflowStateRunning,
			ToState:    WorkflowStateWaitingApproval,
			StepID:     "manager_approval",
		},
	}

	for _, req := range sequence {
		instance, _, err = machine.Transition(instance, req)
		if err != nil {
			t.Fatalf("transition failed: %v", err)
		}
	}

	if instance.CurrentState != WorkflowStateWaitingApproval {
		t.Fatalf("expected waiting approval, got %s", instance.CurrentState)
	}

	return instance
}

func TestManualApprovalRuntimeApproveLifecycle(t *testing.T) {
	runtime := NewManualApprovalRuntime(DefaultManualApprovalRuntimeConfig())

	approval, decision, err := runtime.CreateApprovalRequest(ManualApprovalCreateRequest{
		TenantID:      "tenant_7",
		WorkflowID:    "wf_approval_1",
		StepID:        "manager_approval",
		RequiredRole:  "MANAGER",
		RequiredCount: 1,
		RequestedBy:   "system",
	})
	if err != nil {
		t.Fatalf("create approval failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected create allowed, got reason=%s", decision.Reason)
	}
	if approval.ApprovalID == "" {
		t.Fatal("expected approval id")
	}
	if approval.Status != ApprovalRequestStatusPending {
		t.Fatalf("expected PENDING, got %s", approval.Status)
	}

	approval, decision, err = runtime.Decide(ManualApprovalDecisionRequest{
		TenantID:      "tenant_7",
		ApprovalID:    approval.ApprovalID,
		WorkflowID:    "wf_approval_1",
		StepID:        "manager_approval",
		ApproverRef:   "manager_1",
		ApproverRoles: []string{"MANAGER"},
		Decision:      ApprovalDecisionApprove,
		Comment:       "approved",
	})
	if err != nil {
		t.Fatalf("approval decision failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected decision allowed, got reason=%s", decision.Reason)
	}
	if approval.Status != ApprovalRequestStatusApproved {
		t.Fatalf("expected APPROVED, got %s", approval.Status)
	}
	if len(approval.Decisions) != 1 {
		t.Fatalf("expected 1 decision, got %d", len(approval.Decisions))
	}
}

func TestManualApprovalRuntimeRejectLifecycle(t *testing.T) {
	runtime := NewManualApprovalRuntime(DefaultManualApprovalRuntimeConfig())

	approval, _, err := runtime.CreateApprovalRequest(ManualApprovalCreateRequest{
		TenantID:      "tenant_7",
		WorkflowID:    "wf_approval_2",
		StepID:        "manager_approval",
		RequiredRole:  "MANAGER",
		RequiredCount: 1,
	})
	if err != nil {
		t.Fatalf("create approval failed: %v", err)
	}

	approval, _, err = runtime.Decide(ManualApprovalDecisionRequest{
		TenantID:      "tenant_7",
		ApprovalID:    approval.ApprovalID,
		ApproverRef:   "manager_1",
		ApproverRoles: []string{"MANAGER"},
		Decision:      ApprovalDecisionReject,
		Comment:       "rejected",
	})
	if err != nil {
		t.Fatalf("reject decision failed: %v", err)
	}

	if approval.Status != ApprovalRequestStatusRejected {
		t.Fatalf("expected REJECTED, got %s", approval.Status)
	}
}

func TestManualApprovalRuntimeRejectsWrongRole(t *testing.T) {
	runtime := NewManualApprovalRuntime(DefaultManualApprovalRuntimeConfig())

	approval, _, err := runtime.CreateApprovalRequest(ManualApprovalCreateRequest{
		TenantID:      "tenant_7",
		WorkflowID:    "wf_approval_3",
		StepID:        "manager_approval",
		RequiredRole:  "MANAGER",
		RequiredCount: 1,
	})
	if err != nil {
		t.Fatalf("create approval failed: %v", err)
	}

	_, decision, err := runtime.Decide(ManualApprovalDecisionRequest{
		TenantID:      "tenant_7",
		ApprovalID:    approval.ApprovalID,
		ApproverRef:   "user_1",
		ApproverRoles: []string{"CASHIER"},
		Decision:      ApprovalDecisionApprove,
	})

	if err != ErrApprovalRoleDenied {
		t.Fatalf("expected role denied, got %v", err)
	}
	if decision.Reason != ApprovalReasonRoleDenied {
		t.Fatalf("expected role denied reason, got %s", decision.Reason)
	}
}

func TestManualApprovalRuntimeRejectsCrossTenantAccess(t *testing.T) {
	runtime := NewManualApprovalRuntime(DefaultManualApprovalRuntimeConfig())

	approval, _, err := runtime.CreateApprovalRequest(ManualApprovalCreateRequest{
		TenantID:      "tenant_7",
		WorkflowID:    "wf_approval_4",
		StepID:        "manager_approval",
		RequiredRole:  "MANAGER",
		RequiredCount: 1,
	})
	if err != nil {
		t.Fatalf("create approval failed: %v", err)
	}

	_, decision, err := runtime.Decide(ManualApprovalDecisionRequest{
		TenantID:      "tenant_8",
		ApprovalID:    approval.ApprovalID,
		ApproverRef:   "manager_1",
		ApproverRoles: []string{"MANAGER"},
		Decision:      ApprovalDecisionApprove,
	})

	if err != ErrApprovalCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != ApprovalReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestManualApprovalRuntimeRejectsDuplicateFinalDecision(t *testing.T) {
	runtime := NewManualApprovalRuntime(DefaultManualApprovalRuntimeConfig())

	approval, _, err := runtime.CreateApprovalRequest(ManualApprovalCreateRequest{
		TenantID:      "tenant_7",
		WorkflowID:    "wf_approval_5",
		StepID:        "manager_approval",
		RequiredRole:  "MANAGER",
		RequiredCount: 1,
	})
	if err != nil {
		t.Fatalf("create approval failed: %v", err)
	}

	approval, _, err = runtime.Decide(ManualApprovalDecisionRequest{
		TenantID:      "tenant_7",
		ApprovalID:    approval.ApprovalID,
		ApproverRef:   "manager_1",
		ApproverRoles: []string{"MANAGER"},
		Decision:      ApprovalDecisionApprove,
	})
	if err != nil {
		t.Fatalf("first decision failed: %v", err)
	}

	_, decision, err := runtime.Decide(ManualApprovalDecisionRequest{
		TenantID:      "tenant_7",
		ApprovalID:    approval.ApprovalID,
		ApproverRef:   "manager_2",
		ApproverRoles: []string{"MANAGER"},
		Decision:      ApprovalDecisionApprove,
	})

	if err != ErrApprovalAlreadyFinal {
		t.Fatalf("expected already final error, got %v", err)
	}
	if decision.Reason != ApprovalReasonAlreadyFinal {
		t.Fatalf("expected already final reason, got %s", decision.Reason)
	}
}

func TestManualApprovalRuntimeApprovalWaitStateBridgeApprove(t *testing.T) {
	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())
	instance := workflowWaitingApprovalInstance(t)

	runtime := NewManualApprovalRuntime(DefaultManualApprovalRuntimeConfig())

	approval, _, err := runtime.CreateApprovalRequest(ManualApprovalCreateRequest{
		TenantID:      "tenant_7",
		WorkflowID:    instance.WorkflowID,
		StepID:        "manager_approval",
		RequiredRole:  "MANAGER",
		RequiredCount: 1,
	})
	if err != nil {
		t.Fatalf("create approval failed: %v", err)
	}

	approval, _, err = runtime.Decide(ManualApprovalDecisionRequest{
		TenantID:      "tenant_7",
		ApprovalID:    approval.ApprovalID,
		ApproverRef:   "manager_1",
		ApproverRoles: []string{"MANAGER"},
		Decision:      ApprovalDecisionApprove,
	})
	if err != nil {
		t.Fatalf("approve failed: %v", err)
	}

	next, transition, err := runtime.ApplyDecisionToWorkflow(machine, instance, approval, "manager_1")
	if err != nil {
		t.Fatalf("apply decision to workflow failed: %v", err)
	}
	if !transition.Allowed {
		t.Fatalf("expected transition allowed, got reason=%s", transition.Reason)
	}
	if next.CurrentState != WorkflowStateRunning {
		t.Fatalf("expected RUNNING after approval, got %s", next.CurrentState)
	}
}

func TestManualApprovalRuntimeApprovalWaitStateBridgeReject(t *testing.T) {
	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())
	instance := workflowWaitingApprovalInstance(t)

	runtime := NewManualApprovalRuntime(DefaultManualApprovalRuntimeConfig())

	approval, _, err := runtime.CreateApprovalRequest(ManualApprovalCreateRequest{
		TenantID:      "tenant_7",
		WorkflowID:    instance.WorkflowID,
		StepID:        "manager_approval",
		RequiredRole:  "MANAGER",
		RequiredCount: 1,
	})
	if err != nil {
		t.Fatalf("create approval failed: %v", err)
	}

	approval, _, err = runtime.Decide(ManualApprovalDecisionRequest{
		TenantID:      "tenant_7",
		ApprovalID:    approval.ApprovalID,
		ApproverRef:   "manager_1",
		ApproverRoles: []string{"MANAGER"},
		Decision:      ApprovalDecisionReject,
	})
	if err != nil {
		t.Fatalf("reject failed: %v", err)
	}

	next, transition, err := runtime.ApplyDecisionToWorkflow(machine, instance, approval, "manager_1")
	if err != nil {
		t.Fatalf("apply decision to workflow failed: %v", err)
	}
	if !transition.Allowed {
		t.Fatalf("expected transition allowed, got reason=%s", transition.Reason)
	}
	if next.CurrentState != WorkflowStateApprovalRejected {
		t.Fatalf("expected APPROVAL_REJECTED after reject, got %s", next.CurrentState)
	}
}
