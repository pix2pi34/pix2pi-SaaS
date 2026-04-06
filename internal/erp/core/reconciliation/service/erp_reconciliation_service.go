package service

import (
	"fmt"

	ufkservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/service"
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
	ledgerPostings []ufkservice.LedgerPosting,
	externalMovements []ExternalMovement,
) (ReconciliationResult, error) {

	if len(ledgerPostings) == 0 {
		return ReconciliationResult{}, fmt.Errorf("ledger postings cannot be empty")
	}

	matches := make([]ReconciliationMatch, 0)
	matchedCount := 0
	unmatchedCount := 0

	for _, ledger := range ledgerPostings {

		ledgerAmount := ledger.Debit
		if ledgerAmount == 0 {
			ledgerAmount = ledger.Credit
		}

		found := false

		for _, ext := range externalMovements {

			if ledger.AccountCode == ext.AccountCode &&
				reconciliationRound2(ledgerAmount) == reconciliationRound2(ext.Amount) {

				matches = append(matches, ReconciliationMatch{
					AccountCode:    ledger.AccountCode,
					LedgerAmount:   ledgerAmount,
					ExternalAmount: ext.Amount,
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
				LedgerAmount:   ledgerAmount,
				ExternalAmount: 0,
				IsMatched:      false,
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

func reconciliationRound2(v float64) float64 {
	return float64(int(v*100+0.5)) / 100
}
