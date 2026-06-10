package masterparty

import (
	"errors"
	"testing"
)

func TestValidateCreatePartyInputSuccessOrganization(t *testing.T) {
	input := CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypeOrganization,
		DisplayName: "Test Market A.Ş.",
		LegalName:   "Test Market Anonim Şirketi",
		TaxNo:       "1234567890",
		TaxOffice:   "Kadıköy",
		Email:       "info@testmarket.com",
		Source:      "manual",
		CreatedBy:   "faz3_test",
	}

	if err := ValidateCreatePartyInput(input); err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
}

func TestValidateCreatePartyInputSuccessPerson(t *testing.T) {
	input := CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypePerson,
		DisplayName: "Ali Veli",
		Email:       "ali@example.com",
		Source:      "manual",
		CreatedBy:   "faz3_test",
	}

	if err := ValidateCreatePartyInput(input); err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
}

func TestValidateCreatePartyInputTenantRequired(t *testing.T) {
	input := CreatePartyInput{
		PartyType:   PartyTypeOrganization,
		DisplayName: "Test Market A.Ş.",
		TaxNo:       "1234567890",
		TaxOffice:   "Kadıköy",
	}

	err := ValidateCreatePartyInput(input)

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateCreatePartyInputPartyTypeRequired(t *testing.T) {
	input := CreatePartyInput{
		TenantID:    "tenant_7",
		DisplayName: "Test Market A.Ş.",
		TaxNo:       "1234567890",
		TaxOffice:   "Kadıköy",
	}

	err := ValidateCreatePartyInput(input)

	if !errors.Is(err, ErrPartyTypeRequired) {
		t.Fatalf("expected ErrPartyTypeRequired, got %v", err)
	}
}

func TestValidateCreatePartyInputPartyTypeInvalid(t *testing.T) {
	input := CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyType("company"),
		DisplayName: "Test Market A.Ş.",
		TaxNo:       "1234567890",
		TaxOffice:   "Kadıköy",
	}

	err := ValidateCreatePartyInput(input)

	if !errors.Is(err, ErrPartyTypeInvalid) {
		t.Fatalf("expected ErrPartyTypeInvalid, got %v", err)
	}
}

func TestValidateCreatePartyInputDisplayNameRequired(t *testing.T) {
	input := CreatePartyInput{
		TenantID:  "tenant_7",
		PartyType: PartyTypeOrganization,
		TaxNo:     "1234567890",
		TaxOffice: "Kadıköy",
	}

	err := ValidateCreatePartyInput(input)

	if !errors.Is(err, ErrDisplayNameRequired) {
		t.Fatalf("expected ErrDisplayNameRequired, got %v", err)
	}
}

func TestValidateCreatePartyInputInvalidEmail(t *testing.T) {
	input := CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypeOrganization,
		DisplayName: "Test Market A.Ş.",
		TaxNo:       "1234567890",
		TaxOffice:   "Kadıköy",
		Email:       "hatali-email",
	}

	err := ValidateCreatePartyInput(input)

	if !errors.Is(err, ErrEmailInvalid) {
		t.Fatalf("expected ErrEmailInvalid, got %v", err)
	}
}

func TestValidateCreatePartyInputOrganizationTaxNoRequired(t *testing.T) {
	input := CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypeOrganization,
		DisplayName: "Test Market A.Ş.",
		TaxOffice:   "Kadıköy",
	}

	err := ValidateCreatePartyInput(input)

	if !errors.Is(err, ErrTaxNoRequired) {
		t.Fatalf("expected ErrTaxNoRequired, got %v", err)
	}
}

func TestValidateCreatePartyInputOrganizationTaxOfficeRequired(t *testing.T) {
	input := CreatePartyInput{
		TenantID:    "tenant_7",
		PartyType:   PartyTypeOrganization,
		DisplayName: "Test Market A.Ş.",
		TaxNo:       "1234567890",
	}

	err := ValidateCreatePartyInput(input)

	if !errors.Is(err, ErrTaxOfficeRequired) {
		t.Fatalf("expected ErrTaxOfficeRequired, got %v", err)
	}
}
