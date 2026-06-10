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

func postgresProductRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping product repository integration test")
	}

	return dsn
}

func TestPostgresProductRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresProductRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	unitRepo := NewPostgresUnitRepository(pool)
	categoryRepo := NewPostgresCategoryRepository(pool)
	itemRepo := NewPostgresItemRepository(pool)
	productRepo := NewPostgresProductRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	unit, err := unitRepo.CreateUnit(ctx, CreateUnitInput{
		TenantID:         "tenant_7",
		UnitCode:         "PRD-UNIT-" + unique,
		UnitName:         "Product Test Unit " + unique,
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
		CategoryCode: "PRD-CAT-" + unique,
		CategoryName: "Product Test Category " + unique,
		Description:  "FAZ3 product repository category",
		SortOrder:    1,
		CreatedBy:    "faz3_test",
	})
	if err != nil {
		cleanupPostgresProductStack(t, pool, "tenant_7", "", "", "", unit.UnitID)
		t.Fatalf("create category: %v", err)
	}

	item, err := itemRepo.CreateItem(ctx, CreateItemInput{
		TenantID:           "tenant_7",
		ItemCode:           "PRD-ITEM-" + unique,
		ItemName:           "FAZ3 Product Item Test " + unique,
		ItemType:           ItemTypeStock,
		CategoryID:         category.CategoryID,
		BaseUnitID:         unit.UnitID,
		Barcode:            "978" + unique,
		SKU:                "PRD-SKU-" + unique,
		VATRate:            20,
		IsInventoryTracked: true,
		IsSalesAllowed:     true,
		IsPurchaseAllowed:  true,
		CreatedBy:          "faz3_test",
	})
	if err != nil {
		cleanupPostgresProductStack(t, pool, "tenant_7", "", "", category.CategoryID, unit.UnitID)
		t.Fatalf("create item: %v", err)
	}

	productCode := "PRODUCT-" + unique

	product, err := productRepo.CreateProduct(ctx, CreateProductInput{
		TenantID:           "tenant_7",
		ItemID:             item.ItemID,
		ProductCode:        productCode,
		ProductName:        "FAZ3 Product Test " + unique,
		ShortDescription:   "POS görünür test ürünü",
		LongDescription:    "FAZ3 Product Repository integration test ürünü",
		DefaultSalesUnitID: unit.UnitID,
		IsSellable:         true,
		IsVisiblePOS:       true,
		IsVisibleWeb:       false,
		CreatedBy:          "faz3_test",
	})
	if err != nil {
		cleanupPostgresProductStack(t, pool, "tenant_7", "", item.ItemID, category.CategoryID, unit.UnitID)
		t.Fatalf("create product: %v", err)
	}

	defer cleanupPostgresProductStack(t, pool, "tenant_7", product.ProductID, item.ItemID, category.CategoryID, unit.UnitID)

	if product.ProductID == "" {
		t.Fatal("expected product_id")
	}

	if product.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", product.TenantID)
	}

	if product.ItemID != item.ItemID {
		t.Fatalf("expected item_id %s, got %s", item.ItemID, product.ItemID)
	}

	if product.ProductCode != productCode {
		t.Fatalf("expected product_code %s, got %s", productCode, product.ProductCode)
	}

	if !product.IsSellable {
		t.Fatal("expected product sellable")
	}

	if !product.IsVisiblePOS {
		t.Fatal("expected product visible on POS")
	}

	got, err := productRepo.GetProductByID(ctx, "tenant_7", product.ProductID)
	if err != nil {
		t.Fatalf("get product: %v", err)
	}

	if got.ProductID != product.ProductID {
		t.Fatalf("expected product_id %s, got %s", product.ProductID, got.ProductID)
	}

	visiblePOS := true

	list, err := productRepo.ListProducts(ctx, "tenant_7", ListProductsFilter{
		Query:        unique,
		Status:       CatalogStatusActive,
		VisiblePOS:   &visiblePOS,
		SellableOnly: true,
		Limit:        10,
	})
	if err != nil {
		t.Fatalf("list products: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 product in list, got %d", len(list))
	}

	_, err = productRepo.GetProductByID(ctx, "tenant_99", product.ProductID)
	if !errors.Is(err, ErrProductNotFound) {
		t.Fatalf("expected ErrProductNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresProductRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresProductRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	productRepo := NewPostgresProductRepository(pool)

	_, err = productRepo.CreateProduct(ctx, CreateProductInput{
		TenantID:    "tenant_7",
		ProductCode: "PRD-001",
		ProductName: "Eksik Item",
	})

	if !errors.Is(err, ErrItemIDRequired) {
		t.Fatalf("expected ErrItemIDRequired, got %v", err)
	}
}

func cleanupPostgresProductStack(t *testing.T, pool *pgxpool.Pool, tenantID string, productID string, itemID string, categoryID string, unitID string) {
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

	if productID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_products WHERE product_id = $1;", productID); err != nil {
			t.Logf("cleanup product delete failed: %v", err)
			return
		}
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
