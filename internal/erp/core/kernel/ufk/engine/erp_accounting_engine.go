package engine

import (
	"errors"
	"fmt"
	"math"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/domain"
)

const (
	EventTypeSaleInvoiceCreated = "SaleInvoiceCreated"
	DefaultSalesAccountCode     = "600"
	DefaultReceivableCode       = "120"
	DefaultOutputVAT20Code      = "391.01.20"
)

type AccountingEngine struct {
}

func NewAccountingEngine() *AccountingEngine {
	return &AccountingEngine{}
}

func (e *AccountingEngine) GenerateJournalEntry(
	event domain.FinancialEvent,
) (domain.JournalEntry, error) {
	switch event.Type {
	case EventTypeSaleInvoiceCreated:
		return e.generateSaleInvoiceJournalEntry(event)
	default:
		return domain.JournalEntry{}, fmt.Errorf("unsupported financial event type: %s", event.Type)
	}
}

func (e *AccountingEngine) generateSaleInvoiceJournalEntry(
	event domain.FinancialEvent,
) (domain.JournalEntry, error) {
	if event.Amount <= 0 {
		return domain.JournalEntry{}, errors.New("event amount must be greater than zero")
	}

	netAmount := round2(event.Amount / 1.20)
	taxAmount := round2(event.Amount - netAmount)

	entry := domain.JournalEntry{
		ID:          event.ID,
		Description: fmt.Sprintf("Auto journal for %s", event.Type),
		CreatedAt:   event.OccurredAt,
		Lines: []domain.JournalLine{
			{
				AccountCode: DefaultReceivableCode,
				Debit:       round2(event.Amount),
				Credit:      0,
			},
			{
				AccountCode: DefaultSalesAccountCode,
				Debit:       0,
				Credit:      netAmount,
			},
			{
				AccountCode: DefaultOutputVAT20Code,
				Debit:       0,
				Credit:      taxAmount,
			},
		},
	}

	if err := e.ValidateJournalEntry(entry); err != nil {
		return domain.JournalEntry{}, err
	}

	return entry, nil
}

func (e *AccountingEngine) ValidateJournalEntry(
	entry domain.JournalEntry,
) error {
	if len(entry.Lines) == 0 {
		return errors.New("journal entry must have at least one line")
	}

	var totalDebit float64
	var totalCredit float64

	for _, line := range entry.Lines {
		if line.AccountCode == "" {
			return errors.New("journal line account code cannot be empty")
		}

		if line.Debit < 0 || line.Credit < 0 {
			return errors.New("journal line debit/credit cannot be negative")
		}

		if line.Debit > 0 && line.Credit > 0 {
			return fmt.Errorf("journal line %s cannot have both debit and credit", line.AccountCode)
		}

		if line.Debit == 0 && line.Credit == 0 {
			return fmt.Errorf("journal line %s cannot be empty", line.AccountCode)
		}

		totalDebit += line.Debit
		totalCredit += line.Credit
	}

	if round2(totalDebit) != round2(totalCredit) {
		return fmt.Errorf(
			"journal entry is not balanced: debit=%.2f credit=%.2f",
			totalDebit,
			totalCredit,
		)
	}

	return nil
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
