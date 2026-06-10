package ledger

import (
	"strings"
	"time"
)

type MovementDirection string

const (
	MovementDirectionDebit  MovementDirection = "debit"
	MovementDirectionCredit MovementDirection = "credit"
)

type LedgerMovementStatus string

const (
	LedgerMovementStatusPosted    LedgerMovementStatus = "posted"
	LedgerMovementStatusReversed  LedgerMovementStatus = "reversed"
	LedgerMovementStatusCancelled LedgerMovementStatus = "cancelled"
)

type LedgerSourceModule string

const (
	LedgerSourceManual      LedgerSourceModule = "manual"
	LedgerSourceSales       LedgerSourceModule = "sales"
	LedgerSourceProcurement LedgerSourceModule = "procurement"
	LedgerSourcePayment     LedgerSourceModule = "payment"
	LedgerSourceInventory   LedgerSourceModule = "inventory"
	LedgerSourceTax         LedgerSourceModule = "tax"
	LedgerSourceExport      LedgerSourceModule = "export"
	LedgerSourceSystem      LedgerSourceModule = "system"
)

type LedgerBalanceSide string

const (
	LedgerBalanceSideDebit  LedgerBalanceSide = "debit"
	LedgerBalanceSideCredit LedgerBalanceSide = "credit"
	LedgerBalanceSideZero   LedgerBalanceSide = "zero"
)

type LedgerBalanceStatus string

const (
	LedgerBalanceStatusActive LedgerBalanceStatus = "active"
	LedgerBalanceStatusClosed LedgerBalanceStatus = "closed"
	LedgerBalanceStatusLocked LedgerBalanceStatus = "locked"
)

type AccountMovement struct {
	AccountMovementID string
	TenantID          string

	JournalEntryID string
	JournalLineID  string

	MovementDate time.Time
	PostingDate  time.Time

	FiscalYear   int
	FiscalPeriod string

	AccountCode string
	AccountName string
	Description string

	DebitAmount  float64
	CreditAmount float64

	CurrencyCode string
	ExchangeRate float64

	LocalDebitAmount  float64
	LocalCreditAmount float64

	Direction MovementDirection

	SourceModule       LedgerSourceModule
	SourceDocumentType string
	SourceDocumentID   string

	PartyID    string
	CustomerID string
	VendorID   string
	ItemID     string

	CostCenterCode string
	ProjectCode    string

	Status LedgerMovementStatus

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
	CreatedBy string
	UpdatedBy string
}

type LedgerBalance struct {
	LedgerBalanceID string
	TenantID        string

	FiscalYear   int
	FiscalPeriod string

	AccountCode string
	AccountName string

	CurrencyCode string

	OpeningDebitAmount  float64
	OpeningCreditAmount float64

	PeriodDebitAmount  float64
	PeriodCreditAmount float64

	ClosingDebitAmount  float64
	ClosingCreditAmount float64

	BalanceSide   LedgerBalanceSide
	BalanceAmount float64

	PartyID    string
	CustomerID string
	VendorID   string

	CostCenterCode string
	ProjectCode    string

	Status LedgerBalanceStatus

	CalculatedAt *time.Time

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
	CreatedBy string
	UpdatedBy string
}

type CreateAccountMovementInput struct {
	TenantID string

	JournalEntryID string
	JournalLineID  string

	MovementDate time.Time
	PostingDate  time.Time

	FiscalYear   int
	FiscalPeriod string

	AccountCode string
	AccountName string
	Description string

	DebitAmount  float64
	CreditAmount float64

	CurrencyCode string
	ExchangeRate float64

	LocalDebitAmount  float64
	LocalCreditAmount float64

	Direction MovementDirection

	SourceModule       LedgerSourceModule
	SourceDocumentType string
	SourceDocumentID   string

	PartyID    string
	CustomerID string
	VendorID   string
	ItemID     string

	CostCenterCode string
	ProjectCode    string

	CreatedBy string
}

