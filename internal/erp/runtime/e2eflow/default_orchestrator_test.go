package e2eflow

import (
	"context"
	"errors"
	"testing"
)

type fakeRuntimeFlowPlanner struct {
	err error

	called bool
	gotReq RuntimeFlowRequest
}

func (p *fakeRuntimeFlowPlanner) BuildPlan(ctx context.Context, req RuntimeFlowRequest) (RuntimeFlowPlan, error) {
	p.called = true
	p.gotReq = req

	if p.err != nil {
		return RuntimeFlowPlan{}, p.err
	}

	return BuildRuntimeFlowPlan(req)
}

type fakeRuntimeFlowStepRunner struct {
	errAtStep int
	err       error

	calledSteps []RuntimeFlowStep
}

func (r *fakeRuntimeFlowStepRunner) RunStep(ctx context.Context, plan RuntimeFlowPlan, step RuntimeFlowStep) (RuntimeFlowStep, error) {
	r.calledSteps = append(r.calledSteps, step)

	if r.err != nil && len(r.calledSteps) == r.errAtStep {
		return RuntimeFlowStep{}, r.err
	}

	return NewDefaultRuntimeFlowStepRunner().RunStep(ctx, plan, step)
}

type fakeRuntimeFlowStore struct {
	persistErr  error
	completeErr error
	failErr     error

	persistCalled  bool
	completeCalled bool
	failCalled     bool

	gotPersistPlan  RuntimeFlowPlan
	gotCompletePlan RuntimeFlowPlan
	gotFailPlan     RuntimeFlowPlan
	gotFailCause    error
}

func (s *fakeRuntimeFlowStore) PersistFlowPlan(ctx context.Context, plan RuntimeFlowPlan) (RuntimeFlowPlan, error) {
	s.persistCalled = true
	s.gotPersistPlan = plan

	if s.persistErr != nil {
		return RuntimeFlowPlan{}, s.persistErr
	}

	return plan, nil
}

func (s *fakeRuntimeFlowStore) MarkFlowCompleted(ctx context.Context, plan RuntimeFlowPlan) (RuntimeFlowPlan, error) {
	s.completeCalled = true
	s.gotCompletePlan = plan

	if s.completeErr != nil {
		return RuntimeFlowPlan{}, s.completeErr
	}

	plan.Status = FlowStatusCompleted
	return plan, nil
}

func (s *fakeRuntimeFlowStore) MarkFlowFailed(ctx context.Context, plan RuntimeFlowPlan, cause error) (RuntimeFlowPlan, error) {
	s.failCalled = true
	s.gotFailPlan = plan
	s.gotFailCause = cause

	if s.failErr != nil {
		return RuntimeFlowPlan{}, s.failErr
	}

	plan.Status = FlowStatusFailed
	return plan, nil
}

type fakeRuntimeFlowPublisher struct {
	completeErr error
	failErr     error

	completeCalled bool
	failCalled     bool

	gotResult    RuntimeFlowResult
	gotFailPlan  RuntimeFlowPlan
	gotFailCause error
}

func (p *fakeRuntimeFlowPublisher) PublishFlowCompleted(ctx context.Context, result RuntimeFlowResult) error {
	p.completeCalled = true
	p.gotResult = result

	if p.completeErr != nil {
		return p.completeErr
	}

	return nil
}

func (p *fakeRuntimeFlowPublisher) PublishFlowFailed(ctx context.Context, plan RuntimeFlowPlan, cause error) error {
	p.failCalled = true
	p.gotFailPlan = plan
	p.gotFailCause = cause

	if p.failErr != nil {
		return p.failErr
	}

	return nil
}

func TestDefaultRuntimeFlowPlannerSuccess(t *testing.T) {
	planner := NewDefaultRuntimeFlowPlanner()

	plan, err := planner.BuildPlan(context.Background(), validRuntimeFlowRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if plan.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", plan.TenantID)
	}

	if len(plan.Steps) != 6 {
		t.Fatalf("expected 6 steps, got %d", len(plan.Steps))
	}
}

func TestDefaultRuntimeFlowStepRunnerSuccess(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("expected plan success, got %v", err)
	}

	runner := NewDefaultRuntimeFlowStepRunner()

	step, err := runner.RunStep(context.Background(), plan, plan.Steps[0])
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if step.Status != FlowStepStatusCompleted {
		t.Fatalf("expected completed, got %s", step.Status)
	}

	if step.StartedAt.IsZero() {
		t.Fatal("expected started_at")
	}

	if step.CompletedAt.IsZero() {
		t.Fatal("expected completed_at")
	}
}

