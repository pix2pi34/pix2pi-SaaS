package service

import (
	"fmt"
	"strings"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/domain"
)

type TaxApplyService struct {
}

func NewTaxApplyService() *TaxApplyService {
	return &TaxApplyService{}
}

func (s *TaxApplyService) ApplyTaxAccountToJournalEntry(
	entry domain.JournalEntry,
	taxAccountCode string,
) (domain.JournalEntry, error) {
	if taxAccountCode == "" {
		return domain.JournalEntry{}, fmt.Errorf("tax account code cannot be empty")
	}

	found := false
	lines := make([]domain.JournalLine, 0, len(entry.Lines))

	for _, line := range entry.Lines {
		if s.isTaxLine(line.AccountCode) {
			line.AccountCode = taxAccountCode
			found = true
		}

		lines = append(lines, line)
	}

	if !found {
		return domain.JournalEntry{}, fmt.Errorf("no tax line found in journal entry")
	}

	entry.Lines = lines
	return entry, nil
}

func (s *TaxApplyService) isTaxLine(accountCode string) bool {
	return accountCode == "191" ||
		accountCode == "391" ||
		strings.HasPrefix(accountCode, "191.") ||
		strings.HasPrefix(accountCode, "391.")
}
