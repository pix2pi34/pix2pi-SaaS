package fiscal

import (
	"strings"
	"time"
)

type FiscalYearStatus string

const (
	FiscalYearStatusOpen     FiscalYearStatus = "open"
	FiscalYearStatusLocked   FiscalYearStatus = "locked"
	FiscalYearStatusClosed   FiscalYearStatus = "closed"
	FiscalYearStatusArchived FiscalYearStatus = "archived"
)

type FiscalPeriodStatus string

const (
	FiscalPeriodStatusOpen   FiscalPeriodStatus = "open"
	FiscalPeriodStatusLocked FiscalPeriodStatus = "locked"
	FiscalPeriodStatusClosed FiscalPeriodStatus = "closed"
)

type DocumentModule string

const (
	DocumentModuleSales       DocumentModule = "sales"
	DocumentModuleProcurement DocumentModule = "procurement"
	DocumentModuleJournal     DocumentModule = "journal"
	DocumentModuleLedger      DocumentModule = "ledger"
	DocumentModuleCashBank    DocumentModule = "cashbank"
	DocumentModuleInventory   DocumentModule = "inventory"
	DocumentModuleTax         DocumentModule = "tax"
	DocumentModuleSystem      DocumentModule = "system"
)

type ResetPolicy string

const (
	ResetPolicyNever   ResetPolicy = "never"
	ResetPolicyYearly  ResetPolicy = "yearly"
	ResetPolicyMonthly ResetPolicy = "monthly"
	ResetPolicyDaily   ResetPolicy = "daily"
)

type SequenceStatus string

const (
	SequenceStatusActive  SequenceStatus = "active"
	SequenceStatusPassive SequenceStatus = "passive"
	SequenceStatusLocked  SequenceStatus = "locked"
)

type AllocationStatus string

const (
	AllocationStatusAllocated AllocationStatus = "allocated"
	AllocationStatusConfirmed AllocationStatus = "confirmed"
	AllocationStatusCancelled AllocationStatus = "cancelled"
)

type FiscalYear struct {
	FiscalYearID string
	TenantID     string

	FiscalYear    int
	YearStartDate time.Time
	YearEndDate   time.Time

	Status FiscalYearStatus

	ClosedAt *time.Time
	ClosedBy string

	Description string

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
	CreatedBy string
	UpdatedBy string
}

type FiscalPeriod struct {
	FiscalPeriodID string
	TenantID       string

	FiscalYear   int
	FiscalPeriod string
	PeriodNo     int

	PeriodStartDate time.Time
	PeriodEndDate   time.Time

	Status FiscalPeriodStatus

	ClosedAt *time.Time
	ClosedBy string

	Description string

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
	CreatedBy string
	UpdatedBy string
}

type DocumentSequence struct {
	DocumentSequenceID string
	TenantID           string

	DocumentModule DocumentModule
	DocumentType   string

	FiscalYear *int

	Prefix string
	Suffix string

	CurrentNo int64
	MinNo     int64
	MaxNo     *int64

	Padding int

	ResetPolicy ResetPolicy

	IsActive bool

	Description string
	Status      SequenceStatus

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
	CreatedBy string
	UpdatedBy string
}

type DocumentNumberAllocation struct {
	DocumentNumberAllocationID string
	TenantID                   string

	DocumentSequenceID string

	DocumentModule DocumentModule
	DocumentType   string

	DocumentNo  string
	AllocatedNo int64

	FiscalYear   *int
	FiscalPeriod string

	SourceDocumentID string

	AllocationStatus AllocationStatus

	AllocatedAt time.Time
	AllocatedBy string

	ConfirmedAt *time.Time
	ConfirmedBy string

	CancelledAt *time.Time
	CancelledBy string

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
	CreatedBy string
	UpdatedBy string
}

type CreateFiscalYearInput struct {
	TenantID string

	FiscalYear    int
	YearStartDate time.Time
	YearEndDate   time.Time

	Description string
	CreatedBy   string
}

type CreateFiscalPeriodInput struct {
	TenantID string

	FiscalYear   int
	FiscalPeriod string
	PeriodNo     int

	PeriodStartDate time.Time
	PeriodEndDate   time.Time

	Description string
	CreatedBy   string
}

