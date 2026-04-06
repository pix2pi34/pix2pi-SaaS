package domain

import "github.com/google/uuid"

type AccountType string

const (
	TypeAsset     AccountType = "Asset"
	TypeLiability AccountType = "Liability"
	TypeEquity    AccountType = "Equity"
	TypeIncome    AccountType = "Income"
	TypeExpense   AccountType = "Expense"
)

type Account struct {
	ID       uuid.UUID
	TenantID uuid.UUID
	Code     string
	Name     string
	Type     AccountType
	Version  int
	Active   bool
}

func NewAccount(tenant uuid.UUID, code, name string, t AccountType) *Account {
	return &Account{
		ID:       uuid.New(),
		TenantID: tenant,
		Code:     code,
		Name:     name,
		Type:     t,
		Version:  1,
		Active:   true,
	}
}
