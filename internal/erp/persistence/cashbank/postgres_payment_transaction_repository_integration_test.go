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

func postgresPaymentTransactionRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping payment transaction repository integration test")
	}

	return dsn
}

func TestPostgresPaymentTransactionRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPaymentTransactionRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresPaymentTransactionRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	paymentNo := "PAY-REPO-" + unique
	cashAccountID := createPaymentTransactionCashAccountFixture(t, pool, "tenant_7", unique)
	postedAt := time.Now().UTC()

	payment, err := repo.CreatePaymentTransaction(ctx, CreatePaymentTransactionInput{
		TenantID:           "tenant_7",
		PaymentNo:          paymentNo,
		PaymentDate:        time.Now().UTC(),
		PaymentType:        PaymentTypeCollection,
		PaymentDirection:   PaymentDirectionIn,
		PaymentMethod:      PaymentMethodCash,
		CashAccountID:      cashAccountID,
		SourceModule:       PaymentSourceManual,
		SourceDocumentType: "integration_test",
		CurrencyCode:       "TRY",
		ExchangeRate:       1,
		Amount:             100,
		LocalAmount:        100,
		FeeAmount:          2,
		LocalFeeAmount:     2,
		NetAmount:          98,
		LocalNetAmount:     98,
		Description:        "FAZ3 payment transaction repository test " + unique,
		Status:             PaymentStatusPosted,
		PostedAt:           &postedAt,
		PostedBy:           "faz3_test",
		CreatedBy:          "faz3_test",
	})
	if err != nil {
		cleanupPaymentTransactionRepositoryFixture(t, pool, "tenant_7", cashAccountID)
		t.Fatalf("create payment transaction: %v", err)
	}

	defer cleanupPaymentTransactionRepositoryFixture(t, pool, "tenant_7", cashAccountID)

	if payment.PaymentTransactionID == "" {
		t.Fatal("expected payment_transaction_id")
	}

	if payment.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", payment.TenantID)
	}

	if payment.PaymentNo != paymentNo {
		t.Fatalf("expected payment_no %s, got %s", paymentNo, payment.PaymentNo)
	}

	if payment.NetAmount != 98 {
		t.Fatalf("expected net_amount 98, got %v", payment.NetAmount)
	}

	gotByID, err := repo.GetPaymentTransactionByID(ctx, "tenant_7", payment.PaymentTransactionID)
	if err != nil {
		t.Fatalf("get payment transaction by id: %v", err)
	}

	if gotByID.PaymentTransactionID != payment.PaymentTransactionID {
		t.Fatalf("expected payment_transaction_id %s, got %s", payment.PaymentTransactionID, gotByID.PaymentTransactionID)
	}

	gotByNo, err := repo.GetPaymentTransactionByNo(ctx, "tenant_7", paymentNo)
	if err != nil {
		t.Fatalf("get payment transaction by no: %v", err)
	}

	if gotByNo.PaymentNo != paymentNo {
		t.Fatalf("expected payment_no %s, got %s", paymentNo, gotByNo.PaymentNo)
	}

	list, err := repo.ListPaymentTransactions(ctx, "tenant_7", ListPaymentTransactionsFilter{
		PaymentType:        PaymentTypeCollection,
		PaymentDirection:   PaymentDirectionIn,
		PaymentMethod:      PaymentMethodCash,
		CashAccountID:      cashAccountID,
		SourceModule:       PaymentSourceManual,
		SourceDocumentType: "integration_test",
		Status:             PaymentStatusPosted,
		Query:              unique,
		Limit:              10,
	})
	if err != nil {
		t.Fatalf("list payment transactions: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 payment transaction in list, got %d", len(list))
	}

	_, err = repo.GetPaymentTransactionByID(ctx, "tenant_99", payment.PaymentTransactionID)
	if !errors.Is(err, ErrPaymentTransactionNotFound) {
		t.Fatalf("expected ErrPaymentTransactionNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresPaymentTransactionRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresPaymentTransactionRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresPaymentTransactionRepository(pool)

	_, err = repo.CreatePaymentTransaction(ctx, CreatePaymentTransactionInput{
		TenantID:         "tenant_7",
		PaymentType:      PaymentTypeCollection,
		PaymentDirection: PaymentDirectionIn,
		PaymentMethod:    PaymentMethodCash,
		CashAccountID:    "cash-account-id",
		ExchangeRate:     1,
	})

	if !errors.Is(err, ErrPaymentNoRequired) {
		t.Fatalf("expected ErrPaymentNoRequired, got %v", err)
	}
}

func createPaymentTransactionCashAccountFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) string {
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

	var cashAccountID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_cash_accounts (
    tenant_id,
    cash_code,
    cash_name,
    account_code,
    account_name,
    currency_code,
    opening_balance,
    current_balance,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    '100.01',
    'Merkez Kasa',
    'TRY',
    0.00,
    0.00,
    true,
    $4,
    'active',
    'faz3_payment_transaction_test'
)
RETURNING cash_account_id::text;
`, tenantID, "PAY-CASH-"+unique[len(unique)-6:], "Payment Cash Fixture "+unique, "Payment transaction fixture "+unique).Scan(&cashAccountID); err != nil {
		t.Fatalf("fixture cash account failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return cashAccountID
}

func cleanupPaymentTransactionRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, cashAccountID string) {
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
