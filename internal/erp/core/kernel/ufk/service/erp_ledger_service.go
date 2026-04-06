package service

import (
	"errors"
	"fmt"
	"time"
)

type LedgerPosting struct {
	JournalNo   string
	AccountCode string
	PostingDate time.Time
	Debit       float64
	Credit      float64
	Description string
}

type LedgerResult struct {
	JournalNo      string
	PostingDate    time.Time
	PostingCount   int
	TotalDebit     float64
	TotalCredit    float64
	LedgerPostings []LedgerPosting
}

type LedgerService struct {
}

func NewLedgerService() *LedgerService {
	return &LedgerService{}
}

func (s *LedgerService) PostValidatedJournal(
	journalResult JournalResult,
) (LedgerResult, error) {
	if journalResult.JournalNo == "" {
		return LedgerResult{}, errors.New("journal number cannot be empty")
	}

	if journalResult.Status != JournalStatusValidated {
		return LedgerResult{}, fmt.Errorf("journal status must be %s", JournalStatusValidated)
	}

	if len(journalResult.Entry.Lines) == 0 {
		return LedgerResult{}, errors.New("validated journal must contain lines")
	}

	postingDate := journalResult.ValidatedAt
	if postingDate.IsZero() {
		postingDate = time.Now()
	}

	postings := make([]LedgerPosting, 0, len(journalResult.Entry.Lines))

	var totalDebit float64
	var totalCredit float64

	for _, line := range journalResult.Entry.Lines {
		posting := LedgerPosting{
			JournalNo:   journalResult.JournalNo,
			AccountCode: line.AccountCode,
			PostingDate: postingDate,
			Debit:       line.Debit,
			Credit:      line.Credit,
			Description: journalResult.Entry.Description,
		}

		postings = append(postings, posting)
		totalDebit += line.Debit
		totalCredit += line.Credit
	}

	if ledgerRound2(totalDebit) != ledgerRound2(totalCredit) {
		return LedgerResult{}, fmt.Errorf(
			"ledger posting not balanced: debit=%.2f credit=%.2f",
			totalDebit,
			totalCredit,
		)
	}

	result := LedgerResult{
		JournalNo:      journalResult.JournalNo,
		PostingDate:    postingDate,
		PostingCount:   len(postings),
		TotalDebit:     ledgerRound2(totalDebit),
		TotalCredit:    ledgerRound2(totalCredit),
		LedgerPostings: postings,
	}

	return result, nil
}

func ledgerRound2(v float64) float64 {
	return float64(int(v*100+0.5)) / 100
}
