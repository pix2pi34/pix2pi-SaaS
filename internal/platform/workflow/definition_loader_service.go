package workflow

import (
	"context"
	"errors"
	"strings"
	"time"
)

type LoadWorkflowDefinitionCommand struct {
	TenantID      string
	DefinitionKey string
	RequestedBy   string
}

type LoadWorkflowDefinitionResult struct {
	DefinitionKey string
	Version       int
	InitialState  string
	Loaded        bool
	Steps         []WorkflowDefinitionStep
}

type WorkflowDefinitionLoaderStore interface {
	LoadDefinition(ctx context.Context, cmd LoadWorkflowDefinitionCommand) (LoadWorkflowDefinitionResult, error)
}

type LoadWorkflowDefinitionUsecase struct {
	store WorkflowDefinitionLoaderStore
	nowFn func() time.Time
}

func NewLoadWorkflowDefinitionUsecase(store WorkflowDefinitionLoaderStore) *LoadWorkflowDefinitionUsecase {
	return &LoadWorkflowDefinitionUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *LoadWorkflowDefinitionUsecase) Load(ctx context.Context, req LoadWorkflowDefinitionRequest) (LoadWorkflowDefinitionResponse, error) {
	if u == nil || u.store == nil {
		return LoadWorkflowDefinitionResponse{}, errors.New("workflow definition loader usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.DefinitionKey = strings.TrimSpace(req.DefinitionKey)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return LoadWorkflowDefinitionResponse{}, err
	}

	result, err := u.store.LoadDefinition(ctx, LoadWorkflowDefinitionCommand{
		TenantID:      req.TenantID,
		DefinitionKey: req.DefinitionKey,
		RequestedBy:   req.RequestedBy,
	})
	if err != nil {
		return LoadWorkflowDefinitionResponse{}, err
	}

	resp := LoadWorkflowDefinitionResponse{
		DefinitionKey: firstNonEmpty(strings.TrimSpace(result.DefinitionKey), req.DefinitionKey),
		Version:       result.Version,
		InitialState:  strings.TrimSpace(result.InitialState),
		Loaded:        result.Loaded,
		Steps:         cloneWorkflowDefinitionSteps(result.Steps),
		LoadedAt:      u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return LoadWorkflowDefinitionResponse{}, err
	}

	return resp, nil
}

func cloneWorkflowDefinitionSteps(in []WorkflowDefinitionStep) []WorkflowDefinitionStep {
	if len(in) == 0 {
		return []WorkflowDefinitionStep{}
	}

	out := make([]WorkflowDefinitionStep, len(in))
	copy(out, in)
	return out
}
