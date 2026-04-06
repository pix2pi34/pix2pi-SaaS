package service

import (
	"fmt"
	"time"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/events/domain"
	journaldomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/journal/domain"
	ruledomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/rules/domain"
)

type JournalBuilderService struct{}

func NewJournalBuilderService() *JournalBuilderService {
	return &JournalBuilderService{}
}

func (s *JournalBuilderService) Build(
	event eventdomain.FinancialEventRecord,
	rule ruledomain.AccountingRule,
) (journaldomain.JournalEntry, error) {

	journalID := fmt.Sprintf(
		"JRNL-%d",
		time.Now().UnixNano(),
	)

	lines := []journaldomain.JournalLine{
		{
			AccountCode: rule.DebitAccount,
			Debit:       event.GrossAmount,
			Credit:      0,
		},
		{
			AccountCode: rule.RevenueAccount,
			Debit:       0,
			Credit:      event.NetAmount,
		},
		{
			AccountCode: rule.TaxAccount,
			Debit:       0,
			Credit:      event.TaxAmount,
		},
	}

	return journaldomain.JournalEntry{
		JournalID:    journalID,
		EventID:      event.EventID,
		DocumentNo:   event.DocumentNo,
		ReferenceID:  event.ReferenceID,
		SourceModule: event.SourceModule,
		CreatedAt:    time.Now(),
		Lines:        lines,
	}, nil
}
