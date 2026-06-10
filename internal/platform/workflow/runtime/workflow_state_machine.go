package workflowruntime

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

const (
	WorkflowStateDraft            = "DRAFT"
	WorkflowStateReady            = "READY"
	WorkflowStateRunning          = "RUNNING"
	WorkflowStateWaitingApproval  = "WAITING_APPROVAL"
	WorkflowStateCompleted        = "COMPLETED"
	WorkflowStateFailed           = "FAILED"
	WorkflowStateCompensating     = "COMPENSATING"
	WorkflowStateCompensated      = "COMPENSATED"
	WorkflowStateCanceled         = "CANCELED"
	WorkflowStateApprovalRejected = "APPROVAL_REJECTED"

	WorkflowDecisionAllow = "ALLOW"
	WorkflowDecisionDeny  = "DENY"

	WorkflowReasonAllowed             = "WORKFLOW_TRANSITION_ALLOWED"
	WorkflowReasonMissingTenant       = "WORKFLOW_MISSING_TENANT"
	WorkflowReasonMissingWorkflowID   = "WORKFLOW_MISSING_WORKFLOW_ID"
	WorkflowReasonCrossTenant         = "WORKFLOW_CROSS_TENANT_DENIED"
	WorkflowReasonStateMismatch       = "WORKFLOW_STATE_MISMATCH"
	WorkflowReasonInvalidTransition   = "WORKFLOW_INVALID_TRANSITION"
	WorkflowReasonTerminalState       = "WORKFLOW_TERMINAL_STATE"
	WorkflowReasonMissingTargetState  = "WORKFLOW_MISSING_TARGET_STATE"
	WorkflowReasonMissingCurrentState = "WORKFLOW_MISSING_CURRENT_STATE"
)

var (
	ErrWorkflowMissingTenant       = errors.New("missing workflow tenant id")
	ErrWorkflowMissingWorkflowID   = errors.New("missing workflow id")
	ErrWorkflowCrossTenant         = errors.New("cross-tenant workflow access denied")
	ErrWorkflowStateMismatch       = errors.New("workflow state mismatch")
	ErrWorkflowInvalidTransition   = errors.New("invalid workflow state transition")
	ErrWorkflowTerminalState       = errors.New("workflow is in terminal state")
	ErrWorkflowMissingTargetState  = errors.New("missing target workflow state")
	ErrWorkflowMissingCurrentState = errors.New("missing current workflow state")
)

type WorkflowTransitionKey struct {
	From string
	To   string
}

type WorkflowStateMachineConfig struct {
	RequireTenant bool
}

func DefaultWorkflowStateMachineConfig() WorkflowStateMachineConfig {
	return WorkflowStateMachineConfig{
		RequireTenant: true,
	}
}

type WorkflowInstance struct {
	TenantID       string                    `json:"tenant_id"`
	WorkflowID     string                    `json:"workflow_id"`
	DefinitionKey  string                    `json:"definition_key,omitempty"`
	CurrentState   string                    `json:"current_state"`
	CurrentStepID  string                    `json:"current_step_id,omitempty"`
	Version        int                       `json:"version"`
	CompletedSteps []string                  `json:"completed_steps,omitempty"`
	AuditEvents    []WorkflowTransitionEvent `json:"audit_events,omitempty"`
	CreatedAt      string                    `json:"created_at"`
	UpdatedAt      string                    `json:"updated_at"`
}

