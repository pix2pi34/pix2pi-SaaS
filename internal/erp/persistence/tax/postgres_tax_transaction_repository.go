package tax

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ TaxTransactionRepository = (*PostgresTaxTransactionRepository)(nil)

type PostgresTaxTransactionRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresTaxTransactionRepository(pool *pgxpool.Pool) *PostgresTaxTransactionRepository {
	return &PostgresTaxTransactionRepository{pool: pool}
}

func (r *PostgresTaxTransactionRepository) CreateTaxTransaction(ctx context.Context, input CreateTaxTransactionInput) (TaxTransaction, error) {
	if err := ValidateCreateTaxTransactionInput(input); err != nil {
		return TaxTransaction{}, err
	}

	transactionDate := input.TransactionDate
	if transactionDate.IsZero() {
		transactionDate = time.Now().UTC()
	}

	currencyCode := strings.ToUpper(strings.TrimSpace(input.CurrencyCode))
	if currencyCode == "" {
		currencyCode = "TRY"
	}

	status := input.Status
	if strings.TrimSpace(string(status)) == "" {
		status = TaxTransactionStatusPosted
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return TaxTransaction{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_tax_transactions (
    tenant_id,
    tax_code_id,
    tax_rate_id,
    tax_code,
    tax_name,
    tax_type,
    source_module,
    source_document_type,
    source_document_id,
    source_line_id,
    journal_entry_id,
    journal_line_id,
    transaction_date,
    fiscal_year,
    fiscal_period,
    base_amount,
    rate_percent,
    tax_amount,
    withholding_numerator,
    withholding_denominator,
    withholding_amount,
    payable_amount,
    recoverable_amount,
    currency_code,
    exchange_rate,
    local_base_amount,
    local_tax_amount,
    direction,
    party_id,
    customer_id,
    vendor_id,
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
    $18,
    $19,
    $20,
    $21,
    $22,
    $23,
    $24,
    $25,
    $26,
    $27,
    $28,
    $29,
    $30,
    $31,
    $32,
    NULLIF($33, '')
)
RETURNING
    tax_transaction_id::text,
    tenant_id,
    COALESCE(tax_code_id::text, ''),
    COALESCE(tax_rate_id::text, ''),
    tax_code,
    COALESCE(tax_name, ''),
    tax_type,
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
    COALESCE(source_line_id::text, ''),
    COALESCE(journal_entry_id::text, ''),
    COALESCE(journal_line_id::text, ''),
    transaction_date,
    fiscal_year,
    fiscal_period,
    base_amount::float8,
    rate_percent::float8,
    tax_amount::float8,
    COALESCE(withholding_numerator, -1),
    COALESCE(withholding_denominator, -1),
    withholding_amount::float8,
    payable_amount::float8,
    recoverable_amount::float8,
    currency_code,
    exchange_rate::float8,
    local_base_amount::float8,
    local_tax_amount::float8,
    direction,
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		taxNilIfEmpty(input.TaxCodeID),
		taxNilIfEmpty(input.TaxRateID),
		strings.TrimSpace(input.TaxCode),
		input.TaxName,
		string(input.TaxType),
		string(input.SourceModule),
		input.SourceDocumentType,
		taxNilIfEmpty(input.SourceDocumentID),
		taxNilIfEmpty(input.SourceLineID),
		taxNilIfEmpty(input.JournalEntryID),
		taxNilIfEmpty(input.JournalLineID),
		transactionDate,
		input.FiscalYear,
		strings.TrimSpace(input.FiscalPeriod),
		input.BaseAmount,
		input.RatePercent,
		input.TaxAmount,
		input.WithholdingNumerator,
		input.WithholdingDenominator,
		input.WithholdingAmount,
		input.PayableAmount,
		input.RecoverableAmount,
		currencyCode,
		input.ExchangeRate,
		input.LocalBaseAmount,
		input.LocalTaxAmount,
		string(input.Direction),
		taxNilIfEmpty(input.PartyID),
		taxNilIfEmpty(input.CustomerID),
		taxNilIfEmpty(input.VendorID),
		string(status),
		input.CreatedBy,
	)

	item, err := scanTaxTransaction(row)
	if err != nil {
		return TaxTransaction{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return TaxTransaction{}, err
	}

	return item, nil
}

func (r *PostgresTaxTransactionRepository) GetTaxTransactionByID(ctx context.Context, tenantID string, taxTransactionID string) (TaxTransaction, error) {
	if strings.TrimSpace(tenantID) == "" {
		return TaxTransaction{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return TaxTransaction{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    tax_transaction_id::text,
    tenant_id,
    COALESCE(tax_code_id::text, ''),
    COALESCE(tax_rate_id::text, ''),
    tax_code,
    COALESCE(tax_name, ''),
    tax_type,
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
    COALESCE(source_line_id::text, ''),
    COALESCE(journal_entry_id::text, ''),
    COALESCE(journal_line_id::text, ''),
    transaction_date,
    fiscal_year,
    fiscal_period,
    base_amount::float8,
    rate_percent::float8,
    tax_amount::float8,
    COALESCE(withholding_numerator, -1),
    COALESCE(withholding_denominator, -1),
    withholding_amount::float8,
    payable_amount::float8,
    recoverable_amount::float8,
    currency_code,
    exchange_rate::float8,
    local_base_amount::float8,
    local_tax_amount::float8,
    direction,
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_tax_transactions
WHERE tenant_id = $1
  AND tax_transaction_id = $2
  AND deleted_at IS NULL;
`, tenantID, taxTransactionID)

	item, err := scanTaxTransaction(row)
	if err != nil {
		return TaxTransaction{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return TaxTransaction{}, err
	}

	return item, nil
}

func (r *PostgresTaxTransactionRepository) ListTaxTransactions(ctx context.Context, tenantID string, filter ListTaxTransactionsFilter) ([]TaxTransaction, error) {
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
    tax_transaction_id::text,
    tenant_id,
    COALESCE(tax_code_id::text, ''),
    COALESCE(tax_rate_id::text, ''),
    tax_code,
    COALESCE(tax_name, ''),
    tax_type,
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
    COALESCE(source_line_id::text, ''),
    COALESCE(journal_entry_id::text, ''),
    COALESCE(journal_line_id::text, ''),
    transaction_date,
    fiscal_year,
    fiscal_period,
    base_amount::float8,
    rate_percent::float8,
    tax_amount::float8,
    COALESCE(withholding_numerator, -1),
    COALESCE(withholding_denominator, -1),
    withholding_amount::float8,
    payable_amount::float8,
    recoverable_amount::float8,
    currency_code,
    exchange_rate::float8,
    local_base_amount::float8,
    local_tax_amount::float8,
    direction,
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_tax_transactions
WHERE tenant_id = $1
  AND ($2::text = '' OR tax_code = $2)
  AND ($3::text = '' OR tax_type = $3)
  AND ($4::text = '' OR source_module = $4)
  AND ($5::text = '' OR source_document_type = $5)
  AND ($6::uuid IS NULL OR source_document_id = $6::uuid)
  AND ($7::int = 0 OR fiscal_year = $7)
  AND ($8::text = '' OR fiscal_period = $8)
  AND ($9::text = '' OR direction = $9)
  AND ($10::text = '' OR status = $10)
  AND ($11::text = '' OR (
      tax_code ILIKE '%' || $11 || '%'
      OR COALESCE(tax_name, '') ILIKE '%' || $11 || '%'
      OR COALESCE(source_document_type, '') ILIKE '%' || $11 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY transaction_date DESC, tax_code ASC, created_at DESC
LIMIT $12 OFFSET $13;
`,
		tenantID,
		strings.TrimSpace(filter.TaxCode),
		string(filter.TaxType),
		string(filter.SourceModule),
		strings.TrimSpace(filter.SourceDocumentType),
		taxNilIfEmpty(filter.SourceDocumentID),
		filter.FiscalYear,
		strings.TrimSpace(filter.FiscalPeriod),
		string(filter.Direction),
		string(filter.Status),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]TaxTransaction, 0)

	for rows.Next() {
		item, err := scanTaxTransaction(rows)
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

func (r *PostgresTaxTransactionRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type taxTransactionScanner interface {
	Scan(dest ...any) error
}

func scanTaxTransaction(scanner taxTransactionScanner) (TaxTransaction, error) {
	var item TaxTransaction
	var transactionDate pgtype.Date
	var taxType string
	var sourceModule string
	var direction string
	var status string
	var withholdingNumerator int
	var withholdingDenominator int

	err := scanner.Scan(
		&item.TaxTransactionID,
		&item.TenantID,
		&item.TaxCodeID,
		&item.TaxRateID,
		&item.TaxCode,
		&item.TaxName,
		&taxType,
		&sourceModule,
		&item.SourceDocumentType,
		&item.SourceDocumentID,
		&item.SourceLineID,
		&item.JournalEntryID,
		&item.JournalLineID,
		&transactionDate,
		&item.FiscalYear,
		&item.FiscalPeriod,
		&item.BaseAmount,
		&item.RatePercent,
		&item.TaxAmount,
		&withholdingNumerator,
		&withholdingDenominator,
		&item.WithholdingAmount,
		&item.PayableAmount,
		&item.RecoverableAmount,
		&item.CurrencyCode,
		&item.ExchangeRate,
		&item.LocalBaseAmount,
		&item.LocalTaxAmount,
		&direction,
		&item.PartyID,
		&item.CustomerID,
		&item.VendorID,
		&status,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.CreatedBy,
		&item.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return TaxTransaction{}, ErrTaxTransactionNotFound
	}

	if err != nil {
		return TaxTransaction{}, err
	}

	if transactionDate.Valid {
		item.TransactionDate = transactionDate.Time
	}

	if withholdingNumerator >= 0 {
		item.WithholdingNumerator = &withholdingNumerator
	}

	if withholdingDenominator >= 0 {
		item.WithholdingDenominator = &withholdingDenominator
	}

	item.TaxType = TaxType(taxType)
	item.SourceModule = TaxSourceModule(sourceModule)
	item.Direction = TaxDirection(direction)
	item.Status = TaxTransactionStatus(status)

	return item, nil
}

func taxNilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}
