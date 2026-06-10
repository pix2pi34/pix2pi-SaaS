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

var _ PurchaseReceiptRepository = (*PostgresPurchaseReceiptRepository)(nil)

type PostgresPurchaseReceiptRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresPurchaseReceiptRepository(pool *pgxpool.Pool) *PostgresPurchaseReceiptRepository {
	return &PostgresPurchaseReceiptRepository{pool: pool}
}

func (r *PostgresPurchaseReceiptRepository) CreatePurchaseReceipt(ctx context.Context, input CreatePurchaseReceiptInput) (PurchaseReceipt, error) {
	if err := ValidateCreatePurchaseReceiptInput(input); err != nil {
		return PurchaseReceipt{}, err
	}

	documentDate := input.DocumentDate
	if documentDate.IsZero() {
		documentDate = time.Now().UTC()
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return PurchaseReceipt{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_purchase_receipts (
    tenant_id,
    purchase_receipt_no,
    purchase_order_id,
    vendor_id,
    party_id,
    warehouse_id,
    document_date,
    receipt_date,
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
    purchase_receipt_id::text,
    tenant_id,
    purchase_receipt_no,
    COALESCE(purchase_order_id::text, ''),
    vendor_id::text,
    party_id::text,
    warehouse_id::text,
    document_date,
    receipt_date,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.PurchaseReceiptNo),
		procurementNilIfEmpty(input.PurchaseOrderID),
		input.VendorID,
		input.PartyID,
		input.WarehouseID,
		documentDate,
		input.ReceiptDate,
		input.Note,
		input.CreatedBy,
	)

	receipt, err := scanPurchaseReceipt(row)
	if err != nil {
		return PurchaseReceipt{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseReceipt{}, err
	}

	return receipt, nil
}

func (r *PostgresPurchaseReceiptRepository) CreatePurchaseReceiptLine(ctx context.Context, input CreatePurchaseReceiptLineInput) (PurchaseReceiptLine, error) {
	if err := ValidateCreatePurchaseReceiptLineInput(input); err != nil {
		return PurchaseReceiptLine{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return PurchaseReceiptLine{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_purchase_receipt_lines (
    tenant_id,
    purchase_receipt_id,
    purchase_order_line_id,
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
    purchase_receipt_line_id::text,
    tenant_id,
    purchase_receipt_id::text,
    COALESCE(purchase_order_line_id::text, ''),
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
		input.PurchaseReceiptID,
		procurementNilIfEmpty(input.PurchaseOrderLineID),
		input.LineNo,
		input.ItemID,
		procurementNilIfEmpty(input.ProductID),
		input.UnitID,
		input.Description,
		input.Quantity,
		input.CreatedBy,
	)

	line, err := scanPurchaseReceiptLine(row)
	if err != nil {
		return PurchaseReceiptLine{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseReceiptLine{}, err
	}

	return line, nil
}

func (r *PostgresPurchaseReceiptRepository) GetPurchaseReceiptByID(ctx context.Context, tenantID string, purchaseReceiptID string) (PurchaseReceipt, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PurchaseReceipt{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return PurchaseReceipt{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    purchase_receipt_id::text,
    tenant_id,
    purchase_receipt_no,
    COALESCE(purchase_order_id::text, ''),
    vendor_id::text,
    party_id::text,
    warehouse_id::text,
    document_date,
    receipt_date,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_purchase_receipts
WHERE tenant_id = $1
  AND purchase_receipt_id = $2
  AND deleted_at IS NULL;
`, tenantID, purchaseReceiptID)

	receipt, err := scanPurchaseReceipt(row)
	if err != nil {
		return PurchaseReceipt{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PurchaseReceipt{}, err
	}

	return receipt, nil
}

func (r *PostgresPurchaseReceiptRepository) ListPurchaseReceipts(ctx context.Context, tenantID string, filter ListPurchaseReceiptsFilter) ([]PurchaseReceipt, error) {
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
    purchase_receipt_id::text,
    tenant_id,
    purchase_receipt_no,
    COALESCE(purchase_order_id::text, ''),
    vendor_id::text,
    party_id::text,
    warehouse_id::text,
    document_date,
    receipt_date,
    status,
    COALESCE(note, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_purchase_receipts
WHERE tenant_id = $1
  AND ($2::uuid IS NULL OR vendor_id = $2::uuid)
  AND ($3::uuid IS NULL OR purchase_order_id = $3::uuid)
  AND ($4::uuid IS NULL OR warehouse_id = $4::uuid)
  AND ($5::text = '' OR (
      purchase_receipt_no ILIKE '%' || $5 || '%'
      OR COALESCE(note, '') ILIKE '%' || $5 || '%'
  ))
  AND ($6::text = '' OR status = $6)
  AND deleted_at IS NULL
ORDER BY document_date DESC, purchase_receipt_no DESC
LIMIT $7 OFFSET $8;
`,
		tenantID,
		procurementNilIfEmpty(filter.VendorID),
		procurementNilIfEmpty(filter.PurchaseOrderID),
		procurementNilIfEmpty(filter.WarehouseID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	receipts := make([]PurchaseReceipt, 0)

	for rows.Next() {
		receipt, err := scanPurchaseReceipt(rows)
		if err != nil {
			return nil, err
		}

		receipts = append(receipts, receipt)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return receipts, nil
}

func (r *PostgresPurchaseReceiptRepository) ListPurchaseReceiptLines(ctx context.Context, tenantID string, purchaseReceiptID string) ([]PurchaseReceiptLine, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrTenantRequired
	}

	if strings.TrimSpace(purchaseReceiptID) == "" {
		return nil, ErrPurchaseReceiptIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
SELECT
    purchase_receipt_line_id::text,
    tenant_id,
    purchase_receipt_id::text,
    COALESCE(purchase_order_line_id::text, ''),
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
FROM erp_purchase_receipt_lines
WHERE tenant_id = $1
  AND purchase_receipt_id = $2
  AND deleted_at IS NULL
ORDER BY line_no ASC;
`, tenantID, purchaseReceiptID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lines := make([]PurchaseReceiptLine, 0)

	for rows.Next() {
		line, err := scanPurchaseReceiptLine(rows)
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

func (r *PostgresPurchaseReceiptRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type purchaseReceiptScanner interface {
	Scan(dest ...any) error
}

func scanPurchaseReceipt(scanner purchaseReceiptScanner) (PurchaseReceipt, error) {
	var receipt PurchaseReceipt
	var status string
	var receiptDate pgtype.Date

	err := scanner.Scan(
		&receipt.PurchaseReceiptID,
		&receipt.TenantID,
		&receipt.PurchaseReceiptNo,
		&receipt.PurchaseOrderID,
		&receipt.VendorID,
		&receipt.PartyID,
		&receipt.WarehouseID,
		&receipt.DocumentDate,
		&receiptDate,
		&status,
		&receipt.Note,
		&receipt.CreatedAt,
		&receipt.UpdatedAt,
		&receipt.CreatedBy,
		&receipt.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return PurchaseReceipt{}, ErrPurchaseReceiptNotFound
	}

	if err != nil {
		return PurchaseReceipt{}, err
	}

	if receiptDate.Valid {
		t := receiptDate.Time
		receipt.ReceiptDate = &t
	}

	receipt.Status = PurchaseReceiptStatus(status)

	return receipt, nil
}

func scanPurchaseReceiptLine(scanner purchaseReceiptScanner) (PurchaseReceiptLine, error) {
	var line PurchaseReceiptLine
	var status string

	err := scanner.Scan(
		&line.PurchaseReceiptLineID,
		&line.TenantID,
		&line.PurchaseReceiptID,
		&line.PurchaseOrderLineID,
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
		return PurchaseReceiptLine{}, ErrPurchaseReceiptNotFound
	}

	if err != nil {
		return PurchaseReceiptLine{}, err
	}

	line.Status = ProcurementLineStatus(status)

	return line, nil
}
