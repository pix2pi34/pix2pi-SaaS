package workflow

import (
	"context"
	"errors"
	"strings"
	"time"
)

type LoadWorkflowObservabilityCommand struct {
	TenantID      string
	WorkflowRunID string
	RequestedBy   string
}

type LoadWorkflowObservabilityResult struct {
	WorkflowRunID string
	DefinitionKey string
	WorkflowState string
	Summary       WorkflowObservabilitySummary
	Steps         []WorkflowStepObservation
}

type WorkflowObservabilityStore interface {
	LoadObservability(ctx context.Context, cmd LoadWorkflowObservabilityCommand) (LoadWorkflowObservabilityResult, error)
}

type LoadWorkflowObservabilityUsecase struct {
	store WorkflowObservabilityStore
	nowFn func() time.Time
}

func NewLoadWorkflowObservabilityUsecase(store WorkflowObservabilityStore) *LoadWorkflowObservabilityUsecase {
	return &LoadWorkflowObservabilityUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *LoadWorkflowObservabilityUsecase) Load(ctx context.Context, req LoadWorkflowObservabilityRequest) (LoadWorkflowObservabilityResponse, error) {
	if u == nil || u.store == nil {
		return LoadWorkflowObservabilityResponse{}, errors.New("workflow observability usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.WorkflowRunID = strings.TrimSpace(req.WorkflowRunID)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return LoadWorkflowObservabilityResponse{}, err
	}

	result, err := u.store.LoadObservability(ctx, LoadWorkflowObservabilityCommand{
		TenantID:      req.TenantID,
		WorkflowRunID: req.WorkflowRunID,
		RequestedBy:   req.RequestedBy,
	})
	if err != nil {
		return LoadWorkflowObservabilityResponse{}, err
	}

	resp := LoadWorkflowObservabilityResponse{
		WorkflowRunID: firstNonEmpty(strings.TrimSpace(result.WorkflowRunID), req.WorkflowRunID),
		DefinitionKey: strings.TrimSpace(result.DefinitionKey),
		WorkflowState: strings.TrimSpace(result.WorkflowState),
		HealthStatus:  resolveWorkflowHealthStatus(result.Summary),
		Summary:       result.Summary,
		Steps:         cloneWorkflowStepObservations(result.Steps),
		ObservedAt:    u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return LoadWorkflowObservabilityResponse{}, err
	}

	return resp, nil
}

func resolveWorkflowHealthStatus(summary WorkflowObservabilitySummary) string {
	switch {
	case summary.FailedSteps > 0:
		return "failed"
	case summary.ExpiredLeaseCount > 0:
		return "stalled"
	case summary.PendingApprovals > 0 || summary.InProgressSteps > 0:
		return "degraded"
	default:
		return "healthy"
	}
}

func cloneWorkflowStepObservations(in []WorkflowStepObservation) []WorkflowStepObservation {
	if len(in) == 0 {
		return []WorkflowStepObservation{}
	}

	out := make([]WorkflowStepObservation, len(in))
	copy(out, in)

	for i := range out {
		out[i].LeaseExpiresAt = cloneWorkflowTimePtr(in[i].LeaseExpiresAt)
	}

	return out
}
