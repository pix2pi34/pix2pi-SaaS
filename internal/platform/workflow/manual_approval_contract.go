package workflow

import (
	"strings"
	"time"
)

var allowedWorkflowApprovalDecisions = map[string]struct{}{
	"approve": {},
	"reject":  {},
}

var allowedWorkflowApprovalStatuses = map[string]struct{}{
	"approved": {},
	"rejected": {},
}

type ApplyManualApprovalRequest struct {
	TenantID      string `json:"tenant_id,omitempty"`
	WorkflowRunID string `json:"workflow_run_id"`
	StepKey       string `json:"step_key"`
	ApprovalID    string `json:"approval_id"`
	ApproverRef   string `json:"approver_ref"`
	Decision      string `json:"decision"`
	Comment       string `json:"comment,omitempty"`
}

type ApplyManualApprovalResponse struct {
	WorkflowRunID     string    `json:"workflow_run_id"`
	StepKey           string    `json:"step_key"`
	ApprovalID        string    `json:"approval_id"`
	ApproverRef       string    `json:"approver_ref"`
	Decision          string    `json:"decision"`
	ApprovalStatus    string    `json:"approval_status"`
	WorkflowNextState string    `json:"workflow_next_state"`
	Comment           string    `json:"comment,omitempty"`
	Completed         bool      `json:"completed"`
	DecidedAt         time.Time `json:"decided_at"`
}

func (r ApplyManualApprovalRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.WorkflowRunID)) {
		errs = append(errs, ValidationError{
			Field:   "workflow_run_id",
			Message: "gecersiz format",
		})
	}

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.StepKey)) {
		errs = append(errs, ValidationError{
			Field:   "step_key",
			Message: "gecersiz format",
		})
	}

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.ApprovalID)) {
		errs = append(errs, ValidationError{
			Field:   "approval_id",
			Message: "gecersiz format",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.ApproverRef)) {
		errs = append(errs, ValidationError{
			Field:   "approver_ref",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedWorkflowApprovalDecisions, strings.TrimSpace(r.Decision)) {
		errs = append(errs, ValidationError{
			Field:   "decision",
			Message: "desteklenmeyen deger",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r ApplyManualApprovalResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.WorkflowRunID)) {
		errs = append(errs, ValidationError{
			Field:   "workflow_run_id",
			Message: "gecersiz format",
		})
	}

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.StepKey)) {
		errs = append(errs, ValidationError{
			Field:   "step_key",
			Message: "gecersiz format",
		})
	}

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.ApprovalID)) {
		errs = append(errs, ValidationError{
			Field:   "approval_id",
			Message: "gecersiz format",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.ApproverRef)) {
		errs = append(errs, ValidationError{
			Field:   "approver_ref",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedWorkflowApprovalDecisions, strings.TrimSpace(r.Decision)) {
		errs = append(errs, ValidationError{
			Field:   "decision",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedWorkflowApprovalStatuses, strings.TrimSpace(r.ApprovalStatus)) {
		errs = append(errs, ValidationError{
			Field:   "approval_status",
			Message: "desteklenmeyen deger",
		})
	}

	if strings.TrimSpace(r.WorkflowNextState) != "" {
		if !workflowStatePattern.MatchString(strings.TrimSpace(r.WorkflowNextState)) || !containsValue(allowedWorkflowStates, strings.TrimSpace(r.WorkflowNextState)) {
			errs = append(errs, ValidationError{
				Field:   "workflow_next_state",
				Message: "desteklenmeyen veya gecersiz format",
			})
		}
	}

	if !r.Completed {
		errs = append(errs, ValidationError{
			Field:   "completed",
			Message: "true olmali",
		})
	}

	if r.DecidedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "decided_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
