package chartofaccounts

import (
	"strings"
	"time"
)

type AccountType string

const (
	AccountTypeAsset           AccountType = "asset"
	AccountTypeLiability       AccountType = "liability"
	AccountTypeEquity          AccountType = "equity"
	AccountTypeRevenue         AccountType = "revenue"
	AccountTypeExpense         AccountType = "expense"
	AccountTypeContraAsset     AccountType = "contra_asset"
	AccountTypeContraLiability AccountType = "contra_liability"
	AccountTypeTax             AccountType = "tax"
	AccountTypeOffBalance      AccountType = "off_balance"
)

type NormalBalance string

const (
	NormalBalanceDebit  NormalBalance = "debit"
	NormalBalanceCredit NormalBalance = "credit"
	NormalBalanceZero   NormalBalance = "zero"
)

type AccountStatus string

const (
	AccountStatusActive  AccountStatus = "active"
	AccountStatusPassive AccountStatus = "passive"
	AccountStatusLocked  AccountStatus = "locked"
)

type MappingSourceModule string

const (
	MappingSourceManual      MappingSourceModule = "manual"
	MappingSourceSales       MappingSourceModule = "sales"
	MappingSourceProcurement MappingSourceModule = "procurement"
	MappingSourcePayment     MappingSourceModule = "payment"
	MappingSourceInventory   MappingSourceModule = "inventory"
	MappingSourceTax         MappingSourceModule = "tax"
	MappingSourceExport      MappingSourceModule = "export"
	MappingSourceSystem      MappingSourceModule = "system"
)

type ChartAccount struct {
	ChartAccountID    string
	TenantID          string
	AccountCode       string
	AccountName       string
	ParentAccountCode string
	AccountLevel      int
	AccountClass      string
	AccountGroup      string
	AccountType       AccountType
	NormalBalance     NormalBalance
	IsPostable        bool
	IsActive          bool
	CurrencyCode      string
	TaxCode           string
	VATRate           *float64
	Description       string
	Status            AccountStatus
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
	CreatedBy         string
	UpdatedBy         string
}

type AccountMappingRule struct {
	AccountMappingRuleID string
	TenantID             string
	MappingKey           string
	SourceModule         MappingSourceModule
	SourceDocumentType   string
	EventType            string
	LineType             string
	AccountCode          string
	AccountName          string
	VATRate              *float64
	Priority             int
	IsDefault            bool
	IsActive             bool
	Description          string
	Status               AccountStatus
	CreatedAt            time.Time
	UpdatedAt            time.Time
	DeletedAt            *time.Time
	CreatedBy            string
	UpdatedBy            string
}

type CreateChartAccountInput struct {
	TenantID          string
	AccountCode       string
	AccountName       string
	ParentAccountCode string
	AccountLevel      int
	AccountClass      string
	AccountGroup      string
	AccountType       AccountType
	NormalBalance     NormalBalance
	IsPostable        bool
	IsActive          bool
	CurrencyCode      string
	TaxCode           string
	VATRate           *float64
	Description       string
	CreatedBy         string
}

type CreateAccountMappingRuleInput struct {
	TenantID           string
	MappingKey         string
	SourceModule       MappingSourceModule
	SourceDocumentType string
	EventType          string
	LineType           string
	AccountCode        string
	AccountName        string
	VATRate            *float64
	Priority           int
	IsDefault          bool
	IsActive           bool
	Description        string
	CreatedBy          string
}

func ValidateCreateChartAccountInput(input CreateChartAccountInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.AccountCode) == "" {
		return ErrAccountCodeRequired
	}

	if strings.TrimSpace(input.AccountName) == "" {
		return ErrAccountNameRequired
	}

	if input.AccountLevel <= 0 {
		return ErrAccountLevelInvalid
	}

	switch input.AccountType {
	case AccountTypeAsset, AccountTypeLiability, AccountTypeEquity, AccountTypeRevenue, AccountTypeExpense, AccountTypeContraAsset, AccountTypeContraLiability, AccountTypeTax, AccountTypeOffBalance:
	default:
		return ErrAccountTypeInvalid
	}

	switch input.NormalBalance {
	case NormalBalanceDebit, NormalBalanceCredit, NormalBalanceZero:
	default:
		return ErrNormalBalanceInvalid
	}

	if input.VATRate != nil && (*input.VATRate < 0 || *input.VATRate > 100) {
		return ErrVATRateInvalid
	}

	return nil
}

func ValidateCreateAccountMappingRuleInput(input CreateAccountMappingRuleInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.MappingKey) == "" {
		return ErrMappingKeyRequired
	}

	switch input.SourceModule {
	case MappingSourceManual, MappingSourceSales, MappingSourceProcurement, MappingSourcePayment, MappingSourceInventory, MappingSourceTax, MappingSourceExport, MappingSourceSystem:
	default:
		return ErrSourceModuleInvalid
	}

	if strings.TrimSpace(input.AccountCode) == "" {
		return ErrAccountCodeRequired
	}

	if input.Priority <= 0 {
		return ErrPriorityInvalid
	}

	if input.VATRate != nil && (*input.VATRate < 0 || *input.VATRate > 100) {
		return ErrVATRateInvalid
	}

	return nil
}
