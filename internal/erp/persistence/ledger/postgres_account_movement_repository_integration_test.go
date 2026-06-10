package ledger

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresAccountMovementRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping account movement repository integration test")
	}

	return dsn
}

func TestPostgresAccountMovementRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresAccountMovementRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresAccountMovementRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())

	journalEntryID, debitLineID, creditLineID := createAccountMovementJournalFixture(t, pool, "tenant_7", unique)

	debitMovement, err := repo.CreateAccountMovement(ctx, CreateAccountMovementInput{
		TenantID:           "tenant_7",
		JournalEntryID:     journalEntryID,
		JournalLineID:      debitLineID,
		MovementDate:       time.Now().UTC(),
		PostingDate:        time.Now().UTC(),
		FiscalYear:         2026,
		FiscalPeriod:       "2026-04",
		AccountCode:        "120",
		AccountName:        "Alicilar",
		Description:        "FAZ3 account movement debit test " + unique,
		DebitAmount:        120,
		CreditAmount:       0,
		CurrencyCode:       "TRY",
		ExchangeRate:       1,
		LocalDebitAmount:   120,
		LocalCreditAmount:  0,
		Direction:          MovementDirectionDebit,
		SourceModule:       LedgerSourceManual,
		SourceDocumentType: "integration_test",
		CostCenterCode:     "CC-LEDGER",
		ProjectCode:        "PRJ-LEDGER",
		CreatedBy:          "faz3_test",
	})
	if err != nil {
		cleanupAccountMovementFixture(t, pool, "tenant_7", journalEntryID)
		t.Fatalf("create debit account movement: %v", err)
	}

	creditMovement, err := repo.CreateAccountMovement(ctx, CreateAccountMovementInput{
		TenantID:           "tenant_7",
		JournalEntryID:     journalEntryID,
		JournalLineID:      creditLineID,
		MovementDate:       time.Now().UTC(),
		PostingDate:        time.Now().UTC(),
		FiscalYear:         2026,
		FiscalPeriod:       "2026-04",
		AccountCode:        "600",
		AccountName:        "Yurt Ici Satislar",
		Description:        "FAZ3 account movement credit test " + unique,
		DebitAmount:        0,
		CreditAmount:       120,
		CurrencyCode:       "TRY",
		ExchangeRate:       1,
		LocalDebitAmount:   0,
		LocalCreditAmount:  120,
		Direction:          MovementDirectionCredit,
		SourceModule:       LedgerSourceManual,
		SourceDocumentType: "integration_test",
		CostCenterCode:     "CC-LEDGER",
		ProjectCode:        "PRJ-LEDGER",
		CreatedBy:          "faz3_test",
	})
	if err != nil {
		cleanupAccountMovementFixture(t, pool, "tenant_7", journalEntryID)
		t.Fatalf("create credit account movement: %v", err)
	}

	defer cleanupAccountMovementFixture(t, pool, "tenant_7", journalEntryID)

	if debitMovement.AccountMovementID == "" || creditMovement.AccountMovementID == "" {
		t.Fatal("expected account_movement_id values")
	}

	if debitMovement.Direction != MovementDirectionDebit {
		t.Fatalf("expected debit direction, got %s", debitMovement.Direction)
	}

	if creditMovement.Direction != MovementDirectionCredit {
		t.Fatalf("expected credit direction, got %s", creditMovement.Direction)
	}

	got, err := repo.GetAccountMovementByID(ctx, "tenant_7", debitMovement.AccountMovementID)
	if err != nil {
		t.Fatalf("get account movement: %v", err)
	}

	if got.AccountMovementID != debitMovement.AccountMovementID {
		t.Fatalf("expected account_movement_id %s, got %s", debitMovement.AccountMovementID, got.AccountMovementID)
	}

	list, err := repo.ListAccountMovements(ctx, "tenant_7", ListAccountMovementsFilter{
		AccountCode:        "120",
		FiscalYear:         2026,
		FiscalPeriod:       "2026-04",
		SourceModule:       LedgerSourceManual,
		SourceDocumentType: "integration_test",
		Direction:          MovementDirectionDebit,
		Query:              unique,
		Limit:              10,
	})
	if err != nil {
		t.Fatalf("list account movements: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 account movement in list, got %d", len(list))
	}

	_, err = repo.GetAccountMovementByID(ctx, "tenant_99", debitMovement.AccountMovementID)
	if !errors.Is(err, ErrLedgerMovementNotFound) {
		t.Fatalf("expected ErrLedgerMovementNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresAccountMovementRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresAccountMovementRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresAccountMovementRepository(pool)

	_, err = repo.CreateAccountMovement(ctx, CreateAccountMovementInput{
		TenantID:         "tenant_7",
		JournalLineID:    "journal-line-id",
		FiscalYear:       2026,
		FiscalPeriod:     "2026-04",
		AccountCode:      "120",
		DebitAmount:      120,
		ExchangeRate:     1,
		LocalDebitAmount: 120,
		Direction:        MovementDirectionDebit,
	})

	if !errors.Is(err, ErrJournalEntryIDRequired) {
		t.Fatalf("expected ErrJournalEntryIDRequired, got %v", err)
	}
}

func createAccountMovementJournalFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, unique string) (string, string, string) {
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

	var journalEntryID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_journal_entries (
    tenant_id,
    journal_no,
    journal_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    source_module,
    source_document_type,
    currency_code,
    exchange_rate,
    description,
    total_debit,
    total_credit,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    CURRENT_DATE,
    CURRENT_DATE,
    2026,
    '2026-04',
    'manual',
    'integration_test',
    'TRY',
    1,
    $3,
    120.00,
    120.00,
    'posted',
    'faz3_account_movement_test'
)
RETURNING journal_entry_id::text;
`, tenantID, "AM-JRNL-"+unique, "Account movement fixture "+unique).Scan(&journalEntryID); err != nil {
		t.Fatalf("fixture journal entry failed: %v", err)
	}

	var debitLineID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_journal_lines (
    tenant_id,
    journal_entry_id,
    line_no,
    account_code,
    account_name,
    description,
    debit_amount,
    credit_amount,
    currency_code,
    exchange_rate,
    local_debit_amount,
    local_credit_amount,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    1,
    '120',
    'Alicilar',
    $3,
    120.00,
    0.00,
    'TRY',
    1,
    120.00,
    0.00,
    'active',
    'faz3_account_movement_test'
)
RETURNING journal_line_id::text;
`, tenantID, journalEntryID, "Account movement debit fixture "+unique).Scan(&debitLineID); err != nil {
		t.Fatalf("fixture debit journal line failed: %v", err)
	}

	var creditLineID string
	if err := tx.QueryRow(ctx, `
INSERT INTO erp_journal_lines (
    tenant_id,
    journal_entry_id,
    line_no,
    account_code,
    account_name,
    description,
    debit_amount,
    credit_amount,
    currency_code,
    exchange_rate,
    local_debit_amount,
    local_credit_amount,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    2,
    '600',
    'Yurt Ici Satislar',
    $3,
    0.00,
    120.00,
    'TRY',
    1,
    0.00,
    120.00,
    'active',
    'faz3_account_movement_test'
)
RETURNING journal_line_id::text;
`, tenantID, journalEntryID, "Account movement credit fixture "+unique).Scan(&creditLineID); err != nil {
		t.Fatalf("fixture credit journal line failed: %v", err)
	}

	if err := tx.Commit(ctx); err != nil {
		t.Fatalf("fixture commit failed: %v", err)
	}

	return journalEntryID, debitLineID, creditLineID
}

func cleanupAccountMovementFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, journalEntryID string) {
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
		if _, err := tx.Exec(ctx, "DELETE FROM erp_account_movements WHERE journal_entry_id = $1;", journalEntryID); err != nil {
			t.Logf("cleanup account movements failed: %v", err)
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
