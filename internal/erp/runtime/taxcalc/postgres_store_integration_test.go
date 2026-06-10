package taxcalc

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

func postgresTaxStoreTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping tax postgres store integration test")
	}

	return dsn
}

func TestPostgresTaxStorePersistAndMarkPosted(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresTaxStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresTaxStore(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	sourceDocumentNo := "INV-TAX-" + unique

	tableName := detectTaxStoreTableForTest(t, pool)
	cleanupRuntimeTaxFixture(t, pool, tableName, "tenant_7", sourceDocumentNo)
	defer cleanupRuntimeTaxFixture(t, pool, tableName, "tenant_7", sourceDocumentNo)

	req := validTaxCalculationRequest()
	req.Tenant.TenantID = "tenant_7"
	req.Tenant.RequestID = "req-" + unique
	req.Source.SourceDocumentID = "00000000-0000-0000-0000-" + unique[len(unique)-12:]
	req.Source.SourceDocumentNo = sourceDocumentNo
	req.Fiscal.FiscalYear = 2026
	req.Fiscal.FiscalPeriod = "2026-04"
	req.Fiscal.CalculationDate = time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC)
	req.TaxCode.TaxCodeID = ""
	req.TaxCode.Code = "KDV20"
	req.TaxCode.Name = "KDV %20"
	req.TaxCode.Rate = 20
	req.TaxCode.IsActive = true
	req.Money.BaseAmount = 100
	req.Money.CurrencyCode = "TRY"
	req.Money.ExchangeRate = 1
	req.Description = "Runtime tax calculation integration " + unique

	draft, err := BuildTaxCalculationDraft(req)
	if err != nil {
		t.Fatalf("build tax draft: %v", err)
	}

	persistedDraft, err := store.PersistTaxDraft(ctx, draft)
	if err != nil {
		t.Fatalf("persist tax draft: %v", err)
	}

	if persistedDraft.Status != TaxCalculationStatusDraft {
		t.Fatalf("expected draft status, got %s", persistedDraft.Status)
	}

	rowCount := countRuntimeTaxRows(t, pool, tableName, "tenant_7", sourceDocumentNo)
	if rowCount < 1 {
		t.Fatalf("expected at least 1 tax row, got %d", rowCount)
	}

	postedDraft, err := store.MarkTaxPosted(ctx, persistedDraft)
	if err != nil {
		t.Fatalf("mark tax posted: %v", err)
	}

	if postedDraft.Status != TaxCalculationStatusPosted {
		t.Fatalf("expected posted status, got %s", postedDraft.Status)
	}

	status := getRuntimeTaxStatus(t, pool, tableName, "tenant_7", sourceDocumentNo)
	if status == "" {
		t.Log("tax status column yok veya bos; status check atlandi")
	}
}

func TestPostgresTaxStoreValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresTaxStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresTaxStore(pool)

	req := validTaxCalculationRequest()
	req.Tenant.TenantID = ""

	draft := TaxCalculationDraft{
		TenantID:        req.Tenant.TenantID,
		TransactionType: req.TransactionType,
		Source:          req.Source,
		Fiscal:          req.Fiscal,
		CurrencyCode:    req.Money.CurrencyCode,
		ExchangeRate:    req.Money.ExchangeRate,
		Status:          TaxCalculationStatusDraft,
	}

	_, err = store.PersistTaxDraft(ctx, draft)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func detectTaxStoreTableForTest(t *testing.T, pool *pgxpool.Pool) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("detect tax table begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	tableName, err := detectTaxCalculationTable(ctx, tx)
	if err != nil {
		t.Skipf("tax calculation table bulunamadi: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("detect tax table commit failed: %v", err)
	}

	return tableName
}

func cleanupRuntimeTaxFixture(t *testing.T, pool *pgxpool.Pool, tableName string, tenantID string, sourceDocumentNo string) {
	t.Helper()

	if strings.TrimSpace(tableName) == "" {
		return
	}

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

	columns, err := loadTaxcalcTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Logf("cleanup load columns failed: %v", err)
		return
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}

	if _, ok := columns["source_document_no"]; ok {
		args = append(args, sourceDocumentNo)
		whereParts = append(whereParts, fmt.Sprintf("source_document_no = $%d", len(args)))
	} else if _, ok := columns["created_by"]; ok {
		args = append(args, "runtime")
		whereParts = append(whereParts, fmt.Sprintf("created_by = $%d", len(args)))
	} else {
		return
	}

	sql := fmt.Sprintf("DELETE FROM %s WHERE %s;", tableName, strings.Join(whereParts, " AND "))

	if _, err := tx.Exec(ctx, sql, args...); err != nil {
		t.Logf("cleanup tax rows failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
	}
}

func countRuntimeTaxRows(t *testing.T, pool *pgxpool.Pool, tableName string, tenantID string, sourceDocumentNo string) int {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("count tax begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("count tax set tenant failed: %v", err)
	}

	columns, err := loadTaxcalcTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("count load columns failed: %v", err)
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}

	if _, ok := columns["source_document_no"]; ok {
		args = append(args, sourceDocumentNo)
		whereParts = append(whereParts, fmt.Sprintf("source_document_no = $%d", len(args)))
	} else if _, ok := columns["created_by"]; ok {
		args = append(args, "runtime")
		whereParts = append(whereParts, fmt.Sprintf("created_by = $%d", len(args)))
	}

	query := fmt.Sprintf("SELECT COUNT(*) FROM %s WHERE %s;", tableName, strings.Join(whereParts, " AND "))

	var count int
	if err := tx.QueryRow(ctx, query, args...).Scan(&count); err != nil {
		t.Fatalf("count tax query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("count tax commit failed: %v", err)
	}

	return count
}

func getRuntimeTaxStatus(t *testing.T, pool *pgxpool.Pool, tableName string, tenantID string, sourceDocumentNo string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("tax status begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("tax status set tenant failed: %v", err)
	}

	columns, err := loadTaxcalcTableColumns(ctx, tx, tableName)
	if err != nil {
		t.Fatalf("tax status load columns failed: %v", err)
	}

	statusColumn := taxcalcStatusColumn(columns)
	if strings.TrimSpace(statusColumn) == "" {
		return ""
	}

	whereParts := []string{"tenant_id = $1"}
	args := []any{tenantID}

	if _, ok := columns["source_document_no"]; ok {
		args = append(args, sourceDocumentNo)
		whereParts = append(whereParts, fmt.Sprintf("source_document_no = $%d", len(args)))
	} else if _, ok := columns["created_by"]; ok {
		args = append(args, "runtime")
		whereParts = append(whereParts, fmt.Sprintf("created_by = $%d", len(args)))
	}

	query := fmt.Sprintf(`
SELECT %s
FROM %s
WHERE %s
LIMIT 1;
`, statusColumn, tableName, strings.Join(whereParts, " AND "))

	var status string
	if err := tx.QueryRow(ctx, query, args...).Scan(&status); err != nil {
		t.Fatalf("tax status query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("tax status commit failed: %v", err)
	}

	return status
}
