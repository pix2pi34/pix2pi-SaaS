package salesinvoice

import (
	"context"
	"errors"
	"testing"
)

type fakeSalesInvoiceDraftBuilder struct {
	err error

	called bool
	gotReq SalesInvoiceRequest
}

func (b *fakeSalesInvoiceDraftBuilder) BuildSalesInvoiceDraft(ctx context.Context, req SalesInvoiceRequest) (SalesInvoiceDraft, error) {
	b.called = true
	b.gotReq = req

	if b.err != nil {
		return SalesInvoiceDraft{}, b.err
	}

	return BuildSalesInvoiceDraft(req)
}

type fakeSalesInvoiceStore struct {
	persistErr error
	markErr    error

	persistCalled bool
	markCalled    bool

	gotPersistDraft SalesInvoiceDraft
	gotMarkDraft    SalesInvoiceDraft
}

func (s *fakeSalesInvoiceStore) PersistSalesInvoiceDraft(ctx context.Context, draft SalesInvoiceDraft) (SalesInvoiceDraft, error) {
	s.persistCalled = true
	s.gotPersistDraft = draft

	if s.persistErr != nil {
		return SalesInvoiceDraft{}, s.persistErr
	}

	draft.Status = InvoiceStatusDraft
	return draft, nil
}

func (s *fakeSalesInvoiceStore) MarkSalesInvoicePosted(ctx context.Context, draft SalesInvoiceDraft) (SalesInvoiceDraft, error) {
	s.markCalled = true
	s.gotMarkDraft = draft

	if s.markErr != nil {
		return SalesInvoiceDraft{}, s.markErr
	}

	draft.Status = InvoiceStatusPosted
	return draft, nil
}

type fakeSalesInvoiceTaxCalculator struct {
	err error

	called   bool
	gotDraft SalesInvoiceDraft
}

func (c *fakeSalesInvoiceTaxCalculator) CalculateSalesInvoiceTax(ctx context.Context, draft SalesInvoiceDraft) (SalesInvoiceDraft, error) {
	c.called = true
	c.gotDraft = draft

	if c.err != nil {
		return SalesInvoiceDraft{}, c.err
	}

	return draft, nil
}

type fakeSalesInvoiceJournalPoster struct {
	err error

	called   bool
	gotDraft SalesInvoiceDraft
}

func (p *fakeSalesInvoiceJournalPoster) PostSalesInvoiceJournal(ctx context.Context, draft SalesInvoiceDraft) error {
	p.called = true
	p.gotDraft = draft

	if p.err != nil {
		return p.err
	}

	return nil
}

type fakeSalesInvoiceLedgerPoster struct {
	err error

	called   bool
	gotDraft SalesInvoiceDraft
}

func (p *fakeSalesInvoiceLedgerPoster) PostSalesInvoiceLedger(ctx context.Context, draft SalesInvoiceDraft) error {
	p.called = true
	p.gotDraft = draft

	if p.err != nil {
		return p.err
	}

	return nil
}

type fakeSalesInvoicePublisher struct {
	err error

	called    bool
	gotResult SalesInvoiceResult
}

func (p *fakeSalesInvoicePublisher) PublishSalesInvoicePosted(ctx context.Context, result SalesInvoiceResult) error {
	p.called = true
	p.gotResult = result

	if p.err != nil {
		return p.err
	}

	return nil
}

func TestDefaultSalesInvoiceDraftBuilderSuccess(t *testing.T) {
	builder := NewDefaultSalesInvoiceDraftBuilder()

	draft, err := builder.BuildSalesInvoiceDraft(context.Background(), validSalesInvoiceRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", draft.TenantID)
	}

	if draft.InvoiceNo != "INV-2026-000001" {
		t.Fatalf("expected invoice no INV-2026-000001, got %s", draft.InvoiceNo)
	}

	if draft.Status != InvoiceStatusDraft {
		t.Fatalf("expected draft status, got %s", draft.Status)
	}

	if draft.TotalInvoiceAmount != 120 {
		t.Fatalf("expected total invoice 120, got %v", draft.TotalInvoiceAmount)
	}
}

