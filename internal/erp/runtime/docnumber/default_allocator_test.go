package docnumber

import (
	"context"
	"errors"
	"testing"
)

type fakeDocumentSequenceProvider struct {
	sequence DocumentSequenceSnapshot
	err      error

	called bool
	gotReq AllocateDocumentNumberRequest
}

func (p *fakeDocumentSequenceProvider) FindDocumentSequence(ctx context.Context, req AllocateDocumentNumberRequest) (DocumentSequenceSnapshot, error) {
	p.called = true
	p.gotReq = req

	if p.err != nil {
		return DocumentSequenceSnapshot{}, p.err
	}

	return p.sequence, nil
}

type fakeDocumentNumberAllocationStore struct {
	err error

	called        bool
	gotAllocation DocumentNumberAllocation
}

func (s *fakeDocumentNumberAllocationStore) PersistDocumentNumberAllocation(ctx context.Context, allocation DocumentNumberAllocation) (DocumentNumberAllocation, error) {
	s.called = true
	s.gotAllocation = allocation

	if s.err != nil {
		return DocumentNumberAllocation{}, s.err
	}

	return allocation, nil
}

func TestDefaultDocumentNumberAllocatorSuccess(t *testing.T) {
	provider := &fakeDocumentSequenceProvider{
		sequence: validSequenceSnapshot(),
	}

	store := &fakeDocumentNumberAllocationStore{}

	allocator := NewDefaultDocumentNumberAllocator(provider, store)

	result, err := allocator.AllocateDocumentNumber(context.Background(), validAllocateRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !provider.called {
		t.Fatal("expected provider to be called")
	}

	if !store.called {
		t.Fatal("expected store to be called")
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.DocumentNo != "INV-000001" {
		t.Fatalf("expected document no INV-000001, got %s", result.DocumentNo)
	}

	if result.AllocatedNo != 1 {
		t.Fatalf("expected allocated no 1, got %d", result.AllocatedNo)
	}

	if result.RequestID != "req-123" {
		t.Fatalf("expected request id req-123, got %s", result.RequestID)
	}
}

func TestDefaultDocumentNumberAllocatorValidationFailure(t *testing.T) {
	provider := &fakeDocumentSequenceProvider{
		sequence: validSequenceSnapshot(),
	}

	store := &fakeDocumentNumberAllocationStore{}

	allocator := NewDefaultDocumentNumberAllocator(provider, store)

	req := validAllocateRequest()
	req.TenantID = ""

	_, err := allocator.AllocateDocumentNumber(context.Background(), req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}

	if provider.called {
		t.Fatal("provider should not be called on validation failure")
	}

	if store.called {
		t.Fatal("store should not be called on validation failure")
	}
}

func TestDefaultDocumentNumberAllocatorProviderMissing(t *testing.T) {
	store := &fakeDocumentNumberAllocationStore{}

	allocator := NewDefaultDocumentNumberAllocator(nil, store)

	_, err := allocator.AllocateDocumentNumber(context.Background(), validAllocateRequest())
	if !errors.Is(err, ErrSequenceNotFound) {
		t.Fatalf("expected ErrSequenceNotFound, got %v", err)
	}

	if store.called {
		t.Fatal("store should not be called when provider is missing")
	}
}

func TestDefaultDocumentNumberAllocatorStoreMissing(t *testing.T) {
	provider := &fakeDocumentSequenceProvider{
		sequence: validSequenceSnapshot(),
	}

	allocator := NewDefaultDocumentNumberAllocator(provider, nil)

	_, err := allocator.AllocateDocumentNumber(context.Background(), validAllocateRequest())
	if !errors.Is(err, ErrAllocationStoreRequired) {
		t.Fatalf("expected ErrAllocationStoreRequired, got %v", err)
	}

	if provider.called {
		t.Fatal("provider should not be called when store is missing")
	}
}

func TestDefaultDocumentNumberAllocatorProviderError(t *testing.T) {
	provider := &fakeDocumentSequenceProvider{
		err: ErrSequenceNotFound,
	}

	store := &fakeDocumentNumberAllocationStore{}

	allocator := NewDefaultDocumentNumberAllocator(provider, store)

	_, err := allocator.AllocateDocumentNumber(context.Background(), validAllocateRequest())
	if !errors.Is(err, ErrSequenceNotFound) {
		t.Fatalf("expected ErrSequenceNotFound, got %v", err)
	}

	if !provider.called {
		t.Fatal("expected provider to be called")
	}

	if store.called {
		t.Fatal("store should not be called when provider returns error")
	}
}

func TestDefaultDocumentNumberAllocatorInactiveSequence(t *testing.T) {
	sequence := validSequenceSnapshot()
	sequence.IsActive = false

	provider := &fakeDocumentSequenceProvider{
		sequence: sequence,
	}

	store := &fakeDocumentNumberAllocationStore{}

	allocator := NewDefaultDocumentNumberAllocator(provider, store)

	_, err := allocator.AllocateDocumentNumber(context.Background(), validAllocateRequest())
	if !errors.Is(err, ErrSequenceInactive) {
		t.Fatalf("expected ErrSequenceInactive, got %v", err)
	}

	if store.called {
		t.Fatal("store should not be called when sequence inactive")
	}
}

func TestDefaultDocumentNumberAllocatorLockedSequence(t *testing.T) {
	sequence := validSequenceSnapshot()
	sequence.Status = SequenceStatusLocked

	provider := &fakeDocumentSequenceProvider{
		sequence: sequence,
	}

	store := &fakeDocumentNumberAllocationStore{}

	allocator := NewDefaultDocumentNumberAllocator(provider, store)

	_, err := allocator.AllocateDocumentNumber(context.Background(), validAllocateRequest())
	if !errors.Is(err, ErrSequenceLocked) {
		t.Fatalf("expected ErrSequenceLocked, got %v", err)
	}

	if store.called {
		t.Fatal("store should not be called when sequence locked")
	}
}

func TestDefaultDocumentNumberAllocatorSequenceExhausted(t *testing.T) {
	sequence := validSequenceSnapshot()
	sequence.CurrentNo = 10
	sequence.MaxNo = int64Ptr(10)

	provider := &fakeDocumentSequenceProvider{
		sequence: sequence,
	}

	store := &fakeDocumentNumberAllocationStore{}

	allocator := NewDefaultDocumentNumberAllocator(provider, store)

	_, err := allocator.AllocateDocumentNumber(context.Background(), validAllocateRequest())
	if !errors.Is(err, ErrSequenceExhausted) {
		t.Fatalf("expected ErrSequenceExhausted, got %v", err)
	}

	if store.called {
		t.Fatal("store should not be called when sequence exhausted")
	}
}

func TestDefaultDocumentNumberAllocatorStoreError(t *testing.T) {
	provider := &fakeDocumentSequenceProvider{
		sequence: validSequenceSnapshot(),
	}

	store := &fakeDocumentNumberAllocationStore{
		err: ErrAllocatedNoInvalid,
	}

	allocator := NewDefaultDocumentNumberAllocator(provider, store)

	_, err := allocator.AllocateDocumentNumber(context.Background(), validAllocateRequest())
	if !errors.Is(err, ErrAllocatedNoInvalid) {
		t.Fatalf("expected ErrAllocatedNoInvalid, got %v", err)
	}

	if !store.called {
		t.Fatal("expected store to be called")
	}
}

func TestDefaultDocumentNumberAllocatorContextCancelled(t *testing.T) {
	provider := &fakeDocumentSequenceProvider{
		sequence: validSequenceSnapshot(),
	}

	store := &fakeDocumentNumberAllocationStore{}

	allocator := NewDefaultDocumentNumberAllocator(provider, store)

	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := allocator.AllocateDocumentNumber(ctx, validAllocateRequest())
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("expected context.Canceled, got %v", err)
	}

	if provider.called {
		t.Fatal("provider should not be called when context cancelled")
	}

	if store.called {
		t.Fatal("store should not be called when context cancelled")
	}
}
