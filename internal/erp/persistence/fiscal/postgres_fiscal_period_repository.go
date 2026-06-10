package fiscal

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ FiscalPeriodRepository = (*PostgresFiscalPeriodRepository)(nil)

type PostgresFiscalPeriodRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresFiscalPeriodRepository(pool *pgxpool.Pool) *PostgresFiscalPeriodRepository {
	return &PostgresFiscalPeriodRepository{pool: pool}
}

func (r *PostgresFiscalPeriodRepository) CreateFiscalPeriod(ctx context.Context, input CreateFiscalPeriodInput) (FiscalPeriod, error) {
	if err := ValidateCreateFiscalPeriodInput(input); err != nil {
		return FiscalPeriod{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return FiscalPeriod{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_fiscal_periods (
    tenant_id,
    fiscal_year,
    fiscal_period,
    period_no,
    period_start_date,
    period_end_date,
    status,
    description,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    'open',
    NULLIF($7, ''),
    NULLIF($8, '')
)
RETURNING
    fiscal_period_id::text,
    tenant_id,
    fiscal_year,
    fiscal_period,
    period_no,
    period_start_date,
    period_end_date,
    status,
    closed_at,
    COALESCE(closed_by, ''),
    COALESCE(description, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.FiscalYear,
		strings.TrimSpace(input.FiscalPeriod),
		input.PeriodNo,
		input.PeriodStartDate,
		input.PeriodEndDate,
		input.Description,
		input.CreatedBy,
	)

	item, err := scanFiscalPeriod(row)
	if err != nil {
		return FiscalPeriod{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return FiscalPeriod{}, err
	}

	return item, nil
}

func (r *PostgresFiscalPeriodRepository) GetFiscalPeriodByID(ctx context.Context, tenantID string, fiscalPeriodID string) (FiscalPeriod, error) {
	if strings.TrimSpace(tenantID) == "" {
		return FiscalPeriod{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return FiscalPeriod{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, fiscalPeriodSelectSQL()+`
WHERE tenant_id = $1
  AND fiscal_period_id = $2
  AND deleted_at IS NULL;
`, tenantID, fiscalPeriodID)

	item, err := scanFiscalPeriod(row)
	if err != nil {
		return FiscalPeriod{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return FiscalPeriod{}, err
	}

	return item, nil
}

func (r *PostgresFiscalPeriodRepository) GetFiscalPeriodByCode(ctx context.Context, tenantID string, fiscalPeriod string) (FiscalPeriod, error) {
	if strings.TrimSpace(tenantID) == "" {
		return FiscalPeriod{}, ErrTenantRequired
	}

	if strings.TrimSpace(fiscalPeriod) == "" {
		return FiscalPeriod{}, ErrFiscalPeriodRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return FiscalPeriod{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, fiscalPeriodSelectSQL()+`
WHERE tenant_id = $1
  AND fiscal_period = $2
  AND deleted_at IS NULL;
`, tenantID, strings.TrimSpace(fiscalPeriod))

	item, err := scanFiscalPeriod(row)
	if err != nil {
		return FiscalPeriod{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return FiscalPeriod{}, err
	}

	return item, nil
}

func (r *PostgresFiscalPeriodRepository) ListFiscalPeriods(ctx context.Context, tenantID string, filter ListFiscalPeriodsFilter) ([]FiscalPeriod, error) {
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

	rows, err := tx.Query(ctx, fiscalPeriodSelectSQL()+`
WHERE tenant_id = $1
  AND ($2::int = 0 OR fiscal_year = $2)
  AND ($3::text = '' OR status = $3)
  AND ($4::text = '' OR (
      fiscal_period ILIKE '%' || $4 || '%'
      OR COALESCE(description, '') ILIKE '%' || $4 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY fiscal_year DESC, period_no ASC
LIMIT $5 OFFSET $6;
`,
		tenantID,
		filter.FiscalYear,
		string(filter.Status),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]FiscalPeriod, 0)

	for rows.Next() {
		item, err := scanFiscalPeriod(rows)
		if err != nil {
			return nil, err
		}

		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *PostgresFiscalPeriodRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

func fiscalPeriodSelectSQL() string {
	return `
SELECT
    fiscal_period_id::text,
    tenant_id,
    fiscal_year,
    fiscal_period,
    period_no,
    period_start_date,
    period_end_date,
    status,
    closed_at,
    COALESCE(closed_by, ''),
    COALESCE(description, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_fiscal_periods
`
}

type fiscalPeriodScanner interface {
	Scan(dest ...any) error
}

func scanFiscalPeriod(scanner fiscalPeriodScanner) (FiscalPeriod, error) {
	var item FiscalPeriod
	var periodStartDate pgtype.Date
	var periodEndDate pgtype.Date
	var closedAt pgtype.Timestamptz
	var status string

	err := scanner.Scan(
		&item.FiscalPeriodID,
		&item.TenantID,
		&item.FiscalYear,
		&item.FiscalPeriod,
		&item.PeriodNo,
		&periodStartDate,
		&periodEndDate,
		&status,
		&closedAt,
		&item.ClosedBy,
		&item.Description,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.CreatedBy,
		&item.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return FiscalPeriod{}, ErrFiscalPeriodNotFound
	}

	if err != nil {
		return FiscalPeriod{}, err
	}

	if periodStartDate.Valid {
		item.PeriodStartDate = periodStartDate.Time
	}

	if periodEndDate.Valid {
		item.PeriodEndDate = periodEndDate.Time
	}

	if closedAt.Valid {
		t := closedAt.Time
		item.ClosedAt = &t
	}

	item.Status = FiscalPeriodStatus(status)

	return item, nil
}
