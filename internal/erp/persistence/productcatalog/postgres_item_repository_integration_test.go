package productcatalog

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresItemRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping item repository integration test")
	}

	return dsn
}

func TestPostgresItemRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresItemRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	unitRepo := NewPostgresUnitRepository(pool)
	categoryRepo := NewPostgresCategoryRepository(pool)
	itemRepo := NewPostgresItemRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	unit, err := unitRepo.CreateUnit(ctx, CreateUnitInput{
		TenantID:         "tenant_7",
		UnitCode:         "ITM-UNIT-" + unique,
		UnitName:         "Item Test Unit " + unique,
		UnitType:         UnitTypeQuantity,
		DecimalPrecision: 0,
		IsBaseUnit:       true,
		CreatedBy:        "faz3_test",
	})
	if err != nil {
		t.Fatalf("create unit: %v", err)
	}

	category, err := categoryRepo.CreateCategory(ctx, CreateCategoryInput{
		TenantID:     "tenant_7",
		CategoryCode: "ITM-CAT-" + unique,
		CategoryName: "Item Test Category " + unique,
		Description:  "FAZ3 item repository category",
		SortOrder:    1,
		CreatedBy:    "faz3_test",
	})
	if err != nil {
		cleanupPostgresItemStack(t, pool, "tenant_7", "", "", unit.UnitID)
		t.Fatalf("create category: %v", err)
	}

	itemCode := "ITEM-" + unique
	barcode := "869" + unique

	item, err := itemRepo.CreateItem(ctx, CreateItemInput{
		TenantID:           "tenant_7",
		ItemCode:           itemCode,
		ItemName:           "FAZ3 Item Test " + unique,
		ItemType:           ItemTypeStock,
		CategoryID:         category.CategoryID,
		BaseUnitID:         unit.UnitID,
		Barcode:            barcode,
		SKU:                "SKU-" + unique,
		VATRate:            20,
		IsInventoryTracked: true,
		IsSalesAllowed:     true,
		IsPurchaseAllowed:  true,
		CreatedBy:          "faz3_test",
	})
	if err != nil {
		cleanupPostgresItemStack(t, pool, "tenant_7", "", category.CategoryID, unit.UnitID)
		t.Fatalf("create item: %v", err)
	}

	defer cleanupPostgresItemStack(t, pool, "tenant_7", item.ItemID, category.CategoryID, unit.UnitID)

	if item.ItemID == "" {
		t.Fatal("expected item_id")
	}

	if item.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", item.TenantID)
	}

	if item.ItemCode != itemCode {
		t.Fatalf("expected item_code %s, got %s", itemCode, item.ItemCode)
	}

	if item.CategoryID != category.CategoryID {
		t.Fatalf("expected category_id %s, got %s", category.CategoryID, item.CategoryID)
	}

	if item.BaseUnitID != unit.UnitID {
		t.Fatalf("expected base_unit_id %s, got %s", unit.UnitID, item.BaseUnitID)
	}

	got, err := itemRepo.GetItemByID(ctx, "tenant_7", item.ItemID)
	if err != nil {
		t.Fatalf("get item: %v", err)
	}

	if got.ItemID != item.ItemID {
		t.Fatalf("expected item_id %s, got %s", item.ItemID, got.ItemID)
	}

	list, err := itemRepo.ListItems(ctx, "tenant_7", ListItemsFilter{
		CategoryID: category.CategoryID,
		Query:      unique,
		Status:     CatalogStatusActive,
		Limit:      10,
	})
	if err != nil {
		t.Fatalf("list items: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 item in list, got %d", len(list))
	}

	_, err = itemRepo.GetItemByID(ctx, "tenant_99", item.ItemID)
	if !errors.Is(err, ErrItemNotFound) {
		t.Fatalf("expected ErrItemNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresItemRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresItemRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	itemRepo := NewPostgresItemRepository(pool)

	_, err = itemRepo.CreateItem(ctx, CreateItemInput{
		TenantID:   "tenant_7",
		ItemName:   "Eksik Kod",
		ItemType:   ItemTypeStock,
		BaseUnitID: "unit-id",
		VATRate:    20,
	})

	if !errors.Is(err, ErrItemCodeRequired) {
		t.Fatalf("expected ErrItemCodeRequired, got %v", err)
	}
}

func cleanupPostgresItemStack(t *testing.T, pool *pgxpool.Pool, tenantID string, itemID string, categoryID string, unitID string) {
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

	if itemID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_items WHERE item_id = $1;", itemID); err != nil {
			t.Logf("cleanup item delete failed: %v", err)
			return
		}
	}

	if categoryID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_product_categories WHERE category_id = $1;", categoryID); err != nil {
			t.Logf("cleanup category delete failed: %v", err)
			return
		}
	}

	if unitID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_units WHERE unit_id = $1;", unitID); err != nil {
			t.Logf("cleanup unit delete failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
