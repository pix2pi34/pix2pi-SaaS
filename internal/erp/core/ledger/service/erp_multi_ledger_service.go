package service

import (
	"fmt"
	"sort"

	ledgerdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/ledger/domain"
)

type MultiLedgerService struct {
	accounts map[string]ledgerdomain.MultiLedgerAccount
}

func NewMultiLedgerService() *MultiLedgerService {
	return &MultiLedgerService{
		accounts: make(map[string]ledgerdomain.MultiLedgerAccount),
	}
}

func (s *MultiLedgerService) CreateAccount(
	accountID string,
	accountType string,
	ownerID string,
	currency string,
) error {
	if accountID == "" {
		return fmt.Errorf("account id cannot be empty")
	}
	if accountType == "" {
		return fmt.Errorf("account type cannot be empty")
	}
	if currency == "" {
		return fmt.Errorf("currency cannot be empty")
	}
	if _, exists := s.accounts[accountID]; exists {
		return fmt.Errorf("account already exists: %s", accountID)
	}

	s.accounts[accountID] = ledgerdomain.MultiLedgerAccount{
		AccountID:   accountID,
		AccountType: accountType,
		OwnerID:     ownerID,
		Currency:    currency,
		Balance:     0,
	}

	return nil
}

func (s *MultiLedgerService) ApplyAmount(
	accountID string,
	amount float64,
) error {
	acc, exists := s.accounts[accountID]
	if !exists {
		return fmt.Errorf("account not found: %s", accountID)
	}

	acc.Balance += amount
	s.accounts[accountID] = acc
	return nil
}

func (s *MultiLedgerService) GetAccount(
	accountID string,
) (ledgerdomain.MultiLedgerAccount, error) {
	acc, exists := s.accounts[accountID]
	if !exists {
		return ledgerdomain.MultiLedgerAccount{}, fmt.Errorf("account not found: %s", accountID)
	}
	return acc, nil
}

func (s *MultiLedgerService) ListAccounts() []ledgerdomain.MultiLedgerAccount {
	result := make([]ledgerdomain.MultiLedgerAccount, 0, len(s.accounts))
	for _, acc := range s.accounts {
		result = append(result, acc)
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].AccountID < result[j].AccountID
	})

	return result
}
