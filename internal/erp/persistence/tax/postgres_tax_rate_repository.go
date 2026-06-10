package tax

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ TaxRateRepository = (*PostgresTaxRateRepository)(nil)

type PostgresTaxRateRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresTaxRateRepository(pool *pgxpool.Pool) *PostgresTaxRateRepository {
	return &PostgresTaxRateRepository{pool: pool}
}

func (r *PostgresTaxRateRepository) CreateTaxRate(ctx context.Context, input CreateTaxRateInput) (TaxRate, error) {
	if err := ValidateCreateTaxRateInput(input); err != nil {
		return TaxRate{}, err
	}

	validFrom := input.ValidFrom
	if validFrom.IsZero() {
		validFrom = time.Now().UTC()
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return TaxRate{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_tax_rates (
    tenant_id,
    tax_code_id,
    tax_code,
    rate_percent,
    withholding_numerator,
    withholding_denominator,
    valid_from,
    valid_to,
    is_default,
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
    $5,
    $6,
    $7,
    $8,
    $9,
    $10,
    NULLIF($11, ''),
    'active',
    NULLIF($12, '')
)
RETURNING
    tax_rate_id::text,
    tenant_id,
    tax_code_id::text,
    tax_code,
    rate_percent::float8,
    COALESCE(withholding_numerator, -1),
    COALESCE(withholding_denominator, -1),
    valid_from,
    valid_to,
    is_default,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.TaxCodeID,
		strings.TrimSpace(input.TaxCode),
		input.RatePercent,
		input.WithholdingNumerator,
		input.WithholdingDenominator,
		validFrom,
		input.ValidTo,
		input.IsDefault,
		input.IsActive,
		input.Description,
		input.CreatedBy,
	)

	taxRate, err := scanTaxRate(row)
	if err != nil {
		return TaxRate{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return TaxRate{}, err
	}

	return taxRate, nil
}

func (r *PostgresTaxRateRepository) GetTaxRateByID(ctx context.Context, tenantID string, taxRateID string) (TaxRate, error) {
	if strings.TrimSpace(tenantID) == "" {
		return TaxRate{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return TaxRate{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    tax_rate_id::text,
    tenant_id,
    tax_code_id::text,
    tax_code,
    rate_percent::float8,
    COALESCE(withholding_numerator, -1),
    COALESCE(withholding_denominator, -1),
    valid_from,
    valid_to,
    is_default,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_tax_rates
WHERE tenant_id = $1
  AND tax_rate_id = $2
  AND deleted_at IS NULL;
`, tenantID, taxRateID)

	taxRate, err := scanTaxRate(row)
	if err != nil {
		return TaxRate{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return TaxRate{}, err
	}

	return taxRate, nil
}

func (r *PostgresTaxRateRepository) ListTaxRates(ctx context.Context, tenantID string, filter ListTaxRatesFilter) ([]TaxRate, error) {
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
    tax_rate_id::text,
    tenant_id,
    tax_code_id::text,
    tax_code,
    rate_percent::float8,
    COALESCE(withholding_numerator, -1),
    COALESCE(withholding_denominator, -1),
    valid_from,
    valid_to,
    is_default,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_tax_rates
WHERE tenant_id = $1
  AND ($2::text = '' OR tax_code = $2)
  AND ($3::boolean IS NULL OR is_default = $3)
  AND ($4::boolean IS NULL OR is_active = $4)
  AND ($5::text = '' OR (
      tax_code ILIKE '%' || $5 || '%'
      OR COALESCE(description, '') ILIKE '%' || $5 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY tax_code ASC, valid_from DESC, rate_percent ASC
LIMIT $6 OFFSET $7;
`,
		tenantID,
		strings.TrimSpace(filter.TaxCode),
		taxBoolPtrAny(filter.IsDefault),
		taxBoolPtrAny(filter.IsActive),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	rates := make([]TaxRate, 0)

	for rows.Next() {
		taxRate, err := scanTaxRate(rows)
		if err != nil {
			return nil, err
		}

		rates = append(rates, taxRate)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return rates, nil
}

func (r *PostgresTaxRateRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type taxRateScanner interface {
	Scan(dest ...any) error
}

func scanTaxRate(scanner taxRateScanner) (TaxRate, error) {
	var item TaxRate
	var numerator int
	var denominator int
	var validFrom pgtype.Date
	var validTo pgtype.Date
	var status string

	err := scanner.Scan(
		&item.TaxRateID,
		&item.TenantID,
		&item.TaxCodeID,
		&item.TaxCode,
		&item.RatePercent,
		&numerator,
		&denominator,
		&validFrom,
		&validTo,
		&item.IsDefault,
		&item.IsActive,
		&item.Description,
		&status,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.CreatedBy,
		&item.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return TaxRate{}, ErrTaxRateNotFound
	}

	if err != nil {
		return TaxRate{}, err
	}

	if numerator >= 0 {
		item.WithholdingNumerator = &numerator
	}

	if denominator >= 0 {
		item.WithholdingDenominator = &denominator
	}

	if validFrom.Valid {
		item.ValidFrom = validFrom.Time
	}

	if validTo.Valid {
		t := validTo.Time
		item.ValidTo = &t
	}

	item.Status = TaxStatus(status)

	return item, nil
}
