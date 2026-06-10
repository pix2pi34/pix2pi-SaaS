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

func postgresFiscalPeriodRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping fiscal period repository integration test")
	}

	return dsn
}

func TestPostgresFiscalPeriodRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresFiscalPeriodRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresFiscalPeriodRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	fiscalYear := 2060 + int(time.Now().UnixNano()%30)
	fiscalPeriod := fmt.Sprintf("%d-13-%s", fiscalYear, unique[len(unique)-6:])

	cleanupFiscalPeriodRepositoryFixtureByCode(t, pool, "tenant_7", fiscalPeriod)

	item, err := repo.CreateFiscalPeriod(ctx, CreateFiscalPeriodInput{
		TenantID:        "tenant_7",
		FiscalYear:      fiscalYear,
		FiscalPeriod:    fiscalPeriod,
		PeriodNo:        13,
		PeriodStartDate: time.Date(fiscalYear, 12, 1, 0, 0, 0, 0, time.UTC),
		PeriodEndDate:   time.Date(fiscalYear, 12, 31, 0, 0, 0, 0, time.UTC),
		Description:     "FAZ3 fiscal period repository test " + unique,
		CreatedBy:       "faz3_test",
	})
	if err != nil {
		t.Fatalf("create fiscal period: %v", err)
	}

	defer cleanupFiscalPeriodRepositoryFixture(t, pool, "tenant_7", item.FiscalPeriodID)

	if item.FiscalPeriodID == "" {
		t.Fatal("expected fiscal_period_id")
	}

	if item.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", item.TenantID)
	}

	if item.FiscalYear != fiscalYear {
		t.Fatalf("expected fiscal_year %d, got %d", fiscalYear, item.FiscalYear)
	}

	if item.FiscalPeriod != fiscalPeriod {
		t.Fatalf("expected fiscal_period %s, got %s", fiscalPeriod, item.FiscalPeriod)
	}

	if item.PeriodNo != 13 {
		t.Fatalf("expected period_no 13, got %d", item.PeriodNo)
	}

	if item.Status != FiscalPeriodStatusOpen {
		t.Fatalf("expected status open, got %s", item.Status)
	}

	gotByID, err := repo.GetFiscalPeriodByID(ctx, "tenant_7", item.FiscalPeriodID)
	if err != nil {
		t.Fatalf("get fiscal period by id: %v", err)
	}

	if gotByID.FiscalPeriodID != item.FiscalPeriodID {
		t.Fatalf("expected fiscal_period_id %s, got %s", item.FiscalPeriodID, gotByID.FiscalPeriodID)
	}

	gotByCode, err := repo.GetFiscalPeriodByCode(ctx, "tenant_7", fiscalPeriod)
	if err != nil {
		t.Fatalf("get fiscal period by code: %v", err)
	}

	if gotByCode.FiscalPeriod != fiscalPeriod {
		t.Fatalf("expected fiscal_period %s, got %s", fiscalPeriod, gotByCode.FiscalPeriod)
	}

	list, err := repo.ListFiscalPeriods(ctx, "tenant_7", ListFiscalPeriodsFilter{
		FiscalYear: fiscalYear,
		Status:     FiscalPeriodStatusOpen,
		Query:      unique,
		Limit:      10,
	})
	if err != nil {
		t.Fatalf("list fiscal periods: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 fiscal period in list, got %d", len(list))
	}

	_, err = repo.GetFiscalPeriodByID(ctx, "tenant_99", item.FiscalPeriodID)
	if !errors.Is(err, ErrFiscalPeriodNotFound) {
		t.Fatalf("expected ErrFiscalPeriodNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresFiscalPeriodRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresFiscalPeriodRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresFiscalPeriodRepository(pool)

	_, err = repo.CreateFiscalPeriod(ctx, CreateFiscalPeriodInput{
		TenantID:        "tenant_7",
		FiscalYear:      2026,
		FiscalPeriod:    "2026-14",
		PeriodNo:        14,
		PeriodStartDate: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
		PeriodEndDate:   time.Date(2026, 1, 31, 0, 0, 0, 0, time.UTC),
	})

	if !errors.Is(err, ErrPeriodNoInvalid) {
		t.Fatalf("expected ErrPeriodNoInvalid, got %v", err)
	}
}

func cleanupFiscalPeriodRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, fiscalPeriodID string) {
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

	if fiscalPeriodID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_fiscal_periods WHERE fiscal_period_id = $1;", fiscalPeriodID); err != nil {
			t.Logf("cleanup fiscal period failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}

func cleanupFiscalPeriodRepositoryFixtureByCode(t *testing.T, pool *pgxpool.Pool, tenantID string, fiscalPeriod string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("cleanup by code begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("cleanup by code set tenant failed: %v", err)
		return
	}

	if _, err := tx.Exec(ctx, `
DELETE FROM erp_fiscal_periods
WHERE tenant_id = $1
  AND fiscal_period = $2
  AND created_by = 'faz3_test';
`, tenantID, fiscalPeriod); err != nil {
		t.Logf("cleanup by code failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup by code commit failed: %v", err)
		return
	}
}
