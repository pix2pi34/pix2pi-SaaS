package journal

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ JournalRepository = (*PostgresJournalRepository)(nil)

type PostgresJournalRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresJournalRepository(pool *pgxpool.Pool) *PostgresJournalRepository {
	return &PostgresJournalRepository{pool: pool}
}

func (r *PostgresJournalRepository) CreateJournalEntry(ctx context.Context, input CreateJournalEntryInput) (JournalEntry, error) {
	if err := ValidateCreateJournalEntryInput(input); err != nil {
		return JournalEntry{}, err
	}

	journalDate := input.JournalDate
	if journalDate.IsZero() {
		journalDate = time.Now().UTC()
	}

	currencyCode := strings.ToUpper(strings.TrimSpace(input.CurrencyCode))
	if currencyCode == "" {
		currencyCode = "TRY"
	}

	exchangeRate := input.ExchangeRate
	if exchangeRate <= 0 {
		exchangeRate = 1
	}

	sourceModule := input.SourceModule
	if strings.TrimSpace(string(sourceModule)) == "" {
		sourceModule = JournalSourceManual
	}

	status := input.Status
	if strings.TrimSpace(string(status)) == "" {
		status = JournalStatusDraft
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return JournalEntry{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_journal_entries (
    tenant_id,
    journal_no,
    journal_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    source_module,
    source_document_type,
    source_document_id,
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
    $3,
    $4,
    NULLIF($5, 0),
    NULLIF($6, ''),
    $7,
    NULLIF($8, ''),
    $9,
    $10,
    $11,
    NULLIF($12, ''),
    $13,
    $14,
    $15,
    NULLIF($16, '')
)
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
`,
		input.TenantID,
		strings.TrimSpace(input.JournalNo),
		journalDate,
		input.PostingDate,
		input.FiscalYear,
		input.FiscalPeriod,
		string(sourceModule),
		input.SourceDocumentType,
		journalNilIfEmpty(input.SourceDocumentID),
		currencyCode,
		exchangeRate,
		input.Description,
		input.TotalDebit,
		input.TotalCredit,
		string(status),
		input.CreatedBy,
	)

	entry, err := scanJournalEntry(row)
	if err != nil {
		return JournalEntry{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return JournalEntry{}, err
	}

	return entry, nil
}

func (r *PostgresJournalRepository) CreateJournalLine(ctx context.Context, input CreateJournalLineInput) (JournalLine, error) {
	if err := ValidateCreateJournalLineInput(input); err != nil {
		return JournalLine{}, err
	}

	currencyCode := strings.ToUpper(strings.TrimSpace(input.CurrencyCode))
	if currencyCode == "" {
		currencyCode = "TRY"
	}

	exchangeRate := input.ExchangeRate
	if exchangeRate <= 0 {
		exchangeRate = 1
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return JournalLine{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
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
    party_id,
    customer_id,
    vendor_id,
    item_id,
    cost_center_code,
    project_code,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    $4,
    NULLIF($5, ''),
    NULLIF($6, ''),
    $7,
    $8,
    $9,
    $10,
    $11,
    $12,
    $13,
    $14,
    $15,
    $16,
    NULLIF($17, ''),
    NULLIF($18, ''),
    'active',
    NULLIF($19, '')
)
RETURNING
    journal_line_id::text,
    tenant_id,
    journal_entry_id::text,
    line_no,
    account_code,
    COALESCE(account_name, ''),
    COALESCE(description, ''),
    debit_amount::float8,
    credit_amount::float8,
    currency_code,
    exchange_rate::float8,
    local_debit_amount::float8,
    local_credit_amount::float8,
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    COALESCE(item_id::text, ''),
    COALESCE(cost_center_code, ''),
    COALESCE(project_code, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.JournalEntryID,
		input.LineNo,
		strings.TrimSpace(input.AccountCode),
		input.AccountName,
		input.Description,
		input.DebitAmount,
		input.CreditAmount,
		currencyCode,
		exchangeRate,
		input.LocalDebitAmount,
		input.LocalCreditAmount,
		journalNilIfEmpty(input.PartyID),
		journalNilIfEmpty(input.CustomerID),
		journalNilIfEmpty(input.VendorID),
		journalNilIfEmpty(input.ItemID),
		input.CostCenterCode,
		input.ProjectCode,
		input.CreatedBy,
	)

	line, err := scanJournalLine(row)
	if err != nil {
		return JournalLine{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return JournalLine{}, err
	}

	return line, nil
}

func (r *PostgresJournalRepository) GetJournalEntryByID(ctx context.Context, tenantID string, journalEntryID string) (JournalEntry, error) {
	if strings.TrimSpace(tenantID) == "" {
		return JournalEntry{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return JournalEntry{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
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
    COALESCE(updated_by, '')
FROM erp_journal_entries
WHERE tenant_id = $1
  AND journal_entry_id = $2
  AND deleted_at IS NULL;
`, tenantID, journalEntryID)

	entry, err := scanJournalEntry(row)
	if err != nil {
		return JournalEntry{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return JournalEntry{}, err
	}

	return entry, nil
}

func (r *PostgresJournalRepository) ListJournalEntries(ctx context.Context, tenantID string, filter ListJournalEntriesFilter) ([]JournalEntry, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrTenantRequired
	}

	limit := filter.Limit
	if limit <= 0 || limit > 200 {
		limit = 50
	}

	offset := filter.Offset
	if offset < 0 {
		offset = 0
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
SELECT
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
    COALESCE(updated_by, '')
FROM erp_journal_entries
WHERE tenant_id = $1
  AND ($2::text = '' OR source_module = $2)
  AND ($3::text = '' OR source_document_type = $3)
  AND ($4::uuid IS NULL OR source_document_id = $4::uuid)
  AND ($5::text = '' OR status = $5)
  AND ($6::text = '' OR (
      journal_no ILIKE '%' || $6 || '%'
      OR COALESCE(description, '') ILIKE '%' || $6 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY journal_date DESC, journal_no DESC
LIMIT $7 OFFSET $8;
`,
		tenantID,
		string(filter.SourceModule),
		strings.TrimSpace(filter.SourceDocumentType),
		journalNilIfEmpty(filter.SourceDocumentID),
		string(filter.Status),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	entries := make([]JournalEntry, 0)

	for rows.Next() {
		entry, err := scanJournalEntry(rows)
		if err != nil {
			return nil, err
		}

		entries = append(entries, entry)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return entries, nil
}

func (r *PostgresJournalRepository) ListJournalLines(ctx context.Context, tenantID string, journalEntryID string) ([]JournalLine, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrTenantRequired
	}

	if strings.TrimSpace(journalEntryID) == "" {
		return nil, ErrJournalEntryIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
SELECT
    journal_line_id::text,
    tenant_id,
    journal_entry_id::text,
    line_no,
    account_code,
    COALESCE(account_name, ''),
    COALESCE(description, ''),
    debit_amount::float8,
    credit_amount::float8,
    currency_code,
    exchange_rate::float8,
    local_debit_amount::float8,
    local_credit_amount::float8,
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    COALESCE(item_id::text, ''),
    COALESCE(cost_center_code, ''),
    COALESCE(project_code, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_journal_lines
WHERE tenant_id = $1
  AND journal_entry_id = $2
  AND deleted_at IS NULL
ORDER BY line_no ASC;
`, tenantID, journalEntryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lines := make([]JournalLine, 0)

	for rows.Next() {
		line, err := scanJournalLine(rows)
		if err != nil {
			return nil, err
		}

		lines = append(lines, line)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return lines, nil
}

func (r *PostgresJournalRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		_ = tx.Rollback(ctx)
		return nil, err
	}

	return tx, nil
}

type journalScanner interface {
	Scan(dest ...any) error
}

func scanJournalEntry(scanner journalScanner) (JournalEntry, error) {
	var entry JournalEntry
	var journalDate pgtype.Date
	var postingDate pgtype.Date
	var postedAt pgtype.Timestamptz
	var reversedAt pgtype.Timestamptz
	var sourceModule string
	var status string

	err := scanner.Scan(
		&entry.JournalEntryID,
		&entry.TenantID,
		&entry.JournalNo,
		&journalDate,
		&postingDate,
		&entry.FiscalYear,
		&entry.FiscalPeriod,
		&sourceModule,
		&entry.SourceDocumentType,
		&entry.SourceDocumentID,
		&entry.CurrencyCode,
		&entry.ExchangeRate,
		&entry.Description,
		&entry.TotalDebit,
		&entry.TotalCredit,
		&status,
		&postedAt,
		&entry.PostedBy,
		&reversedAt,
		&entry.ReversedBy,
		&entry.ReversalJournalEntryID,
		&entry.CreatedAt,
		&entry.UpdatedAt,
		&entry.CreatedBy,
		&entry.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return JournalEntry{}, ErrJournalEntryNotFound
	}

	if err != nil {
		return JournalEntry{}, err
	}

	if journalDate.Valid {
		entry.JournalDate = journalDate.Time
	}

	if postingDate.Valid {
		t := postingDate.Time
		entry.PostingDate = &t
	}

	if postedAt.Valid {
		t := postedAt.Time
		entry.PostedAt = &t
	}

	if reversedAt.Valid {
		t := reversedAt.Time
		entry.ReversedAt = &t
	}

	entry.SourceModule = JournalSourceModule(sourceModule)
	entry.Status = JournalStatus(status)

	return entry, nil
}

func scanJournalLine(scanner journalScanner) (JournalLine, error) {
	var line JournalLine
	var status string

	err := scanner.Scan(
		&line.JournalLineID,
		&line.TenantID,
		&line.JournalEntryID,
		&line.LineNo,
		&line.AccountCode,
		&line.AccountName,
		&line.Description,
		&line.DebitAmount,
		&line.CreditAmount,
		&line.CurrencyCode,
		&line.ExchangeRate,
		&line.LocalDebitAmount,
		&line.LocalCreditAmount,
		&line.PartyID,
		&line.CustomerID,
		&line.VendorID,
		&line.ItemID,
		&line.CostCenterCode,
		&line.ProjectCode,
		&status,
		&line.CreatedAt,
		&line.UpdatedAt,
		&line.CreatedBy,
		&line.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return JournalLine{}, ErrJournalLineNotFound
	}

	if err != nil {
		return JournalLine{}, err
	}

	line.Status = JournalLineStatus(status)

	return line, nil
}

func journalNilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}
