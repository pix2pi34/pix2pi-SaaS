package workflowruntime

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	WorkflowRetryBackoffFixed       = "FIXED"
	WorkflowRetryBackoffLinear      = "LINEAR"
	WorkflowRetryBackoffExponential = "EXPONENTIAL"

	WorkflowRetryActionRetry      = "RETRY"
	WorkflowRetryActionCompensate = "COMPENSATE"
	WorkflowRetryActionFail       = "FAIL"

	WorkflowRetryAttemptStatusScheduled = "SCHEDULED"
	WorkflowRetryAttemptStatusRunning   = "RUNNING"
	WorkflowRetryAttemptStatusSucceeded = "SUCCEEDED"
	WorkflowRetryAttemptStatusFailed    = "FAILED"
	WorkflowRetryAttemptStatusExhausted = "EXHAUSTED"

	WorkflowRetryDecisionAllow = "ALLOW"
	WorkflowRetryDecisionDeny  = "DENY"

	WorkflowRetryReasonAllowed              = "WORKFLOW_RETRY_ALLOWED"
	WorkflowRetryReasonMissingTenant        = "WORKFLOW_RETRY_MISSING_TENANT"
	WorkflowRetryReasonMissingWorkflow      = "WORKFLOW_RETRY_MISSING_WORKFLOW"
	WorkflowRetryReasonMissingStep          = "WORKFLOW_RETRY_MISSING_STEP"
	WorkflowRetryReasonInvalidPolicy        = "WORKFLOW_RETRY_INVALID_POLICY"
	WorkflowRetryReasonRetryScheduled       = "WORKFLOW_RETRY_SCHEDULED"
	WorkflowRetryReasonRetryExhausted       = "WORKFLOW_RETRY_EXHAUSTED"
	WorkflowRetryReasonCompensationRequired = "WORKFLOW_COMPENSATION_REQUIRED"
	WorkflowRetryReasonCrossTenant          = "WORKFLOW_RETRY_CROSS_TENANT_DENIED"

	WorkflowCompensationStatusRequested = "REQUESTED"
	WorkflowCompensationStatusRunning   = "RUNNING"
	WorkflowCompensationStatusCompleted = "COMPLETED"
	WorkflowCompensationStatusFailed    = "FAILED"
	WorkflowCompensationStatusCanceled  = "CANCELED"

	WorkflowCompensationReasonAllowed            = "WORKFLOW_COMPENSATION_ALLOWED"
	WorkflowCompensationReasonMissingTenant      = "WORKFLOW_COMPENSATION_MISSING_TENANT"
	WorkflowCompensationReasonMissingWorkflow    = "WORKFLOW_COMPENSATION_MISSING_WORKFLOW"
	WorkflowCompensationReasonMissingFailedStep  = "WORKFLOW_COMPENSATION_MISSING_FAILED_STEP"
	WorkflowCompensationReasonMissingCompStep    = "WORKFLOW_COMPENSATION_MISSING_COMPENSATION_STEP"
	WorkflowCompensationReasonMissingRecord      = "WORKFLOW_COMPENSATION_MISSING_RECORD"
	WorkflowCompensationReasonCrossTenant        = "WORKFLOW_COMPENSATION_CROSS_TENANT_DENIED"
	WorkflowCompensationReasonAlreadyFinal       = "WORKFLOW_COMPENSATION_ALREADY_FINAL"
	WorkflowCompensationReasonWorkflowNotFailed  = "WORKFLOW_COMPENSATION_WORKFLOW_NOT_FAILED"
	WorkflowCompensationReasonWorkflowNotRunning = "WORKFLOW_COMPENSATION_WORKFLOW_NOT_COMPENSATING"
)

