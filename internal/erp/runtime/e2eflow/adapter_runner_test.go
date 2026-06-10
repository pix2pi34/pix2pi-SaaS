package e2eflow

import (
	"context"
	"errors"
	"testing"
)

type fakeRuntimeFlowStepAdapter struct {
	kind FlowStepKind
	err  error

	called  bool
	gotPlan RuntimeFlowPlan
	gotStep RuntimeFlowStep
}

func (a *fakeRuntimeFlowStepAdapter) StepKind() FlowStepKind {
	return a.kind
}

func (a *fakeRuntimeFlowStepAdapter) ExecuteStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	a.called = true
	a.gotPlan = plan
	a.gotStep = step

	if a.err != nil {
		return RuntimeFlowStep{}, a.err
	}

	step.Status = FlowStepStatusCompleted
	step.Message = "fake adapter completed"

	return step, nil
}

func TestDefaultRuntimeFlowAdapterRegistryRegisterAndFind(t *testing.T) {
	registry := NewDefaultRuntimeFlowAdapterRegistry()

	adapter := &fakeRuntimeFlowStepAdapter{
		kind: FlowStepPostJournal,
	}

	if err := registry.Register(adapter); err != nil {
		t.Fatalf("expected register success, got %v", err)
	}

	found, err := registry.AdapterFor(FlowStepPostJournal)
	if err != nil {
		t.Fatalf("expected adapter found, got %v", err)
	}

	if found != adapter {
		t.Fatal("expected same adapter instance")
	}
}

func TestDefaultRuntimeFlowAdapterRegistryNilAdapter(t *testing.T) {
	registry := NewDefaultRuntimeFlowAdapterRegistry()

	err := registry.Register(nil)
	if !errors.Is(err, ErrFlowAdapterRequired) {
		t.Fatalf("expected ErrFlowAdapterRequired, got %v", err)
	}
}

func TestDefaultRuntimeFlowAdapterRegistryInvalidKind(t *testing.T) {
	registry := NewDefaultRuntimeFlowAdapterRegistry()

	adapter := &fakeRuntimeFlowStepAdapter{
		kind: FlowStepKind("wrong"),
	}

	err := registry.Register(adapter)
	if !errors.Is(err, ErrFlowStepKindInvalid) {
		t.Fatalf("expected ErrFlowStepKindInvalid, got %v", err)
	}
}

func TestDefaultRuntimeFlowAdapterRegistryNotFound(t *testing.T) {
	registry := NewDefaultRuntimeFlowAdapterRegistry()

	_, err := registry.AdapterFor(FlowStepPostLedger)
	if !errors.Is(err, ErrFlowAdapterNotFound) {
		t.Fatalf("expected ErrFlowAdapterNotFound, got %v", err)
	}
}

func TestAdapterRuntimeFlowStepRunnerUsesAdapter(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected plan success, got %v", err)
	}

	step := RuntimeFlowStep{
		StepNo: 5,
		Kind:   FlowStepPostLedger,
		Status: FlowStepStatusPending,
	}

	adapter := &fakeRuntimeFlowStepAdapter{
		kind: FlowStepPostLedger,
	}

	registry := NewDefaultRuntimeFlowAdapterRegistry()
	if err := registry.Register(adapter); err != nil {
		t.Fatalf("register adapter: %v", err)
	}

	runner := NewAdapterRuntimeFlowStepRunner(registry, nil, true)

	completedStep, err := runner.RunStep(context.Background(), plan, step)
	if err != nil {
		t.Fatalf("expected runner success, got %v", err)
	}

	if !adapter.called {
		t.Fatal("expected adapter to be called")
	}

	if adapter.gotPlan.TenantID != plan.TenantID {
		t.Fatalf("expected tenant %s, got %s", plan.TenantID, adapter.gotPlan.TenantID)
	}

	if adapter.gotStep.Kind != FlowStepPostLedger {
		t.Fatalf("expected adapter step post_ledger, got %s", adapter.gotStep.Kind)
	}

	if completedStep.Status != FlowStepStatusCompleted {
		t.Fatalf("expected completed status, got %s", completedStep.Status)
	}

	if completedStep.Message != "fake adapter completed" {
		t.Fatalf("expected fake adapter message, got %s", completedStep.Message)
	}
}

func TestAdapterRuntimeFlowStepRunnerFallbackWhenNotStrict(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected plan success, got %v", err)
	}

	registry := NewDefaultRuntimeFlowAdapterRegistry()
	runner := NewAdapterRuntimeFlowStepRunner(registry, nil, false)

	step := RuntimeFlowStep{
		StepNo: 1,
		Kind:   FlowStepValidateRequest,
		Status: FlowStepStatusPending,
	}

	completedStep, err := runner.RunStep(context.Background(), plan, step)
	if err != nil {
		t.Fatalf("expected fallback success, got %v", err)
	}

	if completedStep.Status != FlowStepStatusCompleted {
		t.Fatalf("expected completed status, got %s", completedStep.Status)
	}
}

func TestAdapterRuntimeFlowStepRunnerStrictMissingAdapter(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected plan success, got %v", err)
	}

	registry := NewDefaultRuntimeFlowAdapterRegistry()
	runner := NewAdapterRuntimeFlowStepRunner(registry, nil, true)

	step := RuntimeFlowStep{
		StepNo: 1,
		Kind:   FlowStepValidateRequest,
		Status: FlowStepStatusPending,
	}

	_, err = runner.RunStep(context.Background(), plan, step)
	if !errors.Is(err, ErrFlowAdapterNotFound) {
		t.Fatalf("expected ErrFlowAdapterNotFound, got %v", err)
	}
}

func TestAdapterRuntimeFlowStepRunnerStrictNilRegistry(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected plan success, got %v", err)
	}

	runner := NewAdapterRuntimeFlowStepRunner(nil, nil, true)

	step := RuntimeFlowStep{
		StepNo: 1,
		Kind:   FlowStepValidateRequest,
		Status: FlowStepStatusPending,
	}

	_, err = runner.RunStep(context.Background(), plan, step)
	if !errors.Is(err, ErrFlowAdapterRequired) {
		t.Fatalf("expected ErrFlowAdapterRequired, got %v", err)
	}
}

func TestAdapterRuntimeFlowStepRunnerAdapterError(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected plan success, got %v", err)
	}

	adapter := &fakeRuntimeFlowStepAdapter{
		kind: FlowStepPostJournal,
		err:  ErrFlowStepKindInvalid,
	}

	registry := NewDefaultRuntimeFlowAdapterRegistry()
	if err := registry.Register(adapter); err != nil {
		t.Fatalf("register adapter: %v", err)
	}

	runner := NewAdapterRuntimeFlowStepRunner(registry, nil, true)

	step := RuntimeFlowStep{
		StepNo: 4,
		Kind:   FlowStepPostJournal,
		Status: FlowStepStatusPending,
	}

	failedStep, err := runner.RunStep(context.Background(), plan, step)
	if !errors.Is(err, ErrFlowStepKindInvalid) {
		t.Fatalf("expected ErrFlowStepKindInvalid, got %v", err)
	}

	if failedStep.Status != FlowStepStatusFailed {
		t.Fatalf("expected failed step status, got %s", failedStep.Status)
	}
}
