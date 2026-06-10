package ledgerpost

import (
	"context"
	"errors"
	"fmt"
	"math"
	"regexp"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ LedgerPostingStore = (*PostgresLedgerPostingStore)(nil)

type PostgresLedgerPostingStore struct {
	pool *pgxpool.Pool
}

type ledgerColumnInfo struct {
	Name     string
	DataType string
	UDTName  string
}

func NewPostgresLedgerPostingStore(pool *pgxpool.Pool) *PostgresLedgerPostingStore {
	return &PostgresLedgerPostingStore{pool: pool}
}

func (s *PostgresLedgerPostingStore) PersistLedgerDraft(ctx context.Context, draft LedgerPostingDraft) (LedgerPostingDraft, error) {
	if err := ValidateLedgerPostingDraft(draft); err != nil {
		return LedgerPostingDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return LedgerPostingDraft{}, err
	}
	defer tx.Rollback(ctx)

	movementColumns, err := loadLedgerTableColumns(ctx, tx, "erp_account_movements")
	if err != nil {
		return LedgerPostingDraft{}, err
	}

	for _, movement := range draft.Movements {
		if err := insertAccountMovement(ctx, tx, movementColumns, draft, movement, LedgerPostingStatusDraft); err != nil {
			return LedgerPostingDraft{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return LedgerPostingDraft{}, err
	}

	draft.Status = LedgerPostingStatusDraft
	return draft, nil
}

func (s *PostgresLedgerPostingStore) MarkLedgerPosted(ctx context.Context, draft LedgerPostingDraft) (LedgerPostingDraft, error) {
	if err := ValidateLedgerPostingDraft(draft); err != nil {
		return LedgerPostingDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return LedgerPostingDraft{}, err
	}
	defer tx.Rollback(ctx)

	movementColumns, err := loadLedgerTableColumns(ctx, tx, "erp_account_movements")
	if err != nil {
		return LedgerPostingDraft{}, err
	}

	if _, ok := movementColumns["status"]; ok {
		setParts := []string{"status = $2"}
		args := []any{
			draft.TenantID,
			ledgerMovementDBStatus(LedgerPostingStatusPosted),
		}

		whereParts := []string{"tenant_id = $1"}

		if _, ok := movementColumns["journal_entry_id"]; ok && strings.TrimSpace(draft.Journal.JournalEntryID) != "" {
			args = append(args, ledgerNullableUUID(movementColumns["journal_entry_id"], draft.Journal.JournalEntryID))
			whereParts = append(whereParts, fmt.Sprintf("journal_entry_id = $%d", len(args)))
		} else if _, ok := movementColumns["journal_no"]; ok && strings.TrimSpace(draft.Journal.JournalNo) != "" {
			args = append(args, draft.Journal.JournalNo)
			whereParts = append(whereParts, fmt.Sprintf("journal_no = $%d", len(args)))
		} else {
			return LedgerPostingDraft{}, ErrLedgerNotFound
		}

		if _, ok := movementColumns["updated_at"]; ok {
			setParts = append(setParts, "updated_at = now()")
		}

		if _, ok := movementColumns["updated_by"]; ok {
			args = append(args, "runtime")
			setParts = append(setParts, fmt.Sprintf("updated_by = $%d", len(args)))
		}

		if _, ok := movementColumns["deleted_at"]; ok {
			whereParts = append(whereParts, "deleted_at IS NULL")
		}

		sql := fmt.Sprintf(`
UPDATE erp_account_movements
SET %s
WHERE %s;
`, strings.Join(setParts, ", "), strings.Join(whereParts, " AND "))

		commandTag, err := tx.Exec(ctx, sql, args...)
		if err != nil {
			return LedgerPostingDraft{}, err
		}

		if commandTag.RowsAffected() == 0 {
			return LedgerPostingDraft{}, ErrLedgerNotFound
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return LedgerPostingDraft{}, err
	}

	draft.Status = LedgerPostingStatusPosted
	return draft, nil
}

func (s *PostgresLedgerPostingStore) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

func loadLedgerTableColumns(ctx context.Context, tx pgx.Tx, tableName string) (map[string]ledgerColumnInfo, error) {
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

	columns := make(map[string]ledgerColumnInfo)

	for rows.Next() {
		var col ledgerColumnInfo
		if err := rows.Scan(&col.Name, &col.DataType, &col.UDTName); err != nil {
			return nil, err
		}

		columns[col.Name] = col
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if len(columns) == 0 {
		return nil, ErrLedgerPersistFailed
	}

	return columns, nil
}

func insertAccountMovement(
	ctx context.Context,
	tx pgx.Tx,
	columns map[string]ledgerColumnInfo,
	draft LedgerPostingDraft,
	movement AccountMovementDraft,
	status LedgerPostingStatus,
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
		values = append(values, ledgerNullableUUID(columns[column], value))
	}

	add("tenant_id", draft.TenantID)

	addUUID("journal_entry_id", draft.Journal.JournalEntryID)

	if _, ok := columns["journal_line_id"]; ok {
		journalLineID, err := findLedgerJournalLineID(ctx, tx, draft, movement.LineNo)
		if err != nil {
			return err
		}

		addUUID("journal_line_id", journalLineID)
	}

	add("journal_no", draft.Journal.JournalNo)

	add("movement_date", draft.Fiscal.PostingDate)
	add("posting_date", draft.Fiscal.PostingDate)
	add("entry_date", draft.Fiscal.PostingDate)

	add("fiscal_year", draft.Fiscal.FiscalYear)
	add("fiscal_period", draft.Fiscal.FiscalPeriod)

	add("line_no", movement.LineNo)

	add("account_code", movement.AccountCode)
	add("account_name", ledgerNullableString(movement.AccountName))

	add("movement_direction", string(movement.MovementDirection))
	add("direction", string(movement.MovementDirection))

	add("debit_amount", movement.DebitAmount)
	add("credit_amount", movement.CreditAmount)
	add("local_debit_amount", movement.DebitAmount)
	add("local_credit_amount", movement.CreditAmount)

	add("amount", math.Abs(movement.SignedAmount))
	add("local_amount", math.Abs(movement.SignedAmount))
	add("signed_amount", movement.SignedAmount)

	add("currency_code", ledgerDefaultCurrency(movement.CurrencyCode))
	add("exchange_rate", ledgerDefaultExchangeRate(movement.ExchangeRate))

	add("description", ledgerNullableString(movement.Description))

	addUUID("party_id", movement.PartyID)
	addUUID("customer_id", movement.CustomerID)
	addUUID("vendor_id", movement.VendorID)

	add("status", ledgerMovementDBStatus(status))

	add("created_by", "runtime")
	add("updated_by", "runtime")

	if len(names) == 0 {
		return ErrLedgerPersistFailed
	}

	sql := buildLedgerInsertSQL("erp_account_movements", names)

	_, err := tx.Exec(ctx, sql, values...)
	return err
}

func findLedgerJournalLineID(ctx context.Context, tx pgx.Tx, draft LedgerPostingDraft, lineNo int) (string, error) {
	if strings.TrimSpace(draft.TenantID) == "" {
		return "", ErrTenantRequired
	}

	if lineNo <= 0 {
		return "", ErrLedgerPersistFailed
	}

	journalEntryID := ledgerNullableUUID(ledgerColumnInfo{UDTName: "uuid"}, draft.Journal.JournalEntryID)
	journalNo := strings.TrimSpace(draft.Journal.JournalNo)

	if journalEntryID == nil && journalNo == "" {
		return "", ErrJournalRefRequired
	}

	var journalLineID string

	err := tx.QueryRow(ctx, `
SELECT jl.journal_line_id::text
FROM erp_journal_lines jl
JOIN erp_journal_entries je ON je.journal_entry_id = jl.journal_entry_id
WHERE jl.tenant_id = $1
  AND jl.line_no = $2
  AND (
      ($3::uuid IS NOT NULL AND jl.journal_entry_id = $3::uuid)
      OR
      ($4::text <> '' AND je.journal_no = $4)
  )
  AND (jl.deleted_at IS NULL OR jl.deleted_at IS NULL)
LIMIT 1;
`, draft.TenantID, lineNo, journalEntryID, journalNo).Scan(&journalLineID)

	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrLedgerPersistFailed
	}

	if err != nil {
		return "", err
	}

	if strings.TrimSpace(journalLineID) == "" {
		return "", ErrLedgerPersistFailed
	}

	return journalLineID, nil
}

func buildLedgerInsertSQL(table string, columns []string) string {
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

func ledgerMovementDBStatus(status LedgerPostingStatus) string {
	return "posted"
}

func ledgerNullableString(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}

func ledgerDefaultCurrency(value string) string {
	if strings.TrimSpace(value) == "" {
		return "TRY"
	}

	return strings.ToUpper(strings.TrimSpace(value))
}

func ledgerDefaultExchangeRate(value float64) float64 {
	if value <= 0 {
		return 1
	}

	return value
}

func ledgerNullableUUID(column ledgerColumnInfo, value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}

	if column.UDTName == "uuid" && !ledgerIsUUID(trimmed) {
		return nil
	}

	return trimmed
}

func ledgerIsUUID(value string) bool {
	matched, _ := regexp.MatchString(`^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$`, value)
	return matched
}

func ledgerPostIsNoRows(err error) bool {
	return errors.Is(err, pgx.ErrNoRows)
}
