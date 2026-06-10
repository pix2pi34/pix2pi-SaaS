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

var _ SalesInvoiceRepository = (*PostgresSalesInvoiceRepository)(nil)

type PostgresSalesInvoiceRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresSalesInvoiceRepository(pool *pgxpool.Pool) *PostgresSalesInvoiceRepository {
	return &PostgresSalesInvoiceRepository{pool: pool}
}

func (r *PostgresSalesInvoiceRepository) CreateSalesInvoice(ctx context.Context, input CreateSalesInvoiceInput) (SalesInvoice, error) {
	if err := ValidateCreateSalesInvoiceInput(input); err != nil {
		return SalesInvoice{}, err
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

	invoiceType := input.InvoiceType
	if strings.TrimSpace(string(invoiceType)) == "" {
		invoiceType = SalesInvoiceTypeSales
	}

	eDocumentStatus := input.EDocumentStatus
	if strings.TrimSpace(string(eDocumentStatus)) == "" {
		eDocumentStatus = EDocumentStatusNone
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return SalesInvoice{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_sales_invoices (
    tenant_id,
    sales_invoice_no,
    sales_order_id,
    delivery_id,
    customer_id,
    party_id,
    invoice_type,
    document_date,
    due_date,
    currency_code,
    exchange_rate,
    subtotal_amount,
    discount_amount,
    vat_amount,
    total_amount,
    paid_amount,
    remaining_amount,
    e_document_status,
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
    $14,
    $15,
    $16,
    $17,
    $18,
    'draft',
    NULLIF($19, ''),
    NULLIF($20, '')
)
RETURNING
    sales_invoice_id::text,
    tenant_id,
    sales_invoice_no,
    COALESCE(sales_order_id::text, ''),
    COALESCE(delivery_id::text, ''),
    customer_id::text,
    party_id::text,
    invoice_type,
    document_date,
    due_date,
    currency_code,
    exchange_rate::float8,
    subtotal_amount::float8,
    discount_amount::float8,
    vat_amount::float8,
    total_amount::float8,
    paid_amount::float8,
    remaining_amount::float8,
    e_document_status,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.SalesInvoiceNo),
		salesNilIfEmpty(input.SalesOrderID),
		salesNilIfEmpty(input.DeliveryID),
		input.CustomerID,
		input.PartyID,
		string(invoiceType),
		documentDate,
		input.DueDate,
		currencyCode,
		exchangeRate,
		input.SubtotalAmount,
		input.DiscountAmount,
		input.VATAmount,
		input.TotalAmount,
		input.PaidAmount,
		input.RemainingAmount,
		string(eDocumentStatus),
		input.Note,
		input.CreatedBy,
	)

	invoice, err := scanSalesInvoice(row)
	if err != nil {
		return SalesInvoice{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesInvoice{}, err
	}

	return invoice, nil
}

func (r *PostgresSalesInvoiceRepository) CreateSalesInvoiceLine(ctx context.Context, input CreateSalesInvoiceLineInput) (SalesInvoiceLine, error) {
	if err := ValidateCreateSalesInvoiceLineInput(input); err != nil {
		return SalesInvoiceLine{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return SalesInvoiceLine{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_sales_invoice_lines (
    tenant_id,
    sales_invoice_id,
    sales_order_line_id,
    delivery_line_id,
    line_no,
    item_id,
    product_id,
    unit_id,
    description,
    quantity,
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
    $8,
    NULLIF($9, ''),
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
    sales_invoice_line_id::text,
    tenant_id,
    sales_invoice_id::text,
    COALESCE(sales_order_line_id::text, ''),
    COALESCE(delivery_line_id::text, ''),
    line_no,
    item_id::text,
    COALESCE(product_id::text, ''),
    unit_id::text,
    COALESCE(description, ''),
    quantity::float8,
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
		input.SalesInvoiceID,
		salesNilIfEmpty(input.SalesOrderLineID),
		salesNilIfEmpty(input.DeliveryLineID),
		input.LineNo,
		input.ItemID,
		salesNilIfEmpty(input.ProductID),
		input.UnitID,
		input.Description,
		input.Quantity,
		input.UnitPrice,
		input.DiscountRate,
		input.DiscountAmount,
		input.VATRate,
		input.VATAmount,
		input.LineTotal,
		input.CreatedBy,
	)

	line, err := scanSalesInvoiceLine(row)
	if err != nil {
		return SalesInvoiceLine{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesInvoiceLine{}, err
	}

	return line, nil
}

func (r *PostgresSalesInvoiceRepository) GetSalesInvoiceByID(ctx context.Context, tenantID string, salesInvoiceID string) (SalesInvoice, error) {
	if strings.TrimSpace(tenantID) == "" {
		return SalesInvoice{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return SalesInvoice{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    sales_invoice_id::text,
    tenant_id,
    sales_invoice_no,
    COALESCE(sales_order_id::text, ''),
    COALESCE(delivery_id::text, ''),
    customer_id::text,
    party_id::text,
    invoice_type,
    document_date,
    due_date,
    currency_code,
    exchange_rate::float8,
    subtotal_amount::float8,
    discount_amount::float8,
    vat_amount::float8,
    total_amount::float8,
    paid_amount::float8,
    remaining_amount::float8,
    e_document_status,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_sales_invoices
WHERE tenant_id = $1
  AND sales_invoice_id = $2
  AND deleted_at IS NULL;
`, tenantID, salesInvoiceID)

	invoice, err := scanSalesInvoice(row)
	if err != nil {
		return SalesInvoice{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesInvoice{}, err
	}

	return invoice, nil
}

func (r *PostgresSalesInvoiceRepository) ListSalesInvoices(ctx context.Context, tenantID string, filter ListSalesInvoicesFilter) ([]SalesInvoice, error) {
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
    sales_invoice_id::text,
    tenant_id,
    sales_invoice_no,
    COALESCE(sales_order_id::text, ''),
    COALESCE(delivery_id::text, ''),
    customer_id::text,
    party_id::text,
    invoice_type,
    document_date,
    due_date,
    currency_code,
    exchange_rate::float8,
    subtotal_amount::float8,
    discount_amount::float8,
    vat_amount::float8,
    total_amount::float8,
    paid_amount::float8,
    remaining_amount::float8,
    e_document_status,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_sales_invoices
WHERE tenant_id = $1
  AND ($2::uuid IS NULL OR customer_id = $2::uuid)
  AND ($3::uuid IS NULL OR sales_order_id = $3::uuid)
  AND ($4::uuid IS NULL OR delivery_id = $4::uuid)
  AND ($5::text = '' OR (
      sales_invoice_no ILIKE '%' || $5 || '%'
      OR COALESCE(note, '') ILIKE '%' || $5 || '%'
  ))
  AND ($6::text = '' OR status = $6)
  AND deleted_at IS NULL
ORDER BY document_date DESC, sales_invoice_no DESC
LIMIT $7 OFFSET $8;
`,
		tenantID,
		salesNilIfEmpty(filter.CustomerID),
		salesNilIfEmpty(filter.SalesOrderID),
		salesNilIfEmpty(filter.DeliveryID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	invoices := make([]SalesInvoice, 0)

	for rows.Next() {
		invoice, err := scanSalesInvoice(rows)
		if err != nil {
			return nil, err
		}

		invoices = append(invoices, invoice)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return invoices, nil
}

func (r *PostgresSalesInvoiceRepository) ListSalesInvoiceLines(ctx context.Context, tenantID string, salesInvoiceID string) ([]SalesInvoiceLine, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrTenantRequired
	}

	if strings.TrimSpace(salesInvoiceID) == "" {
		return nil, ErrSalesInvoiceIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
SELECT
    sales_invoice_line_id::text,
    tenant_id,
    sales_invoice_id::text,
    COALESCE(sales_order_line_id::text, ''),
    COALESCE(delivery_line_id::text, ''),
    line_no,
    item_id::text,
    COALESCE(product_id::text, ''),
    unit_id::text,
    COALESCE(description, ''),
    quantity::float8,
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
FROM erp_sales_invoice_lines
WHERE tenant_id = $1
  AND sales_invoice_id = $2
  AND deleted_at IS NULL
ORDER BY line_no ASC;
`, tenantID, salesInvoiceID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lines := make([]SalesInvoiceLine, 0)

	for rows.Next() {
		line, err := scanSalesInvoiceLine(rows)
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

func (r *PostgresSalesInvoiceRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type salesInvoiceScanner interface {
	Scan(dest ...any) error
}

func scanSalesInvoice(scanner salesInvoiceScanner) (SalesInvoice, error) {
	var invoice SalesInvoice
	var invoiceType string
	var eDocumentStatus string
	var status string
	var dueDate pgtype.Date

	err := scanner.Scan(
		&invoice.SalesInvoiceID,
		&invoice.TenantID,
		&invoice.SalesInvoiceNo,
		&invoice.SalesOrderID,
		&invoice.DeliveryID,
		&invoice.CustomerID,
		&invoice.PartyID,
		&invoiceType,
		&invoice.DocumentDate,
		&dueDate,
		&invoice.CurrencyCode,
		&invoice.ExchangeRate,
		&invoice.SubtotalAmount,
		&invoice.DiscountAmount,
		&invoice.VATAmount,
		&invoice.TotalAmount,
		&invoice.PaidAmount,
		&invoice.RemainingAmount,
		&eDocumentStatus,
		&status,
		&invoice.Note,
		&invoice.CreatedAt,
		&invoice.UpdatedAt,
		&invoice.CreatedBy,
		&invoice.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return SalesInvoice{}, ErrSalesInvoiceNotFound
	}

	if err != nil {
		return SalesInvoice{}, err
	}

	if dueDate.Valid {
		t := dueDate.Time
		invoice.DueDate = &t
	}

	invoice.InvoiceType = SalesInvoiceType(invoiceType)
	invoice.EDocumentStatus = EDocumentStatus(eDocumentStatus)
	invoice.Status = SalesInvoiceStatus(status)

	return invoice, nil
}

func scanSalesInvoiceLine(scanner salesInvoiceScanner) (SalesInvoiceLine, error) {
	var line SalesInvoiceLine
	var status string

	err := scanner.Scan(
		&line.SalesInvoiceLineID,
		&line.TenantID,
		&line.SalesInvoiceID,
		&line.SalesOrderLineID,
		&line.DeliveryLineID,
		&line.LineNo,
		&line.ItemID,
		&line.ProductID,
		&line.UnitID,
		&line.Description,
		&line.Quantity,
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
		return SalesInvoiceLine{}, ErrSalesInvoiceNotFound
	}

	if err != nil {
		return SalesInvoiceLine{}, err
	}

	line.Status = SalesLineStatus(status)

	return line, nil
}
