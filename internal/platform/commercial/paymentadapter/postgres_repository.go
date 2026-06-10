package paymentadapter

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"
)

const paymentRepositoryDBTimeout = 5 * time.Second

const insertPaymentAttemptSQL = `
INSERT INTO payment_attempts (
	tenant_id,
	attempt_id,
	invoice_id,
	subscription_id,
	provider_code,
	correlation_id,
	request_id,
	idempotency_key,
	amount_minor,
	currency,
	status,
	provider_transaction_id,
	failure_code,
	failure_message,
	created_at,
	updated_at
) VALUES (
	$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, NOW(), NOW()
)`

const updatePaymentAttemptSQL = `
UPDATE payment_attempts
SET
	invoice_id = $3,
	subscription_id = $4,
	provider_code = $5,
	correlation_id = $6,
	request_id = $7,
	idempotency_key = $8,
	amount_minor = $9,
	currency = $10,
	status = $11,
	provider_transaction_id = $12,
	failure_code = $13,
	failure_message = $14,
	updated_at = NOW()
WHERE tenant_id = $1 AND attempt_id = $2`

const selectPaymentAttemptByIDSQL = `
SELECT
	tenant_id,
	attempt_id,
	invoice_id,
	subscription_id,
	provider_code,
	correlation_id,
	request_id,
	idempotency_key,
	amount_minor,
	currency,
	status,
	provider_transaction_id,
	failure_code,
	failure_message
FROM payment_attempts
WHERE tenant_id = $1 AND attempt_id = $2`

const selectPaymentAttemptByIdempotencySQL = `
SELECT
	tenant_id,
	attempt_id,
	invoice_id,
	subscription_id,
	provider_code,
	correlation_id,
	request_id,
	idempotency_key,
	amount_minor,
	currency,
	status,
	provider_transaction_id,
	failure_code,
	failure_message
FROM payment_attempts
WHERE tenant_id = $1 AND idempotency_key = $2`

const deletePaymentAttemptEventsSQL = `
DELETE FROM payment_attempt_events
WHERE tenant_id = $1 AND attempt_id = $2`

const insertPaymentAttemptEventSQL = `
INSERT INTO payment_attempt_events (
	tenant_id,
	attempt_id,
	from_status,
	to_status,
	operation,
	provider_code,
	provider_transaction_id,
	error_code,
	message,
	correlation_id,
	idempotency_key,
	audit_required,
	real_payment,
	occurred_at
) VALUES (
	$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
)`

const selectPaymentAttemptEventsSQL = `
SELECT
	from_status,
	to_status,
	operation,
	provider_code,
	provider_transaction_id,
	error_code,
	message,
	correlation_id,
	idempotency_key,
	audit_required,
	real_payment,
	occurred_at
FROM payment_attempt_events
WHERE tenant_id = $1 AND attempt_id = $2
ORDER BY event_id ASC`

type PostgreSQLPaymentAttemptRepository struct {
	db *sql.DB
}

var _ PaymentAttemptRepository = (*PostgreSQLPaymentAttemptRepository)(nil)

func NewPostgreSQLPaymentAttemptRepository(db *sql.DB) (*PostgreSQLPaymentAttemptRepository, error) {
	if db == nil {
		return nil, errors.New("postgres payment attempt repository requires db")
	}

	return &PostgreSQLPaymentAttemptRepository{db: db}, nil
}

func (r *PostgreSQLPaymentAttemptRepository) Save(attempt PaymentAttempt) error {
	if err := validatePaymentAttemptForRepository(attempt); err != nil {
		return err
	}

	ctx, cancel := paymentRepositoryContext()
	defer cancel()

	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin payment attempt save tx failed: %w", err)
	}
	defer rollbackPaymentTx(tx)

	if _, err := tx.ExecContext(ctx, insertPaymentAttemptSQL, paymentAttemptSQLArgs(attempt)...); err != nil {
		return mapPaymentPersistenceError(err)
	}

	if err := insertPaymentAttemptEvents(ctx, tx, attempt.TenantID, attempt.AttemptID, attempt.Events); err != nil {
		return err
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit payment attempt save tx failed: %w", err)
	}

	return nil
}

func (r *PostgreSQLPaymentAttemptRepository) Update(attempt PaymentAttempt) error {
	if err := validatePaymentAttemptForRepository(attempt); err != nil {
		return err
	}

	ctx, cancel := paymentRepositoryContext()
	defer cancel()

	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin payment attempt update tx failed: %w", err)
	}
	defer rollbackPaymentTx(tx)

	result, err := tx.ExecContext(ctx, updatePaymentAttemptSQL, paymentAttemptSQLArgs(attempt)...)
	if err != nil {
		return mapPaymentPersistenceError(err)
	}

	affected, err := result.RowsAffected()
	if err == nil && affected == 0 {
		return ErrPaymentAttemptNotFound
	}

	if _, err := tx.ExecContext(ctx, deletePaymentAttemptEventsSQL, attempt.TenantID, attempt.AttemptID); err != nil {
		return fmt.Errorf("delete payment attempt events failed: %w", err)
	}

	if err := insertPaymentAttemptEvents(ctx, tx, attempt.TenantID, attempt.AttemptID, attempt.Events); err != nil {
		return err
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit payment attempt update tx failed: %w", err)
	}

	return nil
}

