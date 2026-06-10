package ledgerpost

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresLedgerPostStoreTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping ledger post postgres store integration test")
	}

	return dsn
}

func TestPostgresLedgerPostingStorePersistAndMarkPosted(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresLedgerPostStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresLedgerPostingStore(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	journalNo := "JRNL-LEDGER-" + unique
	journalEntryID := createRuntimeLedgerJournalFixture(t, pool, "tenant_7", journalNo, unique)

	defer cleanupRuntimeLedgerPostFixture(t, pool, "tenant_7", journalEntryID, journalNo)

	req := validLedgerPostingRequest()
	req.Tenant.TenantID = "tenant_7"
	req.Tenant.RequestID = "req-" + unique
	req.Journal.JournalEntryID = journalEntryID
	req.Journal.JournalNo = journalNo
	req.Journal.JournalStatus = JournalStatusPosted
	req.Fiscal.FiscalYear = 2026
	req.Fiscal.FiscalPeriod = "2026-04"
	req.Fiscal.PostingDate = time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC)
	req.Description = "Runtime ledger post integration " + unique

	draft, err := BuildLedgerPostingDraft(req)
	if err != nil {
		t.Fatalf("build ledger draft: %v", err)
	}

	persistedDraft, err := store.PersistLedgerDraft(ctx, draft)
	if err != nil {
		t.Fatalf("persist ledger draft: %v", err)
	}

	if persistedDraft.Status != LedgerPostingStatusDraft {
		t.Fatalf("expected draft status, got %s", persistedDraft.Status)
	}

	movementCount := countRuntimeAccountMovements(t, pool, "tenant_7", journalEntryID, journalNo)
	if movementCount != 3 {
		t.Fatalf("expected 3 account movements, got %d", movementCount)
	}

	postedDraft, err := store.MarkLedgerPosted(ctx, persistedDraft)
	if err != nil {
		t.Fatalf("mark ledger posted: %v", err)
	}

	if postedDraft.Status != LedgerPostingStatusPosted {
		t.Fatalf("expected posted status, got %s", postedDraft.Status)
	}

	status := getRuntimeLedgerMovementStatus(t, pool, "tenant_7", journalEntryID, journalNo)
	if status != "" && status != "posted" && status != string(LedgerPostingStatusPosted) {
		t.Fatalf("expected DB status posted/posted or empty, got %s", status)
	}
}

func TestPostgresLedgerPostingStoreValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresLedgerPostStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresLedgerPostingStore(pool)

	req := validLedgerPostingRequest()
	req.Tenant.TenantID = ""

	draft := LedgerPostingDraft{
		TenantID:    req.Tenant.TenantID,
		Journal:     req.Journal,
		Fiscal:      req.Fiscal,
		Status:      LedgerPostingStatusDraft,
		Description: req.Description,
	}

	_, err = store.PersistLedgerDraft(ctx, draft)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func createRuntimeLedgerJournalFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, journalNo string, unique string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("journal fixture begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("journal fixture set tenant failed: %v", err)
	}

	columns, err := loadLedgerTableColumns(ctx, tx, "erp_journal_entries")
	if err != nil {
		t.Fatalf("journal fixture load columns failed: %v", err)
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

	addUUID := func(column string, value string) {
		if _, ok := columns[column]; !ok {
			return
		}

		names = append(names, column)
		values = append(values, ledgerNullableUUID(columns[column], value))
	}

	sourceID := "00000000-0000-0000-0000-" + unique[len(unique)-12:]

	add("tenant_id", tenantID)
	add("journal_no", journalNo)

	add("journal_date", time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC))
	add("posting_date", time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC))
	add("entry_date", time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC))

	add("source_module", "sales")
	add("source_document_type", "invoice")
	addUUID("source_document_id", sourceID)
	add("source_document_no", "INV-"+unique)

	add("fiscal_year", 2026)
	add("fiscal_period", "2026-04")

	add("description", "Runtime ledger journal fixture "+unique)
	add("status", "posted")

	add("total_debit", 120)
	add("total_credit", 120)
	add("debit_total", 120)
	add("credit_total", 120)

	add("created_by", "faz3_ledger_runtime_test")
	add("updated_by", "faz3_ledger_runtime_test")

	if len(names) == 0 {
		t.Fatal("journal fixture no insert columns")
	}

	returning := ""
	if _, ok := columns["journal_entry_id"]; ok {
		returning = " RETURNING journal_entry_id::text"
	}

	sql := buildRuntimeLedgerInsertSQL("erp_journal_entries", names, returning)

	if returning == "" {
		if _, err := tx.Exec(ctx, sql, values...); err != nil {
			t.Fatalf("journal fixture insert failed: %v", err)
		}

		if err := tx.Commit(ctx); err != nil {
			t.Fatalf("journal fixture commit failed: %v", err)
		}

		return ""
	}

	var journalEntryID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&journalEntryID); err != nil {
		t.Fatalf("journal fixture insert returning failed: %v", err)
	}

	insertRuntimeLedgerJournalLinesFixture(t, ctx, tx, tenantID, journalEntryID)

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("journal fixture commit failed: %v", err)
	}

	return journalEntryID
}

