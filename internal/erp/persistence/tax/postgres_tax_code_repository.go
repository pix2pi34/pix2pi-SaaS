package tax

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ TaxCodeRepository = (*PostgresTaxCodeRepository)(nil)

type PostgresTaxCodeRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresTaxCodeRepository(pool *pgxpool.Pool) *PostgresTaxCodeRepository {
	return &PostgresTaxCodeRepository{pool: pool}
}

func (r *PostgresTaxCodeRepository) CreateTaxCode(ctx context.Context, input CreateTaxCodeInput) (TaxCode, error) {
	if err := ValidateCreateTaxCodeInput(input); err != nil {
		return TaxCode{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return TaxCode{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_tax_codes (
    tenant_id,
    tax_code,
    tax_name,
    tax_type,
    account_code,
    account_name,
    is_recoverable,
    is_payable,
    is_withholding,
    is_active,
    description,
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
    NULLIF($11, ''),
    'active',
    NULLIF($12, '')
)
RETURNING
    tax_code_id::text,
    tenant_id,
    tax_code,
    tax_name,
    tax_type,
    COALESCE(account_code, ''),
    COALESCE(account_name, ''),
    is_recoverable,
    is_payable,
    is_withholding,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.TaxCode),
		strings.TrimSpace(input.TaxName),
		string(input.TaxType),
		input.AccountCode,
		input.AccountName,
		input.IsRecoverable,
		input.IsPayable,
		input.IsWithholding,
		input.IsActive,
		input.Description,
		input.CreatedBy,
	)

	taxCode, err := scanTaxCode(row)
	if err != nil {
		return TaxCode{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return TaxCode{}, err
	}

	return taxCode, nil
}

func (r *PostgresTaxCodeRepository) GetTaxCodeByID(ctx context.Context, tenantID string, taxCodeID string) (TaxCode, error) {
	if strings.TrimSpace(tenantID) == "" {
		return TaxCode{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return TaxCode{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    tax_code_id::text,
    tenant_id,
    tax_code,
    tax_name,
    tax_type,
    COALESCE(account_code, ''),
    COALESCE(account_name, ''),
    is_recoverable,
    is_payable,
    is_withholding,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_tax_codes
WHERE tenant_id = $1
  AND tax_code_id = $2
  AND deleted_at IS NULL;
`, tenantID, taxCodeID)

	taxCode, err := scanTaxCode(row)
	if err != nil {
		return TaxCode{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return TaxCode{}, err
	}

	return taxCode, nil
}

func (r *PostgresTaxCodeRepository) GetTaxCodeByCode(ctx context.Context, tenantID string, taxCode string) (TaxCode, error) {
	if strings.TrimSpace(tenantID) == "" {
		return TaxCode{}, ErrTenantRequired
	}

	if strings.TrimSpace(taxCode) == "" {
		return TaxCode{}, ErrTaxCodeRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return TaxCode{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    tax_code_id::text,
    tenant_id,
    tax_code,
    tax_name,
    tax_type,
    COALESCE(account_code, ''),
    COALESCE(account_name, ''),
    is_recoverable,
    is_payable,
    is_withholding,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_tax_codes
WHERE tenant_id = $1
  AND tax_code = $2
  AND deleted_at IS NULL;
`, tenantID, strings.TrimSpace(taxCode))

	got, err := scanTaxCode(row)
	if err != nil {
		return TaxCode{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return TaxCode{}, err
	}

	return got, nil
}

func (r *PostgresTaxCodeRepository) ListTaxCodes(ctx context.Context, tenantID string, filter ListTaxCodesFilter) ([]TaxCode, error) {
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
    tax_code_id::text,
    tenant_id,
    tax_code,
    tax_name,
    tax_type,
    COALESCE(account_code, ''),
    COALESCE(account_name, ''),
    is_recoverable,
    is_payable,
    is_withholding,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_tax_codes
WHERE tenant_id = $1
  AND ($2::text = '' OR tax_type = $2)
  AND ($3::boolean IS NULL OR is_recoverable = $3)
  AND ($4::boolean IS NULL OR is_payable = $4)
  AND ($5::boolean IS NULL OR is_withholding = $5)
  AND ($6::boolean IS NULL OR is_active = $6)
  AND ($7::text = '' OR (
      tax_code ILIKE '%' || $7 || '%'
      OR tax_name ILIKE '%' || $7 || '%'
      OR COALESCE(account_code, '') ILIKE '%' || $7 || '%'
      OR COALESCE(account_name, '') ILIKE '%' || $7 || '%'
      OR COALESCE(description, '') ILIKE '%' || $7 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY tax_code ASC
LIMIT $8 OFFSET $9;
`,
		tenantID,
		string(filter.TaxType),
		taxBoolPtrAny(filter.IsRecoverable),
		taxBoolPtrAny(filter.IsPayable),
		taxBoolPtrAny(filter.IsWithholding),
		taxBoolPtrAny(filter.IsActive),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	codes := make([]TaxCode, 0)

	for rows.Next() {
		taxCode, err := scanTaxCode(rows)
		if err != nil {
			return nil, err
		}

		codes = append(codes, taxCode)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return codes, nil
}

func (r *PostgresTaxCodeRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type taxCodeScanner interface {
	Scan(dest ...any) error
}

func scanTaxCode(scanner taxCodeScanner) (TaxCode, error) {
	var item TaxCode
	var taxType string
	var status string

	err := scanner.Scan(
		&item.TaxCodeID,
		&item.TenantID,
		&item.TaxCode,
		&item.TaxName,
		&taxType,
		&item.AccountCode,
		&item.AccountName,
		&item.IsRecoverable,
		&item.IsPayable,
		&item.IsWithholding,
		&item.IsActive,
		&item.Description,
		&status,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.CreatedBy,
		&item.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return TaxCode{}, ErrTaxCodeNotFound
	}

	if err != nil {
		return TaxCode{}, err
	}

	item.TaxType = TaxType(taxType)
	item.Status = TaxStatus(status)

	return item, nil
}

func taxBoolPtrAny(value *bool) any {
	if value == nil {
		return nil
	}

	return *value
}
