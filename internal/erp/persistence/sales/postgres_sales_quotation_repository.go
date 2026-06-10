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

var _ SalesQuotationRepository = (*PostgresSalesQuotationRepository)(nil)

type PostgresSalesQuotationRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresSalesQuotationRepository(pool *pgxpool.Pool) *PostgresSalesQuotationRepository {
	return &PostgresSalesQuotationRepository{pool: pool}
}

func (r *PostgresSalesQuotationRepository) CreateSalesQuotation(ctx context.Context, input CreateSalesQuotationInput) (SalesQuotation, error) {
	if err := ValidateCreateSalesQuotationInput(input); err != nil {
		return SalesQuotation{}, err
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
		return SalesQuotation{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_sales_quotations (
    tenant_id,
    quotation_no,
    customer_id,
    party_id,
    document_date,
    valid_until,
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
    quotation_id::text,
    tenant_id,
    quotation_no,
    customer_id::text,
    party_id::text,
    document_date,
    valid_until,
    currency_code,
    exchange_rate::float8,
    subtotal_amount::float8,
    discount_amount::float8,
    vat_amount::float8,
    total_amount::float8,
    status,
    COALESCE(note, ''),
    COALESCE(converted_order_id::text, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.QuotationNo),
		input.CustomerID,
		input.PartyID,
		documentDate,
		input.ValidUntil,
		currencyCode,
		exchangeRate,
		input.SubtotalAmount,
		input.DiscountAmount,
		input.VATAmount,
		input.TotalAmount,
		input.Note,
		input.CreatedBy,
	)

	quotation, err := scanSalesQuotation(row)
	if err != nil {
		return SalesQuotation{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesQuotation{}, err
	}

	return quotation, nil
}

func (r *PostgresSalesQuotationRepository) CreateSalesQuotationLine(ctx context.Context, input CreateSalesQuotationLineInput) (SalesQuotationLine, error) {
	if err := ValidateCreateSalesQuotationLineInput(input); err != nil {
		return SalesQuotationLine{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return SalesQuotationLine{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_sales_quotation_lines (
    tenant_id,
    quotation_id,
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
    NULLIF($7, ''),
    $8,
    $9,
    $10,
    $11,
    $12,
    $13,
    $14,
    'active',
    NULLIF($15, '')
)
RETURNING
    quotation_line_id::text,
    tenant_id,
    quotation_id::text,
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
		input.QuotationID,
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

	line, err := scanSalesQuotationLine(row)
	if err != nil {
		return SalesQuotationLine{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesQuotationLine{}, err
	}

	return line, nil
}

func (r *PostgresSalesQuotationRepository) GetSalesQuotationByID(ctx context.Context, tenantID string, quotationID string) (SalesQuotation, error) {
	if strings.TrimSpace(tenantID) == "" {
		return SalesQuotation{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return SalesQuotation{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    quotation_id::text,
    tenant_id,
    quotation_no,
    customer_id::text,
    party_id::text,
    document_date,
    valid_until,
    currency_code,
    exchange_rate::float8,
    subtotal_amount::float8,
    discount_amount::float8,
    vat_amount::float8,
    total_amount::float8,
    status,
    COALESCE(note, ''),
    COALESCE(converted_order_id::text, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_sales_quotations
WHERE tenant_id = $1
  AND quotation_id = $2
  AND deleted_at IS NULL;
`, tenantID, quotationID)

	quotation, err := scanSalesQuotation(row)
	if err != nil {
		return SalesQuotation{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return SalesQuotation{}, err
	}

	return quotation, nil
}

func (r *PostgresSalesQuotationRepository) ListSalesQuotations(ctx context.Context, tenantID string, filter ListSalesQuotationsFilter) ([]SalesQuotation, error) {
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
    quotation_id::text,
    tenant_id,
    quotation_no,
    customer_id::text,
    party_id::text,
    document_date,
    valid_until,
    currency_code,
    exchange_rate::float8,
    subtotal_amount::float8,
    discount_amount::float8,
    vat_amount::float8,
    total_amount::float8,
    status,
    COALESCE(note, ''),
    COALESCE(converted_order_id::text, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_sales_quotations
WHERE tenant_id = $1
  AND ($2::uuid IS NULL OR customer_id = $2::uuid)
  AND ($3::text = '' OR (
      quotation_no ILIKE '%' || $3 || '%'
      OR COALESCE(note, '') ILIKE '%' || $3 || '%'
  ))
  AND ($4::text = '' OR status = $4)
  AND deleted_at IS NULL
ORDER BY document_date DESC, quotation_no DESC
LIMIT $5 OFFSET $6;
`,
		tenantID,
		salesNilIfEmpty(filter.CustomerID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	quotations := make([]SalesQuotation, 0)

	for rows.Next() {
		quotation, err := scanSalesQuotation(rows)
		if err != nil {
			return nil, err
		}

		quotations = append(quotations, quotation)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return quotations, nil
}

func (r *PostgresSalesQuotationRepository) ListSalesQuotationLines(ctx context.Context, tenantID string, quotationID string) ([]SalesQuotationLine, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrTenantRequired
	}

	if strings.TrimSpace(quotationID) == "" {
		return nil, ErrQuotationIDRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
SELECT
    quotation_line_id::text,
    tenant_id,
    quotation_id::text,
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
FROM erp_sales_quotation_lines
WHERE tenant_id = $1
  AND quotation_id = $2
  AND deleted_at IS NULL
ORDER BY line_no ASC;
`, tenantID, quotationID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	lines := make([]SalesQuotationLine, 0)

	for rows.Next() {
		line, err := scanSalesQuotationLine(rows)
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

func (r *PostgresSalesQuotationRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type salesQuotationScanner interface {
	Scan(dest ...any) error
}

func scanSalesQuotation(scanner salesQuotationScanner) (SalesQuotation, error) {
	var quotation SalesQuotation
	var status string
	var validUntil pgtype.Date

	err := scanner.Scan(
		&quotation.QuotationID,
		&quotation.TenantID,
		&quotation.QuotationNo,
		&quotation.CustomerID,
		&quotation.PartyID,
		&quotation.DocumentDate,
		&validUntil,
		&quotation.CurrencyCode,
		&quotation.ExchangeRate,
		&quotation.SubtotalAmount,
		&quotation.DiscountAmount,
		&quotation.VATAmount,
		&quotation.TotalAmount,
		&status,
		&quotation.Note,
		&quotation.ConvertedOrderID,
		&quotation.CreatedAt,
		&quotation.UpdatedAt,
		&quotation.CreatedBy,
		&quotation.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return SalesQuotation{}, ErrSalesQuotationNotFound
	}

	if err != nil {
		return SalesQuotation{}, err
	}

	if validUntil.Valid {
		t := validUntil.Time
		quotation.ValidUntil = &t
	}

	quotation.Status = SalesQuotationStatus(status)

	return quotation, nil
}

func scanSalesQuotationLine(scanner salesQuotationScanner) (SalesQuotationLine, error) {
	var line SalesQuotationLine
	var status string

	err := scanner.Scan(
		&line.QuotationLineID,
		&line.TenantID,
		&line.QuotationID,
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
		return SalesQuotationLine{}, ErrSalesQuotationNotFound
	}

	if err != nil {
		return SalesQuotationLine{}, err
	}

	line.Status = SalesLineStatus(status)

	return line, nil
}

func salesNilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}
