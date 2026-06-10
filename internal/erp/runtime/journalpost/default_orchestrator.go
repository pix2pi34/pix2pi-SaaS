package journalpost

import (
	"context"
)

var _ JournalPostingOrchestrator = (*DefaultJournalPostingOrchestrator)(nil)
var _ JournalDraftBuilder = (*DefaultJournalDraftBuilder)(nil)

type DefaultJournalDraftBuilder struct{}

func NewDefaultJournalDraftBuilder() *DefaultJournalDraftBuilder {
	return &DefaultJournalDraftBuilder{}
}

func (b *DefaultJournalDraftBuilder) BuildJournalDraft(ctx context.Context, req JournalPostingRequest) (JournalDraft, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return JournalDraft{}, ctx.Err()
	default:
	}

	return BuildJournalDraft(req)
}

type DefaultJournalPostingOrchestrator struct {
	builder   JournalDraftBuilder
	store     JournalPostingStore
	publisher JournalPostingPublisher
}

func NewDefaultJournalPostingOrchestrator(
	builder JournalDraftBuilder,
	store JournalPostingStore,
	publisher JournalPostingPublisher,
) *DefaultJournalPostingOrchestrator {
	if builder == nil {
		builder = NewDefaultJournalDraftBuilder()
	}

	return &DefaultJournalPostingOrchestrator{
		builder:   builder,
		store:     store,
		publisher: publisher,
	}
}

func (o *DefaultJournalPostingOrchestrator) PostJournal(ctx context.Context, req JournalPostingRequest) (JournalPostingResult, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	select {
	case <-ctx.Done():
		return JournalPostingResult{}, ctx.Err()
	default:
	}

	if err := ValidateJournalPostingRequest(req); err != nil {
		return JournalPostingResult{}, err
	}

	if o.store == nil {
		return JournalPostingResult{}, ErrJournalStoreRequired
	}

	draft, err := o.builder.BuildJournalDraft(ctx, req)
	if err != nil {
		return JournalPostingResult{}, err
	}

	persistedDraft, err := o.store.PersistJournalDraft(ctx, draft)
	if err != nil {
		return JournalPostingResult{}, err
	}

	postedDraft, err := o.store.MarkJournalPosted(ctx, persistedDraft)
	if err != nil {
		return JournalPostingResult{}, err
	}

	finalReq := req
	finalReq.JournalNo = postedDraft.JournalNo
	finalReq.Lines = postedDraft.Lines
	finalReq.Description = postedDraft.Description

	result, err := BuildJournalPostingResult(finalReq, JournalStatusPosted, "journal posted")
	if err != nil {
		return JournalPostingResult{}, err
	}

	if o.publisher != nil {
		if err := o.publisher.PublishJournalPosted(ctx, result); err != nil {
			return JournalPostingResult{}, err
		}
	}

	return result, nil
}
