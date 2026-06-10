package productcatalog

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ ItemRepository = (*PostgresItemRepository)(nil)

type PostgresItemRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresItemRepository(pool *pgxpool.Pool) *PostgresItemRepository {
	return &PostgresItemRepository{pool: pool}
}

func (r *PostgresItemRepository) CreateItem(ctx context.Context, input CreateItemInput) (Item, error) {
	if err := ValidateCreateItemInput(input); err != nil {
		return Item{}, err
	}

	itemType := input.ItemType
	if strings.TrimSpace(string(itemType)) == "" {
		itemType = ItemTypeStock
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return Item{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_items (
    tenant_id,
    item_code,
    item_name,
    item_type,
    category_id,
    base_unit_id,
    barcode,
    sku,
    vat_rate,
    is_inventory_tracked,
    is_sales_allowed,
    is_purchase_allowed,
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
    NULLIF($7, ''),
    NULLIF($8, ''),
    $9,
    $10,
    $11,
    $12,
    'active',
    NULLIF($13, '')
)
RETURNING
    item_id::text,
    tenant_id,
    item_code,
    item_name,
    item_type,
    COALESCE(category_id::text, ''),
    base_unit_id::text,
    COALESCE(barcode, ''),
    COALESCE(sku, ''),
    vat_rate::float8,
    is_inventory_tracked,
    is_sales_allowed,
    is_purchase_allowed,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.ItemCode),
		strings.TrimSpace(input.ItemName),
		string(itemType),
		nilIfEmpty(input.CategoryID),
		input.BaseUnitID,
		input.Barcode,
		input.SKU,
		input.VATRate,
		input.IsInventoryTracked,
		input.IsSalesAllowed,
		input.IsPurchaseAllowed,
		input.CreatedBy,
	)

	item, err := scanItem(row)
	if err != nil {
		return Item{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Item{}, err
	}

	return item, nil
}

func (r *PostgresItemRepository) GetItemByID(ctx context.Context, tenantID string, itemID string) (Item, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Item{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Item{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    item_id::text,
    tenant_id,
    item_code,
    item_name,
    item_type,
    COALESCE(category_id::text, ''),
    base_unit_id::text,
    COALESCE(barcode, ''),
    COALESCE(sku, ''),
    vat_rate::float8,
    is_inventory_tracked,
    is_sales_allowed,
    is_purchase_allowed,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_items
WHERE tenant_id = $1
  AND item_id = $2
  AND deleted_at IS NULL;
`, tenantID, itemID)

	item, err := scanItem(row)
	if err != nil {
		return Item{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Item{}, err
	}

	return item, nil
}

func (r *PostgresItemRepository) ListItems(ctx context.Context, tenantID string, filter ListItemsFilter) ([]Item, error) {
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
    i.item_id::text,
    i.tenant_id,
    i.item_code,
    i.item_name,
    i.item_type,
    COALESCE(i.category_id::text, ''),
    i.base_unit_id::text,
    COALESCE(i.barcode, ''),
    COALESCE(i.sku, ''),
    i.vat_rate::float8,
    i.is_inventory_tracked,
    i.is_sales_allowed,
    i.is_purchase_allowed,
    i.status,
    i.created_at,
    i.updated_at,
    COALESCE(i.created_by, ''),
    COALESCE(i.updated_by, '')
FROM erp_items i
WHERE i.tenant_id = $1
  AND ($2::uuid IS NULL OR i.category_id = $2::uuid)
  AND ($3::text = '' OR (
      i.item_code ILIKE '%' || $3 || '%'
      OR i.item_name ILIKE '%' || $3 || '%'
      OR COALESCE(i.barcode, '') ILIKE '%' || $3 || '%'
      OR COALESCE(i.sku, '') ILIKE '%' || $3 || '%'
  ))
  AND ($4::text = '' OR i.status = $4)
  AND i.deleted_at IS NULL
ORDER BY i.item_code ASC
LIMIT $5 OFFSET $6;
`,
		tenantID,
		nilIfEmpty(filter.CategoryID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]Item, 0)

	for rows.Next() {
		item, err := scanItem(rows)
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

func (r *PostgresItemRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type itemScanner interface {
	Scan(dest ...any) error
}

func scanItem(scanner itemScanner) (Item, error) {
	var item Item
	var itemType string
	var status string

	err := scanner.Scan(
		&item.ItemID,
		&item.TenantID,
		&item.ItemCode,
		&item.ItemName,
		&itemType,
		&item.CategoryID,
		&item.BaseUnitID,
		&item.Barcode,
		&item.SKU,
		&item.VATRate,
		&item.IsInventoryTracked,
		&item.IsSalesAllowed,
		&item.IsPurchaseAllowed,
		&status,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.CreatedBy,
		&item.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return Item{}, ErrItemNotFound
	}

	if err != nil {
		return Item{}, err
	}

	item.ItemType = ItemType(itemType)
	item.Status = CatalogStatus(status)

	return item, nil
}