type WorkflowTransitionRequest struct {
	TenantID      string `json:"tenant_id"`
	WorkflowID    string `json:"workflow_id"`
	FromState     string `json:"from_state"`
	ToState       string `json:"to_state"`
	StepID        string `json:"step_id,omitempty"`
	ActorRef      string `json:"actor_ref,omitempty"`
	Reason        string `json:"reason,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type WorkflowTransitionDecision struct {
	Decision   string `json:"decision"`
	Allowed    bool   `json:"allowed"`
	TenantID   string `json:"tenant_id"`
	WorkflowID string `json:"workflow_id"`
	FromState  string `json:"from_state"`
	ToState    string `json:"to_state"`
	StepID     string `json:"step_id,omitempty"`
	Reason     string `json:"reason"`
	CheckedAt  string `json:"checked_at"`
}

type WorkflowTransitionEvent struct {
	TenantID      string `json:"tenant_id"`
	WorkflowID    string `json:"workflow_id"`
	FromState     string `json:"from_state"`
	ToState       string `json:"to_state"`
	StepID        string `json:"step_id,omitempty"`
	ActorRef      string `json:"actor_ref,omitempty"`
	Reason        string `json:"reason"`
	CorrelationID string `json:"correlation_id,omitempty"`
	OccurredAt    string `json:"occurred_at"`
}

type WorkflowStateMachine struct {
	config      WorkflowStateMachineConfig
	transitions map[WorkflowTransitionKey]struct{}
	terminal    map[string]struct{}
}

func NewWorkflowStateMachine(config WorkflowStateMachineConfig) *WorkflowStateMachine {
	transitions := map[WorkflowTransitionKey]struct{}{
		{From: WorkflowStateDraft, To: WorkflowStateReady}:    {},
		{From: WorkflowStateDraft, To: WorkflowStateCanceled}: {},

		{From: WorkflowStateReady, To: WorkflowStateRunning}:  {},
		{From: WorkflowStateReady, To: WorkflowStateCanceled}: {},

		{From: WorkflowStateRunning, To: WorkflowStateWaitingApproval}: {},
		{From: WorkflowStateRunning, To: WorkflowStateCompleted}:       {},
		{From: WorkflowStateRunning, To: WorkflowStateFailed}:          {},
		{From: WorkflowStateRunning, To: WorkflowStateCompensating}:    {},
		{From: WorkflowStateRunning, To: WorkflowStateCanceled}:        {},

		{From: WorkflowStateWaitingApproval, To: WorkflowStateRunning}:          {},
		{From: WorkflowStateWaitingApproval, To: WorkflowStateApprovalRejected}: {},
		{From: WorkflowStateWaitingApproval, To: WorkflowStateCanceled}:         {},

		{From: WorkflowStateApprovalRejected, To: WorkflowStateCompensating}: {},
		{From: WorkflowStateApprovalRejected, To: WorkflowStateCanceled}:     {},

		{From: WorkflowStateFailed, To: WorkflowStateCompensating}: {},
		{From: WorkflowStateFailed, To: WorkflowStateCompensated}:  {},

		{From: WorkflowStateCompensating, To: WorkflowStateCompensated}: {},
		{From: WorkflowStateCompensating, To: WorkflowStateFailed}:      {},
	}

	terminal := map[string]struct{}{
		WorkflowStateCompleted:   {},
		WorkflowStateCompensated: {},
		WorkflowStateCanceled:    {},
	}

	return &WorkflowStateMachine{
		config:      config,
		transitions: transitions,
		terminal:    terminal,
	}
}

func NewWorkflowInstance(tenantID string, workflowID string, definitionKey string) (WorkflowInstance, error) {
	tenantID = strings.TrimSpace(tenantID)
	workflowID = strings.TrimSpace(workflowID)

	if tenantID == "" {
		return WorkflowInstance{}, ErrWorkflowMissingTenant
	}
	if workflowID == "" {
		return WorkflowInstance{}, ErrWorkflowMissingWorkflowID
	}

	now := time.Now().UTC().Format(time.RFC3339Nano)

	return WorkflowInstance{
		TenantID:      tenantID,
		WorkflowID:    workflowID,
		DefinitionKey: strings.TrimSpace(definitionKey),
		CurrentState:  WorkflowStateDraft,
		Version:       1,
		CreatedAt:     now,
		UpdatedAt:     now,
		AuditEvents:   []WorkflowTransitionEvent{},
	}, nil
}

func (m *WorkflowStateMachine) CanTransition(instance WorkflowInstance, req WorkflowTransitionRequest) WorkflowTransitionDecision {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	workflowID := strings.TrimSpace(req.WorkflowID)
	fromState := strings.TrimSpace(req.FromState)
	toState := strings.TrimSpace(req.ToState)

	decision := WorkflowTransitionDecision{
		Decision:   WorkflowDecisionDeny,
		Allowed:    false,
		TenantID:   tenantID,
		WorkflowID: workflowID,
		FromState:  fromState,
		ToState:    toState,
		StepID:     strings.TrimSpace(req.StepID),
		CheckedAt:  now,
	}

	if m.config.RequireTenant && tenantID == "" {
		decision.Reason = WorkflowReasonMissingTenant
		return decision
	}

	if workflowID == "" {
		decision.Reason = WorkflowReasonMissingWorkflowID
		return decision
	}

	if strings.TrimSpace(instance.TenantID) != tenantID {
		decision.Reason = WorkflowReasonCrossTenant
		return decision
	}

	if strings.TrimSpace(instance.WorkflowID) != workflowID {
		decision.Reason = WorkflowReasonMissingWorkflowID
		return decision
	}

	if fromState == "" {
		decision.Reason = WorkflowReasonMissingCurrentState
		return decision
	}

	if toState == "" {
		decision.Reason = WorkflowReasonMissingTargetState
		return decision
	}

	if instance.CurrentState != fromState {
		decision.Reason = WorkflowReasonStateMismatch
		return decision
	}

	if m.IsTerminal(fromState) {
		decision.Reason = WorkflowReasonTerminalState
		return decision
	}

	if _, ok := m.transitions[WorkflowTransitionKey{From: fromState, To: toState}]; !ok {
		decision.Reason = WorkflowReasonInvalidTransition
		return decision
	}

	decision.Decision = WorkflowDecisionAllow
	decision.Allowed = true
	decision.Reason = WorkflowReasonAllowed
	return decision
}

func (m *WorkflowStateMachine) Transition(instance WorkflowInstance, req WorkflowTransitionRequest) (WorkflowInstance, WorkflowTransitionDecision, error) {
	decision := m.CanTransition(instance, req)
	if !decision.Allowed {
		return instance, decision, errorForDecision(decision.Reason)
	}

	now := time.Now().UTC().Format(time.RFC3339Nano)

	next := instance
	next.CurrentState = strings.TrimSpace(req.ToState)
	next.Version = next.Version + 1
	next.UpdatedAt = now

	stepID := strings.TrimSpace(req.StepID)
	if stepID != "" {
		next.CurrentStepID = stepID
		if req.ToState == WorkflowStateCompleted || req.ToState == WorkflowStateWaitingApproval || req.ToState == WorkflowStateRunning {
			next.CompletedSteps = appendUnique(next.CompletedSteps, stepID)
		}
	}

	next.AuditEvents = append(next.AuditEvents, WorkflowTransitionEvent{
		TenantID:      strings.TrimSpace(req.TenantID),
		WorkflowID:    strings.TrimSpace(req.WorkflowID),
		FromState:     strings.TrimSpace(req.FromState),
		ToState:       strings.TrimSpace(req.ToState),
		StepID:        stepID,
		ActorRef:      strings.TrimSpace(req.ActorRef),
		Reason:        WorkflowReasonAllowed,
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		OccurredAt:    now,
	})

	return next, decision, nil
}

func (m *WorkflowStateMachine) IsTerminal(state string) bool {
	_, ok := m.terminal[strings.TrimSpace(state)]
	return ok
}

func (m *WorkflowStateMachine) AllowedTransitions(fromState string) []string {
	fromState = strings.TrimSpace(fromState)

	out := make([]string, 0)
	for key := range m.transitions {
		if key.From == fromState {
			out = append(out, key.To)
		}
	}
	return out
}

func appendUnique(values []string, value string) []string {
	value = strings.TrimSpace(value)
	if value == "" {
		return values
	}

	for _, existing := range values {
		if existing == value {
			return values
		}
	}

	return append(values, value)
}

func errorForDecision(reason string) error {
	switch reason {
	case WorkflowReasonMissingTenant:
		return ErrWorkflowMissingTenant
	case WorkflowReasonMissingWorkflowID:
		return ErrWorkflowMissingWorkflowID
	case WorkflowReasonCrossTenant:
		return ErrWorkflowCrossTenant
	case WorkflowReasonStateMismatch:
		return ErrWorkflowStateMismatch
	case WorkflowReasonInvalidTransition:
		return ErrWorkflowInvalidTransition
	case WorkflowReasonTerminalState:
		return ErrWorkflowTerminalState
	case WorkflowReasonMissingTargetState:
		return ErrWorkflowMissingTargetState
	case WorkflowReasonMissingCurrentState:
		return ErrWorkflowMissingCurrentState
	default:
		return fmt.Errorf("workflow transition denied: %s", reason)
	}
}
