package tax

import "context"

type TaxCodeRepository interface {
	CreateTaxCode(ctx context.Context, input CreateTaxCodeInput) (TaxCode, error)
	GetTaxCodeByID(ctx context.Context, tenantID string, taxCodeID string) (TaxCode, error)
	GetTaxCodeByCode(ctx context.Context, tenantID string, taxCode string) (TaxCode, error)
	ListTaxCodes(ctx context.Context, tenantID string, filter ListTaxCodesFilter) ([]TaxCode, error)
}

type ListTaxCodesFilter struct {
	TaxType       TaxType
	IsRecoverable *bool
	IsPayable     *bool
	IsWithholding *bool
	IsActive      *bool
	Query         string
	Limit         int
	Offset        int
}

type TaxRateRepository interface {
	CreateTaxRate(ctx context.Context, input CreateTaxRateInput) (TaxRate, error)
	GetTaxRateByID(ctx context.Context, tenantID string, taxRateID string) (TaxRate, error)
	ListTaxRates(ctx context.Context, tenantID string, filter ListTaxRatesFilter) ([]TaxRate, error)
}

type ListTaxRatesFilter struct {
	TaxCode   string
	IsDefault *bool
	IsActive  *bool
	Query     string
	Limit     int
	Offset    int
}

type TaxTransactionRepository interface {
	CreateTaxTransaction(ctx context.Context, input CreateTaxTransactionInput) (TaxTransaction, error)
	GetTaxTransactionByID(ctx context.Context, tenantID string, taxTransactionID string) (TaxTransaction, error)
	ListTaxTransactions(ctx context.Context, tenantID string, filter ListTaxTransactionsFilter) ([]TaxTransaction, error)
}

type ListTaxTransactionsFilter struct {
	TaxCode            string
	TaxType            TaxType
	SourceModule       TaxSourceModule
	SourceDocumentType string
	SourceDocumentID   string
	FiscalYear         int
	FiscalPeriod       string
	Direction          TaxDirection
	Status             TaxTransactionStatus
	Query              string
	Limit              int
	Offset             int
}
