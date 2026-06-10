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

func postgresCategoryRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping category repository integration test")
	}

	return dsn
}

func TestPostgresCategoryRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresCategoryRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	categoryRepo := NewPostgresCategoryRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	categoryCode := "CAT-" + unique

	category, err := categoryRepo.CreateCategory(ctx, CreateCategoryInput{
		TenantID:     "tenant_7",
		CategoryCode: categoryCode,
		CategoryName: "FAZ3 Category Test " + unique,
		Description:  "FAZ3 product category repository test",
		SortOrder:    1,
		CreatedBy:    "faz3_test",
	})
	if err != nil {
		t.Fatalf("create category: %v", err)
	}

	defer cleanupPostgresCategory(t, pool, "tenant_7", category.CategoryID)

	if category.CategoryID == "" {
		t.Fatal("expected category_id")
	}

	if category.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", category.TenantID)
	}

	if category.CategoryCode != categoryCode {
		t.Fatalf("expected category_code %s, got %s", categoryCode, category.CategoryCode)
	}

	got, err := categoryRepo.GetCategoryByID(ctx, "tenant_7", category.CategoryID)
	if err != nil {
		t.Fatalf("get category: %v", err)
	}

	if got.CategoryID != category.CategoryID {
		t.Fatalf("expected category_id %s, got %s", category.CategoryID, got.CategoryID)
	}

	list, err := categoryRepo.ListCategories(ctx, "tenant_7", ListCategoriesFilter{
		Query:  unique,
		Status: CatalogStatusActive,
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("list categories: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 category in list, got %d", len(list))
	}

	_, err = categoryRepo.GetCategoryByID(ctx, "tenant_99", category.CategoryID)
	if !errors.Is(err, ErrCategoryNotFound) {
		t.Fatalf("expected ErrCategoryNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresCategoryRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresCategoryRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	categoryRepo := NewPostgresCategoryRepository(pool)

	_, err = categoryRepo.CreateCategory(ctx, CreateCategoryInput{
		TenantID:     "tenant_7",
		CategoryName: "Eksik Kod",
	})

	if !errors.Is(err, ErrCategoryCodeRequired) {
		t.Fatalf("expected ErrCategoryCodeRequired, got %v", err)
	}
}

func cleanupPostgresCategory(t *testing.T, pool *pgxpool.Pool, tenantID string, categoryID string) {
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

	if categoryID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_product_categories WHERE category_id = $1;", categoryID); err != nil {
			t.Logf("cleanup category delete failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
