package service

import (
	"sort"

	ufkservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/service"
)

type TrialBalanceRow struct {
	AccountCode  string
	TotalDebit   float64
	TotalCredit  float64
	NetBalance   float64
}

type TrialBalanceResult struct {
	Rows         []TrialBalanceRow
	TotalDebit   float64
	TotalCredit  float64
}

type TrialBalanceService struct {
}

func NewTrialBalanceService() *TrialBalanceService {
	return &TrialBalanceService{}
}

func (s *TrialBalanceService) Generate(
	postings []ufkservice.LedgerPosting,
) TrialBalanceResult {
	rowMap := make(map[string]*TrialBalanceRow)

	var totalDebit float64
	var totalCredit float64

	for _, posting := range postings {
		row, ok := rowMap[posting.AccountCode]
		if !ok {
			row = &TrialBalanceRow{
				AccountCode: posting.AccountCode,
			}
			rowMap[posting.AccountCode] = row
		}

		row.TotalDebit += posting.Debit
		row.TotalCredit += posting.Credit
		row.NetBalance = row.TotalDebit - row.TotalCredit

		totalDebit += posting.Debit
		totalCredit += posting.Credit
	}

	rows := make([]TrialBalanceRow, 0, len(rowMap))
	for _, row := range rowMap {
		rows = append(rows, *row)
	}

	sort.Slice(rows, func(i, j int) bool {
		return rows[i].AccountCode < rows[j].AccountCode
	})

	return TrialBalanceResult{
		Rows:        rows,
		TotalDebit:  totalDebit,
		TotalCredit: totalCredit,
	}
}
