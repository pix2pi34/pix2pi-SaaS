package tax

import (
	"strings"
	"time"
)

type TaxType string

const (
	TaxTypeVAT          TaxType = "vat"
	TaxTypeWithholding  TaxType = "withholding"
	TaxTypeStamp        TaxType = "stamp"
	TaxTypeExcise       TaxType = "excise"
	TaxTypeIncomeTax    TaxType = "income_tax"
	TaxTypeCorporateTax TaxType = "corporate_tax"
	TaxTypeOther        TaxType = "other"
)

type TaxStatus string

const (
	TaxStatusActive  TaxStatus = "active"
	TaxStatusPassive TaxStatus = "passive"
	TaxStatusLocked  TaxStatus = "locked"
)

type TaxTransactionStatus string

const (
	TaxTransactionStatusDraft     TaxTransactionStatus = "draft"
	TaxTransactionStatusPosted    TaxTransactionStatus = "posted"
	TaxTransactionStatusReversed  TaxTransactionStatus = "reversed"
	TaxTransactionStatusCancelled TaxTransactionStatus = "cancelled"
)

type TaxSourceModule string

const (
	TaxSourceManual      TaxSourceModule = "manual"
	TaxSourceSales       TaxSourceModule = "sales"
	TaxSourceProcurement TaxSourceModule = "procurement"
	TaxSourcePayment     TaxSourceModule = "payment"
	TaxSourceInventory   TaxSourceModule = "inventory"
	TaxSourceTax         TaxSourceModule = "tax"
	TaxSourceExport      TaxSourceModule = "export"
	TaxSourceSystem      TaxSourceModule = "system"
)

type TaxDirection string

const (
	TaxDirectionPayable     TaxDirection = "payable"
	TaxDirectionRecoverable TaxDirection = "recoverable"
	TaxDirectionNeutral     TaxDirection = "neutral"
)

type TaxCode struct {
	TaxCodeID     string
	TenantID      string
	TaxCode       string
	TaxName       string
	TaxType       TaxType
	AccountCode   string
	AccountName   string
	IsRecoverable bool
	IsPayable     bool
	IsWithholding bool
	IsActive      bool
	Description   string
	Status        TaxStatus
	CreatedAt     time.Time
	UpdatedAt     time.Time
	DeletedAt     *time.Time
	CreatedBy     string
	UpdatedBy     string
}

type TaxRate struct {
	TaxRateID              string
	TenantID               string
	TaxCodeID              string
	TaxCode                string
	RatePercent            float64
	WithholdingNumerator   *int
	WithholdingDenominator *int
	ValidFrom              time.Time
	ValidTo                *time.Time
	IsDefault              bool
	IsActive               bool
	Description            string
	Status                 TaxStatus
	CreatedAt              time.Time
	UpdatedAt              time.Time
	DeletedAt              *time.Time
	CreatedBy              string
	UpdatedBy              string
}

type TaxTransaction struct {
	TaxTransactionID string
	TenantID         string

	TaxCodeID string
	TaxRateID string

	TaxCode string
	TaxName string
	TaxType TaxType

	SourceModule       TaxSourceModule
	SourceDocumentType string
	SourceDocumentID   string
	SourceLineID       string

	JournalEntryID string
	JournalLineID  string

	TransactionDate time.Time
	FiscalYear      int
	FiscalPeriod    string

	BaseAmount  float64
	RatePercent float64
	TaxAmount   float64

	WithholdingNumerator   *int
	WithholdingDenominator *int
	WithholdingAmount      float64

	PayableAmount     float64
	RecoverableAmount float64

	CurrencyCode string
	ExchangeRate float64

	LocalBaseAmount float64
	LocalTaxAmount  float64

	Direction TaxDirection

	PartyID    string
	CustomerID string
	VendorID   string

	Status TaxTransactionStatus

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
	CreatedBy string
	UpdatedBy string
}

type CreateTaxCodeInput struct {
	TenantID      string
	TaxCode       string
	TaxName       string
	TaxType       TaxType
	AccountCode   string
	AccountName   string
	IsRecoverable bool
	IsPayable     bool
	IsWithholding bool
	IsActive      bool
	Description   string
	CreatedBy     string
}

type CreateTaxRateInput struct {
	TenantID               string
	TaxCodeID              string
	TaxCode                string
	RatePercent            float64
	WithholdingNumerator   *int
	WithholdingDenominator *int
	ValidFrom              time.Time
	ValidTo                *time.Time
	IsDefault              bool
	IsActive               bool
	Description            string
	CreatedBy              string
}