type CreateLedgerBalanceInput struct {
	TenantID string

	FiscalYear   int
	FiscalPeriod string

	AccountCode string
	AccountName string

	CurrencyCode string

	OpeningDebitAmount  float64
	OpeningCreditAmount float64

	PeriodDebitAmount  float64
	PeriodCreditAmount float64

	ClosingDebitAmount  float64
	ClosingCreditAmount float64

	BalanceSide   LedgerBalanceSide
	BalanceAmount float64

	PartyID    string
	CustomerID string
	VendorID   string

	CostCenterCode string
	ProjectCode    string

	CalculatedAt *time.Time
	CreatedBy    string
}

func ValidateCreateAccountMovementInput(input CreateAccountMovementInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.JournalEntryID) == "" {
		return ErrJournalEntryIDRequired
	}

	if strings.TrimSpace(input.JournalLineID) == "" {
		return ErrJournalLineIDRequired
	}

	if input.FiscalYear <= 0 {
		return ErrFiscalYearInvalid
	}

	if strings.TrimSpace(input.FiscalPeriod) == "" {
		return ErrFiscalPeriodRequired
	}

	if strings.TrimSpace(input.AccountCode) == "" {
		return ErrAccountCodeRequired
	}

	if input.ExchangeRate <= 0 {
		return ErrAmountInvalid
	}

	if input.DebitAmount < 0 || input.CreditAmount < 0 || input.LocalDebitAmount < 0 || input.LocalCreditAmount < 0 {
		return ErrAmountInvalid
	}

	direction := input.Direction

	switch direction {
	case MovementDirectionDebit:
		if input.DebitAmount <= 0 || input.CreditAmount != 0 || input.LocalDebitAmount <= 0 || input.LocalCreditAmount != 0 {
			return ErrAmountInvalid
		}
	case MovementDirectionCredit:
		if input.CreditAmount <= 0 || input.DebitAmount != 0 || input.LocalCreditAmount <= 0 || input.LocalDebitAmount != 0 {
			return ErrAmountInvalid
		}
	default:
		return ErrDirectionInvalid
	}

	sourceModule := input.SourceModule
	if strings.TrimSpace(string(sourceModule)) == "" {
		sourceModule = LedgerSourceManual
	}

	switch sourceModule {
	case LedgerSourceManual, LedgerSourceSales, LedgerSourceProcurement, LedgerSourcePayment, LedgerSourceInventory, LedgerSourceTax, LedgerSourceExport, LedgerSourceSystem:
	default:
		return ErrLedgerStatusInvalid
	}

	return nil
}

func ValidateCreateLedgerBalanceInput(input CreateLedgerBalanceInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if input.FiscalYear <= 0 {
		return ErrFiscalYearInvalid
	}

	if strings.TrimSpace(input.FiscalPeriod) == "" {
		return ErrFiscalPeriodRequired
	}

	if strings.TrimSpace(input.AccountCode) == "" {
		return ErrAccountCodeRequired
	}

	if input.OpeningDebitAmount < 0 ||
		input.OpeningCreditAmount < 0 ||
		input.PeriodDebitAmount < 0 ||
		input.PeriodCreditAmount < 0 ||
		input.ClosingDebitAmount < 0 ||
		input.ClosingCreditAmount < 0 ||
		input.BalanceAmount < 0 {
		return ErrAmountInvalid
	}

	balanceSide := input.BalanceSide
	if strings.TrimSpace(string(balanceSide)) == "" {
		balanceSide = LedgerBalanceSideZero
	}

	switch balanceSide {
	case LedgerBalanceSideDebit:
		if input.BalanceAmount <= 0 {
			return ErrAmountInvalid
		}
	case LedgerBalanceSideCredit:
		if input.BalanceAmount <= 0 {
			return ErrAmountInvalid
		}
	case LedgerBalanceSideZero:
		if input.BalanceAmount != 0 {
			return ErrAmountInvalid
		}
	default:
		return ErrBalanceSideInvalid
	}

	return nil
}
