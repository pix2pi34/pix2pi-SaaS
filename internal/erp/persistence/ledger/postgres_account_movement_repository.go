package ledger

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ AccountMovementRepository = (*PostgresAccountMovementRepository)(nil)

type PostgresAccountMovementRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresAccountMovementRepository(pool *pgxpool.Pool) *PostgresAccountMovementRepository {
	return &PostgresAccountMovementRepository{pool: pool}
}

func (r *PostgresAccountMovementRepository) CreateAccountMovement(ctx context.Context, input CreateAccountMovementInput) (AccountMovement, error) {
	if err := ValidateCreateAccountMovementInput(input); err != nil {
		return AccountMovement{}, err
	}

	movementDate := input.MovementDate
	if movementDate.IsZero() {
		movementDate = time.Now().UTC()
	}

	postingDate := input.PostingDate
	if postingDate.IsZero() {
		postingDate = movementDate
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
		sourceModule = LedgerSourceManual
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return AccountMovement{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_account_movements (
    tenant_id,
    journal_entry_id,
    journal_line_id,
    movement_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    account_code,
    account_name,
    description,
    debit_amount,
    credit_amount,
    currency_code,
    exchange_rate,
    local_debit_amount,
    local_credit_amount,
    direction,
    source_module,
    source_document_type,
    source_document_id,
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
    $5,
    $6,
    $7,
    $8,
    NULLIF($9, ''),
    NULLIF($10, ''),
    $11,
    $12,
    $13,
    $14,
    $15,
    $16,
    $17,
    $18,
    NULLIF($19, ''),
    $20,
    $21,
    $22,
    $23,
    $24,
    NULLIF($25, ''),
    NULLIF($26, ''),
    'posted',
    NULLIF($27, '')
)
RETURNING
    account_movement_id::text,
    tenant_id,
    journal_entry_id::text,
    journal_line_id::text,
    movement_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    account_code,
    COALESCE(account_name, ''),
    COALESCE(description, ''),
    debit_amount::float8,
    credit_amount::float8,
    currency_code,
    exchange_rate::float8,
    local_debit_amount::float8,
    local_credit_amount::float8,
    direction,
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
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
		input.JournalLineID,
		movementDate,
		postingDate,
		input.FiscalYear,
		strings.TrimSpace(input.FiscalPeriod),
		strings.TrimSpace(input.AccountCode),
		input.AccountName,
		input.Description,
		input.DebitAmount,
		input.CreditAmount,
		currencyCode,
		exchangeRate,
		input.LocalDebitAmount,
		input.LocalCreditAmount,
		string(input.Direction),
		string(sourceModule),
		input.SourceDocumentType,
		ledgerNilIfEmpty(input.SourceDocumentID),
		ledgerNilIfEmpty(input.PartyID),
		ledgerNilIfEmpty(input.CustomerID),
		ledgerNilIfEmpty(input.VendorID),
		ledgerNilIfEmpty(input.ItemID),
		input.CostCenterCode,
		input.ProjectCode,
		input.CreatedBy,
	)

	movement, err := scanAccountMovement(row)
	if err != nil {
		return AccountMovement{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return AccountMovement{}, err
	}

	return movement, nil
}

func (r *PostgresAccountMovementRepository) GetAccountMovementByID(ctx context.Context, tenantID string, accountMovementID string) (AccountMovement, error) {
	if strings.TrimSpace(tenantID) == "" {
		return AccountMovement{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return AccountMovement{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    account_movement_id::text,
    tenant_id,
    journal_entry_id::text,
    journal_line_id::text,
    movement_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    account_code,
    COALESCE(account_name, ''),
    COALESCE(description, ''),
    debit_amount::float8,
    credit_amount::float8,
    currency_code,
    exchange_rate::float8,
    local_debit_amount::float8,
    local_credit_amount::float8,
    direction,
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
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
FROM erp_account_movements
WHERE tenant_id = $1
  AND account_movement_id = $2
  AND deleted_at IS NULL;
`, tenantID, accountMovementID)

	movement, err := scanAccountMovement(row)
	if err != nil {
		return AccountMovement{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return AccountMovement{}, err
	}

	return movement, nil
}

func (r *PostgresAccountMovementRepository) ListAccountMovements(ctx context.Context, tenantID string, filter ListAccountMovementsFilter) ([]AccountMovement, error) {
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
    account_movement_id::text,
    tenant_id,
    journal_entry_id::text,
    journal_line_id::text,
    movement_date,
    posting_date,
    fiscal_year,
    fiscal_period,
    account_code,
    COALESCE(account_name, ''),
    COALESCE(description, ''),
    debit_amount::float8,
    credit_amount::float8,
    currency_code,
    exchange_rate::float8,
    local_debit_amount::float8,
    local_credit_amount::float8,
    direction,
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
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
FROM erp_account_movements
WHERE tenant_id = $1
  AND ($2::text = '' OR account_code = $2)
  AND ($3::int = 0 OR fiscal_year = $3)
  AND ($4::text = '' OR fiscal_period = $4)
  AND ($5::text = '' OR source_module = $5)
  AND ($6::text = '' OR source_document_type = $6)
  AND ($7::uuid IS NULL OR source_document_id = $7::uuid)
  AND ($8::text = '' OR direction = $8)
  AND ($9::text = '' OR (
      account_code ILIKE '%' || $9 || '%'
      OR COALESCE(account_name, '') ILIKE '%' || $9 || '%'
      OR COALESCE(description, '') ILIKE '%' || $9 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY posting_date DESC, account_code ASC, created_at DESC
LIMIT $10 OFFSET $11;
`,
		tenantID,
		strings.TrimSpace(filter.AccountCode),
		filter.FiscalYear,
		strings.TrimSpace(filter.FiscalPeriod),
		string(filter.SourceModule),
		strings.TrimSpace(filter.SourceDocumentType),
		ledgerNilIfEmpty(filter.SourceDocumentID),
		string(filter.Direction),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	movements := make([]AccountMovement, 0)

	for rows.Next() {
		movement, err := scanAccountMovement(rows)
		if err != nil {
			return nil, err
		}

		movements = append(movements, movement)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return movements, nil
}

func (r *PostgresAccountMovementRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type accountMovementScanner interface {
	Scan(dest ...any) error
}

func scanAccountMovement(scanner accountMovementScanner) (AccountMovement, error) {
	var movement AccountMovement
	var movementDate pgtype.Date
	var postingDate pgtype.Date
	var direction string
	var sourceModule string
	var status string

	err := scanner.Scan(
		&movement.AccountMovementID,
		&movement.TenantID,
		&movement.JournalEntryID,
		&movement.JournalLineID,
		&movementDate,
		&postingDate,
		&movement.FiscalYear,
		&movement.FiscalPeriod,
		&movement.AccountCode,
		&movement.AccountName,
		&movement.Description,
		&movement.DebitAmount,
		&movement.CreditAmount,
		&movement.CurrencyCode,
		&movement.ExchangeRate,
		&movement.LocalDebitAmount,
		&movement.LocalCreditAmount,
		&direction,
		&sourceModule,
		&movement.SourceDocumentType,
		&movement.SourceDocumentID,
		&movement.PartyID,
		&movement.CustomerID,
		&movement.VendorID,
		&movement.ItemID,
		&movement.CostCenterCode,
		&movement.ProjectCode,
		&status,
		&movement.CreatedAt,
		&movement.UpdatedAt,
		&movement.CreatedBy,
		&movement.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return AccountMovement{}, ErrLedgerMovementNotFound
	}

	if err != nil {
		return AccountMovement{}, err
	}

	if movementDate.Valid {
		movement.MovementDate = movementDate.Time
	}

	if postingDate.Valid {
		movement.PostingDate = postingDate.Time
	}

	movement.Direction = MovementDirection(direction)
	movement.SourceModule = LedgerSourceModule(sourceModule)
	movement.Status = LedgerMovementStatus(status)

	return movement, nil
}

func ledgerNilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}
