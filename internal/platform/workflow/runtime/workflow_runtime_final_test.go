package workflowruntime

import "testing"

func finalWorkflowDefinitionJSON() []byte {
	return []byte(`{
	  "tenant_id": "tenant_final",
	  "definition_key": "final_purchase_approval",
	  "version": "v1",
	  "name": "Final Purchase Approval",
	  "status": "ACTIVE",
	  "initial_step_id": "prepare",
	  "steps": [
	    {
	      "step_id": "prepare",
	      "name": "Prepare",
	      "type": "TASK",
	      "next_step_ids": ["manager_approval"],
	      "retry_policy": {
	        "max_attempts": 2,
	        "backoff_strategy": "EXPONENTIAL",
	        "backoff_seconds": 10
	      }
	    },
	    {
	      "step_id": "manager_approval",
	      "name": "Manager Approval",
	      "type": "APPROVAL",
	      "next_step_ids": ["post_erp"],
	      "approval_policy": {
	        "required_role": "MANAGER",
	        "required_count": 1
	      }
	    },
	    {
	      "step_id": "post_erp",
	      "name": "Post ERP",
	      "type": "TASK",
	      "next_step_ids": ["rollback_erp"],
	      "retry_policy": {
	        "max_attempts": 1,
	        "backoff_strategy": "FIXED",
	        "backoff_seconds": 5
	      }
	    },
	    {
	      "step_id": "rollback_erp",
	      "name": "Rollback ERP",
	      "type": "COMPENSATION",
	      "compensation_step": {
	        "step_id": "post_erp",
	        "mode": "ROLLBACK"
	      }
	    }
	  ]
	}`)
}

