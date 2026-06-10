package docnumber

import (
	"fmt"
	"strings"
	"time"
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

type SequenceStatus string

const (
	SequenceStatusActive  SequenceStatus = "active"
	SequenceStatusPassive SequenceStatus = "passive"
	SequenceStatusLocked  SequenceStatus = "locked"
)

type ResetPolicy string

const (
	ResetPolicyNever   ResetPolicy = "never"
	ResetPolicyYearly  ResetPolicy = "yearly"
	ResetPolicyMonthly ResetPolicy = "monthly"
	ResetPolicyDaily   ResetPolicy = "daily"
)

type AllocationStatus string

const (
	AllocationStatusAllocated AllocationStatus = "allocated"
	AllocationStatusConfirmed AllocationStatus = "confirmed"
	AllocationStatusCancelled AllocationStatus = "cancelled"
)

type AllocateDocumentNumberRequest struct {
	TenantID  string
	RequestID string
	ActorID   string

	DocumentModule DocumentModule
	DocumentType   string

	FiscalYear   *int
	FiscalPeriod string

	SourceDocumentID string
}

type DocumentSequenceSnapshot struct {
	TenantID           string
	DocumentSequenceID string

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
	Status   SequenceStatus
}

type DocumentNumberAllocation struct {
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

	AllocatedAt time.Time
	AllocatedBy string
}

type AllocateDocumentNumberResult struct {
	OK bool

	TenantID  string
	RequestID string

	DocumentSequenceID string

	DocumentModule DocumentModule
	DocumentType   string

	DocumentNo  string
	AllocatedNo int64

	FiscalYear   *int
	FiscalPeriod string

	AllocationStatus AllocationStatus
	AllocatedAt      time.Time
}

func ValidateAllocateDocumentNumberRequest(req AllocateDocumentNumberRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(req.RequestID) == "" {
		return ErrRequestIDRequired
	}

	if strings.TrimSpace(req.ActorID) == "" {
		return ErrActorRequired
	}

	if !isValidDocumentModule(req.DocumentModule) {
		return ErrDocumentModuleInvalid
	}

	if strings.TrimSpace(req.DocumentType) == "" {
		return ErrDocumentTypeRequired
	}

	if req.FiscalYear != nil && (*req.FiscalYear < 2000 || *req.FiscalYear > 2100) {
		return ErrFiscalYearInvalid
	}

	return nil
}

func ValidateDocumentSequenceSnapshot(seq DocumentSequenceSnapshot) error {
	if strings.TrimSpace(seq.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(seq.DocumentSequenceID) == "" {
		return ErrSequenceIDRequired
	}

	if !isValidDocumentModule(seq.DocumentModule) {
		return ErrDocumentModuleInvalid
	}

	if strings.TrimSpace(seq.DocumentType) == "" {
		return ErrDocumentTypeRequired
	}

	if seq.FiscalYear != nil && (*seq.FiscalYear < 2000 || *seq.FiscalYear > 2100) {
		return ErrFiscalYearInvalid
	}

	if seq.CurrentNo < 0 {
		return ErrCurrentNoInvalid
	}

	if seq.MinNo <= 0 {
		return ErrMinNoInvalid
	}

	if seq.MaxNo != nil && *seq.MaxNo < seq.MinNo {
		return ErrMaxNoInvalid
	}

	if seq.Padding < 1 || seq.Padding > 20 {
		return ErrPaddingInvalid
	}

	return nil
}

func BuildDocumentNumberAllocation(req AllocateDocumentNumberRequest, seq DocumentSequenceSnapshot) (DocumentNumberAllocation, error) {
	if err := ValidateAllocateDocumentNumberRequest(req); err != nil {
		return DocumentNumberAllocation{}, err
	}

	if err := ValidateDocumentSequenceSnapshot(seq); err != nil {
		return DocumentNumberAllocation{}, err
	}

	if req.TenantID != seq.TenantID {
		return DocumentNumberAllocation{}, ErrSequenceNotFound
	}

	if req.DocumentModule != seq.DocumentModule {
		return DocumentNumberAllocation{}, ErrSequenceNotFound
	}

	if strings.TrimSpace(req.DocumentType) != strings.TrimSpace(seq.DocumentType) {
		return DocumentNumberAllocation{}, ErrSequenceNotFound
	}

	if !seq.IsActive || seq.Status == SequenceStatusPassive {
		return DocumentNumberAllocation{}, ErrSequenceInactive
	}

	if seq.Status == SequenceStatusLocked {
		return DocumentNumberAllocation{}, ErrSequenceLocked
	}

	nextNo, err := NextAllocatedNumber(seq)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}

	return DocumentNumberAllocation{
		TenantID:           req.TenantID,
		DocumentSequenceID: seq.DocumentSequenceID,
		DocumentModule:     seq.DocumentModule,
		DocumentType:       seq.DocumentType,
		DocumentNo:         FormatDocumentNumber(seq, nextNo),
		AllocatedNo:        nextNo,
		FiscalYear:         req.FiscalYear,
		FiscalPeriod:       req.FiscalPeriod,
		SourceDocumentID:   req.SourceDocumentID,
		AllocationStatus:   AllocationStatusAllocated,
		AllocatedAt:        time.Now().UTC(),
		AllocatedBy:        req.ActorID,
	}, nil
}

func NextAllocatedNumber(seq DocumentSequenceSnapshot) (int64, error) {
	if err := ValidateDocumentSequenceSnapshot(seq); err != nil {
		return 0, err
	}

	nextNo := seq.CurrentNo + 1
	if nextNo < seq.MinNo {
		nextNo = seq.MinNo
	}

	if seq.MaxNo != nil && nextNo > *seq.MaxNo {
		return 0, ErrSequenceExhausted
	}

	return nextNo, nil
}

func FormatDocumentNumber(seq DocumentSequenceSnapshot, allocatedNo int64) string {
	numberPart := fmt.Sprintf("%0*d", seq.Padding, allocatedNo)
	return seq.Prefix + numberPart + seq.Suffix
}

func BuildAllocateDocumentNumberResult(req AllocateDocumentNumberRequest, allocation DocumentNumberAllocation) (AllocateDocumentNumberResult, error) {
	if err := ValidateAllocateDocumentNumberRequest(req); err != nil {
		return AllocateDocumentNumberResult{}, err
	}

	if allocation.AllocatedNo <= 0 {
		return AllocateDocumentNumberResult{}, ErrAllocatedNoInvalid
	}

	if strings.TrimSpace(allocation.DocumentNo) == "" {
		return AllocateDocumentNumberResult{}, ErrAllocatedNoInvalid
	}

	if allocation.AllocationStatus != AllocationStatusAllocated &&
		allocation.AllocationStatus != AllocationStatusConfirmed &&
		allocation.AllocationStatus != AllocationStatusCancelled {
		return AllocateDocumentNumberResult{}, ErrAllocationStatusInvalid
	}

	return AllocateDocumentNumberResult{
		OK:                 true,
		TenantID:           req.TenantID,
		RequestID:          req.RequestID,
		DocumentSequenceID: allocation.DocumentSequenceID,
		DocumentModule:     allocation.DocumentModule,
		DocumentType:       allocation.DocumentType,
		DocumentNo:         allocation.DocumentNo,
		AllocatedNo:        allocation.AllocatedNo,
		FiscalYear:         allocation.FiscalYear,
		FiscalPeriod:       allocation.FiscalPeriod,
		AllocationStatus:   allocation.AllocationStatus,
		AllocatedAt:        allocation.AllocatedAt,
	}, nil
}

func isValidDocumentModule(value DocumentModule) bool {
	switch value {
	case DocumentModuleSales, DocumentModuleProcurement, DocumentModuleJournal, DocumentModuleLedger, DocumentModuleCashBank, DocumentModuleInventory, DocumentModuleTax, DocumentModuleSystem:
		return true
	default:
		return false
	}
}
