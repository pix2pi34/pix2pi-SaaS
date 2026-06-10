package purchaseinvoice

import (
	"context"
	"errors"
	"testing"
)

type fakePurchaseInvoiceDraftBuilder struct {
	err error

	called bool
	gotReq PurchaseInvoiceRequest
}

func (b *fakePurchaseInvoiceDraftBuilder) BuildPurchaseInvoiceDraft(ctx context.Context, req PurchaseInvoiceRequest) (PurchaseInvoiceDraft, error) {
	b.called = true
	b.gotReq = req

	if b.err != nil {
		return PurchaseInvoiceDraft{}, b.err
	}

	return BuildPurchaseInvoiceDraft(req)
}

type fakePurchaseInvoiceStore struct {
	persistErr error
	markErr    error

	persistCalled bool
	markCalled    bool

	gotPersistDraft PurchaseInvoiceDraft
	gotMarkDraft    PurchaseInvoiceDraft
}

func (s *fakePurchaseInvoiceStore) PersistPurchaseInvoiceDraft(ctx context.Context, draft PurchaseInvoiceDraft) (PurchaseInvoiceDraft, error) {
	s.persistCalled = true
	s.gotPersistDraft = draft

	if s.persistErr != nil {
		return PurchaseInvoiceDraft{}, s.persistErr
	}

	draft.Status = InvoiceStatusDraft
	return draft, nil
}

func (s *fakePurchaseInvoiceStore) MarkPurchaseInvoicePosted(ctx context.Context, draft PurchaseInvoiceDraft) (PurchaseInvoiceDraft, error) {
	s.markCalled = true
	s.gotMarkDraft = draft

	if s.markErr != nil {
		return PurchaseInvoiceDraft{}, s.markErr
	}

	draft.Status = InvoiceStatusPosted
	return draft, nil
}

type fakePurchaseInvoiceTaxCalculator struct {
	err error

	called   bool
	gotDraft PurchaseInvoiceDraft
}

func (c *fakePurchaseInvoiceTaxCalculator) CalculatePurchaseInvoiceTax(ctx context.Context, draft PurchaseInvoiceDraft) (PurchaseInvoiceDraft, error) {
	c.called = true
	c.gotDraft = draft

	if c.err != nil {
		return PurchaseInvoiceDraft{}, c.err
	}

	return draft, nil
}

type fakePurchaseInvoiceJournalPoster struct {
	err error

	called   bool
	gotDraft PurchaseInvoiceDraft
}

func (p *fakePurchaseInvoiceJournalPoster) PostPurchaseInvoiceJournal(ctx context.Context, draft PurchaseInvoiceDraft) error {
	p.called = true
	p.gotDraft = draft

	if p.err != nil {
		return p.err
	}

	return nil
}

type fakePurchaseInvoiceLedgerPoster struct {
	err error

	called   bool
	gotDraft PurchaseInvoiceDraft
}

func (p *fakePurchaseInvoiceLedgerPoster) PostPurchaseInvoiceLedger(ctx context.Context, draft PurchaseInvoiceDraft) error {
	p.called = true
	p.gotDraft = draft

	if p.err != nil {
		return p.err
	}

	return nil
}

type fakePurchaseInvoicePublisher struct {
	err error

	called    bool
	gotResult PurchaseInvoiceResult
}

func (p *fakePurchaseInvoicePublisher) PublishPurchaseInvoicePosted(ctx context.Context, result PurchaseInvoiceResult) error {
	p.called = true
	p.gotResult = result

	if p.err != nil {
		return p.err
	}

	return nil
}

func TestDefaultPurchaseInvoiceDraftBuilderSuccess(t *testing.T) {
	builder := NewDefaultPurchaseInvoiceDraftBuilder()

	draft, err := builder.BuildPurchaseInvoiceDraft(context.Background(), validPurchaseInvoiceRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", draft.TenantID)
	}

	if draft.InvoiceNo != "PINV-2026-000001" {
		t.Fatalf("expected invoice no PINV-2026-000001, got %s", draft.InvoiceNo)
	}

	if draft.Status != InvoiceStatusDraft {
		t.Fatalf("expected draft status, got %s", draft.Status)
	}

	if draft.TotalInvoiceAmount != 120 {
		t.Fatalf("expected total invoice 120, got %v", draft.TotalInvoiceAmount)
	}
}

func TestDefaultPurchaseInvoiceOrchestratorSuccess(t *testing.T) {
	store := &fakePurchaseInvoiceStore{}
	taxCalculator := &fakePurchaseInvoiceTaxCalculator{}
	journalPoster := &fakePurchaseInvoiceJournalPoster{}
	ledgerPoster := &fakePurchaseInvoiceLedgerPoster{}
	publisher := &fakePurchaseInvoicePublisher{}

	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(
		nil,
		store,
		taxCalculator,
		journalPoster,
		ledgerPoster,
		publisher,
	)

	result, err := orchestrator.PostPurchaseInvoice(context.Background(), validPurchaseInvoiceRequest())
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

	if result.InvoiceNo != "PINV-2026-000001" {
		t.Fatalf("expected invoice no PINV-2026-000001, got %s", result.InvoiceNo)
	}

	if result.TotalInvoiceAmount != 120 {
		t.Fatalf("expected total invoice 120, got %v", result.TotalInvoiceAmount)
	}

	if publisher.gotResult.InvoiceNo != result.InvoiceNo {
		t.Fatalf("expected publisher invoice no %s, got %s", result.InvoiceNo, publisher.gotResult.InvoiceNo)
	}
}