type CreateDocumentSequenceInput struct {
	TenantID string

	DocumentModule DocumentModule
	DocumentType   string

	FiscalYear *int

	Prefix string
	Suffix string

	CurrentNo int64
	MinNo     int64
	MaxNo     *int64

	Padding int

	ResetPolicy ResetPolicy

	IsActive bool

	Description string
	CreatedBy   string
}

type CreateDocumentNumberAllocationInput struct {
	TenantID string

	DocumentSequenceID string

	DocumentModule DocumentModule
	DocumentType   string

	DocumentNo  string
	AllocatedNo int64

	FiscalYear   *int
	FiscalPeriod string

	SourceDocumentID string

	AllocationStatus AllocationStatus

	AllocatedBy string
	CreatedBy   string
}

func ValidateCreateFiscalYearInput(input CreateFiscalYearInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if input.FiscalYear < 2000 || input.FiscalYear > 2100 {
		return ErrFiscalYearInvalid
	}

	if input.YearStartDate.IsZero() || input.YearEndDate.IsZero() || input.YearEndDate.Before(input.YearStartDate) {
		return ErrDateRangeInvalid
	}

	return nil
}

func ValidateCreateFiscalPeriodInput(input CreateFiscalPeriodInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if input.FiscalYear < 2000 || input.FiscalYear > 2100 {
		return ErrFiscalYearInvalid
	}

	if strings.TrimSpace(input.FiscalPeriod) == "" {
		return ErrFiscalPeriodRequired
	}

	if input.PeriodNo < 1 || input.PeriodNo > 13 {
		return ErrPeriodNoInvalid
	}

	if input.PeriodStartDate.IsZero() || input.PeriodEndDate.IsZero() || input.PeriodEndDate.Before(input.PeriodStartDate) {
		return ErrDateRangeInvalid
	}

	return nil
}

func ValidateCreateDocumentSequenceInput(input CreateDocumentSequenceInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if !isValidDocumentModule(input.DocumentModule) {
		return ErrDocumentModuleInvalid
	}

	if strings.TrimSpace(input.DocumentType) == "" {
		return ErrDocumentTypeRequired
	}

	minNo := input.MinNo
	if minNo == 0 {
		minNo = 1
	}

	padding := input.Padding
	if padding == 0 {
		padding = 6
	}

	if input.CurrentNo < 0 || minNo <= 0 || padding < 1 || padding > 20 {
		return ErrNumberRangeInvalid
	}

	if input.MaxNo != nil && *input.MaxNo < minNo {
		return ErrNumberRangeInvalid
	}

	resetPolicy := input.ResetPolicy
	if strings.TrimSpace(string(resetPolicy)) == "" {
		resetPolicy = ResetPolicyYearly
	}

	if !isValidResetPolicy(resetPolicy) {
		return ErrResetPolicyInvalid
	}

	return nil
}

func ValidateCreateDocumentNumberAllocationInput(input CreateDocumentNumberAllocationInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.DocumentSequenceID) == "" {
		return ErrDocumentSequenceIDRequired
	}

	if !isValidDocumentModule(input.DocumentModule) {
		return ErrDocumentModuleInvalid
	}

	if strings.TrimSpace(input.DocumentType) == "" {
		return ErrDocumentTypeRequired
	}

	if strings.TrimSpace(input.DocumentNo) == "" {
		return ErrDocumentNoRequired
	}

	if input.AllocatedNo <= 0 {
		return ErrAllocatedNoInvalid
	}

	return nil
}

func isValidDocumentModule(value DocumentModule) bool {
	switch value {
	case DocumentModuleSales, DocumentModuleProcurement, DocumentModuleJournal, DocumentModuleLedger, DocumentModuleCashBank, DocumentModuleInventory, DocumentModuleTax, DocumentModuleSystem:
		return true
	default:
		return false
	}
}

func isValidResetPolicy(value ResetPolicy) bool {
	switch value {
	case ResetPolicyNever, ResetPolicyYearly, ResetPolicyMonthly, ResetPolicyDaily:
		return true
	default:
		return false
	}
}
