package service

import (
	"github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/domain"
)

type AccountMappingApplyService struct {
	mappingService *AccountMappingService
}

func NewAccountMappingApplyService(
	mappingService *AccountMappingService,
) *AccountMappingApplyService {
	return &AccountMappingApplyService{
		mappingService: mappingService,
	}
}

func (s *AccountMappingApplyService) ApplyToJournalEntry(
	tenantID string,
	entry domain.JournalEntry,
) (domain.JournalEntry, error) {
	mappedLines := make([]domain.JournalLine, 0, len(entry.Lines))

	for _, line := range entry.Lines {
		resolvedCode, err := s.mappingService.ResolveAccountCode(
			tenantID,
			line.AccountCode,
		)
		if err != nil {
			return domain.JournalEntry{}, err
		}

		mappedLines = append(mappedLines, domain.JournalLine{
			AccountCode: resolvedCode,
			Debit:       line.Debit,
			Credit:      line.Credit,
		})
	}

	entry.Lines = mappedLines
	return entry, nil
}
