package ledgerpost

import (
	"context"
	"errors"
	"testing"
)

type fakeLedgerPostingDraftBuilder struct {
	err error

	called bool
	gotReq LedgerPostingRequest
}

func (b *fakeLedgerPostingDraftBuilder) BuildLedgerPostingDraft(ctx context.Context, req LedgerPostingRequest) (LedgerPostingDraft, error) {
	b.called = true
	b.gotReq = req

	if b.err != nil {
		return LedgerPostingDraft{}, b.err
	}

	return BuildLedgerPostingDraft(req)
}

type fakeLedgerPostingStore struct {
	persistErr error
	markErr    error

	persistCalled bool
	markCalled    bool

	gotPersistDraft LedgerPostingDraft
	gotMarkDraft    LedgerPostingDraft
}

func (s *fakeLedgerPostingStore) PersistLedgerDraft(ctx context.Context, draft LedgerPostingDraft) (LedgerPostingDraft, error) {
	s.persistCalled = true
	s.gotPersistDraft = draft

	if s.persistErr != nil {
		return LedgerPostingDraft{}, s.persistErr
	}

	draft.Status = LedgerPostingStatusDraft
	return draft, nil
}

func (s *fakeLedgerPostingStore) MarkLedgerPosted(ctx context.Context, draft LedgerPostingDraft) (LedgerPostingDraft, error) {
	s.markCalled = true
	s.gotMarkDraft = draft

	if s.markErr != nil {
		return LedgerPostingDraft{}, s.markErr
	}

	draft.Status = LedgerPostingStatusPosted
	return draft, nil
}

type fakeLedgerPostingPublisher struct {
	err error

	called    bool
	gotResult LedgerPostingResult
}

func (p *fakeLedgerPostingPublisher) PublishLedgerPosted(ctx context.Context, result LedgerPostingResult) error {
	p.called = true
	p.gotResult = result

	if p.err != nil {
		return p.err
	}

	return nil
}

func TestDefaultLedgerPostingDraftBuilderSuccess(t *testing.T) {
	builder := NewDefaultLedgerPostingDraftBuilder()

	draft, err := builder.BuildLedgerPostingDraft(context.Background(), validLedgerPostingRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", draft.TenantID)
	}

	if draft.Status != LedgerPostingStatusDraft {
		t.Fatalf("expected draft status, got %s", draft.Status)
	}

	if len(draft.Movements) != 3 {
		t.Fatalf("expected 3 movements, got %d", len(draft.Movements))
	}
}

func TestDefaultLedgerPostingOrchestratorSuccess(t *testing.T) {
	store := &fakeLedgerPostingStore{}
	publisher := &fakeLedgerPostingPublisher{}

	orchestrator := NewDefaultLedgerPostingOrchestrator(nil, store, publisher)

	result, err := orchestrator.PostLedger(context.Background(), validLedgerPostingRequest())
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

	if result.Status != LedgerPostingStatusPosted {
		t.Fatalf("expected posted status, got %s", result.Status)
	}

	if result.MovementCount != 3 {
		t.Fatalf("expected movement count 3, got %d", result.MovementCount)
	}

	if result.TotalDebit != 120 || result.TotalCredit != 120 {
		t.Fatalf("expected totals 120/120, got %v/%v", result.TotalDebit, result.TotalCredit)
	}

	if publisher.gotResult.JournalNo != result.JournalNo {
		t.Fatalf("expected publisher journal no %s, got %s", result.JournalNo, publisher.gotResult.JournalNo)
	}
}

func TestDefaultLedgerPostingOrchestratorValidationFailure(t *testing.T) {
	builder := &fakeLedgerPostingDraftBuilder{}
	store := &fakeLedgerPostingStore{}
	publisher := &fakeLedgerPostingPublisher{}

	orchestrator := NewDefaultLedgerPostingOrchestrator(builder, store, publisher)

	req := validLedgerPostingRequest()
	req.Tenant.TenantID = ""

	_, err := orchestrator.PostLedger(context.Background(), req)
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

func TestDefaultLedgerPostingOrchestratorStoreRequired(t *testing.T) {
	orchestrator := NewDefaultLedgerPostingOrchestrator(nil, nil, nil)

	_, err := orchestrator.PostLedger(context.Background(), validLedgerPostingRequest())
	if !errors.Is(err, ErrLedgerStoreRequired) {
		t.Fatalf("expected ErrLedgerStoreRequired, got %v", err)
	}
}

func TestDefaultLedgerPostingOrchestratorBuilderError(t *testing.T) {
	builder := &fakeLedgerPostingDraftBuilder{
		err: ErrLedgerUnbalanced,
	}

	store := &fakeLedgerPostingStore{}
	publisher := &fakeLedgerPostingPublisher{}

	orchestrator := NewDefaultLedgerPostingOrchestrator(builder, store, publisher)

	_, err := orchestrator.PostLedger(context.Background(), validLedgerPostingRequest())
	if !errors.Is(err, ErrLedgerUnbalanced) {
		t.Fatalf("expected ErrLedgerUnbalanced, got %v", err)
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

func TestDefaultLedgerPostingOrchestratorPersistError(t *testing.T) {
	store := &fakeLedgerPostingStore{
		persistErr: ErrLedgerStoreRequired,
	}

	publisher := &fakeLedgerPostingPublisher{}

	orchestrator := NewDefaultLedgerPostingOrchestrator(nil, store, publisher)

	_, err := orchestrator.PostLedger(context.Background(), validLedgerPostingRequest())
	if !errors.Is(err, ErrLedgerStoreRequired) {
		t.Fatalf("expected ErrLedgerStoreRequired, got %v", err)
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

func TestDefaultLedgerPostingOrchestratorMarkError(t *testing.T) {
	store := &fakeLedgerPostingStore{
		markErr: ErrLedgerStatusInvalid,
	}

	publisher := &fakeLedgerPostingPublisher{}

	orchestrator := NewDefaultLedgerPostingOrchestrator(nil, store, publisher)

	_, err := orchestrator.PostLedger(context.Background(), validLedgerPostingRequest())
	if !errors.Is(err, ErrLedgerStatusInvalid) {
		t.Fatalf("expected ErrLedgerStatusInvalid, got %v", err)
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

func TestDefaultLedgerPostingOrchestratorPublisherError(t *testing.T) {
	store := &fakeLedgerPostingStore{}
	publisher := &fakeLedgerPostingPublisher{
		err: ErrLedgerStatusInvalid,
	}

	orchestrator := NewDefaultLedgerPostingOrchestrator(nil, store, publisher)

	_, err := orchestrator.PostLedger(context.Background(), validLedgerPostingRequest())
	if !errors.Is(err, ErrLedgerStatusInvalid) {
		t.Fatalf("expected ErrLedgerStatusInvalid, got %v", err)
	}

	if !store.persistCalled || !store.markCalled {
		t.Fatal("expected store calls before publisher error")
	}

	if !publisher.called {
		t.Fatal("expected publisher to be called")
	}
}

func TestDefaultLedgerPostingOrchestratorContextCancelled(t *testing.T) {
	store := &fakeLedgerPostingStore{}
	publisher := &fakeLedgerPostingPublisher{}

	orchestrator := NewDefaultLedgerPostingOrchestrator(nil, store, publisher)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := orchestrator.PostLedger(ctx, validLedgerPostingRequest())
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