type CreateTaxTransactionInput struct {
	TenantID string

	TaxCodeID string
	TaxRateID string

	TaxCode string
	TaxName string
	TaxType TaxType

	SourceModule       TaxSourceModule
	SourceDocumentType string
	SourceDocumentID   string
	SourceLineID       string

	JournalEntryID string
	JournalLineID  string

	TransactionDate time.Time
	FiscalYear      int
	FiscalPeriod    string

	BaseAmount  float64
	RatePercent float64
	TaxAmount   float64

	WithholdingNumerator   *int
	WithholdingDenominator *int
	WithholdingAmount      float64

	PayableAmount     float64
	RecoverableAmount float64

	CurrencyCode string
	ExchangeRate float64

	LocalBaseAmount float64
	LocalTaxAmount  float64

	Direction TaxDirection

	PartyID    string
	CustomerID string
	VendorID   string

	Status    TaxTransactionStatus
	CreatedBy string
}

func ValidateCreateTaxCodeInput(input CreateTaxCodeInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.TaxCode) == "" {
		return ErrTaxCodeRequired
	}

	if strings.TrimSpace(input.TaxName) == "" {
		return ErrTaxNameRequired
	}

	if !isValidTaxType(input.TaxType) {
		return ErrTaxTypeInvalid
	}

	return nil
}

func ValidateCreateTaxRateInput(input CreateTaxRateInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.TaxCodeID) == "" {
		return ErrTaxCodeIDRequired
	}

	if strings.TrimSpace(input.TaxCode) == "" {
		return ErrTaxCodeRequired
	}

	if input.RatePercent < 0 || input.RatePercent > 100 {
		return ErrRateInvalid
	}

	if err := validateWithholdingRatio(input.WithholdingNumerator, input.WithholdingDenominator); err != nil {
		return err
	}

	if input.ValidTo != nil && !input.ValidFrom.IsZero() && input.ValidTo.Before(input.ValidFrom) {
		return ErrValidRangeInvalid
	}

	return nil
}

func ValidateCreateTaxTransactionInput(input CreateTaxTransactionInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.TaxCode) == "" {
		return ErrTaxCodeRequired
	}

	if !isValidTaxType(input.TaxType) {
		return ErrTaxTypeInvalid
	}

	if !isValidSourceModule(input.SourceModule) {
		return ErrSourceModuleInvalid
	}

	if input.FiscalYear <= 0 {
		return ErrFiscalYearInvalid
	}

	if strings.TrimSpace(input.FiscalPeriod) == "" {
		return ErrFiscalPeriodRequired
	}

	if input.BaseAmount < 0 ||
		input.RatePercent < 0 ||
		input.RatePercent > 100 ||
		input.TaxAmount < 0 ||
		input.WithholdingAmount < 0 ||
		input.PayableAmount < 0 ||
		input.RecoverableAmount < 0 ||
		input.ExchangeRate <= 0 ||
		input.LocalBaseAmount < 0 ||
		input.LocalTaxAmount < 0 {
		return ErrAmountInvalid
	}

	if err := validateWithholdingRatio(input.WithholdingNumerator, input.WithholdingDenominator); err != nil {
		return err
	}

	switch input.Direction {
	case TaxDirectionPayable, TaxDirectionRecoverable, TaxDirectionNeutral:
	default:
		return ErrDirectionInvalid
	}

	status := input.Status
	if strings.TrimSpace(string(status)) == "" {
		status = TaxTransactionStatusPosted
	}

	switch status {
	case TaxTransactionStatusDraft, TaxTransactionStatusPosted, TaxTransactionStatusReversed, TaxTransactionStatusCancelled:
	default:
		return ErrTaxStatusInvalid
	}

	return nil
}

func isValidTaxType(value TaxType) bool {
	switch value {
	case TaxTypeVAT, TaxTypeWithholding, TaxTypeStamp, TaxTypeExcise, TaxTypeIncomeTax, TaxTypeCorporateTax, TaxTypeOther:
		return true
	default:
		return false
	}
}

func isValidSourceModule(value TaxSourceModule) bool {
	switch value {
	case TaxSourceManual, TaxSourceSales, TaxSourceProcurement, TaxSourcePayment, TaxSourceInventory, TaxSourceTax, TaxSourceExport, TaxSourceSystem:
		return true
	default:
		return false
	}
}

func validateWithholdingRatio(numerator *int, denominator *int) error {
	if numerator == nil && denominator == nil {
		return nil
	}

	if numerator == nil || denominator == nil {
		return ErrWithholdingRatioInvalid
	}

	if *numerator < 0 || *denominator <= 0 || *numerator > *denominator {
		return ErrWithholdingRatioInvalid
	}

	return nil
}
