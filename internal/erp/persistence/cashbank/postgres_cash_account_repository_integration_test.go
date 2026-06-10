package cashbank

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresCashAccountRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping cash account repository integration test")
	}

	return dsn
}

func TestPostgresCashAccountRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresCashAccountRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresCashAccountRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	cashCode := "KASA-REPO-" + unique[len(unique)-6:]
	isActive := true

	account, err := repo.CreateCashAccount(ctx, CreateCashAccountInput{
		TenantID:       "tenant_7",
		CashCode:       cashCode,
		CashName:       "Merkez Kasa Repo Test " + unique,
		AccountCode:    "100.01",
		AccountName:    "Merkez Kasa",
		CurrencyCode:   "TRY",
		OpeningBalance: 0,
		CurrentBalance: 150,
		IsActive:       true,
		Description:    "FAZ3 cash account repository test " + unique,
		CreatedBy:      "faz3_test",
	})
	if err != nil {
		t.Fatalf("create cash account: %v", err)
	}

	defer cleanupCashAccountRepositoryFixture(t, pool, "tenant_7", account.CashAccountID)

	if account.CashAccountID == "" {
		t.Fatal("expected cash_account_id")
	}

	if account.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", account.TenantID)
	}

	if account.CashCode != cashCode {
		t.Fatalf("expected cash_code %s, got %s", cashCode, account.CashCode)
	}

	if account.CurrentBalance != 150 {
		t.Fatalf("expected current_balance 150, got %v", account.CurrentBalance)
	}

	gotByID, err := repo.GetCashAccountByID(ctx, "tenant_7", account.CashAccountID)
	if err != nil {
		t.Fatalf("get cash account by id: %v", err)
	}

	if gotByID.CashAccountID != account.CashAccountID {
		t.Fatalf("expected cash_account_id %s, got %s", account.CashAccountID, gotByID.CashAccountID)
	}

	gotByCode, err := repo.GetCashAccountByCode(ctx, "tenant_7", cashCode)
	if err != nil {
		t.Fatalf("get cash account by code: %v", err)
	}

	if gotByCode.CashCode != cashCode {
		t.Fatalf("expected cash_code %s, got %s", cashCode, gotByCode.CashCode)
	}

	list, err := repo.ListCashAccounts(ctx, "tenant_7", ListCashAccountsFilter{
		AccountCode:  "100.01",
		CurrencyCode: "TRY",
		IsActive:     &isActive,
		Query:        unique,
		Limit:        10,
	})
	if err != nil {
		t.Fatalf("list cash accounts: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 cash account in list, got %d", len(list))
	}

	_, err = repo.GetCashAccountByID(ctx, "tenant_99", account.CashAccountID)
	if !errors.Is(err, ErrCashAccountNotFound) {
		t.Fatalf("expected ErrCashAccountNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresCashAccountRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresCashAccountRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresCashAccountRepository(pool)

	_, err = repo.CreateCashAccount(ctx, CreateCashAccountInput{
		TenantID: "tenant_7",
		CashName: "Merkez Kasa",
	})

	if !errors.Is(err, ErrCashCodeRequired) {
		t.Fatalf("expected ErrCashCodeRequired, got %v", err)
	}
}

func cleanupCashAccountRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, cashAccountID string) {
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

	if cashAccountID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_payment_transactions WHERE cash_account_id = $1;", cashAccountID); err != nil {
			t.Logf("cleanup payment transactions failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_cash_accounts WHERE cash_account_id = $1;", cashAccountID); err != nil {
			t.Logf("cleanup cash account failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
