package service

import (
	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
)

type AccountBalance struct {
	AccountCode string
	DebitTotal  float64
	CreditTotal float64
	Balance     float64
}

type LedgerBalanceService struct{}

func NewLedgerBalanceService() *LedgerBalanceService {
	return &LedgerBalanceService{}
}

func (s *LedgerBalanceService) Calculate(
	postings []ledgerdomain.LedgerPosting,
) map[string]AccountBalance {

	balances := make(map[string]AccountBalance)

	for _, p := range postings {

		b := balances[p.AccountCode]

		b.AccountCode = p.AccountCode
		b.DebitTotal += p.Debit
		b.CreditTotal += p.Credit
		b.Balance = b.DebitTotal - b.CreditTotal

		balances[p.AccountCode] = b
	}

	return balances
}
