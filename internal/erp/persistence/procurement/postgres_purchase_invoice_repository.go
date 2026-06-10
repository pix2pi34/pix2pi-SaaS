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

var _ PurchaseInvoiceRepository = (*PostgresPurchaseInvoiceRepository)(nil)

type PostgresPurchaseInvoiceRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresPurchaseInvoiceRepository(pool *pgxpool.Pool) *PostgresPurchaseInvoiceRepository {
	return &PostgresPurchaseInvoiceRepository{pool: pool}
}

func (r *PostgresPurchaseInvoiceRepository) CreatePurchaseInvoice(ctx context.Context, input CreatePurchaseInvoiceInput) (PurchaseInvoice, error) {
	if err := ValidateCreatePurchaseInvoiceInput(input); err != nil {
		return PurchaseInvoice{}, err
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
		invoiceType = PurchaseInvoiceTypePurchase
	}

	eDocumentStatus := input.EDocumentStatus
	if strings.TrimSpace(string(eDocumentStatus)) == "" {
		eDocumentStatus = PurchaseEDocumentStatusNone
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return PurchaseInvoice{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_purchase_invoices (
    tenant_id,
    purchase_invoice_no,
    vendor_invoice_no,
    purchase_order_id,
    purchase_receipt_id,
    vendor_id,
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
    NULLIF($3, ''),
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
    $19,
    'draft',
    NULLIF($20, ''),
    NULLIF($21, '')
)
RETURNING
    purchase_invoice_id::text,
    tenant_id,
    purchase_invoice_no,
    COALESCE(vendor_invoice_no, ''),
    COALESCE(purchase_order_id::text, ''),
    COALESCE(purchase_receipt_id::text, ''),
    vendor_id::text,
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
		strings.TrimSpace(input.PurchaseInvoiceNo),
		input.VendorInvoiceNo,
		procurementNilIfEmpty(input.PurchaseOrderID),
		procurementNilIfEmpty(input.PurchaseReceiptID),
		input.VendorID,
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

	invoice, err := scanPurchaseInvoice(row)
	if err != nil {
		return PurchaseInvoice{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseInvoice{}, err
	}

	return invoice, nil
}

func (r *PostgresPurchaseInvoiceRepository) CreatePurchaseInvoiceLine(ctx context.Context, input CreatePurchaseInvoiceLineInput) (PurchaseInvoiceLine, error) {
	if err := ValidateCreatePurchaseInvoiceLineInput(input); err != nil {
		return PurchaseInvoiceLine{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return PurchaseInvoiceLine{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_purchase_invoice_lines (
    tenant_id,
    purchase_invoice_id,
    purchase_order_line_id,
    purchase_receipt_line_id,
    line_no,
    item_id,
    product_id,
    unit_id,
    description,
    quantity,
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
    purchase_invoice_line_id::text,
    tenant_id,
    purchase_invoice_id::text,
    COALESCE(purchase_order_line_id::text, ''),
    COALESCE(purchase_receipt_line_id::text, ''),
    line_no,
    item_id::text,
    COALESCE(product_id::text, ''),
    unit_id::text,
    COALESCE(description, ''),
    quantity::float8,
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
		input.PurchaseInvoiceID,
		procurementNilIfEmpty(input.PurchaseOrderLineID),
		procurementNilIfEmpty(input.PurchaseReceiptLineID),
		input.LineNo,
		input.ItemID,
		procurementNilIfEmpty(input.ProductID),
		input.UnitID,
		input.Description,
		input.Quantity,
		input.UnitCost,
		input.DiscountRate,
		input.DiscountAmount,
		input.VATRate,
		input.VATAmount,
		input.LineTotal,
		input.CreatedBy,
	)

	line, err := scanPurchaseInvoiceLine(row)
	if err != nil {
		return PurchaseInvoiceLine{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseInvoiceLine{}, err
	}

	return line, nil
}

func (r *PostgresPurchaseInvoiceRepository) GetPurchaseInvoiceByID(ctx context.Context, tenantID string, purchaseInvoiceID string) (PurchaseInvoice, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PurchaseInvoice{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return PurchaseInvoice{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    purchase_invoice_id::text,
    tenant_id,
    purchase_invoice_no,
    COALESCE(vendor_invoice_no, ''),
    COALESCE(purchase_order_id::text, ''),
    COALESCE(purchase_receipt_id::text, ''),
    vendor_id::text,
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
FROM erp_purchase_invoices
WHERE tenant_id = $1
  AND purchase_invoice_id = $2
  AND deleted_at IS NULL;
`, tenantID, purchaseInvoiceID)

	invoice, err := scanPurchaseInvoice(row)
	if err != nil {
		return PurchaseInvoice{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseInvoice{}, err
	}

	return invoice, nil
}

func (r *PostgresPurchaseInvoiceRepository) ListPurchaseInvoices(ctx context.Context, tenantID string, filter ListPurchaseInvoicesFilter) ([]PurchaseInvoice, error) {
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
    purchase_invoice_id::text,
    tenant_id,
    purchase_invoice_no,
    COALESCE(vendor_invoice_no, ''),
    COALESCE(purchase_order_id::text, ''),
    COALESCE(purchase_receipt_id::text, ''),
    vendor_id::text,
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
FROM erp_purchase_invoices
WHERE tenant_id = $1
  AND ($2::uuid IS NULL OR vendor_id = $2::uuid)
  AND ($3::uuid IS NULL OR purchase_order_id = $3::uuid)
  AND ($4::uuid IS NULL OR purchase_receipt_id = $4::uuid)
  AND ($5::text = '' OR (
      purchase_invoice_no ILIKE '%' || $5 || '%'
      OR COALESCE(vendor_invoice_no, '') ILIKE '%' || $5 || '%'
      OR COALESCE(note, '') ILIKE '%' || $5 || '%'
  ))
  AND ($6::text = '' OR status = $6)
  AND deleted_at IS NULL
ORDER BY document_date DESC, purchase_invoice_no DESC
LIMIT $7 OFFSET $8;
`,
		tenantID,
		procurementNilIfEmpty(filter.VendorID),
		procurementNilIfEmpty(filter.PurchaseOrderID),
		procurementNilIfEmpty(filter.PurchaseReceiptID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	invoices := make([]PurchaseInvoice, 0)

	for rows.Next() {
		invoice, err := scanPurchaseInvoice(rows)
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

func (r *PostgresPurchaseInvoiceRepository) ListPurchaseInvoiceLines(ctx context.Context, tenantID string, purchaseInvoiceID string) ([]PurchaseInvoiceLine, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrTenantRequired
	}

	if strings.TrimSpace(purchaseInvoiceID) == "" {
		return nil, ErrPurchaseInvoiceIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
SELECT
    purchase_invoice_line_id::text,
    tenant_id,
    purchase_invoice_id::text,
    COALESCE(purchase_order_line_id::text, ''),
    COALESCE(purchase_receipt_line_id::text, ''),
    line_no,
    item_id::text,
    COALESCE(product_id::text, ''),
    unit_id::text,
    COALESCE(description, ''),
    quantity::float8,
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
FROM erp_purchase_invoice_lines
WHERE tenant_id = $1
  AND purchase_invoice_id = $2
  AND deleted_at IS NULL
ORDER BY line_no ASC;
`, tenantID, purchaseInvoiceID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lines := make([]PurchaseInvoiceLine, 0)

	for rows.Next() {
		line, err := scanPurchaseInvoiceLine(rows)
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

func (r *PostgresPurchaseInvoiceRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type purchaseInvoiceScanner interface {
	Scan(dest ...any) error
}

func scanPurchaseInvoice(scanner purchaseInvoiceScanner) (PurchaseInvoice, error) {
	var invoice PurchaseInvoice
	var invoiceType string
	var eDocumentStatus string
	var status string
	var dueDate pgtype.Date

	err := scanner.Scan(
		&invoice.PurchaseInvoiceID,
		&invoice.TenantID,
		&invoice.PurchaseInvoiceNo,
		&invoice.VendorInvoiceNo,
		&invoice.PurchaseOrderID,
		&invoice.PurchaseReceiptID,
		&invoice.VendorID,
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
		return PurchaseInvoice{}, ErrPurchaseInvoiceNotFound
	}

	if err != nil {
		return PurchaseInvoice{}, err
	}

	if dueDate.Valid {
		t := dueDate.Time
		invoice.DueDate = &t
	}

	invoice.InvoiceType = PurchaseInvoiceType(invoiceType)
	invoice.EDocumentStatus = PurchaseEDocumentStatus(eDocumentStatus)
	invoice.Status = PurchaseInvoiceStatus(status)

	return invoice, nil
}

func scanPurchaseInvoiceLine(scanner purchaseInvoiceScanner) (PurchaseInvoiceLine, error) {
	var line PurchaseInvoiceLine
	var status string

	err := scanner.Scan(
		&line.PurchaseInvoiceLineID,
		&line.TenantID,
		&line.PurchaseInvoiceID,
		&line.PurchaseOrderLineID,
		&line.PurchaseReceiptLineID,
		&line.LineNo,
		&line.ItemID,
		&line.ProductID,
		&line.UnitID,
		&line.Description,
		&line.Quantity,
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
		return PurchaseInvoiceLine{}, ErrPurchaseInvoiceNotFound
	}

	if err != nil {
		return PurchaseInvoiceLine{}, err
	}

	line.Status = ProcurementLineStatus(status)

	return line, nil
}
