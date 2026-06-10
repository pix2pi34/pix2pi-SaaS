package chartofaccounts

import (
	"errors"
	"testing"
)

func TestValidateCreateChartAccountInputSuccess(t *testing.T) {
	vatRate := 20.0

	err := ValidateCreateChartAccountInput(CreateChartAccountInput{
		TenantID:      "tenant_7",
		AccountCode:   "120",
		AccountName:   "Alicilar",
		AccountLevel:  1,
		AccountType:   AccountTypeAsset,
		NormalBalance: NormalBalanceDebit,
		IsPostable:    true,
		IsActive:      true,
		CurrencyCode:  "TRY",
		TaxCode:       "KDV20",
		VATRate:       &vatRate,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateChartAccountInputTenantRequired(t *testing.T) {
	err := ValidateCreateChartAccountInput(CreateChartAccountInput{
		AccountCode:   "120",
		AccountName:   "Alicilar",
		AccountLevel:  1,
		AccountType:   AccountTypeAsset,
		NormalBalance: NormalBalanceDebit,
	})

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateCreateChartAccountInputAccountCodeRequired(t *testing.T) {
	err := ValidateCreateChartAccountInput(CreateChartAccountInput{
		TenantID:      "tenant_7",
		AccountName:   "Alicilar",
		AccountLevel:  1,
		AccountType:   AccountTypeAsset,
		NormalBalance: NormalBalanceDebit,
	})

	if !errors.Is(err, ErrAccountCodeRequired) {
		t.Fatalf("expected ErrAccountCodeRequired, got %v", err)
	}
}

func TestValidateCreateChartAccountInputAccountTypeInvalid(t *testing.T) {
	err := ValidateCreateChartAccountInput(CreateChartAccountInput{
		TenantID:      "tenant_7",
		AccountCode:   "120",
		AccountName:   "Alicilar",
		AccountLevel:  1,
		AccountType:   AccountType("wrong"),
		NormalBalance: NormalBalanceDebit,
	})

	if !errors.Is(err, ErrAccountTypeInvalid) {
		t.Fatalf("expected ErrAccountTypeInvalid, got %v", err)
	}
}

func TestValidateCreateChartAccountInputNormalBalanceInvalid(t *testing.T) {
	err := ValidateCreateChartAccountInput(CreateChartAccountInput{
		TenantID:      "tenant_7",
		AccountCode:   "120",
		AccountName:   "Alicilar",
		AccountLevel:  1,
		AccountType:   AccountTypeAsset,
		NormalBalance: NormalBalance("wrong"),
	})

	if !errors.Is(err, ErrNormalBalanceInvalid) {
		t.Fatalf("expected ErrNormalBalanceInvalid, got %v", err)
	}
}

func TestValidateCreateChartAccountInputVATRateInvalid(t *testing.T) {
	vatRate := 120.0

	err := ValidateCreateChartAccountInput(CreateChartAccountInput{
		TenantID:      "tenant_7",
		AccountCode:   "391.01.20",
		AccountName:   "Hesaplanan KDV",
		AccountLevel:  3,
		AccountType:   AccountTypeTax,
		NormalBalance: NormalBalanceCredit,
		VATRate:       &vatRate,
	})

	if !errors.Is(err, ErrVATRateInvalid) {
		t.Fatalf("expected ErrVATRateInvalid, got %v", err)
	}
}

func TestValidateCreateAccountMappingRuleInputSuccess(t *testing.T) {
	vatRate := 20.0

	err := ValidateCreateAccountMappingRuleInput(CreateAccountMappingRuleInput{
		TenantID:           "tenant_7",
		MappingKey:         "sales.invoice.receivable",
		SourceModule:       MappingSourceSales,
		SourceDocumentType: "invoice",
		EventType:          "sales.invoice.posted",
		LineType:           "receivable",
		AccountCode:        "120",
		AccountName:        "Alicilar",
		VATRate:            &vatRate,
		Priority:           100,
		IsDefault:          true,
		IsActive:           true,
	})

	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateCreateAccountMappingRuleInputMappingKeyRequired(t *testing.T) {
	err := ValidateCreateAccountMappingRuleInput(CreateAccountMappingRuleInput{
		TenantID:     "tenant_7",
		SourceModule: MappingSourceSales,
		AccountCode:  "120",
		Priority:     100,
	})

	if !errors.Is(err, ErrMappingKeyRequired) {
		t.Fatalf("expected ErrMappingKeyRequired, got %v", err)
	}
}

func TestValidateCreateAccountMappingRuleInputSourceInvalid(t *testing.T) {
	err := ValidateCreateAccountMappingRuleInput(CreateAccountMappingRuleInput{
		TenantID:     "tenant_7",
		MappingKey:   "bad.source",
		SourceModule: MappingSourceModule("wrong"),
		AccountCode:  "120",
		Priority:     100,
	})

	if !errors.Is(err, ErrSourceModuleInvalid) {
		t.Fatalf("expected ErrSourceModuleInvalid, got %v", err)
	}
}

func TestValidateCreateAccountMappingRuleInputAccountCodeRequired(t *testing.T) {
	err := ValidateCreateAccountMappingRuleInput(CreateAccountMappingRuleInput{
		TenantID:     "tenant_7",
		MappingKey:   "sales.invoice.receivable",
		SourceModule: MappingSourceSales,
		Priority:     100,
	})

	if !errors.Is(err, ErrAccountCodeRequired) {
		t.Fatalf("expected ErrAccountCodeRequired, got %v", err)
	}
}

func TestValidateCreateAccountMappingRuleInputPriorityInvalid(t *testing.T) {
	err := ValidateCreateAccountMappingRuleInput(CreateAccountMappingRuleInput{
		TenantID:     "tenant_7",
		MappingKey:   "sales.invoice.receivable",
		SourceModule: MappingSourceSales,
		AccountCode:  "120",
		Priority:     0,
	})

	if !errors.Is(err, ErrPriorityInvalid) {
		t.Fatalf("expected ErrPriorityInvalid, got %v", err)
	}
}
