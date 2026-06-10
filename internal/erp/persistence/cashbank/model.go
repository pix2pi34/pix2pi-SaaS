package cashbank

import (
	"strings"
	"time"
)

type AccountStatus string

const (
	AccountStatusActive  AccountStatus = "active"
	AccountStatusPassive AccountStatus = "passive"
	AccountStatusLocked  AccountStatus = "locked"
)

type PaymentType string

const (
	PaymentTypeCollection PaymentType = "collection"
	PaymentTypePayment    PaymentType = "payment"
	PaymentTypeTransfer   PaymentType = "transfer"
	PaymentTypeRefund     PaymentType = "refund"
	PaymentTypeFee        PaymentType = "fee"
	PaymentTypeAdjustment PaymentType = "adjustment"
)

type PaymentDirection string

const (
	PaymentDirectionIn      PaymentDirection = "in"
	PaymentDirectionOut     PaymentDirection = "out"
	PaymentDirectionNeutral PaymentDirection = "neutral"
)

type PaymentMethod string

const (
	PaymentMethodCash           PaymentMethod = "cash"
	PaymentMethodBankTransfer   PaymentMethod = "bank_transfer"
	PaymentMethodCreditCard     PaymentMethod = "credit_card"
	PaymentMethodDebitCard      PaymentMethod = "debit_card"
	PaymentMethodPOS            PaymentMethod = "pos"
	PaymentMethodCheck          PaymentMethod = "check"
	PaymentMethodPromissoryNote PaymentMethod = "promissory_note"
	PaymentMethodOther          PaymentMethod = "other"
)

type PaymentSourceModule string

const (
	PaymentSourceManual      PaymentSourceModule = "manual"
	PaymentSourceSales       PaymentSourceModule = "sales"
	PaymentSourceProcurement PaymentSourceModule = "procurement"
	PaymentSourcePayment     PaymentSourceModule = "payment"
	PaymentSourceInventory   PaymentSourceModule = "inventory"
	PaymentSourceTax         PaymentSourceModule = "tax"
	PaymentSourceExport      PaymentSourceModule = "export"
	PaymentSourceSystem      PaymentSourceModule = "system"
)

type PaymentStatus string

const (
	PaymentStatusDraft     PaymentStatus = "draft"
	PaymentStatusPosted    PaymentStatus = "posted"
	PaymentStatusCancelled PaymentStatus = "cancelled"
	PaymentStatusReversed  PaymentStatus = "reversed"
)

type CashAccount struct {
	CashAccountID string
	TenantID      string

	CashCode string
	CashName string

	AccountCode string
	AccountName string

	CurrencyCode string

	OpeningBalance float64
	CurrentBalance float64

	IsActive bool

	Description string
	Status      AccountStatus

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
	CreatedBy string
	UpdatedBy string
}

type BankAccount struct {
	BankAccountID string
	TenantID      string

	BankCode string
	BankName string

	BranchCode string
	BranchName string

	IBAN      string
	AccountNo string

	AccountCode string
	AccountName string

	CurrencyCode string

	OpeningBalance float64
	CurrentBalance float64

	IsActive bool

	Description string
	Status      AccountStatus

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
	CreatedBy string
	UpdatedBy string
}

type PaymentTransaction struct {
	PaymentTransactionID string
	TenantID             string

	PaymentNo   string
	PaymentDate time.Time

	PaymentType      PaymentType
	PaymentDirection PaymentDirection
	PaymentMethod    PaymentMethod

	CashAccountID string
	BankAccountID string

	PartyID    string
	CustomerID string
	VendorID   string

	SourceModule       PaymentSourceModule
	SourceDocumentType string
	SourceDocumentID   string

	JournalEntryID string

	CurrencyCode string
	ExchangeRate float64

	Amount      float64
	LocalAmount float64

	FeeAmount      float64
	LocalFeeAmount float64

	NetAmount      float64
	LocalNetAmount float64

	Description string
	Status      PaymentStatus

	PostedAt *time.Time
	PostedBy string

	CancelledAt *time.Time
	CancelledBy string

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
	CreatedBy string
	UpdatedBy string
}

type CreateCashAccountInput struct {
	TenantID string

	CashCode string
	CashName string

	AccountCode string
	AccountName string

	CurrencyCode string

	OpeningBalance float64
	CurrentBalance float64

	IsActive bool

	Description string
	CreatedBy   string
}

type CreateBankAccountInput struct {
	TenantID string

	BankCode string
	BankName string

	BranchCode string
	BranchName string

	IBAN      string
	AccountNo string

	AccountCode string
	AccountName string

	CurrencyCode string

	OpeningBalance float64
	CurrentBalance float64

	IsActive bool

	Description string
	CreatedBy   string
}

