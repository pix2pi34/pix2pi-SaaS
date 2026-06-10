package docnumber

import (
	"context"
)

var _ DocumentNumberAllocator = (*DefaultDocumentNumberAllocator)(nil)

type DefaultDocumentNumberAllocator struct {
	provider DocumentSequenceProvider
	store    DocumentNumberAllocationStore
}

func NewDefaultDocumentNumberAllocator(provider DocumentSequenceProvider, store DocumentNumberAllocationStore) *DefaultDocumentNumberAllocator {
	return &DefaultDocumentNumberAllocator{
		provider: provider,
		store:    store,
	}
}

func (a *DefaultDocumentNumberAllocator) AllocateDocumentNumber(ctx context.Context, req AllocateDocumentNumberRequest) (AllocateDocumentNumberResult, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return AllocateDocumentNumberResult{}, ctx.Err()
	default:
	}

	if err := ValidateAllocateDocumentNumberRequest(req); err != nil {
		return AllocateDocumentNumberResult{}, err
	}

	if a.provider == nil {
		return AllocateDocumentNumberResult{}, ErrSequenceNotFound
	}

	if a.store == nil {
		return AllocateDocumentNumberResult{}, ErrAllocationStoreRequired
	}

	sequence, err := a.provider.FindDocumentSequence(ctx, req)
	if err != nil {
		return AllocateDocumentNumberResult{}, err
	}

	allocation, err := BuildDocumentNumberAllocation(req, sequence)
	if err != nil {
		return AllocateDocumentNumberResult{}, err
	}

	persisted, err := a.store.PersistDocumentNumberAllocation(ctx, allocation)
	if err != nil {
		return AllocateDocumentNumberResult{}, err
	}

	return BuildAllocateDocumentNumberResult(req, persisted)
}