func insertRuntimeLedgerJournalLinesFixture(t *testing.T, ctx context.Context, tx pgx.Tx, tenantID string, journalEntryID string) {
	t.Helper()

	if strings.TrimSpace(journalEntryID) == "" {
		t.Fatal("journalEntryID bos; journal line fixture olusturulamaz")
	}

	columns, err := loadLedgerTableColumns(ctx, tx, "erp_journal_lines")
	if err != nil {
		t.Fatalf("journal line fixture load columns failed: %v", err)
	}

	lines := []LedgerLineDraft{
		{
			LineNo:       1,
			AccountCode:  "120.01",
			AccountName:  "Alicilar",
			DebitAmount:  120,
			CurrencyCode: "TRY",
			ExchangeRate: 1,
			Description:  "Cari borc",
		},
		{
			LineNo:       2,
			AccountCode:  "600.01",
			AccountName:  "Yurt Ici Satislar",
			CreditAmount: 100,
			CurrencyCode: "TRY",
			ExchangeRate: 1,
			Description:  "Satis geliri",
		},
		{
			LineNo:       3,
			AccountCode:  "391.01",
			AccountName:  "Hesaplanan KDV",
			CreditAmount: 20,
			CurrencyCode: "TRY",
			ExchangeRate: 1,
			Description:  "KDV",
		},
	}

	for _, line := range lines {
		insertRuntimeLedgerJournalLineFixture(t, ctx, tx, columns, tenantID, journalEntryID, line)
	}
}

func insertRuntimeLedgerJournalLineFixture(
	t *testing.T,
	ctx context.Context,
	tx pgx.Tx,
	columns map[string]ledgerColumnInfo,
	tenantID string,
	journalEntryID string,
	line LedgerLineDraft,
) {
	t.Helper()

	names := make([]string, 0)
	values := make([]any, 0)

	add := func(column string, value any) {
		if _, ok := columns[column]; !ok {
			return
		}

		names = append(names, column)
		values = append(values, value)
	}

	addUUID := func(column string, value string) {
		if _, ok := columns[column]; !ok {
			return
		}

		names = append(names, column)
		values = append(values, ledgerNullableUUID(columns[column], value))
	}

	add("tenant_id", tenantID)
	addUUID("journal_entry_id", journalEntryID)

	add("line_no", line.LineNo)
	add("account_code", line.AccountCode)
	add("account_name", line.AccountName)

	add("debit_amount", line.DebitAmount)
	add("credit_amount", line.CreditAmount)
	add("local_debit_amount", line.DebitAmount)
	add("local_credit_amount", line.CreditAmount)

	add("currency_code", line.CurrencyCode)
	add("exchange_rate", line.ExchangeRate)

	add("description", line.Description)

	add("created_by", "faz3_ledger_runtime_test")
	add("updated_by", "faz3_ledger_runtime_test")

	if len(names) == 0 {
		t.Fatal("journal line fixture no insert columns")
	}

	sql := buildRuntimeLedgerInsertSQL("erp_journal_lines", names, "")

	if _, err := tx.Exec(ctx, sql, values...); err != nil {
		t.Fatalf("journal line fixture insert failed: %v", err)
	}
}

func cleanupRuntimeLedgerPostFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, journalEntryID string, journalNo string) {
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

	deleteAccountMovementsForJournal(t, ctx, tx, tenantID, journalEntryID, journalNo)

	if journalEntryID != "" {
		if _, err := tx.Exec(ctx, `
DELETE FROM erp_journal_lines
WHERE tenant_id = $1
  AND journal_entry_id = $2;
`, tenantID, journalEntryID); err != nil {
			t.Logf("cleanup journal lines by id failed: %v", err)
		}
	}

	if _, err := tx.Exec(ctx, `
DELETE FROM erp_journal_entries
WHERE tenant_id = $1
  AND journal_no = $2;
`, tenantID, journalNo); err != nil {
		t.Logf("cleanup journal entries failed: %v", err)
		return
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
	}
}

