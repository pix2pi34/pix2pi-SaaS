package inventory

import "context"

type WarehouseRepository interface {
	CreateWarehouse(ctx context.Context, input CreateWarehouseInput) (Warehouse, error)
	GetWarehouseByID(ctx context.Context, tenantID string, warehouseID string) (Warehouse, error)
	ListWarehouses(ctx context.Context, tenantID string, filter ListWarehousesFilter) ([]Warehouse, error)
}

type ListWarehousesFilter struct {
	Query  string
	Status InventoryStatus
	Limit  int
	Offset int
}

type StockMovementRepository interface {
	CreateStockMovement(ctx context.Context, input CreateStockMovementInput) (StockMovement, error)
	GetStockMovementByID(ctx context.Context, tenantID string, stockMovementID string) (StockMovement, error)
	ListStockMovements(ctx context.Context, tenantID string, filter ListStockMovementsFilter) ([]StockMovement, error)
}

type ListStockMovementsFilter struct {
	WarehouseID string
	ItemID      string
	SourceType  string
	SourceID    string
	Query       string
	Status      InventoryStatus
	Limit       int
	Offset      int
}

type WarehouseBalanceRepository interface {
	CreateWarehouseBalance(ctx context.Context, input CreateWarehouseBalanceInput) (WarehouseBalance, error)
	GetWarehouseBalanceByID(ctx context.Context, tenantID string, balanceID string) (WarehouseBalance, error)
	GetWarehouseBalanceByWarehouseAndItem(ctx context.Context, tenantID string, warehouseID string, itemID string) (WarehouseBalance, error)
	ListWarehouseBalances(ctx context.Context, tenantID string, filter ListWarehouseBalancesFilter) ([]WarehouseBalance, error)
}

type ListWarehouseBalancesFilter struct {
	WarehouseID string
	ItemID      string
	Query       string
	Status      InventoryStatus
	Limit       int
	Offset      int
}
