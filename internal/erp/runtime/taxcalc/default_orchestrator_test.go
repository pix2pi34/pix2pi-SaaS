package taxcalc

import (
	"context"
	"errors"
	"testing"
)

type fakeTaxDraftBuilder struct {
	err error

	called bool
	gotReq TaxCalculationRequest
}

func (b *fakeTaxDraftBuilder) BuildTaxCalculationDraft(ctx context.Context, req TaxCalculationRequest) (TaxCalculationDraft, error) {
	b.called = true
	b.gotReq = req

	if b.err != nil {
		return TaxCalculationDraft{}, b.err
	}

	return BuildTaxCalculationDraft(req)
}

type fakeTaxStore struct {
	persistErr error
	markErr    error

	persistCalled bool
	markCalled    bool

	gotPersistDraft TaxCalculationDraft
	gotMarkDraft    TaxCalculationDraft
}

func (s *fakeTaxStore) PersistTaxDraft(ctx context.Context, draft TaxCalculationDraft) (TaxCalculationDraft, error) {
	s.persistCalled = true
	s.gotPersistDraft = draft

	if s.persistErr != nil {
		return TaxCalculationDraft{}, s.persistErr
	}

	draft.Status = TaxCalculationStatusDraft
	for i := range draft.Lines {
		draft.Lines[i].Status = TaxCalculationStatusDraft
	}

	return draft, nil
}

func (s *fakeTaxStore) MarkTaxPosted(ctx context.Context, draft TaxCalculationDraft) (TaxCalculationDraft, error) {
	s.markCalled = true
	s.gotMarkDraft = draft

	if s.markErr != nil {
		return TaxCalculationDraft{}, s.markErr
	}

	draft.Status = TaxCalculationStatusPosted
	for i := range draft.Lines {
		draft.Lines[i].Status = TaxCalculationStatusPosted
	}

	return draft, nil
}

type fakeTaxPublisher struct {
	err error

	called    bool
	gotResult TaxCalculationResult
}

func (p *fakeTaxPublisher) PublishTaxCalculated(ctx context.Context, result TaxCalculationResult) error {
	p.called = true
	p.gotResult = result

	if p.err != nil {
		return p.err
	}

	return nil
}

func TestDefaultTaxDraftBuilderSuccess(t *testing.T) {
	builder := NewDefaultTaxDraftBuilder()

	draft, err := builder.BuildTaxCalculationDraft(context.Background(), validTaxCalculationRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", draft.TenantID)
	}

	if draft.Status != TaxCalculationStatusDraft {
		t.Fatalf("expected draft status, got %s", draft.Status)
	}

	if len(draft.Lines) != 1 {
		t.Fatalf("expected 1 line, got %d", len(draft.Lines))
	}

	if draft.TotalTaxAmount != 20 {
		t.Fatalf("expected tax amount 20, got %v", draft.TotalTaxAmount)
	}
}

