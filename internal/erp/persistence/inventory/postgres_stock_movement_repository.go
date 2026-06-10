package inventory

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ StockMovementRepository = (*PostgresStockMovementRepository)(nil)

type PostgresStockMovementRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresStockMovementRepository(pool *pgxpool.Pool) *PostgresStockMovementRepository {
	return &PostgresStockMovementRepository{pool: pool}
}

func (r *PostgresStockMovementRepository) CreateStockMovement(ctx context.Context, input CreateStockMovementInput) (StockMovement, error) {
	if err := ValidateCreateStockMovementInput(input); err != nil {
		return StockMovement{}, err
	}

	movementAt := input.MovementAt
	if movementAt.IsZero() {
		movementAt = time.Now().UTC()
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return StockMovement{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_stock_movements (
    tenant_id,
    movement_no,
    movement_type,
    movement_direction,
    warehouse_id,
    item_id,
    unit_id,
    quantity,
    unit_cost,
    total_cost,
    source_type,
    source_id,
    source_line_id,
    movement_at,
    posted_at,
    status,
    note,
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
    NULLIF($12, ''),
    NULLIF($13, ''),
    $14,
    $15,
    'posted',
    NULLIF($16, ''),
    NULLIF($17, '')
)
RETURNING
    stock_movement_id::text,
    tenant_id,
    movement_no,
    movement_type,
    movement_direction,
    warehouse_id::text,
    item_id::text,
    unit_id::text,
    quantity::float8,
    unit_cost::float8,
    total_cost::float8,
    COALESCE(source_type, ''),
    COALESCE(source_id, ''),
    COALESCE(source_line_id, ''),
    movement_at,
    posted_at,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.MovementNo),
		string(input.MovementType),
		string(input.MovementDirection),
		input.WarehouseID,
		input.ItemID,
		input.UnitID,
		input.Quantity,
		input.UnitCost,
		input.TotalCost,
		input.SourceType,
		input.SourceID,
		input.SourceLineID,
		movementAt,
		input.PostedAt,
		input.Note,
		input.CreatedBy,
	)

	movement, err := scanStockMovement(row)
	if err != nil {
		return StockMovement{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return StockMovement{}, err
	}

	return movement, nil
}

func (r *PostgresStockMovementRepository) GetStockMovementByID(ctx context.Context, tenantID string, stockMovementID string) (StockMovement, error) {
	if strings.TrimSpace(tenantID) == "" {
		return StockMovement{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return StockMovement{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    stock_movement_id::text,
    tenant_id,
    movement_no,
    movement_type,
    movement_direction,
    warehouse_id::text,
    item_id::text,
    unit_id::text,
    quantity::float8,
    unit_cost::float8,
    total_cost::float8,
    COALESCE(source_type, ''),
    COALESCE(source_id, ''),
    COALESCE(source_line_id, ''),
    movement_at,
    posted_at,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_stock_movements
WHERE tenant_id = $1
  AND stock_movement_id = $2
  AND deleted_at IS NULL;
`, tenantID, stockMovementID)

	movement, err := scanStockMovement(row)
	if err != nil {
		return StockMovement{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return StockMovement{}, err
	}

	return movement, nil
}

func (r *PostgresStockMovementRepository) ListStockMovements(ctx context.Context, tenantID string, filter ListStockMovementsFilter) ([]StockMovement, error) {
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
    stock_movement_id::text,
    tenant_id,
    movement_no,
    movement_type,
    movement_direction,
    warehouse_id::text,
    item_id::text,
    unit_id::text,
    quantity::float8,
    unit_cost::float8,
    total_cost::float8,
    COALESCE(source_type, ''),
    COALESCE(source_id, ''),
    COALESCE(source_line_id, ''),
    movement_at,
    posted_at,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_stock_movements
WHERE tenant_id = $1
  AND ($2::uuid IS NULL OR warehouse_id = $2::uuid)
  AND ($3::uuid IS NULL OR item_id = $3::uuid)
  AND ($4::text = '' OR source_type = $4)
  AND ($5::text = '' OR source_id = $5)
  AND ($6::text = '' OR (
      movement_no ILIKE '%' || $6 || '%'
      OR COALESCE(source_id, '') ILIKE '%' || $6 || '%'
      OR COALESCE(note, '') ILIKE '%' || $6 || '%'
  ))
  AND ($7::text = '' OR status = $7)
  AND deleted_at IS NULL
ORDER BY movement_at DESC, movement_no DESC
LIMIT $8 OFFSET $9;
`,
		tenantID,
		nilIfEmpty(filter.WarehouseID),
		nilIfEmpty(filter.ItemID),
		strings.TrimSpace(filter.SourceType),
		strings.TrimSpace(filter.SourceID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	movements := make([]StockMovement, 0)

	for rows.Next() {
		movement, err := scanStockMovement(rows)
		if err != nil {
			return nil, err
		}

		movements = append(movements, movement)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return movements, nil
}

func (r *PostgresStockMovementRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type stockMovementScanner interface {
	Scan(dest ...any) error
}

func scanStockMovement(scanner stockMovementScanner) (StockMovement, error) {
	var movement StockMovement
	var movementType string
	var movementDirection string
	var status string
	var postedAt pgtype.Timestamptz

	err := scanner.Scan(
		&movement.StockMovementID,
		&movement.TenantID,
		&movement.MovementNo,
		&movementType,
		&movementDirection,
		&movement.WarehouseID,
		&movement.ItemID,
		&movement.UnitID,
		&movement.Quantity,
		&movement.UnitCost,
		&movement.TotalCost,
		&movement.SourceType,
		&movement.SourceID,
		&movement.SourceLineID,
		&movement.MovementAt,
		&postedAt,
		&status,
		&movement.Note,
		&movement.CreatedAt,
		&movement.UpdatedAt,
		&movement.CreatedBy,
		&movement.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return StockMovement{}, ErrStockMovementNotFound
	}

	if err != nil {
		return StockMovement{}, err
	}

	if postedAt.Valid {
		t := postedAt.Time
		movement.PostedAt = &t
	}

	movement.MovementType = StockMovementType(movementType)
	movement.MovementDirection = StockMovementDirection(movementDirection)
	movement.Status = InventoryStatus(status)

	return movement, nil
}

func nilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}