func TestDefaultPurchaseInvoiceOrchestratorValidationFailure(t *testing.T) {
	builder := &fakePurchaseInvoiceDraftBuilder{}
	store := &fakePurchaseInvoiceStore{}
	publisher := &fakePurchaseInvoicePublisher{}

	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(builder, store, nil, nil, nil, publisher)

	req := validPurchaseInvoiceRequest()
	req.Tenant.TenantID = ""

	_, err := orchestrator.PostPurchaseInvoice(context.Background(), req)
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

func TestDefaultPurchaseInvoiceOrchestratorStoreRequired(t *testing.T) {
	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(nil, nil, nil, nil, nil, nil)

	_, err := orchestrator.PostPurchaseInvoice(context.Background(), validPurchaseInvoiceRequest())
	if !errors.Is(err, ErrPurchaseInvoiceStoreRequired) {
		t.Fatalf("expected ErrPurchaseInvoiceStoreRequired, got %v", err)
	}
}

func TestDefaultPurchaseInvoiceOrchestratorBuilderError(t *testing.T) {
	builder := &fakePurchaseInvoiceDraftBuilder{
		err: ErrInvoiceTotalInvalid,
	}

	store := &fakePurchaseInvoiceStore{}
	publisher := &fakePurchaseInvoicePublisher{}

	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(builder, store, nil, nil, nil, publisher)

	_, err := orchestrator.PostPurchaseInvoice(context.Background(), validPurchaseInvoiceRequest())
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

func TestDefaultPurchaseInvoiceOrchestratorTaxCalculatorError(t *testing.T) {
	store := &fakePurchaseInvoiceStore{}
	taxCalculator := &fakePurchaseInvoiceTaxCalculator{
		err: ErrTaxRateInvalid,
	}
	publisher := &fakePurchaseInvoicePublisher{}

	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(nil, store, taxCalculator, nil, nil, publisher)

	_, err := orchestrator.PostPurchaseInvoice(context.Background(), validPurchaseInvoiceRequest())
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

func TestDefaultPurchaseInvoiceOrchestratorPersistError(t *testing.T) {
	store := &fakePurchaseInvoiceStore{
		persistErr: ErrPurchaseInvoiceStoreRequired,
	}

	publisher := &fakePurchaseInvoicePublisher{}

	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(nil, store, nil, nil, nil, publisher)

	_, err := orchestrator.PostPurchaseInvoice(context.Background(), validPurchaseInvoiceRequest())
	if !errors.Is(err, ErrPurchaseInvoiceStoreRequired) {
		t.Fatalf("expected ErrPurchaseInvoiceStoreRequired, got %v", err)
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

func TestDefaultPurchaseInvoiceOrchestratorJournalPosterError(t *testing.T) {
	store := &fakePurchaseInvoiceStore{}
	journalPoster := &fakePurchaseInvoiceJournalPoster{
		err: ErrInvoiceStatusInvalid,
	}
	publisher := &fakePurchaseInvoicePublisher{}

	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(nil, store, nil, journalPoster, nil, publisher)

	_, err := orchestrator.PostPurchaseInvoice(context.Background(), validPurchaseInvoiceRequest())
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

func TestDefaultPurchaseInvoiceOrchestratorLedgerPosterError(t *testing.T) {
	store := &fakePurchaseInvoiceStore{}
	ledgerPoster := &fakePurchaseInvoiceLedgerPoster{
		err: ErrInvoiceStatusInvalid,
	}
	publisher := &fakePurchaseInvoicePublisher{}

	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(nil, store, nil, nil, ledgerPoster, publisher)

	_, err := orchestrator.PostPurchaseInvoice(context.Background(), validPurchaseInvoiceRequest())
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

func TestDefaultPurchaseInvoiceOrchestratorMarkError(t *testing.T) {
	store := &fakePurchaseInvoiceStore{
		markErr: ErrInvoiceStatusInvalid,
	}

	publisher := &fakePurchaseInvoicePublisher{}

	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(nil, store, nil, nil, nil, publisher)

	_, err := orchestrator.PostPurchaseInvoice(context.Background(), validPurchaseInvoiceRequest())
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

func TestDefaultPurchaseInvoiceOrchestratorPublisherError(t *testing.T) {
	store := &fakePurchaseInvoiceStore{}
	publisher := &fakePurchaseInvoicePublisher{
		err: ErrInvoiceStatusInvalid,
	}

	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(nil, store, nil, nil, nil, publisher)

	_, err := orchestrator.PostPurchaseInvoice(context.Background(), validPurchaseInvoiceRequest())
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

func TestDefaultPurchaseInvoiceOrchestratorContextCancelled(t *testing.T) {
	store := &fakePurchaseInvoiceStore{}
	publisher := &fakePurchaseInvoicePublisher{}

	orchestrator := NewDefaultPurchaseInvoiceOrchestrator(nil, store, nil, nil, nil, publisher)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := orchestrator.PostPurchaseInvoice(ctx, validPurchaseInvoiceRequest())
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
