package productcatalog

import (
	"errors"
	"testing"
)

func TestValidateCreateUnitInputSuccess(t *testing.T) {
	input := CreateUnitInput{
		TenantID:         "tenant_7",
		UnitCode:         "ADET",
		UnitName:         "Adet",
		UnitType:         UnitTypeQuantity,
		DecimalPrecision: 0,
		IsBaseUnit:       true,
		CreatedBy:        "faz3_test",
	}

	if err := ValidateCreateUnitInput(input); err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
}

func TestValidateCreateUnitInputTenantRequired(t *testing.T) {
	err := ValidateCreateUnitInput(CreateUnitInput{
		UnitCode: "ADET",
		UnitName: "Adet",
	})

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateCreateUnitInputInvalidType(t *testing.T) {
	err := ValidateCreateUnitInput(CreateUnitInput{
		TenantID:         "tenant_7",
		UnitCode:         "BAD",
		UnitName:         "Bad",
		UnitType:         UnitType("wrong"),
		DecimalPrecision: 2,
	})

	if !errors.Is(err, ErrUnitTypeInvalid) {
		t.Fatalf("expected ErrUnitTypeInvalid, got %v", err)
	}
}

func TestValidateCreateUnitInputDecimalPrecisionRange(t *testing.T) {
	err := ValidateCreateUnitInput(CreateUnitInput{
		TenantID:         "tenant_7",
		UnitCode:         "KG",
		UnitName:         "Kilogram",
		UnitType:         UnitTypeWeight,
		DecimalPrecision: 9,
	})

	if !errors.Is(err, ErrDecimalPrecisionRange) {
		t.Fatalf("expected ErrDecimalPrecisionRange, got %v", err)
	}
}

func TestValidateCreateCategoryInputSuccess(t *testing.T) {
	input := CreateCategoryInput{
		TenantID:     "tenant_7",
		CategoryCode: "GIDA",
		CategoryName: "Gıda",
		Description:  "Market gıda ürünleri",
		CreatedBy:    "faz3_test",
	}

	if err := ValidateCreateCategoryInput(input); err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
}

func TestValidateCreateCategoryInputCodeRequired(t *testing.T) {
	err := ValidateCreateCategoryInput(CreateCategoryInput{
		TenantID:     "tenant_7",
		CategoryName: "Gıda",
	})

	if !errors.Is(err, ErrCategoryCodeRequired) {
		t.Fatalf("expected ErrCategoryCodeRequired, got %v", err)
	}
}

func TestValidateCreateCategoryInputNameRequired(t *testing.T) {
	err := ValidateCreateCategoryInput(CreateCategoryInput{
		TenantID:     "tenant_7",
		CategoryCode: "GIDA",
	})

	if !errors.Is(err, ErrCategoryNameRequired) {
		t.Fatalf("expected ErrCategoryNameRequired, got %v", err)
	}
}

func TestValidateCreateItemInputSuccess(t *testing.T) {
	input := CreateItemInput{
		TenantID:           "tenant_7",
		ItemCode:           "ITEM-001",
		ItemName:           "Test Ürün",
		ItemType:           ItemTypeStock,
		BaseUnitID:         "unit-1",
		Barcode:            "8690000000001",
		SKU:                "SKU-001",
		VATRate:            20,
		IsInventoryTracked: true,
		IsSalesAllowed:     true,
		IsPurchaseAllowed:  true,
		CreatedBy:          "faz3_test",
	}

	if err := ValidateCreateItemInput(input); err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
}

func TestValidateCreateItemInputBaseUnitRequired(t *testing.T) {
	err := ValidateCreateItemInput(CreateItemInput{
		TenantID: "tenant_7",
		ItemCode: "ITEM-001",
		ItemName: "Test Ürün",
		ItemType: ItemTypeStock,
		VATRate:  20,
	})

	if !errors.Is(err, ErrBaseUnitIDRequired) {
		t.Fatalf("expected ErrBaseUnitIDRequired, got %v", err)
	}
}

func TestValidateCreateItemInputVATRateInvalid(t *testing.T) {
	err := ValidateCreateItemInput(CreateItemInput{
		TenantID:   "tenant_7",
		ItemCode:   "ITEM-001",
		ItemName:   "Test Ürün",
		ItemType:   ItemTypeStock,
		BaseUnitID: "unit-1",
		VATRate:    150,
	})

	if !errors.Is(err, ErrVATRateInvalid) {
		t.Fatalf("expected ErrVATRateInvalid, got %v", err)
	}
}

func TestValidateCreateItemInputInvalidType(t *testing.T) {
	err := ValidateCreateItemInput(CreateItemInput{
		TenantID:   "tenant_7",
		ItemCode:   "ITEM-001",
		ItemName:   "Test Ürün",
		ItemType:   ItemType("wrong"),
		BaseUnitID: "unit-1",
		VATRate:    20,
	})

	if !errors.Is(err, ErrItemTypeInvalid) {
		t.Fatalf("expected ErrItemTypeInvalid, got %v", err)
	}
}

func TestValidateCreateProductInputSuccess(t *testing.T) {
	input := CreateProductInput{
		TenantID:           "tenant_7",
		ItemID:             "item-1",
		ProductCode:        "PRD-001",
		ProductName:        "Satış Ürünü",
		ShortDescription:   "POS satış ürünü",
		DefaultSalesUnitID: "unit-1",
		IsSellable:         true,
		IsVisiblePOS:       true,
		IsVisibleWeb:       false,
		CreatedBy:          "faz3_test",
	}

	if err := ValidateCreateProductInput(input); err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
}

func TestValidateCreateProductInputItemIDRequired(t *testing.T) {
	err := ValidateCreateProductInput(CreateProductInput{
		TenantID:    "tenant_7",
		ProductCode: "PRD-001",
		ProductName: "Satış Ürünü",
	})

	if !errors.Is(err, ErrItemIDRequired) {
		t.Fatalf("expected ErrItemIDRequired, got %v", err)
	}
}

func TestValidateCreateProductInputCodeRequired(t *testing.T) {
	err := ValidateCreateProductInput(CreateProductInput{
		TenantID:    "tenant_7",
		ItemID:      "item-1",
		ProductName: "Satış Ürünü",
	})

	if !errors.Is(err, ErrProductCodeRequired) {
		t.Fatalf("expected ErrProductCodeRequired, got %v", err)
	}
}

func TestValidateCreateProductInputNameRequired(t *testing.T) {
	err := ValidateCreateProductInput(CreateProductInput{
		TenantID:    "tenant_7",
		ItemID:      "item-1",
		ProductCode: "PRD-001",
	})

	if !errors.Is(err, ErrProductNameRequired) {
		t.Fatalf("expected ErrProductNameRequired, got %v", err)
	}
}
