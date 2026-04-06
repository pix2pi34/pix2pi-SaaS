package service

import (
	"encoding/csv"
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/domain"
)

type ChartOfAccountsImportService struct {
	chartService *ChartOfAccountsService
}

func NewChartOfAccountsImportService(
	chartService *ChartOfAccountsService,
) *ChartOfAccountsImportService {
	return &ChartOfAccountsImportService{
		chartService: chartService,
	}
}

func (s *ChartOfAccountsImportService) ImportCSV(filePath string) (int, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return 0, fmt.Errorf("failed to open csv file: %w", err)
	}
	defer file.Close()

	reader := csv.NewReader(file)
	reader.TrimLeadingSpace = true

	rows, err := reader.ReadAll()
	if err != nil {
		return 0, fmt.Errorf("failed to read csv file: %w", err)
	}

	if len(rows) < 2 {
		return 0, fmt.Errorf("csv must contain header and at least one data row")
	}

	importedCount := 0

	for i, row := range rows {
		if i == 0 {
			continue
		}

		if len(row) < 6 {
			return importedCount, fmt.Errorf("row %d must have 6 columns", i+1)
		}

		account, err := s.parseRow(row)
		if err != nil {
			return importedCount, fmt.Errorf("row %d parse error: %w", i+1, err)
		}

		if err := s.chartService.AddCompanyAccount(account); err != nil {
			return importedCount, fmt.Errorf("row %d add error: %w", i+1, err)
		}

		importedCount++
	}

	return importedCount, nil
}

func (s *ChartOfAccountsImportService) parseRow(row []string) (domain.Account, error) {
	code := strings.TrimSpace(row[0])
	name := strings.TrimSpace(row[1])
	parentCode := strings.TrimSpace(row[2])

	level, err := strconv.Atoi(strings.TrimSpace(row[3]))
	if err != nil {
		return domain.Account{}, fmt.Errorf("invalid level: %w", err)
	}

	isLeaf, err := strconv.ParseBool(strings.TrimSpace(row[4]))
	if err != nil {
		return domain.Account{}, fmt.Errorf("invalid is_leaf: %w", err)
	}

	isSystem, err := strconv.ParseBool(strings.TrimSpace(row[5]))
	if err != nil {
		return domain.Account{}, fmt.Errorf("invalid is_system: %w", err)
	}

	if code == "" {
		return domain.Account{}, fmt.Errorf("code cannot be empty")
	}

	if name == "" {
		return domain.Account{}, fmt.Errorf("name cannot be empty")
	}

	return domain.Account{
		Code:       code,
		Name:       name,
		ParentCode: parentCode,
		Level:      level,
		IsLeaf:     isLeaf,
		IsSystem:   isSystem,
	}, nil
}
