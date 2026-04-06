package service

import (
	"sort"

	financeservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/finance/service"
	ufkservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/service"
)

type BalanceSheetRow struct {
	AccountCode string
	AccountType string
	Amount      float64
}

type BalanceSheetResult struct {
	AssetRows        []BalanceSheetRow
	LiabilityRows    []BalanceSheetRow
	EquityRows       []BalanceSheetRow
	TotalAssets      float64
	TotalLiabilities float64
	TotalEquity      float64
	IsBalanced       bool
	Difference       float64
}

type BalanceSheetService struct {
	chartIntelligenceService *financeservice.ChartIntelligenceService
}

func NewBalanceSheetService(
	chartIntelligenceService *financeservice.ChartIntelligenceService,
) *BalanceSheetService {
	return &BalanceSheetService{
		chartIntelligenceService: chartIntelligenceService,
	}
}

func (s *BalanceSheetService) Generate(
	postings []ufkservice.LedgerPosting,
	periodProfit float64,
) (BalanceSheetResult, error) {
	amountMap := make(map[string]float64)

	for _, posting := range postings {
		intel, err := s.chartIntelligenceService.AnalyzeAccountCode(posting.AccountCode)
		if err != nil {
			return BalanceSheetResult{}, err
		}

		if intel.ReportGroup != financeservice.ReportGroupBalanceSheet {
			continue
		}

		switch intel.AccountType {
		case financeservice.AccountTypeAsset:
			amountMap[posting.AccountCode] += posting.Debit
			amountMap[posting.AccountCode] -= posting.Credit

		case financeservice.AccountTypeLiability, financeservice.AccountTypeEquity, financeservice.AccountTypeTax:
			amountMap[posting.AccountCode] += posting.Credit
			amountMap[posting.AccountCode] -= posting.Debit
		}
	}

	assetRows := make([]BalanceSheetRow, 0)
	liabilityRows := make([]BalanceSheetRow, 0)
	equityRows := make([]BalanceSheetRow, 0)

	var totalAssets float64
	var totalLiabilities float64
	var totalEquity float64

	for accountCode, amount := range amountMap {
		intel, err := s.chartIntelligenceService.AnalyzeAccountCode(accountCode)
		if err != nil {
			return BalanceSheetResult{}, err
		}

		row := BalanceSheetRow{
			AccountCode: accountCode,
			AccountType: intel.AccountType,
			Amount:      amount,
		}

		switch intel.AccountType {
		case financeservice.AccountTypeAsset:
			assetRows = append(assetRows, row)
			totalAssets += amount

		case financeservice.AccountTypeLiability, financeservice.AccountTypeTax:
			liabilityRows = append(liabilityRows, row)
			totalLiabilities += amount

		case financeservice.AccountTypeEquity:
			equityRows = append(equityRows, row)
			totalEquity += amount
		}
	}

	if periodProfit != 0 {
		equityRows = append(equityRows, BalanceSheetRow{
			AccountCode: "CURRENT_PERIOD_PROFIT",
			AccountType: financeservice.AccountTypeEquity,
			Amount:      periodProfit,
		})
		totalEquity += periodProfit
	}

	sort.Slice(assetRows, func(i, j int) bool {
		return assetRows[i].AccountCode < assetRows[j].AccountCode
	})

	sort.Slice(liabilityRows, func(i, j int) bool {
		return liabilityRows[i].AccountCode < liabilityRows[j].AccountCode
	})

	sort.Slice(equityRows, func(i, j int) bool {
		return equityRows[i].AccountCode < equityRows[j].AccountCode
	})

	rightSide := totalLiabilities + totalEquity
	diff := totalAssets - rightSide

	return BalanceSheetResult{
		AssetRows:        assetRows,
		LiabilityRows:    liabilityRows,
		EquityRows:       equityRows,
		TotalAssets:      totalAssets,
		TotalLiabilities: totalLiabilities,
		TotalEquity:      totalEquity,
		IsBalanced:       balanceSheetRound2(diff) == 0,
		Difference:       balanceSheetRound2(diff),
	}, nil
}

func balanceSheetRound2(v float64) float64 {
	return float64(int(v*100+0.5)) / 100
}