func TestDefaultSalesInvoiceOrchestratorSuccess(t *testing.T) {
	store := &fakeSalesInvoiceStore{}
	taxCalculator := &fakeSalesInvoiceTaxCalculator{}
	journalPoster := &fakeSalesInvoiceJournalPoster{}
	ledgerPoster := &fakeSalesInvoiceLedgerPoster{}
	publisher := &fakeSalesInvoicePublisher{}

	orchestrator := NewDefaultSalesInvoiceOrchestrator(
		nil,
		store,
		taxCalculator,
		journalPoster,
		ledgerPoster,
		publisher,
	)

	result, err := orchestrator.PostSalesInvoice(context.Background(), validSalesInvoiceRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !taxCalculator.called {
		t.Fatal("expected tax calculator to be called")
	}

	if !store.persistCalled {
		t.Fatal("expected persist to be called")
	}

	if !journalPoster.called {
		t.Fatal("expected journal poster to be called")
	}

	if !ledgerPoster.called {
		t.Fatal("expected ledger poster to be called")
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

	if result.Status != InvoiceStatusPosted {
		t.Fatalf("expected posted status, got %s", result.Status)
	}

	if result.InvoiceNo != "INV-2026-000001" {
		t.Fatalf("expected invoice no INV-2026-000001, got %s", result.InvoiceNo)
	}

	if result.TotalInvoiceAmount != 120 {
		t.Fatalf("expected total invoice 120, got %v", result.TotalInvoiceAmount)
	}

	if publisher.gotResult.InvoiceNo != result.InvoiceNo {
		t.Fatalf("expected publisher invoice no %s, got %s", result.InvoiceNo, publisher.gotResult.InvoiceNo)
	}
}

func TestDefaultSalesInvoiceOrchestratorValidationFailure(t *testing.T) {
	builder := &fakeSalesInvoiceDraftBuilder{}
	store := &fakeSalesInvoiceStore{}
	publisher := &fakeSalesInvoicePublisher{}

	orchestrator := NewDefaultSalesInvoiceOrchestrator(builder, store, nil, nil, nil, publisher)

	req := validSalesInvoiceRequest()
	req.Tenant.TenantID = ""

	_, err := orchestrator.PostSalesInvoice(context.Background(), req)
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

func TestDefaultSalesInvoiceOrchestratorStoreRequired(t *testing.T) {
	orchestrator := NewDefaultSalesInvoiceOrchestrator(nil, nil, nil, nil, nil, nil)

	_, err := orchestrator.PostSalesInvoice(context.Background(), validSalesInvoiceRequest())
	if !errors.Is(err, ErrSalesInvoiceStoreRequired) {
		t.Fatalf("expected ErrSalesInvoiceStoreRequired, got %v", err)
	}
}

func TestDefaultSalesInvoiceOrchestratorBuilderError(t *testing.T) {
	builder := &fakeSalesInvoiceDraftBuilder{
		err: ErrInvoiceTotalInvalid,
	}

	store := &fakeSalesInvoiceStore{}
	publisher := &fakeSalesInvoicePublisher{}

	orchestrator := NewDefaultSalesInvoiceOrchestrator(builder, store, nil, nil, nil, publisher)

	_, err := orchestrator.PostSalesInvoice(context.Background(), validSalesInvoiceRequest())
	if !errors.Is(err, ErrInvoiceTotalInvalid) {
		t.Fatalf("expected ErrInvoiceTotalInvalid, got %v", err)
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

func TestDefaultSalesInvoiceOrchestratorTaxCalculatorError(t *testing.T) {
	store := &fakeSalesInvoiceStore{}
	taxCalculator := &fakeSalesInvoiceTaxCalculator{
		err: ErrTaxRateInvalid,
	}
	publisher := &fakeSalesInvoicePublisher{}

	orchestrator := NewDefaultSalesInvoiceOrchestrator(nil, store, taxCalculator, nil, nil, publisher)

	_, err := orchestrator.PostSalesInvoice(context.Background(), validSalesInvoiceRequest())
	if !errors.Is(err, ErrTaxRateInvalid) {
		t.Fatalf("expected ErrTaxRateInvalid, got %v", err)
	}

	if !taxCalculator.called {
		t.Fatal("expected tax calculator to be called")
	}

	if store.persistCalled || store.markCalled {
		t.Fatal("store should not be called when tax calculator fails")
	}

	if publisher.called {
		t.Fatal("publisher should not be called when tax calculator fails")
	}
}

func TestDefaultSalesInvoiceOrchestratorPersistError(t *testing.T) {
	store := &fakeSalesInvoiceStore{
		persistErr: ErrSalesInvoiceStoreRequired,
	}

	publisher := &fakeSalesInvoicePublisher{}

	orchestrator := NewDefaultSalesInvoiceOrchestrator(nil, store, nil, nil, nil, publisher)

	_, err := orchestrator.PostSalesInvoice(context.Background(), validSalesInvoiceRequest())
	if !errors.Is(err, ErrSalesInvoiceStoreRequired) {
		t.Fatalf("expected ErrSalesInvoiceStoreRequired, got %v", err)
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

func TestDefaultSalesInvoiceOrchestratorJournalPosterError(t *testing.T) {
	store := &fakeSalesInvoiceStore{}
	journalPoster := &fakeSalesInvoiceJournalPoster{
		err: ErrInvoiceStatusInvalid,
	}
	publisher := &fakeSalesInvoicePublisher{}

	orchestrator := NewDefaultSalesInvoiceOrchestrator(nil, store, nil, journalPoster, nil, publisher)

	_, err := orchestrator.PostSalesInvoice(context.Background(), validSalesInvoiceRequest())
	if !errors.Is(err, ErrInvoiceStatusInvalid) {
		t.Fatalf("expected ErrInvoiceStatusInvalid, got %v", err)
	}

	if !store.persistCalled {
		t.Fatal("expected persist to be called")
	}

	if !journalPoster.called {
		t.Fatal("expected journal poster to be called")
	}

	if store.markCalled {
		t.Fatal("mark should not be called when journal poster fails")
	}

	if publisher.called {
		t.Fatal("publisher should not be called when journal poster fails")
	}
}

func TestDefaultSalesInvoiceOrchestratorLedgerPosterError(t *testing.T) {
	store := &fakeSalesInvoiceStore{}
	ledgerPoster := &fakeSalesInvoiceLedgerPoster{
		err: ErrInvoiceStatusInvalid,
	}
	publisher := &fakeSalesInvoicePublisher{}

	orchestrator := NewDefaultSalesInvoiceOrchestrator(nil, store, nil, nil, ledgerPoster, publisher)

	_, err := orchestrator.PostSalesInvoice(context.Background(), validSalesInvoiceRequest())
	if !errors.Is(err, ErrInvoiceStatusInvalid) {
		t.Fatalf("expected ErrInvoiceStatusInvalid, got %v", err)
	}

	if !store.persistCalled {
		t.Fatal("expected persist to be called")
	}

	if !ledgerPoster.called {
		t.Fatal("expected ledger poster to be called")
	}

	if store.markCalled {
		t.Fatal("mark should not be called when ledger poster fails")
	}

	if publisher.called {
		t.Fatal("publisher should not be called when ledger poster fails")
	}
}

func TestDefaultSalesInvoiceOrchestratorMarkError(t *testing.T) {
	store := &fakeSalesInvoiceStore{
		markErr: ErrInvoiceStatusInvalid,
	}

	publisher := &fakeSalesInvoicePublisher{}

	orchestrator := NewDefaultSalesInvoiceOrchestrator(nil, store, nil, nil, nil, publisher)

	_, err := orchestrator.PostSalesInvoice(context.Background(), validSalesInvoiceRequest())
	if !errors.Is(err, ErrInvoiceStatusInvalid) {
		t.Fatalf("expected ErrInvoiceStatusInvalid, got %v", err)
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

func TestDefaultSalesInvoiceOrchestratorPublisherError(t *testing.T) {
	store := &fakeSalesInvoiceStore{}
	publisher := &fakeSalesInvoicePublisher{
		err: ErrInvoiceStatusInvalid,
	}

	orchestrator := NewDefaultSalesInvoiceOrchestrator(nil, store, nil, nil, nil, publisher)

	_, err := orchestrator.PostSalesInvoice(context.Background(), validSalesInvoiceRequest())
	if !errors.Is(err, ErrInvoiceStatusInvalid) {
		t.Fatalf("expected ErrInvoiceStatusInvalid, got %v", err)
	}

	if !store.persistCalled || !store.markCalled {
		t.Fatal("expected store calls before publisher error")
	}

	if !publisher.called {
		t.Fatal("expected publisher to be called")
	}
}

func TestDefaultSalesInvoiceOrchestratorContextCancelled(t *testing.T) {
	store := &fakeSalesInvoiceStore{}
	publisher := &fakeSalesInvoicePublisher{}

	orchestrator := NewDefaultSalesInvoiceOrchestrator(nil, store, nil, nil, nil, publisher)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := orchestrator.PostSalesInvoice(ctx, validSalesInvoiceRequest())
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