var (
	ErrWorkflowRetryMissingTenant   = errors.New("missing workflow retry tenant id")
	ErrWorkflowRetryMissingWorkflow = errors.New("missing workflow retry workflow id")
	ErrWorkflowRetryMissingStep     = errors.New("missing workflow retry step id")
	ErrWorkflowRetryInvalidPolicy   = errors.New("invalid workflow retry policy")
	ErrWorkflowRetryCrossTenant     = errors.New("cross-tenant workflow retry access denied")

	ErrWorkflowCompensationMissingTenant      = errors.New("missing workflow compensation tenant id")
	ErrWorkflowCompensationMissingWorkflow    = errors.New("missing workflow compensation workflow id")
	ErrWorkflowCompensationMissingFailedStep  = errors.New("missing failed workflow step id")
	ErrWorkflowCompensationMissingStep        = errors.New("missing compensation workflow step id")
	ErrWorkflowCompensationMissingRecord      = errors.New("missing workflow compensation record")
	ErrWorkflowCompensationCrossTenant        = errors.New("cross-tenant workflow compensation access denied")
	ErrWorkflowCompensationAlreadyFinal       = errors.New("workflow compensation already final")
	ErrWorkflowCompensationWorkflowNotFailed  = errors.New("workflow is not failed for compensation")
	ErrWorkflowCompensationWorkflowNotRunning = errors.New("workflow is not compensating")
)

type WorkflowRetryCompensationRuntimeConfig struct {
	RequireTenant bool
}

func DefaultWorkflowRetryCompensationRuntimeConfig() WorkflowRetryCompensationRuntimeConfig {
	return WorkflowRetryCompensationRuntimeConfig{RequireTenant: true}
}

type WorkflowRetryRuntimePolicy struct {
	MaxAttempts     int    `json:"max_attempts"`
	BackoffStrategy string `json:"backoff_strategy"`
	BackoffSeconds  int    `json:"backoff_seconds"`
}

type WorkflowRetryDecisionRequest struct {
	TenantID         string                     `json:"tenant_id"`
	WorkflowID       string                     `json:"workflow_id"`
	StepID           string                     `json:"step_id"`
	CurrentAttempt   int                        `json:"current_attempt"`
	Policy           WorkflowRetryRuntimePolicy `json:"policy"`
	LastErrorCode    string                     `json:"last_error_code,omitempty"`
	LastErrorMessage string                     `json:"last_error_message,omitempty"`
	CorrelationID    string                     `json:"correlation_id,omitempty"`
}

type WorkflowRetryAttempt struct {
	TenantID         string `json:"tenant_id"`
	RetryAttemptID   string `json:"retry_attempt_id"`
	WorkflowID       string `json:"workflow_id"`
	StepID           string `json:"step_id"`
	AttemptNumber    int    `json:"attempt_number"`
	MaxAttempts      int    `json:"max_attempts"`
	BackoffStrategy  string `json:"backoff_strategy"`
	BackoffSeconds   int    `json:"backoff_seconds"`
	Status           string `json:"status"`
	NextRetryAt      string `json:"next_retry_at,omitempty"`
	LastErrorCode    string `json:"last_error_code,omitempty"`
	LastErrorMessage string `json:"last_error_message,omitempty"`
	CorrelationID    string `json:"correlation_id,omitempty"`
	CreatedAt        string `json:"created_at"`
	UpdatedAt        string `json:"updated_at"`
}

type WorkflowRetryDecision struct {
	Decision      string `json:"decision"`
	Allowed       bool   `json:"allowed"`
	TenantID      string `json:"tenant_id"`
	WorkflowID    string `json:"workflow_id"`
	StepID        string `json:"step_id"`
	Action        string `json:"action"`
	Reason        string `json:"reason"`
	AttemptNumber int    `json:"attempt_number"`
	NextRetryAt   string `json:"next_retry_at,omitempty"`
	CheckedAt     string `json:"checked_at"`
}

type WorkflowCompensationRequest struct {
	TenantID           string `json:"tenant_id"`
	WorkflowID         string `json:"workflow_id"`
	FailedStepID       string `json:"failed_step_id"`
	CompensationStepID string `json:"compensation_step_id"`
	Reason             string `json:"reason,omitempty"`
	CorrelationID      string `json:"correlation_id,omitempty"`
}

