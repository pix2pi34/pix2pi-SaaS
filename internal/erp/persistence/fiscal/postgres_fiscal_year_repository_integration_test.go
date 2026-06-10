package fiscal

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresFiscalYearRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping fiscal year repository integration test")
	}

	return dsn
}

func TestPostgresFiscalYearRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresFiscalYearRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresFiscalYearRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	fiscalYear := 2060 + int(time.Now().UnixNano()%30)

	cleanupFiscalYearRepositoryFixtureByYear(t, pool, "tenant_7", fiscalYear)

	item, err := repo.CreateFiscalYear(ctx, CreateFiscalYearInput{
		TenantID:      "tenant_7",
		FiscalYear:    fiscalYear,
		YearStartDate: time.Date(fiscalYear, 1, 1, 0, 0, 0, 0, time.UTC),
		YearEndDate:   time.Date(fiscalYear, 12, 31, 0, 0, 0, 0, time.UTC),
		Description:   fiscalYearDescription(unique),
		CreatedBy:     "faz3_test",
	})
	if err != nil {
		t.Fatalf("create fiscal year: %v", err)
	}

	defer cleanupFiscalYearRepositoryFixture(t, pool, "tenant_7", item.FiscalYearID)

	if item.FiscalYearID == "" {
		t.Fatal("expected fiscal_year_id")
	}

	if item.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", item.TenantID)
	}

	if item.FiscalYear != fiscalYear {
		t.Fatalf("expected fiscal_year %d, got %d", fiscalYear, item.FiscalYear)
	}

	if item.Status != FiscalYearStatusOpen {
		t.Fatalf("expected status open, got %s", item.Status)
	}

	gotByID, err := repo.GetFiscalYearByID(ctx, "tenant_7", item.FiscalYearID)
	if err != nil {
		t.Fatalf("get fiscal year by id: %v", err)
	}

	if gotByID.FiscalYearID != item.FiscalYearID {
		t.Fatalf("expected fiscal_year_id %s, got %s", item.FiscalYearID, gotByID.FiscalYearID)
	}

	gotByYear, err := repo.GetFiscalYearByYear(ctx, "tenant_7", fiscalYear)
	if err != nil {
		t.Fatalf("get fiscal year by year: %v", err)
	}

	if gotByYear.FiscalYear != fiscalYear {
		t.Fatalf("expected fiscal_year %d, got %d", fiscalYear, gotByYear.FiscalYear)
	}

	list, err := repo.ListFiscalYears(ctx, "tenant_7", ListFiscalYearsFilter{
		Status: FiscalYearStatusOpen,
		Query:  unique,
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("list fiscal years: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 fiscal year in list, got %d", len(list))
	}

	_, err = repo.GetFiscalYearByID(ctx, "tenant_99", item.FiscalYearID)
	if !errors.Is(err, ErrFiscalYearNotFound) {
		t.Fatalf("expected ErrFiscalYearNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresFiscalYearRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresFiscalYearRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresFiscalYearRepository(pool)

	_, err = repo.CreateFiscalYear(ctx, CreateFiscalYearInput{
		TenantID:      "tenant_7",
		FiscalYear:    1999,
		YearStartDate: time.Date(1999, 1, 1, 0, 0, 0, 0, time.UTC),
		YearEndDate:   time.Date(1999, 12, 31, 0, 0, 0, 0, time.UTC),
	})

	if !errors.Is(err, ErrFiscalYearInvalid) {
		t.Fatalf("expected ErrFiscalYearInvalid, got %v", err)
	}
}

func cleanupFiscalYearRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, fiscalYearID string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
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

	if fiscalYearID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_fiscal_years WHERE fiscal_year_id = $1;", fiscalYearID); err != nil {
			t.Logf("cleanup fiscal year failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}

func cleanupFiscalYearRepositoryFixtureByYear(t *testing.T, pool *pgxpool.Pool, tenantID string, fiscalYear int) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("cleanup by year begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("cleanup by year set tenant failed: %v", err)
		return
	}

	if _, err := tx.Exec(ctx, `
DELETE FROM erp_fiscal_years
WHERE tenant_id = $1
  AND fiscal_year = $2
  AND created_by = 'faz3_test';
`, tenantID, fiscalYear); err != nil {
		t.Logf("cleanup by year failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup by year commit failed: %v", err)
		return
	}
}
