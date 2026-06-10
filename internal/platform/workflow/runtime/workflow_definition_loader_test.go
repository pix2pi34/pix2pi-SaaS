package workflowruntime

import (
	"errors"
	"testing"
)

func validWorkflowDefinitionJSON() []byte {
	return []byte(`{
	  "tenant_id": "tenant_7",
	  "definition_key": "purchase_approval",
	  "version": "v1",
	  "name": "Purchase Approval",
	  "status": "ACTIVE",
	  "initial_step_id": "prepare",
	  "steps": [
	    {
	      "step_id": "prepare",
	      "name": "Prepare Purchase",
	      "type": "TASK",
	      "next_step_ids": ["manager_approval"],
	      "retry_policy": {
	        "max_attempts": 3,
	        "backoff_strategy": "EXPONENTIAL",
	        "backoff_seconds": 60
	      }
	    },
	    {
	      "step_id": "manager_approval",
	      "name": "Manager Approval",
	      "type": "APPROVAL",
	      "next_step_ids": ["post_to_erp"],
	      "approval_policy": {
	        "required_role": "MANAGER",
	        "required_count": 1,
	        "timeout_seconds": 86400
	      }
	    },
	    {
	      "step_id": "post_to_erp",
	      "name": "Post To ERP",
	      "type": "TASK",
	      "next_step_ids": ["compensate_erp"],
	      "retry_policy": {
	        "max_attempts": 2,
	        "backoff_strategy": "LINEAR",
	        "backoff_seconds": 30
	      }
	    },
	    {
	      "step_id": "compensate_erp",
	      "name": "Compensate ERP",
	      "type": "COMPENSATION",
	      "compensation_step": {
	        "step_id": "post_to_erp",
	        "mode": "ROLLBACK"
	      }
	    }
	  ]
	}`)
}

func TestWorkflowDefinitionLoaderLoadsValidDefinition(t *testing.T) {
	loader := NewWorkflowDefinitionLoader(DefaultWorkflowDefinitionLoaderConfig())

	definition, decision, err := loader.LoadJSON(WorkflowDefinitionLoadRequest{
		TenantID: "tenant_7",
		RawJSON:  validWorkflowDefinitionJSON(),
	})
	if err != nil {
		t.Fatalf("load failed: %v", err)
	}

	if !decision.Allowed {
		t.Fatalf("expected allowed decision, got reason=%s", decision.Reason)
	}
	if decision.Decision != WorkflowDefinitionDecisionAllow {
		t.Fatalf("expected ALLOW, got %s", decision.Decision)
	}
	if definition.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", definition.TenantID)
	}
	if definition.DefinitionKey != "purchase_approval" {
		t.Fatalf("unexpected definition key %s", definition.DefinitionKey)
	}
	if definition.InitialStepID != "prepare" {
		t.Fatalf("unexpected initial step %s", definition.InitialStepID)
	}
	if len(definition.Steps) != 4 {
		t.Fatalf("expected 4 steps, got %d", len(definition.Steps))
	}

	approval, ok := definition.StepByID("manager_approval")
	if !ok {
		t.Fatal("approval step not found")
	}
	if approval.Type != WorkflowStepTypeApproval {
		t.Fatalf("expected approval type, got %s", approval.Type)
	}
	if approval.ApprovalPolicy == nil || approval.ApprovalPolicy.RequiredRole != "MANAGER" {
		t.Fatalf("approval policy missing or invalid")
	}

	compensation, ok := definition.StepByID("compensate_erp")
	if !ok {
		t.Fatal("compensation step not found")
	}
	if compensation.CompensationStep == nil || compensation.CompensationStep.StepID != "post_to_erp" {
		t.Fatalf("compensation definition missing or invalid")
	}
}

func TestWorkflowDefinitionLoaderDefaultsTenantFromRequest(t *testing.T) {
	loader := NewWorkflowDefinitionLoader(DefaultWorkflowDefinitionLoaderConfig())

	raw := []byte(`{
	  "definition_key": "simple_flow",
	  "version": "v1",
	  "name": "Simple Flow",
	  "initial_step_id": "start",
	  "steps": [
	    {
	      "step_id": "start",
	      "name": "Start",
	      "type": "TASK"
	    }
	  ]
	}`)

	definition, decision, err := loader.LoadJSON(WorkflowDefinitionLoadRequest{
		TenantID: "tenant_7",
		RawJSON:  raw,
	})
	if err != nil {
		t.Fatalf("load failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected allowed decision")
	}
	if definition.TenantID != "tenant_7" {
		t.Fatalf("expected request tenant to be applied, got %s", definition.TenantID)
	}
	if definition.Status != WorkflowDefinitionStatusDraft {
		t.Fatalf("expected DRAFT default status, got %s", definition.Status)
	}
}

