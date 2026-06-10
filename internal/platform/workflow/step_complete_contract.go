package workflow

import (
	"strings"
	"time"
)

var allowedWorkflowStepCompletionStatuses = map[string]struct{}{
	"completed": {},
	"failed":    {},
	"cancelled": {},
}

type CompleteWorkflowStepRequest struct {
	TenantID       string `json:"tenant_id,omitempty"`
	WorkflowRunID  string `json:"workflow_run_id"`
	StepKey        string `json:"step_key"`
	WorkerID       string `json:"worker_id"`
	Status         string `json:"status"`
	AttemptNo      int    `json:"attempt_no"`
	OutputRef      string `json:"output_ref,omitempty"`
	ErrorCode      string `json:"error_code,omitempty"`
	CompletionNote string `json:"completion_note,omitempty"`
}

type CompleteWorkflowStepResponse struct {
	WorkflowRunID  string    `json:"workflow_run_id"`
	StepKey        string    `json:"step_key"`
	WorkerID       string    `json:"worker_id"`
	Status         string    `json:"status"`
	AttemptNo      int       `json:"attempt_no"`
	OutputRef      string    `json:"output_ref,omitempty"`
	ErrorCode      string    `json:"error_code,omitempty"`
	CompletionNote string    `json:"completion_note,omitempty"`
	LeaseReleased  bool      `json:"lease_released"`
	CompletedAt    time.Time `json:"completed_at"`
}

func (r CompleteWorkflowStepRequest) Validate() error {
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

	if !actorRefPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
		errs = append(errs, ValidationError{
			Field:   "worker_id",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedWorkflowStepCompletionStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.AttemptNo < 1 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "1-100 araliginda olmali",
		})
	}

	if strings.TrimSpace(r.OutputRef) != "" && !workflowKeyPattern.MatchString(strings.TrimSpace(r.OutputRef)) {
		errs = append(errs, ValidationError{
			Field:   "output_ref",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.ErrorCode) != "" && !workflowKeyPattern.MatchString(strings.TrimSpace(r.ErrorCode)) {
		errs = append(errs, ValidationError{
			Field:   "error_code",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.Status) == "failed" && strings.TrimSpace(r.ErrorCode) == "" {
		errs = append(errs, ValidationError{
			Field:   "error_code",
			Message: "failed durumunda zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r CompleteWorkflowStepResponse) Validate() error {
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

	if !actorRefPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
		errs = append(errs, ValidationError{
			Field:   "worker_id",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedWorkflowStepCompletionStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.AttemptNo < 1 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "1-100 araliginda olmali",
		})
	}

	if strings.TrimSpace(r.OutputRef) != "" && !workflowKeyPattern.MatchString(strings.TrimSpace(r.OutputRef)) {
		errs = append(errs, ValidationError{
			Field:   "output_ref",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.ErrorCode) != "" && !workflowKeyPattern.MatchString(strings.TrimSpace(r.ErrorCode)) {
		errs = append(errs, ValidationError{
			Field:   "error_code",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.Status) == "failed" && strings.TrimSpace(r.ErrorCode) == "" {
		errs = append(errs, ValidationError{
			Field:   "error_code",
			Message: "failed durumunda zorunlu alan",
		})
	}

	if !r.LeaseReleased {
		errs = append(errs, ValidationError{
			Field:   "lease_released",
			Message: "true olmali",
		})
	}

	if r.CompletedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "completed_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
