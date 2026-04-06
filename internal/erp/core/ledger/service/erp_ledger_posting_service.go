package service

import (
	"fmt"
	"time"

	journaldomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/domain"
	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
)

type LedgerPostingService struct {
}

func NewLedgerPostingService() *LedgerPostingService {
	return &LedgerPostingService{}
}

func (s *LedgerPostingService) BuildFromJournal(
	journal journaldomain.JournalEntry,
) ([]ledgerdomain.LedgerPosting, error) {
	if journal.JournalID == "" {
		return nil, fmt.Errorf("journal id cannot be empty")
	}

	if len(journal.Lines) == 0 {
		return nil, fmt.Errorf("journal lines cannot be empty")
	}

	postings := make([]ledgerdomain.LedgerPosting, 0, len(journal.Lines))

	for i, line := range journal.Lines {
		posting := ledgerdomain.LedgerPosting{
			PostingID:    fmt.Sprintf("%s-%d", journal.JournalID, i+1),
			JournalID:    journal.JournalID,
			EventID:      journal.EventID,
			DocumentNo:   journal.DocumentNo,
			ReferenceID:  journal.ReferenceID,
			SourceModule: journal.SourceModule,
			AccountCode:  line.AccountCode,
			Debit:        line.Debit,
			Credit:       line.Credit,
			PostingDate:  time.Now(),
		}

		postings = append(postings, posting)
	}

	return postings, nil
}