func TestDefaultTaxOrchestratorSuccess(t *testing.T) {
	store := &fakeTaxStore{}
	publisher := &fakeTaxPublisher{}

	orchestrator := NewDefaultTaxOrchestrator(nil, store, publisher)

	result, err := orchestrator.CalculateTax(context.Background(), validTaxCalculationRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !store.persistCalled {
		t.Fatal("expected persist to be called")
	}

	if !store.markCalled {
		t.Fatal("expected mark posted to be called")
	}

	if !publisher.called {
		t.Fatal("expected publisher to be called")
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.Status != TaxCalculationStatusPosted {
		t.Fatalf("expected posted status, got %s", result.Status)
	}

	if result.TotalBaseAmount != 100 {
		t.Fatalf("expected base amount 100, got %v", result.TotalBaseAmount)
	}

	if result.TotalTaxAmount != 20 {
		t.Fatalf("expected tax amount 20, got %v", result.TotalTaxAmount)
	}

	if result.TotalPayableAmount != 120 {
		t.Fatalf("expected payable 120, got %v", result.TotalPayableAmount)
	}

	if publisher.gotResult.RequestID != result.RequestID {
		t.Fatalf("expected publisher request_id %s, got %s", result.RequestID, publisher.gotResult.RequestID)
	}
}

func TestDefaultTaxOrchestratorValidationFailure(t *testing.T) {
	builder := &fakeTaxDraftBuilder{}
	store := &fakeTaxStore{}
	publisher := &fakeTaxPublisher{}

	orchestrator := NewDefaultTaxOrchestrator(builder, store, publisher)

	req := validTaxCalculationRequest()
	req.Tenant.TenantID = ""

	_, err := orchestrator.CalculateTax(context.Background(), req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}

	if builder.called {
		t.Fatal("builder should not be called on validation failure")
	}

	if store.persistCalled || store.markCalled {
		t.Fatal("store should not be called on validation failure")
	}

	if publisher.called {
		t.Fatal("publisher should not be called on validation failure")
	}
}

func TestDefaultTaxOrchestratorStoreRequired(t *testing.T) {
	orchestrator := NewDefaultTaxOrchestrator(nil, nil, nil)

	_, err := orchestrator.CalculateTax(context.Background(), validTaxCalculationRequest())
	if !errors.Is(err, ErrTaxStoreRequired) {
		t.Fatalf("expected ErrTaxStoreRequired, got %v", err)
	}
}

func TestDefaultTaxOrchestratorBuilderError(t *testing.T) {
	builder := &fakeTaxDraftBuilder{
		err: ErrTaxRateInvalid,
	}

	store := &fakeTaxStore{}
	publisher := &fakeTaxPublisher{}

	orchestrator := NewDefaultTaxOrchestrator(builder, store, publisher)

	_, err := orchestrator.CalculateTax(context.Background(), validTaxCalculationRequest())
	if !errors.Is(err, ErrTaxRateInvalid) {
		t.Fatalf("expected ErrTaxRateInvalid, got %v", err)
	}

	if !builder.called {
		t.Fatal("expected builder to be called")
	}

	if store.persistCalled || store.markCalled {
		t.Fatal("store should not be called when builder fails")
	}

	if publisher.called {
		t.Fatal("publisher should not be called when builder fails")
	}
}

func TestDefaultTaxOrchestratorPersistError(t *testing.T) {
	store := &fakeTaxStore{
		persistErr: ErrTaxStoreRequired,
	}

	publisher := &fakeTaxPublisher{}

	orchestrator := NewDefaultTaxOrchestrator(nil, store, publisher)

	_, err := orchestrator.CalculateTax(context.Background(), validTaxCalculationRequest())
	if !errors.Is(err, ErrTaxStoreRequired) {
		t.Fatalf("expected ErrTaxStoreRequired, got %v", err)
	}

	if !store.persistCalled {
		t.Fatal("expected persist to be called")
	}

	if store.markCalled {
		t.Fatal("mark should not be called when persist fails")
	}

	if publisher.called {
		t.Fatal("publisher should not be called when persist fails")
	}
}

func TestDefaultTaxOrchestratorMarkError(t *testing.T) {
	store := &fakeTaxStore{
		markErr: ErrTaxCalculationStatusInvalid,
	}

	publisher := &fakeTaxPublisher{}

	orchestrator := NewDefaultTaxOrchestrator(nil, store, publisher)

	_, err := orchestrator.CalculateTax(context.Background(), validTaxCalculationRequest())
	if !errors.Is(err, ErrTaxCalculationStatusInvalid) {
		t.Fatalf("expected ErrTaxCalculationStatusInvalid, got %v", err)
	}

	if !store.persistCalled {
		t.Fatal("expected persist to be called")
	}

	if !store.markCalled {
		t.Fatal("expected mark to be called")
	}

	if publisher.called {
		t.Fatal("publisher should not be called when mark fails")
	}
}

func TestDefaultTaxOrchestratorPublisherError(t *testing.T) {
	store := &fakeTaxStore{}
	publisher := &fakeTaxPublisher{
		err: ErrTaxCalculationStatusInvalid,
	}

	orchestrator := NewDefaultTaxOrchestrator(nil, store, publisher)

	_, err := orchestrator.CalculateTax(context.Background(), validTaxCalculationRequest())
	if !errors.Is(err, ErrTaxCalculationStatusInvalid) {
		t.Fatalf("expected ErrTaxCalculationStatusInvalid, got %v", err)
	}

	if !store.persistCalled || !store.markCalled {
		t.Fatal("expected store calls before publisher error")
	}

	if !publisher.called {
		t.Fatal("expected publisher to be called")
	}
}

func TestDefaultTaxOrchestratorContextCancelled(t *testing.T) {
	store := &fakeTaxStore{}
	publisher := &fakeTaxPublisher{}

	orchestrator := NewDefaultTaxOrchestrator(nil, store, publisher)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := orchestrator.CalculateTax(ctx, validTaxCalculationRequest())
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("expected context.Canceled, got %v", err)
	}

	if store.persistCalled || store.markCalled {
		t.Fatal("store should not be called when context cancelled")
	}

	if publisher.called {
		t.Fatal("publisher should not be called when context cancelled")
	}
}
