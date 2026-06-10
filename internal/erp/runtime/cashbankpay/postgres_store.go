package cashbankpay

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ PaymentStore = (*PostgresPaymentStore)(nil)

type PostgresPaymentStore struct {
	pool *pgxpool.Pool
}

type cashbankColumnInfo struct {
	Name     string
	DataType string
	UDTName  string
}

func NewPostgresPaymentStore(pool *pgxpool.Pool) *PostgresPaymentStore {
	return &PostgresPaymentStore{pool: pool}
}

func (s *PostgresPaymentStore) PersistPaymentDraft(ctx context.Context, draft PaymentDraft) (PaymentDraft, error) {
	if err := ValidatePaymentDraft(draft); err != nil {
		return PaymentDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return PaymentDraft{}, err
	}
	defer tx.Rollback(ctx)

	columns, err := loadCashbankTableColumns(ctx, tx, "erp_payment_transactions")
	if err != nil {
		return PaymentDraft{}, err
	}

	for _, movement := range draft.Movements {
		if err := insertPaymentTransaction(ctx, tx, columns, draft, movement, PaymentStatusDraft); err != nil {
			return PaymentDraft{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return PaymentDraft{}, err
	}

	draft.Status = PaymentStatusDraft
	for i := range draft.Movements {
		draft.Movements[i].Status = PaymentStatusDraft
	}

	return draft, nil
}

func (s *PostgresPaymentStore) MarkPaymentPosted(ctx context.Context, draft PaymentDraft) (PaymentDraft, error) {
	if err := ValidatePaymentDraft(draft); err != nil {
		return PaymentDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return PaymentDraft{}, err
	}
	defer tx.Rollback(ctx)

	columns, err := loadCashbankTableColumns(ctx, tx, "erp_payment_transactions")
	if err != nil {
		return PaymentDraft{}, err
	}

	statusColumn := cashbankStatusColumn(columns)
	if statusColumn != "" {
		setParts := []string{fmt.Sprintf("%s = $2", statusColumn)}
		args := []any{draft.TenantID, cashbankPaymentDBStatus(PaymentStatusPosted)}

		whereParts := []string{"tenant_id = $1"}

		if strings.TrimSpace(draft.PaymentNo) != "" {
			args = append(args, draft.PaymentNo)
			whereParts = append(whereParts, fmt.Sprintf("payment_no = $%d", len(args)))
		} else {
			return PaymentDraft{}, ErrPaymentNotFound
		}

		if _, ok := columns["updated_at"]; ok {
			setParts = append(setParts, "updated_at = now()")
		}

		if _, ok := columns["updated_by"]; ok {
			args = append(args, "runtime")
			setParts = append(setParts, fmt.Sprintf("updated_by = $%d", len(args)))
		}

		if _, ok := columns["posted_at"]; ok {
			setParts = append(setParts, "posted_at = now()")
		}

		if _, ok := columns["posted_by"]; ok {
			args = append(args, "runtime")
			setParts = append(setParts, fmt.Sprintf("posted_by = $%d", len(args)))
		}

		if _, ok := columns["deleted_at"]; ok {
			whereParts = append(whereParts, "deleted_at IS NULL")
		}

		sql := fmt.Sprintf(`
UPDATE erp_payment_transactions
SET %s
WHERE %s;
`, strings.Join(setParts, ", "), strings.Join(whereParts, " AND "))

		commandTag, err := tx.Exec(ctx, sql, args...)
		if err != nil {
			return PaymentDraft{}, err
		}

		if commandTag.RowsAffected() == 0 {
			return PaymentDraft{}, ErrPaymentNotFound
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return PaymentDraft{}, err
	}

	draft.Status = PaymentStatusPosted
	for i := range draft.Movements {
		draft.Movements[i].Status = PaymentStatusPosted
	}

	return draft, nil
}

func (s *PostgresPaymentStore) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		_ = tx.Rollback(ctx)
		return nil, err
	}

	return tx, nil
}

func loadCashbankTableColumns(ctx context.Context, tx pgx.Tx, tableName string) (map[string]cashbankColumnInfo, error) {
	rows, err := tx.Query(ctx, `
SELECT column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = $1;
`, tableName)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	columns := make(map[string]cashbankColumnInfo)

	for rows.Next() {
		var col cashbankColumnInfo
		if err := rows.Scan(&col.Name, &col.DataType, &col.UDTName); err != nil {
			return nil, err
		}

		columns[col.Name] = col
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if len(columns) == 0 {
		return nil, ErrPaymentPersistFailed
	}

	return columns, nil
}

func insertPaymentTransaction(
	ctx context.Context,
	tx pgx.Tx,
	columns map[string]cashbankColumnInfo,
	draft PaymentDraft,
	movement CashBankMovementDraft,
	status PaymentStatus,
) error {
	names := make([]string, 0)
	values := make([]any, 0)

	add := func(column string, value any) {
		if _, ok := columns[column]; !ok {
			return
		}

		names = append(names, column)
		values = append(values, value)
	}

	addUUID := func(column string, value string) {
		if _, ok := columns[column]; !ok {
			return
		}

		names = append(names, column)
		values = append(values, cashbankNullableUUID(columns[column], value))
	}

	add("tenant_id", draft.TenantID)

	add("payment_no", draft.PaymentNo)
	add("transaction_no", draft.PaymentNo)
	add("reference_no", draft.PaymentNo)

	add("payment_direction", cashbankPaymentDBDirection(draft))
	add("direction", cashbankPaymentDBDirection(draft))
	add("payment_type", cashbankPaymentDBType(draft))

	add("payment_method", string(draft.Method))
	add("method", string(draft.Method))

	add("account_type", string(draft.Account.AccountType))
	add("cashbank_account_type", string(draft.Account.AccountType))

	addUUID("account_id", draft.Account.AccountID)
	addUUID("cash_account_id", cashbankCashAccountID(draft.Account))
	addUUID("bank_account_id", cashbankBankAccountID(draft.Account))

	add("account_code", draft.Account.AccountCode)
	add("account_name", cashbankNullableString(draft.Account.AccountName))

	add("amount", draft.Money.Amount)
	add("local_amount", draft.Money.LocalAmount)
	add("signed_amount", movement.SignedAmount)

	add("currency_code", cashbankDefaultCurrency(draft.Money.CurrencyCode))
	add("exchange_rate", cashbankDefaultExchangeRate(draft.Money.ExchangeRate))

	add("payment_date", draft.Fiscal.PaymentDate)
	add("transaction_date", draft.Fiscal.PaymentDate)
	add("posting_date", draft.Fiscal.PaymentDate)

	add("fiscal_year", draft.Fiscal.FiscalYear)
	add("fiscal_period", draft.Fiscal.FiscalPeriod)

	add("source_module", draft.Source.SourceModule)
	add("source_document_type", draft.Source.SourceDocumentType)
	addUUID("source_document_id", draft.Source.SourceDocumentID)
	add("source_document_no", draft.Source.SourceDocumentNo)

	addUUID("party_id", draft.Counterparty.PartyID)
	addUUID("customer_id", draft.Counterparty.CustomerID)
	addUUID("vendor_id", draft.Counterparty.VendorID)
	add("counterparty_name", cashbankNullableString(draft.Counterparty.Name))
	add("party_name", cashbankNullableString(draft.Counterparty.Name))

	statusColumn := cashbankStatusColumn(columns)
	if statusColumn != "" {
		add(statusColumn, cashbankPaymentDBStatus(status))
	}

	add("description", cashbankNullableString(draft.Description))

	add("created_by", "runtime")
	add("updated_by", "runtime")

	if len(names) == 0 {
		return ErrPaymentPersistFailed
	}

	sql := buildCashbankInsertSQL("erp_payment_transactions", names)

	_, err := tx.Exec(ctx, sql, values...)
	return err
}

func buildCashbankInsertSQL(table string, columns []string) string {
	placeholders := make([]string, 0, len(columns))

	for i := range columns {
		placeholders = append(placeholders, fmt.Sprintf("$%d", i+1))
	}

	return fmt.Sprintf(
		"INSERT INTO %s (%s) VALUES (%s);",
		table,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
	)
}

func cashbankPaymentDBDirection(draft PaymentDraft) string {
	switch draft.Direction {
	case PaymentDirectionInflow:
		return "in"
	case PaymentDirectionOutflow:
		return "out"
	default:
		return "in"
	}
}

func cashbankPaymentDBType(draft PaymentDraft) string {
	switch "receipt_payment" {
	case "direction":
		return string(draft.Direction)
	case "receipt_payment":
		if draft.Direction == PaymentDirectionInflow {
			return "collection"
		}
		return "payment"
	case "method":
		return string(draft.Method)
	default:
		return string(draft.Method)
	}
}

func cashbankStatusColumn(columns map[string]cashbankColumnInfo) string {
	if _, ok := columns["payment_status"]; ok {
		return "payment_status"
	}

	if _, ok := columns["status"]; ok {
		return "status"
	}

	return ""
}

func cashbankPaymentDBStatus(status PaymentStatus) string {
	switch status {
	case PaymentStatusDraft:
		return "draft"
	case PaymentStatusPosted:
		return "posted"
	case PaymentStatusCancelled:
		return "cancelled"
	case PaymentStatusReversed:
		return "reversed"
	default:
		return "draft"
	}
}

func cashbankCashAccountID(account AccountRef) string {
	if account.AccountType == AccountTypeCash {
		return account.AccountID
	}

	return ""
}

func cashbankBankAccountID(account AccountRef) string {
	if account.AccountType == AccountTypeBank {
		return account.AccountID
	}

	return ""
}

func cashbankNullableString(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}

func cashbankDefaultCurrency(value string) string {
	if strings.TrimSpace(value) == "" {
		return "TRY"
	}

	return strings.ToUpper(strings.TrimSpace(value))
}

func cashbankDefaultExchangeRate(value float64) float64 {
	if value <= 0 {
		return 1
	}

	return value
}

func cashbankNullableUUID(column cashbankColumnInfo, value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}

	if column.UDTName == "uuid" && !cashbankIsUUID(trimmed) {
		return nil
	}

	return trimmed
}

func cashbankIsUUID(value string) bool {
	matched, _ := regexp.MatchString(`^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$`, value)
	return matched
}

func cashbankPayIsNoRows(err error) bool {
	return errors.Is(err, pgx.ErrNoRows)
}
