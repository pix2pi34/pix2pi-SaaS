package workflow

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ApplyManualApprovalCommand struct {
	TenantID      string
	WorkflowRunID string
	StepKey       string
	ApprovalID    string
	ApproverRef   string
	Decision      string
	Comment       string
}

type ApplyManualApprovalResult struct {
	WorkflowRunID     string
	StepKey           string
	ApprovalID        string
	ApproverRef       string
	Decision          string
	ApprovalStatus    string
	WorkflowNextState string
	Comment           string
	Completed         bool
}

type ManualApprovalStore interface {
	ApplyApprovalDecision(ctx context.Context, cmd ApplyManualApprovalCommand) (ApplyManualApprovalResult, error)
}

type ApplyManualApprovalUsecase struct {
	store ManualApprovalStore
	nowFn func() time.Time
}

func NewApplyManualApprovalUsecase(store ManualApprovalStore) *ApplyManualApprovalUsecase {
	return &ApplyManualApprovalUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ApplyManualApprovalUsecase) Apply(ctx context.Context, req ApplyManualApprovalRequest) (ApplyManualApprovalResponse, error) {
	if u == nil || u.store == nil {
		return ApplyManualApprovalResponse{}, errors.New("manual approval usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.WorkflowRunID = strings.TrimSpace(req.WorkflowRunID)
	req.StepKey = strings.TrimSpace(req.StepKey)
	req.ApprovalID = strings.TrimSpace(req.ApprovalID)
	req.ApproverRef = strings.TrimSpace(req.ApproverRef)
	req.Decision = strings.TrimSpace(req.Decision)
	req.Comment = strings.TrimSpace(req.Comment)

	if err := req.Validate(); err != nil {
		return ApplyManualApprovalResponse{}, err
	}

	result, err := u.store.ApplyApprovalDecision(ctx, ApplyManualApprovalCommand{
		TenantID:      req.TenantID,
		WorkflowRunID: req.WorkflowRunID,
		StepKey:       req.StepKey,
		ApprovalID:    req.ApprovalID,
		ApproverRef:   req.ApproverRef,
		Decision:      req.Decision,
		Comment:       req.Comment,
	})
	if err != nil {
		return ApplyManualApprovalResponse{}, err
	}

	approvalStatus, workflowNextState := resolveFallbackApprovalOutcome(req.Decision)
	if strings.TrimSpace(result.ApprovalStatus) != "" {
		approvalStatus = strings.TrimSpace(result.ApprovalStatus)
	}
	if strings.TrimSpace(result.WorkflowNextState) != "" {
		workflowNextState = strings.TrimSpace(result.WorkflowNextState)
	}

	completed := result.Completed
	if !completed {
		completed = true
	}

	resp := ApplyManualApprovalResponse{
		WorkflowRunID:     firstNonEmpty(strings.TrimSpace(result.WorkflowRunID), req.WorkflowRunID),
		StepKey:           firstNonEmpty(strings.TrimSpace(result.StepKey), req.StepKey),
		ApprovalID:        firstNonEmpty(strings.TrimSpace(result.ApprovalID), req.ApprovalID),
		ApproverRef:       firstNonEmpty(strings.TrimSpace(result.ApproverRef), req.ApproverRef),
		Decision:          firstNonEmpty(strings.TrimSpace(result.Decision), req.Decision),
		ApprovalStatus:    approvalStatus,
		WorkflowNextState: workflowNextState,
		Comment:           firstNonEmpty(strings.TrimSpace(result.Comment), req.Comment),
		Completed:         completed,
		DecidedAt:         u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return ApplyManualApprovalResponse{}, err
	}

	return resp, nil
}

func resolveFallbackApprovalOutcome(decision string) (string, string) {
	switch strings.TrimSpace(decision) {
	case "approve":
		return "approved", "approved"
	case "reject":
		return "rejected", "rejected"
	default:
		return "", ""
	}
}
