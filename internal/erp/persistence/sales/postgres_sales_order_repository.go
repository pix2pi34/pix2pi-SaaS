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

var _ SalesOrderRepository = (*PostgresSalesOrderRepository)(nil)

type PostgresSalesOrderRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresSalesOrderRepository(pool *pgxpool.Pool) *PostgresSalesOrderRepository {
	return &PostgresSalesOrderRepository{pool: pool}
}

func (r *PostgresSalesOrderRepository) CreateSalesOrder(ctx context.Context, input CreateSalesOrderInput) (SalesOrder, error) {
	if err := ValidateCreateSalesOrderInput(input); err != nil {
		return SalesOrder{}, err
	}

	documentDate := input.DocumentDate
	if documentDate.IsZero() {
		documentDate = time.Now().UTC()
	}

	currencyCode := strings.ToUpper(strings.TrimSpace(input.CurrencyCode))
	if currencyCode == "" {
		currencyCode = "TRY"
	}

	exchangeRate := input.ExchangeRate
	if exchangeRate <= 0 {
		exchangeRate = 1
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return SalesOrder{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_sales_orders (
    tenant_id,
    sales_order_no,
    quotation_id,
    customer_id,
    party_id,
    document_date,
    requested_delivery_date,
    currency_code,
    exchange_rate,
    subtotal_amount,
    discount_amount,
    vat_amount,
    total_amount,
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
    $11,
    $12,
    $13,
    'draft',
    NULLIF($14, ''),
    NULLIF($15, '')
)
RETURNING
    sales_order_id::text,
    tenant_id,
    sales_order_no,
    COALESCE(quotation_id::text, ''),
    customer_id::text,
    party_id::text,
    document_date,
    requested_delivery_date,
    currency_code,
    exchange_rate::float8,
    subtotal_amount::float8,
    discount_amount::float8,
    vat_amount::float8,
    total_amount::float8,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.SalesOrderNo),
		salesNilIfEmpty(input.QuotationID),
		input.CustomerID,
		input.PartyID,
		documentDate,
		input.RequestedDeliveryDate,
		currencyCode,
		exchangeRate,
		input.SubtotalAmount,
		input.DiscountAmount,
		input.VATAmount,
		input.TotalAmount,
		input.Note,
		input.CreatedBy,
	)

	order, err := scanSalesOrder(row)
	if err != nil {
		return SalesOrder{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesOrder{}, err
	}

	return order, nil
}

func (r *PostgresSalesOrderRepository) CreateSalesOrderLine(ctx context.Context, input CreateSalesOrderLineInput) (SalesOrderLine, error) {
	if err := ValidateCreateSalesOrderLineInput(input); err != nil {
		return SalesOrderLine{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return SalesOrderLine{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_sales_order_lines (
    tenant_id,
    sales_order_id,
    quotation_line_id,
    line_no,
    item_id,
    product_id,
    unit_id,
    description,
    quantity,
    delivered_quantity,
    invoiced_quantity,
    unit_price,
    discount_rate,
    discount_amount,
    vat_rate,
    vat_amount,
    line_total,
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
    $10,
    $11,
    $12,
    $13,
    $14,
    $15,
    $16,
    $17,
    'active',
    NULLIF($18, '')
)
RETURNING
    sales_order_line_id::text,
    tenant_id,
    sales_order_id::text,
    COALESCE(quotation_line_id::text, ''),
    line_no,
    item_id::text,
    COALESCE(product_id::text, ''),
    unit_id::text,
    COALESCE(description, ''),
    quantity::float8,
    delivered_quantity::float8,
    invoiced_quantity::float8,
    unit_price::float8,
    discount_rate::float8,
    discount_amount::float8,
    vat_rate::float8,
    vat_amount::float8,
    line_total::float8,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.SalesOrderID,
		salesNilIfEmpty(input.QuotationLineID),
		input.LineNo,
		input.ItemID,
		salesNilIfEmpty(input.ProductID),
		input.UnitID,
		input.Description,
		input.Quantity,
		input.DeliveredQuantity,
		input.InvoicedQuantity,
		input.UnitPrice,
		input.DiscountRate,
		input.DiscountAmount,
		input.VATRate,
		input.VATAmount,
		input.LineTotal,
		input.CreatedBy,
	)

	line, err := scanSalesOrderLine(row)
	if err != nil {
		return SalesOrderLine{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesOrderLine{}, err
	}

	return line, nil
}

func (r *PostgresSalesOrderRepository) GetSalesOrderByID(ctx context.Context, tenantID string, salesOrderID string) (SalesOrder, error) {
	if strings.TrimSpace(tenantID) == "" {
		return SalesOrder{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return SalesOrder{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    sales_order_id::text,
    tenant_id,
    sales_order_no,
    COALESCE(quotation_id::text, ''),
    customer_id::text,
    party_id::text,
    document_date,
    requested_delivery_date,
    currency_code,
    exchange_rate::float8,
    subtotal_amount::float8,
    discount_amount::float8,
    vat_amount::float8,
    total_amount::float8,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_sales_orders
WHERE tenant_id = $1
  AND sales_order_id = $2
  AND deleted_at IS NULL;
`, tenantID, salesOrderID)

	order, err := scanSalesOrder(row)
	if err != nil {
		return SalesOrder{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesOrder{}, err
	}

	return order, nil
}

func (r *PostgresSalesOrderRepository) ListSalesOrders(ctx context.Context, tenantID string, filter ListSalesOrdersFilter) ([]SalesOrder, error) {
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
    sales_order_id::text,
    tenant_id,
    sales_order_no,
    COALESCE(quotation_id::text, ''),
    customer_id::text,
    party_id::text,
    document_date,
    requested_delivery_date,
    currency_code,
    exchange_rate::float8,
    subtotal_amount::float8,
    discount_amount::float8,
    vat_amount::float8,
    total_amount::float8,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_sales_orders
WHERE tenant_id = $1
  AND ($2::uuid IS NULL OR customer_id = $2::uuid)
  AND ($3::uuid IS NULL OR quotation_id = $3::uuid)
  AND ($4::text = '' OR (
      sales_order_no ILIKE '%' || $4 || '%'
      OR COALESCE(note, '') ILIKE '%' || $4 || '%'
  ))
  AND ($5::text = '' OR status = $5)
  AND deleted_at IS NULL
ORDER BY document_date DESC, sales_order_no DESC
LIMIT $6 OFFSET $7;
`,
		tenantID,
		salesNilIfEmpty(filter.CustomerID),
		salesNilIfEmpty(filter.QuotationID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	orders := make([]SalesOrder, 0)

	for rows.Next() {
		order, err := scanSalesOrder(rows)
		if err != nil {
			return nil, err
		}

		orders = append(orders, order)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return orders, nil
}

func (r *PostgresSalesOrderRepository) ListSalesOrderLines(ctx context.Context, tenantID string, salesOrderID string) ([]SalesOrderLine, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrTenantRequired
	}

	if strings.TrimSpace(salesOrderID) == "" {
		return nil, ErrSalesOrderIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
SELECT
    sales_order_line_id::text,
    tenant_id,
    sales_order_id::text,
    COALESCE(quotation_line_id::text, ''),
    line_no,
    item_id::text,
    COALESCE(product_id::text, ''),
    unit_id::text,
    COALESCE(description, ''),
    quantity::float8,
    delivered_quantity::float8,
    invoiced_quantity::float8,
    unit_price::float8,
    discount_rate::float8,
    discount_amount::float8,
    vat_rate::float8,
    vat_amount::float8,
    line_total::float8,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_sales_order_lines
WHERE tenant_id = $1
  AND sales_order_id = $2
  AND deleted_at IS NULL
ORDER BY line_no ASC;
`, tenantID, salesOrderID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lines := make([]SalesOrderLine, 0)

	for rows.Next() {
		line, err := scanSalesOrderLine(rows)
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

func (r *PostgresSalesOrderRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type salesOrderScanner interface {
	Scan(dest ...any) error
}

func scanSalesOrder(scanner salesOrderScanner) (SalesOrder, error) {
	var order SalesOrder
	var status string
	var requestedDeliveryDate pgtype.Date

	err := scanner.Scan(
		&order.SalesOrderID,
		&order.TenantID,
		&order.SalesOrderNo,
		&order.QuotationID,
		&order.CustomerID,
		&order.PartyID,
		&order.DocumentDate,
		&requestedDeliveryDate,
		&order.CurrencyCode,
		&order.ExchangeRate,
		&order.SubtotalAmount,
		&order.DiscountAmount,
		&order.VATAmount,
		&order.TotalAmount,
		&status,
		&order.Note,
		&order.CreatedAt,
		&order.UpdatedAt,
		&order.CreatedBy,
		&order.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return SalesOrder{}, ErrSalesOrderNotFound
	}

	if err != nil {
		return SalesOrder{}, err
	}

	if requestedDeliveryDate.Valid {
		t := requestedDeliveryDate.Time
		order.RequestedDeliveryDate = &t
	}

	order.Status = SalesOrderStatus(status)

	return order, nil
}

func scanSalesOrderLine(scanner salesOrderScanner) (SalesOrderLine, error) {
	var line SalesOrderLine
	var status string

	err := scanner.Scan(
		&line.SalesOrderLineID,
		&line.TenantID,
		&line.SalesOrderID,
		&line.QuotationLineID,
		&line.LineNo,
		&line.ItemID,
		&line.ProductID,
		&line.UnitID,
		&line.Description,
		&line.Quantity,
		&line.DeliveredQuantity,
		&line.InvoicedQuantity,
		&line.UnitPrice,
		&line.DiscountRate,
		&line.DiscountAmount,
		&line.VATRate,
		&line.VATAmount,
		&line.LineTotal,
		&status,
		&line.CreatedAt,
		&line.UpdatedAt,
		&line.CreatedBy,
		&line.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return SalesOrderLine{}, ErrSalesOrderNotFound
	}

	if err != nil {
		return SalesOrderLine{}, err
	}

	line.Status = SalesLineStatus(status)

	return line, nil
}
