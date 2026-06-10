package fiscal

import "context"

type FiscalYearRepository interface {
	CreateFiscalYear(ctx context.Context, input CreateFiscalYearInput) (FiscalYear, error)
	GetFiscalYearByID(ctx context.Context, tenantID string, fiscalYearID string) (FiscalYear, error)
	GetFiscalYearByYear(ctx context.Context, tenantID string, fiscalYear int) (FiscalYear, error)
	ListFiscalYears(ctx context.Context, tenantID string, filter ListFiscalYearsFilter) ([]FiscalYear, error)
}

type ListFiscalYearsFilter struct {
	Status FiscalYearStatus
	Query  string
	Limit  int
	Offset int
}

type FiscalPeriodRepository interface {
	CreateFiscalPeriod(ctx context.Context, input CreateFiscalPeriodInput) (FiscalPeriod, error)
	GetFiscalPeriodByID(ctx context.Context, tenantID string, fiscalPeriodID string) (FiscalPeriod, error)
	GetFiscalPeriodByCode(ctx context.Context, tenantID string, fiscalPeriod string) (FiscalPeriod, error)
	ListFiscalPeriods(ctx context.Context, tenantID string, filter ListFiscalPeriodsFilter) ([]FiscalPeriod, error)
}

type ListFiscalPeriodsFilter struct {
	FiscalYear int
	Status     FiscalPeriodStatus
	Query      string
	Limit      int
	Offset     int
}

type DocumentSequenceRepository interface {
	CreateDocumentSequence(ctx context.Context, input CreateDocumentSequenceInput) (DocumentSequence, error)
	GetDocumentSequenceByID(ctx context.Context, tenantID string, documentSequenceID string) (DocumentSequence, error)
	GetDocumentSequenceByModuleTypeYear(ctx context.Context, tenantID string, documentModule DocumentModule, documentType string, fiscalYear *int) (DocumentSequence, error)
	ListDocumentSequences(ctx context.Context, tenantID string, filter ListDocumentSequencesFilter) ([]DocumentSequence, error)
}

type ListDocumentSequencesFilter struct {
	DocumentModule DocumentModule
	DocumentType   string
	FiscalYear     *int
	IsActive       *bool
	Status         SequenceStatus
	Query          string
	Limit          int
	Offset         int
}

type DocumentNumberAllocationRepository interface {
	CreateDocumentNumberAllocation(ctx context.Context, input CreateDocumentNumberAllocationInput) (DocumentNumberAllocation, error)
	GetDocumentNumberAllocationByID(ctx context.Context, tenantID string, documentNumberAllocationID string) (DocumentNumberAllocation, error)
	GetDocumentNumberAllocationByNo(ctx context.Context, tenantID string, documentModule DocumentModule, documentType string, documentNo string) (DocumentNumberAllocation, error)
	ListDocumentNumberAllocations(ctx context.Context, tenantID string, filter ListDocumentNumberAllocationsFilter) ([]DocumentNumberAllocation, error)
}

type ListDocumentNumberAllocationsFilter struct {
	DocumentSequenceID string
	DocumentModule     DocumentModule
	DocumentType       string
	FiscalYear         *int
	FiscalPeriod       string
	AllocationStatus   AllocationStatus
	Query              string
	Limit              int
	Offset             int
}
