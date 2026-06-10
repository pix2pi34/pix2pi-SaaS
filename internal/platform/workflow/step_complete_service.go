package workflow

import (
	"context"
	"errors"
	"strings"
	"time"
)

type CompleteWorkflowStepCommand struct {
	TenantID       string
	WorkflowRunID  string
	StepKey        string
	WorkerID       string
	Status         string
	AttemptNo      int
	OutputRef      string
	ErrorCode      string
	CompletionNote string
}

type CompleteWorkflowStepResult struct {
	WorkflowRunID  string
	StepKey        string
	Status         string
	AttemptNo      int
	OutputRef      string
	ErrorCode      string
	CompletionNote string
	LeaseReleased  bool
}

type WorkflowStepCompletionStore interface {
	CompleteStep(ctx context.Context, cmd CompleteWorkflowStepCommand) (CompleteWorkflowStepResult, error)
}

type CompleteWorkflowStepUsecase struct {
	store WorkflowStepCompletionStore
	nowFn func() time.Time
}

func NewCompleteWorkflowStepUsecase(store WorkflowStepCompletionStore) *CompleteWorkflowStepUsecase {
	return &CompleteWorkflowStepUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *CompleteWorkflowStepUsecase) Complete(ctx context.Context, req CompleteWorkflowStepRequest) (CompleteWorkflowStepResponse, error) {
	if u == nil || u.store == nil {
		return CompleteWorkflowStepResponse{}, errors.New("workflow step complete usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.WorkflowRunID = strings.TrimSpace(req.WorkflowRunID)
	req.StepKey = strings.TrimSpace(req.StepKey)
	req.WorkerID = strings.TrimSpace(req.WorkerID)
	req.Status = strings.TrimSpace(req.Status)
	req.OutputRef = strings.TrimSpace(req.OutputRef)
	req.ErrorCode = strings.TrimSpace(req.ErrorCode)
	req.CompletionNote = strings.TrimSpace(req.CompletionNote)

	if err := req.Validate(); err != nil {
		return CompleteWorkflowStepResponse{}, err
	}

	result, err := u.store.CompleteStep(ctx, CompleteWorkflowStepCommand{
		TenantID:       req.TenantID,
		WorkflowRunID:  req.WorkflowRunID,
		StepKey:        req.StepKey,
		WorkerID:       req.WorkerID,
		Status:         req.Status,
		AttemptNo:      req.AttemptNo,
		OutputRef:      req.OutputRef,
		ErrorCode:      req.ErrorCode,
		CompletionNote: req.CompletionNote,
	})
	if err != nil {
		return CompleteWorkflowStepResponse{}, err
	}

	leaseReleased := result.LeaseReleased
	if !leaseReleased {
		leaseReleased = true
	}

	resp := CompleteWorkflowStepResponse{
		WorkflowRunID:  firstNonEmpty(strings.TrimSpace(result.WorkflowRunID), req.WorkflowRunID),
		StepKey:        firstNonEmpty(strings.TrimSpace(result.StepKey), req.StepKey),
		WorkerID:       req.WorkerID,
		Status:         firstNonEmpty(strings.TrimSpace(result.Status), req.Status),
		AttemptNo:      req.AttemptNo,
		OutputRef:      firstNonEmpty(strings.TrimSpace(result.OutputRef), req.OutputRef),
		ErrorCode:      firstNonEmpty(strings.TrimSpace(result.ErrorCode), req.ErrorCode),
		CompletionNote: firstNonEmpty(strings.TrimSpace(result.CompletionNote), req.CompletionNote),
		LeaseReleased:  leaseReleased,
		CompletedAt:    u.nowFn().UTC(),
	}

	if result.AttemptNo != 0 {
		resp.AttemptNo = result.AttemptNo
	}

	if err := resp.Validate(); err != nil {
		return CompleteWorkflowStepResponse{}, err
	}

	return resp, nil
}
