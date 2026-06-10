package service

import (
	"fmt"
	"math"
	"strings"
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
	if err := s.validateEvent(event); err != nil {
		return journaldomain.JournalEntry{}, err
	}

	if err := s.validateRule(rule); err != nil {
		return journaldomain.JournalEntry{}, err
	}

	lines := []journaldomain.JournalLine{
		{
			AccountCode: rule.DebitAccount,
			Debit:       round2(event.GrossAmount),
			Credit:      0,
		},
		{
			AccountCode: rule.RevenueAccount,
			Debit:       0,
			Credit:      round2(event.NetAmount),
		},
		{
			AccountCode: rule.TaxAccount,
			Debit:       0,
			Credit:      round2(event.TaxAmount),
		},
	}

	entry := journaldomain.JournalEntry{
		JournalID:    s.buildJournalID(event.EventID),
		EventID:      event.EventID,
		DocumentNo:   event.DocumentNo,
		ReferenceID:  event.ReferenceID,
		SourceModule: event.SourceModule,
		CreatedAt:    time.Now(),
		Lines:        lines,
	}

	if err := s.validateEntry(entry); err != nil {
		return journaldomain.JournalEntry{}, err
	}

	return entry, nil
}

func (s *JournalBuilderService) validateEvent(
	event eventdomain.FinancialEventRecord,
) error {
	if strings.TrimSpace(event.EventID) == "" {
		return fmt.Errorf("event id cannot be empty")
	}
	if strings.TrimSpace(event.EventType) == "" {
		return fmt.Errorf("event type cannot be empty")
	}
	if strings.TrimSpace(event.SourceModule) == "" {
		return fmt.Errorf("source module cannot be empty")
	}
	if strings.TrimSpace(event.DocumentNo) == "" {
		return fmt.Errorf("document no cannot be empty")
	}
	if strings.TrimSpace(event.ReferenceID) == "" {
		return fmt.Errorf("reference id cannot be empty")
	}
	if event.GrossAmount <= 0 {
		return fmt.Errorf("gross amount must be greater than zero")
	}
	if event.NetAmount < 0 {
		return fmt.Errorf("net amount cannot be negative")
	}
	if event.TaxAmount < 0 {
		return fmt.Errorf("tax amount cannot be negative")
	}
	if round2(event.NetAmount+event.TaxAmount) != round2(event.GrossAmount) {
		return fmt.Errorf(
			"financial event not balanced: gross=%.2f net=%.2f tax=%.2f",
			event.GrossAmount,
			event.NetAmount,
			event.TaxAmount,
		)
	}

	return nil
}

func (s *JournalBuilderService) validateRule(
	rule ruledomain.AccountingRule,
) error {
	if strings.TrimSpace(rule.RuleID) == "" {
		return fmt.Errorf("rule id cannot be empty")
	}
	if strings.TrimSpace(rule.DebitAccount) == "" {
		return fmt.Errorf("debit account cannot be empty")
	}
	if strings.TrimSpace(rule.RevenueAccount) == "" {
		return fmt.Errorf("revenue account cannot be empty")
	}
	if strings.TrimSpace(rule.TaxAccount) == "" {
		return fmt.Errorf("tax account cannot be empty")
	}

	return nil
}

func (s *JournalBuilderService) validateEntry(
	entry journaldomain.JournalEntry,
) error {
	if strings.TrimSpace(entry.JournalID) == "" {
		return fmt.Errorf("journal id cannot be empty")
	}
	if len(entry.Lines) == 0 {
		return fmt.Errorf("journal lines cannot be empty")
	}

	totalDebit := 0.0
	totalCredit := 0.0

	for _, line := range entry.Lines {
		if strings.TrimSpace(line.AccountCode) == "" {
			return fmt.Errorf("journal line account code cannot be empty")
		}
		if line.Debit < 0 || line.Credit < 0 {
			return fmt.Errorf("journal line %s cannot have negative debit/credit", line.AccountCode)
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
			"journal entry not balanced: debit=%.2f credit=%.2f",
			round2(totalDebit),
			round2(totalCredit),
		)
	}

	return nil
}

func (s *JournalBuilderService) buildJournalID(eventID string) string {
	eventID = strings.TrimSpace(eventID)
	eventID = strings.ReplaceAll(eventID, " ", "_")
	return "JRNL-" + eventID
}

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}
