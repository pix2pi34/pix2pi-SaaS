package service

import (
	"fmt"
	"sort"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/core/kernel/ufk/domain"
)

type ChartOfAccountsService struct {
	accounts map[string]domain.Account
}

func NewChartOfAccountsService() *ChartOfAccountsService {
	s := &ChartOfAccountsService{
		accounts: make(map[string]domain.Account),
	}

	s.seedCoreAccounts()

	return s
}

func (s *ChartOfAccountsService) seedCoreAccounts() {
	coreAccounts := []domain.Account{
		{Code: "100", Name: "Kasa", ParentCode: "", Level: 1, IsLeaf: false, IsSystem: true},
		{Code: "102", Name: "Bankalar", ParentCode: "", Level: 1, IsLeaf: false, IsSystem: true},
		{Code: "120", Name: "Alicilar", ParentCode: "", Level: 1, IsLeaf: false, IsSystem: true},
		{Code: "153", Name: "Ticari Mallar", ParentCode: "", Level: 1, IsLeaf: false, IsSystem: true},
		{Code: "191", Name: "Indirilecek KDV", ParentCode: "", Level: 1, IsLeaf: false, IsSystem: true},
		{Code: "320", Name: "Saticilar", ParentCode: "", Level: 1, IsLeaf: false, IsSystem: true},
		{Code: "360", Name: "Odenecek Vergi ve Fonlar", ParentCode: "", Level: 1, IsLeaf: false, IsSystem: true},
		{Code: "391", Name: "Hesaplanan KDV", ParentCode: "", Level: 1, IsLeaf: false, IsSystem: true},
		{Code: "600", Name: "Yurtici Satislar", ParentCode: "", Level: 1, IsLeaf: false, IsSystem: true},
		{Code: "770", Name: "Genel Yonetim Giderleri", ParentCode: "", Level: 1, IsLeaf: false, IsSystem: true},

		{Code: "191.01", Name: "KDV", ParentCode: "191", Level: 2, IsLeaf: false, IsSystem: true},
		{Code: "191.01.01", Name: "%1 KDV", ParentCode: "191.01", Level: 3, IsLeaf: true, IsSystem: true},
		{Code: "191.01.10", Name: "%10 KDV", ParentCode: "191.01", Level: 3, IsLeaf: true, IsSystem: true},
		{Code: "191.01.20", Name: "%20 KDV", ParentCode: "191.01", Level: 3, IsLeaf: true, IsSystem: true},

		{Code: "391.01", Name: "KDV", ParentCode: "391", Level: 2, IsLeaf: false, IsSystem: true},
		{Code: "391.01.01", Name: "%1 KDV", ParentCode: "391.01", Level: 3, IsLeaf: true, IsSystem: true},
		{Code: "391.01.10", Name: "%10 KDV", ParentCode: "391.01", Level: 3, IsLeaf: true, IsSystem: true},
		{Code: "391.01.20", Name: "%20 KDV", ParentCode: "391.01", Level: 3, IsLeaf: true, IsSystem: true},
	}

	for _, acc := range coreAccounts {
		s.accounts[acc.Code] = acc
	}
}

func (s *ChartOfAccountsService) GetAccount(code string) (domain.Account, error) {
	acc, ok := s.accounts[code]
	if !ok {
		return domain.Account{}, fmt.Errorf("account not found: %s", code)
	}

	return acc, nil
}

func (s *ChartOfAccountsService) ListAccounts() []domain.Account {
	result := make([]domain.Account, 0, len(s.accounts))

	for _, acc := range s.accounts {
		result = append(result, acc)
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].Code < result[j].Code
	})

	return result
}

func (s *ChartOfAccountsService) AddCompanyAccount(account domain.Account) error {
	if account.Code == "" {
		return fmt.Errorf("account code cannot be empty")
	}

	if _, exists := s.accounts[account.Code]; exists {
		return fmt.Errorf("account already exists: %s", account.Code)
	}

	if account.ParentCode != "" {
		parent, ok := s.accounts[account.ParentCode]
		if !ok {
			return fmt.Errorf("parent account not found: %s", account.ParentCode)
		}

		if parent.IsLeaf {
			return fmt.Errorf("parent account cannot be leaf: %s", account.ParentCode)
		}
	}

	s.accounts[account.Code] = account
	return nil
}
