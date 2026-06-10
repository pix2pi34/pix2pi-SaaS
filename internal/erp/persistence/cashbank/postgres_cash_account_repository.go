package cashbank

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ CashAccountRepository = (*PostgresCashAccountRepository)(nil)

type PostgresCashAccountRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresCashAccountRepository(pool *pgxpool.Pool) *PostgresCashAccountRepository {
	return &PostgresCashAccountRepository{pool: pool}
}

func (r *PostgresCashAccountRepository) CreateCashAccount(ctx context.Context, input CreateCashAccountInput) (CashAccount, error) {
	if err := ValidateCreateCashAccountInput(input); err != nil {
		return CashAccount{}, err
	}

	currencyCode := strings.ToUpper(strings.TrimSpace(input.CurrencyCode))
	if currencyCode == "" {
		currencyCode = "TRY"
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return CashAccount{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_cash_accounts (
    tenant_id,
    cash_code,
    cash_name,
    account_code,
    account_name,
    currency_code,
    opening_balance,
    current_balance,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    NULLIF($4, ''),
    NULLIF($5, ''),
    $6,
    $7,
    $8,
    $9,
    NULLIF($10, ''),
    'active',
    NULLIF($11, '')
)
RETURNING
    cash_account_id::text,
    tenant_id,
    cash_code,
    cash_name,
    COALESCE(account_code, ''),
    COALESCE(account_name, ''),
    currency_code,
    opening_balance::float8,
    current_balance::float8,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.CashCode),
		strings.TrimSpace(input.CashName),
		input.AccountCode,
		input.AccountName,
		currencyCode,
		input.OpeningBalance,
		input.CurrentBalance,
		input.IsActive,
		input.Description,
		input.CreatedBy,
	)

	account, err := scanCashAccount(row)
	if err != nil {
		return CashAccount{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return CashAccount{}, err
	}

	return account, nil
}

func (r *PostgresCashAccountRepository) GetCashAccountByID(ctx context.Context, tenantID string, cashAccountID string) (CashAccount, error) {
	if strings.TrimSpace(tenantID) == "" {
		return CashAccount{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return CashAccount{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    cash_account_id::text,
    tenant_id,
    cash_code,
    cash_name,
    COALESCE(account_code, ''),
    COALESCE(account_name, ''),
    currency_code,
    opening_balance::float8,
    current_balance::float8,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_cash_accounts
WHERE tenant_id = $1
  AND cash_account_id = $2
  AND deleted_at IS NULL;
`, tenantID, cashAccountID)

	account, err := scanCashAccount(row)
	if err != nil {
		return CashAccount{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return CashAccount{}, err
	}

	return account, nil
}

func (r *PostgresCashAccountRepository) GetCashAccountByCode(ctx context.Context, tenantID string, cashCode string) (CashAccount, error) {
	if strings.TrimSpace(tenantID) == "" {
		return CashAccount{}, ErrTenantRequired
	}

	if strings.TrimSpace(cashCode) == "" {
		return CashAccount{}, ErrCashCodeRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return CashAccount{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    cash_account_id::text,
    tenant_id,
    cash_code,
    cash_name,
    COALESCE(account_code, ''),
    COALESCE(account_name, ''),
    currency_code,
    opening_balance::float8,
    current_balance::float8,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_cash_accounts
WHERE tenant_id = $1
  AND cash_code = $2
  AND deleted_at IS NULL;
`, tenantID, strings.TrimSpace(cashCode))

	account, err := scanCashAccount(row)
	if err != nil {
		return CashAccount{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return CashAccount{}, err
	}

	return account, nil
}

func (r *PostgresCashAccountRepository) ListCashAccounts(ctx context.Context, tenantID string, filter ListCashAccountsFilter) ([]CashAccount, error) {
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
    cash_account_id::text,
    tenant_id,
    cash_code,
    cash_name,
    COALESCE(account_code, ''),
    COALESCE(account_name, ''),
    currency_code,
    opening_balance::float8,
    current_balance::float8,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_cash_accounts
WHERE tenant_id = $1
  AND ($2::text = '' OR account_code = $2)
  AND ($3::text = '' OR currency_code = $3)
  AND ($4::boolean IS NULL OR is_active = $4)
  AND ($5::text = '' OR (
      cash_code ILIKE '%' || $5 || '%'
      OR cash_name ILIKE '%' || $5 || '%'
      OR COALESCE(account_code, '') ILIKE '%' || $5 || '%'
      OR COALESCE(account_name, '') ILIKE '%' || $5 || '%'
      OR COALESCE(description, '') ILIKE '%' || $5 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY cash_code ASC
LIMIT $6 OFFSET $7;
`,
		tenantID,
		strings.TrimSpace(filter.AccountCode),
		strings.ToUpper(strings.TrimSpace(filter.CurrencyCode)),
		cashBankBoolPtrAny(filter.IsActive),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	accounts := make([]CashAccount, 0)

	for rows.Next() {
		account, err := scanCashAccount(rows)
		if err != nil {
			return nil, err
		}

		accounts = append(accounts, account)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return accounts, nil
}

func (r *PostgresCashAccountRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type cashAccountScanner interface {
	Scan(dest ...any) error
}

func scanCashAccount(scanner cashAccountScanner) (CashAccount, error) {
	var account CashAccount
	var status string

	err := scanner.Scan(
		&account.CashAccountID,
		&account.TenantID,
		&account.CashCode,
		&account.CashName,
		&account.AccountCode,
		&account.AccountName,
		&account.CurrencyCode,
		&account.OpeningBalance,
		&account.CurrentBalance,
		&account.IsActive,
		&account.Description,
		&status,
		&account.CreatedAt,
		&account.UpdatedAt,
		&account.CreatedBy,
		&account.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return CashAccount{}, ErrCashAccountNotFound
	}

	if err != nil {
		return CashAccount{}, err
	}

	account.Status = AccountStatus(status)

	return account, nil
}

func cashBankBoolPtrAny(value *bool) any {
	if value == nil {
		return nil
	}

	return *value
}

func cashBankNilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}