func (r *PostgreSQLPaymentAttemptRepository) FindByAttemptID(tenantID string, attemptID string) (PaymentAttempt, bool, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PaymentAttempt{}, false, fmt.Errorf("%w: tenant id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attemptID) == "" {
		return PaymentAttempt{}, false, fmt.Errorf("%w: attempt id is required", ErrInvalidPaymentAttempt)
	}

	ctx, cancel := paymentRepositoryContext()
	defer cancel()

	attempt, found, err := scanPaymentAttempt(r.db.QueryRowContext(ctx, selectPaymentAttemptByIDSQL, tenantID, attemptID))
	if err != nil || !found {
		return attempt, found, err
	}

	events, err := r.ListEvents(tenantID, attemptID)
	if err != nil {
		return PaymentAttempt{}, false, err
	}
	attempt.Events = events

	return attempt, true, nil
}

func (r *PostgreSQLPaymentAttemptRepository) FindByIdempotencyKey(tenantID string, idempotencyKey string) (PaymentAttempt, bool, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PaymentAttempt{}, false, fmt.Errorf("%w: tenant id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(idempotencyKey) == "" {
		return PaymentAttempt{}, false, fmt.Errorf("%w: idempotency key is required", ErrInvalidPaymentAttempt)
	}

	ctx, cancel := paymentRepositoryContext()
	defer cancel()

	attempt, found, err := scanPaymentAttempt(r.db.QueryRowContext(ctx, selectPaymentAttemptByIdempotencySQL, tenantID, idempotencyKey))
	if err != nil || !found {
		return attempt, found, err
	}

	events, err := r.ListEvents(tenantID, attempt.AttemptID)
	if err != nil {
		return PaymentAttempt{}, false, err
	}
	attempt.Events = events

	return attempt, true, nil
}

func (r *PostgreSQLPaymentAttemptRepository) AppendEvent(tenantID string, attemptID string, event PaymentAttemptEvent) error {
	if strings.TrimSpace(tenantID) == "" {
		return fmt.Errorf("%w: tenant id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attemptID) == "" {
		return fmt.Errorf("%w: attempt id is required", ErrInvalidPaymentAttempt)
	}

	ctx, cancel := paymentRepositoryContext()
	defer cancel()

	if _, exists, err := r.FindByAttemptID(tenantID, attemptID); err != nil {
		return err
	} else if !exists {
		return ErrPaymentAttemptNotFound
	}

	if _, err := r.db.ExecContext(ctx, insertPaymentAttemptEventSQL, paymentAttemptEventSQLArgs(tenantID, attemptID, event)...); err != nil {
		return fmt.Errorf("append payment attempt event failed: %w", err)
	}

	return nil
}

func (r *PostgreSQLPaymentAttemptRepository) ListEvents(tenantID string, attemptID string) ([]PaymentAttemptEvent, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, fmt.Errorf("%w: tenant id is required", ErrInvalidPaymentAttempt)
	}
	if strings.TrimSpace(attemptID) == "" {
		return nil, fmt.Errorf("%w: attempt id is required", ErrInvalidPaymentAttempt)
	}

	ctx, cancel := paymentRepositoryContext()
	defer cancel()

	rows, err := r.db.QueryContext(ctx, selectPaymentAttemptEventsSQL, tenantID, attemptID)
	if err != nil {
		return nil, fmt.Errorf("list payment attempt events failed: %w", err)
	}
	defer rows.Close()

	var events []PaymentAttemptEvent
	for rows.Next() {
		event, err := scanPaymentAttemptEvent(rows)
		if err != nil {
			return nil, err
		}
		events = append(events, event)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("scan payment attempt events failed: %w", err)
	}

	return events, nil
}

type paymentAttemptScanner interface {
	Scan(dest ...any) error
}

