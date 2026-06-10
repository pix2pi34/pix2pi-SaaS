package e2eflow

import (
	"context"
	"errors"
	"testing"
)

type fakeDocumentPort struct {
	err    error
	called bool
}

func (p *fakeDocumentPort) PersistDocument(ctx context.Context, plan RuntimeFlowPlan) error {
	p.called = true
	return p.err
}

type fakeTaxPort struct {
	err    error
	called bool
}

func (p *fakeTaxPort) CalculateTax(ctx context.Context, plan RuntimeFlowPlan) error {
	p.called = true
	return p.err
}

type fakeCashBankPort struct {
	err    error
	called bool
}

func (p *fakeCashBankPort) ExecuteCashBankPayment(ctx context.Context, plan RuntimeFlowPlan) error {
	p.called = true
	return p.err
}

type fakeJournalPort struct {
	err    error
	called bool
}

func (p *fakeJournalPort) PostJournal(ctx context.Context, plan RuntimeFlowPlan) error {
	p.called = true
	return p.err
}

type fakeLedgerPort struct {
	err    error
	called bool
}

func (p *fakeLedgerPort) PostLedger(ctx context.Context, plan RuntimeFlowPlan) error {
	p.called = true
	return p.err
}

type fakePublisherPort struct {
	err    error
	called bool
}

func (p *fakePublisherPort) PublishRuntimeEvent(ctx context.Context, plan RuntimeFlowPlan) error {
	p.called = true
	return p.err
}

func validRuntimeFlowPlanForAdapterTest(t *testing.T) RuntimeFlowPlan {
	t.Helper()

	plan, err := BuildRuntimeFlowPlan(validRuntimeFlowRequest())
	if err != nil {
		t.Fatalf("build plan: %v", err)
	}

	return plan
}

func TestValidateRequestStepAdapterSuccess(t *testing.T) {
	plan := validRuntimeFlowPlanForAdapterTest(t)

	adapter := NewValidateRequestStepAdapter()

	step := RuntimeFlowStep{
		StepNo: 1,
		Kind:   FlowStepValidateRequest,
		Status: FlowStepStatusPending,
	}

	completedStep, err := adapter.ExecuteStep(context.Background(), plan, step)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if completedStep.Status != FlowStepStatusCompleted {
		t.Fatalf("expected completed, got %s", completedStep.Status)
	}

	if completedStep.Message != "request validated" {
		t.Fatalf("expected request validated, got %s", completedStep.Message)
	}
}

func TestPersistDocumentStepAdapterSuccess(t *testing.T) {
	plan := validRuntimeFlowPlanForAdapterTest(t)
	port := &fakeDocumentPort{}

	adapter := NewPersistDocumentStepAdapter(port)

	step := RuntimeFlowStep{
		StepNo: 2,
		Kind:   FlowStepPersistDocument,
		Status: FlowStepStatusPending,
	}

	completedStep, err := adapter.ExecuteStep(context.Background(), plan, step)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !port.called {
		t.Fatal("expected document port to be called")
	}

	if completedStep.Status != FlowStepStatusCompleted {
		t.Fatalf("expected completed, got %s", completedStep.Status)
	}
}

func TestPersistDocumentStepAdapterRequired(t *testing.T) {
	plan := validRuntimeFlowPlanForAdapterTest(t)

	adapter := NewPersistDocumentStepAdapter(nil)

	step := RuntimeFlowStep{
		StepNo: 2,
		Kind:   FlowStepPersistDocument,
		Status: FlowStepStatusPending,
	}

	_, err := adapter.ExecuteStep(context.Background(), plan, step)
	if !errors.Is(err, ErrDocumentAdapterRequired) {
		t.Fatalf("expected ErrDocumentAdapterRequired, got %v", err)
	}
}

func TestCalculateTaxStepAdapterSuccess(t *testing.T) {
	plan := validRuntimeFlowPlanForAdapterTest(t)
	port := &fakeTaxPort{}

	adapter := NewCalculateTaxStepAdapter(port)

	step := RuntimeFlowStep{
		StepNo: 3,
		Kind:   FlowStepCalculateTax,
		Status: FlowStepStatusPending,
	}

	_, err := adapter.ExecuteStep(context.Background(), plan, step)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !port.called {
		t.Fatal("expected tax port to be called")
	}
}

func TestCashBankPaymentStepAdapterSuccess(t *testing.T) {
	plan := validRuntimeFlowPlanForAdapterTest(t)
	port := &fakeCashBankPort{}

	adapter := NewCashBankPaymentStepAdapter(port)

	step := RuntimeFlowStep{
		StepNo: 2,
		Kind:   FlowStepCashBankPayment,
		Status: FlowStepStatusPending,
	}

	_, err := adapter.ExecuteStep(context.Background(), plan, step)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !port.called {
		t.Fatal("expected cashbank port to be called")
	}
}

