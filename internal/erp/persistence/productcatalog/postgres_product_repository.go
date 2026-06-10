package productcatalog

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ ProductRepository = (*PostgresProductRepository)(nil)

type PostgresProductRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresProductRepository(pool *pgxpool.Pool) *PostgresProductRepository {
	return &PostgresProductRepository{pool: pool}
}

func (r *PostgresProductRepository) CreateProduct(ctx context.Context, input CreateProductInput) (Product, error) {
	if err := ValidateCreateProductInput(input); err != nil {
		return Product{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return Product{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_products (
    tenant_id,
    item_id,
    product_code,
    product_name,
    short_description,
    long_description,
    default_sales_unit_id,
    is_sellable,
    is_visible_pos,
    is_visible_web,
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
    'active',
    NULLIF($11, '')
)
RETURNING
    product_id::text,
    tenant_id,
    item_id::text,
    product_code,
    product_name,
    COALESCE(short_description, ''),
    COALESCE(long_description, ''),
    COALESCE(default_sales_unit_id::text, ''),
    is_sellable,
    is_visible_pos,
    is_visible_web,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.ItemID,
		strings.TrimSpace(input.ProductCode),
		strings.TrimSpace(input.ProductName),
		input.ShortDescription,
		input.LongDescription,
		nilIfEmpty(input.DefaultSalesUnitID),
		input.IsSellable,
		input.IsVisiblePOS,
		input.IsVisibleWeb,
		input.CreatedBy,
	)

	product, err := scanProduct(row)
	if err != nil {
		return Product{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Product{}, err
	}

	return product, nil
}

func (r *PostgresProductRepository) GetProductByID(ctx context.Context, tenantID string, productID string) (Product, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Product{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Product{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    product_id::text,
    tenant_id,
    item_id::text,
    product_code,
    product_name,
    COALESCE(short_description, ''),
    COALESCE(long_description, ''),
    COALESCE(default_sales_unit_id::text, ''),
    is_sellable,
    is_visible_pos,
    is_visible_web,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_products
WHERE tenant_id = $1
  AND product_id = $2
  AND deleted_at IS NULL;
`, tenantID, productID)

	product, err := scanProduct(row)
	if err != nil {
		return Product{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Product{}, err
	}

	return product, nil
}

func (r *PostgresProductRepository) ListProducts(ctx context.Context, tenantID string, filter ListProductsFilter) ([]Product, error) {
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
    p.product_id::text,
    p.tenant_id,
    p.item_id::text,
    p.product_code,
    p.product_name,
    COALESCE(p.short_description, ''),
    COALESCE(p.long_description, ''),
    COALESCE(p.default_sales_unit_id::text, ''),
    p.is_sellable,
    p.is_visible_pos,
    p.is_visible_web,
    p.status,
    p.created_at,
    p.updated_at,
    COALESCE(p.created_by, ''),
    COALESCE(p.updated_by, '')
FROM erp_products p
JOIN erp_items i ON i.item_id = p.item_id
WHERE p.tenant_id = $1
  AND i.tenant_id = $1
  AND ($2::text = '' OR (
      p.product_code ILIKE '%' || $2 || '%'
      OR p.product_name ILIKE '%' || $2 || '%'
      OR i.item_code ILIKE '%' || $2 || '%'
      OR i.item_name ILIKE '%' || $2 || '%'
      OR COALESCE(i.barcode, '') ILIKE '%' || $2 || '%'
  ))
  AND ($3::text = '' OR p.status = $3)
  AND ($4::boolean IS NULL OR p.is_visible_pos = $4)
  AND ($5::boolean IS NULL OR p.is_visible_web = $5)
  AND ($6::boolean = false OR p.is_sellable = true)
  AND p.deleted_at IS NULL
  AND i.deleted_at IS NULL
ORDER BY p.product_code ASC
LIMIT $7 OFFSET $8;
`,
		tenantID,
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		nullableBool(filter.VisiblePOS),
		nullableBool(filter.VisibleWeb),
		filter.SellableOnly,
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	products := make([]Product, 0)

	for rows.Next() {
		product, err := scanProduct(rows)
		if err != nil {
			return nil, err
		}

		products = append(products, product)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return products, nil
}

func (r *PostgresProductRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type productScanner interface {
	Scan(dest ...any) error
}

func scanProduct(scanner productScanner) (Product, error) {
	var product Product
	var status string

	err := scanner.Scan(
		&product.ProductID,
		&product.TenantID,
		&product.ItemID,
		&product.ProductCode,
		&product.ProductName,
		&product.ShortDescription,
		&product.LongDescription,
		&product.DefaultSalesUnitID,
		&product.IsSellable,
		&product.IsVisiblePOS,
		&product.IsVisibleWeb,
		&status,
		&product.CreatedAt,
		&product.UpdatedAt,
		&product.CreatedBy,
		&product.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return Product{}, ErrProductNotFound
	}

	if err != nil {
		return Product{}, err
	}

	product.Status = CatalogStatus(status)

	return product, nil
}

func nullableBool(value *bool) any {
	if value == nil {
		return nil
	}

	return *value
}
