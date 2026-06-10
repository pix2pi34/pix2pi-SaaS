package ledger

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ LedgerBalanceRepository = (*PostgresLedgerBalanceRepository)(nil)

type PostgresLedgerBalanceRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresLedgerBalanceRepository(pool *pgxpool.Pool) *PostgresLedgerBalanceRepository {
	return &PostgresLedgerBalanceRepository{pool: pool}
}

func (r *PostgresLedgerBalanceRepository) CreateLedgerBalance(ctx context.Context, input CreateLedgerBalanceInput) (LedgerBalance, error) {
	if err := ValidateCreateLedgerBalanceInput(input); err != nil {
		return LedgerBalance{}, err
	}

	currencyCode := strings.ToUpper(strings.TrimSpace(input.CurrencyCode))
	if currencyCode == "" {
		currencyCode = "TRY"
	}

	balanceSide := input.BalanceSide
	if strings.TrimSpace(string(balanceSide)) == "" {
		balanceSide = LedgerBalanceSideZero
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return LedgerBalance{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_ledger_balances (
    tenant_id,
    fiscal_year,
    fiscal_period,
    account_code,
    account_name,
    currency_code,
    opening_debit_amount,
    opening_credit_amount,
    period_debit_amount,
    period_credit_amount,
    closing_debit_amount,
    closing_credit_amount,
    balance_side,
    balance_amount,
    party_id,
    customer_id,
    vendor_id,
    cost_center_code,
    project_code,
    status,
    calculated_at,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    $4,
    NULLIF($5, ''),
    $6,
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
    $17,
    NULLIF($18, ''),
    NULLIF($19, ''),
    'active',
    $20,
    NULLIF($21, '')
)
RETURNING
    ledger_balance_id::text,
    tenant_id,
    fiscal_year,
    fiscal_period,
    account_code,
    COALESCE(account_name, ''),
    currency_code,
    opening_debit_amount::float8,
    opening_credit_amount::float8,
    period_debit_amount::float8,
    period_credit_amount::float8,
    closing_debit_amount::float8,
    closing_credit_amount::float8,
    balance_side,
    balance_amount::float8,
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    COALESCE(cost_center_code, ''),
    COALESCE(project_code, ''),
    status,
    calculated_at,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.FiscalYear,
		strings.TrimSpace(input.FiscalPeriod),
		strings.TrimSpace(input.AccountCode),
		input.AccountName,
		currencyCode,
		input.OpeningDebitAmount,
		input.OpeningCreditAmount,
		input.PeriodDebitAmount,
		input.PeriodCreditAmount,
		input.ClosingDebitAmount,
		input.ClosingCreditAmount,
		string(balanceSide),
		input.BalanceAmount,
		ledgerNilIfEmpty(input.PartyID),
		ledgerNilIfEmpty(input.CustomerID),
		ledgerNilIfEmpty(input.VendorID),
		input.CostCenterCode,
		input.ProjectCode,
		input.CalculatedAt,
		input.CreatedBy,
	)

	balance, err := scanLedgerBalance(row)
	if err != nil {
		return LedgerBalance{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return LedgerBalance{}, err
	}

	return balance, nil
}

func (r *PostgresLedgerBalanceRepository) GetLedgerBalanceByID(ctx context.Context, tenantID string, ledgerBalanceID string) (LedgerBalance, error) {
	if strings.TrimSpace(tenantID) == "" {
		return LedgerBalance{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return LedgerBalance{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    ledger_balance_id::text,
    tenant_id,
    fiscal_year,
    fiscal_period,
    account_code,
    COALESCE(account_name, ''),
    currency_code,
    opening_debit_amount::float8,
    opening_credit_amount::float8,
    period_debit_amount::float8,
    period_credit_amount::float8,
    closing_debit_amount::float8,
    closing_credit_amount::float8,
    balance_side,
    balance_amount::float8,
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    COALESCE(cost_center_code, ''),
    COALESCE(project_code, ''),
    status,
    calculated_at,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_ledger_balances
WHERE tenant_id = $1
  AND ledger_balance_id = $2
  AND deleted_at IS NULL;
`, tenantID, ledgerBalanceID)

	balance, err := scanLedgerBalance(row)
	if err != nil {
		return LedgerBalance{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return LedgerBalance{}, err
	}

	return balance, nil
}

func (r *PostgresLedgerBalanceRepository) ListLedgerBalances(ctx context.Context, tenantID string, filter ListLedgerBalancesFilter) ([]LedgerBalance, error) {
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
    ledger_balance_id::text,
    tenant_id,
    fiscal_year,
    fiscal_period,
    account_code,
    COALESCE(account_name, ''),
    currency_code,
    opening_debit_amount::float8,
    opening_credit_amount::float8,
    period_debit_amount::float8,
    period_credit_amount::float8,
    closing_debit_amount::float8,
    closing_credit_amount::float8,
    balance_side,
    balance_amount::float8,
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    COALESCE(cost_center_code, ''),
    COALESCE(project_code, ''),
    status,
    calculated_at,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_ledger_balances
WHERE tenant_id = $1
  AND ($2::text = '' OR account_code = $2)
  AND ($3::int = 0 OR fiscal_year = $3)
  AND ($4::text = '' OR fiscal_period = $4)
  AND ($5::text = '' OR balance_side = $5)
  AND ($6::text = '' OR cost_center_code = $6)
  AND ($7::text = '' OR project_code = $7)
  AND ($8::text = '' OR (
      account_code ILIKE '%' || $8 || '%'
      OR COALESCE(account_name, '') ILIKE '%' || $8 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY fiscal_year DESC, fiscal_period DESC, account_code ASC
LIMIT $9 OFFSET $10;
`,
		tenantID,
		strings.TrimSpace(filter.AccountCode),
		filter.FiscalYear,
		strings.TrimSpace(filter.FiscalPeriod),
		string(filter.BalanceSide),
		strings.TrimSpace(filter.CostCenterCode),
		strings.TrimSpace(filter.ProjectCode),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	balances := make([]LedgerBalance, 0)

	for rows.Next() {
		balance, err := scanLedgerBalance(rows)
		if err != nil {
			return nil, err
		}

		balances = append(balances, balance)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return balances, nil
}

func (r *PostgresLedgerBalanceRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type ledgerBalanceScanner interface {
	Scan(dest ...any) error
}

func scanLedgerBalance(scanner ledgerBalanceScanner) (LedgerBalance, error) {
	var balance LedgerBalance
	var balanceSide string
	var status string
	var calculatedAt pgtype.Timestamptz

	err := scanner.Scan(
		&balance.LedgerBalanceID,
		&balance.TenantID,
		&balance.FiscalYear,
		&balance.FiscalPeriod,
		&balance.AccountCode,
		&balance.AccountName,
		&balance.CurrencyCode,
		&balance.OpeningDebitAmount,
		&balance.OpeningCreditAmount,
		&balance.PeriodDebitAmount,
		&balance.PeriodCreditAmount,
		&balance.ClosingDebitAmount,
		&balance.ClosingCreditAmount,
		&balanceSide,
		&balance.BalanceAmount,
		&balance.PartyID,
		&balance.CustomerID,
		&balance.VendorID,
		&balance.CostCenterCode,
		&balance.ProjectCode,
		&status,
		&calculatedAt,
		&balance.CreatedAt,
		&balance.UpdatedAt,
		&balance.CreatedBy,
		&balance.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return LedgerBalance{}, ErrLedgerBalanceNotFound
	}

	if err != nil {
		return LedgerBalance{}, err
	}

	if calculatedAt.Valid {
		t := calculatedAt.Time
		balance.CalculatedAt = &t
	}

	balance.BalanceSide = LedgerBalanceSide(balanceSide)
	balance.Status = LedgerBalanceStatus(status)

	return balance, nil
}
