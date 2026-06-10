package ledger

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresLedgerBalanceRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping ledger balance repository integration test")
	}

	return dsn
}

func TestPostgresLedgerBalanceRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresLedgerBalanceRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresLedgerBalanceRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	accountCode := "120-" + unique
	calculatedAt := time.Now().UTC()

	balance, err := repo.CreateLedgerBalance(ctx, CreateLedgerBalanceInput{
		TenantID:            "tenant_7",
		FiscalYear:          2026,
		FiscalPeriod:        "2026-04",
		AccountCode:         accountCode,
		AccountName:         "Alicilar " + unique,
		CurrencyCode:        "TRY",
		OpeningDebitAmount:  0,
		OpeningCreditAmount: 0,
		PeriodDebitAmount:   120,
		PeriodCreditAmount:  0,
		ClosingDebitAmount:  120,
		ClosingCreditAmount: 0,
		BalanceSide:         LedgerBalanceSideDebit,
		BalanceAmount:       120,
		CostCenterCode:      "CC-BALANCE",
		ProjectCode:         "PRJ-BALANCE",
		CalculatedAt:        &calculatedAt,
		CreatedBy:           "faz3_test",
	})
	if err != nil {
		t.Fatalf("create ledger balance: %v", err)
	}

	defer cleanupLedgerBalanceFixture(t, pool, "tenant_7", balance.LedgerBalanceID)

	if balance.LedgerBalanceID == "" {
		t.Fatal("expected ledger_balance_id")
	}

	if balance.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", balance.TenantID)
	}

	if balance.AccountCode != accountCode {
		t.Fatalf("expected account_code %s, got %s", accountCode, balance.AccountCode)
	}

	if balance.BalanceSide != LedgerBalanceSideDebit {
		t.Fatalf("expected debit balance_side, got %s", balance.BalanceSide)
	}

	if balance.BalanceAmount != 120 {
		t.Fatalf("expected balance_amount 120, got %v", balance.BalanceAmount)
	}

	got, err := repo.GetLedgerBalanceByID(ctx, "tenant_7", balance.LedgerBalanceID)
	if err != nil {
		t.Fatalf("get ledger balance: %v", err)
	}

	if got.LedgerBalanceID != balance.LedgerBalanceID {
		t.Fatalf("expected ledger_balance_id %s, got %s", balance.LedgerBalanceID, got.LedgerBalanceID)
	}

	list, err := repo.ListLedgerBalances(ctx, "tenant_7", ListLedgerBalancesFilter{
		AccountCode:    accountCode,
		FiscalYear:     2026,
		FiscalPeriod:   "2026-04",
		BalanceSide:    LedgerBalanceSideDebit,
		CostCenterCode: "CC-BALANCE",
		ProjectCode:    "PRJ-BALANCE",
		Query:          unique,
		Limit:          10,
	})
	if err != nil {
		t.Fatalf("list ledger balances: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 ledger balance in list, got %d", len(list))
	}

	_, err = repo.GetLedgerBalanceByID(ctx, "tenant_99", balance.LedgerBalanceID)
	if !errors.Is(err, ErrLedgerBalanceNotFound) {
		t.Fatalf("expected ErrLedgerBalanceNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresLedgerBalanceRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresLedgerBalanceRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresLedgerBalanceRepository(pool)

	_, err = repo.CreateLedgerBalance(ctx, CreateLedgerBalanceInput{
		TenantID:     "tenant_7",
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		BalanceSide:  LedgerBalanceSideZero,
	})

	if !errors.Is(err, ErrAccountCodeRequired) {
		t.Fatalf("expected ErrAccountCodeRequired, got %v", err)
	}
}

func cleanupLedgerBalanceFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, ledgerBalanceID string) {
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

	if ledgerBalanceID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_ledger_balances WHERE ledger_balance_id = $1;", ledgerBalanceID); err != nil {
			t.Logf("cleanup ledger balance failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
