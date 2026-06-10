package workflow

import (
	"context"
	"errors"
	"strings"
	"time"
)

type ClaimWorkflowStepCommand struct {
	TenantID      string
	WorkflowRunID string
	StepKey       string
	WorkerID      string
	LeaseSeconds  int
}

type ClaimWorkflowStepResult struct {
	Claimed        bool
	WorkflowRunID  string
	StepKey        string
	StepType       string
	Status         string
	AttemptNo      int
	LeaseExpiresAt *time.Time
}

type WorkflowStepClaimStore interface {
	ClaimStep(ctx context.Context, cmd ClaimWorkflowStepCommand) (ClaimWorkflowStepResult, error)
}

type ClaimWorkflowStepUsecase struct {
	store WorkflowStepClaimStore
	nowFn func() time.Time
}

func NewClaimWorkflowStepUsecase(store WorkflowStepClaimStore) *ClaimWorkflowStepUsecase {
	return &ClaimWorkflowStepUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ClaimWorkflowStepUsecase) Claim(ctx context.Context, req ClaimWorkflowStepRequest) (ClaimWorkflowStepResponse, error) {
	if u == nil || u.store == nil {
		return ClaimWorkflowStepResponse{}, errors.New("workflow step claim usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.WorkflowRunID = strings.TrimSpace(req.WorkflowRunID)
	req.StepKey = strings.TrimSpace(req.StepKey)
	req.WorkerID = strings.TrimSpace(req.WorkerID)

	if err := req.Validate(); err != nil {
		return ClaimWorkflowStepResponse{}, err
	}

	result, err := u.store.ClaimStep(ctx, ClaimWorkflowStepCommand{
		TenantID:      req.TenantID,
		WorkflowRunID: req.WorkflowRunID,
		StepKey:       req.StepKey,
		WorkerID:      req.WorkerID,
		LeaseSeconds:  req.LeaseSeconds,
	})
	if err != nil {
		return ClaimWorkflowStepResponse{}, err
	}

	resp := ClaimWorkflowStepResponse{
		Claimed:   result.Claimed,
		ClaimedAt: u.nowFn().UTC(),
	}

	if result.Claimed {
		resp.WorkflowRunID = firstNonEmpty(strings.TrimSpace(result.WorkflowRunID), req.WorkflowRunID)
		resp.StepKey = firstNonEmpty(strings.TrimSpace(result.StepKey), req.StepKey)
		resp.StepType = strings.TrimSpace(result.StepType)
		resp.Status = firstNonEmpty(strings.TrimSpace(result.Status), "in_progress")
		resp.AttemptNo = result.AttemptNo
		resp.WorkerID = req.WorkerID
		resp.LeaseExpiresAt = cloneWorkflowTimePtr(result.LeaseExpiresAt)
	}

	if err := resp.Validate(); err != nil {
		return ClaimWorkflowStepResponse{}, err
	}

	return resp, nil
}

func cloneWorkflowTimePtr(in *time.Time) *time.Time {
	if in == nil {
		return nil
	}
	t := in.UTC()
	return &t
}
