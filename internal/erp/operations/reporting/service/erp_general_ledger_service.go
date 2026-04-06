package service

import (
	"sort"
	"time"

	ufkservice "github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/service"
)

type GeneralLedgerRow struct {
	AccountCode  string
	JournalNo    string
	PostingDate  time.Time
	Description  string
	Debit        float64
	Credit       float64
	Balance      float64
}

type GeneralLedgerResult struct {
	AccountCode  string
	Rows         []GeneralLedgerRow
	TotalDebit   float64
	TotalCredit  float64
	EndingBalance float64
}

type GeneralLedgerService struct {
}

func NewGeneralLedgerService() *GeneralLedgerService {
	return &GeneralLedgerService{}
}

func (s *GeneralLedgerService) Generate(
	accountCode string,
	postings []ufkservice.LedgerPosting,
) GeneralLedgerResult {
	filtered := make([]ufkservice.LedgerPosting, 0)

	for _, posting := range postings {
		if posting.AccountCode == accountCode {
			filtered = append(filtered, posting)
		}
	}

	sort.Slice(filtered, func(i, j int) bool {
		if filtered[i].PostingDate.Equal(filtered[j].PostingDate) {
			return filtered[i].JournalNo < filtered[j].JournalNo
		}
		return filtered[i].PostingDate.Before(filtered[j].PostingDate)
	})

	rows := make([]GeneralLedgerRow, 0, len(filtered))

	var runningBalance float64
	var totalDebit float64
	var totalCredit float64

	for _, posting := range filtered {
		runningBalance += posting.Debit
		runningBalance -= posting.Credit

		totalDebit += posting.Debit
		totalCredit += posting.Credit

		rows = append(rows, GeneralLedgerRow{
			AccountCode: accountCode,
			JournalNo:   posting.JournalNo,
			PostingDate: posting.PostingDate,
			Description: posting.Description,
			Debit:       posting.Debit,
			Credit:      posting.Credit,
			Balance:     runningBalance,
		})
	}

	return GeneralLedgerResult{
		AccountCode:   accountCode,
		Rows:          rows,
		TotalDebit:    totalDebit,
		TotalCredit:   totalCredit,
		EndingBalance: runningBalance,
	}
}
