package sales

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ SalesDeliveryRepository = (*PostgresSalesDeliveryRepository)(nil)

type PostgresSalesDeliveryRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresSalesDeliveryRepository(pool *pgxpool.Pool) *PostgresSalesDeliveryRepository {
	return &PostgresSalesDeliveryRepository{pool: pool}
}

func (r *PostgresSalesDeliveryRepository) CreateSalesDelivery(ctx context.Context, input CreateSalesDeliveryInput) (SalesDelivery, error) {
	if err := ValidateCreateSalesDeliveryInput(input); err != nil {
		return SalesDelivery{}, err
	}

	documentDate := input.DocumentDate
	if documentDate.IsZero() {
		documentDate = time.Now().UTC()
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return SalesDelivery{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_sales_deliveries (
    tenant_id,
    delivery_no,
    sales_order_id,
    customer_id,
    party_id,
    warehouse_id,
    document_date,
    delivery_date,
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
    'draft',
    NULLIF($9, ''),
    NULLIF($10, '')
)
RETURNING
    delivery_id::text,
    tenant_id,
    delivery_no,
    COALESCE(sales_order_id::text, ''),
    customer_id::text,
    party_id::text,
    warehouse_id::text,
    document_date,
    delivery_date,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.DeliveryNo),
		salesNilIfEmpty(input.SalesOrderID),
		input.CustomerID,
		input.PartyID,
		input.WarehouseID,
		documentDate,
		input.DeliveryDate,
		input.Note,
		input.CreatedBy,
	)

	delivery, err := scanSalesDelivery(row)
	if err != nil {
		return SalesDelivery{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesDelivery{}, err
	}

	return delivery, nil
}

func (r *PostgresSalesDeliveryRepository) CreateSalesDeliveryLine(ctx context.Context, input CreateSalesDeliveryLineInput) (SalesDeliveryLine, error) {
	if err := ValidateCreateSalesDeliveryLineInput(input); err != nil {
		return SalesDeliveryLine{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return SalesDeliveryLine{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_sales_delivery_lines (
    tenant_id,
    delivery_id,
    sales_order_line_id,
    line_no,
    item_id,
    product_id,
    unit_id,
    description,
    quantity,
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
    NULLIF($8, ''),
    $9,
    'active',
    NULLIF($10, '')
)
RETURNING
    delivery_line_id::text,
    tenant_id,
    delivery_id::text,
    COALESCE(sales_order_line_id::text, ''),
    line_no,
    item_id::text,
    COALESCE(product_id::text, ''),
    unit_id::text,
    COALESCE(description, ''),
    quantity::float8,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.DeliveryID,
		salesNilIfEmpty(input.SalesOrderLineID),
		input.LineNo,
		input.ItemID,
		salesNilIfEmpty(input.ProductID),
		input.UnitID,
		input.Description,
		input.Quantity,
		input.CreatedBy,
	)

	line, err := scanSalesDeliveryLine(row)
	if err != nil {
		return SalesDeliveryLine{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesDeliveryLine{}, err
	}

	return line, nil
}

func (r *PostgresSalesDeliveryRepository) GetSalesDeliveryByID(ctx context.Context, tenantID string, deliveryID string) (SalesDelivery, error) {
	if strings.TrimSpace(tenantID) == "" {
		return SalesDelivery{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return SalesDelivery{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    delivery_id::text,
    tenant_id,
    delivery_no,
    COALESCE(sales_order_id::text, ''),
    customer_id::text,
    party_id::text,
    warehouse_id::text,
    document_date,
    delivery_date,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_sales_deliveries
WHERE tenant_id = $1
  AND delivery_id = $2
  AND deleted_at IS NULL;
`, tenantID, deliveryID)

	delivery, err := scanSalesDelivery(row)
	if err != nil {
		return SalesDelivery{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesDelivery{}, err
	}

	return delivery, nil
}

func (r *PostgresSalesDeliveryRepository) ListSalesDeliveries(ctx context.Context, tenantID string, filter ListSalesDeliveriesFilter) ([]SalesDelivery, error) {
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
    delivery_id::text,
    tenant_id,
    delivery_no,
    COALESCE(sales_order_id::text, ''),
    customer_id::text,
    party_id::text,
    warehouse_id::text,
    document_date,
    delivery_date,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_sales_deliveries
WHERE tenant_id = $1
  AND ($2::uuid IS NULL OR customer_id = $2::uuid)
  AND ($3::uuid IS NULL OR sales_order_id = $3::uuid)
  AND ($4::uuid IS NULL OR warehouse_id = $4::uuid)
  AND ($5::text = '' OR (
      delivery_no ILIKE '%' || $5 || '%'
      OR COALESCE(note, '') ILIKE '%' || $5 || '%'
  ))
  AND ($6::text = '' OR status = $6)
  AND deleted_at IS NULL
ORDER BY document_date DESC, delivery_no DESC
LIMIT $7 OFFSET $8;
`,
		tenantID,
		salesNilIfEmpty(filter.CustomerID),
		salesNilIfEmpty(filter.SalesOrderID),
		salesNilIfEmpty(filter.WarehouseID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	deliveries := make([]SalesDelivery, 0)

	for rows.Next() {
		delivery, err := scanSalesDelivery(rows)
		if err != nil {
			return nil, err
		}

		deliveries = append(deliveries, delivery)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return deliveries, nil
}

func (r *PostgresSalesDeliveryRepository) ListSalesDeliveryLines(ctx context.Context, tenantID string, deliveryID string) ([]SalesDeliveryLine, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrTenantRequired
	}

	if strings.TrimSpace(deliveryID) == "" {
		return nil, ErrDeliveryIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
SELECT
    delivery_line_id::text,
    tenant_id,
    delivery_id::text,
    COALESCE(sales_order_line_id::text, ''),
    line_no,
    item_id::text,
    COALESCE(product_id::text, ''),
    unit_id::text,
    COALESCE(description, ''),
    quantity::float8,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_sales_delivery_lines
WHERE tenant_id = $1
  AND delivery_id = $2
  AND deleted_at IS NULL
ORDER BY line_no ASC;
`, tenantID, deliveryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lines := make([]SalesDeliveryLine, 0)

	for rows.Next() {
		line, err := scanSalesDeliveryLine(rows)
		if err != nil {
			return nil, err
		}

		lines = append(lines, line)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return lines, nil
}

func (r *PostgresSalesDeliveryRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type salesDeliveryScanner interface {
	Scan(dest ...any) error
}

func scanSalesDelivery(scanner salesDeliveryScanner) (SalesDelivery, error) {
	var delivery SalesDelivery
	var status string
	var deliveryDate pgtype.Date

	err := scanner.Scan(
		&delivery.DeliveryID,
		&delivery.TenantID,
		&delivery.DeliveryNo,
		&delivery.SalesOrderID,
		&delivery.CustomerID,
		&delivery.PartyID,
		&delivery.WarehouseID,
		&delivery.DocumentDate,
		&deliveryDate,
		&status,
		&delivery.Note,
		&delivery.CreatedAt,
		&delivery.UpdatedAt,
		&delivery.CreatedBy,
		&delivery.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return SalesDelivery{}, ErrSalesDeliveryNotFound
	}

	if err != nil {
		return SalesDelivery{}, err
	}

	if deliveryDate.Valid {
		t := deliveryDate.Time
		delivery.DeliveryDate = &t
	}

	delivery.Status = SalesDeliveryStatus(status)

	return delivery, nil
}

func scanSalesDeliveryLine(scanner salesDeliveryScanner) (SalesDeliveryLine, error) {
	var line SalesDeliveryLine
	var status string

	err := scanner.Scan(
		&line.DeliveryLineID,
		&line.TenantID,
		&line.DeliveryID,
		&line.SalesOrderLineID,
		&line.LineNo,
		&line.ItemID,
		&line.ProductID,
		&line.UnitID,
		&line.Description,
		&line.Quantity,
		&status,
		&line.CreatedAt,
		&line.UpdatedAt,
		&line.CreatedBy,
		&line.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return SalesDeliveryLine{}, ErrSalesDeliveryNotFound
	}

	if err != nil {
		return SalesDeliveryLine{}, err
	}

	line.Status = SalesLineStatus(status)

	return line, nil
}
