package workflow

import (
	"strings"
	"time"
)

type WorkflowDefinitionStep struct {
	StepKey                string `json:"step_key"`
	StepType               string `json:"step_type"`
	NextOnSuccess          string `json:"next_on_success,omitempty"`
	NextOnFailure          string `json:"next_on_failure,omitempty"`
	RequiresManualApproval bool   `json:"requires_manual_approval"`
}

type LoadWorkflowDefinitionRequest struct {
	TenantID      string `json:"tenant_id,omitempty"`
	DefinitionKey string `json:"definition_key"`
	RequestedBy   string `json:"requested_by"`
}

type LoadWorkflowDefinitionResponse struct {
	DefinitionKey string                   `json:"definition_key"`
	Version       int                      `json:"version"`
	InitialState  string                   `json:"initial_state,omitempty"`
	Loaded        bool                     `json:"loaded"`
	Steps         []WorkflowDefinitionStep `json:"steps,omitempty"`
	LoadedAt      time.Time                `json:"loaded_at"`
}

func (s WorkflowDefinitionStep) Validate() error {
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

	if next := strings.TrimSpace(s.NextOnSuccess); next != "" && !workflowKeyPattern.MatchString(next) {
		errs = append(errs, ValidationError{
			Field:   "next_on_success",
			Message: "gecersiz format",
		})
	}

	if next := strings.TrimSpace(s.NextOnFailure); next != "" && !workflowKeyPattern.MatchString(next) {
		errs = append(errs, ValidationError{
			Field:   "next_on_failure",
			Message: "gecersiz format",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r LoadWorkflowDefinitionRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.DefinitionKey)) {
		errs = append(errs, ValidationError{
			Field:   "definition_key",
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

func (r LoadWorkflowDefinitionResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !workflowKeyPattern.MatchString(strings.TrimSpace(r.DefinitionKey)) {
		errs = append(errs, ValidationError{
			Field:   "definition_key",
			Message: "gecersiz format",
		})
	}

	if r.Loaded {
		if r.Version < 1 || r.Version > 1000 {
			errs = append(errs, ValidationError{
				Field:   "version",
				Message: "1-1000 araliginda olmali",
			})
		}

		if !containsValue(allowedWorkflowStates, strings.TrimSpace(r.InitialState)) {
			errs = append(errs, ValidationError{
				Field:   "initial_state",
				Message: "desteklenmeyen deger",
			})
		}

		if len(r.Steps) == 0 {
			errs = append(errs, ValidationError{
				Field:   "steps",
				Message: "en az bir adim olmali",
			})
		}

		for idx, step := range r.Steps {
			if err := step.Validate(); err != nil {
				errs = append(errs, ValidationError{
					Field:   "steps[" + strings.TrimSpace(step.StepKey) + "]",
					Message: err.Error(),
				})
				if idx > 50 {
					break
				}
			}
		}
	}

	if r.LoadedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "loaded_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