func TestWorkflowRuntimeFinalEndToEndApprovalRetryCompensationObservability(t *testing.T) {
	loader := NewWorkflowDefinitionLoader(DefaultWorkflowDefinitionLoaderConfig())
	definition, loadDecision, err := loader.LoadJSON(WorkflowDefinitionLoadRequest{
		TenantID: "tenant_final",
		RawJSON:  finalWorkflowDefinitionJSON(),
	})
	if err != nil {
		t.Fatalf("definition load failed: %v", err)
	}
	if !loadDecision.Allowed {
		t.Fatalf("expected definition load allowed, got reason=%s", loadDecision.Reason)
	}
	if definition.DefinitionKey != "final_purchase_approval" {
		t.Fatalf("unexpected definition key %s", definition.DefinitionKey)
	}

	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())
	observability := NewWorkflowObservabilityRuntime(DefaultWorkflowObservabilityRuntimeConfig())
	approvalRuntime := NewManualApprovalRuntime(DefaultManualApprovalRuntimeConfig())
	retryRuntime := NewWorkflowRetryCompensationRuntime(DefaultWorkflowRetryCompensationRuntimeConfig())

	instance, err := NewWorkflowInstance("tenant_final", "wf_final_1", definition.DefinitionKey)
	if err != nil {
		t.Fatalf("new workflow instance failed: %v", err)
	}

	transitionRequests := []WorkflowTransitionRequest{
		{
			TenantID:   "tenant_final",
			WorkflowID: instance.WorkflowID,
			FromState:  WorkflowStateDraft,
			ToState:    WorkflowStateReady,
			StepID:     "prepare",
			ActorRef:   "system",
		},
		{
			TenantID:   "tenant_final",
			WorkflowID: instance.WorkflowID,
			FromState:  WorkflowStateReady,
			ToState:    WorkflowStateRunning,
			StepID:     "prepare",
			ActorRef:   "system",
		},
		{
			TenantID:   "tenant_final",
			WorkflowID: instance.WorkflowID,
			FromState:  WorkflowStateRunning,
			ToState:    WorkflowStateWaitingApproval,
			StepID:     "manager_approval",
			ActorRef:   "system",
		},
	}

	for _, req := range transitionRequests {
		var transition WorkflowTransitionDecision
		instance, transition, err = machine.Transition(instance, req)
		if err != nil {
			t.Fatalf("transition %s -> %s failed: %v", req.FromState, req.ToState, err)
		}
		if !transition.Allowed {
			t.Fatalf("expected transition allowed, got reason=%s", transition.Reason)
		}

		if len(instance.AuditEvents) == 0 {
			t.Fatalf("expected transition audit event")
		}
		lastEvent := instance.AuditEvents[len(instance.AuditEvents)-1]
		if _, _, err := observability.RecordTransition(lastEvent); err != nil {
			t.Fatalf("record transition metric failed: %v", err)
		}
	}

	if instance.CurrentState != WorkflowStateWaitingApproval {
		t.Fatalf("expected WAITING_APPROVAL, got %s", instance.CurrentState)
	}

	approvalStep, ok := definition.StepByID("manager_approval")
	if !ok {
		t.Fatal("approval step missing")
	}
	if approvalStep.ApprovalPolicy == nil {
		t.Fatal("approval policy missing")
	}

	approval, approvalCreateDecision, err := approvalRuntime.CreateApprovalRequest(ManualApprovalCreateRequest{
		TenantID:      "tenant_final",
		WorkflowID:    instance.WorkflowID,
		StepID:        approvalStep.StepID,
		RequiredRole:  approvalStep.ApprovalPolicy.RequiredRole,
		RequiredCount: approvalStep.ApprovalPolicy.RequiredCount,
		RequestedBy:   "system",
	})
	if err != nil {
		t.Fatalf("create approval failed: %v", err)
	}
	if !approvalCreateDecision.Allowed {
		t.Fatalf("expected approval create allowed, got reason=%s", approvalCreateDecision.Reason)
	}

	approval, approvalDecision, err := approvalRuntime.Decide(ManualApprovalDecisionRequest{
		TenantID:      "tenant_final",
		ApprovalID:    approval.ApprovalID,
		WorkflowID:    instance.WorkflowID,
		StepID:        approvalStep.StepID,
		ApproverRef:   "manager_final",
		ApproverRoles: []string{"MANAGER"},
		Decision:      ApprovalDecisionApprove,
		Comment:       "final approval accepted",
	})
	if err != nil {
		t.Fatalf("approval decision failed: %v", err)
	}
	if !approvalDecision.Allowed {
		t.Fatalf("expected approval decision allowed, got reason=%s", approvalDecision.Reason)
	}
	if _, _, err := observability.RecordApproval(approval); err != nil {
		t.Fatalf("record approval metric failed: %v", err)
	}

	instance, workflowDecision, err := approvalRuntime.ApplyDecisionToWorkflow(machine, instance, approval, "manager_final")
	if err != nil {
		t.Fatalf("apply approval to workflow failed: %v", err)
	}
	if !workflowDecision.Allowed {
		t.Fatalf("expected approval workflow bridge allowed, got reason=%s", workflowDecision.Reason)
	}
	if instance.CurrentState != WorkflowStateRunning {
		t.Fatalf("expected RUNNING after approval, got %s", instance.CurrentState)
	}
	if len(instance.AuditEvents) == 0 {
		t.Fatal("expected audit event after approval bridge")
	}
	if _, _, err := observability.RecordTransition(instance.AuditEvents[len(instance.AuditEvents)-1]); err != nil {
		t.Fatalf("record approval transition metric failed: %v", err)
	}

	postStep, ok := definition.StepByID("post_erp")
	if !ok {
		t.Fatal("post_erp step missing")
	}
	if postStep.RetryPolicy == nil {
		t.Fatal("post_erp retry policy missing")
	}

	instance, workflowDecision, err = machine.Transition(instance, WorkflowTransitionRequest{
		TenantID:   "tenant_final",
		WorkflowID: instance.WorkflowID,
		FromState:  WorkflowStateRunning,
		ToState:    WorkflowStateFailed,
		StepID:     postStep.StepID,
		ActorRef:   "workflow-worker",
		Reason:     "provider timeout",
	})
	if err != nil {
		t.Fatalf("failed transition failed: %v", err)
	}
	if !workflowDecision.Allowed {
		t.Fatalf("expected failed transition allowed, got reason=%s", workflowDecision.Reason)
	}
	if _, _, err := observability.RecordTransition(instance.AuditEvents[len(instance.AuditEvents)-1]); err != nil {
		t.Fatalf("record failed transition metric failed: %v", err)
	}

	runtimePolicy := WorkflowRetryRuntimePolicy{
		MaxAttempts:     postStep.RetryPolicy.MaxAttempts,
		BackoffStrategy: postStep.RetryPolicy.BackoffStrategy,
		BackoffSeconds:  postStep.RetryPolicy.BackoffSeconds,
	}

	retryAttempt, retryDecision, err := retryRuntime.DecideFailedStep(WorkflowRetryDecisionRequest{
		TenantID:       "tenant_final",
		WorkflowID:     instance.WorkflowID,
		StepID:         postStep.StepID,
		CurrentAttempt: 0,
		Policy:         runtimePolicy,
		LastErrorCode:  "TEMPORARY_PROVIDER_ERROR",
	})
	if err != nil {
		t.Fatalf("retry decision failed: %v", err)
	}
	if retryAttempt.Status != WorkflowRetryAttemptStatusScheduled {
		t.Fatalf("expected scheduled retry, got %s", retryAttempt.Status)
	}
	if retryDecision.Action != WorkflowRetryActionRetry {
		t.Fatalf("expected retry action, got %s", retryDecision.Action)
	}
	if _, _, err := observability.RecordRetryDecision(retryDecision); err != nil {
		t.Fatalf("record retry metric failed: %v", err)
	}

	_, retryDecision, err = retryRuntime.DecideFailedStep(WorkflowRetryDecisionRequest{
		TenantID:       "tenant_final",
		WorkflowID:     instance.WorkflowID,
		StepID:         postStep.StepID,
		CurrentAttempt: runtimePolicy.MaxAttempts,
		Policy:         runtimePolicy,
		LastErrorCode:  "TEMPORARY_PROVIDER_ERROR",
	})
	if err != nil {
		t.Fatalf("retry exhaustion decision failed: %v", err)
	}
	if retryDecision.Action != WorkflowRetryActionCompensate {
		t.Fatalf("expected compensate action, got %s", retryDecision.Action)
	}
	if _, _, err := observability.RecordRetryDecision(retryDecision); err != nil {
		t.Fatalf("record compensate retry metric failed: %v", err)
	}

	compStep, ok := definition.StepByID("rollback_erp")
	if !ok {
		t.Fatal("rollback_erp compensation step missing")
	}

	compensation, compDecision, err := retryRuntime.RequestCompensation(WorkflowCompensationRequest{
		TenantID:           "tenant_final",
		WorkflowID:         instance.WorkflowID,
		FailedStepID:       postStep.StepID,
		CompensationStepID: compStep.StepID,
		Reason:             "retry exhausted",
	})
	if err != nil {
		t.Fatalf("request compensation failed: %v", err)
	}
	if !compDecision.Allowed {
		t.Fatalf("expected compensation decision allowed, got reason=%s", compDecision.Reason)
	}

	compensation, _, err = retryRuntime.StartCompensation("tenant_final", compensation.CompensationID)
	if err != nil {
		t.Fatalf("start compensation failed: %v", err)
	}

	instance, workflowDecision, err = retryRuntime.ApplyCompensationStartToWorkflow(machine, instance, compensation, "workflow-worker")
	if err != nil {
		t.Fatalf("apply compensation start failed: %v", err)
	}
	if !workflowDecision.Allowed {
		t.Fatalf("expected compensation start transition allowed, got reason=%s", workflowDecision.Reason)
	}
	if instance.CurrentState != WorkflowStateCompensating {
		t.Fatalf("expected COMPENSATING, got %s", instance.CurrentState)
	}
	if _, _, err := observability.RecordTransition(instance.AuditEvents[len(instance.AuditEvents)-1]); err != nil {
		t.Fatalf("record compensation start transition metric failed: %v", err)
	}

	compensation, _, err = retryRuntime.CompleteCompensation("tenant_final", compensation.CompensationID)
	if err != nil {
		t.Fatalf("complete compensation failed: %v", err)
	}
	if _, _, err := observability.RecordCompensation(compensation); err != nil {
		t.Fatalf("record compensation metric failed: %v", err)
	}

	instance, workflowDecision, err = retryRuntime.ApplyCompensationCompleteToWorkflow(machine, instance, compensation, "workflow-worker")
	if err != nil {
		t.Fatalf("apply compensation complete failed: %v", err)
	}
	if !workflowDecision.Allowed {
		t.Fatalf("expected compensation complete transition allowed, got reason=%s", workflowDecision.Reason)
	}
	if instance.CurrentState != WorkflowStateCompensated {
		t.Fatalf("expected COMPENSATED, got %s", instance.CurrentState)
	}
	if _, _, err := observability.RecordTransition(instance.AuditEvents[len(instance.AuditEvents)-1]); err != nil {
		t.Fatalf("record compensation complete transition metric failed: %v", err)
	}

	snapshot, err := observability.Snapshot("tenant_final")
	if err != nil {
		t.Fatalf("snapshot failed: %v", err)
	}

	if snapshot.TotalTransitions < 7 {
		t.Fatalf("expected at least 7 transitions, got %d", snapshot.TotalTransitions)
	}
	if snapshot.TotalApprovals != 1 {
		t.Fatalf("expected total approvals 1, got %d", snapshot.TotalApprovals)
	}
	if snapshot.TotalRetryDecisions != 2 {
		t.Fatalf("expected retry decisions 2, got %d", snapshot.TotalRetryDecisions)
	}
	if snapshot.TotalCompensations != 1 {
		t.Fatalf("expected compensations 1, got %d", snapshot.TotalCompensations)
	}
	if snapshot.FailedWorkflowCounters[WorkflowStateFailed] != 1 {
		t.Fatalf("expected failed workflow counter 1, got %d", snapshot.FailedWorkflowCounters[WorkflowStateFailed])
	}
}

