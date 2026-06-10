package journal

import "context"

type JournalRepository interface {
	CreateJournalEntry(ctx context.Context, input CreateJournalEntryInput) (JournalEntry, error)
	CreateJournalLine(ctx context.Context, input CreateJournalLineInput) (JournalLine, error)
	GetJournalEntryByID(ctx context.Context, tenantID string, journalEntryID string) (JournalEntry, error)
	ListJournalEntries(ctx context.Context, tenantID string, filter ListJournalEntriesFilter) ([]JournalEntry, error)
	ListJournalLines(ctx context.Context, tenantID string, journalEntryID string) ([]JournalLine, error)
}

type ListJournalEntriesFilter struct {
	SourceModule       JournalSourceModule
	SourceDocumentType string
	SourceDocumentID   string
	Status             JournalStatus
	Query              string
	Limit              int
	Offset             int
}

type JournalPostingRepository interface {
	MarkJournalPosted(ctx context.Context, tenantID string, journalEntryID string, postedBy string) (JournalEntry, error)
	MarkJournalCancelled(ctx context.Context, tenantID string, journalEntryID string, updatedBy string) (JournalEntry, error)
	MarkJournalReversed(ctx context.Context, tenantID string, journalEntryID string, reversalJournalEntryID string, reversedBy string) (JournalEntry, error)
}