type WorkflowCompensationRecord struct {
	TenantID           string `json:"tenant_id"`
	CompensationID     string `json:"compensation_id"`
	WorkflowID         string `json:"workflow_id"`
	FailedStepID       string `json:"failed_step_id"`
	CompensationStepID string `json:"compensation_step_id"`
	Status             string `json:"status"`
	Reason             string `json:"reason,omitempty"`
	CorrelationID      string `json:"correlation_id,omitempty"`
	CreatedAt          string `json:"created_at"`
	UpdatedAt          string `json:"updated_at"`
	StartedAt          string `json:"started_at,omitempty"`
	CompletedAt        string `json:"completed_at,omitempty"`
	FailedAt           string `json:"failed_at,omitempty"`
}

type WorkflowCompensationDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	WorkflowID     string `json:"workflow_id"`
	CompensationID string `json:"compensation_id,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type WorkflowRetryCompensationRuntime struct {
	config        WorkflowRetryCompensationRuntimeConfig
	mu            sync.RWMutex
	retryAttempts map[string]WorkflowRetryAttempt
	compensations map[string]WorkflowCompensationRecord
}

func NewWorkflowRetryCompensationRuntime(config WorkflowRetryCompensationRuntimeConfig) *WorkflowRetryCompensationRuntime {
	return &WorkflowRetryCompensationRuntime{
		config:        config,
		retryAttempts: make(map[string]WorkflowRetryAttempt),
		compensations: make(map[string]WorkflowCompensationRecord),
	}
}

func (r *WorkflowRetryCompensationRuntime) DecideFailedStep(req WorkflowRetryDecisionRequest) (WorkflowRetryAttempt, WorkflowRetryDecision, error) {
	now := time.Now().UTC()
	tenantID := strings.TrimSpace(req.TenantID)
	workflowID := strings.TrimSpace(req.WorkflowID)
	stepID := strings.TrimSpace(req.StepID)

	decision := WorkflowRetryDecision{
		Decision:   WorkflowRetryDecisionDeny,
		Allowed:    false,
		TenantID:   tenantID,
		WorkflowID: workflowID,
		StepID:     stepID,
		CheckedAt:  now.Format(time.RFC3339Nano),
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = WorkflowRetryReasonMissingTenant
		return WorkflowRetryAttempt{}, decision, ErrWorkflowRetryMissingTenant
	}
	if workflowID == "" {
		decision.Reason = WorkflowRetryReasonMissingWorkflow
		return WorkflowRetryAttempt{}, decision, ErrWorkflowRetryMissingWorkflow
	}
	if stepID == "" {
		decision.Reason = WorkflowRetryReasonMissingStep
		return WorkflowRetryAttempt{}, decision, ErrWorkflowRetryMissingStep
	}

	policy := normalizeRetryPolicy(req.Policy)
	if !validRetryPolicy(policy) {
		decision.Reason = WorkflowRetryReasonInvalidPolicy
		return WorkflowRetryAttempt{}, decision, ErrWorkflowRetryInvalidPolicy
	}

	nextAttempt := req.CurrentAttempt + 1
	if req.CurrentAttempt < 0 {
		nextAttempt = 1
	}

	attempt := WorkflowRetryAttempt{
		TenantID:         tenantID,
		RetryAttemptID:   NewRetryAttemptID(),
		WorkflowID:       workflowID,
		StepID:           stepID,
		AttemptNumber:    nextAttempt,
		MaxAttempts:      policy.MaxAttempts,
		BackoffStrategy:  policy.BackoffStrategy,
		BackoffSeconds:   policy.BackoffSeconds,
		LastErrorCode:    strings.TrimSpace(req.LastErrorCode),
		LastErrorMessage: strings.TrimSpace(req.LastErrorMessage),
		CorrelationID:    strings.TrimSpace(req.CorrelationID),
		CreatedAt:        now.Format(time.RFC3339Nano),
		UpdatedAt:        now.Format(time.RFC3339Nano),
	}

	if req.CurrentAttempt >= policy.MaxAttempts {
		attempt.Status = WorkflowRetryAttemptStatusExhausted
		decision.Decision = WorkflowRetryDecisionAllow
		decision.Allowed = true
		decision.Action = WorkflowRetryActionCompensate
		decision.Reason = WorkflowRetryReasonCompensationRequired
		decision.AttemptNumber = req.CurrentAttempt
		return attempt, decision, nil
	}

	delaySeconds := CalculateRetryBackoffSeconds(policy, nextAttempt)
	attempt.Status = WorkflowRetryAttemptStatusScheduled
	attempt.NextRetryAt = now.Add(time.Duration(delaySeconds) * time.Second).Format(time.RFC3339Nano)

	r.mu.Lock()
	r.retryAttempts[attempt.RetryAttemptID] = attempt
	r.mu.Unlock()

	decision.Decision = WorkflowRetryDecisionAllow
	decision.Allowed = true
	decision.Action = WorkflowRetryActionRetry
	decision.Reason = WorkflowRetryReasonRetryScheduled
	decision.AttemptNumber = nextAttempt
	decision.NextRetryAt = attempt.NextRetryAt

	return attempt, decision, nil
}

func (r *WorkflowRetryCompensationRuntime) RequestCompensation(req WorkflowCompensationRequest) (WorkflowCompensationRecord, WorkflowCompensationDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	workflowID := strings.TrimSpace(req.WorkflowID)
	failedStepID := strings.TrimSpace(req.FailedStepID)
	compStepID := strings.TrimSpace(req.CompensationStepID)

	decision := WorkflowCompensationDecision{
		Decision:   WorkflowRetryDecisionDeny,
		Allowed:    false,
		TenantID:   tenantID,
		WorkflowID: workflowID,
		CheckedAt:  now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = WorkflowCompensationReasonMissingTenant
		return WorkflowCompensationRecord{}, decision, ErrWorkflowCompensationMissingTenant
	}
	if workflowID == "" {
		decision.Reason = WorkflowCompensationReasonMissingWorkflow
		return WorkflowCompensationRecord{}, decision, ErrWorkflowCompensationMissingWorkflow
	}
	if failedStepID == "" {
		decision.Reason = WorkflowCompensationReasonMissingFailedStep
		return WorkflowCompensationRecord{}, decision, ErrWorkflowCompensationMissingFailedStep
	}
	if compStepID == "" {
		decision.Reason = WorkflowCompensationReasonMissingCompStep
		return WorkflowCompensationRecord{}, decision, ErrWorkflowCompensationMissingStep
	}

	record := WorkflowCompensationRecord{
		TenantID:           tenantID,
		CompensationID:     NewCompensationID(),
		WorkflowID:         workflowID,
		FailedStepID:       failedStepID,
		CompensationStepID: compStepID,
		Status:             WorkflowCompensationStatusRequested,
		Reason:             strings.TrimSpace(req.Reason),
		CorrelationID:      strings.TrimSpace(req.CorrelationID),
		CreatedAt:          now,
		UpdatedAt:          now,
	}

	r.mu.Lock()
	r.compensations[record.CompensationID] = record
	r.mu.Unlock()

	decision.Decision = WorkflowRetryDecisionAllow
	decision.Allowed = true
	decision.CompensationID = record.CompensationID
	decision.Reason = WorkflowCompensationReasonAllowed

	return record, decision, nil
}

func (r *WorkflowRetryCompensationRuntime) StartCompensation(tenantID string, compensationID string) (WorkflowCompensationRecord, WorkflowCompensationDecision, error) {
	return r.changeCompensationStatus(tenantID, compensationID, WorkflowCompensationStatusRunning, WorkflowCompensationReasonAllowed)
}

func (r *WorkflowRetryCompensationRuntime) CompleteCompensation(tenantID string, compensationID string) (WorkflowCompensationRecord, WorkflowCompensationDecision, error) {
	return r.changeCompensationStatus(tenantID, compensationID, WorkflowCompensationStatusCompleted, WorkflowCompensationReasonAllowed)
}

func (r *WorkflowRetryCompensationRuntime) FailCompensation(tenantID string, compensationID string) (WorkflowCompensationRecord, WorkflowCompensationDecision, error) {
	return r.changeCompensationStatus(tenantID, compensationID, WorkflowCompensationStatusFailed, WorkflowCompensationReasonAllowed)
}

func (r *WorkflowRetryCompensationRuntime) GetCompensation(tenantID string, compensationID string) (WorkflowCompensationRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	compensationID = strings.TrimSpace(compensationID)

	if tenantID == "" {
		return WorkflowCompensationRecord{}, ErrWorkflowCompensationMissingTenant
	}
	if compensationID == "" {
		return WorkflowCompensationRecord{}, ErrWorkflowCompensationMissingRecord
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.compensations[compensationID]
	if !ok {
		return WorkflowCompensationRecord{}, ErrWorkflowCompensationMissingRecord
	}
	if record.TenantID != tenantID {
		return WorkflowCompensationRecord{}, ErrWorkflowCompensationCrossTenant
	}

	return record, nil
}

func (r *WorkflowRetryCompensationRuntime) ApplyCompensationStartToWorkflow(machine *WorkflowStateMachine, instance WorkflowInstance, record WorkflowCompensationRecord, actorRef string) (WorkflowInstance, WorkflowTransitionDecision, error) {
	if instance.TenantID != record.TenantID {
		return instance, WorkflowTransitionDecision{
			Decision:   WorkflowDecisionDeny,
			Allowed:    false,
			TenantID:   record.TenantID,
			WorkflowID: record.WorkflowID,
			StepID:     record.CompensationStepID,
			Reason:     WorkflowReasonCrossTenant,
			CheckedAt:  time.Now().UTC().Format(time.RFC3339Nano),
		}, ErrWorkflowCrossTenant
	}

	if instance.CurrentState != WorkflowStateFailed {
		return instance, WorkflowTransitionDecision{
			Decision:   WorkflowDecisionDeny,
			Allowed:    false,
			TenantID:   record.TenantID,
			WorkflowID: record.WorkflowID,
			StepID:     record.CompensationStepID,
			Reason:     WorkflowCompensationReasonWorkflowNotFailed,
			CheckedAt:  time.Now().UTC().Format(time.RFC3339Nano),
		}, ErrWorkflowCompensationWorkflowNotFailed
	}

	return machine.Transition(instance, WorkflowTransitionRequest{
		TenantID:      record.TenantID,
		WorkflowID:    record.WorkflowID,
		FromState:     WorkflowStateFailed,
		ToState:       WorkflowStateCompensating,
		StepID:        record.CompensationStepID,
		ActorRef:      strings.TrimSpace(actorRef),
		Reason:        record.Reason,
		CorrelationID: record.CorrelationID,
	})
}

func (r *WorkflowRetryCompensationRuntime) ApplyCompensationCompleteToWorkflow(machine *WorkflowStateMachine, instance WorkflowInstance, record WorkflowCompensationRecord, actorRef string) (WorkflowInstance, WorkflowTransitionDecision, error) {
	if instance.TenantID != record.TenantID {
		return instance, WorkflowTransitionDecision{
			Decision:   WorkflowDecisionDeny,
			Allowed:    false,
			TenantID:   record.TenantID,
			WorkflowID: record.WorkflowID,
			StepID:     record.CompensationStepID,
			Reason:     WorkflowReasonCrossTenant,
			CheckedAt:  time.Now().UTC().Format(time.RFC3339Nano),
		}, ErrWorkflowCrossTenant
	}

	if instance.CurrentState != WorkflowStateCompensating {
		return instance, WorkflowTransitionDecision{
			Decision:   WorkflowDecisionDeny,
			Allowed:    false,
			TenantID:   record.TenantID,
			WorkflowID: record.WorkflowID,
			StepID:     record.CompensationStepID,
			Reason:     WorkflowCompensationReasonWorkflowNotRunning,
			CheckedAt:  time.Now().UTC().Format(time.RFC3339Nano),
		}, ErrWorkflowCompensationWorkflowNotRunning
	}

	return machine.Transition(instance, WorkflowTransitionRequest{
		TenantID:      record.TenantID,
		WorkflowID:    record.WorkflowID,
		FromState:     WorkflowStateCompensating,
		ToState:       WorkflowStateCompensated,
		StepID:        record.CompensationStepID,
		ActorRef:      strings.TrimSpace(actorRef),
		Reason:        record.Status,
		CorrelationID: record.CorrelationID,
	})
}

func (r *WorkflowRetryCompensationRuntime) changeCompensationStatus(tenantID string, compensationID string, targetStatus string, reason string) (WorkflowCompensationRecord, WorkflowCompensationDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID = strings.TrimSpace(tenantID)
	compensationID = strings.TrimSpace(compensationID)

	decision := WorkflowCompensationDecision{
		Decision:       WorkflowRetryDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		CompensationID: compensationID,
		CheckedAt:      now,
	}

	if tenantID == "" {
		decision.Reason = WorkflowCompensationReasonMissingTenant
		return WorkflowCompensationRecord{}, decision, ErrWorkflowCompensationMissingTenant
	}
	if compensationID == "" {
		decision.Reason = WorkflowCompensationReasonMissingRecord
		return WorkflowCompensationRecord{}, decision, ErrWorkflowCompensationMissingRecord
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	record, ok := r.compensations[compensationID]
	if !ok {
		decision.Reason = WorkflowCompensationReasonMissingRecord
		return WorkflowCompensationRecord{}, decision, ErrWorkflowCompensationMissingRecord
	}
	if record.TenantID != tenantID {
		decision.Reason = WorkflowCompensationReasonCrossTenant
		return WorkflowCompensationRecord{}, decision, ErrWorkflowCompensationCrossTenant
	}
	if isFinalCompensationStatus(record.Status) {
		decision.Reason = WorkflowCompensationReasonAlreadyFinal
		return WorkflowCompensationRecord{}, decision, ErrWorkflowCompensationAlreadyFinal
	}

	record.Status = targetStatus
	record.UpdatedAt = now
	switch targetStatus {
	case WorkflowCompensationStatusRunning:
		record.StartedAt = now
	case WorkflowCompensationStatusCompleted:
		record.CompletedAt = now
	case WorkflowCompensationStatusFailed:
		record.FailedAt = now
	}

	r.compensations[compensationID] = record

	decision.Decision = WorkflowRetryDecisionAllow
	decision.Allowed = true
	decision.WorkflowID = record.WorkflowID
	decision.Reason = reason

	return record, decision, nil
}

func CalculateRetryBackoffSeconds(policy WorkflowRetryRuntimePolicy, attemptNumber int) int {
	policy = normalizeRetryPolicy(policy)

	if attemptNumber <= 0 {
		attemptNumber = 1
	}

	switch policy.BackoffStrategy {
	case WorkflowRetryBackoffFixed:
		return policy.BackoffSeconds
	case WorkflowRetryBackoffLinear:
		return policy.BackoffSeconds * attemptNumber
	case WorkflowRetryBackoffExponential:
		result := policy.BackoffSeconds
		for i := 1; i < attemptNumber; i++ {
			result *= 2
		}
		return result
	default:
		return policy.BackoffSeconds
	}
}

func normalizeRetryPolicy(policy WorkflowRetryRuntimePolicy) WorkflowRetryRuntimePolicy {
	if policy.MaxAttempts <= 0 {
		policy.MaxAttempts = 3
	}
	if strings.TrimSpace(policy.BackoffStrategy) == "" {
		policy.BackoffStrategy = WorkflowRetryBackoffExponential
	}
	if policy.BackoffSeconds < 0 {
		policy.BackoffSeconds = 0
	}
	return policy
}

func validRetryPolicy(policy WorkflowRetryRuntimePolicy) bool {
	if policy.MaxAttempts <= 0 {
		return false
	}
	switch policy.BackoffStrategy {
	case WorkflowRetryBackoffFixed, WorkflowRetryBackoffLinear, WorkflowRetryBackoffExponential:
		return true
	default:
		return false
	}
}

func isFinalCompensationStatus(status string) bool {
	return status == WorkflowCompensationStatusCompleted ||
		status == WorkflowCompensationStatusFailed ||
		status == WorkflowCompensationStatusCanceled
}

func NewRetryAttemptID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "retry_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "retry_" + hex.EncodeToString(raw[:])
}

func NewCompensationID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "comp_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "comp_" + hex.EncodeToString(raw[:])
}