func scanPaymentAttempt(scanner paymentAttemptScanner) (PaymentAttempt, bool, error) {
	var (
		attempt               PaymentAttempt
		providerTransactionID sql.NullString
		failureCode           sql.NullString
		failureMessage        sql.NullString
	)

	err := scanner.Scan(
		&attempt.TenantID,
		&attempt.AttemptID,
		&attempt.InvoiceID,
		&attempt.SubscriptionID,
		&attempt.ProviderCode,
		&attempt.CorrelationID,
		&attempt.RequestID,
		&attempt.IdempotencyKey,
		&attempt.Money.AmountMinor,
		&attempt.Money.Currency,
		&attempt.Status,
		&providerTransactionID,
		&failureCode,
		&failureMessage,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return PaymentAttempt{}, false, nil
	}
	if err != nil {
		return PaymentAttempt{}, false, fmt.Errorf("scan payment attempt failed: %w", err)
	}

	attempt.ProviderTransactionID = nullableStringValue(providerTransactionID)
	attempt.FailureCode = ContractErrorCode(nullableStringValue(failureCode))
	attempt.FailureMessage = nullableStringValue(failureMessage)

	return attempt, true, nil
}

func scanPaymentAttemptEvent(scanner paymentAttemptScanner) (PaymentAttemptEvent, error) {
	var (
		event                 PaymentAttemptEvent
		providerTransactionID sql.NullString
		errorCode             sql.NullString
	)

	err := scanner.Scan(
		&event.FromStatus,
		&event.ToStatus,
		&event.Operation,
		&event.ProviderCode,
		&providerTransactionID,
		&errorCode,
		&event.Message,
		&event.CorrelationID,
		&event.IdempotencyKey,
		&event.AuditRequired,
		&event.RealPayment,
		&event.OccurredAt,
	)
	if err != nil {
		return PaymentAttemptEvent{}, fmt.Errorf("scan payment attempt event failed: %w", err)
	}

	event.ProviderTransactionID = nullableStringValue(providerTransactionID)
	event.ErrorCode = ContractErrorCode(nullableStringValue(errorCode))
	return event, nil
}

func insertPaymentAttemptEvents(ctx context.Context, tx *sql.Tx, tenantID string, attemptID string, events []PaymentAttemptEvent) error {
	for _, event := range events {
		if _, err := tx.ExecContext(ctx, insertPaymentAttemptEventSQL, paymentAttemptEventSQLArgs(tenantID, attemptID, event)...); err != nil {
			return fmt.Errorf("insert payment attempt event failed: %w", err)
		}
	}
	return nil
}

func paymentAttemptSQLArgs(attempt PaymentAttempt) []any {
	return []any{
		attempt.TenantID,
		attempt.AttemptID,
		attempt.InvoiceID,
		attempt.SubscriptionID,
		attempt.ProviderCode,
		attempt.CorrelationID,
		attempt.RequestID,
		attempt.IdempotencyKey,
		attempt.Money.AmountMinor,
		attempt.Money.Currency,
		string(attempt.Status),
		nullableSQLString(attempt.ProviderTransactionID),
		nullableSQLString(string(attempt.FailureCode)),
		nullableSQLString(attempt.FailureMessage),
	}
}

func paymentAttemptEventSQLArgs(tenantID string, attemptID string, event PaymentAttemptEvent) []any {
	occurredAt := event.OccurredAt
	if occurredAt.IsZero() {
		occurredAt = time.Now().UTC()
	}

	return []any{
		tenantID,
		attemptID,
		string(event.FromStatus),
		string(event.ToStatus),
		string(event.Operation),
		event.ProviderCode,
		nullableSQLString(event.ProviderTransactionID),
		nullableSQLString(string(event.ErrorCode)),
		event.Message,
		event.CorrelationID,
		event.IdempotencyKey,
		event.AuditRequired,
		event.RealPayment,
		occurredAt,
	}
}

func nullableSQLString(value string) sql.NullString {
	trimmed := strings.TrimSpace(value)
	return sql.NullString{String: trimmed, Valid: trimmed != ""}
}

func nullableStringValue(value sql.NullString) string {
	if !value.Valid {
		return ""
	}
	return value.String
}

func paymentRepositoryContext() (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), paymentRepositoryDBTimeout)
}

func rollbackPaymentTx(tx *sql.Tx) {
	_ = tx.Rollback()
}

func mapPaymentPersistenceError(err error) error {
	if err == nil {
		return nil
	}
	msg := strings.ToLower(err.Error())
	switch {
	case strings.Contains(msg, "payment_attempts_pkey"):
		return ErrPaymentAttemptAlreadyExists
	case strings.Contains(msg, "payment_attempts_tenant_idempotency_unique"):
		return ErrPaymentAttemptIdempotencyConflict
	default:
		return fmt.Errorf("payment persistence error: %w", err)
	}
}

func PaymentAttemptPostgreSQLRequiredColumns() []string {
	return []string{
		"tenant_id",
		"attempt_id",
		"invoice_id",
		"provider_code",
		"correlation_id",
		"idempotency_key",
		"amount_minor",
		"currency",
		"status",
	}
}

func PaymentAttemptPostgreSQLTables() []string {
	return []string{
		"payment_attempts",
		"payment_attempt_events",
	}
}
