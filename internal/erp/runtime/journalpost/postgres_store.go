package journalpost

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ JournalPostingStore = (*PostgresJournalPostingStore)(nil)

type PostgresJournalPostingStore struct {
	pool *pgxpool.Pool
}

type journalColumnInfo struct {
	Name     string
	DataType string
	UDTName  string
}

func NewPostgresJournalPostingStore(pool *pgxpool.Pool) *PostgresJournalPostingStore {
	return &PostgresJournalPostingStore{pool: pool}
}

func (s *PostgresJournalPostingStore) PersistJournalDraft(ctx context.Context, draft JournalDraft) (JournalDraft, error) {
	if err := ValidateJournalDraft(draft); err != nil {
		return JournalDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return JournalDraft{}, err
	}
	defer tx.Rollback(ctx)

	entryColumns, err := loadJournalTableColumns(ctx, tx, "erp_journal_entries")
	if err != nil {
		return JournalDraft{}, err
	}

	lineColumns, err := loadJournalTableColumns(ctx, tx, "erp_journal_lines")
	if err != nil {
		return JournalDraft{}, err
	}

	journalEntryID, err := insertJournalEntry(ctx, tx, entryColumns, draft)
	if err != nil {
		return JournalDraft{}, err
	}

	if _, ok := lineColumns["journal_entry_id"]; ok && strings.TrimSpace(journalEntryID) == "" {
		return JournalDraft{}, ErrJournalPersistFailed
	}

	for _, line := range draft.Lines {
		if err := insertJournalLine(ctx, tx, lineColumns, draft, journalEntryID, line); err != nil {
			return JournalDraft{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return JournalDraft{}, err
	}

	draft.Status = JournalStatusDraft
	return draft, nil
}

func (s *PostgresJournalPostingStore) MarkJournalPosted(ctx context.Context, draft JournalDraft) (JournalDraft, error) {
	if err := ValidateJournalDraft(draft); err != nil {
		return JournalDraft{}, err
	}

	tx, err := s.beginTenantTx(ctx, draft.TenantID)
	if err != nil {
		return JournalDraft{}, err
	}
	defer tx.Rollback(ctx)

	entryColumns, err := loadJournalTableColumns(ctx, tx, "erp_journal_entries")
	if err != nil {
		return JournalDraft{}, err
	}

	setParts := make([]string, 0)
	args := []any{draft.TenantID, draft.JournalNo}

	addSet := func(column string, value any) {
		if _, ok := entryColumns[column]; !ok {
			return
		}

		args = append(args, value)
		setParts = append(setParts, fmt.Sprintf("%s = $%d", column, len(args)))
	}

	addSet("status", string(JournalStatusPosted))
	addSet("posted_at", draft.Fiscal.PostingDate)
	addSet("posted_by", "runtime")
	addSet("updated_at", "now()")
	addSet("updated_by", "runtime")

	if len(setParts) == 0 {
		return JournalDraft{}, ErrJournalPersistFailed
	}

	for i, setPart := range setParts {
		if strings.Contains(setPart, "= $") {
			continue
		}

		setParts[i] = setPart
	}

	queryArgs := make([]any, 0, len(args))
	queryArgs = append(queryArgs, args[0], args[1])

	finalSetParts := make([]string, 0, len(setParts))
	nextArgIndex := 3

	for _, part := range setParts {
		if strings.Contains(part, "updated_at = $") {
			finalSetParts = append(finalSetParts, "updated_at = now()")
			continue
		}

		valueIndex := extractLastPlaceholderIndex(part)
		if valueIndex == 0 {
			finalSetParts = append(finalSetParts, part)
			continue
		}

		queryArgs = append(queryArgs, args[valueIndex-1])
		columnName := strings.TrimSpace(strings.Split(part, "=")[0])
		finalSetParts = append(finalSetParts, fmt.Sprintf("%s = $%d", columnName, nextArgIndex))
		nextArgIndex++
	}

	whereDeleted := ""
	if _, ok := entryColumns["deleted_at"]; ok {
		whereDeleted = " AND deleted_at IS NULL"
	}

	sql := fmt.Sprintf(`
UPDATE erp_journal_entries
SET %s
WHERE tenant_id = $1
  AND journal_no = $2
  %s;
`, strings.Join(finalSetParts, ", "), whereDeleted)

	commandTag, err := tx.Exec(ctx, sql, queryArgs...)
	if err != nil {
		return JournalDraft{}, err
	}

	if commandTag.RowsAffected() != 1 {
		return JournalDraft{}, ErrJournalNotFound
	}

	if err := tx.Commit(ctx); err != nil {
		return JournalDraft{}, err
	}

	draft.Status = JournalStatusPosted
	return draft, nil
}

func (s *PostgresJournalPostingStore) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

func loadJournalTableColumns(ctx context.Context, tx pgx.Tx, tableName string) (map[string]journalColumnInfo, error) {
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

	columns := make(map[string]journalColumnInfo)

	for rows.Next() {
		var col journalColumnInfo
		if err := rows.Scan(&col.Name, &col.DataType, &col.UDTName); err != nil {
			return nil, err
		}
		columns[col.Name] = col
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if len(columns) == 0 {
		return nil, ErrJournalPersistFailed
	}

	return columns, nil
}

func insertJournalEntry(ctx context.Context, tx pgx.Tx, columns map[string]journalColumnInfo, draft JournalDraft) (string, error) {
	totalDebit, totalCredit := SumJournalLines(draft.Lines)

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
		values = append(values, postgresJournalNullableUUID(columns[column], value))
	}

	add("tenant_id", draft.TenantID)
	add("journal_no", draft.JournalNo)
	add("journal_date", draft.Fiscal.PostingDate)
	add("posting_date", draft.Fiscal.PostingDate)
	add("entry_date", draft.Fiscal.PostingDate)

	add("source_module", draft.Source.SourceModule)
	add("source_document_type", draft.Source.SourceDocumentType)
	addUUID("source_document_id", draft.Source.SourceDocumentID)
	add("source_document_no", draft.Source.SourceDocumentNo)

	add("fiscal_year", draft.Fiscal.FiscalYear)
	add("fiscal_period", draft.Fiscal.FiscalPeriod)

	add("description", nullableString(draft.Description))
	add("status", string(JournalStatusDraft))

	add("total_debit", totalDebit)
	add("total_credit", totalCredit)
	add("debit_total", totalDebit)
	add("credit_total", totalCredit)

	add("created_by", "runtime")
	add("updated_by", "runtime")

	if len(names) == 0 {
		return "", ErrJournalPersistFailed
	}

	returning := ""
	if _, ok := columns["journal_entry_id"]; ok {
		returning = " RETURNING journal_entry_id::text"
	}

	sql := buildJournalInsertSQL("erp_journal_entries", names, returning)

	if returning == "" {
		if _, err := tx.Exec(ctx, sql, values...); err != nil {
			return "", err
		}

		return "", nil
	}

	var journalEntryID string
	if err := tx.QueryRow(ctx, sql, values...).Scan(&journalEntryID); err != nil {
		return "", err
	}

	return journalEntryID, nil
}

func insertJournalLine(ctx context.Context, tx pgx.Tx, columns map[string]journalColumnInfo, draft JournalDraft, journalEntryID string, line JournalLineDraft) error {
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
		values = append(values, postgresJournalNullableUUID(columns[column], value))
	}

	add("tenant_id", draft.TenantID)
	addUUID("journal_entry_id", journalEntryID)

	add("line_no", line.LineNo)
	add("account_code", line.AccountCode)
	add("account_name", nullableString(line.AccountName))

	add("debit_amount", line.DebitAmount)
	add("credit_amount", line.CreditAmount)
	add("local_debit_amount", line.DebitAmount)
	add("local_credit_amount", line.CreditAmount)

	add("currency_code", nullableString(line.CurrencyCode))
	add("exchange_rate", line.ExchangeRate)

	add("description", nullableString(line.Description))

	addUUID("party_id", line.PartyID)
	addUUID("customer_id", line.CustomerID)
	addUUID("vendor_id", line.VendorID)

	add("created_by", "runtime")
	add("updated_by", "runtime")

	if len(names) == 0 {
		return ErrJournalPersistFailed
	}

	sql := buildJournalInsertSQL("erp_journal_lines", names, "")

	_, err := tx.Exec(ctx, sql, values...)
	return err
}

func buildJournalInsertSQL(table string, columns []string, returning string) string {
	placeholders := make([]string, 0, len(columns))

	for i := range columns {
		placeholders = append(placeholders, fmt.Sprintf("$%d", i+1))
	}

	return fmt.Sprintf(
		"INSERT INTO %s (%s) VALUES (%s)%s;",
		table,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "),
		returning,
	)
}

func nullableString(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}

func postgresJournalNullableUUID(column journalColumnInfo, value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}

	if column.UDTName == "uuid" && !isUUID(trimmed) {
		return nil
	}

	return trimmed
}

func isUUID(value string) bool {
	matched, _ := regexp.MatchString(`^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$`, value)
	return matched
}

func extractLastPlaceholderIndex(value string) int {
	idx := strings.LastIndex(value, "$")
	if idx < 0 {
		return 0
	}

	var number int
	_, _ = fmt.Sscanf(value[idx+1:], "%d", &number)
	return number
}

func journalPostIsNoRows(err error) bool {
	return errors.Is(err, pgx.ErrNoRows)
}
