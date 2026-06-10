package cashbankpay

import (
	"context"
	"errors"
	"testing"
)

type fakePaymentDraftBuilder struct {
	err error

	called bool
	gotReq PaymentRequest
}

func (b *fakePaymentDraftBuilder) BuildPaymentDraft(ctx context.Context, req PaymentRequest) (PaymentDraft, error) {
	b.called = true
	b.gotReq = req

	if b.err != nil {
		return PaymentDraft{}, b.err
	}

	return BuildPaymentDraft(req)
}

type fakePaymentStore struct {
	persistErr error
	markErr    error

	persistCalled bool
	markCalled    bool

	gotPersistDraft PaymentDraft
	gotMarkDraft    PaymentDraft
}

func (s *fakePaymentStore) PersistPaymentDraft(ctx context.Context, draft PaymentDraft) (PaymentDraft, error) {
	s.persistCalled = true
	s.gotPersistDraft = draft

	if s.persistErr != nil {
		return PaymentDraft{}, s.persistErr
	}

	draft.Status = PaymentStatusDraft
	for i := range draft.Movements {
		draft.Movements[i].Status = PaymentStatusDraft
	}

	return draft, nil
}

func (s *fakePaymentStore) MarkPaymentPosted(ctx context.Context, draft PaymentDraft) (PaymentDraft, error) {
	s.markCalled = true
	s.gotMarkDraft = draft

	if s.markErr != nil {
		return PaymentDraft{}, s.markErr
	}

	draft.Status = PaymentStatusPosted
	for i := range draft.Movements {
		draft.Movements[i].Status = PaymentStatusPosted
	}

	return draft, nil
}

type fakePaymentPublisher struct {
	err error

	called    bool
	gotResult PaymentResult
}

func (p *fakePaymentPublisher) PublishPaymentPosted(ctx context.Context, result PaymentResult) error {
	p.called = true
	p.gotResult = result

	if p.err != nil {
		return p.err
	}

	return nil
}

func TestDefaultPaymentDraftBuilderSuccess(t *testing.T) {
	builder := NewDefaultPaymentDraftBuilder()

	draft, err := builder.BuildPaymentDraft(context.Background(), validPaymentRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", draft.TenantID)
	}

	if draft.PaymentNo != "PAY-2026-000001" {
		t.Fatalf("expected payment no PAY-2026-000001, got %s", draft.PaymentNo)
	}

	if draft.Status != PaymentStatusDraft {
		t.Fatalf("expected draft status, got %s", draft.Status)
	}

	if len(draft.Movements) != 1 {
		t.Fatalf("expected 1 movement, got %d", len(draft.Movements))
	}
}

func TestDefaultPaymentOrchestratorSuccess(t *testing.T) {
	store := &fakePaymentStore{}
	publisher := &fakePaymentPublisher{}

	orchestrator := NewDefaultPaymentOrchestrator(nil, store, publisher)

	result, err := orchestrator.PostPayment(context.Background(), validPaymentRequest())
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

	if result.Status != PaymentStatusPosted {
		t.Fatalf("expected posted status, got %s", result.Status)
	}

	if result.PaymentNo != "PAY-2026-000001" {
		t.Fatalf("expected payment no PAY-2026-000001, got %s", result.PaymentNo)
	}

	if result.SignedAmount != 120 {
		t.Fatalf("expected signed amount 120, got %v", result.SignedAmount)
	}

	if publisher.gotResult.PaymentNo != result.PaymentNo {
		t.Fatalf("expected publisher payment no %s, got %s", result.PaymentNo, publisher.gotResult.PaymentNo)
	}
}

func TestDefaultPaymentOrchestratorValidationFailure(t *testing.T) {
	builder := &fakePaymentDraftBuilder{}
	store := &fakePaymentStore{}
	publisher := &fakePaymentPublisher{}

	orchestrator := NewDefaultPaymentOrchestrator(builder, store, publisher)

	req := validPaymentRequest()
	req.Tenant.TenantID = ""

	_, err := orchestrator.PostPayment(context.Background(), req)
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

func TestDefaultPaymentOrchestratorStoreRequired(t *testing.T) {
	orchestrator := NewDefaultPaymentOrchestrator(nil, nil, nil)

	_, err := orchestrator.PostPayment(context.Background(), validPaymentRequest())
	if !errors.Is(err, ErrPaymentStoreRequired) {
		t.Fatalf("expected ErrPaymentStoreRequired, got %v", err)
	}
}

func TestDefaultPaymentOrchestratorBuilderError(t *testing.T) {
	builder := &fakePaymentDraftBuilder{
		err: ErrAmountInvalid,
	}

	store := &fakePaymentStore{}
	publisher := &fakePaymentPublisher{}

	orchestrator := NewDefaultPaymentOrchestrator(builder, store, publisher)

	_, err := orchestrator.PostPayment(context.Background(), validPaymentRequest())
	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
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

func TestDefaultPaymentOrchestratorPersistError(t *testing.T) {
	store := &fakePaymentStore{
		persistErr: ErrPaymentStoreRequired,
	}

	publisher := &fakePaymentPublisher{}

	orchestrator := NewDefaultPaymentOrchestrator(nil, store, publisher)

	_, err := orchestrator.PostPayment(context.Background(), validPaymentRequest())
	if !errors.Is(err, ErrPaymentStoreRequired) {
		t.Fatalf("expected ErrPaymentStoreRequired, got %v", err)
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

func TestDefaultPaymentOrchestratorMarkError(t *testing.T) {
	store := &fakePaymentStore{
		markErr: ErrPaymentStatusInvalid,
	}

	publisher := &fakePaymentPublisher{}

	orchestrator := NewDefaultPaymentOrchestrator(nil, store, publisher)

	_, err := orchestrator.PostPayment(context.Background(), validPaymentRequest())
	if !errors.Is(err, ErrPaymentStatusInvalid) {
		t.Fatalf("expected ErrPaymentStatusInvalid, got %v", err)
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

func TestDefaultPaymentOrchestratorPublisherError(t *testing.T) {
	store := &fakePaymentStore{}
	publisher := &fakePaymentPublisher{
		err: ErrPaymentStatusInvalid,
	}

	orchestrator := NewDefaultPaymentOrchestrator(nil, store, publisher)

	_, err := orchestrator.PostPayment(context.Background(), validPaymentRequest())
	if !errors.Is(err, ErrPaymentStatusInvalid) {
		t.Fatalf("expected ErrPaymentStatusInvalid, got %v", err)
	}

	if !store.persistCalled || !store.markCalled {
		t.Fatal("expected store calls before publisher error")
	}

	if !publisher.called {
		t.Fatal("expected publisher to be called")
	}
}

func TestDefaultPaymentOrchestratorContextCancelled(t *testing.T) {
	store := &fakePaymentStore{}
	publisher := &fakePaymentPublisher{}

	orchestrator := NewDefaultPaymentOrchestrator(nil, store, publisher)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := orchestrator.PostPayment(ctx, validPaymentRequest())
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
