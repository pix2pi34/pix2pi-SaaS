package docnumber

import "context"

type DocumentNumberAllocator interface {
	AllocateDocumentNumber(ctx context.Context, req AllocateDocumentNumberRequest) (AllocateDocumentNumberResult, error)
}

type DocumentSequenceProvider interface {
	FindDocumentSequence(ctx context.Context, req AllocateDocumentNumberRequest) (DocumentSequenceSnapshot, error)
}

type DocumentNumberAllocationStore interface {
	PersistDocumentNumberAllocation(ctx context.Context, allocation DocumentNumberAllocation) (DocumentNumberAllocation, error)
}
