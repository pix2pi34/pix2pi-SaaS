package ledger

import (
	"errors"
	"testing"
)

func TestValidateCreateAccountMovementInputDebitSuccess(t *testing.T) {
	err := ValidateCreateAccountMovementInput(CreateAccountMovementInput{
		TenantID:          "tenant_7",
		JournalEntryID:    "journal-entry-1",
		JournalLineID:     "journal-line-1",
		FiscalYear:        2026,
		FiscalPeriod:      "2026-04",
		AccountCode:       "120",
		DebitAmount:       120,
		CreditAmount:      0,
		CurrencyCode:      "TRY",
		ExchangeRate:      1,
		LocalDebitAmount:  120,
		LocalCreditAmount: 0,
		Direction:         MovementDirectionDebit,
		SourceModule:      LedgerSourceManual,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateAccountMovementInputCreditSuccess(t *testing.T) {
	err := ValidateCreateAccountMovementInput(CreateAccountMovementInput{
		TenantID:          "tenant_7",
		JournalEntryID:    "journal-entry-1",
		JournalLineID:     "journal-line-1",
		FiscalYear:        2026,
		FiscalPeriod:      "2026-04",
		AccountCode:       "600",
		DebitAmount:       0,
		CreditAmount:      120,
		CurrencyCode:      "TRY",
		ExchangeRate:      1,
		LocalDebitAmount:  0,
		LocalCreditAmount: 120,
		Direction:         MovementDirectionCredit,
		SourceModule:      LedgerSourceSales,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateAccountMovementInputTenantRequired(t *testing.T) {
	err := ValidateCreateAccountMovementInput(CreateAccountMovementInput{
		JournalEntryID:   "journal-entry-1",
		JournalLineID:    "journal-line-1",
		FiscalYear:       2026,
		FiscalPeriod:     "2026-04",
		AccountCode:      "120",
		DebitAmount:      120,
		ExchangeRate:     1,
		LocalDebitAmount: 120,
		Direction:        MovementDirectionDebit,
	})

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateCreateAccountMovementInputJournalEntryRequired(t *testing.T) {
	err := ValidateCreateAccountMovementInput(CreateAccountMovementInput{
		TenantID:         "tenant_7",
		JournalLineID:    "journal-line-1",
		FiscalYear:       2026,
		FiscalPeriod:     "2026-04",
		AccountCode:      "120",
		DebitAmount:      120,
		ExchangeRate:     1,
		LocalDebitAmount: 120,
		Direction:        MovementDirectionDebit,
	})

	if !errors.Is(err, ErrJournalEntryIDRequired) {
		t.Fatalf("expected ErrJournalEntryIDRequired, got %v", err)
	}
}

func TestValidateCreateAccountMovementInputDirectionInvalid(t *testing.T) {
	err := ValidateCreateAccountMovementInput(CreateAccountMovementInput{
		TenantID:         "tenant_7",
		JournalEntryID:   "journal-entry-1",
		JournalLineID:    "journal-line-1",
		FiscalYear:       2026,
		FiscalPeriod:     "2026-04",
		AccountCode:      "120",
		DebitAmount:      120,
		ExchangeRate:     1,
		LocalDebitAmount: 120,
		Direction:        MovementDirection("wrong"),
	})

	if !errors.Is(err, ErrDirectionInvalid) {
		t.Fatalf("expected ErrDirectionInvalid, got %v", err)
	}
}

func TestValidateCreateAccountMovementInputDebitAmountInvalid(t *testing.T) {
	err := ValidateCreateAccountMovementInput(CreateAccountMovementInput{
		TenantID:          "tenant_7",
		JournalEntryID:    "journal-entry-1",
		JournalLineID:     "journal-line-1",
		FiscalYear:        2026,
		FiscalPeriod:      "2026-04",
		AccountCode:       "120",
		DebitAmount:       0,
		CreditAmount:      120,
		ExchangeRate:      1,
		LocalDebitAmount:  0,
		LocalCreditAmount: 120,
		Direction:         MovementDirectionDebit,
	})

	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}

func TestValidateCreateLedgerBalanceInputDebitSuccess(t *testing.T) {
	err := ValidateCreateLedgerBalanceInput(CreateLedgerBalanceInput{
		TenantID:           "tenant_7",
		FiscalYear:         2026,
		FiscalPeriod:       "2026-04",
		AccountCode:        "120",
		CurrencyCode:       "TRY",
		PeriodDebitAmount:  120,
		ClosingDebitAmount: 120,
		BalanceSide:        LedgerBalanceSideDebit,
		BalanceAmount:      120,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateLedgerBalanceInputZeroSuccess(t *testing.T) {
	err := ValidateCreateLedgerBalanceInput(CreateLedgerBalanceInput{
		TenantID:      "tenant_7",
		FiscalYear:    2026,
		FiscalPeriod:  "2026-04",
		AccountCode:   "120",
		CurrencyCode:  "TRY",
		BalanceSide:   LedgerBalanceSideZero,
		BalanceAmount: 0,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateLedgerBalanceInputFiscalPeriodRequired(t *testing.T) {
	err := ValidateCreateLedgerBalanceInput(CreateLedgerBalanceInput{
		TenantID:    "tenant_7",
		FiscalYear:  2026,
		AccountCode: "120",
		BalanceSide: LedgerBalanceSideZero,
	})

	if !errors.Is(err, ErrFiscalPeriodRequired) {
		t.Fatalf("expected ErrFiscalPeriodRequired, got %v", err)
	}
}

func TestValidateCreateLedgerBalanceInputAccountCodeRequired(t *testing.T) {
	err := ValidateCreateLedgerBalanceInput(CreateLedgerBalanceInput{
		TenantID:     "tenant_7",
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		BalanceSide:  LedgerBalanceSideZero,
	})

	if !errors.Is(err, ErrAccountCodeRequired) {
		t.Fatalf("expected ErrAccountCodeRequired, got %v", err)
	}
}

func TestValidateCreateLedgerBalanceInputBalanceSideInvalid(t *testing.T) {
	err := ValidateCreateLedgerBalanceInput(CreateLedgerBalanceInput{
		TenantID:      "tenant_7",
		FiscalYear:    2026,
		FiscalPeriod:  "2026-04",
		AccountCode:   "120",
		BalanceSide:   LedgerBalanceSide("wrong"),
		BalanceAmount: 0,
	})

	if !errors.Is(err, ErrBalanceSideInvalid) {
		t.Fatalf("expected ErrBalanceSideInvalid, got %v", err)
	}
}

func TestValidateCreateLedgerBalanceInputZeroMustHaveZeroAmount(t *testing.T) {
	err := ValidateCreateLedgerBalanceInput(CreateLedgerBalanceInput{
		TenantID:      "tenant_7",
		FiscalYear:    2026,
		FiscalPeriod:  "2026-04",
		AccountCode:   "120",
		BalanceSide:   LedgerBalanceSideZero,
		BalanceAmount: 10,
	})

	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}
