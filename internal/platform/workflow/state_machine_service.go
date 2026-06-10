package workflow

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ApplyWorkflowTransitionCommand struct {
	TenantID      string
	WorkflowRunID string
	DefinitionKey string
	CurrentState  string
	Action        string
	RequestedBy   string
	ContextVars   map[string]any
}

type ApplyWorkflowTransitionResult struct {
	WorkflowRunID     string
	DefinitionKey     string
	PreviousState     string
	Action            string
	NextState         string
	TransitionAllowed bool
	Reason            string
	ContextVars       map[string]any
}

type WorkflowStateMachineStore interface {
	ApplyTransition(ctx context.Context, cmd ApplyWorkflowTransitionCommand) (ApplyWorkflowTransitionResult, error)
}

type ApplyWorkflowTransitionUsecase struct {
	store WorkflowStateMachineStore
	nowFn func() time.Time
}

func NewApplyWorkflowTransitionUsecase(store WorkflowStateMachineStore) *ApplyWorkflowTransitionUsecase {
	return &ApplyWorkflowTransitionUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ApplyWorkflowTransitionUsecase) Apply(ctx context.Context, req ApplyWorkflowTransitionRequest) (ApplyWorkflowTransitionResponse, error) {
	if u == nil || u.store == nil {
		return ApplyWorkflowTransitionResponse{}, errors.New("workflow state machine usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.WorkflowRunID = strings.TrimSpace(req.WorkflowRunID)
	req.DefinitionKey = strings.TrimSpace(req.DefinitionKey)
	req.CurrentState = strings.TrimSpace(req.CurrentState)
	req.Action = strings.TrimSpace(req.Action)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return ApplyWorkflowTransitionResponse{}, err
	}

	result, err := u.store.ApplyTransition(ctx, ApplyWorkflowTransitionCommand{
		TenantID:      req.TenantID,
		WorkflowRunID: req.WorkflowRunID,
		DefinitionKey: req.DefinitionKey,
		CurrentState:  req.CurrentState,
		Action:        req.Action,
		RequestedBy:   req.RequestedBy,
		ContextVars:   cloneMap(req.ContextVars),
	})
	if err != nil {
		return ApplyWorkflowTransitionResponse{}, err
	}

	transitionAllowed := result.TransitionAllowed
	nextState := strings.TrimSpace(result.NextState)
	if nextState == "" {
		nextState, transitionAllowed = resolveFallbackWorkflowTransition(req.CurrentState, req.Action)
	}

	resp := ApplyWorkflowTransitionResponse{
		WorkflowRunID:     firstNonEmpty(strings.TrimSpace(result.WorkflowRunID), req.WorkflowRunID),
		DefinitionKey:     firstNonEmpty(strings.TrimSpace(result.DefinitionKey), req.DefinitionKey),
		PreviousState:     firstNonEmpty(strings.TrimSpace(result.PreviousState), req.CurrentState),
		Action:            firstNonEmpty(strings.TrimSpace(result.Action), req.Action),
		NextState:         nextState,
		TransitionAllowed: transitionAllowed,
		Reason:            strings.TrimSpace(result.Reason),
		ContextVars:       cloneMap(nonNilMap(result.ContextVars, req.ContextVars)),
		TransitionedAt:    u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return ApplyWorkflowTransitionResponse{}, err
	}

	return resp, nil
}

func resolveFallbackWorkflowTransition(currentState, action string) (string, bool) {
	currentState = strings.TrimSpace(currentState)
	action = strings.TrimSpace(action)

	switch {
	case currentState == "draft" && action == "submit":
		return "pending", true
	case currentState == "pending" && action == "start":
		return "in_progress", true
	case currentState == "in_progress" && action == "request_approval":
		return "waiting_approval", true
	case currentState == "waiting_approval" && action == "approve":
		return "approved", true
	case currentState == "waiting_approval" && action == "reject":
		return "rejected", true
	case currentState == "approved" && action == "complete":
		return "completed", true
	case currentState == "in_progress" && action == "fail":
		return "failed", true
	case (currentState == "pending" || currentState == "in_progress" || currentState == "waiting_approval") && action == "cancel":
		return "cancelled", true
	case currentState == "failed" && action == "retry":
		return "pending", true
	default:
		return "", false
	}
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}

func cloneMap(in map[string]any) map[string]any {
	if len(in) == 0 {
		return map[string]any{}
	}

	out := make(map[string]any, len(in))
	for k, v := range in {
		out[k] = v
	}

	return out
}

func nonNilMap(primary map[string]any, fallback map[string]any) map[string]any {
	if len(primary) > 0 {
		return primary
	}
	return fallback
}
