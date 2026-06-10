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

func postgresStockMovementRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping stock movement repository integration test")
	}

	return dsn
}

func TestPostgresStockMovementRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresStockMovementRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	warehouseRepo := NewPostgresWarehouseRepository(pool)
	movementRepo := NewPostgresStockMovementRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	unitID, itemID := createInventoryItemForStockMovementTest(t, pool, "tenant_7", unique)

	warehouse, err := warehouseRepo.CreateWarehouse(ctx, CreateWarehouseInput{
		TenantID:      "tenant_7",
		WarehouseCode: "SM-WH-" + unique,
		WarehouseName: "Stock Movement Warehouse " + unique,
		WarehouseType: WarehouseTypeMain,
		City:          "Istanbul",
		District:      "Kadikoy",
		AddressLine:   "FAZ3 stock movement test warehouse",
		IsDefault:     false,
		CreatedBy:     "faz3_test",
	})
	if err != nil {
		cleanupStockMovementStack(t, pool, "tenant_7", "", "", itemID, unitID, "")
		t.Fatalf("create warehouse: %v", err)
	}

	movementNo := "SM-MOV-" + unique
	postedAt := time.Now().UTC()

	movement, err := movementRepo.CreateStockMovement(ctx, CreateStockMovementInput{
		TenantID:          "tenant_7",
		MovementNo:        movementNo,
		MovementType:      StockMovementTypeOpening,
		MovementDirection: StockMovementDirectionIn,
		WarehouseID:       warehouse.WarehouseID,
		ItemID:            itemID,
		UnitID:            unitID,
		Quantity:          10,
		UnitCost:          5,
		TotalCost:         50,
		SourceType:        "integration_test",
		SourceID:          "SRC-" + unique,
		SourceLineID:      "SRC-LINE-" + unique,
		MovementAt:        time.Now().UTC(),
		PostedAt:          &postedAt,
		Note:              "FAZ3 stock movement repository test",
		CreatedBy:         "faz3_test",
	})
	if err != nil {
		cleanupStockMovementStack(t, pool, "tenant_7", "", warehouse.WarehouseID, itemID, unitID, "")
		t.Fatalf("create stock movement: %v", err)
	}

	defer cleanupStockMovementStack(t, pool, "tenant_7", movement.StockMovementID, warehouse.WarehouseID, itemID, unitID, "")

	if movement.StockMovementID == "" {
		t.Fatal("expected stock_movement_id")
	}

	if movement.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", movement.TenantID)
	}

	if movement.MovementNo != movementNo {
		t.Fatalf("expected movement_no %s, got %s", movementNo, movement.MovementNo)
	}

	if movement.WarehouseID != warehouse.WarehouseID {
		t.Fatalf("expected warehouse_id %s, got %s", warehouse.WarehouseID, movement.WarehouseID)
	}

	if movement.ItemID != itemID {
		t.Fatalf("expected item_id %s, got %s", itemID, movement.ItemID)
	}

	if movement.UnitID != unitID {
		t.Fatalf("expected unit_id %s, got %s", unitID, movement.UnitID)
	}

	got, err := movementRepo.GetStockMovementByID(ctx, "tenant_7", movement.StockMovementID)
	if err != nil {
		t.Fatalf("get stock movement: %v", err)
	}

	if got.StockMovementID != movement.StockMovementID {
		t.Fatalf("expected stock_movement_id %s, got %s", movement.StockMovementID, got.StockMovementID)
	}

	list, err := movementRepo.ListStockMovements(ctx, "tenant_7", ListStockMovementsFilter{
		WarehouseID: warehouse.WarehouseID,
		ItemID:      itemID,
		SourceType:  "integration_test",
		SourceID:    "SRC-" + unique,
		Query:       unique,
		Status:      InventoryStatusPosted,
		Limit:       10,
	})
	if err != nil {
		t.Fatalf("list stock movements: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 stock movement in list, got %d", len(list))
	}

	_, err = movementRepo.GetStockMovementByID(ctx, "tenant_99", movement.StockMovementID)
	if !errors.Is(err, ErrStockMovementNotFound) {
		t.Fatalf("expected ErrStockMovementNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresStockMovementRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresStockMovementRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	movementRepo := NewPostgresStockMovementRepository(pool)

	_, err = movementRepo.CreateStockMovement(ctx, CreateStockMovementInput{
		TenantID:          "tenant_7",
		MovementType:      StockMovementTypeOpening,
		MovementDirection: StockMovementDirectionIn,
		WarehouseID:       "warehouse-id",
		ItemID:            "item-id",
		UnitID:            "unit-id",
		Quantity:          1,
	})

	if !errors.Is(err, ErrMovementNoRequired) {
		t.Fatalf("expected ErrMovementNoRequired, got %v", err)
	}
}

func createInventoryItemForStockMovementTest(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string) {
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
    'faz3_stock_movement_test'
)
RETURNING unit_id::text;
`, tenantID, "SM-UNIT-"+unique, "Stock Movement Unit "+unique).Scan(&unitID); err != nil {
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
    'faz3_stock_movement_test'
)
RETURNING item_id::text;
`, tenantID, "SM-ITEM-"+unique, "Stock Movement Item "+unique, unitID, "SM-BAR-"+unique, "SM-SKU-"+unique).Scan(&itemID); err != nil {
		t.Fatalf("setup item failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("setup commit failed: %v", err)
	}

	return unitID, itemID
}

func cleanupStockMovementStack(t *testing.T, pool *pgxpool.Pool, tenantID string, stockMovementID string, warehouseID string, itemID string, unitID string, balanceID string) {
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
