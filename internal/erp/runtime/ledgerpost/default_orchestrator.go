package ledgerpost

import (
	"context"
)

var _ LedgerPostingOrchestrator = (*DefaultLedgerPostingOrchestrator)(nil)
var _ LedgerPostingDraftBuilder = (*DefaultLedgerPostingDraftBuilder)(nil)

type DefaultLedgerPostingDraftBuilder struct{}

func NewDefaultLedgerPostingDraftBuilder() *DefaultLedgerPostingDraftBuilder {
	return &DefaultLedgerPostingDraftBuilder{}
}

func (b *DefaultLedgerPostingDraftBuilder) BuildLedgerPostingDraft(ctx context.Context, req LedgerPostingRequest) (LedgerPostingDraft, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return LedgerPostingDraft{}, ctx.Err()
	default:
	}

	return BuildLedgerPostingDraft(req)
}

type DefaultLedgerPostingOrchestrator struct {
	builder   LedgerPostingDraftBuilder
	store     LedgerPostingStore
	publisher LedgerPostingPublisher
}

func NewDefaultLedgerPostingOrchestrator(
	builder LedgerPostingDraftBuilder,
	store LedgerPostingStore,
	publisher LedgerPostingPublisher,
) *DefaultLedgerPostingOrchestrator {
	if builder == nil {
		builder = NewDefaultLedgerPostingDraftBuilder()
	}

	return &DefaultLedgerPostingOrchestrator{
		builder:   builder,
		store:     store,
		publisher: publisher,
	}
}

func (o *DefaultLedgerPostingOrchestrator) PostLedger(ctx context.Context, req LedgerPostingRequest) (LedgerPostingResult, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return LedgerPostingResult{}, ctx.Err()
	default:
	}

	if err := ValidateLedgerPostingRequest(req); err != nil {
		return LedgerPostingResult{}, err
	}

	if o.store == nil {
		return LedgerPostingResult{}, ErrLedgerStoreRequired
	}

	draft, err := o.builder.BuildLedgerPostingDraft(ctx, req)
	if err != nil {
		return LedgerPostingResult{}, err
	}

	persistedDraft, err := o.store.PersistLedgerDraft(ctx, draft)
	if err != nil {
		return LedgerPostingResult{}, err
	}

	postedDraft, err := o.store.MarkLedgerPosted(ctx, persistedDraft)
	if err != nil {
		return LedgerPostingResult{}, err
	}

	result, err := BuildLedgerPostingResult(req, postedDraft, "ledger posted")
	if err != nil {
		return LedgerPostingResult{}, err
	}

	if o.publisher != nil {
		if err := o.publisher.PublishLedgerPosted(ctx, result); err != nil {
			return LedgerPostingResult{}, err
		}
	}

	return result, nil
}
