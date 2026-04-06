package service

import (
	"sort"

	financeservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/finance/service"
	ufkservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/service"
)

type IncomeStatementRow struct {
	AccountCode string
	AccountType string
	Amount      float64
}

type IncomeStatementResult struct {
	RevenueRows  []IncomeStatementRow
	ExpenseRows  []IncomeStatementRow
	CostRows     []IncomeStatementRow
	TotalRevenue float64
	TotalExpense float64
	TotalCost    float64
	NetProfit    float64
}

type IncomeStatementService struct {
	chartIntelligenceService *financeservice.ChartIntelligenceService
}

func NewIncomeStatementService(
	chartIntelligenceService *financeservice.ChartIntelligenceService,
) *IncomeStatementService {
	return &IncomeStatementService{
		chartIntelligenceService: chartIntelligenceService,
	}
}

func (s *IncomeStatementService) Generate(
	postings []ufkservice.LedgerPosting,
) (IncomeStatementResult, error) {
	amountMap := make(map[string]float64)

	for _, posting := range postings {
		intel, err := s.chartIntelligenceService.AnalyzeAccountCode(posting.AccountCode)
		if err != nil {
			return IncomeStatementResult{}, err
		}

		if intel.ReportGroup != financeservice.ReportGroupIncomeStatement {
			continue
		}

		amountMap[posting.AccountCode] += posting.Credit
		amountMap[posting.AccountCode] -= posting.Debit
	}

	revenueRows := make([]IncomeStatementRow, 0)
	expenseRows := make([]IncomeStatementRow, 0)
	costRows := make([]IncomeStatementRow, 0)

	var totalRevenue float64
	var totalExpense float64
	var totalCost float64

	for accountCode, amount := range amountMap {
		intel, err := s.chartIntelligenceService.AnalyzeAccountCode(accountCode)
		if err != nil {
			return IncomeStatementResult{}, err
		}

		row := IncomeStatementRow{
			AccountCode: accountCode,
			AccountType: intel.AccountType,
			Amount:      amount,
		}

		switch intel.AccountType {
		case financeservice.AccountTypeRevenue:
			revenueRows = append(revenueRows, row)
			totalRevenue += amount

		case financeservice.AccountTypeExpense:
			expenseRows = append(expenseRows, row)
			totalExpense += -amount

		case financeservice.AccountTypeCost:
			costRows = append(costRows, row)
			totalCost += -amount
		}
	}

	sort.Slice(revenueRows, func(i, j int) bool {
		return revenueRows[i].AccountCode < revenueRows[j].AccountCode
	})

	sort.Slice(expenseRows, func(i, j int) bool {
		return expenseRows[i].AccountCode < expenseRows[j].AccountCode
	})

	sort.Slice(costRows, func(i, j int) bool {
		return costRows[i].AccountCode < costRows[j].AccountCode
	})

	netProfit := totalRevenue - totalExpense - totalCost

	return IncomeStatementResult{
		RevenueRows:  revenueRows,
		ExpenseRows:  expenseRows,
		CostRows:     costRows,
		TotalRevenue: totalRevenue,
		TotalExpense: totalExpense,
		TotalCost:    totalCost,
		NetProfit:    netProfit,
	}, nil
}
