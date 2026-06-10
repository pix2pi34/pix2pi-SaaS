package journal

import (
	"context"
	"strings"
)

var _ JournalPostingRepository = (*PostgresJournalRepository)(nil)

func (r *PostgresJournalRepository) MarkJournalPosted(ctx context.Context, tenantID string, journalEntryID string, postedBy string) (JournalEntry, error) {
	if strings.TrimSpace(tenantID) == "" {
		return JournalEntry{}, ErrTenantRequired
	}

	if strings.TrimSpace(journalEntryID) == "" {
		return JournalEntry{}, ErrJournalEntryIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return JournalEntry{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
UPDATE erp_journal_entries
SET
    status = 'posted',
    posted_at = now(),
    posted_by = NULLIF($3, ''),
    updated_at = now(),
    updated_by = NULLIF($3, '')
WHERE tenant_id = $1
  AND journal_entry_id = $2
  AND deleted_at IS NULL
RETURNING
    journal_entry_id::text,
    tenant_id,
    journal_no,
    journal_date,
    posting_date,
    COALESCE(fiscal_year, 0),
    COALESCE(fiscal_period, ''),
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
    currency_code,
    exchange_rate::float8,
    COALESCE(description, ''),
    total_debit::float8,
    total_credit::float8,
    status,
    posted_at,
    COALESCE(posted_by, ''),
    reversed_at,
    COALESCE(reversed_by, ''),
    COALESCE(reversal_journal_entry_id::text, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`, tenantID, journalEntryID, postedBy)

	entry, err := scanJournalEntry(row)
	if err != nil {
		return JournalEntry{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return JournalEntry{}, err
	}

	return entry, nil
}

func (r *PostgresJournalRepository) MarkJournalCancelled(ctx context.Context, tenantID string, journalEntryID string, updatedBy string) (JournalEntry, error) {
	if strings.TrimSpace(tenantID) == "" {
		return JournalEntry{}, ErrTenantRequired
	}

	if strings.TrimSpace(journalEntryID) == "" {
		return JournalEntry{}, ErrJournalEntryIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return JournalEntry{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
UPDATE erp_journal_entries
SET
    status = 'cancelled',
    updated_at = now(),
    updated_by = NULLIF($3, '')
WHERE tenant_id = $1
  AND journal_entry_id = $2
  AND deleted_at IS NULL
RETURNING
    journal_entry_id::text,
    tenant_id,
    journal_no,
    journal_date,
    posting_date,
    COALESCE(fiscal_year, 0),
    COALESCE(fiscal_period, ''),
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
    currency_code,
    exchange_rate::float8,
    COALESCE(description, ''),
    total_debit::float8,
    total_credit::float8,
    status,
    posted_at,
    COALESCE(posted_by, ''),
    reversed_at,
    COALESCE(reversed_by, ''),
    COALESCE(reversal_journal_entry_id::text, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`, tenantID, journalEntryID, updatedBy)

	entry, err := scanJournalEntry(row)
	if err != nil {
		return JournalEntry{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return JournalEntry{}, err
	}

	return entry, nil
}

func (r *PostgresJournalRepository) MarkJournalReversed(ctx context.Context, tenantID string, journalEntryID string, reversalJournalEntryID string, reversedBy string) (JournalEntry, error) {
	if strings.TrimSpace(tenantID) == "" {
		return JournalEntry{}, ErrTenantRequired
	}

	if strings.TrimSpace(journalEntryID) == "" {
		return JournalEntry{}, ErrJournalEntryIDRequired
	}

	if strings.TrimSpace(reversalJournalEntryID) == "" {
		return JournalEntry{}, ErrJournalEntryIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return JournalEntry{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
UPDATE erp_journal_entries
SET
    status = 'reversed',
    reversed_at = now(),
    reversed_by = NULLIF($4, ''),
    reversal_journal_entry_id = $3,
    updated_at = now(),
    updated_by = NULLIF($4, '')
WHERE tenant_id = $1
  AND journal_entry_id = $2
  AND deleted_at IS NULL
RETURNING
    journal_entry_id::text,
    tenant_id,
    journal_no,
    journal_date,
    posting_date,
    COALESCE(fiscal_year, 0),
    COALESCE(fiscal_period, ''),
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
    currency_code,
    exchange_rate::float8,
    COALESCE(description, ''),
    total_debit::float8,
    total_credit::float8,
    status,
    posted_at,
    COALESCE(posted_by, ''),
    reversed_at,
    COALESCE(reversed_by, ''),
    COALESCE(reversal_journal_entry_id::text, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`, tenantID, journalEntryID, reversalJournalEntryID, reversedBy)

	entry, err := scanJournalEntry(row)
	if err != nil {
		return JournalEntry{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return JournalEntry{}, err
	}

	return entry, nil
}