func deleteAccountMovementsForJournal(t *testing.T, ctx context.Context, tx pgx.Tx, tenantID string, journalEntryID string, journalNo string) {
	t.Helper()

	columns, err := loadLedgerTableColumns(ctx, tx, "erp_account_movements")
	if err != nil {
		t.Logf("cleanup load account movement columns failed: %v", err)
		return
	}

	if _, ok := columns["journal_entry_id"]; ok && strings.TrimSpace(journalEntryID) != "" {
		if _, err := tx.Exec(ctx, `
DELETE FROM erp_account_movements
WHERE tenant_id = $1
  AND journal_entry_id = $2;
`, tenantID, journalEntryID); err != nil {
			t.Logf("cleanup account movements by journal_entry_id failed: %v", err)
		}

		return
	}

	if _, ok := columns["journal_no"]; ok && strings.TrimSpace(journalNo) != "" {
		if _, err := tx.Exec(ctx, `
DELETE FROM erp_account_movements
WHERE tenant_id = $1
  AND journal_no = $2;
`, tenantID, journalNo); err != nil {
			t.Logf("cleanup account movements by journal_no failed: %v", err)
		}

		return
	}

	if _, ok := columns["created_by"]; ok {
		if _, err := tx.Exec(ctx, `
DELETE FROM erp_account_movements
WHERE tenant_id = $1
  AND created_by = 'runtime';
`, tenantID); err != nil {
			t.Logf("cleanup account movements by created_by failed: %v", err)
		}
	}
}

func countRuntimeAccountMovements(t *testing.T, pool *pgxpool.Pool, tenantID string, journalEntryID string, journalNo string) int {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("count movements begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("count movements set tenant failed: %v", err)
	}

	columns, err := loadLedgerTableColumns(ctx, tx, "erp_account_movements")
	if err != nil {
		t.Fatalf("count movements load columns failed: %v", err)
	}

	var count int

	if _, ok := columns["journal_entry_id"]; ok && strings.TrimSpace(journalEntryID) != "" {
		if err := tx.QueryRow(ctx, `
SELECT COUNT(*)
FROM erp_account_movements
WHERE tenant_id = $1
  AND journal_entry_id = $2;
`, tenantID, journalEntryID).Scan(&count); err != nil {
			t.Fatalf("count movements by journal_entry_id failed: %v", err)
		}
	} else if _, ok := columns["journal_no"]; ok && strings.TrimSpace(journalNo) != "" {
		if err := tx.QueryRow(ctx, `
SELECT COUNT(*)
FROM erp_account_movements
WHERE tenant_id = $1
  AND journal_no = $2;
`, tenantID, journalNo).Scan(&count); err != nil {
			t.Fatalf("count movements by journal_no failed: %v", err)
		}
	} else {
		if err := tx.QueryRow(ctx, `
SELECT COUNT(*)
FROM erp_account_movements
WHERE tenant_id = $1
  AND created_by = 'runtime';
`, tenantID).Scan(&count); err != nil {
			t.Fatalf("count movements by created_by failed: %v", err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("count movements commit failed: %v", err)
	}

	return count
}

func getRuntimeLedgerMovementStatus(t *testing.T, pool *pgxpool.Pool, tenantID string, journalEntryID string, journalNo string) string {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("status begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("status set tenant failed: %v", err)
	}

	columns, err := loadLedgerTableColumns(ctx, tx, "erp_account_movements")
	if err != nil {
		t.Fatalf("status load columns failed: %v", err)
	}

	if _, ok := columns["status"]; !ok {
		return ""
	}

	orderBy := ""
	if _, ok := columns["line_no"]; ok {
		orderBy = "ORDER BY line_no ASC"
	} else if _, ok := columns["account_movement_id"]; ok {
		orderBy = "ORDER BY account_movement_id ASC"
	} else if _, ok := columns["created_at"]; ok {
		orderBy = "ORDER BY created_at ASC"
	}

	var status string

	if _, ok := columns["journal_entry_id"]; ok && strings.TrimSpace(journalEntryID) != "" {
		query := fmt.Sprintf(`
SELECT status
FROM erp_account_movements
WHERE tenant_id = $1
  AND journal_entry_id = $2
%s
LIMIT 1;
`, orderBy)

		if err := tx.QueryRow(ctx, query, tenantID, journalEntryID).Scan(&status); err != nil {
			t.Fatalf("status query by journal_entry_id failed: %v", err)
		}
	} else if _, ok := columns["journal_no"]; ok && strings.TrimSpace(journalNo) != "" {
		query := fmt.Sprintf(`
SELECT status
FROM erp_account_movements
WHERE tenant_id = $1
  AND journal_no = $2
%s
LIMIT 1;
`, orderBy)

		if err := tx.QueryRow(ctx, query, tenantID, journalNo).Scan(&status); err != nil {
			t.Fatalf("status query by journal_no failed: %v", err)
		}
	} else {
		return ""
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("status commit failed: %v", err)
	}

	return status
}

func buildRuntimeLedgerInsertSQL(table string, columns []string, returning string) string {
	placeholders := make([]string, 0, len(columns))

	for i := range columns {
		placeholders = append(placeholders, fmt.Sprintf("$%d", i+1))
	}

	return fmt.Sprintf(
		"INSERT INTO %s (%s) VALUES (%s)%s;",
		table,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
		returning,
	)
}
