package cashbank

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ PaymentTransactionRepository = (*PostgresPaymentTransactionRepository)(nil)

type PostgresPaymentTransactionRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresPaymentTransactionRepository(pool *pgxpool.Pool) *PostgresPaymentTransactionRepository {
	return &PostgresPaymentTransactionRepository{pool: pool}
}

func (r *PostgresPaymentTransactionRepository) CreatePaymentTransaction(ctx context.Context, input CreatePaymentTransactionInput) (PaymentTransaction, error) {
	if err := ValidateCreatePaymentTransactionInput(input); err != nil {
		return PaymentTransaction{}, err
	}

	paymentDate := input.PaymentDate
	if paymentDate.IsZero() {
		paymentDate = time.Now().UTC()
	}

	currencyCode := strings.ToUpper(strings.TrimSpace(input.CurrencyCode))
	if currencyCode == "" {
		currencyCode = "TRY"
	}

	sourceModule := input.SourceModule
	if strings.TrimSpace(string(sourceModule)) == "" {
		sourceModule = PaymentSourceManual
	}

	status := input.Status
	if strings.TrimSpace(string(status)) == "" {
		status = PaymentStatusDraft
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return PaymentTransaction{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_payment_transactions (
    tenant_id,
    payment_no,
    payment_date,
    payment_type,
    payment_direction,
    payment_method,
    cash_account_id,
    bank_account_id,
    party_id,
    customer_id,
    vendor_id,
    source_module,
    source_document_type,
    source_document_id,
    journal_entry_id,
    currency_code,
    exchange_rate,
    amount,
    local_amount,
    fee_amount,
    local_fee_amount,
    net_amount,
    local_net_amount,
    description,
    status,
    posted_at,
    posted_by,
    cancelled_at,
    cancelled_by,
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
    NULLIF($13, ''),
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
    NULLIF($24, ''),
    $25,
    $26,
    NULLIF($27, ''),
    $28,
    NULLIF($29, ''),
    NULLIF($30, '')
)
RETURNING
    payment_transaction_id::text,
    tenant_id,
    payment_no,
    payment_date,
    payment_type,
    payment_direction,
    payment_method,
    COALESCE(cash_account_id::text, ''),
    COALESCE(bank_account_id::text, ''),
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
    COALESCE(journal_entry_id::text, ''),
    currency_code,
    exchange_rate::float8,
    amount::float8,
    local_amount::float8,
    fee_amount::float8,
    local_fee_amount::float8,
    net_amount::float8,
    local_net_amount::float8,
    COALESCE(description, ''),
    status,
    posted_at,
    COALESCE(posted_by, ''),
    cancelled_at,
    COALESCE(cancelled_by, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.PaymentNo),
		paymentDate,
		string(input.PaymentType),
		string(input.PaymentDirection),
		string(input.PaymentMethod),
		cashBankNilIfEmpty(input.CashAccountID),
		cashBankNilIfEmpty(input.BankAccountID),
		cashBankNilIfEmpty(input.PartyID),
		cashBankNilIfEmpty(input.CustomerID),
		cashBankNilIfEmpty(input.VendorID),
		string(sourceModule),
		input.SourceDocumentType,
		cashBankNilIfEmpty(input.SourceDocumentID),
		cashBankNilIfEmpty(input.JournalEntryID),
		currencyCode,
		input.ExchangeRate,
		input.Amount,
		input.LocalAmount,
		input.FeeAmount,
		input.LocalFeeAmount,
		input.NetAmount,
		input.LocalNetAmount,
		input.Description,
		string(status),
		input.PostedAt,
		input.PostedBy,
		input.CancelledAt,
		input.CancelledBy,
		input.CreatedBy,
	)

	payment, err := scanPaymentTransaction(row)
	if err != nil {
		return PaymentTransaction{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PaymentTransaction{}, err
	}

	return payment, nil
}

func (r *PostgresPaymentTransactionRepository) GetPaymentTransactionByID(ctx context.Context, tenantID string, paymentTransactionID string) (PaymentTransaction, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PaymentTransaction{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return PaymentTransaction{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    payment_transaction_id::text,
    tenant_id,
    payment_no,
    payment_date,
    payment_type,
    payment_direction,
    payment_method,
    COALESCE(cash_account_id::text, ''),
    COALESCE(bank_account_id::text, ''),
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
    COALESCE(journal_entry_id::text, ''),
    currency_code,
    exchange_rate::float8,
    amount::float8,
    local_amount::float8,
    fee_amount::float8,
    local_fee_amount::float8,
    net_amount::float8,
    local_net_amount::float8,
    COALESCE(description, ''),
    status,
    posted_at,
    COALESCE(posted_by, ''),
    cancelled_at,
    COALESCE(cancelled_by, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_payment_transactions
WHERE tenant_id = $1
  AND payment_transaction_id = $2
  AND deleted_at IS NULL;
`, tenantID, paymentTransactionID)

	payment, err := scanPaymentTransaction(row)
	if err != nil {
		return PaymentTransaction{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PaymentTransaction{}, err
	}

	return payment, nil
}

func (r *PostgresPaymentTransactionRepository) GetPaymentTransactionByNo(ctx context.Context, tenantID string, paymentNo string) (PaymentTransaction, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PaymentTransaction{}, ErrTenantRequired
	}

	if strings.TrimSpace(paymentNo) == "" {
		return PaymentTransaction{}, ErrPaymentNoRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return PaymentTransaction{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    payment_transaction_id::text,
    tenant_id,
    payment_no,
    payment_date,
    payment_type,
    payment_direction,
    payment_method,
    COALESCE(cash_account_id::text, ''),
    COALESCE(bank_account_id::text, ''),
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
    COALESCE(journal_entry_id::text, ''),
    currency_code,
    exchange_rate::float8,
    amount::float8,
    local_amount::float8,
    fee_amount::float8,
    local_fee_amount::float8,
    net_amount::float8,
    local_net_amount::float8,
    COALESCE(description, ''),
    status,
    posted_at,
    COALESCE(posted_by, ''),
    cancelled_at,
    COALESCE(cancelled_by, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_payment_transactions
WHERE tenant_id = $1
  AND payment_no = $2
  AND deleted_at IS NULL;
`, tenantID, strings.TrimSpace(paymentNo))

	payment, err := scanPaymentTransaction(row)
	if err != nil {
		return PaymentTransaction{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return PaymentTransaction{}, err
	}

	return payment, nil
}

func (r *PostgresPaymentTransactionRepository) ListPaymentTransactions(ctx context.Context, tenantID string, filter ListPaymentTransactionsFilter) ([]PaymentTransaction, error) {
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
    payment_transaction_id::text,
    tenant_id,
    payment_no,
    payment_date,
    payment_type,
    payment_direction,
    payment_method,
    COALESCE(cash_account_id::text, ''),
    COALESCE(bank_account_id::text, ''),
    COALESCE(party_id::text, ''),
    COALESCE(customer_id::text, ''),
    COALESCE(vendor_id::text, ''),
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(source_document_id::text, ''),
    COALESCE(journal_entry_id::text, ''),
    currency_code,
    exchange_rate::float8,
    amount::float8,
    local_amount::float8,
    fee_amount::float8,
    local_fee_amount::float8,
    net_amount::float8,
    local_net_amount::float8,
    COALESCE(description, ''),
    status,
    posted_at,
    COALESCE(posted_by, ''),
    cancelled_at,
    COALESCE(cancelled_by, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_payment_transactions
WHERE tenant_id = $1
  AND ($2::text = '' OR payment_type = $2)
  AND ($3::text = '' OR payment_direction = $3)
  AND ($4::text = '' OR payment_method = $4)
  AND ($5::uuid IS NULL OR cash_account_id = $5::uuid)
  AND ($6::uuid IS NULL OR bank_account_id = $6::uuid)
  AND ($7::text = '' OR source_module = $7)
  AND ($8::text = '' OR source_document_type = $8)
  AND ($9::uuid IS NULL OR source_document_id = $9::uuid)
  AND ($10::text = '' OR status = $10)
  AND ($11::text = '' OR (
      payment_no ILIKE '%' || $11 || '%'
      OR COALESCE(description, '') ILIKE '%' || $11 || '%'
      OR COALESCE(source_document_type, '') ILIKE '%' || $11 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY payment_date DESC, payment_no ASC
LIMIT $12 OFFSET $13;
`,
		tenantID,
		string(filter.PaymentType),
		string(filter.PaymentDirection),
		string(filter.PaymentMethod),
		cashBankNilIfEmpty(filter.CashAccountID),
		cashBankNilIfEmpty(filter.BankAccountID),
		string(filter.SourceModule),
		strings.TrimSpace(filter.SourceDocumentType),
		cashBankNilIfEmpty(filter.SourceDocumentID),
		string(filter.Status),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	payments := make([]PaymentTransaction, 0)

	for rows.Next() {
		payment, err := scanPaymentTransaction(rows)
		if err != nil {
			return nil, err
		}

		payments = append(payments, payment)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return payments, nil
}

func (r *PostgresPaymentTransactionRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type paymentTransactionScanner interface {
	Scan(dest ...any) error
}

func scanPaymentTransaction(scanner paymentTransactionScanner) (PaymentTransaction, error) {
	var payment PaymentTransaction
	var paymentDate pgtype.Date
	var paymentType string
	var paymentDirection string
	var paymentMethod string
	var sourceModule string
	var status string
	var postedAt pgtype.Timestamptz
	var cancelledAt pgtype.Timestamptz

	err := scanner.Scan(
		&payment.PaymentTransactionID,
		&payment.TenantID,
		&payment.PaymentNo,
		&paymentDate,
		&paymentType,
		&paymentDirection,
		&paymentMethod,
		&payment.CashAccountID,
		&payment.BankAccountID,
		&payment.PartyID,
		&payment.CustomerID,
		&payment.VendorID,
		&sourceModule,
		&payment.SourceDocumentType,
		&payment.SourceDocumentID,
		&payment.JournalEntryID,
		&payment.CurrencyCode,
		&payment.ExchangeRate,
		&payment.Amount,
		&payment.LocalAmount,
		&payment.FeeAmount,
		&payment.LocalFeeAmount,
		&payment.NetAmount,
		&payment.LocalNetAmount,
		&payment.Description,
		&status,
		&postedAt,
		&payment.PostedBy,
		&cancelledAt,
		&payment.CancelledBy,
		&payment.CreatedAt,
		&payment.UpdatedAt,
		&payment.CreatedBy,
		&payment.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return PaymentTransaction{}, ErrPaymentTransactionNotFound
	}

	if err != nil {
		return PaymentTransaction{}, err
	}

	if paymentDate.Valid {
		payment.PaymentDate = paymentDate.Time
	}

	if postedAt.Valid {
		t := postedAt.Time
		payment.PostedAt = &t
	}

	if cancelledAt.Valid {
		t := cancelledAt.Time
		payment.CancelledAt = &t
	}

	payment.PaymentType = PaymentType(paymentType)
	payment.PaymentDirection = PaymentDirection(paymentDirection)
	payment.PaymentMethod = PaymentMethod(paymentMethod)
	payment.SourceModule = PaymentSourceModule(sourceModule)
	payment.Status = PaymentStatus(status)

	return payment, nil
}