func TestWorkflowRuntimeFinalCrossTenantDenyAcrossModules(t *testing.T) {
	loader := NewWorkflowDefinitionLoader(DefaultWorkflowDefinitionLoaderConfig())
	_, loadDecision, err := loader.LoadJSON(WorkflowDefinitionLoadRequest{
		TenantID: "tenant_other",
		RawJSON:  finalWorkflowDefinitionJSON(),
	})
	if err != ErrWorkflowDefinitionCrossTenant {
		t.Fatalf("expected definition cross tenant error, got %v", err)
	}
	if loadDecision.Reason != WorkflowDefinitionReasonCrossTenant {
		t.Fatalf("expected definition cross tenant reason, got %s", loadDecision.Reason)
	}

	machine := NewWorkflowStateMachine(DefaultWorkflowStateMachineConfig())
	instance, err := NewWorkflowInstance("tenant_final", "wf_cross_1", "final_purchase_approval")
	if err != nil {
		t.Fatalf("new instance failed: %v", err)
	}
	_, stateDecision, err := machine.Transition(instance, WorkflowTransitionRequest{
		TenantID:   "tenant_other",
		WorkflowID: instance.WorkflowID,
		FromState:  WorkflowStateDraft,
		ToState:    WorkflowStateReady,
	})
	if err != ErrWorkflowCrossTenant {
		t.Fatalf("expected state machine cross tenant error, got %v", err)
	}
	if stateDecision.Reason != WorkflowReasonCrossTenant {
		t.Fatalf("expected state cross tenant reason, got %s", stateDecision.Reason)
	}

	approvalRuntime := NewManualApprovalRuntime(DefaultManualApprovalRuntimeConfig())
	approval, _, err := approvalRuntime.CreateApprovalRequest(ManualApprovalCreateRequest{
		TenantID:      "tenant_final",
		WorkflowID:    "wf_cross_approval",
		StepID:        "manager_approval",
		RequiredRole:  "MANAGER",
		RequiredCount: 1,
	})
	if err != nil {
		t.Fatalf("create approval failed: %v", err)
	}

	_, approvalDecision, err := approvalRuntime.Decide(ManualApprovalDecisionRequest{
		TenantID:      "tenant_other",
		ApprovalID:    approval.ApprovalID,
		ApproverRef:   "manager_1",
		ApproverRoles: []string{"MANAGER"},
		Decision:      ApprovalDecisionApprove,
	})
	if err != ErrApprovalCrossTenant {
		t.Fatalf("expected approval cross tenant error, got %v", err)
	}
	if approvalDecision.Reason != ApprovalReasonCrossTenant {
		t.Fatalf("expected approval cross tenant reason, got %s", approvalDecision.Reason)
	}

	retryRuntime := NewWorkflowRetryCompensationRuntime(DefaultWorkflowRetryCompensationRuntimeConfig())
	compensation, _, err := retryRuntime.RequestCompensation(WorkflowCompensationRequest{
		TenantID:           "tenant_final",
		WorkflowID:         "wf_cross_comp",
		FailedStepID:       "failed_step",
		CompensationStepID: "rollback_step",
	})
	if err != nil {
		t.Fatalf("request compensation failed: %v", err)
	}

	_, compensationDecision, err := retryRuntime.StartCompensation("tenant_other", compensation.CompensationID)
	if err != ErrWorkflowCompensationCrossTenant {
		t.Fatalf("expected compensation cross tenant error, got %v", err)
	}
	if compensationDecision.Reason != WorkflowCompensationReasonCrossTenant {
		t.Fatalf("expected compensation cross tenant reason, got %s", compensationDecision.Reason)
	}

	observability := NewWorkflowObservabilityRuntime(DefaultWorkflowObservabilityRuntimeConfig())
	_, _, err = observability.RecordTransition(WorkflowTransitionEvent{
		TenantID:   "tenant_final",
		WorkflowID: "wf_obs",
		FromState:  WorkflowStateDraft,
		ToState:    WorkflowStateReady,
	})
	if err != nil {
		t.Fatalf("record observability failed: %v", err)
	}

	snapshotOther, err := observability.Snapshot("tenant_other")
	if err != nil {
		t.Fatalf("snapshot other tenant failed: %v", err)
	}
	if snapshotOther.TotalTransitions != 0 {
		t.Fatalf("expected other tenant to see zero transitions, got %d", snapshotOther.TotalTransitions)
	}
}