func TestPostJournalStepAdapterSuccess(t *testing.T) {
	plan := validRuntimeFlowPlanForAdapterTest(t)
	port := &fakeJournalPort{}

	adapter := NewPostJournalStepAdapter(port)

	step := RuntimeFlowStep{
		StepNo: 4,
		Kind:   FlowStepPostJournal,
		Status: FlowStepStatusPending,
	}

	_, err := adapter.ExecuteStep(context.Background(), plan, step)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !port.called {
		t.Fatal("expected journal port to be called")
	}
}

func TestPostLedgerStepAdapterSuccess(t *testing.T) {
	plan := validRuntimeFlowPlanForAdapterTest(t)
	port := &fakeLedgerPort{}

	adapter := NewPostLedgerStepAdapter(port)

	step := RuntimeFlowStep{
		StepNo: 5,
		Kind:   FlowStepPostLedger,
		Status: FlowStepStatusPending,
	}

	_, err := adapter.ExecuteStep(context.Background(), plan, step)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !port.called {
		t.Fatal("expected ledger port to be called")
	}
}

func TestPublishEventStepAdapterSuccess(t *testing.T) {
	plan := validRuntimeFlowPlanForAdapterTest(t)
	port := &fakePublisherPort{}

	adapter := NewPublishEventStepAdapter(port)

	step := RuntimeFlowStep{
		StepNo: 6,
		Kind:   FlowStepPublishEvent,
		Status: FlowStepStatusPending,
	}

	_, err := adapter.ExecuteStep(context.Background(), plan, step)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !port.called {
		t.Fatal("expected publisher port to be called")
	}
}

func TestRuntimeStepAdapterRegistryRegistersAllAdapters(t *testing.T) {
	registry, err := NewRuntimeStepAdapterRegistry(RuntimeStepAdapterPorts{
		Document:  &fakeDocumentPort{},
		Tax:       &fakeTaxPort{},
		CashBank:  &fakeCashBankPort{},
		Journal:   &fakeJournalPort{},
		Ledger:    &fakeLedgerPort{},
		Publisher: &fakePublisherPort{},
	})
	if err != nil {
		t.Fatalf("expected registry success, got %v", err)
	}

	requiredKinds := []FlowStepKind{
		FlowStepValidateRequest,
		FlowStepPersistDocument,
		FlowStepCalculateTax,
		FlowStepCashBankPayment,
		FlowStepPostJournal,
		FlowStepPostLedger,
		FlowStepPublishEvent,
	}

	for _, kind := range requiredKinds {
		adapter, err := registry.AdapterFor(kind)
		if err != nil {
			t.Fatalf("expected adapter for %s, got %v", kind, err)
		}

		if adapter.StepKind() != kind {
			t.Fatalf("expected adapter kind %s, got %s", kind, adapter.StepKind())
		}
	}
}

func TestRuntimeStepAdapterRunnerWithRegistrySuccess(t *testing.T) {
	req := validRuntimeFlowRequest()

	plan, err := BuildRuntimeFlowPlan(req)
	if err != nil {
		t.Fatalf("build plan: %v", err)
	}

	document := &fakeDocumentPort{}
	tax := &fakeTaxPort{}
	journal := &fakeJournalPort{}
	ledger := &fakeLedgerPort{}
	publisher := &fakePublisherPort{}

	registry, err := NewRuntimeStepAdapterRegistry(RuntimeStepAdapterPorts{
		Document:  document,
		Tax:       tax,
		CashBank:  &fakeCashBankPort{},
		Journal:   journal,
		Ledger:    ledger,
		Publisher: publisher,
	})
	if err != nil {
		t.Fatalf("registry: %v", err)
	}

	runner := NewAdapterRuntimeFlowStepRunner(registry, nil, true)

	for _, step := range plan.Steps {
		completedStep, err := runner.RunStep(context.Background(), plan, step)
		if err != nil {
			t.Fatalf("run step %s: %v", step.Kind, err)
		}

		if completedStep.Status != FlowStepStatusCompleted {
			t.Fatalf("expected completed step, got %s", completedStep.Status)
		}
	}

	if !document.called {
		t.Fatal("expected document adapter to be called")
	}

	if !tax.called {
		t.Fatal("expected tax adapter to be called")
	}

	if !journal.called {
		t.Fatal("expected journal adapter to be called")
	}

	if !ledger.called {
		t.Fatal("expected ledger adapter to be called")
	}

	if !publisher.called {
		t.Fatal("expected publisher adapter to be called")
	}
}
