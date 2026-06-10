package tax

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresTaxTransactionRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping tax transaction repository integration test")
	}

	return dsn
}

func TestPostgresTaxTransactionRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresTaxTransactionRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresTaxTransactionRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	taxCodeValue := "KDV-TRX-" + unique[len(unique)-6:]
	taxCodeID, taxRateID := createTaxTransactionRepositoryFixture(t, pool, "tenant_7", taxCodeValue, unique)

	transaction, err := repo.CreateTaxTransaction(ctx, CreateTaxTransactionInput{
		TenantID:           "tenant_7",
		TaxCodeID:          taxCodeID,
		TaxRateID:          taxRateID,
		TaxCode:            taxCodeValue,
		TaxName:            "KDV Transaction Repo Test " + unique,
		TaxType:            TaxTypeVAT,
		SourceModule:       TaxSourceSales,
		SourceDocumentType: "invoice",
		TransactionDate:    time.Now().UTC(),
		FiscalYear:         2026,
		FiscalPeriod:       "2026-04",
		BaseAmount:         100,
		RatePercent:        20,
		TaxAmount:          20,
		WithholdingAmount:  0,
		PayableAmount:      20,
		RecoverableAmount:  0,
		CurrencyCode:       "TRY",
		ExchangeRate:       1,
		LocalBaseAmount:    100,
		LocalTaxAmount:     20,
		Direction:          TaxDirectionPayable,
		Status:             TaxTransactionStatusPosted,
		CreatedBy:          "faz3_test",
	})
	if err != nil {
		cleanupTaxTransactionRepositoryFixture(t, pool, "tenant_7", taxCodeID)
		t.Fatalf("create tax transaction: %v", err)
	}

	defer cleanupTaxTransactionRepositoryFixture(t, pool, "tenant_7", taxCodeID)

	if transaction.TaxTransactionID == "" {
		t.Fatal("expected tax_transaction_id")
	}

	if transaction.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", transaction.TenantID)
	}

	if transaction.TaxCode != taxCodeValue {
		t.Fatalf("expected tax_code %s, got %s", taxCodeValue, transaction.TaxCode)
	}

	if transaction.TaxAmount != 20 {
		t.Fatalf("expected tax_amount 20, got %v", transaction.TaxAmount)
	}

	gotByID, err := repo.GetTaxTransactionByID(ctx, "tenant_7", transaction.TaxTransactionID)
	if err != nil {
		t.Fatalf("get tax transaction by id: %v", err)
	}

	if gotByID.TaxTransactionID != transaction.TaxTransactionID {
		t.Fatalf("expected tax_transaction_id %s, got %s", transaction.TaxTransactionID, gotByID.TaxTransactionID)
	}

	list, err := repo.ListTaxTransactions(ctx, "tenant_7", ListTaxTransactionsFilter{
		TaxCode:            taxCodeValue,
		TaxType:            TaxTypeVAT,
		SourceModule:       TaxSourceSales,
		SourceDocumentType: "invoice",
		FiscalYear:         2026,
		FiscalPeriod:       "2026-04",
		Direction:          TaxDirectionPayable,
		Status:             TaxTransactionStatusPosted,
		Query:              taxCodeValue,
		Limit:              10,
	})
	if err != nil {
		t.Fatalf("list tax transactions: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 tax transaction in list, got %d", len(list))
	}

	_, err = repo.GetTaxTransactionByID(ctx, "tenant_99", transaction.TaxTransactionID)
	if !errors.Is(err, ErrTaxTransactionNotFound) {
		t.Fatalf("expected ErrTaxTransactionNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresTaxTransactionRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresTaxTransactionRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresTaxTransactionRepository(pool)

	_, err = repo.CreateTaxTransaction(ctx, CreateTaxTransactionInput{
		TenantID:     "tenant_7",
		TaxType:      TaxTypeVAT,
		SourceModule: TaxSourceSales,
		FiscalYear:   2026,
		FiscalPeriod: "2026-04",
		ExchangeRate: 1,
		Direction:    TaxDirectionPayable,
	})

	if !errors.Is(err, ErrTaxCodeRequired) {
		t.Fatalf("expected ErrTaxCodeRequired, got %v", err)
	}
}

func createTaxTransactionRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, taxCodeValue string, unique string) (string, string) {
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

	var taxCodeID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_tax_codes (
    tenant_id,
    tax_code,
    tax_name,
    tax_type,
    account_code,
    account_name,
    is_recoverable,
    is_payable,
    is_withholding,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    'vat',
    '391.01.20',
    'Hesaplanan KDV',
    false,
    true,
    false,
    true,
    $4,
    'active',
    'faz3_tax_transaction_test'
)
RETURNING tax_code_id::text;
`, tenantID, taxCodeValue, "KDV Transaction Fixture "+unique, "Tax transaction fixture "+unique).Scan(&taxCodeID); err != nil {
		t.Fatalf("fixture tax code failed: %v", err)
	}

	var taxRateID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_tax_rates (
    tenant_id,
    tax_code_id,
    tax_code,
    rate_percent,
    valid_from,
    is_default,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    20.00,
    CURRENT_DATE,
    true,
    true,
    $4,
    'active',
    'faz3_tax_transaction_test'
)
RETURNING tax_rate_id::text;
`, tenantID, taxCodeID, taxCodeValue, "Tax transaction rate fixture "+unique).Scan(&taxRateID); err != nil {
		t.Fatalf("fixture tax rate failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return taxCodeID, taxRateID
}

func cleanupTaxTransactionRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, taxCodeID string) {
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

	if taxCodeID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_tax_transactions WHERE tax_code_id = $1;", taxCodeID); err != nil {
			t.Logf("cleanup tax transactions failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_tax_rates WHERE tax_code_id = $1;", taxCodeID); err != nil {
			t.Logf("cleanup tax rates failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_tax_codes WHERE tax_code_id = $1;", taxCodeID); err != nil {
			t.Logf("cleanup tax code failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
