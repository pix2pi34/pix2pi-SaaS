package chartofaccounts

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ ChartAccountRepository = (*PostgresChartAccountRepository)(nil)

type PostgresChartAccountRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresChartAccountRepository(pool *pgxpool.Pool) *PostgresChartAccountRepository {
	return &PostgresChartAccountRepository{pool: pool}
}

func (r *PostgresChartAccountRepository) CreateChartAccount(ctx context.Context, input CreateChartAccountInput) (ChartAccount, error) {
	if err := ValidateCreateChartAccountInput(input); err != nil {
		return ChartAccount{}, err
	}

	currencyCode := strings.ToUpper(strings.TrimSpace(input.CurrencyCode))
	if currencyCode == "" {
		currencyCode = "TRY"
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return ChartAccount{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_chart_accounts (
    tenant_id,
    account_code,
    account_name,
    parent_account_code,
    account_level,
    account_class,
    account_group,
    account_type,
    normal_balance,
    is_postable,
    is_active,
    currency_code,
    tax_code,
    vat_rate,
    description,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    NULLIF($4, ''),
    $5,
    NULLIF($6, ''),
    NULLIF($7, ''),
    $8,
    $9,
    $10,
    $11,
    $12,
    NULLIF($13, ''),
    $14,
    NULLIF($15, ''),
    'active',
    NULLIF($16, '')
)
RETURNING
    chart_account_id::text,
    tenant_id,
    account_code,
    account_name,
    COALESCE(parent_account_code, ''),
    account_level,
    COALESCE(account_class, ''),
    COALESCE(account_group, ''),
    account_type,
    normal_balance,
    is_postable,
    is_active,
    currency_code,
    COALESCE(tax_code, ''),
    COALESCE(vat_rate::float8, -1),
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.AccountCode),
		strings.TrimSpace(input.AccountName),
		input.ParentAccountCode,
		input.AccountLevel,
		input.AccountClass,
		input.AccountGroup,
		string(input.AccountType),
		string(input.NormalBalance),
		input.IsPostable,
		input.IsActive,
		currencyCode,
		input.TaxCode,
		input.VATRate,
		input.Description,
		input.CreatedBy,
	)

	account, err := scanChartAccount(row)
	if err != nil {
		return ChartAccount{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return ChartAccount{}, err
	}

	return account, nil
}

func (r *PostgresChartAccountRepository) GetChartAccountByID(ctx context.Context, tenantID string, chartAccountID string) (ChartAccount, error) {
	if strings.TrimSpace(tenantID) == "" {
		return ChartAccount{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return ChartAccount{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    chart_account_id::text,
    tenant_id,
    account_code,
    account_name,
    COALESCE(parent_account_code, ''),
    account_level,
    COALESCE(account_class, ''),
    COALESCE(account_group, ''),
    account_type,
    normal_balance,
    is_postable,
    is_active,
    currency_code,
    COALESCE(tax_code, ''),
    COALESCE(vat_rate::float8, -1),
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_chart_accounts
WHERE tenant_id = $1
  AND chart_account_id = $2
  AND deleted_at IS NULL;
`, tenantID, chartAccountID)

	account, err := scanChartAccount(row)
	if err != nil {
		return ChartAccount{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return ChartAccount{}, err
	}

	return account, nil
}

func (r *PostgresChartAccountRepository) GetChartAccountByCode(ctx context.Context, tenantID string, accountCode string) (ChartAccount, error) {
	if strings.TrimSpace(tenantID) == "" {
		return ChartAccount{}, ErrTenantRequired
	}

	if strings.TrimSpace(accountCode) == "" {
		return ChartAccount{}, ErrAccountCodeRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return ChartAccount{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    chart_account_id::text,
    tenant_id,
    account_code,
    account_name,
    COALESCE(parent_account_code, ''),
    account_level,
    COALESCE(account_class, ''),
    COALESCE(account_group, ''),
    account_type,
    normal_balance,
    is_postable,
    is_active,
    currency_code,
    COALESCE(tax_code, ''),
    COALESCE(vat_rate::float8, -1),
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_chart_accounts
WHERE tenant_id = $1
  AND account_code = $2
  AND deleted_at IS NULL;
`, tenantID, strings.TrimSpace(accountCode))

	account, err := scanChartAccount(row)
	if err != nil {
		return ChartAccount{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return ChartAccount{}, err
	}

	return account, nil
}

func (r *PostgresChartAccountRepository) ListChartAccounts(ctx context.Context, tenantID string, filter ListChartAccountsFilter) ([]ChartAccount, error) {
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
    chart_account_id::text,
    tenant_id,
    account_code,
    account_name,
    COALESCE(parent_account_code, ''),
    account_level,
    COALESCE(account_class, ''),
    COALESCE(account_group, ''),
    account_type,
    normal_balance,
    is_postable,
    is_active,
    currency_code,
    COALESCE(tax_code, ''),
    COALESCE(vat_rate::float8, -1),
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_chart_accounts
WHERE tenant_id = $1
  AND ($2::text = '' OR account_type = $2)
  AND ($3::text = '' OR normal_balance = $3)
  AND ($4::text = '' OR parent_account_code = $4)
  AND ($5::boolean IS NULL OR is_postable = $5)
  AND ($6::boolean IS NULL OR is_active = $6)
  AND ($7::text = '' OR (
      account_code ILIKE '%' || $7 || '%'
      OR account_name ILIKE '%' || $7 || '%'
      OR COALESCE(description, '') ILIKE '%' || $7 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY account_code ASC
LIMIT $8 OFFSET $9;
`,
		tenantID,
		string(filter.AccountType),
		string(filter.NormalBalance),
		strings.TrimSpace(filter.ParentAccountCode),
		boolPtrAny(filter.IsPostable),
		boolPtrAny(filter.IsActive),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	accounts := make([]ChartAccount, 0)

	for rows.Next() {
		account, err := scanChartAccount(rows)
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

func (r *PostgresChartAccountRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type chartAccountScanner interface {
	Scan(dest ...any) error
}

func scanChartAccount(scanner chartAccountScanner) (ChartAccount, error) {
	var account ChartAccount
	var accountType string
	var normalBalance string
	var status string
	var vatRate float64

	err := scanner.Scan(
		&account.ChartAccountID,
		&account.TenantID,
		&account.AccountCode,
		&account.AccountName,
		&account.ParentAccountCode,
		&account.AccountLevel,
		&account.AccountClass,
		&account.AccountGroup,
		&accountType,
		&normalBalance,
		&account.IsPostable,
		&account.IsActive,
		&account.CurrencyCode,
		&account.TaxCode,
		&vatRate,
		&account.Description,
		&status,
		&account.CreatedAt,
		&account.UpdatedAt,
		&account.CreatedBy,
		&account.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return ChartAccount{}, ErrChartAccountNotFound
	}

	if err != nil {
		return ChartAccount{}, err
	}

	if vatRate >= 0 {
		account.VATRate = &vatRate
	}

	account.AccountType = AccountType(accountType)
	account.NormalBalance = NormalBalance(normalBalance)
	account.Status = AccountStatus(status)

	return account, nil
}

func boolPtrAny(value *bool) any {
	if value == nil {
		return nil
	}

	return *value
}
