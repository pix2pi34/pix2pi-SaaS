package workflow

import (
	"strings"
	"time"
)

var allowedWorkflowHealthStatuses = map[string]struct{}{
	"healthy":  {},
	"degraded": {},
	"stalled":  {},
	"failed":   {},
}

type WorkflowStepObservation struct {
	StepKey         string     `json:"step_key"`
	StepType        string     `json:"step_type"`
	Status          string     `json:"status"`
	AttemptNo       int        `json:"attempt_no"`
	WorkerID        string     `json:"worker_id,omitempty"`
	LeaseExpiresAt  *time.Time `json:"lease_expires_at,omitempty"`
	LastErrorCode   string     `json:"last_error_code,omitempty"`
}

type WorkflowObservabilitySummary struct {
	TotalSteps            int `json:"total_steps"`
	PendingSteps          int `json:"pending_steps"`
	InProgressSteps       int `json:"in_progress_steps"`
	CompletedSteps        int `json:"completed_steps"`
	FailedSteps           int `json:"failed_steps"`
	PendingApprovals      int `json:"pending_approvals"`
	ActiveLeaseCount      int `json:"active_lease_count"`
	ExpiredLeaseCount     int `json:"expired_lease_count"`
}

type LoadWorkflowObservabilityRequest struct {
	TenantID      string `json:"tenant_id,omitempty"`
	WorkflowRunID string `json:"workflow_run_id"`
	RequestedBy   string `json:"requested_by"`
}

type LoadWorkflowObservabilityResponse struct {
	WorkflowRunID string                     `json:"workflow_run_id"`
	DefinitionKey string                     `json:"definition_key"`
	WorkflowState string                     `json:"workflow_state"`
	HealthStatus  string                     `json:"health_status"`
	Summary       WorkflowObservabilitySummary `json:"summary"`
	Steps         []WorkflowStepObservation  `json:"steps,omitempty"`
	ObservedAt    time.Time                  `json:"observed_at"`
}

func (s WorkflowStepObservation) Validate() error {
	errs := make(ValidationErrors, 0)

	if !workflowKeyPattern.MatchString(strings.TrimSpace(s.StepKey)) {
		errs = append(errs, ValidationError{
			Field:   "step_key",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedWorkflowStepTypes, strings.TrimSpace(s.StepType)) {
		errs = append(errs, ValidationError{
			Field:   "step_type",
			Message: "desteklenmeyen deger",
		})
	}

	stepStatus := strings.TrimSpace(s.Status)
	if stepStatus == "" || !workflowStatePattern.MatchString(stepStatus) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "gecersiz format",
		})
	}

	if s.AttemptNo < 0 || s.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "0-100 araliginda olmali",
		})
	}

	if workerID := strings.TrimSpace(s.WorkerID); workerID != "" && !actorRefPattern.MatchString(workerID) {
		errs = append(errs, ValidationError{
			Field:   "worker_id",
			Message: "gecersiz format",
		})
	}

	if errCode := strings.TrimSpace(s.LastErrorCode); errCode != "" && !workflowKeyPattern.MatchString(errCode) {
		errs = append(errs, ValidationError{
			Field:   "last_error_code",
			Message: "gecersiz format",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (s WorkflowObservabilitySummary) Validate() error {
	errs := make(ValidationErrors, 0)

	if s.TotalSteps < 0 || s.TotalSteps > 10000 {
		errs = append(errs, ValidationError{
			Field:   "total_steps",
			Message: "0-10000 araliginda olmali",
		})
	}

	if s.PendingSteps < 0 || s.PendingSteps > 10000 {
		errs = append(errs, ValidationError{
			Field:   "pending_steps",
			Message: "0-10000 araliginda olmali",
		})
	}

	if s.InProgressSteps < 0 || s.InProgressSteps > 10000 {
		errs = append(errs, ValidationError{
			Field:   "in_progress_steps",
			Message: "0-10000 araliginda olmali",
		})
	}

	if s.CompletedSteps < 0 || s.CompletedSteps > 10000 {
		errs = append(errs, ValidationError{
			Field:   "completed_steps",
			Message: "0-10000 araliginda olmali",
		})
	}

	if s.FailedSteps < 0 || s.FailedSteps > 10000 {
		errs = append(errs, ValidationError{
			Field:   "failed_steps",
			Message: "0-10000 araliginda olmali",
		})
	}

	if s.PendingApprovals < 0 || s.PendingApprovals > 10000 {
		errs = append(errs, ValidationError{
			Field:   "pending_approvals",
			Message: "0-10000 araliginda olmali",
		})
	}

	if s.ActiveLeaseCount < 0 || s.ActiveLeaseCount > 10000 {
		errs = append(errs, ValidationError{
			Field:   "active_lease_count",
			Message: "0-10000 araliginda olmali",
		})
	}

	if s.ExpiredLeaseCount < 0 || s.ExpiredLeaseCount > 10000 {
		errs = append(errs, ValidationError{
			Field:   "expired_lease_count",
			Message: "0-10000 araliginda olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r LoadWorkflowObservabilityRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.WorkflowRunID)) {
		errs = append(errs, ValidationError{
			Field:   "workflow_run_id",
			Message: "gecersiz format",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r LoadWorkflowObservabilityResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.WorkflowRunID)) {
		errs = append(errs, ValidationError{
			Field:   "workflow_run_id",
			Message: "gecersiz format",
		})
	}

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.DefinitionKey)) {
		errs = append(errs, ValidationError{
			Field:   "definition_key",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedWorkflowStates, strings.TrimSpace(r.WorkflowState)) {
		errs = append(errs, ValidationError{
			Field:   "workflow_state",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedWorkflowHealthStatuses, strings.TrimSpace(r.HealthStatus)) {
		errs = append(errs, ValidationError{
			Field:   "health_status",
			Message: "desteklenmeyen deger",
		})
	}

	if err := r.Summary.Validate(); err != nil {
		errs = append(errs, ValidationError{
			Field:   "summary",
			Message: err.Error(),
		})
	}

	for _, step := range r.Steps {
		if err := step.Validate(); err != nil {
			errs = append(errs, ValidationError{
				Field:   "steps[" + strings.TrimSpace(step.StepKey) + "]",
				Message: err.Error(),
			})
		}
	}

	if r.ObservedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "observed_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
