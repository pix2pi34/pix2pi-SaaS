package service

import (
	"fmt"
	"math"
	"strings"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/domain"
	journaldomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/domain"
	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
)

type FinancialConsistencyResult struct {
	IsConsistent          bool
	EventGrossAmount      float64
	JournalDebitTotal     float64
	JournalCreditTotal    float64
	LedgerDebitTotal      float64
	LedgerCreditTotal     float64
}

type FinancialConsistencyService struct {
}

func NewFinancialConsistencyService() *FinancialConsistencyService {
	return &FinancialConsistencyService{}
}

func (s *FinancialConsistencyService) Check(
	event eventdomain.FinancialEventRecord,
	journal journaldomain.JournalEntry,
	postings []ledgerdomain.LedgerPosting,
) (FinancialConsistencyResult, error) {
	if strings.TrimSpace(event.EventID) == "" {
		return FinancialConsistencyResult{}, fmt.Errorf("event id cannot be empty")
	}
	if strings.TrimSpace(journal.JournalID) == "" {
		return FinancialConsistencyResult{}, fmt.Errorf("journal id cannot be empty")
	}
	if strings.TrimSpace(journal.EventID) == "" {
		return FinancialConsistencyResult{}, fmt.Errorf("journal event id cannot be empty")
	}
	if len(journal.Lines) == 0 {
		return FinancialConsistencyResult{}, fmt.Errorf("journal lines cannot be empty")
	}
	if len(postings) == 0 {
		return FinancialConsistencyResult{}, fmt.Errorf("ledger postings cannot be empty")
	}

	if journal.EventID != event.EventID {
		return FinancialConsistencyResult{}, fmt.Errorf(
			"event mismatch: event=%s journal=%s",
			event.EventID,
			journal.EventID,
		)
	}

	journalDebitTotal := 0.0
	journalCreditTotal := 0.0

	for _, line := range journal.Lines {
		if strings.TrimSpace(line.AccountCode) == "" {
			return FinancialConsistencyResult{}, fmt.Errorf("journal line account code cannot be empty")
		}
		journalDebitTotal += line.Debit
		journalCreditTotal += line.Credit
	}

	ledgerDebitTotal := 0.0
	ledgerCreditTotal := 0.0

	for _, posting := range postings {
		if strings.TrimSpace(posting.JournalID) == "" {
			return FinancialConsistencyResult{}, fmt.Errorf("posting journal id cannot be empty")
		}
		if strings.TrimSpace(posting.EventID) == "" {
			return FinancialConsistencyResult{}, fmt.Errorf("posting event id cannot be empty")
		}
		if posting.JournalID != journal.JournalID {
			return FinancialConsistencyResult{}, fmt.Errorf(
				"posting journal mismatch: expected=%s got=%s",
				journal.JournalID,
				posting.JournalID,
			)
		}
		if posting.EventID != event.EventID {
			return FinancialConsistencyResult{}, fmt.Errorf(
				"posting event mismatch: expected=%s got=%s",
				event.EventID,
				posting.EventID,
			)
		}

		ledgerDebitTotal += posting.Debit
		ledgerCreditTotal += posting.Credit
	}

	if round2(event.GrossAmount) != round2(journalDebitTotal) {
		return FinancialConsistencyResult{}, fmt.Errorf(
			"event gross and journal debit mismatch: gross=%.2f journal_debit=%.2f",
			round2(event.GrossAmount),
			round2(journalDebitTotal),
		)
	}

	if round2(journalDebitTotal) != round2(journalCreditTotal) {
		return FinancialConsistencyResult{}, fmt.Errorf(
			"journal not balanced: debit=%.2f credit=%.2f",
			round2(journalDebitTotal),
			round2(journalCreditTotal),
		)
	}

	if round2(ledgerDebitTotal) != round2(ledgerCreditTotal) {
		return FinancialConsistencyResult{}, fmt.Errorf(
			"ledger not balanced: debit=%.2f credit=%.2f",
			round2(ledgerDebitTotal),
			round2(ledgerCreditTotal),
		)
	}

	if round2(journalDebitTotal) != round2(ledgerDebitTotal) ||
		round2(journalCreditTotal) != round2(ledgerCreditTotal) {
		return FinancialConsistencyResult{}, fmt.Errorf(
			"journal and ledger totals mismatch: journal_debit=%.2f ledger_debit=%.2f journal_credit=%.2f ledger_credit=%.2f",
			round2(journalDebitTotal),
			round2(ledgerDebitTotal),
			round2(journalCreditTotal),
			round2(ledgerCreditTotal),
		)
	}

	return FinancialConsistencyResult{
		IsConsistent:       true,
		EventGrossAmount:   round2(event.GrossAmount),
		JournalDebitTotal:  round2(journalDebitTotal),
		JournalCreditTotal: round2(journalCreditTotal),
		LedgerDebitTotal:   round2(ledgerDebitTotal),
		LedgerCreditTotal:  round2(ledgerCreditTotal),
	}, nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
