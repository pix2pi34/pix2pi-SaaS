package ledgerpost

import "context"

type LedgerPostingOrchestrator interface {
	PostLedger(ctx context.Context, req LedgerPostingRequest) (LedgerPostingResult, error)
}

type LedgerPostingDraftBuilder interface {
	BuildLedgerPostingDraft(ctx context.Context, req LedgerPostingRequest) (LedgerPostingDraft, error)
}

type LedgerPostingStore interface {
	PersistLedgerDraft(ctx context.Context, draft LedgerPostingDraft) (LedgerPostingDraft, error)
	MarkLedgerPosted(ctx context.Context, draft LedgerPostingDraft) (LedgerPostingDraft, error)
}

type LedgerPostingPublisher interface {
	PublishLedgerPosted(ctx context.Context, result LedgerPostingResult) error
}
