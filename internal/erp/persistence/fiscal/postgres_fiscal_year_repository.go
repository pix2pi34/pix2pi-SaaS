package fiscal

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ FiscalYearRepository = (*PostgresFiscalYearRepository)(nil)

type PostgresFiscalYearRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresFiscalYearRepository(pool *pgxpool.Pool) *PostgresFiscalYearRepository {
	return &PostgresFiscalYearRepository{pool: pool}
}

func (r *PostgresFiscalYearRepository) CreateFiscalYear(ctx context.Context, input CreateFiscalYearInput) (FiscalYear, error) {
	if err := ValidateCreateFiscalYearInput(input); err != nil {
		return FiscalYear{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return FiscalYear{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_fiscal_years (
    tenant_id,
    fiscal_year,
    year_start_date,
    year_end_date,
    status,
    description,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    $4,
    'open',
    NULLIF($5, ''),
    NULLIF($6, '')
)
RETURNING
    fiscal_year_id::text,
    tenant_id,
    fiscal_year,
    year_start_date,
    year_end_date,
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
		input.YearStartDate,
		input.YearEndDate,
		input.Description,
		input.CreatedBy,
	)

	item, err := scanFiscalYear(row)
	if err != nil {
		return FiscalYear{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return FiscalYear{}, err
	}

	return item, nil
}

func (r *PostgresFiscalYearRepository) GetFiscalYearByID(ctx context.Context, tenantID string, fiscalYearID string) (FiscalYear, error) {
	if strings.TrimSpace(tenantID) == "" {
		return FiscalYear{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return FiscalYear{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, fiscalYearSelectSQL()+`
WHERE tenant_id = $1
  AND fiscal_year_id = $2
  AND deleted_at IS NULL;
`, tenantID, fiscalYearID)

	item, err := scanFiscalYear(row)
	if err != nil {
		return FiscalYear{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return FiscalYear{}, err
	}

	return item, nil
}

func (r *PostgresFiscalYearRepository) GetFiscalYearByYear(ctx context.Context, tenantID string, fiscalYear int) (FiscalYear, error) {
	if strings.TrimSpace(tenantID) == "" {
		return FiscalYear{}, ErrTenantRequired
	}

	if fiscalYear < 2000 || fiscalYear > 2100 {
		return FiscalYear{}, ErrFiscalYearInvalid
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return FiscalYear{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, fiscalYearSelectSQL()+`
WHERE tenant_id = $1
  AND fiscal_year = $2
  AND deleted_at IS NULL;
`, tenantID, fiscalYear)

	item, err := scanFiscalYear(row)
	if err != nil {
		return FiscalYear{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return FiscalYear{}, err
	}

	return item, nil
}

func (r *PostgresFiscalYearRepository) ListFiscalYears(ctx context.Context, tenantID string, filter ListFiscalYearsFilter) ([]FiscalYear, error) {
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

	rows, err := tx.Query(ctx, fiscalYearSelectSQL()+`
WHERE tenant_id = $1
  AND ($2::text = '' OR status = $2)
  AND ($3::text = '' OR (
      fiscal_year::text ILIKE '%' || $3 || '%'
      OR COALESCE(description, '') ILIKE '%' || $3 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY fiscal_year DESC
LIMIT $4 OFFSET $5;
`,
		tenantID,
		string(filter.Status),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]FiscalYear, 0)

	for rows.Next() {
		item, err := scanFiscalYear(rows)
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

func (r *PostgresFiscalYearRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

func fiscalYearSelectSQL() string {
	return `
SELECT
    fiscal_year_id::text,
    tenant_id,
    fiscal_year,
    year_start_date,
    year_end_date,
    status,
    closed_at,
    COALESCE(closed_by, ''),
    COALESCE(description, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_fiscal_years
`
}

type fiscalYearScanner interface {
	Scan(dest ...any) error
}

func scanFiscalYear(scanner fiscalYearScanner) (FiscalYear, error) {
	var item FiscalYear
	var yearStartDate pgtype.Date
	var yearEndDate pgtype.Date
	var closedAt pgtype.Timestamptz
	var status string

	err := scanner.Scan(
		&item.FiscalYearID,
		&item.TenantID,
		&item.FiscalYear,
		&yearStartDate,
		&yearEndDate,
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
		return FiscalYear{}, ErrFiscalYearNotFound
	}

	if err != nil {
		return FiscalYear{}, err
	}

	if yearStartDate.Valid {
		item.YearStartDate = yearStartDate.Time
	}

	if yearEndDate.Valid {
		item.YearEndDate = yearEndDate.Time
	}

	if closedAt.Valid {
		t := closedAt.Time
		item.ClosedAt = &t
	}

	item.Status = FiscalYearStatus(status)

	return item, nil
}

func fiscalIntPtrAny(value *int) any {
	if value == nil {
		return nil
	}
	return *value
}

func fiscalIntPtrKey(value *int) int {
	if value == nil {
		return 0
	}
	return *value
}

func fiscalNilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	return value
}

func fiscalYearDescription(unique string) string {
	return fmt.Sprintf("FAZ3 fiscal year repository test %s", unique)
}
