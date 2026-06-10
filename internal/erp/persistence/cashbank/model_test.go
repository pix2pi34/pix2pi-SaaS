package cashbank

import (
	"errors"
	"testing"
)

func TestValidateCreateCashAccountInputSuccess(t *testing.T) {
	err := ValidateCreateCashAccountInput(CreateCashAccountInput{
		TenantID:       "tenant_7",
		CashCode:       "KASA-001",
		CashName:       "Merkez Kasa",
		AccountCode:    "100.01",
		AccountName:    "Merkez Kasa",
		CurrencyCode:   "TRY",
		OpeningBalance: 0,
		CurrentBalance: 0,
		IsActive:       true,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateCashAccountInputTenantRequired(t *testing.T) {
	err := ValidateCreateCashAccountInput(CreateCashAccountInput{
		CashCode: "KASA-001",
		CashName: "Merkez Kasa",
	})

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateCreateCashAccountInputCashCodeRequired(t *testing.T) {
	err := ValidateCreateCashAccountInput(CreateCashAccountInput{
		TenantID: "tenant_7",
		CashName: "Merkez Kasa",
	})

	if !errors.Is(err, ErrCashCodeRequired) {
		t.Fatalf("expected ErrCashCodeRequired, got %v", err)
	}
}

func TestValidateCreateCashAccountInputAmountInvalid(t *testing.T) {
	err := ValidateCreateCashAccountInput(CreateCashAccountInput{
		TenantID:       "tenant_7",
		CashCode:       "KASA-001",
		CashName:       "Merkez Kasa",
		OpeningBalance: -1,
	})

	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}

func TestValidateCreateBankAccountInputSuccess(t *testing.T) {
	err := ValidateCreateBankAccountInput(CreateBankAccountInput{
		TenantID:       "tenant_7",
		BankCode:       "BANK-001",
		BankName:       "Test Bankasi",
		IBAN:           "TR000000000000000000000001",
		AccountCode:    "102.01",
		AccountName:    "Banka Hesabi",
		CurrencyCode:   "TRY",
		OpeningBalance: 0,
		CurrentBalance: 0,
		IsActive:       true,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateBankAccountInputBankCodeRequired(t *testing.T) {
	err := ValidateCreateBankAccountInput(CreateBankAccountInput{
		TenantID: "tenant_7",
		BankName: "Test Bankasi",
	})

	if !errors.Is(err, ErrBankCodeRequired) {
		t.Fatalf("expected ErrBankCodeRequired, got %v", err)
	}
}

func TestValidateCreatePaymentTransactionInputSuccess(t *testing.T) {
	err := ValidateCreatePaymentTransactionInput(CreatePaymentTransactionInput{
		TenantID:         "tenant_7",
		PaymentNo:        "PAY-001",
		PaymentType:      PaymentTypeCollection,
		PaymentDirection: PaymentDirectionIn,
		PaymentMethod:    PaymentMethodCash,
		CashAccountID:    "cash-account-id",
		SourceModule:     PaymentSourceManual,
		CurrencyCode:     "TRY",
		ExchangeRate:     1,
		Amount:           100,
		LocalAmount:      100,
		NetAmount:        100,
		LocalNetAmount:   100,
		Status:           PaymentStatusPosted,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreatePaymentTransactionInputPaymentNoRequired(t *testing.T) {
	err := ValidateCreatePaymentTransactionInput(CreatePaymentTransactionInput{
		TenantID:         "tenant_7",
		PaymentType:      PaymentTypeCollection,
		PaymentDirection: PaymentDirectionIn,
		PaymentMethod:    PaymentMethodCash,
		CashAccountID:    "cash-account-id",
		ExchangeRate:     1,
	})

	if !errors.Is(err, ErrPaymentNoRequired) {
		t.Fatalf("expected ErrPaymentNoRequired, got %v", err)
	}
}

func TestValidateCreatePaymentTransactionInputPaymentTypeInvalid(t *testing.T) {
	err := ValidateCreatePaymentTransactionInput(CreatePaymentTransactionInput{
		TenantID:         "tenant_7",
		PaymentNo:        "PAY-001",
		PaymentType:      PaymentType("wrong"),
		PaymentDirection: PaymentDirectionIn,
		PaymentMethod:    PaymentMethodCash,
		CashAccountID:    "cash-account-id",
		ExchangeRate:     1,
	})

	if !errors.Is(err, ErrPaymentTypeInvalid) {
		t.Fatalf("expected ErrPaymentTypeInvalid, got %v", err)
	}
}

func TestValidateCreatePaymentTransactionInputAccountRequired(t *testing.T) {
	err := ValidateCreatePaymentTransactionInput(CreatePaymentTransactionInput{
		TenantID:         "tenant_7",
		PaymentNo:        "PAY-001",
		PaymentType:      PaymentTypeCollection,
		PaymentDirection: PaymentDirectionIn,
		PaymentMethod:    PaymentMethodCash,
		ExchangeRate:     1,
	})

	if !errors.Is(err, ErrPaymentAccountRequired) {
		t.Fatalf("expected ErrPaymentAccountRequired, got %v", err)
	}
}

func TestValidateCreatePaymentTransactionInputAmountInvalid(t *testing.T) {
	err := ValidateCreatePaymentTransactionInput(CreatePaymentTransactionInput{
		TenantID:         "tenant_7",
		PaymentNo:        "PAY-001",
		PaymentType:      PaymentTypeCollection,
		PaymentDirection: PaymentDirectionIn,
		PaymentMethod:    PaymentMethodCash,
		CashAccountID:    "cash-account-id",
		ExchangeRate:     0,
	})

	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}
