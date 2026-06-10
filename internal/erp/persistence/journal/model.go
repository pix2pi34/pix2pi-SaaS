package journal

import (
	"strings"
	"time"
)

type JournalStatus string

const (
	JournalStatusDraft     JournalStatus = "draft"
	JournalStatusPosted    JournalStatus = "posted"
	JournalStatusReversed  JournalStatus = "reversed"
	JournalStatusCancelled JournalStatus = "cancelled"
)

type JournalLineStatus string

const (
	JournalLineStatusActive    JournalLineStatus = "active"
	JournalLineStatusCancelled JournalLineStatus = "cancelled"
	JournalLineStatusDeleted   JournalLineStatus = "deleted"
)

type JournalSourceModule string

const (
	JournalSourceManual      JournalSourceModule = "manual"
	JournalSourceSales       JournalSourceModule = "sales"
	JournalSourceProcurement JournalSourceModule = "procurement"
	JournalSourcePayment     JournalSourceModule = "payment"
	JournalSourceInventory   JournalSourceModule = "inventory"
	JournalSourceTax         JournalSourceModule = "tax"
	JournalSourceExport      JournalSourceModule = "export"
	JournalSourceSystem      JournalSourceModule = "system"
)

type JournalEntry struct {
	JournalEntryID         string
	TenantID               string
	JournalNo              string
	JournalDate            time.Time
	PostingDate            *time.Time
	FiscalYear             int
	FiscalPeriod           string
	SourceModule           JournalSourceModule
	SourceDocumentType     string
	SourceDocumentID       string
	CurrencyCode           string
	ExchangeRate           float64
	Description            string
	TotalDebit             float64
	TotalCredit            float64
	Status                 JournalStatus
	PostedAt               *time.Time
	PostedBy               string
	ReversedAt             *time.Time
	ReversedBy             string
	ReversalJournalEntryID string
	CreatedAt              time.Time
	UpdatedAt              time.Time
	DeletedAt              *time.Time
	CreatedBy              string
	UpdatedBy              string
}

type JournalLine struct {
	JournalLineID     string
	TenantID          string
	JournalEntryID    string
	LineNo            int
	AccountCode       string
	AccountName       string
	Description       string
	DebitAmount       float64
	CreditAmount      float64
	CurrencyCode      string
	ExchangeRate      float64
	LocalDebitAmount  float64
	LocalCreditAmount float64
	PartyID           string
	CustomerID        string
	VendorID          string
	ItemID            string
	CostCenterCode    string
	ProjectCode       string
	Status            JournalLineStatus
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
	CreatedBy         string
	UpdatedBy         string
}

type CreateJournalEntryInput struct {
	TenantID           string
	JournalNo          string
	JournalDate        time.Time
	PostingDate        *time.Time
	FiscalYear         int
	FiscalPeriod       string
	SourceModule       JournalSourceModule
	SourceDocumentType string
	SourceDocumentID   string
	CurrencyCode       string
	ExchangeRate       float64
	Description        string
	TotalDebit         float64
	TotalCredit        float64
	Status             JournalStatus
	CreatedBy          string
}

type CreateJournalLineInput struct {
	TenantID          string
	JournalEntryID    string
	LineNo            int
	AccountCode       string
	AccountName       string
	Description       string
	DebitAmount       float64
	CreditAmount      float64
	CurrencyCode      string
	ExchangeRate      float64
	LocalDebitAmount  float64
	LocalCreditAmount float64
	PartyID           string
	CustomerID        string
	VendorID          string
	ItemID            string
	CostCenterCode    string
	ProjectCode       string
	CreatedBy         string
}

func ValidateCreateJournalEntryInput(input CreateJournalEntryInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.JournalNo) == "" {
		return ErrJournalNoRequired
	}

	sourceModule := input.SourceModule
	if strings.TrimSpace(string(sourceModule)) == "" {
		sourceModule = JournalSourceManual
	}

	switch sourceModule {
	case JournalSourceManual, JournalSourceSales, JournalSourceProcurement, JournalSourcePayment, JournalSourceInventory, JournalSourceTax, JournalSourceExport, JournalSourceSystem:
	default:
		return ErrJournalSourceInvalid
	}

	status := input.Status
	if strings.TrimSpace(string(status)) == "" {
		status = JournalStatusDraft
	}

	switch status {
	case JournalStatusDraft, JournalStatusPosted, JournalStatusReversed, JournalStatusCancelled:
	default:
		return ErrJournalStatusInvalid
	}

	if input.ExchangeRate <= 0 {
		return ErrAmountInvalid
	}

	if input.TotalDebit < 0 || input.TotalCredit < 0 {
		return ErrAmountInvalid
	}

	if status == JournalStatusPosted && input.TotalDebit != input.TotalCredit {
		return ErrJournalNotBalanced
	}

	return nil
}

func ValidateCreateJournalLineInput(input CreateJournalLineInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.JournalEntryID) == "" {
		return ErrJournalEntryIDRequired
	}

	if input.LineNo <= 0 {
		return ErrLineNoInvalid
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

	debitSide := input.DebitAmount > 0 && input.CreditAmount == 0
	creditSide := input.CreditAmount > 0 && input.DebitAmount == 0

	if !debitSide && !creditSide {
		return ErrJournalLineSideInvalid
	}

	localDebitSide := input.LocalDebitAmount > 0 && input.LocalCreditAmount == 0
	localCreditSide := input.LocalCreditAmount > 0 && input.LocalDebitAmount == 0

	if !localDebitSide && !localCreditSide {
		return ErrJournalLineSideInvalid
	}

	return nil
}
