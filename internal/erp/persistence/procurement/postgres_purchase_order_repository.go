package procurement

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ PurchaseOrderRepository = (*PostgresPurchaseOrderRepository)(nil)

type PostgresPurchaseOrderRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresPurchaseOrderRepository(pool *pgxpool.Pool) *PostgresPurchaseOrderRepository {
	return &PostgresPurchaseOrderRepository{pool: pool}
}

func (r *PostgresPurchaseOrderRepository) CreatePurchaseOrder(ctx context.Context, input CreatePurchaseOrderInput) (PurchaseOrder, error) {
	if err := ValidateCreatePurchaseOrderInput(input); err != nil {
		return PurchaseOrder{}, err
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
		return PurchaseOrder{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_purchase_orders (
    tenant_id,
    purchase_order_no,
    vendor_id,
    party_id,
    document_date,
    expected_receipt_date,
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
    'draft',
    NULLIF($13, ''),
    NULLIF($14, '')
)
RETURNING
    purchase_order_id::text,
    tenant_id,
    purchase_order_no,
    vendor_id::text,
    party_id::text,
    document_date,
    expected_receipt_date,
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
		strings.TrimSpace(input.PurchaseOrderNo),
		input.VendorID,
		input.PartyID,
		documentDate,
		input.ExpectedReceiptDate,
		currencyCode,
		exchangeRate,
		input.SubtotalAmount,
		input.DiscountAmount,
		input.VATAmount,
		input.TotalAmount,
		input.Note,
		input.CreatedBy,
	)

	order, err := scanPurchaseOrder(row)
	if err != nil {
		return PurchaseOrder{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseOrder{}, err
	}

	return order, nil
}

func (r *PostgresPurchaseOrderRepository) CreatePurchaseOrderLine(ctx context.Context, input CreatePurchaseOrderLineInput) (PurchaseOrderLine, error) {
	if err := ValidateCreatePurchaseOrderLineInput(input); err != nil {
		return PurchaseOrderLine{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return PurchaseOrderLine{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_purchase_order_lines (
    tenant_id,
    purchase_order_id,
    line_no,
    item_id,
    product_id,
    unit_id,
    description,
    quantity,
    received_quantity,
    invoiced_quantity,
    unit_cost,
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
    NULLIF($7, ''),
    $8,
    $9,
    $10,
    $11,
    $12,
    $13,
    $14,
    $15,
    $16,
    'active',
    NULLIF($17, '')
)
RETURNING
    purchase_order_line_id::text,
    tenant_id,
    purchase_order_id::text,
    line_no,
    item_id::text,
    COALESCE(product_id::text, ''),
    unit_id::text,
    COALESCE(description, ''),
    quantity::float8,
    received_quantity::float8,
    invoiced_quantity::float8,
    unit_cost::float8,
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
		input.PurchaseOrderID,
		input.LineNo,
		input.ItemID,
		procurementNilIfEmpty(input.ProductID),
		input.UnitID,
		input.Description,
		input.Quantity,
		input.ReceivedQuantity,
		input.InvoicedQuantity,
		input.UnitCost,
		input.DiscountRate,
		input.DiscountAmount,
		input.VATRate,
		input.VATAmount,
		input.LineTotal,
		input.CreatedBy,
	)

	line, err := scanPurchaseOrderLine(row)
	if err != nil {
		return PurchaseOrderLine{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseOrderLine{}, err
	}

	return line, nil
}

func (r *PostgresPurchaseOrderRepository) GetPurchaseOrderByID(ctx context.Context, tenantID string, purchaseOrderID string) (PurchaseOrder, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PurchaseOrder{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return PurchaseOrder{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    purchase_order_id::text,
    tenant_id,
    purchase_order_no,
    vendor_id::text,
    party_id::text,
    document_date,
    expected_receipt_date,
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
FROM erp_purchase_orders
WHERE tenant_id = $1
  AND purchase_order_id = $2
  AND deleted_at IS NULL;
`, tenantID, purchaseOrderID)

	order, err := scanPurchaseOrder(row)
	if err != nil {
		return PurchaseOrder{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseOrder{}, err
	}

	return order, nil
}

func (r *PostgresPurchaseOrderRepository) ListPurchaseOrders(ctx context.Context, tenantID string, filter ListPurchaseOrdersFilter) ([]PurchaseOrder, error) {
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
    purchase_order_id::text,
    tenant_id,
    purchase_order_no,
    vendor_id::text,
    party_id::text,
    document_date,
    expected_receipt_date,
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
FROM erp_purchase_orders
WHERE tenant_id = $1
  AND ($2::uuid IS NULL OR vendor_id = $2::uuid)
  AND ($3::text = '' OR (
      purchase_order_no ILIKE '%' || $3 || '%'
      OR COALESCE(note, '') ILIKE '%' || $3 || '%'
  ))
  AND ($4::text = '' OR status = $4)
  AND deleted_at IS NULL
ORDER BY document_date DESC, purchase_order_no DESC
LIMIT $5 OFFSET $6;
`,
		tenantID,
		procurementNilIfEmpty(filter.VendorID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	orders := make([]PurchaseOrder, 0)

	for rows.Next() {
		order, err := scanPurchaseOrder(rows)
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

func (r *PostgresPurchaseOrderRepository) ListPurchaseOrderLines(ctx context.Context, tenantID string, purchaseOrderID string) ([]PurchaseOrderLine, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrTenantRequired
	}

	if strings.TrimSpace(purchaseOrderID) == "" {
		return nil, ErrPurchaseOrderIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
SELECT
    purchase_order_line_id::text,
    tenant_id,
    purchase_order_id::text,
    line_no,
    item_id::text,
    COALESCE(product_id::text, ''),
    unit_id::text,
    COALESCE(description, ''),
    quantity::float8,
    received_quantity::float8,
    invoiced_quantity::float8,
    unit_cost::float8,
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
FROM erp_purchase_order_lines
WHERE tenant_id = $1
  AND purchase_order_id = $2
  AND deleted_at IS NULL
ORDER BY line_no ASC;
`, tenantID, purchaseOrderID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lines := make([]PurchaseOrderLine, 0)

	for rows.Next() {
		line, err := scanPurchaseOrderLine(rows)
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

func (r *PostgresPurchaseOrderRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type purchaseOrderScanner interface {
	Scan(dest ...any) error
}

func scanPurchaseOrder(scanner purchaseOrderScanner) (PurchaseOrder, error) {
	var order PurchaseOrder
	var status string
	var expectedReceiptDate pgtype.Date

	err := scanner.Scan(
		&order.PurchaseOrderID,
		&order.TenantID,
		&order.PurchaseOrderNo,
		&order.VendorID,
		&order.PartyID,
		&order.DocumentDate,
		&expectedReceiptDate,
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
		return PurchaseOrder{}, ErrPurchaseOrderNotFound
	}

	if err != nil {
		return PurchaseOrder{}, err
	}

	if expectedReceiptDate.Valid {
		t := expectedReceiptDate.Time
		order.ExpectedReceiptDate = &t
	}

	order.Status = PurchaseOrderStatus(status)

	return order, nil
}

func scanPurchaseOrderLine(scanner purchaseOrderScanner) (PurchaseOrderLine, error) {
	var line PurchaseOrderLine
	var status string

	err := scanner.Scan(
		&line.PurchaseOrderLineID,
		&line.TenantID,
		&line.PurchaseOrderID,
		&line.LineNo,
		&line.ItemID,
		&line.ProductID,
		&line.UnitID,
		&line.Description,
		&line.Quantity,
		&line.ReceivedQuantity,
		&line.InvoicedQuantity,
		&line.UnitCost,
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
		return PurchaseOrderLine{}, ErrPurchaseOrderNotFound
	}

	if err != nil {
		return PurchaseOrderLine{}, err
	}

	line.Status = ProcurementLineStatus(status)

	return line, nil
}

func procurementNilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}
