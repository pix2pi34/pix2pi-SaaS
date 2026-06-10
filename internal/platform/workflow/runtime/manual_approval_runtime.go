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
	ApprovalRequestStatusPending  = "PENDING"
	ApprovalRequestStatusApproved = "APPROVED"
	ApprovalRequestStatusRejected = "REJECTED"
	ApprovalRequestStatusCanceled = "CANCELED"

	ApprovalDecisionApprove = "APPROVE"
	ApprovalDecisionReject  = "REJECT"

	ApprovalRuntimeDecisionAllow = "ALLOW"
	ApprovalRuntimeDecisionDeny  = "DENY"

	ApprovalReasonAllowed            = "APPROVAL_ALLOWED"
	ApprovalReasonMissingTenant      = "APPROVAL_MISSING_TENANT"
	ApprovalReasonMissingWorkflow    = "APPROVAL_MISSING_WORKFLOW"
	ApprovalReasonMissingStep        = "APPROVAL_MISSING_STEP"
	ApprovalReasonMissingApproval    = "APPROVAL_MISSING_APPROVAL"
	ApprovalReasonCrossTenant        = "APPROVAL_CROSS_TENANT_DENIED"
	ApprovalReasonMissingApprover    = "APPROVAL_MISSING_APPROVER"
	ApprovalReasonRoleDenied         = "APPROVAL_ROLE_DENIED"
	ApprovalReasonAlreadyFinal       = "APPROVAL_ALREADY_FINAL"
	ApprovalReasonInvalidDecision    = "APPROVAL_INVALID_DECISION"
	ApprovalReasonWorkflowNotWaiting = "APPROVAL_WORKFLOW_NOT_WAITING"
)

var (
	ErrApprovalMissingTenant      = errors.New("missing approval tenant id")
	ErrApprovalMissingWorkflow    = errors.New("missing approval workflow id")
	ErrApprovalMissingStep        = errors.New("missing approval step id")
	ErrApprovalMissingApproval    = errors.New("missing approval request id")
	ErrApprovalCrossTenant        = errors.New("cross-tenant approval access denied")
	ErrApprovalMissingApprover    = errors.New("missing approver ref")
	ErrApprovalRoleDenied         = errors.New("approval role denied")
	ErrApprovalAlreadyFinal       = errors.New("approval already final")
	ErrApprovalInvalidDecision    = errors.New("invalid approval decision")
	ErrApprovalWorkflowNotWaiting = errors.New("workflow is not waiting approval")
)

type ManualApprovalRuntimeConfig struct {
	RequireTenant bool
}

func DefaultManualApprovalRuntimeConfig() ManualApprovalRuntimeConfig {
	return ManualApprovalRuntimeConfig{
		RequireTenant: true,
	}
}

type ManualApprovalRequest struct {
	TenantID      string                   `json:"tenant_id"`
	ApprovalID    string                   `json:"approval_id"`
	WorkflowID    string                   `json:"workflow_id"`
	StepID        string                   `json:"step_id"`
	RequiredRole  string                   `json:"required_role"`
	RequiredCount int                      `json:"required_count"`
	Status        string                   `json:"status"`
	RequestedBy   string                   `json:"requested_by,omitempty"`
	CreatedAt     string                   `json:"created_at"`
	UpdatedAt     string                   `json:"updated_at"`
	Decisions     []ManualApprovalDecision `json:"decisions,omitempty"`
	CorrelationID string                   `json:"correlation_id,omitempty"`
}

type ManualApprovalCreateRequest struct {
	TenantID      string
	WorkflowID    string
	StepID        string
	RequiredRole  string
	RequiredCount int
	RequestedBy   string
	CorrelationID string
}

type ManualApprovalDecisionRequest struct {
	TenantID      string
	ApprovalID    string
	WorkflowID    string
	StepID        string
	ApproverRef   string
	ApproverRoles []string
	Decision      string
	Comment       string
	CorrelationID string
}

type ManualApprovalDecision struct {
	TenantID      string   `json:"tenant_id"`
	ApprovalID    string   `json:"approval_id"`
	WorkflowID    string   `json:"workflow_id"`
	StepID        string   `json:"step_id"`
	ApproverRef   string   `json:"approver_ref"`
	ApproverRoles []string `json:"approver_roles,omitempty"`
	Decision      string   `json:"decision"`
	Comment       string   `json:"comment,omitempty"`
	DecidedAt     string   `json:"decided_at"`
	CorrelationID string   `json:"correlation_id,omitempty"`
}

type ManualApprovalRuntimeDecision struct {
	Decision   string `json:"decision"`
	Allowed    bool   `json:"allowed"`
	TenantID   string `json:"tenant_id"`
	ApprovalID string `json:"approval_id,omitempty"`
	WorkflowID string `json:"workflow_id,omitempty"`
	StepID     string `json:"step_id,omitempty"`
	Reason     string `json:"reason"`
	CheckedAt  string `json:"checked_at"`
}

type ManualApprovalRuntime struct {
	config   ManualApprovalRuntimeConfig
	mu       sync.RWMutex
	requests map[string]ManualApprovalRequest
}

