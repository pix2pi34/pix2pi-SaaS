package cashbankpay

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresCashbankPaymentStoreTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping cashbank payment postgres store integration test")
	}

	return dsn
}

func TestPostgresPaymentStorePersistAndMarkPosted(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresCashbankPaymentStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresPaymentStore(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	paymentNo := "PAY-RUNTIME-" + unique

	cashAccountID := createRuntimeCashbankCashAccountFixture(t, pool, "tenant_7", unique)
	defer cleanupRuntimeCashbankCashAccountFixture(t, pool, "tenant_7", cashAccountID)

	cleanupRuntimePaymentFixture(t, pool, "tenant_7", paymentNo)
	defer cleanupRuntimePaymentFixture(t, pool, "tenant_7", paymentNo)

	req := validPaymentRequest()
	req.Tenant.TenantID = "tenant_7"
	req.Tenant.RequestID = "req-" + unique
	req.PaymentNo = paymentNo
	req.Source.SourceDocumentID = "00000000-0000-0000-0000-" + unique[len(unique)-12:]
	req.Source.SourceDocumentNo = "INV-" + unique
	req.Fiscal.FiscalYear = 2026
	req.Fiscal.FiscalPeriod = "2026-04"
	req.Fiscal.PaymentDate = time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC)
	req.Account.AccountID = cashAccountID
	req.Account.AccountCode = "100.01"
	req.Account.AccountName = "Merkez Kasa"
	req.Account.AccountType = AccountTypeCash
	req.Description = "Runtime cashbank payment integration " + unique

	draft, err := BuildPaymentDraft(req)
	if err != nil {
		t.Fatalf("build payment draft: %v", err)
	}

	persistedDraft, err := store.PersistPaymentDraft(ctx, draft)
	if err != nil {
		t.Fatalf("persist payment draft: %v", err)
	}

	if persistedDraft.Status != PaymentStatusDraft {
		t.Fatalf("expected draft status, got %s", persistedDraft.Status)
	}

	transactionCount := countRuntimePaymentTransactions(t, pool, "tenant_7", paymentNo)
	if transactionCount != 1 {
		t.Fatalf("expected 1 payment transaction, got %d", transactionCount)
	}

	postedDraft, err := store.MarkPaymentPosted(ctx, persistedDraft)
	if err != nil {
		t.Fatalf("mark payment posted: %v", err)
	}

	if postedDraft.Status != PaymentStatusPosted {
		t.Fatalf("expected posted status, got %s", postedDraft.Status)
	}

	status := getRuntimePaymentStatus(t, pool, "tenant_7", paymentNo)
	if status == "" {
		t.Fatal("expected DB payment status")
	}
}

func TestPostgresPaymentStoreValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresCashbankPaymentStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresPaymentStore(pool)

	req := validPaymentRequest()
	req.Tenant.TenantID = ""

	draft := PaymentDraft{
		TenantID:     req.Tenant.TenantID,
		PaymentNo:    req.PaymentNo,
		Direction:    req.Direction,
		Method:       req.Method,
		Account:      req.Account,
		Counterparty: req.Counterparty,
		Money:        req.Money,
		Fiscal:       req.Fiscal,
		Source:       req.Source,
		Status:       PaymentStatusDraft,
	}

	_, err = store.PersistPaymentDraft(ctx, draft)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func createRuntimeCashbankCashAccountFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("cash account fixture begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("cash account fixture set tenant failed: %v", err)
	}

	columns, err := loadCashbankTableColumns(ctx, tx, "erp_cash_accounts")
	if err != nil {
		t.Fatalf("cash account fixture load columns failed: %v", err)
	}

	names := make([]string, 0)
	values := make([]any, 0)

	add := func(column string, value any) {
		if _, ok := columns[column]; !ok {
			return
		}

		names = append(names, column)
		values = append(values, value)
	}

	accountCode := "100.TEST." + unique[len(unique)-6:]
	accountName := "Runtime Test Kasa " + unique[len(unique)-6:]

	add("tenant_id", tenantID)
	add("cash_code", accountCode)
	add("cash_name", accountName)
	add("cash_account_code", accountCode)
	add("account_code", accountCode)
	add("cash_account_name", accountName)
	add("account_name", accountName)
	add("name", accountName)
	add("currency_code", "TRY")
	add("opening_balance", 0)
	add("current_balance", 0)
	add("balance", 0)
	add("is_active", true)
	add("status", "active")
	add("description", "Runtime cashbank payment fixture "+unique)
	add("created_by", "faz3_cashbankpay_runtime_test")
	add("updated_by", "faz3_cashbankpay_runtime_test")

	if len(names) == 0 {
		t.Fatal("cash account fixture no insert columns")
	}

	returningColumn := "cash_account_id"
	if _, ok := columns["cash_account_id"]; !ok {
		if _, ok := columns["account_id"]; ok {
			returningColumn = "account_id"
		} else {
			t.Fatal("cash account id column bulunamadi")
		}
	}

	sql := buildCashbankInsertSQL("erp_cash_accounts", names)[:len(buildCashbankInsertSQL("erp_cash_accounts", names))-1] +
		" RETURNING " + returningColumn + "::text;"

	var cashAccountID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&cashAccountID); err != nil {
		t.Fatalf("cash account fixture insert failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("cash account fixture commit failed: %v", err)
	}

	return cashAccountID
}

func cleanupRuntimeCashbankCashAccountFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, cashAccountID string) {
	t.Helper()

	if strings.TrimSpace(cashAccountID) == "" {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("cash account cleanup begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("cash account cleanup set tenant failed: %v", err)
		return
	}

	if _, err := tx.Exec(ctx, `
DELETE FROM erp_cash_accounts
WHERE tenant_id = $1
  AND cash_account_id = $2;
`, tenantID, cashAccountID); err != nil {
		t.Logf("cash account cleanup failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cash account cleanup commit failed: %v", err)
	}
}

func cleanupRuntimePaymentFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, paymentNo string) {
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
DELETE FROM erp_payment_transactions
WHERE tenant_id = $1
  AND payment_no = $2;
`, tenantID, paymentNo); err != nil {
		t.Logf("cleanup payment transactions failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
	}
}

func countRuntimePaymentTransactions(t *testing.T, pool *pgxpool.Pool, tenantID string, paymentNo string) int {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("count payment begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("count payment set tenant failed: %v", err)
	}

	var count int
	if err := tx.QueryRow(ctx, `
SELECT COUNT(*)
FROM erp_payment_transactions
WHERE tenant_id = $1
  AND payment_no = $2;
`, tenantID, paymentNo).Scan(&count); err != nil {
		t.Fatalf("count payment query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("count payment commit failed: %v", err)
	}

	return count
}

func getRuntimePaymentStatus(t *testing.T, pool *pgxpool.Pool, tenantID string, paymentNo string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("payment status begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("payment status set tenant failed: %v", err)
	}

	columns, err := loadCashbankTableColumns(ctx, tx, "erp_payment_transactions")
	if err != nil {
		t.Fatalf("payment status load columns failed: %v", err)
	}

	statusColumn := cashbankStatusColumn(columns)
	if strings.TrimSpace(statusColumn) == "" {
		return ""
	}

	query := fmt.Sprintf(`
SELECT %s
FROM erp_payment_transactions
WHERE tenant_id = $1
  AND payment_no = $2
LIMIT 1;
`, statusColumn)

	var status string
	if err := tx.QueryRow(ctx, query, tenantID, paymentNo).Scan(&status); err != nil {
		t.Fatalf("payment status query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("payment status commit failed: %v", err)
	}

	return status
}
