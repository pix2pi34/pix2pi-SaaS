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

func postgresBankAccountRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping bank account repository integration test")
	}

	return dsn
}

func TestPostgresBankAccountRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresBankAccountRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresBankAccountRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	bankCode := "BANK-REPO-" + unique[len(unique)-6:]
	isActive := true

	account, err := repo.CreateBankAccount(ctx, CreateBankAccountInput{
		TenantID:       "tenant_7",
		BankCode:       bankCode,
		BankName:       "Test Bankasi Repo " + unique,
		BranchCode:     "0001",
		BranchName:     "Merkez",
		IBAN:           "TR000000000000000000" + unique[len(unique)-6:],
		AccountNo:      "ACC-" + unique[len(unique)-6:],
		AccountCode:    "102.01",
		AccountName:    "Banka Hesabi",
		CurrencyCode:   "TRY",
		OpeningBalance: 0,
		CurrentBalance: 250,
		IsActive:       true,
		Description:    "FAZ3 bank account repository test " + unique,
		CreatedBy:      "faz3_test",
	})
	if err != nil {
		t.Fatalf("create bank account: %v", err)
	}

	defer cleanupBankAccountRepositoryFixture(t, pool, "tenant_7", account.BankAccountID)

	if account.BankAccountID == "" {
		t.Fatal("expected bank_account_id")
	}

	if account.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", account.TenantID)
	}

	if account.BankCode != bankCode {
		t.Fatalf("expected bank_code %s, got %s", bankCode, account.BankCode)
	}

	if account.CurrentBalance != 250 {
		t.Fatalf("expected current_balance 250, got %v", account.CurrentBalance)
	}

	gotByID, err := repo.GetBankAccountByID(ctx, "tenant_7", account.BankAccountID)
	if err != nil {
		t.Fatalf("get bank account by id: %v", err)
	}

	if gotByID.BankAccountID != account.BankAccountID {
		t.Fatalf("expected bank_account_id %s, got %s", account.BankAccountID, gotByID.BankAccountID)
	}

	gotByCode, err := repo.GetBankAccountByCode(ctx, "tenant_7", bankCode)
	if err != nil {
		t.Fatalf("get bank account by code: %v", err)
	}

	if gotByCode.BankCode != bankCode {
		t.Fatalf("expected bank_code %s, got %s", bankCode, gotByCode.BankCode)
	}

	list, err := repo.ListBankAccounts(ctx, "tenant_7", ListBankAccountsFilter{
		AccountCode:  "102.01",
		CurrencyCode: "TRY",
		IsActive:     &isActive,
		Query:        unique,
		Limit:        10,
	})
	if err != nil {
		t.Fatalf("list bank accounts: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 bank account in list, got %d", len(list))
	}

	_, err = repo.GetBankAccountByID(ctx, "tenant_99", account.BankAccountID)
	if !errors.Is(err, ErrBankAccountNotFound) {
		t.Fatalf("expected ErrBankAccountNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresBankAccountRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresBankAccountRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresBankAccountRepository(pool)

	_, err = repo.CreateBankAccount(ctx, CreateBankAccountInput{
		TenantID: "tenant_7",
		BankName: "Test Bankasi",
	})

	if !errors.Is(err, ErrBankCodeRequired) {
		t.Fatalf("expected ErrBankCodeRequired, got %v", err)
	}
}

func cleanupBankAccountRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, bankAccountID string) {
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

	if bankAccountID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_payment_transactions WHERE bank_account_id = $1;", bankAccountID); err != nil {
			t.Logf("cleanup payment transactions failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_bank_accounts WHERE bank_account_id = $1;", bankAccountID); err != nil {
			t.Logf("cleanup bank account failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
