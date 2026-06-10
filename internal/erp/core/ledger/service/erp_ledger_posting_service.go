package service

import (
	"fmt"
	"math"
	"strings"

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
	if strings.TrimSpace(journal.JournalID) == "" {
		return nil, fmt.Errorf("journal id cannot be empty")
	}

	if strings.TrimSpace(journal.EventID) == "" {
		return nil, fmt.Errorf("event id cannot be empty")
	}

	if len(journal.Lines) == 0 {
		return nil, fmt.Errorf("journal lines cannot be empty")
	}

	postings := make([]ledgerdomain.LedgerPosting, 0, len(journal.Lines))
	seenPostingIDs := make(map[string]struct{})

	totalDebit := 0.0
	totalCredit := 0.0

	for i, line := range journal.Lines {
		if strings.TrimSpace(line.AccountCode) == "" {
			return nil, fmt.Errorf("journal line account code cannot be empty")
		}
		if line.Debit < 0 || line.Credit < 0 {
			return nil, fmt.Errorf("journal line %s cannot have negative debit/credit", line.AccountCode)
		}
		if line.Debit > 0 && line.Credit > 0 {
			return nil, fmt.Errorf("journal line %s cannot have both debit and credit", line.AccountCode)
		}
		if line.Debit == 0 && line.Credit == 0 {
			return nil, fmt.Errorf("journal line %s cannot be empty", line.AccountCode)
		}

		postingID := fmt.Sprintf("%s-%d", journal.JournalID, i+1)
		if _, exists := seenPostingIDs[postingID]; exists {
			return nil, fmt.Errorf("duplicate posting id: %s", postingID)
		}
		seenPostingIDs[postingID] = struct{}{}

		posting := ledgerdomain.LedgerPosting{
			PostingID:    postingID,
			JournalID:    journal.JournalID,
			EventID:      journal.EventID,
			DocumentNo:   journal.DocumentNo,
			ReferenceID:  journal.ReferenceID,
			SourceModule: journal.SourceModule,
			AccountCode:  line.AccountCode,
			Debit:        round2(line.Debit),
			Credit:       round2(line.Credit),
		}

		postings = append(postings, posting)

		totalDebit += line.Debit
		totalCredit += line.Credit
	}

	if round2(totalDebit) != round2(totalCredit) {
		return nil, fmt.Errorf(
			"ledger posting not balanced: debit=%.2f credit=%.2f",
			round2(totalDebit),
			round2(totalCredit),
		)
	}

	return postings, nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
