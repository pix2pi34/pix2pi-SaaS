package tax

import (
	"errors"
	"testing"
	"time"
)

func TestValidateCreateTaxCodeInputSuccess(t *testing.T) {
	err := ValidateCreateTaxCodeInput(CreateTaxCodeInput{
		TenantID:      "tenant_7",
		TaxCode:       "KDV20",
		TaxName:       "KDV %20",
		TaxType:       TaxTypeVAT,
		AccountCode:   "391.01.20",
		AccountName:   "Hesaplanan KDV",
		IsRecoverable: false,
		IsPayable:     true,
		IsActive:      true,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateTaxCodeInputTenantRequired(t *testing.T) {
	err := ValidateCreateTaxCodeInput(CreateTaxCodeInput{
		TaxCode: "KDV20",
		TaxName: "KDV %20",
		TaxType: TaxTypeVAT,
	})

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateCreateTaxCodeInputTaxCodeRequired(t *testing.T) {
	err := ValidateCreateTaxCodeInput(CreateTaxCodeInput{
		TenantID: "tenant_7",
		TaxName:  "KDV %20",
		TaxType:  TaxTypeVAT,
	})

	if !errors.Is(err, ErrTaxCodeRequired) {
		t.Fatalf("expected ErrTaxCodeRequired, got %v", err)
	}
}

func TestValidateCreateTaxCodeInputTaxTypeInvalid(t *testing.T) {
	err := ValidateCreateTaxCodeInput(CreateTaxCodeInput{
		TenantID: "tenant_7",
		TaxCode:  "BAD",
		TaxName:  "Bad Tax",
		TaxType:  TaxType("wrong"),
	})

	if !errors.Is(err, ErrTaxTypeInvalid) {
		t.Fatalf("expected ErrTaxTypeInvalid, got %v", err)
	}
}

func TestValidateCreateTaxRateInputSuccess(t *testing.T) {
	num := 7
	den := 10
	validTo := time.Now().AddDate(0, 1, 0)

	err := ValidateCreateTaxRateInput(CreateTaxRateInput{
		TenantID:               "tenant_7",
		TaxCodeID:              "tax-code-id",
		TaxCode:                "TEVK7_10",
		RatePercent:            20,
		WithholdingNumerator:   &num,
		WithholdingDenominator: &den,
		ValidFrom:              time.Now(),
		ValidTo:                &validTo,
		IsDefault:              true,
		IsActive:               true,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateTaxRateInputTaxCodeIDRequired(t *testing.T) {
	err := ValidateCreateTaxRateInput(CreateTaxRateInput{
		TenantID:    "tenant_7",
		TaxCode:     "KDV20",
		RatePercent: 20,
	})

	if !errors.Is(err, ErrTaxCodeIDRequired) {
		t.Fatalf("expected ErrTaxCodeIDRequired, got %v", err)
	}
}

func TestValidateCreateTaxRateInputRateInvalid(t *testing.T) {
	err := ValidateCreateTaxRateInput(CreateTaxRateInput{
		TenantID:    "tenant_7",
		TaxCodeID:   "tax-code-id",
		TaxCode:     "KDV120",
		RatePercent: 120,
	})

	if !errors.Is(err, ErrRateInvalid) {
		t.Fatalf("expected ErrRateInvalid, got %v", err)
	}
}

func TestValidateCreateTaxRateInputWithholdingRatioInvalid(t *testing.T) {
	num := 11
	den := 10

	err := ValidateCreateTaxRateInput(CreateTaxRateInput{
		TenantID:               "tenant_7",
		TaxCodeID:              "tax-code-id",
		TaxCode:                "TEVK11_10",
		RatePercent:            20,
		WithholdingNumerator:   &num,
		WithholdingDenominator: &den,
	})

	if !errors.Is(err, ErrWithholdingRatioInvalid) {
		t.Fatalf("expected ErrWithholdingRatioInvalid, got %v", err)
	}
}

func TestValidateCreateTaxTransactionInputSuccess(t *testing.T) {
	err := ValidateCreateTaxTransactionInput(CreateTaxTransactionInput{
		TenantID:        "tenant_7",
		TaxCode:         "KDV20",
		TaxName:         "KDV %20",
		TaxType:         TaxTypeVAT,
		SourceModule:    TaxSourceSales,
		FiscalYear:      2026,
		FiscalPeriod:    "2026-04",
		BaseAmount:      100,
		RatePercent:     20,
		TaxAmount:       20,
		PayableAmount:   20,
		CurrencyCode:    "TRY",
		ExchangeRate:    1,
		LocalBaseAmount: 100,
		LocalTaxAmount:  20,
		Direction:       TaxDirectionPayable,
		Status:          TaxTransactionStatusPosted,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateTaxTransactionInputFiscalPeriodRequired(t *testing.T) {
	err := ValidateCreateTaxTransactionInput(CreateTaxTransactionInput{
		TenantID:     "tenant_7",
		TaxCode:      "KDV20",
		TaxType:      TaxTypeVAT,
		SourceModule: TaxSourceSales,
		FiscalYear:   2026,
		ExchangeRate: 1,
		Direction:    TaxDirectionPayable,
	})

	if !errors.Is(err, ErrFiscalPeriodRequired) {
		t.Fatalf("expected ErrFiscalPeriodRequired, got %v", err)
	}
}

func TestValidateCreateTaxTransactionInputDirectionInvalid(t *testing.T) {
	err := ValidateCreateTaxTransactionInput(CreateTaxTransactionInput{
		TenantID:     "tenant_7",
		TaxCode:      "KDV20",
		TaxType:      TaxTypeVAT,
		SourceModule: TaxSourceSales,
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		ExchangeRate: 1,
		Direction:    TaxDirection("wrong"),
	})

	if !errors.Is(err, ErrDirectionInvalid) {
		t.Fatalf("expected ErrDirectionInvalid, got %v", err)
	}
}

func TestValidateCreateTaxTransactionInputAmountInvalid(t *testing.T) {
	err := ValidateCreateTaxTransactionInput(CreateTaxTransactionInput{
		TenantID:     "tenant_7",
		TaxCode:      "KDV20",
		TaxType:      TaxTypeVAT,
		SourceModule: TaxSourceSales,
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		BaseAmount:   -1,
		ExchangeRate: 1,
		Direction:    TaxDirectionPayable,
	})

	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}
