package fiscal

import (
	"errors"
	"testing"
	"time"
)

func TestValidateCreateFiscalYearInputSuccess(t *testing.T) {
	err := ValidateCreateFiscalYearInput(CreateFiscalYearInput{
		TenantID:      "tenant_7",
		FiscalYear:    2026,
		YearStartDate: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
		YearEndDate:   time.Date(2026, 12, 31, 0, 0, 0, 0, time.UTC),
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateFiscalYearInputTenantRequired(t *testing.T) {
	err := ValidateCreateFiscalYearInput(CreateFiscalYearInput{
		FiscalYear:    2026,
		YearStartDate: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
		YearEndDate:   time.Date(2026, 12, 31, 0, 0, 0, 0, time.UTC),
	})

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateCreateFiscalYearInputYearInvalid(t *testing.T) {
	err := ValidateCreateFiscalYearInput(CreateFiscalYearInput{
		TenantID:      "tenant_7",
		FiscalYear:    1999,
		YearStartDate: time.Date(1999, 1, 1, 0, 0, 0, 0, time.UTC),
		YearEndDate:   time.Date(1999, 12, 31, 0, 0, 0, 0, time.UTC),
	})

	if !errors.Is(err, ErrFiscalYearInvalid) {
		t.Fatalf("expected ErrFiscalYearInvalid, got %v", err)
	}
}

func TestValidateCreateFiscalPeriodInputSuccess(t *testing.T) {
	err := ValidateCreateFiscalPeriodInput(CreateFiscalPeriodInput{
		TenantID:        "tenant_7",
		FiscalYear:      2026,
		FiscalPeriod:    "2026-04",
		PeriodNo:        4,
		PeriodStartDate: time.Date(2026, 4, 1, 0, 0, 0, 0, time.UTC),
		PeriodEndDate:   time.Date(2026, 4, 30, 0, 0, 0, 0, time.UTC),
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateFiscalPeriodInputPeriodNoInvalid(t *testing.T) {
	err := ValidateCreateFiscalPeriodInput(CreateFiscalPeriodInput{
		TenantID:        "tenant_7",
		FiscalYear:      2026,
		FiscalPeriod:    "2026-14",
		PeriodNo:        14,
		PeriodStartDate: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
		PeriodEndDate:   time.Date(2026, 1, 31, 0, 0, 0, 0, time.UTC),
	})

	if !errors.Is(err, ErrPeriodNoInvalid) {
		t.Fatalf("expected ErrPeriodNoInvalid, got %v", err)
	}
}

func TestValidateCreateDocumentSequenceInputSuccess(t *testing.T) {
	maxNo := int64(999999)
	fiscalYear := 2026

	err := ValidateCreateDocumentSequenceInput(CreateDocumentSequenceInput{
		TenantID:       "tenant_7",
		DocumentModule: DocumentModuleSales,
		DocumentType:   "invoice",
		FiscalYear:     &fiscalYear,
		Prefix:         "INV-",
		CurrentNo:      0,
		MinNo:          1,
		MaxNo:          &maxNo,
		Padding:        6,
		ResetPolicy:    ResetPolicyYearly,
		IsActive:       true,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateDocumentSequenceInputModuleInvalid(t *testing.T) {
	err := ValidateCreateDocumentSequenceInput(CreateDocumentSequenceInput{
		TenantID:       "tenant_7",
		DocumentModule: DocumentModule("wrong"),
		DocumentType:   "invoice",
		MinNo:          1,
		Padding:        6,
		ResetPolicy:    ResetPolicyYearly,
	})

	if !errors.Is(err, ErrDocumentModuleInvalid) {
		t.Fatalf("expected ErrDocumentModuleInvalid, got %v", err)
	}
}

func TestValidateCreateDocumentSequenceInputNumberRangeInvalid(t *testing.T) {
	maxNo := int64(5)

	err := ValidateCreateDocumentSequenceInput(CreateDocumentSequenceInput{
		TenantID:       "tenant_7",
		DocumentModule: DocumentModuleSales,
		DocumentType:   "invoice",
		MinNo:          10,
		MaxNo:          &maxNo,
		Padding:        6,
		ResetPolicy:    ResetPolicyYearly,
	})

	if !errors.Is(err, ErrNumberRangeInvalid) {
		t.Fatalf("expected ErrNumberRangeInvalid, got %v", err)
	}
}

func TestValidateCreateDocumentNumberAllocationInputSuccess(t *testing.T) {
	fiscalYear := 2026

	err := ValidateCreateDocumentNumberAllocationInput(CreateDocumentNumberAllocationInput{
		TenantID:           "tenant_7",
		DocumentSequenceID: "sequence-id",
		DocumentModule:     DocumentModuleSales,
		DocumentType:       "invoice",
		DocumentNo:         "INV-000001",
		AllocatedNo:        1,
		FiscalYear:         &fiscalYear,
		FiscalPeriod:       "2026-04",
		AllocationStatus:   AllocationStatusAllocated,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateDocumentNumberAllocationInputDocumentNoRequired(t *testing.T) {
	err := ValidateCreateDocumentNumberAllocationInput(CreateDocumentNumberAllocationInput{
		TenantID:           "tenant_7",
		DocumentSequenceID: "sequence-id",
		DocumentModule:     DocumentModuleSales,
		DocumentType:       "invoice",
		AllocatedNo:        1,
	})

	if !errors.Is(err, ErrDocumentNoRequired) {
		t.Fatalf("expected ErrDocumentNoRequired, got %v", err)
	}
}

func TestValidateCreateDocumentNumberAllocationInputAllocatedNoInvalid(t *testing.T) {
	err := ValidateCreateDocumentNumberAllocationInput(CreateDocumentNumberAllocationInput{
		TenantID:           "tenant_7",
		DocumentSequenceID: "sequence-id",
		DocumentModule:     DocumentModuleSales,
		DocumentType:       "invoice",
		DocumentNo:         "INV-000001",
		AllocatedNo:        0,
	})

	if !errors.Is(err, ErrAllocatedNoInvalid) {
		t.Fatalf("expected ErrAllocatedNoInvalid, got %v", err)
	}
}
