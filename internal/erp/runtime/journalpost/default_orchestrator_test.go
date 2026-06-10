package journalpost

import (
	"context"
	"errors"
	"testing"
)

type fakeJournalDraftBuilder struct {
	err error

	called bool
	gotReq JournalPostingRequest
}

func (b *fakeJournalDraftBuilder) BuildJournalDraft(ctx context.Context, req JournalPostingRequest) (JournalDraft, error) {
	b.called = true
	b.gotReq = req

	if b.err != nil {
		return JournalDraft{}, b.err
	}

	return BuildJournalDraft(req)
}

type fakeJournalPostingStore struct {
	persistErr error
	markErr    error

	persistCalled bool
	markCalled    bool

	gotPersistDraft JournalDraft
	gotMarkDraft    JournalDraft
}

func (s *fakeJournalPostingStore) PersistJournalDraft(ctx context.Context, draft JournalDraft) (JournalDraft, error) {
	s.persistCalled = true
	s.gotPersistDraft = draft

	if s.persistErr != nil {
		return JournalDraft{}, s.persistErr
	}

	draft.Status = JournalStatusDraft
	return draft, nil
}

func (s *fakeJournalPostingStore) MarkJournalPosted(ctx context.Context, draft JournalDraft) (JournalDraft, error) {
	s.markCalled = true
	s.gotMarkDraft = draft

	if s.markErr != nil {
		return JournalDraft{}, s.markErr
	}

	draft.Status = JournalStatusPosted
	return draft, nil
}

type fakeJournalPostingPublisher struct {
	err error

	called    bool
	gotResult JournalPostingResult
}

func (p *fakeJournalPostingPublisher) PublishJournalPosted(ctx context.Context, result JournalPostingResult) error {
	p.called = true
	p.gotResult = result

	if p.err != nil {
		return p.err
	}

	return nil
}

func TestDefaultJournalDraftBuilderSuccess(t *testing.T) {
	builder := NewDefaultJournalDraftBuilder()

	draft, err := builder.BuildJournalDraft(context.Background(), validJournalPostingRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.JournalNo != "JRNL-2026-000001" {
		t.Fatalf("expected journal no JRNL-2026-000001, got %s", draft.JournalNo)
	}
}

func TestDefaultJournalPostingOrchestratorSuccess(t *testing.T) {
	store := &fakeJournalPostingStore{}
	publisher := &fakeJournalPostingPublisher{}

	orchestrator := NewDefaultJournalPostingOrchestrator(nil, store, publisher)

	result, err := orchestrator.PostJournal(context.Background(), validJournalPostingRequest())
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

	if result.Status != JournalStatusPosted {
		t.Fatalf("expected posted status, got %s", result.Status)
	}

	if result.JournalNo != "JRNL-2026-000001" {
		t.Fatalf("expected journal no JRNL-2026-000001, got %s", result.JournalNo)
	}

	if result.TotalDebit != 120 || result.TotalCredit != 120 {
		t.Fatalf("expected totals 120/120, got %v/%v", result.TotalDebit, result.TotalCredit)
	}

	if publisher.gotResult.JournalNo != result.JournalNo {
		t.Fatalf("expected publisher journal no %s, got %s", result.JournalNo, publisher.gotResult.JournalNo)
	}
}

func TestDefaultJournalPostingOrchestratorValidationFailure(t *testing.T) {
	builder := &fakeJournalDraftBuilder{}
	store := &fakeJournalPostingStore{}
	publisher := &fakeJournalPostingPublisher{}

	orchestrator := NewDefaultJournalPostingOrchestrator(builder, store, publisher)

	req := validJournalPostingRequest()
	req.Tenant.TenantID = ""

	_, err := orchestrator.PostJournal(context.Background(), req)
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

func TestDefaultJournalPostingOrchestratorStoreRequired(t *testing.T) {
	orchestrator := NewDefaultJournalPostingOrchestrator(nil, nil, nil)

	_, err := orchestrator.PostJournal(context.Background(), validJournalPostingRequest())
	if !errors.Is(err, ErrJournalStoreRequired) {
		t.Fatalf("expected ErrJournalStoreRequired, got %v", err)
	}
}

func TestDefaultJournalPostingOrchestratorBuilderError(t *testing.T) {
	builder := &fakeJournalDraftBuilder{
		err: ErrJournalUnbalanced,
	}

	store := &fakeJournalPostingStore{}
	publisher := &fakeJournalPostingPublisher{}

	orchestrator := NewDefaultJournalPostingOrchestrator(builder, store, publisher)

	_, err := orchestrator.PostJournal(context.Background(), validJournalPostingRequest())
	if !errors.Is(err, ErrJournalUnbalanced) {
		t.Fatalf("expected ErrJournalUnbalanced, got %v", err)
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

func TestDefaultJournalPostingOrchestratorPersistError(t *testing.T) {
	store := &fakeJournalPostingStore{
		persistErr: ErrJournalStoreRequired,
	}

	publisher := &fakeJournalPostingPublisher{}

	orchestrator := NewDefaultJournalPostingOrchestrator(nil, store, publisher)

	_, err := orchestrator.PostJournal(context.Background(), validJournalPostingRequest())
	if !errors.Is(err, ErrJournalStoreRequired) {
		t.Fatalf("expected ErrJournalStoreRequired, got %v", err)
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

func TestDefaultJournalPostingOrchestratorMarkError(t *testing.T) {
	store := &fakeJournalPostingStore{
		markErr: ErrJournalStatusInvalid,
	}

	publisher := &fakeJournalPostingPublisher{}

	orchestrator := NewDefaultJournalPostingOrchestrator(nil, store, publisher)

	_, err := orchestrator.PostJournal(context.Background(), validJournalPostingRequest())
	if !errors.Is(err, ErrJournalStatusInvalid) {
		t.Fatalf("expected ErrJournalStatusInvalid, got %v", err)
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

func TestDefaultJournalPostingOrchestratorPublisherError(t *testing.T) {
	store := &fakeJournalPostingStore{}
	publisher := &fakeJournalPostingPublisher{
		err: ErrJournalStatusInvalid,
	}

	orchestrator := NewDefaultJournalPostingOrchestrator(nil, store, publisher)

	_, err := orchestrator.PostJournal(context.Background(), validJournalPostingRequest())
	if !errors.Is(err, ErrJournalStatusInvalid) {
		t.Fatalf("expected ErrJournalStatusInvalid, got %v", err)
	}

	if !store.persistCalled || !store.markCalled {
		t.Fatal("expected store calls before publisher error")
	}

	if !publisher.called {
		t.Fatal("expected publisher to be called")
	}
}

func TestDefaultJournalPostingOrchestratorContextCancelled(t *testing.T) {
	store := &fakeJournalPostingStore{}
	publisher := &fakeJournalPostingPublisher{}

	orchestrator := NewDefaultJournalPostingOrchestrator(nil, store, publisher)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := orchestrator.PostJournal(ctx, validJournalPostingRequest())
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
