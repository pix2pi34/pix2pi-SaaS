package journal

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresJournalRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping journal repository integration test")
	}

	return dsn
}

func TestPostgresJournalRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresJournalRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresJournalRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	journalNo := "JRNL-REPO-" + unique
	postingDate := time.Now().UTC()

	entry, err := repo.CreateJournalEntry(ctx, CreateJournalEntryInput{
		TenantID:           "tenant_7",
		JournalNo:          journalNo,
		JournalDate:        time.Now().UTC(),
		PostingDate:        &postingDate,
		FiscalYear:         2026,
		FiscalPeriod:       "2026-04",
		SourceModule:       JournalSourceManual,
		SourceDocumentType: "integration_test",
		CurrencyCode:       "TRY",
		ExchangeRate:       1,
		Description:        "FAZ3 journal repository test " + unique,
		TotalDebit:         120,
		TotalCredit:        120,
		Status:             JournalStatusPosted,
		CreatedBy:          "faz3_test",
	})
	if err != nil {
		t.Fatalf("create journal entry: %v", err)
	}

	debitLine, err := repo.CreateJournalLine(ctx, CreateJournalLineInput{
		TenantID:          "tenant_7",
		JournalEntryID:    entry.JournalEntryID,
		LineNo:            1,
		AccountCode:       "120",
		AccountName:       "Alicilar",
		Description:       "FAZ3 debit line " + unique,
		DebitAmount:       120,
		CreditAmount:      0,
		CurrencyCode:      "TRY",
		ExchangeRate:      1,
		LocalDebitAmount:  120,
		LocalCreditAmount: 0,
		CostCenterCode:    "CC-TEST",
		ProjectCode:       "PRJ-TEST",
		CreatedBy:         "faz3_test",
	})
	if err != nil {
		cleanupJournalRepositoryFixture(t, pool, "tenant_7", entry.JournalEntryID)
		t.Fatalf("create debit journal line: %v", err)
	}

	creditLine, err := repo.CreateJournalLine(ctx, CreateJournalLineInput{
		TenantID:          "tenant_7",
		JournalEntryID:    entry.JournalEntryID,
		LineNo:            2,
		AccountCode:       "600",
		AccountName:       "Yurt Ici Satislar",
		Description:       "FAZ3 credit line " + unique,
		DebitAmount:       0,
		CreditAmount:      120,
		CurrencyCode:      "TRY",
		ExchangeRate:      1,
		LocalDebitAmount:  0,
		LocalCreditAmount: 120,
		CostCenterCode:    "CC-TEST",
		ProjectCode:       "PRJ-TEST",
		CreatedBy:         "faz3_test",
	})
	if err != nil {
		cleanupJournalRepositoryFixture(t, pool, "tenant_7", entry.JournalEntryID)
		t.Fatalf("create credit journal line: %v", err)
	}

	defer cleanupJournalRepositoryFixture(t, pool, "tenant_7", entry.JournalEntryID)

	if entry.JournalEntryID == "" {
		t.Fatal("expected journal_entry_id")
	}

	if entry.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", entry.TenantID)
	}

	if entry.JournalNo != journalNo {
		t.Fatalf("expected journal_no %s, got %s", journalNo, entry.JournalNo)
	}

	if debitLine.JournalLineID == "" || creditLine.JournalLineID == "" {
		t.Fatal("expected journal_line_id values")
	}

	got, err := repo.GetJournalEntryByID(ctx, "tenant_7", entry.JournalEntryID)
	if err != nil {
		t.Fatalf("get journal entry: %v", err)
	}

	if got.JournalEntryID != entry.JournalEntryID {
		t.Fatalf("expected journal_entry_id %s, got %s", entry.JournalEntryID, got.JournalEntryID)
	}

	list, err := repo.ListJournalEntries(ctx, "tenant_7", ListJournalEntriesFilter{
		SourceModule:       JournalSourceManual,
		SourceDocumentType: "integration_test",
		Status:             JournalStatusPosted,
		Query:              unique,
		Limit:              10,
	})
	if err != nil {
		t.Fatalf("list journal entries: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 journal entry in list, got %d", len(list))
	}

	lines, err := repo.ListJournalLines(ctx, "tenant_7", entry.JournalEntryID)
	if err != nil {
		t.Fatalf("list journal lines: %v", err)
	}

	if len(lines) != 2 {
		t.Fatalf("expected 2 journal lines, got %d", len(lines))
	}

	_, err = repo.GetJournalEntryByID(ctx, "tenant_99", entry.JournalEntryID)
	if !errors.Is(err, ErrJournalEntryNotFound) {
		t.Fatalf("expected ErrJournalEntryNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresJournalRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresJournalRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresJournalRepository(pool)

	_, err = repo.CreateJournalEntry(ctx, CreateJournalEntryInput{
		TenantID:     "tenant_7",
		ExchangeRate: 1,
	})

	if !errors.Is(err, ErrJournalNoRequired) {
		t.Fatalf("expected ErrJournalNoRequired, got %v", err)
	}
}

func cleanupJournalRepositoryFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, journalEntryID string) {
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

	if journalEntryID != "" {
		if _, err := tx.Exec(ctx, `
UPDATE erp_journal_entries
SET
    reversal_journal_entry_id = NULL,
    reversed_at = NULL,
    reversed_by = NULL,
    updated_at = now()
WHERE tenant_id = $1
  AND reversal_journal_entry_id = $2;
`, tenantID, journalEntryID); err != nil {
			t.Logf("cleanup reversal reference reset failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_journal_lines WHERE journal_entry_id = $1;", journalEntryID); err != nil {
			t.Logf("cleanup journal lines failed: %v", err)
			return
		}

		if _, err := tx.Exec(ctx, "DELETE FROM erp_journal_entries WHERE journal_entry_id = $1;", journalEntryID); err != nil {
			t.Logf("cleanup journal entry failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