func TestWorkflowDefinitionLoaderRejectsCrossTenantDefinition(t *testing.T) {
	loader := NewWorkflowDefinitionLoader(DefaultWorkflowDefinitionLoaderConfig())

	_, decision, err := loader.LoadJSON(WorkflowDefinitionLoadRequest{
		TenantID: "tenant_8",
		RawJSON:  validWorkflowDefinitionJSON(),
	})

	if !errors.Is(err, ErrWorkflowDefinitionCrossTenant) {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != WorkflowDefinitionReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestWorkflowDefinitionLoaderRejectsInvalidJSON(t *testing.T) {
	loader := NewWorkflowDefinitionLoader(DefaultWorkflowDefinitionLoaderConfig())

	_, decision, err := loader.LoadJSON(WorkflowDefinitionLoadRequest{
		TenantID: "tenant_7",
		RawJSON:  []byte(`{invalid-json}`),
	})

	if !errors.Is(err, ErrWorkflowDefinitionInvalidJSON) {
		t.Fatalf("expected invalid json error, got %v", err)
	}
	if decision.Reason != WorkflowDefinitionReasonInvalidJSON {
		t.Fatalf("expected invalid json reason, got %s", decision.Reason)
	}
}

func TestWorkflowDefinitionLoaderRejectsDuplicateStep(t *testing.T) {
	loader := NewWorkflowDefinitionLoader(DefaultWorkflowDefinitionLoaderConfig())

	raw := []byte(`{
	  "tenant_id": "tenant_7",
	  "definition_key": "bad_flow",
	  "version": "v1",
	  "name": "Bad Flow",
	  "initial_step_id": "step_1",
	  "steps": [
	    {
	      "step_id": "step_1",
	      "name": "Step 1",
	      "type": "TASK"
	    },
	    {
	      "step_id": "step_1",
	      "name": "Step 1 Duplicate",
	      "type": "TASK"
	    }
	  ]
	}`)

	_, decision, err := loader.LoadJSON(WorkflowDefinitionLoadRequest{
		TenantID: "tenant_7",
		RawJSON:  raw,
	})

	if !errors.Is(err, ErrWorkflowDefinitionDuplicateStep) {
		t.Fatalf("expected duplicate step error, got %v", err)
	}
	if decision.Reason != WorkflowDefinitionReasonDuplicateStep {
		t.Fatalf("expected duplicate step reason, got %s", decision.Reason)
	}
}

func TestWorkflowDefinitionLoaderRejectsApprovalWithoutPolicy(t *testing.T) {
	loader := NewWorkflowDefinitionLoader(DefaultWorkflowDefinitionLoaderConfig())

	raw := []byte(`{
	  "tenant_id": "tenant_7",
	  "definition_key": "bad_approval",
	  "version": "v1",
	  "name": "Bad Approval",
	  "initial_step_id": "approval",
	  "steps": [
	    {
	      "step_id": "approval",
	      "name": "Approval",
	      "type": "APPROVAL"
	    }
	  ]
	}`)

	_, decision, err := loader.LoadJSON(WorkflowDefinitionLoadRequest{
		TenantID: "tenant_7",
		RawJSON:  raw,
	})

	if !errors.Is(err, ErrWorkflowDefinitionMissingApprovalPolicy) {
		t.Fatalf("expected missing approval policy error, got %v", err)
	}
	if decision.Reason != WorkflowDefinitionReasonMissingApprovalPolicy {
		t.Fatalf("expected missing approval policy reason, got %s", decision.Reason)
	}
}

func TestWorkflowDefinitionLoaderRejectsMissingCompensationStep(t *testing.T) {
	loader := NewWorkflowDefinitionLoader(DefaultWorkflowDefinitionLoaderConfig())

	raw := []byte(`{
	  "tenant_id": "tenant_7",
	  "definition_key": "bad_compensation",
	  "version": "v1",
	  "name": "Bad Compensation",
	  "initial_step_id": "compensate",
	  "steps": [
	    {
	      "step_id": "compensate",
	      "name": "Compensate",
	      "type": "COMPENSATION",
	      "compensation_step": {
	        "step_id": "missing_step",
	        "mode": "ROLLBACK"
	      }
	    }
	  ]
	}`)

	_, decision, err := loader.LoadJSON(WorkflowDefinitionLoadRequest{
		TenantID: "tenant_7",
		RawJSON:  raw,
	})

	if !errors.Is(err, ErrWorkflowDefinitionMissingCompensationStep) {
		t.Fatalf("expected missing compensation step error, got %v", err)
	}
	if decision.Reason != WorkflowDefinitionReasonMissingCompensationStep {
		t.Fatalf("expected missing compensation reason, got %s", decision.Reason)
	}
}

func TestWorkflowDefinitionLoaderRejectsInvalidInitialStep(t *testing.T) {
	loader := NewWorkflowDefinitionLoader(DefaultWorkflowDefinitionLoaderConfig())

	raw := []byte(`{
	  "tenant_id": "tenant_7",
	  "definition_key": "bad_initial",
	  "version": "v1",
	  "name": "Bad Initial",
	  "initial_step_id": "missing",
	  "steps": [
	    {
	      "step_id": "start",
	      "name": "Start",
	      "type": "TASK"
	    }
	  ]
	}`)

	_, decision, err := loader.LoadJSON(WorkflowDefinitionLoadRequest{
		TenantID: "tenant_7",
		RawJSON:  raw,
	})

	if !errors.Is(err, ErrWorkflowDefinitionInvalidInitialStep) {
		t.Fatalf("expected invalid initial step error, got %v", err)
	}
	if decision.Reason != WorkflowDefinitionReasonInvalidInitialStep {
		t.Fatalf("expected invalid initial step reason, got %s", decision.Reason)
	}
}
