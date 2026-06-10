package inventory

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresWarehouseBalanceRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping warehouse balance repository integration test")
	}

	return dsn
}

func TestPostgresWarehouseBalanceRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresWarehouseBalanceRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	warehouseRepo := NewPostgresWarehouseRepository(pool)
	movementRepo := NewPostgresStockMovementRepository(pool)
	balanceRepo := NewPostgresWarehouseBalanceRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	unitID, itemID := createInventoryItemForWarehouseBalanceTest(t, pool, "tenant_7", unique)

	warehouse, err := warehouseRepo.CreateWarehouse(ctx, CreateWarehouseInput{
		TenantID:      "tenant_7",
		WarehouseCode: "WB-WH-" + unique,
		WarehouseName: "Warehouse Balance Warehouse " + unique,
		WarehouseType: WarehouseTypeMain,
		City:          "Istanbul",
		District:      "Kadikoy",
		AddressLine:   "FAZ3 warehouse balance test warehouse",
		IsDefault:     false,
		CreatedBy:     "faz3_test",
	})
	if err != nil {
		cleanupWarehouseBalanceStack(t, pool, "tenant_7", "", "", "", itemID, unitID)
		t.Fatalf("create warehouse: %v", err)
	}

	postedAt := time.Now().UTC()

	movement, err := movementRepo.CreateStockMovement(ctx, CreateStockMovementInput{
		TenantID:          "tenant_7",
		MovementNo:        "WB-MOV-" + unique,
		MovementType:      StockMovementTypeOpening,
		MovementDirection: StockMovementDirectionIn,
		WarehouseID:       warehouse.WarehouseID,
		ItemID:            itemID,
		UnitID:            unitID,
		Quantity:          25,
		UnitCost:          4,
		TotalCost:         100,
		SourceType:        "integration_test",
		SourceID:          "WB-SRC-" + unique,
		SourceLineID:      "WB-SRC-LINE-" + unique,
		MovementAt:        time.Now().UTC(),
		PostedAt:          &postedAt,
		Note:              "FAZ3 warehouse balance repository test movement",
		CreatedBy:         "faz3_test",
	})
	if err != nil {
		cleanupWarehouseBalanceStack(t, pool, "tenant_7", "", "", warehouse.WarehouseID, itemID, unitID)
		t.Fatalf("create stock movement: %v", err)
	}

	lastMovementAt := time.Now().UTC()

	balance, err := balanceRepo.CreateWarehouseBalance(ctx, CreateWarehouseBalanceInput{
		TenantID:            "tenant_7",
		WarehouseID:         warehouse.WarehouseID,
		ItemID:              itemID,
		UnitID:              unitID,
		OnHandQuantity:      25,
		ReservedQuantity:    5,
		AvailableQuantity:   20,
		LastMovementAt:      &lastMovementAt,
		LastStockMovementID: movement.StockMovementID,
		CreatedBy:           "faz3_test",
	})
	if err != nil {
		cleanupWarehouseBalanceStack(t, pool, "tenant_7", "", movement.StockMovementID, warehouse.WarehouseID, itemID, unitID)
		t.Fatalf("create warehouse balance: %v", err)
	}

	defer cleanupWarehouseBalanceStack(t, pool, "tenant_7", balance.BalanceID, movement.StockMovementID, warehouse.WarehouseID, itemID, unitID)

	if balance.BalanceID == "" {
		t.Fatal("expected balance_id")
	}

	if balance.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", balance.TenantID)
	}

	if balance.WarehouseID != warehouse.WarehouseID {
		t.Fatalf("expected warehouse_id %s, got %s", warehouse.WarehouseID, balance.WarehouseID)
	}

	if balance.ItemID != itemID {
		t.Fatalf("expected item_id %s, got %s", itemID, balance.ItemID)
	}

	if balance.OnHandQuantity != 25 {
		t.Fatalf("expected on_hand_quantity 25, got %v", balance.OnHandQuantity)
	}

	if balance.AvailableQuantity != 20 {
		t.Fatalf("expected available_quantity 20, got %v", balance.AvailableQuantity)
	}

	got, err := balanceRepo.GetWarehouseBalanceByID(ctx, "tenant_7", balance.BalanceID)
	if err != nil {
		t.Fatalf("get warehouse balance by id: %v", err)
	}

	if got.BalanceID != balance.BalanceID {
		t.Fatalf("expected balance_id %s, got %s", balance.BalanceID, got.BalanceID)
	}

	gotByPair, err := balanceRepo.GetWarehouseBalanceByWarehouseAndItem(ctx, "tenant_7", warehouse.WarehouseID, itemID)
	if err != nil {
		t.Fatalf("get warehouse balance by warehouse and item: %v", err)
	}

	if gotByPair.BalanceID != balance.BalanceID {
		t.Fatalf("expected balance_id %s, got %s", balance.BalanceID, gotByPair.BalanceID)
	}

	list, err := balanceRepo.ListWarehouseBalances(ctx, "tenant_7", ListWarehouseBalancesFilter{
		WarehouseID: warehouse.WarehouseID,
		ItemID:      itemID,
		Query:       unique,
		Status:      InventoryStatusActive,
		Limit:       10,
	})
	if err != nil {
		t.Fatalf("list warehouse balances: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 warehouse balance in list, got %d", len(list))
	}

	_, err = balanceRepo.GetWarehouseBalanceByID(ctx, "tenant_99", balance.BalanceID)
	if !errors.Is(err, ErrWarehouseBalanceNotFound) {
		t.Fatalf("expected ErrWarehouseBalanceNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresWarehouseBalanceRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresWarehouseBalanceRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	balanceRepo := NewPostgresWarehouseBalanceRepository(pool)

	_, err = balanceRepo.CreateWarehouseBalance(ctx, CreateWarehouseBalanceInput{
		TenantID:          "tenant_7",
		ItemID:            "item-id",
		UnitID:            "unit-id",
		OnHandQuantity:    10,
		ReservedQuantity:  2,
		AvailableQuantity: 8,
	})

	if !errors.Is(err, ErrWarehouseIDRequired) {
		t.Fatalf("expected ErrWarehouseIDRequired, got %v", err)
	}
}

func createInventoryItemForWarehouseBalanceTest(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("setup begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("setup set tenant failed: %v", err)
	}

	var unitID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_units (
    tenant_id,
    unit_code,
    unit_name,
    unit_type,
    decimal_precision,
    is_base_unit,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    'quantity',
    0,
    true,
    'faz3_warehouse_balance_test'
)
RETURNING unit_id::text;
`, tenantID, "WB-UNIT-"+unique, "Warehouse Balance Unit "+unique).Scan(&unitID); err != nil {
		t.Fatalf("setup unit failed: %v", err)
	}

	var itemID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_items (
    tenant_id,
    item_code,
    item_name,
    item_type,
    base_unit_id,
    barcode,
    sku,
    vat_rate,
    is_inventory_tracked,
    is_sales_allowed,
    is_purchase_allowed,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    'stock',
    $4,
    $5,
    $6,
    20.00,
    true,
    true,
    true,
    'faz3_warehouse_balance_test'
)
RETURNING item_id::text;
`, tenantID, "WB-ITEM-"+unique, "Warehouse Balance Item "+unique, unitID, "WB-BAR-"+unique, "WB-SKU-"+unique).Scan(&itemID); err != nil {
		t.Fatalf("setup item failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("setup commit failed: %v", err)
	}

	return unitID, itemID
}

func cleanupWarehouseBalanceStack(t *testing.T, pool *pgxpool.Pool, tenantID string, balanceID string, stockMovementID string, warehouseID string, itemID string, unitID string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("cleanup begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("cleanup set tenant failed: %v", err)
		return
	}

	if balanceID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_warehouse_balances WHERE balance_id = $1;", balanceID); err != nil {
			t.Logf("cleanup balance delete failed: %v", err)
			return
		}
	}

	if stockMovementID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_stock_movements WHERE stock_movement_id = $1;", stockMovementID); err != nil {
			t.Logf("cleanup stock movement delete failed: %v", err)
			return
		}
	}

	if itemID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_items WHERE item_id = $1;", itemID); err != nil {
			t.Logf("cleanup item delete failed: %v", err)
			return
		}
	}

	if unitID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_units WHERE unit_id = $1;", unitID); err != nil {
			t.Logf("cleanup unit delete failed: %v", err)
			return
		}
	}

	if warehouseID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_warehouses WHERE warehouse_id = $1;", warehouseID); err != nil {
			t.Logf("cleanup warehouse delete failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
