package fiscalguard

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresFiscalGuardProviderTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping fiscal guard postgres provider integration test")
	}

	return dsn
}

func TestPostgresFiscalPeriodProviderFindPeriodByPostingDate(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresFiscalGuardProviderTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	fiscalYear := 2080 + int(time.Now().UnixNano()%15)
	fiscalPeriod := fmt.Sprintf("%d-13-%s", fiscalYear, unique[len(unique)-6:])

	cleanupRuntimeFiscalPeriodFixture(t, pool, "tenant_7", fiscalYear, 13)
	createRuntimeFiscalPeriodFixture(t, pool, "tenant_7", fiscalYear, fiscalPeriod)

	defer cleanupRuntimeFiscalPeriodFixture(t, pool, "tenant_7", fiscalYear, 13)

	provider := NewPostgresFiscalPeriodProvider(pool)

	period, err := provider.FindPeriodByPostingDate(ctx, "tenant_7", fmt.Sprintf("%d-12-15", fiscalYear))
	if err != nil {
		t.Fatalf("find period by posting date: %v", err)
	}

	if period.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", period.TenantID)
	}

	if period.FiscalYear != fiscalYear {
		t.Fatalf("expected fiscal_year %d, got %d", fiscalYear, period.FiscalYear)
	}

	if period.FiscalPeriod != fiscalPeriod {
		t.Fatalf("expected fiscal_period %s, got %s", fiscalPeriod, period.FiscalPeriod)
	}

	if period.PeriodNo != 13 {
		t.Fatalf("expected period_no 13, got %d", period.PeriodNo)
	}

	if period.Status != FiscalPeriodStatusOpen {
		t.Fatalf("expected status open, got %s", period.Status)
	}
}

func TestPostgresFiscalPeriodProviderTenantIsolationNotFound(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresFiscalGuardProviderTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	fiscalYear := 2080 + int(time.Now().UnixNano()%15)
	fiscalPeriod := fmt.Sprintf("%d-13-rls-%s", fiscalYear, unique[len(unique)-6:])

	cleanupRuntimeFiscalPeriodFixture(t, pool, "tenant_7", fiscalYear, 13)
	createRuntimeFiscalPeriodFixture(t, pool, "tenant_7", fiscalYear, fiscalPeriod)

	defer cleanupRuntimeFiscalPeriodFixture(t, pool, "tenant_7", fiscalYear, 13)

	provider := NewPostgresFiscalPeriodProvider(pool)

	_, err = provider.FindPeriodByPostingDate(ctx, "tenant_99", fmt.Sprintf("%d-12-15", fiscalYear))
	if !errors.Is(err, ErrPeriodNotFound) {
		t.Fatalf("expected ErrPeriodNotFound for cross tenant read, got %v", err)
	}
}

func TestPostgresFiscalPeriodProviderValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresFiscalGuardProviderTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	provider := NewPostgresFiscalPeriodProvider(pool)

	_, err = provider.FindPeriodByPostingDate(ctx, "", "2026-04-26")
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}

	_, err = provider.FindPeriodByPostingDate(ctx, "tenant_7", "")
	if !errors.Is(err, ErrPostingDateRequired) {
		t.Fatalf("expected ErrPostingDateRequired, got %v", err)
	}
}

func createRuntimeFiscalPeriodFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, fiscalYear int, fiscalPeriod string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("fixture begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("fixture set tenant failed: %v", err)
	}

	if _, err := tx.Exec(ctx, `
INSERT INTO erp_fiscal_periods (
    tenant_id,
    fiscal_year,
    fiscal_period,
    period_no,
    period_start_date,
    period_end_date,
    status,
    description,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    13,
    make_date($2, 12, 1),
    make_date($2, 12, 31),
    'open',
    'Runtime fiscal guard provider fixture',
    'faz3_fiscalguard_provider_test'
);
`, tenantID, fiscalYear, fiscalPeriod); err != nil {
		t.Fatalf("fixture insert fiscal period failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}
}

func cleanupRuntimeFiscalPeriodFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, fiscalYear int, periodNo int) {
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

	if _, err := tx.Exec(ctx, `
DELETE FROM erp_fiscal_periods
WHERE tenant_id = $1
  AND fiscal_year = $2
  AND period_no = $3
  AND created_by = 'faz3_fiscalguard_provider_test';
`, tenantID, fiscalYear, periodNo); err != nil {
		t.Logf("cleanup fiscal period failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
