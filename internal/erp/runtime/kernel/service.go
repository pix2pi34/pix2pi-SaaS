package kernel

import "context"

type RuntimeKernel interface {
	Validate(ctx context.Context, req RuntimeRequest) error
	Execute(ctx context.Context, req RuntimeRequest) (RuntimeResult, error)
}

type RuntimeValidator interface {
	ValidateRuntimeRequest(req RuntimeRequest) error
}

type RuntimeExecutor interface {
	ExecuteRuntimeRequest(ctx context.Context, req RuntimeRequest) (RuntimeResult, error)
}
