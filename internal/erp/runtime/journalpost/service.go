package journalpost

import "context"

type JournalPostingOrchestrator interface {
	PostJournal(ctx context.Context, req JournalPostingRequest) (JournalPostingResult, error)
}

type JournalDraftBuilder interface {
	BuildJournalDraft(ctx context.Context, req JournalPostingRequest) (JournalDraft, error)
}

type JournalPostingStore interface {
	PersistJournalDraft(ctx context.Context, draft JournalDraft) (JournalDraft, error)
	MarkJournalPosted(ctx context.Context, draft JournalDraft) (JournalDraft, error)
}

type JournalPostingPublisher interface {
	PublishJournalPosted(ctx context.Context, result JournalPostingResult) error
}
