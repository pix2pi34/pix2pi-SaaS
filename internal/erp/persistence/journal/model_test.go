package journal

import (
	"errors"
	"testing"
)

func TestValidateCreateJournalEntryInputSuccessDraft(t *testing.T) {
	err := ValidateCreateJournalEntryInput(CreateJournalEntryInput{
		TenantID:     "tenant_7",
		JournalNo:    "JRNL-001",
		SourceModule: JournalSourceManual,
		ExchangeRate: 1,
		TotalDebit:   100,
		TotalCredit:  90,
		Status:       JournalStatusDraft,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateJournalEntryInputSuccessPostedBalanced(t *testing.T) {
	err := ValidateCreateJournalEntryInput(CreateJournalEntryInput{
		TenantID:     "tenant_7",
		JournalNo:    "JRNL-002",
		SourceModule: JournalSourceSales,
		ExchangeRate: 1,
		TotalDebit:   120,
		TotalCredit:  120,
		Status:       JournalStatusPosted,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateJournalEntryInputTenantRequired(t *testing.T) {
	err := ValidateCreateJournalEntryInput(CreateJournalEntryInput{
		JournalNo:    "JRNL-001",
		ExchangeRate: 1,
	})

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateCreateJournalEntryInputJournalNoRequired(t *testing.T) {
	err := ValidateCreateJournalEntryInput(CreateJournalEntryInput{
		TenantID:     "tenant_7",
		ExchangeRate: 1,
	})

	if !errors.Is(err, ErrJournalNoRequired) {
		t.Fatalf("expected ErrJournalNoRequired, got %v", err)
	}
}

func TestValidateCreateJournalEntryInputInvalidSource(t *testing.T) {
	err := ValidateCreateJournalEntryInput(CreateJournalEntryInput{
		TenantID:     "tenant_7",
		JournalNo:    "JRNL-001",
		SourceModule: JournalSourceModule("wrong"),
		ExchangeRate: 1,
	})

	if !errors.Is(err, ErrJournalSourceInvalid) {
		t.Fatalf("expected ErrJournalSourceInvalid, got %v", err)
	}
}

func TestValidateCreateJournalEntryInputPostedMustBalance(t *testing.T) {
	err := ValidateCreateJournalEntryInput(CreateJournalEntryInput{
		TenantID:     "tenant_7",
		JournalNo:    "JRNL-001",
		ExchangeRate: 1,
		TotalDebit:   100,
		TotalCredit:  90,
		Status:       JournalStatusPosted,
	})

	if !errors.Is(err, ErrJournalNotBalanced) {
		t.Fatalf("expected ErrJournalNotBalanced, got %v", err)
	}
}

func TestValidateCreateJournalLineInputDebitSuccess(t *testing.T) {
	err := ValidateCreateJournalLineInput(CreateJournalLineInput{
		TenantID:          "tenant_7",
		JournalEntryID:    "journal-entry-1",
		LineNo:            1,
		AccountCode:       "120",
		DebitAmount:       100,
		CreditAmount:      0,
		ExchangeRate:      1,
		LocalDebitAmount:  100,
		LocalCreditAmount: 0,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateJournalLineInputCreditSuccess(t *testing.T) {
	err := ValidateCreateJournalLineInput(CreateJournalLineInput{
		TenantID:          "tenant_7",
		JournalEntryID:    "journal-entry-1",
		LineNo:            2,
		AccountCode:       "600",
		DebitAmount:       0,
		CreditAmount:      100,
		ExchangeRate:      1,
		LocalDebitAmount:  0,
		LocalCreditAmount: 100,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateJournalLineInputEntryRequired(t *testing.T) {
	err := ValidateCreateJournalLineInput(CreateJournalLineInput{
		TenantID:         "tenant_7",
		LineNo:           1,
		AccountCode:      "120",
		DebitAmount:      100,
		ExchangeRate:     1,
		LocalDebitAmount: 100,
	})

	if !errors.Is(err, ErrJournalEntryIDRequired) {
		t.Fatalf("expected ErrJournalEntryIDRequired, got %v", err)
	}
}

func TestValidateCreateJournalLineInputAccountRequired(t *testing.T) {
	err := ValidateCreateJournalLineInput(CreateJournalLineInput{
		TenantID:         "tenant_7",
		JournalEntryID:   "journal-entry-1",
		LineNo:           1,
		DebitAmount:      100,
		ExchangeRate:     1,
		LocalDebitAmount: 100,
	})

	if !errors.Is(err, ErrAccountCodeRequired) {
		t.Fatalf("expected ErrAccountCodeRequired, got %v", err)
	}
}

func TestValidateCreateJournalLineInputBothDebitAndCreditInvalid(t *testing.T) {
	err := ValidateCreateJournalLineInput(CreateJournalLineInput{
		TenantID:          "tenant_7",
		JournalEntryID:    "journal-entry-1",
		LineNo:            1,
		AccountCode:       "120",
		DebitAmount:       100,
		CreditAmount:      100,
		ExchangeRate:      1,
		LocalDebitAmount:  100,
		LocalCreditAmount: 100,
	})

	if !errors.Is(err, ErrJournalLineSideInvalid) {
		t.Fatalf("expected ErrJournalLineSideInvalid, got %v", err)
	}
}

func TestValidateCreateJournalLineInputNegativeAmountInvalid(t *testing.T) {
	err := ValidateCreateJournalLineInput(CreateJournalLineInput{
		TenantID:         "tenant_7",
		JournalEntryID:   "journal-entry-1",
		LineNo:           1,
		AccountCode:      "120",
		DebitAmount:      -1,
		ExchangeRate:     1,
		LocalDebitAmount: 100,
	})

	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}
