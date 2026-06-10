package e2eflow

import (
	"context"
	"errors"
	"time"
)

var _ RuntimeFlowStepRunner = (*AdapterRuntimeFlowStepRunner)(nil)

type RuntimeFlowStepAdapter interface {
	StepKind() FlowStepKind
	ExecuteStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error)
}

type RuntimeFlowAdapterRegistry interface {
	Register(adapter RuntimeFlowStepAdapter) error
	AdapterFor(kind FlowStepKind) (RuntimeFlowStepAdapter, error)
}

type DefaultRuntimeFlowAdapterRegistry struct {
	adapters map[FlowStepKind]RuntimeFlowStepAdapter
}

func NewDefaultRuntimeFlowAdapterRegistry() *DefaultRuntimeFlowAdapterRegistry {
	return &DefaultRuntimeFlowAdapterRegistry{
		adapters: make(map[FlowStepKind]RuntimeFlowStepAdapter),
	}
}

func (r *DefaultRuntimeFlowAdapterRegistry) Register(adapter RuntimeFlowStepAdapter) error {
	if adapter == nil {
		return ErrFlowAdapterRequired
	}

	kind := adapter.StepKind()
	if !isValidFlowStepKind(kind) {
		return ErrFlowStepKindInvalid
	}

	r.adapters[kind] = adapter
	return nil
}

func (r *DefaultRuntimeFlowAdapterRegistry) AdapterFor(kind FlowStepKind) (RuntimeFlowStepAdapter, error) {
	if !isValidFlowStepKind(kind) {
		return nil, ErrFlowStepKindInvalid
	}

	adapter, ok := r.adapters[kind]
	if !ok || adapter == nil {
		return nil, ErrFlowAdapterNotFound
	}

	return adapter, nil
}

type AdapterRuntimeFlowStepRunner struct {
	registry RuntimeFlowAdapterRegistry
	fallback RuntimeFlowStepRunner
	strict   bool
}

func NewAdapterRuntimeFlowStepRunner(
	registry RuntimeFlowAdapterRegistry,
	fallback RuntimeFlowStepRunner,
	strict bool,
) *AdapterRuntimeFlowStepRunner {
	if fallback == nil {
		fallback = NewDefaultRuntimeFlowStepRunner()
	}

	return &AdapterRuntimeFlowStepRunner{
		registry: registry,
		fallback: fallback,
		strict:   strict,
	}
}

func (r *AdapterRuntimeFlowStepRunner) RunStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return RuntimeFlowStep{}, ctx.Err()
	default:
	}

	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowStep{}, err
	}

	if err := ValidateRuntimeFlowStep(step); err != nil {
		return RuntimeFlowStep{}, err
	}

	if r.registry == nil {
		if r.strict {
			return RuntimeFlowStep{}, ErrFlowAdapterRequired
		}

		return r.fallback.RunStep(ctx, plan, step)
	}

	adapter, err := r.registry.AdapterFor(step.Kind)
	if err != nil {
		if r.strict || !errors.Is(err, ErrFlowAdapterNotFound) {
			return RuntimeFlowStep{}, err
		}

		return r.fallback.RunStep(ctx, plan, step)
	}

	startedAt := time.Now().UTC()

	if step.StartedAt.IsZero() {
		step.StartedAt = startedAt
	}

	step.Status = FlowStepStatusRunning

	completedStep, err := adapter.ExecuteStep(ctx, plan, step)
	if err != nil {
		step.Status = FlowStepStatusFailed
		step.Message = err.Error()
		return step, err
	}

	if completedStep.StepNo == 0 {
		completedStep.StepNo = step.StepNo
	}

	if completedStep.Kind == "" {
		completedStep.Kind = step.Kind
	}

	if completedStep.Status == "" {
		completedStep.Status = FlowStepStatusCompleted
	}

	if completedStep.StartedAt.IsZero() {
		completedStep.StartedAt = step.StartedAt
	}

	if completedStep.CompletedAt.IsZero() {
		completedStep.CompletedAt = time.Now().UTC()
	}

	if completedStep.Message == "" {
		completedStep.Message = "adapter completed"
	}

	return completedStep, nil
}