func NewManualApprovalRuntime(config ManualApprovalRuntimeConfig) *ManualApprovalRuntime {
	return &ManualApprovalRuntime{
		config:   config,
		requests: make(map[string]ManualApprovalRequest),
	}
}

func (r *ManualApprovalRuntime) CreateApprovalRequest(req ManualApprovalCreateRequest) (ManualApprovalRequest, ManualApprovalRuntimeDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	workflowID := strings.TrimSpace(req.WorkflowID)
	stepID := strings.TrimSpace(req.StepID)

	decision := ManualApprovalRuntimeDecision{
		Decision:   ApprovalRuntimeDecisionDeny,
		Allowed:    false,
		TenantID:   tenantID,
		WorkflowID: workflowID,
		StepID:     stepID,
		CheckedAt:  now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = ApprovalReasonMissingTenant
		return ManualApprovalRequest{}, decision, ErrApprovalMissingTenant
	}

	if workflowID == "" {
		decision.Reason = ApprovalReasonMissingWorkflow
		return ManualApprovalRequest{}, decision, ErrApprovalMissingWorkflow
	}

	if stepID == "" {
		decision.Reason = ApprovalReasonMissingStep
		return ManualApprovalRequest{}, decision, ErrApprovalMissingStep
	}

	requiredCount := req.RequiredCount
	if requiredCount <= 0 {
		requiredCount = 1
	}

	approvalID := NewApprovalID()
	approval := ManualApprovalRequest{
		TenantID:      tenantID,
		ApprovalID:    approvalID,
		WorkflowID:    workflowID,
		StepID:        stepID,
		RequiredRole:  strings.TrimSpace(req.RequiredRole),
		RequiredCount: requiredCount,
		Status:        ApprovalRequestStatusPending,
		RequestedBy:   strings.TrimSpace(req.RequestedBy),
		CreatedAt:     now,
		UpdatedAt:     now,
		Decisions:     []ManualApprovalDecision{},
		CorrelationID: strings.TrimSpace(req.CorrelationID),
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	r.requests[approvalID] = approval

	decision.Decision = ApprovalRuntimeDecisionAllow
	decision.Allowed = true
	decision.ApprovalID = approvalID
	decision.Reason = ApprovalReasonAllowed

	return approval, decision, nil
}

func (r *ManualApprovalRuntime) Decide(req ManualApprovalDecisionRequest) (ManualApprovalRequest, ManualApprovalRuntimeDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	approvalID := strings.TrimSpace(req.ApprovalID)
	workflowID := strings.TrimSpace(req.WorkflowID)
	stepID := strings.TrimSpace(req.StepID)

	decision := ManualApprovalRuntimeDecision{
		Decision:   ApprovalRuntimeDecisionDeny,
		Allowed:    false,
		TenantID:   tenantID,
		ApprovalID: approvalID,
		WorkflowID: workflowID,
		StepID:     stepID,
		CheckedAt:  now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = ApprovalReasonMissingTenant
		return ManualApprovalRequest{}, decision, ErrApprovalMissingTenant
	}

	if approvalID == "" {
		decision.Reason = ApprovalReasonMissingApproval
		return ManualApprovalRequest{}, decision, ErrApprovalMissingApproval
	}

	if strings.TrimSpace(req.ApproverRef) == "" {
		decision.Reason = ApprovalReasonMissingApprover
		return ManualApprovalRequest{}, decision, ErrApprovalMissingApprover
	}

	if req.Decision != ApprovalDecisionApprove && req.Decision != ApprovalDecisionReject {
		decision.Reason = ApprovalReasonInvalidDecision
		return ManualApprovalRequest{}, decision, ErrApprovalInvalidDecision
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	approval, ok := r.requests[approvalID]
	if !ok {
		decision.Reason = ApprovalReasonMissingApproval
		return ManualApprovalRequest{}, decision, ErrApprovalMissingApproval
	}

	if approval.TenantID != tenantID {
		decision.Reason = ApprovalReasonCrossTenant
		return ManualApprovalRequest{}, decision, ErrApprovalCrossTenant
	}

	if workflowID != "" && approval.WorkflowID != workflowID {
		decision.Reason = ApprovalReasonMissingWorkflow
		return ManualApprovalRequest{}, decision, ErrApprovalMissingWorkflow
	}

	if stepID != "" && approval.StepID != stepID {
		decision.Reason = ApprovalReasonMissingStep
		return ManualApprovalRequest{}, decision, ErrApprovalMissingStep
	}

	if approval.Status != ApprovalRequestStatusPending {
		decision.Reason = ApprovalReasonAlreadyFinal
		return ManualApprovalRequest{}, decision, ErrApprovalAlreadyFinal
	}

	if approval.RequiredRole != "" && !hasApprovalRole(req.ApproverRoles, approval.RequiredRole) {
		decision.Reason = ApprovalReasonRoleDenied
		return ManualApprovalRequest{}, decision, ErrApprovalRoleDenied
	}

	approval.Decisions = append(approval.Decisions, ManualApprovalDecision{
		TenantID:      tenantID,
		ApprovalID:    approvalID,
		WorkflowID:    approval.WorkflowID,
		StepID:        approval.StepID,
		ApproverRef:   strings.TrimSpace(req.ApproverRef),
		ApproverRoles: normalizeRoles(req.ApproverRoles),
		Decision:      req.Decision,
		Comment:       strings.TrimSpace(req.Comment),
		DecidedAt:     now,
		CorrelationID: strings.TrimSpace(req.CorrelationID),
	})
	approval.UpdatedAt = now

	if req.Decision == ApprovalDecisionReject {
		approval.Status = ApprovalRequestStatusRejected
	} else if approvalApprovedCount(approval.Decisions) >= approval.RequiredCount {
		approval.Status = ApprovalRequestStatusApproved
	}

	r.requests[approvalID] = approval

	decision.Decision = ApprovalRuntimeDecisionAllow
	decision.Allowed = true
	decision.WorkflowID = approval.WorkflowID
	decision.StepID = approval.StepID
	decision.Reason = ApprovalReasonAllowed

	return approval, decision, nil
}

func (r *ManualApprovalRuntime) GetApproval(tenantID string, approvalID string) (ManualApprovalRequest, error) {
	tenantID = strings.TrimSpace(tenantID)
	approvalID = strings.TrimSpace(approvalID)

	if tenantID == "" {
		return ManualApprovalRequest{}, ErrApprovalMissingTenant
	}
	if approvalID == "" {
		return ManualApprovalRequest{}, ErrApprovalMissingApproval
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	approval, ok := r.requests[approvalID]
	if !ok {
		return ManualApprovalRequest{}, ErrApprovalMissingApproval
	}

	if approval.TenantID != tenantID {
		return ManualApprovalRequest{}, ErrApprovalCrossTenant
	}

	return approval, nil
}

func (r *ManualApprovalRuntime) ApplyDecisionToWorkflow(machine *WorkflowStateMachine, instance WorkflowInstance, approval ManualApprovalRequest, actorRef string) (WorkflowInstance, WorkflowTransitionDecision, error) {
	if instance.TenantID != approval.TenantID {
		return instance, WorkflowTransitionDecision{
			Decision:   WorkflowDecisionDeny,
			Allowed:    false,
			TenantID:   approval.TenantID,
			WorkflowID: approval.WorkflowID,
			StepID:     approval.StepID,
			Reason:     WorkflowReasonCrossTenant,
			CheckedAt:  time.Now().UTC().Format(time.RFC3339Nano),
		}, ErrWorkflowCrossTenant
	}

	if instance.CurrentState != WorkflowStateWaitingApproval {
		return instance, WorkflowTransitionDecision{
			Decision:   WorkflowDecisionDeny,
			Allowed:    false,
			TenantID:   approval.TenantID,
			WorkflowID: approval.WorkflowID,
			StepID:     approval.StepID,
			Reason:     ApprovalReasonWorkflowNotWaiting,
			CheckedAt:  time.Now().UTC().Format(time.RFC3339Nano),
		}, ErrApprovalWorkflowNotWaiting
	}

	toState := WorkflowStateRunning
	if approval.Status == ApprovalRequestStatusRejected {
		toState = WorkflowStateApprovalRejected
	}

	if approval.Status != ApprovalRequestStatusApproved && approval.Status != ApprovalRequestStatusRejected {
		return instance, WorkflowTransitionDecision{
			Decision:   WorkflowDecisionDeny,
			Allowed:    false,
			TenantID:   approval.TenantID,
			WorkflowID: approval.WorkflowID,
			StepID:     approval.StepID,
			Reason:     ApprovalReasonInvalidDecision,
			CheckedAt:  time.Now().UTC().Format(time.RFC3339Nano),
		}, ErrApprovalInvalidDecision
	}

	return machine.Transition(instance, WorkflowTransitionRequest{
		TenantID:      approval.TenantID,
		WorkflowID:    approval.WorkflowID,
		FromState:     WorkflowStateWaitingApproval,
		ToState:       toState,
		StepID:        approval.StepID,
		ActorRef:      strings.TrimSpace(actorRef),
		Reason:        approval.Status,
		CorrelationID: approval.CorrelationID,
	})
}

func hasApprovalRole(roles []string, requiredRole string) bool {
	requiredRole = strings.TrimSpace(requiredRole)
	for _, role := range roles {
		if strings.EqualFold(strings.TrimSpace(role), requiredRole) {
			return true
		}
	}
	return false
}

func normalizeRoles(roles []string) []string {
	out := make([]string, 0, len(roles))
	for _, role := range roles {
		role = strings.TrimSpace(role)
		if role != "" {
			out = append(out, role)
		}
	}
	return out
}

func approvalApprovedCount(decisions []ManualApprovalDecision) int {
	count := 0
	for _, decision := range decisions {
		if decision.Decision == ApprovalDecisionApprove {
			count++
		}
	}
	return count
}

func NewApprovalID() string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return "appr_" + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return "appr_" + hex.EncodeToString(raw[:])
}
