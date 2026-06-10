package cashbank

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ BankAccountRepository = (*PostgresBankAccountRepository)(nil)

type PostgresBankAccountRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresBankAccountRepository(pool *pgxpool.Pool) *PostgresBankAccountRepository {
	return &PostgresBankAccountRepository{pool: pool}
}

func (r *PostgresBankAccountRepository) CreateBankAccount(ctx context.Context, input CreateBankAccountInput) (BankAccount, error) {
	if err := ValidateCreateBankAccountInput(input); err != nil {
		return BankAccount{}, err
	}

	currencyCode := strings.ToUpper(strings.TrimSpace(input.CurrencyCode))
	if currencyCode == "" {
		currencyCode = "TRY"
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return BankAccount{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_bank_accounts (
    tenant_id,
    bank_code,
    bank_name,
    branch_code,
    branch_name,
    iban,
    account_no,
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
    NULLIF($6, ''),
    NULLIF($7, ''),
    NULLIF($8, ''),
    NULLIF($9, ''),
    $10,
    $11,
    $12,
    $13,
    NULLIF($14, ''),
    'active',
    NULLIF($15, '')
)
RETURNING
    bank_account_id::text,
    tenant_id,
    bank_code,
    bank_name,
    COALESCE(branch_code, ''),
    COALESCE(branch_name, ''),
    COALESCE(iban, ''),
    COALESCE(account_no, ''),
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
		strings.TrimSpace(input.BankCode),
		strings.TrimSpace(input.BankName),
		input.BranchCode,
		input.BranchName,
		input.IBAN,
		input.AccountNo,
		input.AccountCode,
		input.AccountName,
		currencyCode,
		input.OpeningBalance,
		input.CurrentBalance,
		input.IsActive,
		input.Description,
		input.CreatedBy,
	)

	account, err := scanBankAccount(row)
	if err != nil {
		return BankAccount{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return BankAccount{}, err
	}

	return account, nil
}

func (r *PostgresBankAccountRepository) GetBankAccountByID(ctx context.Context, tenantID string, bankAccountID string) (BankAccount, error) {
	if strings.TrimSpace(tenantID) == "" {
		return BankAccount{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return BankAccount{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    bank_account_id::text,
    tenant_id,
    bank_code,
    bank_name,
    COALESCE(branch_code, ''),
    COALESCE(branch_name, ''),
    COALESCE(iban, ''),
    COALESCE(account_no, ''),
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
FROM erp_bank_accounts
WHERE tenant_id = $1
  AND bank_account_id = $2
  AND deleted_at IS NULL;
`, tenantID, bankAccountID)

	account, err := scanBankAccount(row)
	if err != nil {
		return BankAccount{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return BankAccount{}, err
	}

	return account, nil
}

func (r *PostgresBankAccountRepository) GetBankAccountByCode(ctx context.Context, tenantID string, bankCode string) (BankAccount, error) {
	if strings.TrimSpace(tenantID) == "" {
		return BankAccount{}, ErrTenantRequired
	}

	if strings.TrimSpace(bankCode) == "" {
		return BankAccount{}, ErrBankCodeRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return BankAccount{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    bank_account_id::text,
    tenant_id,
    bank_code,
    bank_name,
    COALESCE(branch_code, ''),
    COALESCE(branch_name, ''),
    COALESCE(iban, ''),
    COALESCE(account_no, ''),
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
FROM erp_bank_accounts
WHERE tenant_id = $1
  AND bank_code = $2
  AND deleted_at IS NULL;
`, tenantID, strings.TrimSpace(bankCode))

	account, err := scanBankAccount(row)
	if err != nil {
		return BankAccount{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return BankAccount{}, err
	}

	return account, nil
}

func (r *PostgresBankAccountRepository) ListBankAccounts(ctx context.Context, tenantID string, filter ListBankAccountsFilter) ([]BankAccount, error) {
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
    bank_account_id::text,
    tenant_id,
    bank_code,
    bank_name,
    COALESCE(branch_code, ''),
    COALESCE(branch_name, ''),
    COALESCE(iban, ''),
    COALESCE(account_no, ''),
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
FROM erp_bank_accounts
WHERE tenant_id = $1
  AND ($2::text = '' OR account_code = $2)
  AND ($3::text = '' OR currency_code = $3)
  AND ($4::boolean IS NULL OR is_active = $4)
  AND ($5::text = '' OR (
      bank_code ILIKE '%' || $5 || '%'
      OR bank_name ILIKE '%' || $5 || '%'
      OR COALESCE(branch_code, '') ILIKE '%' || $5 || '%'
      OR COALESCE(branch_name, '') ILIKE '%' || $5 || '%'
      OR COALESCE(iban, '') ILIKE '%' || $5 || '%'
      OR COALESCE(account_no, '') ILIKE '%' || $5 || '%'
      OR COALESCE(account_code, '') ILIKE '%' || $5 || '%'
      OR COALESCE(account_name, '') ILIKE '%' || $5 || '%'
      OR COALESCE(description, '') ILIKE '%' || $5 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY bank_code ASC
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

	accounts := make([]BankAccount, 0)

	for rows.Next() {
		account, err := scanBankAccount(rows)
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

func (r *PostgresBankAccountRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type bankAccountScanner interface {
	Scan(dest ...any) error
}

func scanBankAccount(scanner bankAccountScanner) (BankAccount, error) {
	var account BankAccount
	var status string

	err := scanner.Scan(
		&account.BankAccountID,
		&account.TenantID,
		&account.BankCode,
		&account.BankName,
		&account.BranchCode,
		&account.BranchName,
		&account.IBAN,
		&account.AccountNo,
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
		return BankAccount{}, ErrBankAccountNotFound
	}

	if err != nil {
		return BankAccount{}, err
	}

	account.Status = AccountStatus(status)

	return account, nil
}
