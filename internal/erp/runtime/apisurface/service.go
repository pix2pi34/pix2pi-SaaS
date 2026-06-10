package apisurface

import (
	"context"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/e2eflow"
)

type RuntimeFlowExecutor interface {
	ExecuteRuntimeFlow(ctx context.Context, req e2eflow.RuntimeFlowRequest) (e2eflow.RuntimeFlowResult, error)
}

type RuntimeFlowAPIService interface {
	PostRuntimeFlow(ctx context.Context, req RuntimeFlowAPIRequest) (RuntimeFlowAPIResponse, error)
}

type DefaultRuntimeFlowAPIService struct {
	executor RuntimeFlowExecutor
}

func NewDefaultRuntimeFlowAPIService(executor RuntimeFlowExecutor) *DefaultRuntimeFlowAPIService {
	return &DefaultRuntimeFlowAPIService{executor: executor}
}

func (s *DefaultRuntimeFlowAPIService) PostRuntimeFlow(ctx context.Context, req RuntimeFlowAPIRequest) (RuntimeFlowAPIResponse, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return RuntimeFlowAPIResponse{}, ctx.Err()
	default:
	}

	if err := ValidateRuntimeFlowAPIRequest(req); err != nil {
		return RuntimeFlowAPIResponse{}, err
	}

	if s.executor == nil {
		return RuntimeFlowAPIResponse{}, ErrRuntimeFlowExecutorRequired
	}

	flowReq, err := ToRuntimeFlowRequest(req)
	if err != nil {
		return RuntimeFlowAPIResponse{}, err
	}

	result, err := s.executor.ExecuteRuntimeFlow(ctx, flowReq)
	if err != nil {
		return RuntimeFlowAPIResponse{}, err
	}

	return BuildRuntimeFlowAPIResponse(result), nil
}
