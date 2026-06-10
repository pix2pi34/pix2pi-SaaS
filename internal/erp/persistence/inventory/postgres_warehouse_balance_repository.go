package inventory

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ WarehouseBalanceRepository = (*PostgresWarehouseBalanceRepository)(nil)

type PostgresWarehouseBalanceRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresWarehouseBalanceRepository(pool *pgxpool.Pool) *PostgresWarehouseBalanceRepository {
	return &PostgresWarehouseBalanceRepository{pool: pool}
}

func (r *PostgresWarehouseBalanceRepository) CreateWarehouseBalance(ctx context.Context, input CreateWarehouseBalanceInput) (WarehouseBalance, error) {
	if err := ValidateCreateWarehouseBalanceInput(input); err != nil {
		return WarehouseBalance{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return WarehouseBalance{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_warehouse_balances (
    tenant_id,
    warehouse_id,
    item_id,
    unit_id,
    on_hand_quantity,
    reserved_quantity,
    available_quantity,
    last_movement_at,
    last_stock_movement_id,
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
    'active',
    NULLIF($10, '')
)
RETURNING
    balance_id::text,
    tenant_id,
    warehouse_id::text,
    item_id::text,
    unit_id::text,
    on_hand_quantity::float8,
    reserved_quantity::float8,
    available_quantity::float8,
    last_movement_at,
    COALESCE(last_stock_movement_id::text, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.WarehouseID,
		input.ItemID,
		input.UnitID,
		input.OnHandQuantity,
		input.ReservedQuantity,
		input.AvailableQuantity,
		input.LastMovementAt,
		nilIfEmpty(input.LastStockMovementID),
		input.CreatedBy,
	)

	balance, err := scanWarehouseBalance(row)
	if err != nil {
		return WarehouseBalance{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return WarehouseBalance{}, err
	}

	return balance, nil
}

func (r *PostgresWarehouseBalanceRepository) GetWarehouseBalanceByID(ctx context.Context, tenantID string, balanceID string) (WarehouseBalance, error) {
	if strings.TrimSpace(tenantID) == "" {
		return WarehouseBalance{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return WarehouseBalance{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    balance_id::text,
    tenant_id,
    warehouse_id::text,
    item_id::text,
    unit_id::text,
    on_hand_quantity::float8,
    reserved_quantity::float8,
    available_quantity::float8,
    last_movement_at,
    COALESCE(last_stock_movement_id::text, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_warehouse_balances
WHERE tenant_id = $1
  AND balance_id = $2
  AND deleted_at IS NULL;
`, tenantID, balanceID)

	balance, err := scanWarehouseBalance(row)
	if err != nil {
		return WarehouseBalance{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return WarehouseBalance{}, err
	}

	return balance, nil
}

func (r *PostgresWarehouseBalanceRepository) GetWarehouseBalanceByWarehouseAndItem(ctx context.Context, tenantID string, warehouseID string, itemID string) (WarehouseBalance, error) {
	if strings.TrimSpace(tenantID) == "" {
		return WarehouseBalance{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return WarehouseBalance{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    balance_id::text,
    tenant_id,
    warehouse_id::text,
    item_id::text,
    unit_id::text,
    on_hand_quantity::float8,
    reserved_quantity::float8,
    available_quantity::float8,
    last_movement_at,
    COALESCE(last_stock_movement_id::text, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_warehouse_balances
WHERE tenant_id = $1
  AND warehouse_id = $2
  AND item_id = $3
  AND deleted_at IS NULL;
`, tenantID, warehouseID, itemID)

	balance, err := scanWarehouseBalance(row)
	if err != nil {
		return WarehouseBalance{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return WarehouseBalance{}, err
	}

	return balance, nil
}

func (r *PostgresWarehouseBalanceRepository) ListWarehouseBalances(ctx context.Context, tenantID string, filter ListWarehouseBalancesFilter) ([]WarehouseBalance, error) {
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
    b.balance_id::text,
    b.tenant_id,
    b.warehouse_id::text,
    b.item_id::text,
    b.unit_id::text,
    b.on_hand_quantity::float8,
    b.reserved_quantity::float8,
    b.available_quantity::float8,
    b.last_movement_at,
    COALESCE(b.last_stock_movement_id::text, ''),
    b.status,
    b.created_at,
    b.updated_at,
    COALESCE(b.created_by, ''),
    COALESCE(b.updated_by, '')
FROM erp_warehouse_balances b
JOIN erp_warehouses w ON w.warehouse_id = b.warehouse_id
JOIN erp_items i ON i.item_id = b.item_id
WHERE b.tenant_id = $1
  AND w.tenant_id = $1
  AND i.tenant_id = $1
  AND ($2::uuid IS NULL OR b.warehouse_id = $2::uuid)
  AND ($3::uuid IS NULL OR b.item_id = $3::uuid)
  AND ($4::text = '' OR (
      w.warehouse_code ILIKE '%' || $4 || '%'
      OR w.warehouse_name ILIKE '%' || $4 || '%'
      OR i.item_code ILIKE '%' || $4 || '%'
      OR i.item_name ILIKE '%' || $4 || '%'
  ))
  AND ($5::text = '' OR b.status = $5)
  AND b.deleted_at IS NULL
  AND w.deleted_at IS NULL
  AND i.deleted_at IS NULL
ORDER BY w.warehouse_code ASC, i.item_code ASC
LIMIT $6 OFFSET $7;
`,
		tenantID,
		nilIfEmpty(filter.WarehouseID),
		nilIfEmpty(filter.ItemID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	balances := make([]WarehouseBalance, 0)

	for rows.Next() {
		balance, err := scanWarehouseBalance(rows)
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

func (r *PostgresWarehouseBalanceRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type warehouseBalanceScanner interface {
	Scan(dest ...any) error
}

func scanWarehouseBalance(scanner warehouseBalanceScanner) (WarehouseBalance, error) {
	var balance WarehouseBalance
	var lastMovementAt pgtype.Timestamptz
	var status string

	err := scanner.Scan(
		&balance.BalanceID,
		&balance.TenantID,
		&balance.WarehouseID,
		&balance.ItemID,
		&balance.UnitID,
		&balance.OnHandQuantity,
		&balance.ReservedQuantity,
		&balance.AvailableQuantity,
		&lastMovementAt,
		&balance.LastStockMovementID,
		&status,
		&balance.CreatedAt,
		&balance.UpdatedAt,
		&balance.CreatedBy,
		&balance.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return WarehouseBalance{}, ErrWarehouseBalanceNotFound
	}

	if err != nil {
		return WarehouseBalance{}, err
	}

	if lastMovementAt.Valid {
		t := lastMovementAt.Time
		balance.LastMovementAt = &t
	}

	balance.Status = InventoryStatus(status)

	return balance, nil
}
