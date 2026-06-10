package productcatalog

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ CategoryRepository = (*PostgresCategoryRepository)(nil)

type PostgresCategoryRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresCategoryRepository(pool *pgxpool.Pool) *PostgresCategoryRepository {
	return &PostgresCategoryRepository{pool: pool}
}

func (r *PostgresCategoryRepository) CreateCategory(ctx context.Context, input CreateCategoryInput) (ProductCategory, error) {
	if err := ValidateCreateCategoryInput(input); err != nil {
		return ProductCategory{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return ProductCategory{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_product_categories (
    tenant_id,
    parent_category_id,
    category_code,
    category_name,
    description,
    sort_order,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    $4,
    NULLIF($5, ''),
    $6,
    'active',
    NULLIF($7, '')
)
RETURNING
    category_id::text,
    tenant_id,
    COALESCE(parent_category_id::text, ''),
    category_code,
    category_name,
    COALESCE(description, ''),
    sort_order,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		nilIfEmpty(input.ParentCategoryID),
		strings.TrimSpace(input.CategoryCode),
		strings.TrimSpace(input.CategoryName),
		input.Description,
		input.SortOrder,
		input.CreatedBy,
	)

	category, err := scanCategory(row)
	if err != nil {
		return ProductCategory{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return ProductCategory{}, err
	}

	return category, nil
}

func (r *PostgresCategoryRepository) GetCategoryByID(ctx context.Context, tenantID string, categoryID string) (ProductCategory, error) {
	if strings.TrimSpace(tenantID) == "" {
		return ProductCategory{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return ProductCategory{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    category_id::text,
    tenant_id,
    COALESCE(parent_category_id::text, ''),
    category_code,
    category_name,
    COALESCE(description, ''),
    sort_order,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_product_categories
WHERE tenant_id = $1
  AND category_id = $2
  AND deleted_at IS NULL;
`, tenantID, categoryID)

	category, err := scanCategory(row)
	if err != nil {
		return ProductCategory{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return ProductCategory{}, err
	}

	return category, nil
}

func (r *PostgresCategoryRepository) ListCategories(ctx context.Context, tenantID string, filter ListCategoriesFilter) ([]ProductCategory, error) {
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
    category_id::text,
    tenant_id,
    COALESCE(parent_category_id::text, ''),
    category_code,
    category_name,
    COALESCE(description, ''),
    sort_order,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_product_categories
WHERE tenant_id = $1
  AND ($2::uuid IS NULL OR parent_category_id = $2::uuid)
  AND ($3::text = '' OR (
      category_code ILIKE '%' || $3 || '%'
      OR category_name ILIKE '%' || $3 || '%'
      OR COALESCE(description, '') ILIKE '%' || $3 || '%'
  ))
  AND ($4::text = '' OR status = $4)
  AND deleted_at IS NULL
ORDER BY sort_order ASC, category_name ASC
LIMIT $5 OFFSET $6;
`,
		tenantID,
		nilIfEmpty(filter.ParentCategoryID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	categories := make([]ProductCategory, 0)

	for rows.Next() {
		category, err := scanCategory(rows)
		if err != nil {
			return nil, err
		}

		categories = append(categories, category)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return categories, nil
}

func (r *PostgresCategoryRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type categoryScanner interface {
	Scan(dest ...any) error
}

func scanCategory(scanner categoryScanner) (ProductCategory, error) {
	var category ProductCategory
	var status string

	err := scanner.Scan(
		&category.CategoryID,
		&category.TenantID,
		&category.ParentCategoryID,
		&category.CategoryCode,
		&category.CategoryName,
		&category.Description,
		&category.SortOrder,
		&status,
		&category.CreatedAt,
		&category.UpdatedAt,
		&category.CreatedBy,
		&category.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return ProductCategory{}, ErrCategoryNotFound
	}

	if err != nil {
		return ProductCategory{}, err
	}

	category.Status = CatalogStatus(status)

	return category, nil
}

func nilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}
