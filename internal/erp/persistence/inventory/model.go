package inventory

import (
	"strings"
	"time"
)

type InventoryStatus string

const (
	InventoryStatusActive    InventoryStatus = "active"
	InventoryStatusPassive   InventoryStatus = "passive"
	InventoryStatusBlocked   InventoryStatus = "blocked"
	InventoryStatusDeleted   InventoryStatus = "deleted"
	InventoryStatusDraft     InventoryStatus = "draft"
	InventoryStatusPosted    InventoryStatus = "posted"
	InventoryStatusCancelled InventoryStatus = "cancelled"
	InventoryStatusReversed  InventoryStatus = "reversed"
)

type WarehouseType string

const (
	WarehouseTypeMain    WarehouseType = "main"
	WarehouseTypeBranch  WarehouseType = "branch"
	WarehouseTypeStore   WarehouseType = "store"
	WarehouseTypeVirtual WarehouseType = "virtual"
	WarehouseTypeTransit WarehouseType = "transit"
	WarehouseTypeDamaged WarehouseType = "damaged"
)

type StockMovementType string

const (
	StockMovementTypeOpening         StockMovementType = "opening"
	StockMovementTypePurchaseReceipt StockMovementType = "purchase_receipt"
	StockMovementTypeSalesDelivery   StockMovementType = "sales_delivery"
	StockMovementTypeStockIn         StockMovementType = "stock_in"
	StockMovementTypeStockOut        StockMovementType = "stock_out"
	StockMovementTypeTransferIn      StockMovementType = "transfer_in"
	StockMovementTypeTransferOut     StockMovementType = "transfer_out"
	StockMovementTypeAdjustmentIn    StockMovementType = "adjustment_in"
	StockMovementTypeAdjustmentOut   StockMovementType = "adjustment_out"
	StockMovementTypeReturnIn        StockMovementType = "return_in"
	StockMovementTypeReturnOut       StockMovementType = "return_out"
)

type StockMovementDirection string

const (
	StockMovementDirectionIn  StockMovementDirection = "in"
	StockMovementDirectionOut StockMovementDirection = "out"
)

type Warehouse struct {
	WarehouseID   string
	TenantID      string
	WarehouseCode string
	WarehouseName string
	WarehouseType WarehouseType
	City          string
	District      string
	AddressLine   string
	IsDefault     bool
	Status        InventoryStatus
	CreatedAt     time.Time
	UpdatedAt     time.Time
	DeletedAt     *time.Time
	CreatedBy     string
	UpdatedBy     string
}

type StockMovement struct {
	StockMovementID   string
	TenantID          string
	MovementNo        string
	MovementType      StockMovementType
	MovementDirection StockMovementDirection
	WarehouseID       string
	ItemID            string
	UnitID            string
	Quantity          float64
	UnitCost          float64
	TotalCost         float64
	SourceType        string
	SourceID          string
	SourceLineID      string
	MovementAt        time.Time
	PostedAt          *time.Time
	Status            InventoryStatus
	Note              string
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
	CreatedBy         string
	UpdatedBy         string
}

type WarehouseBalance struct {
	BalanceID           string
	TenantID            string
	WarehouseID         string
	ItemID              string
	UnitID              string
	OnHandQuantity      float64
	ReservedQuantity    float64
	AvailableQuantity   float64
	LastMovementAt      *time.Time
	LastStockMovementID string
	Status              InventoryStatus
	CreatedAt           time.Time
	UpdatedAt           time.Time
	DeletedAt           *time.Time
	CreatedBy           string
	UpdatedBy           string
}

type CreateWarehouseInput struct {
	TenantID      string
	WarehouseCode string
	WarehouseName string
	WarehouseType WarehouseType
	City          string
	District      string
	AddressLine   string
	IsDefault     bool
	CreatedBy     string
}

type CreateStockMovementInput struct {
	TenantID          string
	MovementNo        string
	MovementType      StockMovementType
	MovementDirection StockMovementDirection
	WarehouseID       string
	ItemID            string
	UnitID            string
	Quantity          float64
	UnitCost          float64
	TotalCost         float64
	SourceType        string
	SourceID          string
	SourceLineID      string
	MovementAt        time.Time
	PostedAt          *time.Time
	Note              string
	CreatedBy         string
}

type CreateWarehouseBalanceInput struct {
	TenantID            string
	WarehouseID         string
	ItemID              string
	UnitID              string
	OnHandQuantity      float64
	ReservedQuantity    float64
	AvailableQuantity   float64
	LastMovementAt      *time.Time
	LastStockMovementID string
	CreatedBy           string
}

func ValidateCreateWarehouseInput(input CreateWarehouseInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.WarehouseCode) == "" {
		return ErrWarehouseCodeRequired
	}

	if strings.TrimSpace(input.WarehouseName) == "" {
		return ErrWarehouseNameRequired
	}

	warehouseType := input.WarehouseType
	if strings.TrimSpace(string(warehouseType)) == "" {
		warehouseType = WarehouseTypeMain
	}

	switch warehouseType {
	case WarehouseTypeMain, WarehouseTypeBranch, WarehouseTypeStore, WarehouseTypeVirtual, WarehouseTypeTransit, WarehouseTypeDamaged:
	default:
		return ErrWarehouseTypeInvalid
	}

	return nil
}

func ValidateCreateStockMovementInput(input CreateStockMovementInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.MovementNo) == "" {
		return ErrMovementNoRequired
	}

	switch input.MovementType {
	case StockMovementTypeOpening,
		StockMovementTypePurchaseReceipt,
		StockMovementTypeSalesDelivery,
		StockMovementTypeStockIn,
		StockMovementTypeStockOut,
		StockMovementTypeTransferIn,
		StockMovementTypeTransferOut,
		StockMovementTypeAdjustmentIn,
		StockMovementTypeAdjustmentOut,
		StockMovementTypeReturnIn,
		StockMovementTypeReturnOut:
	default:
		return ErrMovementTypeInvalid
	}

	switch input.MovementDirection {
	case StockMovementDirectionIn, StockMovementDirectionOut:
	default:
		return ErrMovementDirectionInvalid
	}

	if strings.TrimSpace(input.WarehouseID) == "" {
		return ErrWarehouseIDRequired
	}

	if strings.TrimSpace(input.ItemID) == "" {
		return ErrItemIDRequired
	}

	if strings.TrimSpace(input.UnitID) == "" {
		return ErrUnitIDRequired
	}

	if input.Quantity <= 0 {
		return ErrQuantityMustBePositive
	}

	if input.UnitCost < 0 || input.TotalCost < 0 {
		return ErrCostInvalid
	}

	return nil
}

func ValidateCreateWarehouseBalanceInput(input CreateWarehouseBalanceInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.WarehouseID) == "" {
		return ErrWarehouseIDRequired
	}

	if strings.TrimSpace(input.ItemID) == "" {
		return ErrItemIDRequired
	}

	if strings.TrimSpace(input.UnitID) == "" {
		return ErrUnitIDRequired
	}

	if input.OnHandQuantity < 0 || input.ReservedQuantity < 0 || input.AvailableQuantity < 0 {
		return ErrBalanceQuantityInvalid
	}

	if input.AvailableQuantity > input.OnHandQuantity {
		return ErrBalanceQuantityInvalid
	}

	return nil
}
