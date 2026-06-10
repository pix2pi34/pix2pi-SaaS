package e2eflow

import "context"

type RuntimeE2EOrchestrator interface {
	ExecuteRuntimeFlow(ctx context.Context, req RuntimeFlowRequest) (RuntimeFlowResult, error)
}

type RuntimeFlowPlanner interface {
	BuildPlan(ctx context.Context, req RuntimeFlowRequest) (RuntimeFlowPlan, error)
}

type RuntimeFlowStepRunner interface {
	RunStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error)
}

type RuntimeFlowStore interface {
	PersistFlowPlan(ctx context.Context, plan RuntimeFlowPlan) (RuntimeFlowPlan, error)
	MarkFlowCompleted(ctx context.Context, plan RuntimeFlowPlan) (RuntimeFlowPlan, error)
	MarkFlowFailed(ctx context.Context, plan RuntimeFlowPlan, cause error) (RuntimeFlowPlan, error)
}

type RuntimeFlowPublisher interface {
	PublishFlowCompleted(ctx context.Context, result RuntimeFlowResult) error
	PublishFlowFailed(ctx context.Context, plan RuntimeFlowPlan, cause error) error
}
