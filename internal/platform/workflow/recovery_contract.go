package workflow

import (
	"strings"
	"time"
)

var allowedWorkflowRecoveryActionTypes = map[string]struct{}{
	"retry":      {},
	"compensate": {},
}

var allowedWorkflowRecoveryStepStatuses = map[string]struct{}{
	"pending":      {},
	"compensating": {},
	"failed":       {},
}

type ApplyWorkflowRecoveryRequest struct {
	TenantID        string `json:"tenant_id,omitempty"`
	WorkflowRunID   string `json:"workflow_run_id"`
	StepKey         string `json:"step_key"`
	ActionType      string `json:"action_type"`
	RequestedBy     string `json:"requested_by"`
	Reason          string `json:"reason,omitempty"`
	ResetAttempts   bool   `json:"reset_attempts"`
	CompensationRef string `json:"compensation_ref,omitempty"`
}

type ApplyWorkflowRecoveryResponse struct {
	WorkflowRunID   string    `json:"workflow_run_id"`
	StepKey         string    `json:"step_key"`
	ActionType      string    `json:"action_type"`
	StepStatus      string    `json:"step_status"`
	WorkflowState   string    `json:"workflow_state"`
	AttemptNo       int       `json:"attempt_no"`
	CompensationRef string    `json:"compensation_ref,omitempty"`
	LeaseReleased   bool      `json:"lease_released"`
	RequestedBy     string    `json:"requested_by"`
	Reason          string    `json:"reason,omitempty"`
	RequestedAt     time.Time `json:"requested_at"`
}

func (r ApplyWorkflowRecoveryRequest) Validate() error {
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

	if !containsValue(allowedWorkflowRecoveryActionTypes, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{
			Field:   "action_type",
			Message: "desteklenmeyen deger",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if ref := strings.TrimSpace(r.CompensationRef); ref != "" && !workflowKeyPattern.MatchString(ref) {
		errs = append(errs, ValidationError{
			Field:   "compensation_ref",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.ActionType) == "compensate" && strings.TrimSpace(r.CompensationRef) == "" {
		errs = append(errs, ValidationError{
			Field:   "compensation_ref",
			Message: "compensate icin zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r ApplyWorkflowRecoveryResponse) Validate() error {
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

	if !containsValue(allowedWorkflowRecoveryActionTypes, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{
			Field:   "action_type",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedWorkflowRecoveryStepStatuses, strings.TrimSpace(r.StepStatus)) {
		errs = append(errs, ValidationError{
			Field:   "step_status",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedWorkflowStates, strings.TrimSpace(r.WorkflowState)) {
		errs = append(errs, ValidationError{
			Field:   "workflow_state",
			Message: "desteklenmeyen deger",
		})
	}

	if r.AttemptNo < 0 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "0-100 araliginda olmali",
		})
	}

	if ref := strings.TrimSpace(r.CompensationRef); ref != "" && !workflowKeyPattern.MatchString(ref) {
		errs = append(errs, ValidationError{
			Field:   "compensation_ref",
			Message: "gecersiz format",
		})
	}

	if !r.LeaseReleased {
		errs = append(errs, ValidationError{
			Field:   "lease_released",
			Message: "true olmali",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.ActionType) == "compensate" && strings.TrimSpace(r.CompensationRef) == "" {
		errs = append(errs, ValidationError{
			Field:   "compensation_ref",
			Message: "compensate icin zorunlu alan",
		})
	}

	if r.RequestedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "requested_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
