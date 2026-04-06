package service

import (
	"strings"

	ufkservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/service"
)

type CashFlowRow struct {
	AccountCode string
	Inflow      float64
	Outflow     float64
	NetCash     float64
}

type CashFlowResult struct {
	Rows        []CashFlowRow
	TotalInflow float64
	TotalOutflow float64
	NetCashFlow float64
}

type CashFlowService struct {
}

func NewCashFlowService() *CashFlowService {
	return &CashFlowService{}
}

func (s *CashFlowService) Generate(
	postings []ufkservice.LedgerPosting,
) CashFlowResult {
	rowMap := make(map[string]*CashFlowRow)

	var totalInflow float64
	var totalOutflow float64

	for _, posting := range postings {
		if !s.isCashLikeAccount(posting.AccountCode) {
			continue
		}

		row, ok := rowMap[posting.AccountCode]
		if !ok {
			row = &CashFlowRow{
				AccountCode: posting.AccountCode,
			}
			rowMap[posting.AccountCode] = row
		}

		row.Inflow += posting.Debit
		row.Outflow += posting.Credit
		row.NetCash = row.Inflow - row.Outflow

		totalInflow += posting.Debit
		totalOutflow += posting.Credit
	}

	rows := make([]CashFlowRow, 0, len(rowMap))
	for _, row := range rowMap {
		rows = append(rows, *row)
	}

	return CashFlowResult{
		Rows:         rows,
		TotalInflow:  totalInflow,
		TotalOutflow: totalOutflow,
		NetCashFlow:  totalInflow - totalOutflow,
	}
}

func (s *CashFlowService) isCashLikeAccount(accountCode string) bool {
	return strings.HasPrefix(accountCode, "100") ||
		strings.HasPrefix(accountCode, "102") ||
		strings.HasPrefix(accountCode, "108")
}
