package workflow

import (
	"regexp"
	"strings"
	"time"
)

var (
	workflowKeyPattern    = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
	workflowStatePattern  = regexp.MustCompile(`^[a-z][a-z0-9_]*$`)
	workflowActionPattern = regexp.MustCompile(`^[a-z][a-z0-9_]*$`)
	actorRefPattern       = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
)

var allowedWorkflowStates = map[string]struct{}{
	"draft":            {},
	"pending":          {},
	"in_progress":      {},
	"waiting_approval": {},
	"approved":         {},
	"rejected":         {},
	"completed":        {},
	"cancelled":        {},
	"failed":           {},
}

var allowedWorkflowActions = map[string]struct{}{
	"submit":           {},
	"start":            {},
	"request_approval": {},
	"approve":          {},
	"reject":           {},
	"complete":         {},
	"cancel":           {},
	"fail":             {},
	"retry":            {},
}

type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

type ValidationErrors []ValidationError

func (v ValidationErrors) Error() string {
	if len(v) == 0 {
		return "validation failed"
	}

	parts := make([]string, 0, len(v))
	for _, item := range v {
		parts = append(parts, item.Field+": "+item.Message)
	}

	return strings.Join(parts, ", ")
}

func containsValue(values map[string]struct{}, value string) bool {
	_, ok := values[value]
	return ok
}

type ApplyWorkflowTransitionRequest struct {
	TenantID      string         `json:"tenant_id,omitempty"`
	WorkflowRunID string         `json:"workflow_run_id"`
	DefinitionKey string         `json:"definition_key"`
	CurrentState  string         `json:"current_state"`
	Action        string         `json:"action"`
	RequestedBy   string         `json:"requested_by"`
	ContextVars   map[string]any `json:"context_vars,omitempty"`
}

type ApplyWorkflowTransitionResponse struct {
	WorkflowRunID      string         `json:"workflow_run_id"`
	DefinitionKey      string         `json:"definition_key"`
	PreviousState      string         `json:"previous_state"`
	Action             string         `json:"action"`
	NextState          string         `json:"next_state"`
	TransitionAllowed  bool           `json:"transition_allowed"`
	Reason             string         `json:"reason,omitempty"`
	ContextVars        map[string]any `json:"context_vars,omitempty"`
	TransitionedAt     time.Time      `json:"transitioned_at"`
}

func (r ApplyWorkflowTransitionRequest) Validate() error {
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

	if !workflowStatePattern.MatchString(strings.TrimSpace(r.CurrentState)) || !containsValue(allowedWorkflowStates, strings.TrimSpace(r.CurrentState)) {
		errs = append(errs, ValidationError{
			Field:   "current_state",
			Message: "desteklenmeyen veya gecersiz format",
		})
	}

	if !workflowActionPattern.MatchString(strings.TrimSpace(r.Action)) || !containsValue(allowedWorkflowActions, strings.TrimSpace(r.Action)) {
		errs = append(errs, ValidationError{
			Field:   "action",
			Message: "desteklenmeyen veya gecersiz format",
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

func (r ApplyWorkflowTransitionResponse) Validate() error {
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

	if !workflowStatePattern.MatchString(strings.TrimSpace(r.PreviousState)) || !containsValue(allowedWorkflowStates, strings.TrimSpace(r.PreviousState)) {
		errs = append(errs, ValidationError{
			Field:   "previous_state",
			Message: "desteklenmeyen veya gecersiz format",
		})
	}

	if !workflowActionPattern.MatchString(strings.TrimSpace(r.Action)) || !containsValue(allowedWorkflowActions, strings.TrimSpace(r.Action)) {
		errs = append(errs, ValidationError{
			Field:   "action",
			Message: "desteklenmeyen veya gecersiz format",
		})
	}

	if r.TransitionAllowed {
		if !workflowStatePattern.MatchString(strings.TrimSpace(r.NextState)) || !containsValue(allowedWorkflowStates, strings.TrimSpace(r.NextState)) {
			errs = append(errs, ValidationError{
				Field:   "next_state",
				Message: "desteklenmeyen veya gecersiz format",
			})
		}
	}

	if r.TransitionedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "transitioned_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
