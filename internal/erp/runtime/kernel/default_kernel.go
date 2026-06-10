package kernel

import (
	"context"
	"time"
)

var _ RuntimeKernel = (*DefaultRuntimeKernel)(nil)

type DefaultRuntimeKernel struct{}

func NewDefaultRuntimeKernel() *DefaultRuntimeKernel {
	return &DefaultRuntimeKernel{}
}

func (k *DefaultRuntimeKernel) Validate(ctx context.Context, req RuntimeRequest) error {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	return ValidateRuntimeRequest(req)
}

func (k *DefaultRuntimeKernel) Execute(ctx context.Context, req RuntimeRequest) (RuntimeResult, error) {
	if err := k.Validate(ctx, req); err != nil {
		return RuntimeResult{}, err
	}

	return RuntimeResult{
		OK:         true,
		TenantID:   req.Tenant.TenantID,
		RequestID:  req.Tenant.RequestID,
		Operation:  req.Operation,
		Document:   req.Document,
		Message:    "erp runtime kernel executed",
		OccurredAt: time.Now().UTC(),
	}, nil
}
