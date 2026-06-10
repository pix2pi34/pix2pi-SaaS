package workflow

import (
	"strings"
	"time"
)

var allowedWorkflowStepTypes = map[string]struct{}{
	"task":     {},
	"approval": {},
	"service":  {},
	"timer":    {},
}

var allowedWorkflowStepClaimStatuses = map[string]struct{}{
	"in_progress": {},
}

type ClaimWorkflowStepRequest struct {
	TenantID      string `json:"tenant_id,omitempty"`
	WorkflowRunID string `json:"workflow_run_id"`
	StepKey       string `json:"step_key"`
	WorkerID      string `json:"worker_id"`
	LeaseSeconds  int    `json:"lease_seconds"`
}

type ClaimWorkflowStepResponse struct {
	Claimed        bool       `json:"claimed"`
	WorkflowRunID  string     `json:"workflow_run_id,omitempty"`
	StepKey        string     `json:"step_key,omitempty"`
	StepType       string     `json:"step_type,omitempty"`
	Status         string     `json:"status,omitempty"`
	AttemptNo      int        `json:"attempt_no,omitempty"`
	WorkerID       string     `json:"worker_id,omitempty"`
	LeaseExpiresAt *time.Time `json:"lease_expires_at,omitempty"`
	ClaimedAt      time.Time  `json:"claimed_at"`
}

func (r ClaimWorkflowStepRequest) Validate() error {
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

	if r.LeaseSeconds < 5 || r.LeaseSeconds > 3600 {
		errs = append(errs, ValidationError{
			Field:   "lease_seconds",
			Message: "5-3600 araliginda olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r ClaimWorkflowStepResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if r.ClaimedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "claimed_at",
			Message: "zorunlu alan",
		})
	}

	if r.Claimed {
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

		if !containsValue(allowedWorkflowStepTypes, strings.TrimSpace(r.StepType)) {
			errs = append(errs, ValidationError{
				Field:   "step_type",
				Message: "desteklenmeyen deger",
			})
		}

		if !containsValue(allowedWorkflowStepClaimStatuses, strings.TrimSpace(r.Status)) {
			errs = append(errs, ValidationError{
				Field:   "status",
				Message: "in_progress olmali",
			})
		}

		if r.AttemptNo < 1 || r.AttemptNo > 100 {
			errs = append(errs, ValidationError{
				Field:   "attempt_no",
				Message: "1-100 araliginda olmali",
			})
		}

		if !actorRefPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
			errs = append(errs, ValidationError{
				Field:   "worker_id",
				Message: "gecersiz format",
			})
		}

		if r.LeaseExpiresAt == nil || r.LeaseExpiresAt.IsZero() {
			errs = append(errs, ValidationError{
				Field:   "lease_expires_at",
				Message: "zorunlu alan",
			})
		}
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
