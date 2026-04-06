package service

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/domain"
)

const (
	JournalStatusDraft     = "draft"
	JournalStatusValidated = "validated"
)

type JournalResult struct {
	JournalNo   string
	Status      string
	Entry       domain.JournalEntry
	ValidatedAt time.Time
}

type JournalService struct {
}

func NewJournalService() *JournalService {
	return &JournalService{}
}

func (s *JournalService) PrepareJournalEntry(
	entry domain.JournalEntry,
) (JournalResult, error) {
	if err := s.validateEntry(entry); err != nil {
		return JournalResult{}, err
	}

	journalNo := s.generateJournalNo(entry.CreatedAt, entry.ID)

	result := JournalResult{
		JournalNo:   journalNo,
		Status:      JournalStatusValidated,
		Entry:       entry,
		ValidatedAt: time.Now(),
	}

	return result, nil
}

func (s *JournalService) validateEntry(
	entry domain.JournalEntry,
) error {
	if strings.TrimSpace(entry.ID) == "" {
		return errors.New("journal entry id cannot be empty")
	}

	if strings.TrimSpace(entry.Description) == "" {
		return errors.New("journal entry description cannot be empty")
	}

	if entry.CreatedAt.IsZero() {
		return errors.New("journal entry createdAt cannot be zero")
	}

	if len(entry.Lines) == 0 {
		return errors.New("journal entry must contain lines")
	}

	var totalDebit float64
	var totalCredit float64

	for _, line := range entry.Lines {
		if strings.TrimSpace(line.AccountCode) == "" {
			return errors.New("journal line account code cannot be empty")
		}

		if line.Debit < 0 || line.Credit < 0 {
			return fmt.Errorf("journal line %s has negative debit/credit", line.AccountCode)
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
			totalDebit,
			totalCredit,
		)
	}

	return nil
}

func (s *JournalService) generateJournalNo(
	createdAt time.Time,
	entryID string,
) string {
	datePart := createdAt.Format("20060102")
	safeID := strings.ReplaceAll(entryID, "-", "")
	return fmt.Sprintf("JRNL-%s-%s", datePart, safeID)
}

func round2(v float64) float64 {
	return float64(int(v*100+0.5)) / 100
}
