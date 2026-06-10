package service

import (
	"fmt"
	"math"
	"strings"

	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
)

type ExternalMovement struct {
	Source      string
	AccountCode string
	Amount      float64
	ReferenceID string
}

type ReconciliationMatch struct {
	AccountCode    string
	LedgerAmount   float64
	ExternalAmount float64
	IsMatched      bool
	Source         string
	ReferenceID    string
}

type ReconciliationResult struct {
	MatchedCount   int
	UnmatchedCount int
	Matches        []ReconciliationMatch
}

type ReconciliationService struct {
}

func NewReconciliationService() *ReconciliationService {
	return &ReconciliationService{}
}

func (s *ReconciliationService) Reconcile(
	ledgerPostings []ledgerdomain.LedgerPosting,
	externalMovements []ExternalMovement,
) (ReconciliationResult, error) {
	if len(ledgerPostings) == 0 {
		return ReconciliationResult{}, fmt.Errorf("ledger postings cannot be empty")
	}

	matches := make([]ReconciliationMatch, 0)
	matchedCount := 0
	unmatchedCount := 0

	for _, ledger := range ledgerPostings {
		if strings.TrimSpace(ledger.AccountCode) == "" {
			return ReconciliationResult{}, fmt.Errorf("ledger account code cannot be empty")
		}
		if ledger.Debit < 0 || ledger.Credit < 0 {
			return ReconciliationResult{}, fmt.Errorf("ledger posting %s cannot have negative debit/credit", ledger.AccountCode)
		}
		if ledger.Debit > 0 && ledger.Credit > 0 {
			return ReconciliationResult{}, fmt.Errorf("ledger posting %s cannot have both debit and credit", ledger.AccountCode)
		}
		if ledger.Debit == 0 && ledger.Credit == 0 {
			return ReconciliationResult{}, fmt.Errorf("ledger posting %s cannot be empty", ledger.AccountCode)
		}

		ledgerAmount := ledger.Debit
		if ledgerAmount == 0 {
			ledgerAmount = ledger.Credit
		}

		found := false

		for _, ext := range externalMovements {
			if strings.TrimSpace(ext.AccountCode) == "" {
				return ReconciliationResult{}, fmt.Errorf("external movement account code cannot be empty")
			}

			if ledger.AccountCode == ext.AccountCode &&
				round2(ledgerAmount) == round2(ext.Amount) {
				matches = append(matches, ReconciliationMatch{
					AccountCode:    ledger.AccountCode,
					LedgerAmount:   round2(ledgerAmount),
					ExternalAmount: round2(ext.Amount),
					IsMatched:      true,
					Source:         ext.Source,
					ReferenceID:    ext.ReferenceID,
				})

				matchedCount++
				found = true
				break
			}
		}

		if !found {
			matches = append(matches, ReconciliationMatch{
				AccountCode:    ledger.AccountCode,
				LedgerAmount:   round2(ledgerAmount),
				ExternalAmount: 0,
				IsMatched:      false,
				Source:         "",
				ReferenceID:    ledger.ReferenceID,
			})

			unmatchedCount++
		}
	}

	return ReconciliationResult{
		MatchedCount:   matchedCount,
		UnmatchedCount: unmatchedCount,
		Matches:        matches,
	}, nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
