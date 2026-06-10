package workflow

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ApplyWorkflowRecoveryCommand struct {
	TenantID        string
	WorkflowRunID   string
	StepKey         string
	ActionType      string
	RequestedBy     string
	Reason          string
	ResetAttempts   bool
	CompensationRef string
}

type ApplyWorkflowRecoveryResult struct {
	WorkflowRunID   string
	StepKey         string
	ActionType      string
	StepStatus      string
	WorkflowState   string
	AttemptNo       int
	CompensationRef string
	LeaseReleased   bool
}

type WorkflowRecoveryStore interface {
	ApplyRecovery(ctx context.Context, cmd ApplyWorkflowRecoveryCommand) (ApplyWorkflowRecoveryResult, error)
}

type ApplyWorkflowRecoveryUsecase struct {
	store WorkflowRecoveryStore
	nowFn func() time.Time
}

func NewApplyWorkflowRecoveryUsecase(store WorkflowRecoveryStore) *ApplyWorkflowRecoveryUsecase {
	return &ApplyWorkflowRecoveryUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ApplyWorkflowRecoveryUsecase) Apply(ctx context.Context, req ApplyWorkflowRecoveryRequest) (ApplyWorkflowRecoveryResponse, error) {
	if u == nil || u.store == nil {
		return ApplyWorkflowRecoveryResponse{}, errors.New("workflow recovery usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.WorkflowRunID = strings.TrimSpace(req.WorkflowRunID)
	req.StepKey = strings.TrimSpace(req.StepKey)
	req.ActionType = strings.TrimSpace(req.ActionType)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)
	req.Reason = strings.TrimSpace(req.Reason)
	req.CompensationRef = strings.TrimSpace(req.CompensationRef)

	if err := req.Validate(); err != nil {
		return ApplyWorkflowRecoveryResponse{}, err
	}

	result, err := u.store.ApplyRecovery(ctx, ApplyWorkflowRecoveryCommand{
		TenantID:        req.TenantID,
		WorkflowRunID:   req.WorkflowRunID,
		StepKey:         req.StepKey,
		ActionType:      req.ActionType,
		RequestedBy:     req.RequestedBy,
		Reason:          req.Reason,
		ResetAttempts:   req.ResetAttempts,
		CompensationRef: req.CompensationRef,
	})
	if err != nil {
		return ApplyWorkflowRecoveryResponse{}, err
	}

	stepStatus, workflowState := resolveFallbackWorkflowRecoveryOutcome(req.ActionType)
	if strings.TrimSpace(result.StepStatus) != "" {
		stepStatus = strings.TrimSpace(result.StepStatus)
	}
	if strings.TrimSpace(result.WorkflowState) != "" {
		workflowState = strings.TrimSpace(result.WorkflowState)
	}

	attemptNo := result.AttemptNo
	if req.ResetAttempts && attemptNo == 0 {
		attemptNo = 0
	}

	leaseReleased := result.LeaseReleased
	if !leaseReleased {
		leaseReleased = true
	}

	resp := ApplyWorkflowRecoveryResponse{
		WorkflowRunID:   firstNonEmpty(strings.TrimSpace(result.WorkflowRunID), req.WorkflowRunID),
		StepKey:         firstNonEmpty(strings.TrimSpace(result.StepKey), req.StepKey),
		ActionType:      firstNonEmpty(strings.TrimSpace(result.ActionType), req.ActionType),
		StepStatus:      stepStatus,
		WorkflowState:   workflowState,
		AttemptNo:       attemptNo,
		CompensationRef: firstNonEmpty(strings.TrimSpace(result.CompensationRef), req.CompensationRef),
		LeaseReleased:   leaseReleased,
		RequestedBy:     req.RequestedBy,
		Reason:          req.Reason,
		RequestedAt:     u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return ApplyWorkflowRecoveryResponse{}, err
	}

	return resp, nil
}

func resolveFallbackWorkflowRecoveryOutcome(actionType string) (string, string) {
	switch strings.TrimSpace(actionType) {
	case "retry":
		return "pending", "pending"
	case "compensate":
		return "compensating", "failed"
	default:
		return "", ""
	}
}
