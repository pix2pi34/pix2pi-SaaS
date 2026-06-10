package inventory

import (
	"errors"
	"testing"
)

func TestValidateCreateWarehouseInputSuccess(t *testing.T) {
	input := CreateWarehouseInput{
		TenantID:      "tenant_7",
		WarehouseCode: "WH-001",
		WarehouseName: "Ana Depo",
		WarehouseType: WarehouseTypeMain,
		City:          "Istanbul",
		District:      "Kadikoy",
		AddressLine:   "Test adres",
		IsDefault:     true,
		CreatedBy:     "faz3_test",
	}

	if err := ValidateCreateWarehouseInput(input); err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
}

func TestValidateCreateWarehouseInputTenantRequired(t *testing.T) {
	err := ValidateCreateWarehouseInput(CreateWarehouseInput{
		WarehouseCode: "WH-001",
		WarehouseName: "Ana Depo",
		WarehouseType: WarehouseTypeMain,
	})

	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateCreateWarehouseInputCodeRequired(t *testing.T) {
	err := ValidateCreateWarehouseInput(CreateWarehouseInput{
		TenantID:      "tenant_7",
		WarehouseName: "Ana Depo",
		WarehouseType: WarehouseTypeMain,
	})

	if !errors.Is(err, ErrWarehouseCodeRequired) {
		t.Fatalf("expected ErrWarehouseCodeRequired, got %v", err)
	}
}

func TestValidateCreateWarehouseInputNameRequired(t *testing.T) {
	err := ValidateCreateWarehouseInput(CreateWarehouseInput{
		TenantID:      "tenant_7",
		WarehouseCode: "WH-001",
		WarehouseType: WarehouseTypeMain,
	})

	if !errors.Is(err, ErrWarehouseNameRequired) {
		t.Fatalf("expected ErrWarehouseNameRequired, got %v", err)
	}
}

func TestValidateCreateWarehouseInputInvalidType(t *testing.T) {
	err := ValidateCreateWarehouseInput(CreateWarehouseInput{
		TenantID:      "tenant_7",
		WarehouseCode: "WH-001",
		WarehouseName: "Ana Depo",
		WarehouseType: WarehouseType("wrong"),
	})

	if !errors.Is(err, ErrWarehouseTypeInvalid) {
		t.Fatalf("expected ErrWarehouseTypeInvalid, got %v", err)
	}
}

func TestValidateCreateStockMovementInputSuccess(t *testing.T) {
	input := CreateStockMovementInput{
		TenantID:          "tenant_7",
		MovementNo:        "MOV-001",
		MovementType:      StockMovementTypeOpening,
		MovementDirection: StockMovementDirectionIn,
		WarehouseID:       "warehouse-1",
		ItemID:            "item-1",
		UnitID:            "unit-1",
		Quantity:          10,
		UnitCost:          5,
		TotalCost:         50,
		SourceType:        "integration_test",
		SourceID:          "source-1",
		CreatedBy:         "faz3_test",
	}

	if err := ValidateCreateStockMovementInput(input); err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
}

func TestValidateCreateStockMovementInputMovementNoRequired(t *testing.T) {
	err := ValidateCreateStockMovementInput(CreateStockMovementInput{
		TenantID:          "tenant_7",
		MovementType:      StockMovementTypeOpening,
		MovementDirection: StockMovementDirectionIn,
		WarehouseID:       "warehouse-1",
		ItemID:            "item-1",
		UnitID:            "unit-1",
		Quantity:          10,
	})

	if !errors.Is(err, ErrMovementNoRequired) {
		t.Fatalf("expected ErrMovementNoRequired, got %v", err)
	}
}

func TestValidateCreateStockMovementInputInvalidType(t *testing.T) {
	err := ValidateCreateStockMovementInput(CreateStockMovementInput{
		TenantID:          "tenant_7",
		MovementNo:        "MOV-001",
		MovementType:      StockMovementType("wrong"),
		MovementDirection: StockMovementDirectionIn,
		WarehouseID:       "warehouse-1",
		ItemID:            "item-1",
		UnitID:            "unit-1",
		Quantity:          10,
	})

	if !errors.Is(err, ErrMovementTypeInvalid) {
		t.Fatalf("expected ErrMovementTypeInvalid, got %v", err)
	}
}

func TestValidateCreateStockMovementInputInvalidDirection(t *testing.T) {
	err := ValidateCreateStockMovementInput(CreateStockMovementInput{
		TenantID:          "tenant_7",
		MovementNo:        "MOV-001",
		MovementType:      StockMovementTypeOpening,
		MovementDirection: StockMovementDirection("wrong"),
		WarehouseID:       "warehouse-1",
		ItemID:            "item-1",
		UnitID:            "unit-1",
		Quantity:          10,
	})

	if !errors.Is(err, ErrMovementDirectionInvalid) {
		t.Fatalf("expected ErrMovementDirectionInvalid, got %v", err)
	}
}

func TestValidateCreateStockMovementInputQuantityPositive(t *testing.T) {
	err := ValidateCreateStockMovementInput(CreateStockMovementInput{
		TenantID:          "tenant_7",
		MovementNo:        "MOV-001",
		MovementType:      StockMovementTypeOpening,
		MovementDirection: StockMovementDirectionIn,
		WarehouseID:       "warehouse-1",
		ItemID:            "item-1",
		UnitID:            "unit-1",
		Quantity:          0,
	})

	if !errors.Is(err, ErrQuantityMustBePositive) {
		t.Fatalf("expected ErrQuantityMustBePositive, got %v", err)
	}
}

func TestValidateCreateStockMovementInputCostInvalid(t *testing.T) {
	err := ValidateCreateStockMovementInput(CreateStockMovementInput{
		TenantID:          "tenant_7",
		MovementNo:        "MOV-001",
		MovementType:      StockMovementTypeOpening,
		MovementDirection: StockMovementDirectionIn,
		WarehouseID:       "warehouse-1",
		ItemID:            "item-1",
		UnitID:            "unit-1",
		Quantity:          1,
		UnitCost:          -1,
	})

	if !errors.Is(err, ErrCostInvalid) {
		t.Fatalf("expected ErrCostInvalid, got %v", err)
	}
}

func TestValidateCreateWarehouseBalanceInputSuccess(t *testing.T) {
	input := CreateWarehouseBalanceInput{
		TenantID:          "tenant_7",
		WarehouseID:       "warehouse-1",
		ItemID:            "item-1",
		UnitID:            "unit-1",
		OnHandQuantity:    10,
		ReservedQuantity:  2,
		AvailableQuantity: 8,
		CreatedBy:         "faz3_test",
	}

	if err := ValidateCreateWarehouseBalanceInput(input); err != nil {
		t.Fatalf("expected success, got error: %v", err)
	}
}

func TestValidateCreateWarehouseBalanceInputWarehouseRequired(t *testing.T) {
	err := ValidateCreateWarehouseBalanceInput(CreateWarehouseBalanceInput{
		TenantID:          "tenant_7",
		ItemID:            "item-1",
		UnitID:            "unit-1",
		OnHandQuantity:    10,
		ReservedQuantity:  2,
		AvailableQuantity: 8,
	})

	if !errors.Is(err, ErrWarehouseIDRequired) {
		t.Fatalf("expected ErrWarehouseIDRequired, got %v", err)
	}
}

func TestValidateCreateWarehouseBalanceInputQuantityInvalidNegative(t *testing.T) {
	err := ValidateCreateWarehouseBalanceInput(CreateWarehouseBalanceInput{
		TenantID:          "tenant_7",
		WarehouseID:       "warehouse-1",
		ItemID:            "item-1",
		UnitID:            "unit-1",
		OnHandQuantity:    -1,
		ReservedQuantity:  0,
		AvailableQuantity: 0,
	})

	if !errors.Is(err, ErrBalanceQuantityInvalid) {
		t.Fatalf("expected ErrBalanceQuantityInvalid, got %v", err)
	}
}

func TestValidateCreateWarehouseBalanceInputAvailableGreaterThanOnHand(t *testing.T) {
	err := ValidateCreateWarehouseBalanceInput(CreateWarehouseBalanceInput{
		TenantID:          "tenant_7",
		WarehouseID:       "warehouse-1",
		ItemID:            "item-1",
		UnitID:            "unit-1",
		OnHandQuantity:    5,
		ReservedQuantity:  0,
		AvailableQuantity: 6,
	})

	if !errors.Is(err, ErrBalanceQuantityInvalid) {
		t.Fatalf("expected ErrBalanceQuantityInvalid, got %v", err)
	}
}
