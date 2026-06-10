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

func postgresJournalPostingRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping journal posting repository integration test")
	}

	return dsn
}

func TestPostgresJournalPostingRepositoryStatusTransitions(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresJournalPostingRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresJournalRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	postableEntry, err := repo.CreateJournalEntry(ctx, CreateJournalEntryInput{
		TenantID:     "tenant_7",
		JournalNo:    "JRNL-POST-" + unique,
		JournalDate:  time.Now().UTC(),
		SourceModule: JournalSourceManual,
		CurrencyCode: "TRY",
		ExchangeRate: 1,
		Description:  "FAZ3 journal posting test " + unique,
		TotalDebit:   120,
		TotalCredit:  120,
		Status:       JournalStatusDraft,
		CreatedBy:    "faz3_test",
	})
	if err != nil {
		t.Fatalf("create postable journal entry: %v", err)
	}

	cancelEntry, err := repo.CreateJournalEntry(ctx, CreateJournalEntryInput{
		TenantID:     "tenant_7",
		JournalNo:    "JRNL-CANCEL-" + unique,
		JournalDate:  time.Now().UTC(),
		SourceModule: JournalSourceManual,
		CurrencyCode: "TRY",
		ExchangeRate: 1,
		Description:  "FAZ3 journal cancel test " + unique,
		TotalDebit:   0,
		TotalCredit:  0,
		Status:       JournalStatusDraft,
		CreatedBy:    "faz3_test",
	})
	if err != nil {
		cleanupJournalRepositoryFixture(t, pool, "tenant_7", postableEntry.JournalEntryID)
		t.Fatalf("create cancellable journal entry: %v", err)
	}

	reversalEntry, err := repo.CreateJournalEntry(ctx, CreateJournalEntryInput{
		TenantID:     "tenant_7",
		JournalNo:    "JRNL-REVERSAL-" + unique,
		JournalDate:  time.Now().UTC(),
		SourceModule: JournalSourceManual,
		CurrencyCode: "TRY",
		ExchangeRate: 1,
		Description:  "FAZ3 journal reversal test " + unique,
		TotalDebit:   120,
		TotalCredit:  120,
		Status:       JournalStatusDraft,
		CreatedBy:    "faz3_test",
	})
	if err != nil {
		cleanupJournalRepositoryFixture(t, pool, "tenant_7", postableEntry.JournalEntryID)
		cleanupJournalRepositoryFixture(t, pool, "tenant_7", cancelEntry.JournalEntryID)
		t.Fatalf("create reversal journal entry: %v", err)
	}

	defer cleanupJournalRepositoryFixture(t, pool, "tenant_7", postableEntry.JournalEntryID)
	defer cleanupJournalRepositoryFixture(t, pool, "tenant_7", cancelEntry.JournalEntryID)
	defer cleanupJournalRepositoryFixture(t, pool, "tenant_7", reversalEntry.JournalEntryID)

	posted, err := repo.MarkJournalPosted(ctx, "tenant_7", postableEntry.JournalEntryID, "faz3_test")
	if err != nil {
		t.Fatalf("mark journal posted: %v", err)
	}

	if posted.Status != JournalStatusPosted {
		t.Fatalf("expected posted status, got %s", posted.Status)
	}

	if posted.PostedAt == nil {
		t.Fatal("expected posted_at")
	}

	if posted.PostedBy != "faz3_test" {
		t.Fatalf("expected posted_by faz3_test, got %s", posted.PostedBy)
	}

	cancelled, err := repo.MarkJournalCancelled(ctx, "tenant_7", cancelEntry.JournalEntryID, "faz3_test")
	if err != nil {
		t.Fatalf("mark journal cancelled: %v", err)
	}

	if cancelled.Status != JournalStatusCancelled {
		t.Fatalf("expected cancelled status, got %s", cancelled.Status)
	}

	reversed, err := repo.MarkJournalReversed(ctx, "tenant_7", posted.JournalEntryID, reversalEntry.JournalEntryID, "faz3_test")
	if err != nil {
		t.Fatalf("mark journal reversed: %v", err)
	}

	if reversed.Status != JournalStatusReversed {
		t.Fatalf("expected reversed status, got %s", reversed.Status)
	}

	if reversed.ReversedAt == nil {
		t.Fatal("expected reversed_at")
	}

	if reversed.ReversalJournalEntryID != reversalEntry.JournalEntryID {
		t.Fatalf("expected reversal_journal_entry_id %s, got %s", reversalEntry.JournalEntryID, reversed.ReversalJournalEntryID)
	}

	_, err = repo.MarkJournalPosted(ctx, "tenant_99", postableEntry.JournalEntryID, "faz3_test")
	if !errors.Is(err, ErrJournalEntryNotFound) {
		t.Fatalf("expected ErrJournalEntryNotFound for cross-tenant posting, got %v", err)
	}
}

func TestPostgresJournalPostingRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresJournalPostingRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresJournalRepository(pool)

	_, err = repo.MarkJournalPosted(ctx, "", "journal-entry-id", "faz3_test")
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}

	_, err = repo.MarkJournalPosted(ctx, "tenant_7", "", "faz3_test")
	if !errors.Is(err, ErrJournalEntryIDRequired) {
		t.Fatalf("expected ErrJournalEntryIDRequired, got %v", err)
	}

	_, err = repo.MarkJournalReversed(ctx, "tenant_7", "journal-entry-id", "", "faz3_test")
	if !errors.Is(err, ErrJournalEntryIDRequired) {
		t.Fatalf("expected ErrJournalEntryIDRequired, got %v", err)
	}
}
