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

func postgresWarehouseRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping warehouse repository integration test")
	}

	return dsn
}

func TestPostgresWarehouseRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresWarehouseRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresWarehouseRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	warehouseCode := "WH-REPO-" + unique

	warehouse, err := repo.CreateWarehouse(ctx, CreateWarehouseInput{
		TenantID:      "tenant_7",
		WarehouseCode: warehouseCode,
		WarehouseName: "FAZ3 Warehouse Repo Test " + unique,
		WarehouseType: WarehouseTypeMain,
		City:          "Istanbul",
		District:      "Kadikoy",
		AddressLine:   "FAZ3 warehouse repository test adresi",
		IsDefault:     false,
		CreatedBy:     "faz3_test",
	})
	if err != nil {
		t.Fatalf("create warehouse: %v", err)
	}

	defer cleanupPostgresWarehouse(t, pool, "tenant_7", warehouse.WarehouseID)

	if warehouse.WarehouseID == "" {
		t.Fatal("expected warehouse_id")
	}

	if warehouse.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", warehouse.TenantID)
	}

	if warehouse.WarehouseCode != warehouseCode {
		t.Fatalf("expected warehouse_code %s, got %s", warehouseCode, warehouse.WarehouseCode)
	}

	got, err := repo.GetWarehouseByID(ctx, "tenant_7", warehouse.WarehouseID)
	if err != nil {
		t.Fatalf("get warehouse: %v", err)
	}

	if got.WarehouseID != warehouse.WarehouseID {
		t.Fatalf("expected warehouse_id %s, got %s", warehouse.WarehouseID, got.WarehouseID)
	}

	list, err := repo.ListWarehouses(ctx, "tenant_7", ListWarehousesFilter{
		Query:  unique,
		Status: InventoryStatusActive,
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("list warehouses: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 warehouse in list, got %d", len(list))
	}

	_, err = repo.GetWarehouseByID(ctx, "tenant_99", warehouse.WarehouseID)
	if !errors.Is(err, ErrWarehouseNotFound) {
		t.Fatalf("expected ErrWarehouseNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresWarehouseRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresWarehouseRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresWarehouseRepository(pool)

	_, err = repo.CreateWarehouse(ctx, CreateWarehouseInput{
		TenantID:      "tenant_7",
		WarehouseName: "Eksik Kod",
		WarehouseType: WarehouseTypeMain,
	})

	if !errors.Is(err, ErrWarehouseCodeRequired) {
		t.Fatalf("expected ErrWarehouseCodeRequired, got %v", err)
	}
}

func cleanupPostgresWarehouse(t *testing.T, pool *pgxpool.Pool, tenantID string, warehouseID string) {
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
