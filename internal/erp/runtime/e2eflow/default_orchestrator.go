package e2eflow

import (
	"context"
	"time"
)

var _ RuntimeE2EOrchestrator = (*DefaultRuntimeE2EOrchestrator)(nil)
var _ RuntimeFlowPlanner = (*DefaultRuntimeFlowPlanner)(nil)
var _ RuntimeFlowStepRunner = (*DefaultRuntimeFlowStepRunner)(nil)

type DefaultRuntimeFlowPlanner struct{}

func NewDefaultRuntimeFlowPlanner() *DefaultRuntimeFlowPlanner {
	return &DefaultRuntimeFlowPlanner{}
}

func (p *DefaultRuntimeFlowPlanner) BuildPlan(ctx context.Context, req RuntimeFlowRequest) (RuntimeFlowPlan, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return RuntimeFlowPlan{}, ctx.Err()
	default:
	}

	return BuildRuntimeFlowPlan(req)
}

type DefaultRuntimeFlowStepRunner struct{}

func NewDefaultRuntimeFlowStepRunner() *DefaultRuntimeFlowStepRunner {
	return &DefaultRuntimeFlowStepRunner{}
}

func (r *DefaultRuntimeFlowStepRunner) RunStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return RuntimeFlowStep{}, ctx.Err()
	default:
	}

	if err := ValidateRuntimeFlowStep(step); err != nil {
		return RuntimeFlowStep{}, err
	}

	now := time.Now().UTC()

	if step.StartedAt.IsZero() {
		step.StartedAt = now
	}

	step.CompletedAt = now
	step.Status = FlowStepStatusCompleted

	if step.Message == "" {
		step.Message = "completed"
	}

	return step, nil
}

type DefaultRuntimeE2EOrchestrator struct {
	planner   RuntimeFlowPlanner
	runner    RuntimeFlowStepRunner
	store     RuntimeFlowStore
	publisher RuntimeFlowPublisher
}

func NewDefaultRuntimeE2EOrchestrator(
	planner RuntimeFlowPlanner,
	runner RuntimeFlowStepRunner,
	store RuntimeFlowStore,
	publisher RuntimeFlowPublisher,
) *DefaultRuntimeE2EOrchestrator {
	if planner == nil {
		planner = NewDefaultRuntimeFlowPlanner()
	}

	if runner == nil {
		runner = NewDefaultRuntimeFlowStepRunner()
	}

	return &DefaultRuntimeE2EOrchestrator{
		planner:   planner,
		runner:    runner,
		store:     store,
		publisher: publisher,
	}
}

func (o *DefaultRuntimeE2EOrchestrator) ExecuteRuntimeFlow(ctx context.Context, req RuntimeFlowRequest) (RuntimeFlowResult, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return RuntimeFlowResult{}, ctx.Err()
	default:
	}

	if err := ValidateRuntimeFlowRequest(req); err != nil {
		return RuntimeFlowResult{}, err
	}

	if o.store == nil {
		return RuntimeFlowResult{}, ErrFlowStoreRequired
	}

	plan, err := o.planner.BuildPlan(ctx, req)
	if err != nil {
		return RuntimeFlowResult{}, err
	}

	persistedPlan, err := o.store.PersistFlowPlan(ctx, plan)
	if err != nil {
		return RuntimeFlowResult{}, err
	}

	persistedPlan.Status = FlowStatusRunning

	for index := range persistedPlan.Steps {
		select {
		case <-ctx.Done():
			return RuntimeFlowResult{}, ctx.Err()
		default:
		}

		step := persistedPlan.Steps[index]
		step.Status = FlowStepStatusRunning
		step.StartedAt = time.Now().UTC()

		completedStep, err := o.runner.RunStep(ctx, persistedPlan, step)
		if err != nil {
			failedPlan, markErr := o.store.MarkFlowFailed(ctx, persistedPlan, err)
			if markErr == nil && o.publisher != nil {
				_ = o.publisher.PublishFlowFailed(ctx, failedPlan, err)
			}

			return RuntimeFlowResult{}, err
		}

		persistedPlan.Steps[index] = completedStep
	}

	completedPlan, err := CompleteRuntimeFlowPlan(persistedPlan, time.Now().UTC())
	if err != nil {
		return RuntimeFlowResult{}, err
	}

	completedPlan, err = o.store.MarkFlowCompleted(ctx, completedPlan)
	if err != nil {
		return RuntimeFlowResult{}, err
	}

	result, err := BuildRuntimeFlowResult(req, completedPlan, "runtime flow completed")
	if err != nil {
		return RuntimeFlowResult{}, err
	}

	if o.publisher != nil {
		if err := o.publisher.PublishFlowCompleted(ctx, result); err != nil {
			return RuntimeFlowResult{}, err
		}
	}

	return result, nil
}
