package journalpost

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresJournalPostStoreTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping journal post postgres store integration test")
	}

	return dsn
}

func TestPostgresJournalPostingStorePersistAndMarkPosted(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresJournalPostStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresJournalPostingStore(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	journalNo := "JRNL-RUNTIME-" + unique
	sourceID := "00000000-0000-0000-0000-" + unique[len(unique)-12:]

	cleanupRuntimeJournalPostFixture(t, pool, "tenant_7", journalNo)
	defer cleanupRuntimeJournalPostFixture(t, pool, "tenant_7", journalNo)

	req := validJournalPostingRequest()
	req.Tenant.TenantID = "tenant_7"
	req.Tenant.RequestID = "req-" + unique
	req.Source.SourceDocumentID = sourceID
	req.Source.SourceDocumentNo = "INV-" + unique
	req.JournalNo = journalNo
	req.Fiscal.FiscalYear = 2026
	req.Fiscal.FiscalPeriod = "2026-04"
	req.Fiscal.PostingDate = time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC)
	req.Description = "Runtime journal post integration " + unique

	draft, err := BuildJournalDraft(req)
	if err != nil {
		t.Fatalf("build draft: %v", err)
	}

	persistedDraft, err := store.PersistJournalDraft(ctx, draft)
	if err != nil {
		t.Fatalf("persist journal draft: %v", err)
	}

	if persistedDraft.Status != JournalStatusDraft {
		t.Fatalf("expected draft status, got %s", persistedDraft.Status)
	}

	entryCount := countRuntimeJournalEntries(t, pool, "tenant_7", journalNo)
	if entryCount != 1 {
		t.Fatalf("expected 1 journal entry, got %d", entryCount)
	}

	lineCount := countRuntimeJournalLines(t, pool, "tenant_7", journalNo)
	if lineCount != 3 {
		t.Fatalf("expected 3 journal lines, got %d", lineCount)
	}

	postedDraft, err := store.MarkJournalPosted(ctx, persistedDraft)
	if err != nil {
		t.Fatalf("mark journal posted: %v", err)
	}

	if postedDraft.Status != JournalStatusPosted {
		t.Fatalf("expected posted status, got %s", postedDraft.Status)
	}

	status := getRuntimeJournalStatus(t, pool, "tenant_7", journalNo)
	if status != string(JournalStatusPosted) {
		t.Fatalf("expected DB status posted, got %s", status)
	}
}

func TestPostgresJournalPostingStoreValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresJournalPostStoreTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	store := NewPostgresJournalPostingStore(pool)

	req := validJournalPostingRequest()
	req.Tenant.TenantID = ""

	draft := JournalDraft{
		TenantID:  req.Tenant.TenantID,
		JournalNo: req.JournalNo,
		Source:    req.Source,
		Fiscal:    req.Fiscal,
		Status:    JournalStatusDraft,
		Lines:     req.Lines,
	}

	_, err = store.PersistJournalDraft(ctx, draft)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func cleanupRuntimeJournalPostFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, journalNo string) {
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
DELETE FROM erp_journal_lines
WHERE tenant_id = $1
  AND journal_entry_id IN (
    SELECT journal_entry_id
    FROM erp_journal_entries
    WHERE tenant_id = $1
      AND journal_no = $2
  );
`, tenantID, journalNo); err != nil {
		t.Logf("cleanup journal lines failed: %v", err)
		return
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

func countRuntimeJournalEntries(t *testing.T, pool *pgxpool.Pool, tenantID string, journalNo string) int {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("count entries begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("count entries set tenant failed: %v", err)
	}

	var count int
	if err := tx.QueryRow(ctx, `
SELECT COUNT(*)
FROM erp_journal_entries
WHERE tenant_id = $1
  AND journal_no = $2;
`, tenantID, journalNo).Scan(&count); err != nil {
		t.Fatalf("count entries query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("count entries commit failed: %v", err)
	}

	return count
}

func countRuntimeJournalLines(t *testing.T, pool *pgxpool.Pool, tenantID string, journalNo string) int {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("count lines begin failed: %v", err)
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Fatalf("count lines set tenant failed: %v", err)
	}

	var count int
	if err := tx.QueryRow(ctx, `
SELECT COUNT(*)
FROM erp_journal_lines jl
JOIN erp_journal_entries je ON je.journal_entry_id = jl.journal_entry_id
WHERE jl.tenant_id = $1
  AND je.tenant_id = $1
  AND je.journal_no = $2;
`, tenantID, journalNo).Scan(&count); err != nil {
		t.Fatalf("count lines query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("count lines commit failed: %v", err)
	}

	return count
}

func getRuntimeJournalStatus(t *testing.T, pool *pgxpool.Pool, tenantID string, journalNo string) string {
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

	var status string
	if err := tx.QueryRow(ctx, `
SELECT status
FROM erp_journal_entries
WHERE tenant_id = $1
  AND journal_no = $2;
`, tenantID, journalNo).Scan(&status); err != nil {
		t.Fatalf("status query failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("status commit failed: %v", err)
	}

	return status
}
