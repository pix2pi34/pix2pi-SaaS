package cashbank

import "context"

type CashAccountRepository interface {
	CreateCashAccount(ctx context.Context, input CreateCashAccountInput) (CashAccount, error)
	GetCashAccountByID(ctx context.Context, tenantID string, cashAccountID string) (CashAccount, error)
	GetCashAccountByCode(ctx context.Context, tenantID string, cashCode string) (CashAccount, error)
	ListCashAccounts(ctx context.Context, tenantID string, filter ListCashAccountsFilter) ([]CashAccount, error)
}

type ListCashAccountsFilter struct {
	AccountCode  string
	CurrencyCode string
	IsActive     *bool
	Query        string
	Limit        int
	Offset       int
}

type BankAccountRepository interface {
	CreateBankAccount(ctx context.Context, input CreateBankAccountInput) (BankAccount, error)
	GetBankAccountByID(ctx context.Context, tenantID string, bankAccountID string) (BankAccount, error)
	GetBankAccountByCode(ctx context.Context, tenantID string, bankCode string) (BankAccount, error)
	ListBankAccounts(ctx context.Context, tenantID string, filter ListBankAccountsFilter) ([]BankAccount, error)
}

type ListBankAccountsFilter struct {
	AccountCode  string
	CurrencyCode string
	IsActive     *bool
	Query        string
	Limit        int
	Offset       int
}

type PaymentTransactionRepository interface {
	CreatePaymentTransaction(ctx context.Context, input CreatePaymentTransactionInput) (PaymentTransaction, error)
	GetPaymentTransactionByID(ctx context.Context, tenantID string, paymentTransactionID string) (PaymentTransaction, error)
	GetPaymentTransactionByNo(ctx context.Context, tenantID string, paymentNo string) (PaymentTransaction, error)
	ListPaymentTransactions(ctx context.Context, tenantID string, filter ListPaymentTransactionsFilter) ([]PaymentTransaction, error)
}

type ListPaymentTransactionsFilter struct {
	PaymentType        PaymentType
	PaymentDirection   PaymentDirection
	PaymentMethod      PaymentMethod
	CashAccountID      string
	BankAccountID      string
	SourceModule       PaymentSourceModule
	SourceDocumentType string
	SourceDocumentID   string
	Status             PaymentStatus
	Query              string
	Limit              int
	Offset             int
}