type CreatePaymentTransactionInput struct {
	TenantID string

	PaymentNo   string
	PaymentDate time.Time

	PaymentType      PaymentType
	PaymentDirection PaymentDirection
	PaymentMethod    PaymentMethod

	CashAccountID string
	BankAccountID string

	PartyID    string
	CustomerID string
	VendorID   string

	SourceModule       PaymentSourceModule
	SourceDocumentType string
	SourceDocumentID   string

	JournalEntryID string

	CurrencyCode string
	ExchangeRate float64

	Amount      float64
	LocalAmount float64

	FeeAmount      float64
	LocalFeeAmount float64

	NetAmount      float64
	LocalNetAmount float64

	Description string
	Status      PaymentStatus

	PostedAt *time.Time
	PostedBy string

	CancelledAt *time.Time
	CancelledBy string

	CreatedBy string
}

func ValidateCreateCashAccountInput(input CreateCashAccountInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.CashCode) == "" {
		return ErrCashCodeRequired
	}

	if strings.TrimSpace(input.CashName) == "" {
		return ErrCashNameRequired
	}

	if input.OpeningBalance < 0 || input.CurrentBalance < 0 {
		return ErrAmountInvalid
	}

	return nil
}

func ValidateCreateBankAccountInput(input CreateBankAccountInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.BankCode) == "" {
		return ErrBankCodeRequired
	}

	if strings.TrimSpace(input.BankName) == "" {
		return ErrBankNameRequired
	}

	if input.OpeningBalance < 0 || input.CurrentBalance < 0 {
		return ErrAmountInvalid
	}

	return nil
}

func ValidateCreatePaymentTransactionInput(input CreatePaymentTransactionInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.PaymentNo) == "" {
		return ErrPaymentNoRequired
	}

	if !isValidPaymentType(input.PaymentType) {
		return ErrPaymentTypeInvalid
	}

	if !isValidPaymentDirection(input.PaymentDirection) {
		return ErrPaymentDirectionInvalid
	}

	if !isValidPaymentMethod(input.PaymentMethod) {
		return ErrPaymentMethodInvalid
	}

	if strings.TrimSpace(input.CashAccountID) == "" && strings.TrimSpace(input.BankAccountID) == "" {
		return ErrPaymentAccountRequired
	}

	sourceModule := input.SourceModule
	if strings.TrimSpace(string(sourceModule)) == "" {
		sourceModule = PaymentSourceManual
	}

	if !isValidPaymentSourceModule(sourceModule) {
		return ErrSourceModuleInvalid
	}

	if input.ExchangeRate <= 0 ||
		input.Amount < 0 ||
		input.LocalAmount < 0 ||
		input.FeeAmount < 0 ||
		input.LocalFeeAmount < 0 ||
		input.NetAmount < 0 ||
		input.LocalNetAmount < 0 {
		return ErrAmountInvalid
	}

	status := input.Status
	if strings.TrimSpace(string(status)) == "" {
		status = PaymentStatusDraft
	}

	if !isValidPaymentStatus(status) {
		return ErrPaymentStatusInvalid
	}

	return nil
}

func isValidPaymentType(value PaymentType) bool {
	switch value {
	case PaymentTypeCollection, PaymentTypePayment, PaymentTypeTransfer, PaymentTypeRefund, PaymentTypeFee, PaymentTypeAdjustment:
		return true
	default:
		return false
	}
}

func isValidPaymentDirection(value PaymentDirection) bool {
	switch value {
	case PaymentDirectionIn, PaymentDirectionOut, PaymentDirectionNeutral:
		return true
	default:
		return false
	}
}

func isValidPaymentMethod(value PaymentMethod) bool {
	switch value {
	case PaymentMethodCash, PaymentMethodBankTransfer, PaymentMethodCreditCard, PaymentMethodDebitCard, PaymentMethodPOS, PaymentMethodCheck, PaymentMethodPromissoryNote, PaymentMethodOther:
		return true
	default:
		return false
	}
}

func isValidPaymentSourceModule(value PaymentSourceModule) bool {
	switch value {
	case PaymentSourceManual, PaymentSourceSales, PaymentSourceProcurement, PaymentSourcePayment, PaymentSourceInventory, PaymentSourceTax, PaymentSourceExport, PaymentSourceSystem:
		return true
	default:
		return false
	}
}

func isValidPaymentStatus(value PaymentStatus) bool {
	switch value {
	case PaymentStatusDraft, PaymentStatusPosted, PaymentStatusCancelled, PaymentStatusReversed:
		return true
	default:
		return false
	}
}
