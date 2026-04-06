package service

import (
	"fmt"
	"strings"
)

const (
	AccountTypeAsset      = "asset"
	AccountTypeLiability  = "liability"
	AccountTypeEquity     = "equity"
	AccountTypeRevenue    = "revenue"
	AccountTypeExpense    = "expense"
	AccountTypeCost       = "cost"
	AccountTypeTax        = "tax"
	AccountTypeUnknown    = "unknown"

	ReportGroupBalanceSheet    = "balance_sheet"
	ReportGroupIncomeStatement = "income_statement"
	ReportGroupUnknown         = "unknown"

	NormalBalanceDebit  = "debit"
	NormalBalanceCredit = "credit"
	NormalBalanceUnknown = "unknown"
)

type AccountIntelligence struct {
	AccountCode    string
	MainGroup      string
	AccountType    string
	ReportGroup    string
	NormalBalance  string
}

type ChartIntelligenceService struct {
}

func NewChartIntelligenceService() *ChartIntelligenceService {
	return &ChartIntelligenceService{}
}

func (s *ChartIntelligenceService) AnalyzeAccountCode(
	accountCode string,
) (AccountIntelligence, error) {
	if strings.TrimSpace(accountCode) == "" {
		return AccountIntelligence{}, fmt.Errorf("account code cannot be empty")
	}

	mainGroup := s.extractMainGroup(accountCode)

	accountType := s.detectAccountType(mainGroup, accountCode)
	reportGroup := s.detectReportGroup(accountType)
	normalBalance := s.detectNormalBalance(accountType)

	return AccountIntelligence{
		AccountCode:   accountCode,
		MainGroup:     mainGroup,
		AccountType:   accountType,
		ReportGroup:   reportGroup,
		NormalBalance: normalBalance,
	}, nil
}

func (s *ChartIntelligenceService) extractMainGroup(accountCode string) string {
	parts := strings.Split(accountCode, ".")
	if len(parts) == 0 {
		return ""
	}

	code := parts[0]
	if len(code) == 0 {
		return ""
	}

	return string(code[0])
}

func (s *ChartIntelligenceService) detectAccountType(
	mainGroup string,
	accountCode string,
) string {
	if strings.HasPrefix(accountCode, "191") || strings.HasPrefix(accountCode, "391") || strings.HasPrefix(accountCode, "360") {
		return AccountTypeTax
	}

	switch mainGroup {
	case "1", "2":
		return AccountTypeAsset
	case "3", "4":
		return AccountTypeLiability
	case "5":
		return AccountTypeEquity
	case "6":
		return AccountTypeRevenue
	case "7":
		if strings.HasPrefix(accountCode, "710") ||
			strings.HasPrefix(accountCode, "720") ||
			strings.HasPrefix(accountCode, "730") ||
			strings.HasPrefix(accountCode, "740") {
			return AccountTypeCost
		}
		return AccountTypeExpense
	default:
		return AccountTypeUnknown
	}
}

func (s *ChartIntelligenceService) detectReportGroup(
	accountType string,
) string {
	switch accountType {
	case AccountTypeAsset, AccountTypeLiability, AccountTypeEquity, AccountTypeTax:
		return ReportGroupBalanceSheet
	case AccountTypeRevenue, AccountTypeExpense, AccountTypeCost:
		return ReportGroupIncomeStatement
	default:
		return ReportGroupUnknown
	}
}

func (s *ChartIntelligenceService) detectNormalBalance(
	accountType string,
) string {
	switch accountType {
	case AccountTypeAsset, AccountTypeExpense, AccountTypeCost:
		return NormalBalanceDebit
	case AccountTypeLiability, AccountTypeEquity, AccountTypeRevenue, AccountTypeTax:
		return NormalBalanceCredit
	default:
		return NormalBalanceUnknown
	}
}
