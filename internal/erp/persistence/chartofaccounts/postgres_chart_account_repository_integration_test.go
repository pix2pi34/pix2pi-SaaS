package chartofaccounts

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresChartAccountRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping chart account repository integration test")
	}

	return dsn
}

func TestPostgresChartAccountRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresChartAccountRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresChartAccountRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	accountCode := "120." + unique[len(unique)-6:]
	vatRate := 20.0
	isPostable := true
	isActive := true

	account, err := repo.CreateChartAccount(ctx, CreateChartAccountInput{
		TenantID:          "tenant_7",
		AccountCode:       accountCode,
		AccountName:       "Alicilar Repo Test " + unique,
		ParentAccountCode: "120",
		AccountLevel:      2,
		AccountClass:      "1",
		AccountGroup:      "12",
		AccountType:       AccountTypeAsset,
		NormalBalance:     NormalBalanceDebit,
		IsPostable:        true,
		IsActive:          true,
		CurrencyCode:      "TRY",
		TaxCode:           "KDV20",
		VATRate:           &vatRate,
		Description:       "FAZ3 chart account repository test " + unique,
		CreatedBy:         "faz3_test",
	})
	if err != nil {
		t.Fatalf("create chart account: %v", err)
	}

	defer cleanupChartAccountFixture(t, pool, "tenant_7", account.ChartAccountID)

	if account.ChartAccountID == "" {
		t.Fatal("expected chart_account_id")
	}

	if account.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", account.TenantID)
	}

	if account.AccountCode != accountCode {
		t.Fatalf("expected account_code %s, got %s", accountCode, account.AccountCode)
	}

	if account.AccountType != AccountTypeAsset {
		t.Fatalf("expected asset account type, got %s", account.AccountType)
	}

	if account.VATRate == nil || *account.VATRate != 20 {
		t.Fatalf("expected vat_rate 20, got %v", account.VATRate)
	}

	gotByID, err := repo.GetChartAccountByID(ctx, "tenant_7", account.ChartAccountID)
	if err != nil {
		t.Fatalf("get chart account by id: %v", err)
	}

	if gotByID.ChartAccountID != account.ChartAccountID {
		t.Fatalf("expected chart_account_id %s, got %s", account.ChartAccountID, gotByID.ChartAccountID)
	}

	gotByCode, err := repo.GetChartAccountByCode(ctx, "tenant_7", accountCode)
	if err != nil {
		t.Fatalf("get chart account by code: %v", err)
	}

	if gotByCode.AccountCode != accountCode {
		t.Fatalf("expected account_code %s, got %s", accountCode, gotByCode.AccountCode)
	}

	list, err := repo.ListChartAccounts(ctx, "tenant_7", ListChartAccountsFilter{
		AccountType:       AccountTypeAsset,
		NormalBalance:     NormalBalanceDebit,
		ParentAccountCode: "120",
		IsPostable:        &isPostable,
		IsActive:          &isActive,
		Query:             unique,
		Limit:             10,
	})
	if err != nil {
		t.Fatalf("list chart accounts: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 chart account in list, got %d", len(list))
	}

	_, err = repo.GetChartAccountByID(ctx, "tenant_99", account.ChartAccountID)
	if !errors.Is(err, ErrChartAccountNotFound) {
		t.Fatalf("expected ErrChartAccountNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresChartAccountRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresChartAccountRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresChartAccountRepository(pool)

	_, err = repo.CreateChartAccount(ctx, CreateChartAccountInput{
		TenantID:      "tenant_7",
		AccountName:   "Alicilar",
		AccountLevel:  1,
		AccountType:   AccountTypeAsset,
		NormalBalance: NormalBalanceDebit,
	})

	if !errors.Is(err, ErrAccountCodeRequired) {
		t.Fatalf("expected ErrAccountCodeRequired, got %v", err)
	}
}

func cleanupChartAccountFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, chartAccountID string) {
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

	if chartAccountID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_chart_accounts WHERE chart_account_id = $1;", chartAccountID); err != nil {
			t.Logf("cleanup chart account failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