func TestDefaultRuntimeE2EOrchestratorSuccess(t *testing.T) {
	planner := &fakeRuntimeFlowPlanner{}
	runner := &fakeRuntimeFlowStepRunner{}
	store := &fakeRuntimeFlowStore{}
	publisher := &fakeRuntimeFlowPublisher{}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(planner, runner, store, publisher)

	result, err := orchestrator.ExecuteRuntimeFlow(context.Background(), validRuntimeFlowRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !planner.called {
		t.Fatal("expected planner to be called")
	}

	if !store.persistCalled {
		t.Fatal("expected persist to be called")
	}

	if len(runner.calledSteps) != 6 {
		t.Fatalf("expected 6 runner calls, got %d", len(runner.calledSteps))
	}

	if !store.completeCalled {
		t.Fatal("expected complete to be called")
	}

	if !publisher.completeCalled {
		t.Fatal("expected completed event to be published")
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.Status != FlowStatusCompleted {
		t.Fatalf("expected completed status, got %s", result.Status)
	}

	if result.StepCount != 6 {
		t.Fatalf("expected step count 6, got %d", result.StepCount)
	}
}

func TestDefaultRuntimeE2EOrchestratorValidationFailure(t *testing.T) {
	planner := &fakeRuntimeFlowPlanner{}
	store := &fakeRuntimeFlowStore{}
	publisher := &fakeRuntimeFlowPublisher{}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(planner, nil, store, publisher)

	req := validRuntimeFlowRequest()
	req.Tenant.TenantID = ""

	_, err := orchestrator.ExecuteRuntimeFlow(context.Background(), req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}

	if planner.called {
		t.Fatal("planner should not be called on validation failure")
	}

	if store.persistCalled || store.completeCalled || store.failCalled {
		t.Fatal("store should not be called on validation failure")
	}

	if publisher.completeCalled || publisher.failCalled {
		t.Fatal("publisher should not be called on validation failure")
	}
}

func TestDefaultRuntimeE2EOrchestratorStoreRequired(t *testing.T) {
	orchestrator := NewDefaultRuntimeE2EOrchestrator(nil, nil, nil, nil)

	_, err := orchestrator.ExecuteRuntimeFlow(context.Background(), validRuntimeFlowRequest())
	if !errors.Is(err, ErrFlowStoreRequired) {
		t.Fatalf("expected ErrFlowStoreRequired, got %v", err)
	}
}

func TestDefaultRuntimeE2EOrchestratorPlannerError(t *testing.T) {
	planner := &fakeRuntimeFlowPlanner{
		err: ErrTransactionKindInvalid,
	}
	store := &fakeRuntimeFlowStore{}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(planner, nil, store, nil)

	_, err := orchestrator.ExecuteRuntimeFlow(context.Background(), validRuntimeFlowRequest())
	if !errors.Is(err, ErrTransactionKindInvalid) {
		t.Fatalf("expected ErrTransactionKindInvalid, got %v", err)
	}

	if !planner.called {
		t.Fatal("expected planner to be called")
	}

	if store.persistCalled {
		t.Fatal("store should not be called when planner fails")
	}
}

func TestDefaultRuntimeE2EOrchestratorPersistError(t *testing.T) {
	store := &fakeRuntimeFlowStore{
		persistErr: ErrFlowPlanRequired,
	}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(nil, nil, store, nil)

	_, err := orchestrator.ExecuteRuntimeFlow(context.Background(), validRuntimeFlowRequest())
	if !errors.Is(err, ErrFlowPlanRequired) {
		t.Fatalf("expected ErrFlowPlanRequired, got %v", err)
	}

	if !store.persistCalled {
		t.Fatal("expected persist to be called")
	}

	if store.completeCalled || store.failCalled {
		t.Fatal("complete/fail should not be called when persist fails")
	}
}

func TestDefaultRuntimeE2EOrchestratorStepErrorMarksFailed(t *testing.T) {
	runner := &fakeRuntimeFlowStepRunner{
		errAtStep: 3,
		err:       ErrFlowStepKindInvalid,
	}
	store := &fakeRuntimeFlowStore{}
	publisher := &fakeRuntimeFlowPublisher{}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(nil, runner, store, publisher)

	_, err := orchestrator.ExecuteRuntimeFlow(context.Background(), validRuntimeFlowRequest())
	if !errors.Is(err, ErrFlowStepKindInvalid) {
		t.Fatalf("expected ErrFlowStepKindInvalid, got %v", err)
	}

	if len(runner.calledSteps) != 3 {
		t.Fatalf("expected 3 runner calls, got %d", len(runner.calledSteps))
	}

	if !store.failCalled {
		t.Fatal("expected flow failed to be marked")
	}

	if !publisher.failCalled {
		t.Fatal("expected failure event to be published")
	}

	if store.completeCalled {
		t.Fatal("complete should not be called when step fails")
	}
}

func TestDefaultRuntimeE2EOrchestratorCompleteError(t *testing.T) {
	store := &fakeRuntimeFlowStore{
		completeErr: ErrFlowStatusInvalid,
	}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(nil, nil, store, nil)

	_, err := orchestrator.ExecuteRuntimeFlow(context.Background(), validRuntimeFlowRequest())
	if !errors.Is(err, ErrFlowStatusInvalid) {
		t.Fatalf("expected ErrFlowStatusInvalid, got %v", err)
	}

	if !store.completeCalled {
		t.Fatal("expected complete to be called")
	}
}

func TestDefaultRuntimeE2EOrchestratorPublisherError(t *testing.T) {
	store := &fakeRuntimeFlowStore{}
	publisher := &fakeRuntimeFlowPublisher{
		completeErr: ErrFlowStatusInvalid,
	}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(nil, nil, store, publisher)

	_, err := orchestrator.ExecuteRuntimeFlow(context.Background(), validRuntimeFlowRequest())
	if !errors.Is(err, ErrFlowStatusInvalid) {
		t.Fatalf("expected ErrFlowStatusInvalid, got %v", err)
	}

	if !store.completeCalled {
		t.Fatal("expected complete before publisher error")
	}

	if !publisher.completeCalled {
		t.Fatal("expected publisher to be called")
	}
}

func TestDefaultRuntimeE2EOrchestratorContextCancelled(t *testing.T) {
	store := &fakeRuntimeFlowStore{}
	publisher := &fakeRuntimeFlowPublisher{}

	orchestrator := NewDefaultRuntimeE2EOrchestrator(nil, nil, store, publisher)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := orchestrator.ExecuteRuntimeFlow(ctx, validRuntimeFlowRequest())
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("expected context.Canceled, got %v", err)
	}

	if store.persistCalled || store.completeCalled || store.failCalled {
		t.Fatal("store should not be called when context cancelled")
	}

	if publisher.completeCalled || publisher.failCalled {
		t.Fatal("publisher should not be called when context cancelled")
	}
}
