package productcatalog

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ UnitRepository = (*PostgresUnitRepository)(nil)

type PostgresUnitRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresUnitRepository(pool *pgxpool.Pool) *PostgresUnitRepository {
	return &PostgresUnitRepository{pool: pool}
}

func (r *PostgresUnitRepository) CreateUnit(ctx context.Context, input CreateUnitInput) (Unit, error) {
	if err := ValidateCreateUnitInput(input); err != nil {
		return Unit{}, err
	}

	unitType := input.UnitType
	if strings.TrimSpace(string(unitType)) == "" {
		unitType = UnitTypeQuantity
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return Unit{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_units (
    tenant_id,
    unit_code,
    unit_name,
    unit_type,
    decimal_precision,
    is_base_unit,
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
    'active',
    NULLIF($7, '')
)
RETURNING
    unit_id::text,
    tenant_id,
    unit_code,
    unit_name,
    unit_type,
    decimal_precision,
    is_base_unit,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.UnitCode),
		strings.TrimSpace(input.UnitName),
		string(unitType),
		input.DecimalPrecision,
		input.IsBaseUnit,
		input.CreatedBy,
	)

	unit, err := scanUnit(row)
	if err != nil {
		return Unit{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Unit{}, err
	}

	return unit, nil
}

func (r *PostgresUnitRepository) GetUnitByID(ctx context.Context, tenantID string, unitID string) (Unit, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Unit{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Unit{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    unit_id::text,
    tenant_id,
    unit_code,
    unit_name,
    unit_type,
    decimal_precision,
    is_base_unit,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_units
WHERE tenant_id = $1
  AND unit_id = $2
  AND deleted_at IS NULL;
`, tenantID, unitID)

	unit, err := scanUnit(row)
	if err != nil {
		return Unit{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Unit{}, err
	}

	return unit, nil
}

func (r *PostgresUnitRepository) ListUnits(ctx context.Context, tenantID string, filter ListUnitsFilter) ([]Unit, error) {
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
    unit_id::text,
    tenant_id,
    unit_code,
    unit_name,
    unit_type,
    decimal_precision,
    is_base_unit,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_units
WHERE tenant_id = $1
  AND ($2::text = '' OR (
      unit_code ILIKE '%' || $2 || '%'
      OR unit_name ILIKE '%' || $2 || '%'
  ))
  AND ($3::text = '' OR status = $3)
  AND deleted_at IS NULL
ORDER BY unit_code ASC
LIMIT $4 OFFSET $5;
`,
		tenantID,
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	units := make([]Unit, 0)

	for rows.Next() {
		unit, err := scanUnit(rows)
		if err != nil {
			return nil, err
		}

		units = append(units, unit)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return units, nil
}

func (r *PostgresUnitRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type unitScanner interface {
	Scan(dest ...any) error
}

func scanUnit(scanner unitScanner) (Unit, error) {
	var unit Unit
	var unitType string
	var status string

	err := scanner.Scan(
		&unit.UnitID,
		&unit.TenantID,
		&unit.UnitCode,
		&unit.UnitName,
		&unitType,
		&unit.DecimalPrecision,
		&unit.IsBaseUnit,
		&status,
		&unit.CreatedAt,
		&unit.UpdatedAt,
		&unit.CreatedBy,
		&unit.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return Unit{}, ErrUnitNotFound
	}

	if err != nil {
		return Unit{}, err
	}

	unit.UnitType = UnitType(unitType)
	unit.Status = CatalogStatus(status)

	return unit, nil
}
