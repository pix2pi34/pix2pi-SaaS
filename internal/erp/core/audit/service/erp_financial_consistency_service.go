package service

import (
	"strings"

	reporting "github.com/divrigili/pix2pi-SaaS/internal/erp/operations/reporting/service"
)

type FinancialConsistencyResult struct {
	JournalBalanced          bool
	TrialBalanceBalanced     bool
	BalanceSheetBalanced     bool
	NoNegativeCashAccounts   bool
	ProfitTransferConsistent bool
	IsConsistent             bool
	Messages                 []string
}

type FinancialConsistencyService struct {
}

func NewFinancialConsistencyService() *FinancialConsistencyService {
	return &FinancialConsistencyService{}
}

func (s *FinancialConsistencyService) Validate(
	journalDebit float64,
	journalCredit float64,
	trialBalance reporting.TrialBalanceResult,
	balanceSheet reporting.BalanceSheetResult,
	netProfit float64,
) FinancialConsistencyResult {

	result := FinancialConsistencyResult{
		Messages: make([]string, 0),
	}

	if round2(journalDebit) == round2(journalCredit) {
		result.JournalBalanced = true
		result.Messages = append(result.Messages, "journal balanced OK")
	}

	if round2(trialBalance.TotalDebit) == round2(trialBalance.TotalCredit) {
		result.TrialBalanceBalanced = true
		result.Messages = append(result.Messages, "trial balance balanced OK")
	}

	if balanceSheet.IsBalanced && round2(balanceSheet.Difference) == 0 {
		result.BalanceSheetBalanced = true
		result.Messages = append(result.Messages, "balance sheet balanced OK")
	}

	for _, row := range balanceSheet.AssetRows {

		if s.isCashLike(row.AccountCode) && row.Amount < 0 {
			result.NoNegativeCashAccounts = false
			result.Messages = append(result.Messages, "negative cash detected")
		}

	}

	if result.NoNegativeCashAccounts {
		result.Messages = append(result.Messages, "cash accounts OK")
	}

	var equityProfit float64

	for _, row := range balanceSheet.EquityRows {

		if row.AccountCode == "CURRENT_PERIOD_PROFIT" {
			equityProfit += row.Amount
		}

	}

	if round2(equityProfit) == round2(netProfit) {

		result.ProfitTransferConsistent = true
		result.Messages = append(result.Messages, "profit transfer OK")

	}

	result.IsConsistent =
		result.JournalBalanced &&
			result.TrialBalanceBalanced &&
			result.BalanceSheetBalanced &&
			result.NoNegativeCashAccounts &&
			result.ProfitTransferConsistent

	return result

}

func (s *FinancialConsistencyService) isCashLike(accountCode string) bool {

	return strings.HasPrefix(accountCode, "100") ||
		strings.HasPrefix(accountCode, "102") ||
		strings.HasPrefix(accountCode, "108")

}

func round2(v float64) float64 {

	return float64(int(v*100+0.5)) / 100

}
