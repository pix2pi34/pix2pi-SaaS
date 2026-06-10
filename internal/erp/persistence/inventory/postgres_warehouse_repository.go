package inventory

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ WarehouseRepository = (*PostgresWarehouseRepository)(nil)

type PostgresWarehouseRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresWarehouseRepository(pool *pgxpool.Pool) *PostgresWarehouseRepository {
	return &PostgresWarehouseRepository{pool: pool}
}

func (r *PostgresWarehouseRepository) CreateWarehouse(ctx context.Context, input CreateWarehouseInput) (Warehouse, error) {
	if err := ValidateCreateWarehouseInput(input); err != nil {
		return Warehouse{}, err
	}

	warehouseType := input.WarehouseType
	if strings.TrimSpace(string(warehouseType)) == "" {
		warehouseType = WarehouseTypeMain
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return Warehouse{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_warehouses (
    tenant_id,
    warehouse_code,
    warehouse_name,
    warehouse_type,
    city,
    district,
    address_line,
    is_default,
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
    NULLIF($7, ''),
    $8,
    'active',
    NULLIF($9, '')
)
RETURNING
    warehouse_id::text,
    tenant_id,
    warehouse_code,
    warehouse_name,
    warehouse_type,
    COALESCE(city, ''),
    COALESCE(district, ''),
    COALESCE(address_line, ''),
    is_default,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.WarehouseCode),
		strings.TrimSpace(input.WarehouseName),
		string(warehouseType),
		input.City,
		input.District,
		input.AddressLine,
		input.IsDefault,
		input.CreatedBy,
	)

	warehouse, err := scanWarehouse(row)
	if err != nil {
		return Warehouse{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Warehouse{}, err
	}

	return warehouse, nil
}

func (r *PostgresWarehouseRepository) GetWarehouseByID(ctx context.Context, tenantID string, warehouseID string) (Warehouse, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Warehouse{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Warehouse{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    warehouse_id::text,
    tenant_id,
    warehouse_code,
    warehouse_name,
    warehouse_type,
    COALESCE(city, ''),
    COALESCE(district, ''),
    COALESCE(address_line, ''),
    is_default,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_warehouses
WHERE tenant_id = $1
  AND warehouse_id = $2
  AND deleted_at IS NULL;
`, tenantID, warehouseID)

	warehouse, err := scanWarehouse(row)
	if err != nil {
		return Warehouse{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Warehouse{}, err
	}

	return warehouse, nil
}

func (r *PostgresWarehouseRepository) ListWarehouses(ctx context.Context, tenantID string, filter ListWarehousesFilter) ([]Warehouse, error) {
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
    warehouse_id::text,
    tenant_id,
    warehouse_code,
    warehouse_name,
    warehouse_type,
    COALESCE(city, ''),
    COALESCE(district, ''),
    COALESCE(address_line, ''),
    is_default,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_warehouses
WHERE tenant_id = $1
  AND ($2::text = '' OR (
      warehouse_code ILIKE '%' || $2 || '%'
      OR warehouse_name ILIKE '%' || $2 || '%'
      OR COALESCE(city, '') ILIKE '%' || $2 || '%'
      OR COALESCE(district, '') ILIKE '%' || $2 || '%'
  ))
  AND ($3::text = '' OR status = $3)
  AND deleted_at IS NULL
ORDER BY is_default DESC, warehouse_code ASC
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

	warehouses := make([]Warehouse, 0)

	for rows.Next() {
		warehouse, err := scanWarehouse(rows)
		if err != nil {
			return nil, err
		}

		warehouses = append(warehouses, warehouse)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return warehouses, nil
}

func (r *PostgresWarehouseRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type warehouseScanner interface {
	Scan(dest ...any) error
}

func scanWarehouse(scanner warehouseScanner) (Warehouse, error) {
	var warehouse Warehouse
	var warehouseType string
	var status string

	err := scanner.Scan(
		&warehouse.WarehouseID,
		&warehouse.TenantID,
		&warehouse.WarehouseCode,
		&warehouse.WarehouseName,
		&warehouseType,
		&warehouse.City,
		&warehouse.District,
		&warehouse.AddressLine,
		&warehouse.IsDefault,
		&status,
		&warehouse.CreatedAt,
		&warehouse.UpdatedAt,
		&warehouse.CreatedBy,
		&warehouse.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return Warehouse{}, ErrWarehouseNotFound
	}

	if err != nil {
		return Warehouse{}, err
	}

	warehouse.WarehouseType = WarehouseType(warehouseType)
	warehouse.Status = InventoryStatus(status)

	return warehouse, nil
}
